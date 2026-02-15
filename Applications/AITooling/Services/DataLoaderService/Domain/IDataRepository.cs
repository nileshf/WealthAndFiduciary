using System.Collections.Generic;
using System.Threading.Tasks;

namespace DataLoaderService.Domain;

/// <summary>
/// Repository interface for data record operations
/// </summary>
public interface IDataRepository
{
    /// <summary>
    /// Retrieves all data records from the database
    /// </summary>
    /// <returns>A collection of all data records</returns>
    /// <exception cref="System.Exception">Thrown when database operation fails</exception>
    Task<IEnumerable<DataRecord>> GetAllAsync();

    /// <summary>
    /// Adds multiple data records to the database in a single transaction
    /// </summary>
    /// <param name="records">The collection of data records to add</param>
    /// <returns>A task representing the asynchronous operation</returns>
    /// <exception cref="System.ArgumentNullException">Thrown when records is null</exception>
    /// <exception cref="System.Exception">Thrown when database operation fails</exception>
    Task AddRangeAsync(IEnumerable<DataRecord> records);
}
