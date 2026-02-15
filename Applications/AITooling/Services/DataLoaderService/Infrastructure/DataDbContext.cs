using Microsoft.EntityFrameworkCore;
using DataLoaderService.Domain;

namespace DataLoaderService.Infrastructure;

/// <summary>
/// Database context for data loader service
/// </summary>
public class DataDbContext : DbContext
{
    /// <summary>
    /// Initializes a new instance of the DataDbContext
    /// </summary>
    /// <param name="options">The database context options</param>
    public DataDbContext(DbContextOptions<DataDbContext> options) : base(options) { }

    /// <summary>
    /// Gets or sets the data records DbSet
    /// </summary>
    public DbSet<DataRecord> DataRecords { get; set; } = null!;
}
