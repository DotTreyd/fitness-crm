using System;
using System.IO;
using System.Windows;

namespace Lab2BD1_WPF
{
    public static class Errors
    {
        private static readonly string logFile = "errors.txt";

        public static void LogException(Exception ex, string action)
        {
            string time = DateTime.Now.ToString("dd-MM-yyyy HH:mm:ss");
            string entry = $"{time} | Действие: {action} | Ошибка: {ex.Message}";
            try
            {
                if (!File.Exists(logFile))
                {
                    File.Create(logFile).Close();
                }
                File.AppendAllLines(logFile, new[] { entry });
            }
            catch (Exception logErr)
            {
                MessageBox.Show($"Ошибка записи в лог: {logErr.Message}");
            }
        }
    }
}