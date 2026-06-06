using Lab2BD1_WPF.Repositories;
using System;
using System.Windows;

namespace Lab2BD1_WPF.Views
{
    public partial class LoginWindow : Window
    {
        private readonly FitnessRepository _repo = new();

        public LoginWindow()
        {
            InitializeComponent();
            txtLogin.Focus();
        }

        private void Window_KeyDown(object sender, System.Windows.Input.KeyEventArgs e)
        {
            if (e.Key == System.Windows.Input.Key.Enter)
                Login_Click(sender, e);
        }

        private void Header_MouseLeftButtonDown(object sender, System.Windows.Input.MouseButtonEventArgs e)
        {
            if (e.LeftButton == System.Windows.Input.MouseButtonState.Pressed)
                DragMove();
        }

        private void Login_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                string login = txtLogin.Text;
                string password = txtPassword.Password;

                if (string.IsNullOrEmpty(login) || string.IsNullOrEmpty(password))
                {
                    MessageBox.Show("Введите логин и пароль!");
                    return;
                }

                var user = _repo.AuthenticateUser(login, password, out var instructorId);
                if (user == null)
                {
                    MessageBox.Show("Неверный логин или пароль!");
                    return;
                }

                var mainWindow = new MainWindow(user, instructorId);
                mainWindow.Show();
                Close();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка входа: " + ex.Message);
            }
        }

        private void Exit_Click(object sender, RoutedEventArgs e)
        {
            Application.Current.Shutdown();
        }
    }
}
