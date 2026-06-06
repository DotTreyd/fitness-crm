using Lab2BD1_WPF.Models;
using System;
using System.Collections.ObjectModel;
using System.Windows;

namespace Lab2BD1_WPF.Views
{
    public partial class EditTrainingWindow : Window
    {
        public TrainingSession EditedItem { get; private set; }

        public EditTrainingWindow(TrainingSession source, ObservableCollection<InstructorShort> instructors)
        {
            InitializeComponent();
            cbInstructor.ItemsSource = instructors;

            EditedItem = new TrainingSession
            {
                Id = source.Id,
                Title = source.Title,
                Date = source.Date,
                Type = source.Type,
                Seats = source.Seats,
                InstructorId = source.InstructorId,
                TrainerName = source.TrainerName,
                AdminId = source.AdminId
            };

            txtTitle.Text = source.Title.Replace("ОТМЕНА: ", string.Empty);
            dpDate.SelectedDate = source.Date;
            cbType.Text = source.Type;
            cbInstructor.SelectedValue = source.InstructorId;
            txtSeats.Text = source.Seats.ToString();
            chkCancelled.IsChecked = source.Title.StartsWith("ОТМЕНА:");
        }

        private void Save_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(txtTitle.Text))
            {
                MessageBox.Show("Введите название.");
                return;
            }

            if (!int.TryParse(txtSeats.Text, out var seats) || seats < 0)
            {
                MessageBox.Show("Введите корректное количество мест.");
                return;
            }

            if (cbInstructor.SelectedValue == null || dpDate.SelectedDate == null || string.IsNullOrWhiteSpace(cbType.Text))
            {
                MessageBox.Show("Заполните все поля.");
                return;
            }

            var finalTitle = txtTitle.Text.Trim();
            if (chkCancelled.IsChecked == true && !finalTitle.StartsWith("ОТМЕНА:"))
                finalTitle = $"ОТМЕНА: {finalTitle}";

            EditedItem.Title = finalTitle;
            EditedItem.Date = dpDate.SelectedDate.Value;
            EditedItem.Type = cbType.Text.Trim();
            EditedItem.Seats = seats;
            EditedItem.InstructorId = (int)cbInstructor.SelectedValue;

            DialogResult = true;
        }
    }
}
