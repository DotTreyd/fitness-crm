using Lab2BD1_WPF.Models;
using Lab2BD1_WPF.Repositories;
using System.Linq;
using System.Windows;

namespace Lab2BD1_WPF.Views
{
    public partial class ClientPaymentsWindow : Window
    {
        public ClientPaymentsWindow(ClientEditModel client)
        {
            InitializeComponent();
            txtClientTitle.Text = $"Платежи клиента: {client.FullName}";

            var payments = new FitnessRepository().GetClientPayments(client.Id);
            dgPayments.ItemsSource = payments;

            if (payments.Count == 0)
                txtSummary.Text = "Платежи не найдены.";
            else
            {
                var total = payments.Sum(p => p.Amount);
                txtSummary.Text = $"Записей: {payments.Count}  •  Сумма: {total:N0} ₽";
            }
        }
    }
}
