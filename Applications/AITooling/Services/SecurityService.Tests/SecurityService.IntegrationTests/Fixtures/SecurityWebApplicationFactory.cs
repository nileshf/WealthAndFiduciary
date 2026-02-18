using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SecurityService.Infrastructure;

namespace SecurityService.IntegrationTests.Fixtures;

public class SecurityWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureAppConfiguration((context, config) =>
        {
            // Override JWT configuration for testing
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = "ThisIsASecretKeyForTestingPurposesOnly123456",
                ["Jwt:Issuer"] = "SecurityService",
                ["Jwt:Audience"] = "SecurityService"
            });
        });

        builder.ConfigureServices(services =>
        {
            // Remove the production database context
            var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<SecurityDbContext>));
            if (descriptor != null)
            {
                services.Remove(descriptor);
            }

            // Add in-memory database for testing
            services.AddDbContext<SecurityDbContext>(options =>
            {
                options.UseInMemoryDatabase($"SecurityTest_{Guid.NewGuid()}");
            });

            // Ensure database is created
            var serviceProvider = services.BuildServiceProvider();
            using (var scope = serviceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<SecurityDbContext>();
                dbContext.Database.EnsureCreated();
            }
        });
    }
}
