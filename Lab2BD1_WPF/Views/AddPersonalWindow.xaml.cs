using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using Lab2BD1_WPF.Models;
using System;
using System.Collections.ObjectModel;

namespace Lab2BD1_WPF.Views
{
    public partial class AddPersonalWindow : Window
    {
        public int SelectedClientId { get; private set; }
        public int SelectedInstructorId { get; private set; }
        public DateTime SelectedDateTime { get; private set; }

        public AddPersonalWindow(ObservableCollection<ClientShort> clients, ObservableCollection<InstructorShort> instructors)
        {
            InitializeComponent();
            cbClient.ItemsSource = clients;
            cbInstructor.ItemsSource = instructors;
            dpDate.SelectedDate = DateTime.Today;
        }

        public void PreselectInstructor(int instructorId)
        {
            cbInstructor.SelectedValue = instructorId;
            cbInstructor.IsEnabled = false;
        }

        private void Save_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                if (cbClient.SelectedValue == null) throw new Exception("Выберите клиента!");
                if (cbInstructor.SelectedValue == null) throw new Exception("Выберите тренера!");
                if (string.IsNullOrWhiteSpace(txtTime.Text)) throw new Exception("Введите время!");

                if (!TimeSpan.TryParse(txtTime.Text, out TimeSpan time))
                {
                    throw new Exception("Неверный формат времени! Используйте формат ЧЧ:ММ (напр. 14:30)");
                }

                // Полная дату
                DateTime date = dpDate.SelectedDate.Value;
                SelectedDateTime = date.Add(time);

                SelectedClientId = (int)cbClient.SelectedValue;
                SelectedInstructorId = (int)cbInstructor.SelectedValue;

                DialogResult = true;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка: " + ex.Message);
            }
        }
    }
}
