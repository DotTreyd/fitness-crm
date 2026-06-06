using Lab2BD1_WPF.Models;
using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows;

namespace Lab2BD1_WPF.Views
{
    public partial class EditPersonalWindow : Window
    {
        private readonly bool _lockInstructor;
        private readonly int? _lockedInstructorId;

        public int ClientId { get; private set; }
        public int InstructorId { get; private set; }
        public DateTime DateTimeVal { get; private set; }
        public bool StatusVal { get; private set; }

        public EditPersonalWindow(PersonalSession source, ObservableCollection<ClientShort> clients, ObservableCollection<InstructorShort> instructors, bool lockInstructor = false, int? instructorId = null)
        {
            InitializeComponent();
            _lockInstructor = lockInstructor;
            _lockedInstructorId = instructorId;
            cbClient.ItemsSource = clients;
            cbInstructor.ItemsSource = instructors;
            cbClient.SelectedValue = clients.FirstOrDefault(x => x.FullName == source.ClientName)?.Id;
            cbInstructor.SelectedValue = lockInstructor && instructorId.HasValue
                ? instructorId.Value
                : instructors.FirstOrDefault(x => x.Name == source.TrainerName)?.Id;
            cbInstructor.IsEnabled = !lockInstructor;
            dpDate.SelectedDate = source.DateTime.Date;
            txtTime.Text = source.DateTime.ToString("HH:mm");
            chkStatus.IsChecked = source.Status;
        }

        private void Save_Click(object sender, RoutedEventArgs e)
        {
            if (cbClient.SelectedValue == null || cbInstructor.SelectedValue == null || dpDate.SelectedDate == null || !TimeSpan.TryParse(txtTime.Text, out var time))
            {
                MessageBox.Show("Проверьте поля.");
                return;
            }
            ClientId = (int)cbClient.SelectedValue;
            InstructorId = _lockInstructor && _lockedInstructorId.HasValue
                ? _lockedInstructorId.Value
                : (int)cbInstructor.SelectedValue;
            DateTimeVal = dpDate.SelectedDate.Value.Date.Add(time);
            StatusVal = chkStatus.IsChecked == true;
            DialogResult = true;
        }
    }
}
