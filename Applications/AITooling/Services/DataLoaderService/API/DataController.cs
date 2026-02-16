using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using DataLoaderService.Application;

namespace DataLoaderService.API;

/// <summary>
/// Controller for data loading and retrieval operations
/// Test comment to verify CI/CD pipeline execution
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DataController : ControllerBase
{
    private readonly FileLoaderService _fileLoaderService;
    private readonly ILogger<DataController> _logger;

    // File size constraints
    private const int BytesPerKilobyte = 1024;
    private const int KilobytesPerMegabyte = 1024;
    private const int MaxFileSizeMegabytes = 10;
    private const long MaxFileSizeBytes = MaxFileSizeMegabytes * KilobytesPerMegabyte * BytesPerKilobyte;

    /// <summary>
    /// Initializes a new instance of the DataController
    /// </summary>
    /// <param name="fileLoaderService">The file loader service for CSV operations</param>
    /// <param name="logger">The logger for diagnostic information</param>
    public DataController(FileLoaderService fileLoaderService, ILogger<DataController> logger)
    {
        _fileLoaderService = fileLoaderService;
        _logger = logger;
    }

    /// <summary>
    /// Uploads and processes a CSV file
    /// </summary>
    /// <param name="file">The CSV file to upload</param>
    /// <returns>A response indicating the number of records loaded</returns>
    /// <response code="200">Returns the number of records loaded successfully</response>
    /// <response code="400">If the file is null, empty, too large, or not a CSV file</response>
    /// <response code="401">If the user is not authenticated</response>
    /// <response code="500">If an error occurs during processing</response>
    [HttpPost("upload")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> UploadFile(IFormFile file)
    {
        // Validate file is provided
        if (file == null || file.Length == 0)
        {
            _logger.LogWarning("Upload attempt with no file");
            return BadRequest(new { message = "No file uploaded" });
        }

        // Validate file size
        if (file.Length > MaxFileSizeBytes)
        {
            _logger.LogWarning("Upload attempt with file size {FileSize} bytes exceeding limit of {MaxSize} bytes",
                file.Length, MaxFileSizeBytes);
            return BadRequest(new { message = $"File size exceeds maximum limit of {MaxFileSizeMegabytes} MB" });
        }

        // Validate file type
        var fileExtension = Path.GetExtension(file.FileName)?.ToLowerInvariant();
        if (fileExtension != ".csv")
        {
            _logger.LogWarning("Upload attempt with invalid file type: {FileExtension}", fileExtension);
            return BadRequest(new { message = "Only CSV files are supported" });
        }

        // Validate content type
        if (!string.IsNullOrEmpty(file.ContentType) &&
            file.ContentType != "text/csv" &&
            file.ContentType != "application/csv" &&
            file.ContentType != "application/vnd.ms-excel")
        {
            _logger.LogWarning("Upload attempt with invalid content type: {ContentType}", file.ContentType);
            return BadRequest(new { message = "Invalid file content type. Expected CSV file." });
        }

        try
        {
            using var stream = file.OpenReadStream();
            var count = await _fileLoaderService.LoadFromCsvAsync(stream);

            _logger.LogInformation("Successfully loaded {Count} records from file {FileName}", count, file.FileName);
            return Ok(new { message = $"Loaded {count} records", count });
        }
        catch (CsvHelper.CsvHelperException ex)
        {
            _logger.LogError(ex, "CSV parsing error for file {FileName}", file.FileName);
            return BadRequest(new { message = "Invalid CSV format. Please ensure the file has 'Name' and 'Value' columns." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing file {FileName}", file.FileName);
            return StatusCode(StatusCodes.Status500InternalServerError,
                new { message = "An error occurred while processing the file" });
        }
    }

    /// <summary>
    /// Retrieves all data records from the database
    /// </summary>
    /// <returns>A collection of all data records</returns>
    /// <response code="200">Returns all data records</response>
    /// <response code="401">If the user is not authenticated</response>
    /// <response code="500">If an error occurs during retrieval</response>
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetAll()
    {
        try
        {
            var data = await _fileLoaderService.GetAllDataAsync();
            _logger.LogInformation("Retrieved all data records");
            return Ok(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving data records");
            return StatusCode(StatusCodes.Status500InternalServerError,
                new { message = "An error occurred while retrieving data" });
        }
    }

    /// <summary>
    /// Retrieves a specific data record by ID
    /// </summary>
    /// <param name="id">The ID of the data record</param>
    /// <returns>The data record</returns>
    /// <response code="200">Returns the data record</response>
    /// <response code="404">If the data record is not found</response>
    [HttpGet("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id)
    {
        var allData = await _fileLoaderService.GetAllDataAsync();
        var data = allData.FirstOrDefault(d => d.Id == id);

        if (data == null)
        {
            return NotFound(new { message = $"Data record with ID {id} not found" });
        }

        return Ok(data.Name);
    }



}
