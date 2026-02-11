using DataLoaderService.Domain;
using DataLoaderService.Infrastructure;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;

namespace DataLoaderService.IntegrationTests.Infrastructure;

public class DataRepositoryTests : IDisposable
{
    private readonly DataDbContext _context;
    private readonly DataRepository _repository;

    public DataRepositoryTests()
    {
        var options = new DbContextOptionsBuilder<DataDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        _context = new DataDbContext(options);
        _repository = new DataRepository(_context);
    }

    public void Dispose()
    {
        _context.Database.EnsureDeleted();
        _context.Dispose();
    }

    [Fact]
    public async Task AddRangeAsync_WithValidRecords_SavesRecordsToDatabase()
    {
        // Arrange
        var records = new List<DataRecord>
        {
            new() { Name = "Test1", Value = "Value1", CreatedAt = DateTime.UtcNow },
            new() { Name = "Test2", Value = "Value2", CreatedAt = DateTime.UtcNow }
        };

        // Act
        await _repository.AddRangeAsync(records);

        // Assert
        var savedRecords = await _context.DataRecords.ToListAsync();
        savedRecords.Should().HaveCount(2);
        savedRecords[0].Name.Should().Be("Test1");
        savedRecords[1].Name.Should().Be("Test2");
    }

    [Fact]
    public async Task GetAllAsync_WithExistingRecords_ReturnsAllRecords()
    {
        // Arrange
        var records = new List<DataRecord>
        {
            new() { Name = "Item1", Value = "Val1", CreatedAt = DateTime.UtcNow },
            new() { Name = "Item2", Value = "Val2", CreatedAt = DateTime.UtcNow },
            new() { Name = "Item3", Value = "Val3", CreatedAt = DateTime.UtcNow }
        };

        _context.DataRecords.AddRange(records);
        await _context.SaveChangesAsync();

        // Act
        var result = await _repository.GetAllAsync();

        // Assert
        result.Should().HaveCount(3);
        result.Should().Contain(r => r.Name == "Item1");
        result.Should().Contain(r => r.Name == "Item2");
        result.Should().Contain(r => r.Name == "Item3");
    }

    [Fact]
    public async Task GetAllAsync_WithNoRecords_ReturnsEmptyList()
    {
        // Act
        var result = await _repository.GetAllAsync();

        // Assert
        result.Should().BeEmpty();
    }

    [Fact]
    public async Task AddRangeAsync_WithEmptyList_DoesNotThrowException()
    {
        // Arrange
        var records = new List<DataRecord>();

        // Act
        Func<Task> act = async () => await _repository.AddRangeAsync(records);

        // Assert
        await act.Should().NotThrowAsync();

        var savedRecords = await _context.DataRecords.ToListAsync();
        savedRecords.Should().BeEmpty();
    }

    [Fact]
    public async Task AddRangeAsync_WithMultipleBatches_SavesAllRecords()
    {
        // Arrange
        var batch1 = new List<DataRecord>
        {
            new() { Name = "Batch1Item1", Value = "Value1", CreatedAt = DateTime.UtcNow }
        };

        var batch2 = new List<DataRecord>
        {
            new() { Name = "Batch2Item1", Value = "Value2", CreatedAt = DateTime.UtcNow }
        };

        // Act
        await _repository.AddRangeAsync(batch1);
        await _repository.AddRangeAsync(batch2);

        // Assert
        var allRecords = await _repository.GetAllAsync();
        allRecords.Should().HaveCount(2);
        allRecords.Should().Contain(r => r.Name == "Batch1Item1");
        allRecords.Should().Contain(r => r.Name == "Batch2Item1");
    }

    [Fact]
    public async Task AddRangeAsync_AssignsAutoIncrementIds()
    {
        // Arrange
        var records = new List<DataRecord>
        {
            new() { Name = "Test1", Value = "Value1", CreatedAt = DateTime.UtcNow },
            new() { Name = "Test2", Value = "Value2", CreatedAt = DateTime.UtcNow }
        };

        // Act
        await _repository.AddRangeAsync(records);

        // Assert
        var savedRecords = await _context.DataRecords.ToListAsync();
        savedRecords[0].Id.Should().BeGreaterThan(0);
        savedRecords[1].Id.Should().BeGreaterThan(0);
        savedRecords[1].Id.Should().BeGreaterThan(savedRecords[0].Id);
    }
}
