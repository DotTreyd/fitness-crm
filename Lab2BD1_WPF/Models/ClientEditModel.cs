using System;

namespace Lab2BD1_WPF.Models
{
    public class ClientEditModel
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Contacts { get; set; } = string.Empty;
        public DateTime Birthday { get; set; }
        public DateTime RegistrationDate { get; set; }
    }
}
