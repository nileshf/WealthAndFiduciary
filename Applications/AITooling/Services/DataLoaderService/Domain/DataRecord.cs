using System;

namespace DataLoaderService.Domain;

/// <summary>
/// Represents a data record loaded from a CSV file
/// </summary>
public class DataRecord
{
    /// <summary>
    /// Gets or sets the unique identifier for the record
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// Gets or sets the name field from the CSV file
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the value field from the CSV file
    /// </summary>
    public string Value { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the UTC timestamp when the record was created
    /// </summary>
    public DateTime CreatedAt { get; set; }
}
