using Microsoft.EntityFrameworkCore;
using SecurityService.Domain;

namespace SecurityService.Infrastructure;

public class SecurityDbContext : DbContext
{
    public SecurityDbContext(DbContextOptions<SecurityDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
}
