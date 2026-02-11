using System.Threading.Tasks;

namespace SecurityService.Domain;

public interface IUserRepository
{
    Task<User?> GetByUsernameAsync(string username);
    Task<User> CreateAsync(User user);
}
