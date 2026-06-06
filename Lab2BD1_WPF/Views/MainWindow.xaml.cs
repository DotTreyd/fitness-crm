using Lab2BD1_WPF.Models;
using Lab2BD1_WPF.Repositories;
using Npgsql;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;

namespace Lab2BD1_WPF.Views
{
    public partial class MainWindow : Window
    {
        private readonly FitnessRepository _repo = new();
        private readonly User _user;
        private readonly int? _instructorId;
        private readonly List<InstructorShort> _trainersForFilter = new();
        private List<TrainingSession> _allSchedule = new();
        private List<PersonalSession> _allPersonal = new();
        private List<PaymentWithClient> _allPayments = new();
        private readonly List<string> _paymentMethodsFilter = new();
        private readonly List<string> _scheduleTypeFilter = new();
        private const int PageSize = 15;
        private const int FinanceTabIndex = 3;
        private const int ClientsTabIndex = 2;
        private int _currentPage = 1;
        private int _totalPages = 1;

        public MainWindow(User user, int? instructorId)
        {
            InitializeComponent();
            _user = user;
            _instructorId = instructorId;
            var roleLabel = _user.Role == Role.Admin ? "Администратор" : "Тренер";
            var fullName = _repo.GetUserFullName(_user, _instructorId);
            txtRole.Text = roleLabel;
            txtUserFullName.Text = fullName;
            LoadData();
            ConfigurePermissions();
            Tab_Click(rbGroup, null);
        }

        private void ConfigurePermissions()
        {
            rbClients.Visibility = _user.Role == Role.Admin || _user.Role == Role.Trainer
                ? Visibility.Visible
                : Visibility.Collapsed;
            dgClients.IsReadOnly = _user.Role != Role.Admin;
            colGroupCancel.Visibility = _user.Role == Role.Admin || _user.Role == Role.Trainer
                ? Visibility.Visible
                : Visibility.Collapsed;
            colPersonalStatus.Visibility = _user.Role == Role.Admin || _user.Role == Role.Trainer
                ? Visibility.Visible
                : Visibility.Collapsed;
            rbFinance.Visibility = _user.Role == Role.Admin ? Visibility.Visible : Visibility.Collapsed;
            btnSubscriptionReport.Visibility = _user.Role == Role.Admin ? Visibility.Visible : Visibility.Collapsed;
        }

        private int CurrentAdminId => _user.AdminId ?? 1;

        private void LoadData()
        {
            InitTrainerFilters();
            InitScheduleTypeFilter();
            _allSchedule = _repo.GetSchedule().ToList();
            _allPersonal = _repo.GetPersonalSchedule().ToList();
            foreach (var s in _allSchedule) s.CanCancel = CanManageGroupSession(s);
            foreach (var p in _allPersonal) p.CanEditStatus = CanManagePersonalSession(p);
            dgClients.ItemsSource = _repo.GetClientsForInlineEdit();
            if (_user.Role == Role.Admin)
            {
                _allPayments = _repo.GetAllPayments().ToList();
                InitFinanceFilters();
            }
            _currentPage = 1;
            ApplyCurrentTabData();
        }

        private void ApplyCurrentTabData()
        {
            if (MainTabs.SelectedIndex == 0)
            {
                var filtered = FilterSchedule().ToList();
                foreach (var s in filtered)
                    s.CanCancel = CanManageGroupSession(s);
                ApplyPagination(filtered, x => dgSchedule.ItemsSource = x);
            }
            else if (MainTabs.SelectedIndex == 1)
            {
                var filtered = FilterPersonal().ToList();
                foreach (var p in filtered)
                    p.CanEditStatus = CanManagePersonalSession(p);
                ApplyPagination(filtered, x => dgPersonal.ItemsSource = x);
            }
            else if (MainTabs.SelectedIndex == FinanceTabIndex)
            {
                var filtered = FilterPayments().ToList();
                dgFinance.ItemsSource = filtered;
                pnlPagination.Visibility = Visibility.Collapsed;
                var total = filtered.Sum(p => p.Amount);
                txtCounter.Text = $"Платежей: {filtered.Count}  •  Общая сумма: {total:N0} ₽";
            }
            else
            {
                var clients = ((IEnumerable<ClientEditModel>)_repo.GetClientsForInlineEdit()).ToList();
                if (cbClientHasContacts.IsChecked == true)
                    clients = clients.Where(x => !string.IsNullOrWhiteSpace(x.Contacts)).ToList();
                dgClients.ItemsSource = clients;
                pnlPagination.Visibility = Visibility.Collapsed;
                txtCounter.Text = $"Всего клиентов в базе: {clients.Count}";
            }
            UpdateAddButtonVisibility();
        }

        private void ApplyPagination<T>(List<T> items, Action<List<T>> setSource)
        {
            _totalPages = Math.Max(1, (int)Math.Ceiling(items.Count / (double)PageSize));
            if (_currentPage < 1) _currentPage = 1;
            if (_currentPage > _totalPages) _currentPage = _totalPages;
            setSource(items.Skip((_currentPage - 1) * PageSize).Take(PageSize).ToList());
            txtPageInfo.Text = $"Страница {_currentPage} из {_totalPages}";
            btnPrevPage.IsEnabled = _currentPage > 1;
            btnNextPage.IsEnabled = _currentPage < _totalPages;
            txtCounter.Text = $"Найдено записей: {items.Count}";
            pnlPagination.Visibility = Visibility.Visible;
        }

        private IEnumerable<TrainingSession> FilterSchedule()
        {
            var q = (txtSearch.Text ?? "").Trim().ToLowerInvariant();
            var data = string.IsNullOrWhiteSpace(q) ? _allSchedule : _allSchedule.Where(x =>
                x.Title.ToLowerInvariant().Contains(q) || x.TrainerName.ToLowerInvariant().Contains(q) || x.Type.ToLowerInvariant().Contains(q));
            if (cbGroupTrainerFilter.SelectedValue is int groupTrainerId && groupTrainerId > 0)
                data = data.Where(x => x.InstructorId == groupTrainerId);
            if (cbGroupActive.IsChecked == true) data = data.Where(x => !x.Title.StartsWith("ОТМЕНА:"));
            if (cbGroupCancelled.IsChecked == true) data = data.Where(x => x.Title.StartsWith("ОТМЕНА:"));
            if (cbGroupFree.IsChecked == true) data = data.Where(x => x.Seats > 0);
            if (cbGroupBusy.IsChecked == true) data = data.Where(x => x.Seats == 0);
            if (cbGroupTypeFilter.SelectedItem is string typeFilter && typeFilter != "Все типы")
            {
                if (typeFilter == "Групповые")
                    data = data.Where(x => x.Type.Contains("Группов", StringComparison.OrdinalIgnoreCase));
                else if (typeFilter == "Персональные")
                    data = data.Where(x => x.Type.Contains("Персональн", StringComparison.OrdinalIgnoreCase));
            }
            return data;
        }

        private IEnumerable<PaymentWithClient> FilterPayments()
        {
            var q = (txtSearch.Text ?? "").Trim().ToLowerInvariant();
            var data = string.IsNullOrWhiteSpace(q)
                ? _allPayments
                : _allPayments.Where(x =>
                    x.ClientName.ToLowerInvariant().Contains(q)
                    || x.ClientContacts.ToLowerInvariant().Contains(q)
                    || x.Purpose.ToLowerInvariant().Contains(q)
                    || x.Method.ToLowerInvariant().Contains(q)
                    || x.Number.ToString().Contains(q));

            if (cbFinanceMethodFilter.SelectedItem is string method && method != "Все способы")
                data = data.Where(x => x.Method == method);

            return data;
        }

        private IEnumerable<PersonalSession> FilterPersonal()
        {
            var q = (txtSearch.Text ?? "").Trim().ToLowerInvariant();
            var data = string.IsNullOrWhiteSpace(q) ? _allPersonal : _allPersonal.Where(x =>
                x.ClientName.ToLowerInvariant().Contains(q) || x.TrainerName.ToLowerInvariant().Contains(q));
            if (cbPersonalTrainerFilter.SelectedValue is int personalTrainerId && personalTrainerId > 0)
                data = data.Where(x => x.InstructorId == personalTrainerId);
            if (cbPersonalActive.IsChecked == true) data = data.Where(x => x.Status);
            if (cbPersonalCancelled.IsChecked == true) data = data.Where(x => !x.Status);
            return data;
        }

        private void Search_TextChanged(object sender, TextChangedEventArgs e)
        {
            _currentPage = 1;
            ApplyCurrentTabData();
        }
        private void FilterChanged_Click(object sender, RoutedEventArgs e)
        {
            _currentPage = 1;
            ApplyCurrentTabData();
        }
        private void TrainerFilter_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            _currentPage = 1;
            ApplyCurrentTabData();
        }

        private void GroupTypeFilter_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            _currentPage = 1;
            ApplyCurrentTabData();
        }

        private void FinanceFilter_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            _currentPage = 1;
            ApplyCurrentTabData();
        }

        private void Tab_Click(object sender, RoutedEventArgs e)
        {
            txtSearch.Text = "";
            if (sender == rbGroup) { MainTabs.SelectedIndex = 0; txtPageTitle.Text = "Расписание занятий"; }
            else if (sender == rbPersonal) { MainTabs.SelectedIndex = 1; txtPageTitle.Text = "Персональные записи"; }
            else if (sender == rbFinance) { MainTabs.SelectedIndex = FinanceTabIndex; txtPageTitle.Text = "Финансы"; }
            else { MainTabs.SelectedIndex = ClientsTabIndex; txtPageTitle.Text = "Клиенты"; }
            _currentPage = 1;
            ApplyCurrentTabData();
        }

        private void UpdateAddButtonVisibility()
        {
            btnUniversalAdd.Visibility = MainTabs.SelectedIndex == FinanceTabIndex
                ? Visibility.Collapsed
                : Visibility.Visible;
        }

        private void PrevPage_Click(object sender, RoutedEventArgs e) { _currentPage--; ApplyCurrentTabData(); }
        private void NextPage_Click(object sender, RoutedEventArgs e) { _currentPage++; ApplyCurrentTabData(); }

        private void UniversalAdd_Click(object sender, RoutedEventArgs e)
        {
            if (MainTabs.SelectedIndex == 0)
            {
                var win = new AddTrainingWindow(_repo.GetInstructors());
                if (_user.Role == Role.Trainer && _instructorId.HasValue) win.PreselectInstructor(_instructorId.Value);
                if (win.ShowDialog() == true)
                {
                    var iid = _user.Role == Role.Trainer ? _instructorId ?? win.InstructorIdVal : win.InstructorIdVal;
                    try
                    {
                        _repo.AddTraining(win.TitleVal, win.DateVal, win.SeatsVal, win.TypeVal, iid, CurrentAdminId);
                        LoadData();
                    }
                    catch (PostgresException ex)
                    {
                        MessageBox.Show(BuildFriendlyDbMessage(ex, iid), "Предупреждение", MessageBoxButton.OK, MessageBoxImage.Warning);
                    }
                }
            }
            else if (MainTabs.SelectedIndex == 1)
            {
                var win = new AddPersonalWindow(_repo.GetClients(), _repo.GetInstructors());
                if (_user.Role == Role.Trainer && _instructorId.HasValue) win.PreselectInstructor(_instructorId.Value);
                if (win.ShowDialog() == true)
                {
                    var iid = _user.Role == Role.Trainer ? _instructorId ?? win.SelectedInstructorId : win.SelectedInstructorId;
                    _repo.AddPersonalTraining(win.SelectedClientId, iid, win.SelectedDateTime);
                    LoadData();
                }
            }
            else if (MainTabs.SelectedIndex == ClientsTabIndex)
            {
                if (_user.Role != Role.Admin) return;
                var win = new AddClientWindow();
                if (win.ShowDialog() == true)
                {
                    _repo.AddClient(win.FullNameVal, win.ContactsVal, win.BirthdayVal, win.RegistrationVal, CurrentAdminId);
                    LoadData();
                }
            }
        }

        private void EditTraining_Click(object sender, RoutedEventArgs e) => OpenEdit();
        private void dgSchedule_MouseDoubleClick(object sender, MouseButtonEventArgs e) => OpenEdit();
        private void OpenEdit()
        {
            if (dgSchedule.SelectedItem is not TrainingSession selected) return;
            if (!CanManageGroupSession(selected))
            {
                MessageBox.Show("Вы можете изменять только свои групповые занятия.", "Недостаточно прав", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }
            var win = new EditTrainingWindow(selected, _repo.GetInstructors());
            if (win.ShowDialog() == true)
            {
                try
                {
                    _repo.UpdateTraining(win.EditedItem);
                    LoadData();
                }
                catch (PostgresException ex)
                {
                    MessageBox.Show(BuildFriendlyDbMessage(ex, win.EditedItem.InstructorId), "Предупреждение", MessageBoxButton.OK, MessageBoxImage.Warning);
                }
            }
        }

        private void Cancel_Click(object sender, RoutedEventArgs e)
        {
            if ((sender as Button)?.DataContext is not TrainingSession selected) return;
            if (!CanManageGroupSession(selected))
            {
                MessageBox.Show("Вы можете отменять только свои групповые занятия.", "Недостаточно прав", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }
            if (selected.IsCancelled)
            {
                MessageBox.Show("Это занятие уже отменено.");
                return;
            }
            if (MessageBox.Show($"Отменить занятие '{selected.Title}'?", "Подтверждение", MessageBoxButton.YesNo, MessageBoxImage.Question) != MessageBoxResult.Yes)
                return;
            _repo.CancelByProcedure(selected.Id);
            LoadData();
        }

        private void PersonalStatus_Click(object sender, RoutedEventArgs e)
        {
            if ((sender as CheckBox)?.DataContext is not PersonalSession item) return;
            if (!CanManagePersonalSession(item))
            {
                MessageBox.Show("Вы можете менять статус только своих персональных тренировок.", "Недостаточно прав", MessageBoxButton.OK, MessageBoxImage.Information);
                LoadData();
                return;
            }

            if (sender is CheckBox cb)
                _repo.SetPersonalTrainingStatus(item.Id, cb.IsChecked == true);
        }

        private void ClientPayments_Click(object sender, RoutedEventArgs e)
        {
            if (dgClients.SelectedItem is not ClientEditModel client)
            {
                MessageBox.Show("Выберите клиента в таблице.", "История платежей", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            var win = new ClientPaymentsWindow(client) { Owner = this };
            win.ShowDialog();
        }

        private void dgPersonal_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            if (dgPersonal.SelectedItem is not PersonalSession item) return;
            if (!CanManagePersonalSession(item))
            {
                MessageBox.Show("Вы можете изменять только свои персональные тренировки.", "Недостаточно прав", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }
            var win = new EditPersonalWindow(item, _repo.GetClients(), _repo.GetInstructors(),
                _user.Role == Role.Trainer, _instructorId);
            if (win.ShowDialog() == true)
            {
                _repo.UpdatePersonalTraining(item.Id, win.ClientId, win.InstructorId, win.DateTimeVal, win.StatusVal);
                LoadData();
            }
        }

        private void dgClients_RowEditEnding(object sender, DataGridRowEditEndingEventArgs e)
        {
            if (_user.Role != Role.Admin) return;
            if (e.Row.Item is not ClientEditModel item) return;
            Dispatcher.BeginInvoke(new Action(() =>
            {
                _repo.UpdateClient(item);
                LoadData();
            }), System.Windows.Threading.DispatcherPriority.Background);
        }

        private void Report_Click(object sender, RoutedEventArgs e) => new ReportWindow().ShowDialog();

        private void SubscriptionReport_Click(object sender, RoutedEventArgs e) => new SubscriptionReportWindow().ShowDialog();

        private void EnrollClientToGroup_Click(object sender, RoutedEventArgs e)
        {
            if (dgSchedule.SelectedItem is not TrainingSession session)
            {
                MessageBox.Show("Выберите групповое занятие в таблице.", "Запись клиента", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            if (!CanManageGroupSession(session))
            {
                MessageBox.Show("Вы можете записывать клиентов только на свои групповые занятия.", "Недостаточно прав",
                    MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            if (session.IsCancelled)
            {
                MessageBox.Show("Нельзя записать клиента на отменённое занятие.", "Запись клиента",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (!session.Type.Contains("Группов", StringComparison.OrdinalIgnoreCase))
            {
                MessageBox.Show("Запись через это меню доступна только для групповых занятий.", "Запись клиента",
                    MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            if (session.Seats <= 0)
            {
                MessageBox.Show($"На занятие «{session.Title}» нет свободных мест.", "Запись клиента",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            var win = new AddClientToGroupWindow(session, _repo.GetClients(), _repo) { Owner = this };
            if (win.ShowDialog() != true) return;

            if (_repo.IsClientEnrolledInGroupSession(session.Id, win.SelectedClientId))
            {
                MessageBox.Show("Этот клиент уже записан на выбранное занятие.", "Запись клиента",
                    MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            try
            {
                _repo.AddClientToGroupSession(session.Id, win.SelectedClientId);
                LoadData();
                MessageBox.Show("Клиент успешно записан на занятие.", "Запись клиента",
                    MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (PostgresException ex)
            {
                MessageBox.Show(BuildParticipationErrorMessage(ex, session.Title), "Запись клиента",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                LoadData();
            }
        }

        private static string BuildParticipationErrorMessage(PostgresException ex, string sessionTitle)
        {
            var message = ex.MessageText ?? ex.Message ?? string.Empty;
            if (ex.SqlState == "23505")
                return "Этот клиент уже записан на выбранное занятие.";

            if (message.Contains("нет свободных мест", StringComparison.OrdinalIgnoreCase))
                return message;

            if (message.Contains("Ошибка", StringComparison.OrdinalIgnoreCase))
                return message;

            return $"Не удалось записать клиента на занятие «{sessionTitle}». Проверьте данные и попробуйте снова.";
        }
        private void Logout_Click(object sender, RoutedEventArgs e) { new LoginWindow().Show(); Close(); }

        private bool CanManageGroupSession(TrainingSession item)
        {
            if (_user.Role == Role.Admin) return true;
            if (_user.Role == Role.Trainer) return _instructorId.HasValue && item.InstructorId == _instructorId.Value;
            return false;
        }

        private bool CanManagePersonalSession(PersonalSession item)
        {
            if (_user.Role == Role.Admin) return true;
            if (_user.Role == Role.Trainer) return _instructorId.HasValue && item.InstructorId == _instructorId.Value;
            return false;
        }

        private void InitTrainerFilters()
        {
            if (_trainersForFilter.Count == 0)
            {
                _trainersForFilter.Add(new InstructorShort { Id = 0, Name = "Все тренеры" });
                foreach (var trainer in _repo.GetInstructors())
                    _trainersForFilter.Add(trainer);
            }

            cbGroupTrainerFilter.ItemsSource = _trainersForFilter;
            cbPersonalTrainerFilter.ItemsSource = _trainersForFilter;

            if (cbGroupTrainerFilter.SelectedValue == null) cbGroupTrainerFilter.SelectedValue = 0;
            if (cbPersonalTrainerFilter.SelectedValue == null) cbPersonalTrainerFilter.SelectedValue = 0;
        }

        private void InitScheduleTypeFilter()
        {
            if (_scheduleTypeFilter.Count > 0) return;
            _scheduleTypeFilter.Add("Все типы");
            _scheduleTypeFilter.Add("Групповые");
            _scheduleTypeFilter.Add("Персональные");
            cbGroupTypeFilter.ItemsSource = _scheduleTypeFilter;
            if (cbGroupTypeFilter.SelectedItem == null)
                cbGroupTypeFilter.SelectedIndex = 0;
        }

        private void InitFinanceFilters()
        {
            if (_paymentMethodsFilter.Count > 0) return;

            _paymentMethodsFilter.Add("Все способы");
            foreach (var method in _allPayments.Select(p => p.Method).Distinct().OrderBy(m => m))
                _paymentMethodsFilter.Add(method);

            cbFinanceMethodFilter.ItemsSource = _paymentMethodsFilter;
            if (cbFinanceMethodFilter.SelectedItem == null)
                cbFinanceMethodFilter.SelectedIndex = 0;
        }

        private string BuildFriendlyDbMessage(PostgresException ex, int instructorId)
        {
            var dbMessage = ex.MessageText ?? ex.Message ?? string.Empty;
            if (!dbMessage.Contains("Перегрузка", StringComparison.OrdinalIgnoreCase))
                return "Операцию не удалось выполнить. Проверьте введённые данные занятия.";

            var trainerName = _repo.GetInstructorName(instructorId)
                ?? _trainersForFilter.FirstOrDefault(x => x.Id == instructorId)?.Name
                ?? "тренер";

            if (dbMessage.Contains("Групповую", StringComparison.OrdinalIgnoreCase)
                || dbMessage.Contains("группов", StringComparison.OrdinalIgnoreCase))
            {
                if (_user.Role == Role.Trainer)
                {
                    var adminName = _repo.GetPrimaryAdminFullName();
                    return $"Невозможно провести второе групповое занятие за этот день. Обратитесь к администратору: {adminName}.";
                }

                return $"Невозможно назначить второе групповое занятие за этот день тренеру {trainerName}.";
            }

            if (dbMessage.Contains("персональн", StringComparison.OrdinalIgnoreCase))
                return $"Невозможно назначить более трёх персональных тренировок за день тренеру {trainerName}.";

            return $"Невозможно назначить занятие тренеру {trainerName} из-за ограничения расписания на этот день.";
        }
    }
}
