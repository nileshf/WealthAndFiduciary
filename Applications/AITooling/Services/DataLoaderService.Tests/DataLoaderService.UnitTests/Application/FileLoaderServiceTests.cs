using System.Text;
using DataLoaderService.Application;
using DataLoaderService.Domain;
using FluentAssertions;
using Moq;

namespace DataLoaderService.UnitTests.Application;

public class FileLoaderServiceTests
{
    private readonly Mock<IDataRepository> _repositoryMock;
    private readonly FileLoaderService _service;

    public FileLoaderServiceTests()
    {
        _repositoryMock = new Mock<IDataRepository>();
        _service = new FileLoaderService(_repositoryMock.Object);
    }

    [Fact]
    public async Task LoadFromCsvAsync_WithValidCsv_ReturnsCorrectCount()
    {
        // Arrange
        var csvContent = "Name,Value\nProduct1,Value1\nProduct2,Value2";
        var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));

        _repositoryMock
            .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
            .Returns(Task.CompletedTask);

        // Act
        var count = await _service.LoadFromCsvAsync(stream);

        // Assert
        count.Should().Be(2);
        _repositoryMock.Verify(x => x.AddRangeAsync(It.Is<IEnumerable<DataRecord>>(
            records => records.Count() == 2)), Times.Once);
    }

    [Fact]
    public async Task LoadFromCsvAsync_WithValidCsv_CreatesCorrectDataRecords()
    {
        // Arrange
        var csvContent = "Name,Value\nTestName,TestValue";
        var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));
        IEnumerable<DataRecord>? capturedRecords = null;

        _repositoryMock
            .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
            .Callback<IEnumerable<DataRecord>>(records => capturedRecords = records.ToList())
            .Returns(Task.CompletedTask);

        // Act
        await _service.LoadFromCsvAsync(stream);

        // Assert
        capturedRecords.Should().NotBeNull();
        capturedRecords.Should().HaveCount(1);

        var record = capturedRecords!.First();
        record.Name.Should().Be("TestName");
        record.Value.Should().Be("TestValue");
    }

    [Fact]
    public async Task LoadFromCsvAsync_WithValidCsv_SetsCreatedAtToUtcNow()
    {
        // Arrange
        var csvContent = "Name,Value\nTest,Value";
        var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));
        var beforeTime = DateTime.UtcNow.AddSeconds(-1);
        IEnumerable<DataRecord>? capturedRecords = null;

        _repositoryMock
            .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
            .Callback<IEnumerable<DataRecord>>(records => capturedRecords = records.ToList())
            .Returns(Task.CompletedTask);

        // Act
        await _service.LoadFromCsvAsync(stream);
        var afterTime = DateTime.UtcNow.AddSeconds(1);

        // Assert
        capturedRecords.Should().NotBeNull();
        var record = capturedRecords!.First();
        record.CreatedAt.Should().BeAfter(beforeTime);
        record.CreatedAt.Should().BeBefore(afterTime);
        record.CreatedAt.Kind.Should().Be(DateTimeKind.Utc);
    }

    [Fact]
    public async Task LoadFromCsvAsync_WithEmptyStream_ReturnsZero()
    {
        // Arrange
        var csvContent = "Name,Value";
        var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));

        _repositoryMock
            .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
            .Returns(Task.CompletedTask);

        // Act
        var count = await _service.LoadFromCsvAsync(stream);

        // Assert
        count.Should().Be(0);
        _repositoryMock.Verify(x => x.AddRangeAsync(It.Is<IEnumerable<DataRecord>>(
            records => !records.Any())), Times.Once);
    }

    [Fact]
    public async Task LoadFromCsvAsync_WithMultipleRecords_ParsesAllCorrectly()
    {
        // Arrange
        var csvContent = "Name,Value\nItem1,Val1\nItem2,Val2\nItem3,Val3";
        var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));
        IEnumerable<DataRecord>? capturedRecords = null;

        _repositoryMock
            .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
            .Callback<IEnumerable<DataRecord>>(records => capturedRecords = records.ToList())
            .Returns(Task.CompletedTask);

        // Act
        await _service.LoadFromCsvAsync(stream);

        // Assert
        capturedRecords.Should().NotBeNull();
        capturedRecords.Should().HaveCount(3);

        var recordsList = capturedRecords!.ToList();
        recordsList[0].Name.Should().Be("Item1");
        recordsList[0].Value.Should().Be("Val1");
        recordsList[1].Name.Should().Be("Item2");
        recordsList[1].Value.Should().Be("Val2");
        recordsList[2].Name.Should().Be("Item3");
        recordsList[2].Value.Should().Be("Val3");
    }

    [Fact]
    public async Task GetAllDataAsync_ReturnsAllRecords()
    {
        // Arrange
        var expectedRecords = new List<DataRecord>
        {
            new() { Id = 1, Name = "Test1", Value = "Value1", CreatedAt = DateTime.UtcNow },
            new() { Id = 2, Name = "Test2", Value = "Value2", CreatedAt = DateTime.UtcNow }
        };

        _repositoryMock
            .Setup(x => x.GetAllAsync())
            .ReturnsAsync(expectedRecords);

        // Act
        var result = await _service.GetAllDataAsync();

        // Assert
        result.Should().BeEquivalentTo(expectedRecords);
        _repositoryMock.Verify(x => x.GetAllAsync(), Times.Once);
    }

    [Fact]
    public async Task GetAllDataAsync_WhenNoRecords_ReturnsEmptyCollection()
    {
        // Arrange
        _repositoryMock
            .Setup(x => x.GetAllAsync())
            .ReturnsAsync(new List<DataRecord>());

        // Act
        var result = await _service.GetAllDataAsync();

        // Assert
        result.Should().BeEmpty();
        _repositoryMock.Verify(x => x.GetAllAsync(), Times.Once);
    }
}
