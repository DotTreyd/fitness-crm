using Lab2BD1_WPF.Models;
using Lab2BD1_WPF.Repositories;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows;

namespace Lab2BD1_WPF.Views
{
    public partial class AddClientToGroupWindow : Window
    {
        public int SelectedClientId { get; private set; }

        public AddClientToGroupWindow(TrainingSession session, ObservableCollection<ClientShort> clients, FitnessRepository repo)
        {
            InitializeComponent();
            txtSessionTitle.Text = session.Title;
            txtSessionInfo.Text = $"{session.Date:dd.MM.yyyy}  •  {session.TrainerName}  •  Свободно мест: {session.Seats}";

            var enrolled = repo.GetEnrolledClients(session.Id);
            lbEnrolled.ItemsSource = enrolled;
            txtEnrolledHeader.Text = enrolled.Count == 0
                ? "Записанные клиенты (пока никого нет)"
                : $"Записанные клиенты ({enrolled.Count})";

            var enrolledIds = enrolled.Select(x => x.ClientId).ToHashSet();
            var available = clients.Where(c => !enrolledIds.Contains(c.Id)).ToList();
            cbClient.ItemsSource = available;

            if (available.Count == 0)
                cbClient.IsEnabled = false;
        }

        private void Save_Click(object sender, RoutedEventArgs e)
        {
            if (cbClient.SelectedValue is not int clientId)
            {
                MessageBox.Show("Выберите клиента для записи.", "Запись на занятие", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            SelectedClientId = clientId;
            DialogResult = true;
        }
    }
}
