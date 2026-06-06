using System;

namespace Lab2BD1_WPF.Models
{
    public class SubscriptionReportRow
    {
        public int SubscriptionId { get; set; }
        public string ClientName { get; set; } = string.Empty;
        public string ClientContacts { get; set; } = string.Empty;
        public string SubscriptionType { get; set; } = string.Empty;
        public decimal SubscriptionPrice { get; set; }
        public decimal DiscountPrice { get; set; }
        public int PeriodDays { get; set; }
        public string StatusText { get; set; } = string.Empty;
        public string AdminName { get; set; } = string.Empty;
        public int? PaymentNumber { get; set; }
        public DateTime? PaymentDate { get; set; }
        public string PaymentPurpose { get; set; } = string.Empty;
        public decimal? PaymentAmount { get; set; }
        public string PaymentMethod { get; set; } = string.Empty;
    }
}
