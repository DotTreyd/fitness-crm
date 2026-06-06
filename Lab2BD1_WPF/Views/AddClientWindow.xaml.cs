using System;
using System.Windows;

namespace Lab2BD1_WPF.Views
{
    public partial class AddClientWindow : Window
    {
        public string FullNameVal { get; private set; } = string.Empty;
        public string ContactsVal { get; private set; } = string.Empty;
        public DateTime BirthdayVal { get; private set; }
        public DateTime RegistrationVal { get; private set; }

        public AddClientWindow()
        {
            InitializeComponent();
            dpBirthday.SelectedDate = DateTime.Today.AddYears(-20);
            dpRegistration.SelectedDate = DateTime.Today;
        }

        private void Save_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(txtName.Text) || string.IsNullOrWhiteSpace(txtContacts.Text) ||
                dpBirthday.SelectedDate == null || dpRegistration.SelectedDate == null)
            {
                MessageBox.Show("Заполните все поля.");
                return;
            }

            FullNameVal = txtName.Text.Trim();
            ContactsVal = txtContacts.Text.Trim();
            BirthdayVal = dpBirthday.SelectedDate.Value;
            RegistrationVal = dpRegistration.SelectedDate.Value;
            DialogResult = true;
        }
    }
}
