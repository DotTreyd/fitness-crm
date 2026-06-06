using System;

namespace Lab2BD1_WPF.Models
{
    public class Payment
    {
        public int Number { get; set; }
        public DateTime Date { get; set; }
        public string Purpose { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Method { get; set; } = string.Empty;
    }
}
