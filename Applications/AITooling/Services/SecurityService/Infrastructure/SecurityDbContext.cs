using Microsoft.EntityFrameworkCore;
using SecurityService.Domain;

namespace SecurityService.Infrastructure;

public class SecurityDbContext(DbContextOptions<SecurityDbContext> options) : DbContext(options)
{
    public required DbSet<User> Users { get; set; }
}
