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
using System.Collections.ObjectModel;

namespace Lab2BD1_WPF.Views
{
    public partial class AddTrainingWindow : Window
    {
        public string TitleVal { get; private set; }
        public DateTime DateVal { get; private set; }
        public string TypeVal { get; private set; }
        public int InstructorIdVal { get; private set; }
        public int SeatsVal { get; private set; }

        public AddTrainingWindow(ObservableCollection<InstructorShort> instructors)
        {
            InitializeComponent();
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
                if (string.IsNullOrWhiteSpace(txtTitle.Text)) throw new Exception("Введите название!");
                if (cbInstructor.SelectedValue == null) throw new Exception("Выберите тренера!");
                TitleVal = txtTitle.Text;
                DateVal = dpDate.SelectedDate.Value;
                TypeVal = "Групповая";
                InstructorIdVal = (int)cbInstructor.SelectedValue;
                SeatsVal = int.Parse(txtSeats.Text);

                DialogResult = true;
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка ввода: " + ex.Message);
            }
        }
    }
}
