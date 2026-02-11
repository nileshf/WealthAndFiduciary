using DataLoaderService.Domain;
using FluentAssertions;

namespace DataLoaderService.UnitTests.Domain;

public class DataRecordTests
{
    [Fact]
    public void DataRecord_Instantiation_CreatesObjectWithDefaultValues()
    {
        // Act
        var record = new DataRecord();

        // Assert
        record.Should().NotBeNull();
        record.Id.Should().Be(0);
        record.Name.Should().Be(string.Empty);
        record.Value.Should().Be(string.Empty);
        record.CreatedAt.Should().Be(default(DateTime));
    }

    [Fact]
    public void DataRecord_SetProperties_StoresValuesCorrectly()
    {
        // Arrange
        var record = new DataRecord();
        var testDate = DateTime.UtcNow;

        // Act
        record.Id = 1;
        record.Name = "TestName";
        record.Value = "TestValue";
        record.CreatedAt = testDate;

        // Assert
        record.Id.Should().Be(1);
        record.Name.Should().Be("TestName");
        record.Value.Should().Be("TestValue");
        record.CreatedAt.Should().Be(testDate);
    }

    [Fact]
    public void DataRecord_WithInitializer_SetsPropertiesCorrectly()
    {
        // Arrange
        var testDate = DateTime.UtcNow;

        // Act
        var record = new DataRecord
        {
            Id = 42,
            Name = "Product",
            Value = "Widget",
            CreatedAt = testDate
        };

        // Assert
        record.Id.Should().Be(42);
        record.Name.Should().Be("Product");
        record.Value.Should().Be("Widget");
        record.CreatedAt.Should().Be(testDate);
    }
}
