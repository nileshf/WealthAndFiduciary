using System.Text;
using DataLoaderService.Application;
using DataLoaderService.Domain;
using FsCheck;
using FsCheck.Xunit;
using Moq;

namespace DataLoaderService.PropertyTests;

public class CsvRoundTripPropertyTests
{
    /// <summary>
    /// Property 1.1: CSV Round-Trip
    /// Validates: Requirements 2, 3, 4
    /// For any valid CSV file, parsing and storing should preserve all data
    /// </summary>
    [Property(MaxTest = 100)]
    public Property CsvRoundTrip_PreservesAllData()
    {
        return Prop.ForAll(
            GenerateCsvRecords(),
            records =>
            {
                // Arrange
                var csvContent = BuildCsvContent(records);
                var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));
                var capturedRecords = new List<DataRecord>();

                var repositoryMock = new Mock<IDataRepository>();
                repositoryMock
                    .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
                    .Callback<IEnumerable<DataRecord>>(r => capturedRecords.AddRange(r))
                    .Returns(Task.CompletedTask);

                var service = new FileLoaderService(repositoryMock.Object);

                // Act
                var count = service.LoadFromCsvAsync(stream).Result;

                // Assert
                var recordsList = records.ToList();
                return count == recordsList.Count &&
                       capturedRecords.Count == recordsList.Count &&
                       capturedRecords.Zip(recordsList, (captured, original) =>
                           captured.Name == original.Name &&
                           captured.Value == original.Value).All(x => x);
            });
    }

    /// <summary>
    /// Property 1.2: Timestamp Consistency
    /// Validates: Requirement 2.5
    /// All records from a single upload should have CreatedAt within 1 second
    /// </summary>
    [Property(MaxTest = 100)]
    public Property TimestampConsistency_AllWithinOneSecond()
    {
        return Prop.ForAll(
            GenerateCsvRecords(),
            records =>
            {
                if (!records.Any()) return true;

                // Arrange
                var csvContent = BuildCsvContent(records);
                var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));
                var capturedRecords = new List<DataRecord>();

                var repositoryMock = new Mock<IDataRepository>();
                repositoryMock
                    .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
                    .Callback<IEnumerable<DataRecord>>(r => capturedRecords.AddRange(r))
                    .Returns(Task.CompletedTask);

                var service = new FileLoaderService(repositoryMock.Object);

                // Act
                service.LoadFromCsvAsync(stream).Wait();

                // Assert
                if (!capturedRecords.Any()) return true;

                var minTime = capturedRecords.Min(r => r.CreatedAt);
                var maxTime = capturedRecords.Max(r => r.CreatedAt);
                var timeDifference = maxTime - minTime;

                return timeDifference.TotalSeconds <= 1.0;
            });
    }

    /// <summary>
    /// Property 2.2: Count Accuracy
    /// Validates: Requirement 2.6
    /// Returned count always matches number of records saved
    /// </summary>
    [Property(MaxTest = 100)]
    public Property CountAccuracy_MatchesSavedRecords()
    {
        return Prop.ForAll(
            GenerateCsvRecords(),
            records =>
            {
                // Arrange
                var csvContent = BuildCsvContent(records);
                var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));
                var capturedRecords = new List<DataRecord>();

                var repositoryMock = new Mock<IDataRepository>();
                repositoryMock
                    .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
                    .Callback<IEnumerable<DataRecord>>(r => capturedRecords.AddRange(r))
                    .Returns(Task.CompletedTask);

                var service = new FileLoaderService(repositoryMock.Object);

                // Act
                var returnedCount = service.LoadFromCsvAsync(stream).Result;

                // Assert
                return returnedCount == capturedRecords.Count &&
                       returnedCount == records.Count();
            });
    }

    /// <summary>
    /// Property 4.1: Column Mapping
    /// Validates: Requirements 2.3, 2.4, 12
    /// CSV columns Name and Value map correctly to DataRecord
    /// </summary>
    [Property(MaxTest = 100)]
    public Property ColumnMapping_MapsCorrectly()
    {
        return Prop.ForAll(
            GenerateCsvRecords(),
            records =>
            {
                // Arrange
                var csvContent = BuildCsvContent(records);
                var stream = new MemoryStream(Encoding.UTF8.GetBytes(csvContent));
                var capturedRecords = new List<DataRecord>();

                var repositoryMock = new Mock<IDataRepository>();
                repositoryMock
                    .Setup(x => x.AddRangeAsync(It.IsAny<IEnumerable<DataRecord>>()))
                    .Callback<IEnumerable<DataRecord>>(r => capturedRecords.AddRange(r))
                    .Returns(Task.CompletedTask);

                var service = new FileLoaderService(repositoryMock.Object);

                // Act
                service.LoadFromCsvAsync(stream).Wait();

                // Assert
                var recordsList = records.ToList();
                if (capturedRecords.Count != recordsList.Count) return false;

                for (int i = 0; i < recordsList.Count; i++)
                {
                    if (capturedRecords[i].Name != recordsList[i].Name ||
                        capturedRecords[i].Value != recordsList[i].Value)
                    {
                        return false;
                    }
                }

                return true;
            });
    }

    private static Arbitrary<IEnumerable<CsvRecord>> GenerateCsvRecords()
    {
        var recordGen = from name in Arb.Generate<NonEmptyString>()
                        from value in Arb.Generate<NonEmptyString>()
                        select new CsvRecord
                        {
                            Name = SanitizeCsvValue(name.Get),
                            Value = SanitizeCsvValue(value.Get)
                        };

        return Gen.ListOf(recordGen)
            .Where(list => list.Count() <= 50) // Limit size for performance
            .Select(list => (IEnumerable<CsvRecord>)list)
            .ToArbitrary();
    }

    private static string SanitizeCsvValue(string value)
    {
        // Remove characters that could break CSV format
        return value
            .Replace("\n", " ")
            .Replace("\r", " ")
            .Replace("\"", "'")
            .Replace(",", ";")
            .Trim();
    }

    private static string BuildCsvContent(IEnumerable<CsvRecord> records)
    {
        var sb = new StringBuilder();
        sb.AppendLine("Name,Value");

        foreach (var record in records)
        {
            sb.AppendLine($"{record.Name},{record.Value}");
        }

        return sb.ToString();
    }
}
