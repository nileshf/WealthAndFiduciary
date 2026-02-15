using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Threading.Tasks;
using CsvHelper;
using CsvHelper.Configuration;
using DataLoaderService.Domain;

namespace DataLoaderService.Application;

/// <summary>
/// Service for loading data from CSV files into the database
/// </summary>
public class FileLoaderService
{
    private readonly IDataRepository _dataRepository;

    /// <summary>
    /// Initializes a new instance of the FileLoaderService
    /// </summary>
    /// <param name="dataRepository">The data repository for database operations</param>
    public FileLoaderService(IDataRepository dataRepository)
    {
        _dataRepository = dataRepository;
    }

    /// <summary>
    /// Loads data from a CSV file stream and saves it to the database
    /// </summary>
    /// <param name="fileStream">The CSV file stream to read from</param>
    /// <returns>The number of records loaded</returns>
    /// <exception cref="System.ArgumentNullException">Thrown when fileStream is null</exception>
    /// <exception cref="CsvHelper.CsvHelperException">Thrown when CSV parsing fails</exception>
    /// <exception cref="System.Exception">Thrown when database operation fails</exception>
    public async Task<int> LoadFromCsvAsync(Stream fileStream)
    {
        var records = new List<DataRecord>();

        using var reader = new StreamReader(fileStream);
        using var csv = new CsvReader(reader, new CsvConfiguration(CultureInfo.InvariantCulture));

        var csvRecords = csv.GetRecords<CsvRecord>();

        foreach (var record in csvRecords)
        {
            records.Add(new DataRecord
            {
                Name = record.Name,
                Value = record.Value,
                CreatedAt = DateTime.UtcNow
            });
        }

        await _dataRepository.AddRangeAsync(records);
        return records.Count;
    }

    /// <summary>
    /// Retrieves all data records from the database
    /// </summary>
    /// <returns>A collection of all data records</returns>
    /// <exception cref="System.Exception">Thrown when database operation fails</exception>
    public async Task<IEnumerable<DataRecord>> GetAllDataAsync()
    {
        return await _dataRepository.GetAllAsync();
    }
}

/// <summary>
/// Represents a CSV record with Name and Value columns
/// </summary>
public class CsvRecord
{
    /// <summary>
    /// Gets or sets the name column value
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the value column value
    /// </summary>
    public string Value { get; set; } = string.Empty;
}
