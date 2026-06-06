using System;

namespace Lab2BD1_WPF.Models
{
    public class PaymentWithClient
    {
        public int Number { get; set; }
        public int ClientId { get; set; }
        public string ClientName { get; set; } = string.Empty;
        public string ClientContacts { get; set; } = string.Empty;
        public DateTime Date { get; set; }
        public string Purpose { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Method { get; set; } = string.Empty;
    }
}
