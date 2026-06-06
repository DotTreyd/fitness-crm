using System;
using System.Xml.Serialization;

namespace Lab2BD1_WPF.Models
{
    // Перечисление ролей
    public enum Role
    {
        Admin,
        Trainer
    }

    public class User
    {
        public string Login { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public Role Role { get; set; }
        public int? AdminId { get; set; }

        public User() { }

        public User(string login, string password, Role role, int? adminId = null)
        {
            Login = login;
            Password = password;
            Role = role;
            AdminId = adminId;
        }
    }
}
