using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using DataLoaderService.Domain;

namespace DataLoaderService.Infrastructure;

public class DataRepository : IDataRepository
{
    private readonly DataDbContext _context;

    public DataRepository(DataDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<DataRecord>> GetAllAsync()
    {
        return await _context.DataRecords.ToListAsync();
    }

    public async Task AddRangeAsync(IEnumerable<DataRecord> records)
    {
        _context.DataRecords.AddRange(records);
        await _context.SaveChangesAsync();
    }
}
