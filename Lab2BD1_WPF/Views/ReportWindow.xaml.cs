using Lab2BD1_WPF.Models;
using Lab2BD1_WPF.Repositories;
using Microsoft.Win32;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows;

namespace Lab2BD1_WPF.Views
{
    public partial class ReportWindow : Window
    {
        private FitnessRepository _repo;

        // Списки
        private List<TrainingSession> _groupData;
        private List<PersonalSession> _personalData;
        private List<SessionReportRow> _allRows = new();
        private ReportData? _lastReport;

        public ReportWindow()
        {
            InitializeComponent();
            _repo = new FitnessRepository();
            dpStart.SelectedDate = new DateTime(DateTime.Now.Year, DateTime.Now.Month, 1);
            dpEnd.SelectedDate = DateTime.Now;
            SetupRowsGridColumns(dgAll);
            SetupRowsGridColumns(dgGroups);
            SetupRowsGridColumns(dgPersonals);
            SetupRowsGridColumns(dgCancelled);
        }

        private static void SetupRowsGridColumns(System.Windows.Controls.DataGrid grid)
        {
            grid.Columns.Add(new System.Windows.Controls.DataGridTextColumn { Header = "Дата", Binding = new System.Windows.Data.Binding("Date") { StringFormat = "dd.MM.yyyy HH:mm" }, Width = 140 });
            grid.Columns.Add(new System.Windows.Controls.DataGridTextColumn { Header = "Название", Binding = new System.Windows.Data.Binding("Title"), Width = new System.Windows.Controls.DataGridLength(2, System.Windows.Controls.DataGridLengthUnitType.Star) });
            grid.Columns.Add(new System.Windows.Controls.DataGridTextColumn { Header = "Вид", Binding = new System.Windows.Data.Binding("Kind"), Width = 110 });
            grid.Columns.Add(new System.Windows.Controls.DataGridTextColumn { Header = "Тип", Binding = new System.Windows.Data.Binding("Type"), Width = 110 });
            grid.Columns.Add(new System.Windows.Controls.DataGridTextColumn { Header = "Тренер", Binding = new System.Windows.Data.Binding("TrainerName"), Width = new System.Windows.Controls.DataGridLength(1.5, System.Windows.Controls.DataGridLengthUnitType.Star) });
            grid.Columns.Add(new System.Windows.Controls.DataGridTextColumn { Header = "Клиент", Binding = new System.Windows.Data.Binding("ClientName"), Width = new System.Windows.Controls.DataGridLength(1.5, System.Windows.Controls.DataGridLengthUnitType.Star) });
            grid.Columns.Add(new System.Windows.Controls.DataGridTextColumn { Header = "Мест", Binding = new System.Windows.Data.Binding("Seats"), Width = 70 });
            grid.Columns.Add(new System.Windows.Controls.DataGridTextColumn { Header = "Статус", Binding = new System.Windows.Data.Binding("StatusText"), Width = 90 });
        }

        private void Generate_Click(object sender, RoutedEventArgs e)
        {
            if (dpStart.SelectedDate == null || dpEnd.SelectedDate == null)
            {
                MessageBox.Show("Выберите даты!");
                return;
            }

            try
            {
                DateTime start = dpStart.SelectedDate.Value;
                DateTime end = dpEnd.SelectedDate.Value;

                //Получаем данные
                var groups = _repo.GetScheduleReport(start, end);
                var personals = _repo.GetPersonalReport(start, end);

                _groupData = groups.ToList();
                _personalData = personals.ToList();

                _lastReport = BuildReportData(start, end);
                _allRows = BuildRows(_lastReport);

                dgAll.ItemsSource = _allRows.OrderBy(x => x.Date).ToList();
                dgGroups.ItemsSource = _allRows.Where(x => x.Kind == "Групповая" && x.StatusText == "Активно").OrderBy(x => x.Date).ToList();
                dgPersonals.ItemsSource = _allRows.Where(x => x.Kind == "Персональная" && x.StatusText == "Активно").OrderBy(x => x.Date).ToList();
                dgCancelled.ItemsSource = _allRows.Where(x => x.StatusText != "Активно").OrderBy(x => x.Date).ToList();

                txtGroupCount.Text = _lastReport.ActiveGroups.Count.ToString();
                txtPersonalCount.Text = _lastReport.ActivePersonals.Count.ToString();
                txtCancelledCount.Text = (_lastReport.CancelledGroups.Count + _lastReport.CancelledPersonals.Count).ToString();

                var topTrainer = _lastReport.TrainerStats.FirstOrDefault();
                txtTopTrainer.Text = topTrainer.Total > 0 ? $"{topTrainer.Name} ({topTrainer.Total})" : "—";

                BuildByTrainerPanel(_lastReport);
                txtSummary.Text = $"Всего строк: {_allRows.Count}  •  Активных занятий: {_lastReport.ActiveGroups.Count + _lastReport.ActivePersonals.Count}  •  Отменено: {_lastReport.CancelledGroups.Count + _lastReport.CancelledPersonals.Count}";
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка: " + ex.Message);
            }
        }

        private static List<SessionReportRow> BuildRows(ReportData report)
        {
            var rows = new List<SessionReportRow>();

            foreach (var g in report.ActiveGroups)
            {
                rows.Add(new SessionReportRow
                {
                    Date = g.Date,
                    Title = g.Title,
                    Kind = "Групповая",
                    Type = g.Type,
                    TrainerName = g.TrainerName,
                    ClientName = string.Empty,
                    Seats = g.Seats,
                    StatusText = "Активно"
                });
            }

            foreach (var p in report.ActivePersonals)
            {
                rows.Add(new SessionReportRow
                {
                    Date = p.DateTime,
                    Title = $"Персональная: {p.ClientName}",
                    Kind = "Персональная",
                    Type = "Персональная",
                    TrainerName = p.TrainerName,
                    ClientName = p.ClientName,
                    Seats = 1,
                    StatusText = "Активно"
                });
            }

            foreach (var g in report.CancelledGroups)
            {
                rows.Add(new SessionReportRow
                {
                    Date = g.Date,
                    Title = g.Title,
                    Kind = "Групповая",
                    Type = g.Type,
                    TrainerName = g.TrainerName,
                    ClientName = string.Empty,
                    Seats = g.Seats,
                    StatusText = "ОТМЕНА"
                });
            }

            foreach (var p in report.CancelledPersonals)
            {
                rows.Add(new SessionReportRow
                {
                    Date = p.DateTime,
                    Title = $"Персональная: {p.ClientName}",
                    Kind = "Персональная",
                    Type = "Персональная",
                    TrainerName = p.TrainerName,
                    ClientName = p.ClientName,
                    Seats = 1,
                    StatusText = "ОТМЕНА"
                });
            }

            return rows;
        }

        private void BuildByTrainerPanel(ReportData report)
        {
            pnlByTrainer.Children.Clear();

            var activeRows = _allRows.Where(x => x.StatusText == "Активно").ToList();

            foreach (var stat in report.TrainerStats)
            {
                var card = new System.Windows.Controls.Border
                {
                    Margin = new Thickness(0, 0, 0, 12),
                    Padding = new Thickness(16),
                    CornerRadius = new CornerRadius(8),
                    Background = System.Windows.Media.Brushes.White,
                    BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(232, 235, 239)),
                    BorderThickness = new Thickness(1)
                };

                var stack = new System.Windows.Controls.StackPanel();
                stack.Children.Add(new System.Windows.Controls.TextBlock
                {
                    Text = $"{stat.Name} — всего {stat.Total} (групп.: {stat.GroupCount}, персон.: {stat.PersonalCount})",
                    FontSize = 15,
                    FontWeight = FontWeights.SemiBold,
                    Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(44, 62, 80))
                });

                var grid = new System.Windows.Controls.DataGrid
                {
                    AutoGenerateColumns = false,
                    IsReadOnly = true,
                    ItemsSource = activeRows.Where(x => x.TrainerName == stat.Name).OrderBy(x => x.Date).ToList(),
                    MaxHeight = 220,
                    HeadersVisibility = System.Windows.Controls.DataGridHeadersVisibility.Column
                };
                SetupRowsGridColumns(grid);
                stack.Children.Add(grid);

                card.Child = stack;
                pnlByTrainer.Children.Add(card);
            }
        }

        private void Export_Click(object sender, RoutedEventArgs e)
        {
            if (_groupData == null || _personalData == null)
            {
                MessageBox.Show("Сначала нажмите 'Сформировать'");
                return;
            }

            SaveFileDialog sfd = new SaveFileDialog
            {
                Filter = "HTML файл (*.html)|*.html",
                FileName = $"Отчет_{DateTime.Now:yyyy-MM-dd}.html"
            };

            if (sfd.ShowDialog() == true)
            {
                try
                {
                    string html = GenerateComplexHtml(dpStart.SelectedDate.Value, dpEnd.SelectedDate.Value);
                    File.WriteAllText(sfd.FileName, html);
                    MessageBox.Show("Отчет успешно сохранен!");

                    // Сразу открыть
                    var p = new System.Diagnostics.Process();
                    p.StartInfo = new System.Diagnostics.ProcessStartInfo(sfd.FileName) { UseShellExecute = true };
                    p.Start();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Ошибка сохранения: " + ex.Message);
                }
            }
        }

        private void ExportPdf_Click(object sender, RoutedEventArgs e)
        {
            if (_groupData == null || _personalData == null)
            {
                MessageBox.Show("Сначала нажмите 'Сформировать'");
                return;
            }

            SaveFileDialog sfd = new SaveFileDialog
            {
                Filter = "PDF файл (*.pdf)|*.pdf",
                FileName = $"Отчет_{DateTime.Now:yyyy-MM-dd}.pdf"
            };

            if (sfd.ShowDialog() != true) return;

            try
            {
                var start = dpStart.SelectedDate!.Value;
                var end = dpEnd.SelectedDate!.Value;
                var report = BuildReportData(start, end);
                GeneratePdfReport(sfd.FileName, start, end, report);
                MessageBox.Show("PDF-отчёт успешно сохранён.", "Экспорт", MessageBoxButton.OK, MessageBoxImage.Information);

                var process = new System.Diagnostics.Process();
                process.StartInfo = new System.Diagnostics.ProcessStartInfo(sfd.FileName) { UseShellExecute = true };
                process.Start();
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка формирования PDF: " + ex.Message, "Экспорт", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private sealed class ReportData
        {
            public List<TrainingSession> ActiveGroups { get; init; } = new();
            public List<PersonalSession> ActivePersonals { get; init; } = new();
            public List<TrainingSession> CancelledGroups { get; init; } = new();
            public List<PersonalSession> CancelledPersonals { get; init; } = new();
            public List<(string Name, int GroupCount, int PersonalCount, int Total)> TrainerStats { get; init; } = new();
        }

        private sealed class SessionReportRow
        {
            public DateTime Date { get; init; }
            public string Title { get; init; } = string.Empty;
            public string Kind { get; init; } = string.Empty;
            public string Type { get; init; } = string.Empty;
            public string TrainerName { get; init; } = string.Empty;
            public string ClientName { get; init; } = string.Empty;
            public int Seats { get; init; }
            public string StatusText { get; init; } = string.Empty;
        }

        private ReportData BuildReportData(DateTime start, DateTime end)
        {
            var activeGroups = _groupData.Where(x => !x.Title.StartsWith("ОТМЕНА:")).ToList();
            var activePersonals = _personalData.Where(x => x.Status).ToList();
            var cancelledGroups = _groupData.Where(x => x.Title.StartsWith("ОТМЕНА:")).ToList();
            var cancelledPersonals = _personalData.Where(x => !x.Status).ToList();
            var trainerStats = activeGroups.Select(g => new { Trainer = g.TrainerName, Type = "Group" })
                .Concat(activePersonals.Select(p => new { Trainer = p.TrainerName, Type = "Personal" }))
                .GroupBy(x => x.Trainer)
                .Select(g => (Name: g.Key, GroupCount: g.Count(x => x.Type == "Group"), PersonalCount: g.Count(x => x.Type == "Personal"), Total: g.Count()))
                .OrderByDescending(t => t.Total)
                .ToList();

            return new ReportData
            {
                ActiveGroups = activeGroups,
                ActivePersonals = activePersonals,
                CancelledGroups = cancelledGroups,
                CancelledPersonals = cancelledPersonals,
                TrainerStats = trainerStats
            };
        }

        private static void GeneratePdfReport(string filePath, DateTime start, DateTime end, ReportData data)
        {
            QuestPDF.Settings.License = LicenseType.Community;
            var textStyle = TextStyle.Default.FontFamily("Segoe UI").FontSize(10);
            var headerStyle = textStyle.SemiBold().FontColor(Colors.White);
            var sectionStyle = textStyle.FontSize(12).SemiBold().FontColor("#2C3E50");
            var headerFill = "#4A90E2";

            Document.Create(doc =>
            {
                doc.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(30);
                    page.DefaultTextStyle(textStyle);

                    page.Header().Column(h =>
                    {
                        h.Item().Text("DDX-48 Фитнес").Style(textStyle.FontSize(11).FontColor("#7F8C8D"));
                        h.Item().Text("Аналитический отчёт по занятиям").Style(textStyle.FontSize(18).SemiBold().FontColor("#2C3E50"));
                        h.Item().PaddingTop(4).Text($"Период: {start:dd.MM.yyyy} — {end:dd.MM.yyyy}").Style(textStyle.FontSize(11));
                        h.Item().PaddingBottom(8).LineHorizontal(1).LineColor("#E8EBEF");
                    });

                    page.Footer().AlignCenter().Text(t =>
                    {
                        t.Span("Страница ");
                        t.CurrentPageNumber();
                        t.Span(" из ");
                        t.TotalPages();
                    });

                    page.Content().Column(col =>
                    {
                        col.Spacing(14);

                        col.Item().Row(row =>
                        {
                            row.Spacing(10);
                            row.RelativeItem().Element(c => SummaryCard(c, "Групповые", data.ActiveGroups.Count.ToString()));
                            row.RelativeItem().Element(c => SummaryCard(c, "Персональные", data.ActivePersonals.Count.ToString()));
                            row.RelativeItem().Element(c => SummaryCard(c, "Отменено",
                                (data.CancelledGroups.Count + data.CancelledPersonals.Count).ToString()));
                        });

                        col.Item().Element(c => SectionTitle(c, $"Групповые тренировки ({data.ActiveGroups.Count})", sectionStyle));
                        col.Item().Element(c => BuildGroupTable(c, data.ActiveGroups, headerStyle, headerFill));

                        col.Item().Element(c => SectionTitle(c, $"Персональные тренировки ({data.ActivePersonals.Count})", sectionStyle));
                        col.Item().Element(c => BuildPersonalTable(c, data.ActivePersonals, headerStyle, headerFill));

                        col.Item().Element(c => SectionTitle(c,
                            $"Отменённые занятия ({data.CancelledGroups.Count + data.CancelledPersonals.Count})", sectionStyle));
                        col.Item().Element(c => BuildCancelledTable(c, data.CancelledGroups, data.CancelledPersonals, headerStyle, headerFill));

                        col.Item().Element(c => SectionTitle(c, "Загруженность тренеров", sectionStyle));
                        col.Item().Element(c => BuildTrainerStatsTable(c, data.TrainerStats, headerStyle, headerFill));
                    });
                });
            }).GeneratePdf(filePath);
        }

        private static void SummaryCard(IContainer container, string title, string value)
        {
            container.Border(1).BorderColor("#E8EBEF").Background("#F8FAFC").Padding(10).Column(c =>
            {
                c.Item().Text(title).FontSize(10).FontColor("#7F8C8D");
                c.Item().Text(value).FontSize(18).SemiBold().FontColor("#4A90E2");
            });
        }

        private static void SectionTitle(IContainer container, string title, TextStyle style)
        {
            container.PaddingTop(4).Text(title).Style(style);
        }

        private static IContainer PdfHeaderCell(IContainer cell, string fill) =>
            cell.Background(fill).PaddingVertical(6).PaddingHorizontal(6);

        private static IContainer PdfBodyCell(IContainer cell) =>
            cell.BorderBottom(1).BorderColor("#EEEEEE").PaddingVertical(5).PaddingHorizontal(6);

        private static void BuildGroupTable(IContainer container, List<TrainingSession> items, TextStyle headerStyle, string headerFill)
        {
            if (items.Count == 0)
            {
                container.Text("Нет данных за выбранный период.").Italic().FontColor("#95A5A6");
                return;
            }

            container.Table(table =>
            {
                table.ColumnsDefinition(c =>
                {
                    c.ConstantColumn(72);
                    c.RelativeColumn(3);
                    c.RelativeColumn(1.2f);
                    c.RelativeColumn(2);
                    c.ConstantColumn(48);
                });

                table.Header(header =>
                {
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Дата").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Название").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Тип").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Тренер").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Мест").Style(headerStyle);
                });

                foreach (var g in items)
                {
                    table.Cell().Element(PdfBodyCell).Text(g.Date.ToString("dd.MM.yyyy"));
                    table.Cell().Element(PdfBodyCell).Text(g.Title);
                    table.Cell().Element(PdfBodyCell).Text(g.Type);
                    table.Cell().Element(PdfBodyCell).Text(g.TrainerName);
                    table.Cell().Element(PdfBodyCell).Text(g.Seats.ToString());
                }
            });
        }

        private static void BuildPersonalTable(IContainer container, List<PersonalSession> items, TextStyle headerStyle, string headerFill)
        {
            if (items.Count == 0)
            {
                container.Text("Нет данных за выбранный период.").Italic().FontColor("#95A5A6");
                return;
            }

            container.Table(table =>
            {
                table.ColumnsDefinition(c =>
                {
                    c.ConstantColumn(100);
                    c.RelativeColumn(2);
                    c.RelativeColumn(2);
                });

                table.Header(header =>
                {
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Дата/время").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Клиент").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Тренер").Style(headerStyle);
                });

                foreach (var p in items)
                {
                    table.Cell().Element(PdfBodyCell).Text(p.DateTime.ToString("dd.MM.yyyy HH:mm"));
                    table.Cell().Element(PdfBodyCell).Text(p.ClientName);
                    table.Cell().Element(PdfBodyCell).Text(p.TrainerName);
                }
            });
        }

        private static void BuildCancelledTable(IContainer container, List<TrainingSession> groups, List<PersonalSession> personals, TextStyle headerStyle, string headerFill)
        {
            if (groups.Count == 0 && personals.Count == 0)
            {
                container.Text("Отменённых занятий нет.").Italic().FontColor("#95A5A6");
                return;
            }

            container.Table(table =>
            {
                table.ColumnsDefinition(c =>
                {
                    c.ConstantColumn(90);
                    c.RelativeColumn(2);
                    c.RelativeColumn(2);
                    c.ConstantColumn(70);
                });

                table.Header(header =>
                {
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Тип").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Описание").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Тренер").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Статус").Style(headerStyle);
                });

                foreach (var g in groups)
                {
                    table.Cell().Element(PdfBodyCell).Text("Групповая");
                    table.Cell().Element(PdfBodyCell).Text($"{g.Title} ({g.Date:dd.MM.yyyy})");
                    table.Cell().Element(PdfBodyCell).Text(g.TrainerName);
                    table.Cell().Element(PdfBodyCell).Text("ОТМЕНА").FontColor("#C62828");
                }
                foreach (var p in personals)
                {
                    table.Cell().Element(PdfBodyCell).Text("Персональная");
                    table.Cell().Element(PdfBodyCell).Text($"{p.ClientName} ({p.DateTime:dd.MM.yyyy})");
                    table.Cell().Element(PdfBodyCell).Text(p.TrainerName);
                    table.Cell().Element(PdfBodyCell).Text("ОТМЕНА").FontColor("#C62828");
                }
            });
        }

        private static void BuildTrainerStatsTable(IContainer container, List<(string Name, int GroupCount, int PersonalCount, int Total)> stats, TextStyle headerStyle, string headerFill)
        {
            if (stats.Count == 0)
            {
                container.Text("Нет данных.").Italic().FontColor("#95A5A6");
                return;
            }

            container.Table(table =>
            {
                table.ColumnsDefinition(c =>
                {
                    c.RelativeColumn(3);
                    c.ConstantColumn(80);
                    c.ConstantColumn(95);
                    c.ConstantColumn(60);
                });

                table.Header(header =>
                {
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Тренер").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Групповых").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Персональных").Style(headerStyle);
                    header.Cell().Element(c => PdfHeaderCell(c, headerFill)).Text("Всего").Style(headerStyle);
                });

                foreach (var s in stats)
                {
                    table.Cell().Element(PdfBodyCell).Text(s.Name).SemiBold();
                    table.Cell().Element(PdfBodyCell).Text(s.GroupCount.ToString());
                    table.Cell().Element(PdfBodyCell).Text(s.PersonalCount.ToString());
                    table.Cell().Element(PdfBodyCell).Text(s.Total.ToString()).SemiBold();
                }
            });
        }

        private string GenerateComplexHtml(DateTime start, DateTime end)
        {
            // Фильтр
            var activeGroups = _groupData.Where(x => !x.Title.StartsWith("ОТМЕНА:")).ToList();


            var activePersonals = _personalData.Where(x => x.Status).ToList();


            var cancelledGroups = _groupData.Where(x => x.Title.StartsWith("ОТМЕНА:")).ToList();
            var cancelledPersonals = _personalData.Where(x => !x.Status).ToList();

            // Загруженность
            var trainerStats = activeGroups.Select(g => new { Trainer = g.TrainerName, Type = "Group" })
                .Concat(activePersonals.Select(p => new { Trainer = p.TrainerName, Type = "Personal" }))
                .GroupBy(x => x.Trainer)
                .Select(g => new
                {
                    Name = g.Key,
                    GroupCount = g.Count(x => x.Type == "Group"),
                    PersonalCount = g.Count(x => x.Type == "Personal"),
                    Total = g.Count()
                })
                .OrderByDescending(t => t.Total)
                .ToList();

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("<!DOCTYPE html><html lang='ru'><head><meta charset='UTF-8'>");
            sb.AppendLine("<title>Отчет</title>");

            // Стили
            sb.AppendLine("<style>");
            sb.AppendLine("body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 20px; background: #f4f5f7; color: #333; }");
            sb.AppendLine("h1 { color: #2c3e50; text-align: center; }");
            sb.AppendLine("h2 { color: #4a90e2; border-bottom: 2px solid #4a90e2; padding-bottom: 10px; margin-top: 40px; }");
            sb.AppendLine(".card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); margin-bottom: 20px; }");
            sb.AppendLine("table { width: 100%; border-collapse: collapse; margin-top: 10px; }");
            sb.AppendLine("th, td { border-bottom: 1px solid #eee; padding: 12px; text-align: left; }");
            sb.AppendLine("th { background-color: #f8f9fa; color: #7f8c8d; font-weight: 600; }");
            sb.AppendLine("tr:hover { background-color: #f1f1f1; }");
            sb.AppendLine(".badge-cancel { background: #ffebee; color: #c62828; padding: 4px 8px; border-radius: 4px; font-size: 0.9em; }");
            sb.AppendLine(".chart-container { width: 100%; height: 400px; margin: 0 auto; }");
            sb.AppendLine("</style>");

            // График
            sb.AppendLine("<script type='text/javascript' src='https://www.gstatic.com/charts/loader.js'></script>");
            sb.AppendLine("<script type='text/javascript'>");
            sb.AppendLine("google.charts.load('current', {'packages':['corechart']});");
            sb.AppendLine("google.charts.setOnLoadCallback(drawChart);");
            sb.AppendLine("function drawChart() {");

            sb.AppendLine("var data = google.visualization.arrayToDataTable([");
            sb.AppendLine("['Тип', 'Количество'],");
            sb.AppendLine($"['Групповые', {activeGroups.Count}],");
            sb.AppendLine($"['Персональные', {activePersonals.Count}]");
            sb.AppendLine("]);");

            sb.AppendLine("var options = { title: 'Соотношение тренировок', pieHole: 0.4, colors: ['#4a90e2', '#27ae60'] };");
            sb.AppendLine("var chart = new google.visualization.PieChart(document.getElementById('piechart'));");
            sb.AppendLine("chart.draw(data, options);");
            sb.AppendLine("}");
            sb.AppendLine("</script>");

            sb.AppendLine("</head><body>");

            sb.AppendLine($"<h1>Отчет по работе фитнес-центра</h1>");
            sb.AppendLine($"<p style='text-align:center'>Период: <b>{start:dd.MM.yyyy}</b> — <b>{end:dd.MM.yyyy}</b></p>");

            // 1.Групповые
            sb.AppendLine("<div class='card'>");
            sb.AppendLine($"<h2>Групповые тренировки (Всего: {activeGroups.Count})</h2>");
            if (activeGroups.Count > 0)
            {
                sb.AppendLine("<table><thead><tr><th>Дата</th><th>Название</th><th>Тип</th><th>Тренер</th><th>Мест занято</th></tr></thead><tbody>");
                foreach (var item in activeGroups)
                {
                    sb.AppendLine($"<tr><td>{item.Date:dd.MM.yyyy}</td><td>{item.Title}</td><td>{item.Type}</td><td>{item.TrainerName}</td><td>{item.Seats}</td></tr>");
                }
                sb.AppendLine("</tbody></table>");
            }
            else sb.AppendLine("<p>Нет данных.</p>");
            sb.AppendLine("</div>");

            // 2.Персональные
            sb.AppendLine("<div class='card'>");
            sb.AppendLine($"<h2>Персональные тренировки (Всего: {activePersonals.Count})</h2>");
            if (activePersonals.Count > 0)
            {
                sb.AppendLine("<table><thead><tr><th>Дата/Время</th><th>Клиент</th><th>Тренер</th></tr></thead><tbody>");
                foreach (var item in activePersonals)
                {
                    sb.AppendLine($"<tr><td>{item.DateTime:dd.MM.yyyy HH:mm}</td><td>{item.ClientName}</td><td>{item.TrainerName}</td></tr>");
                }
                sb.AppendLine("</tbody></table>");
            }
            else sb.AppendLine("<p>Нет данных.</p>");
            sb.AppendLine("</div>");

            // 3. Отмененные
            sb.AppendLine("<div class='card'>");
            sb.AppendLine($"<h2>Отмененные занятия (Всего: {cancelledGroups.Count + cancelledPersonals.Count})</h2>");
            sb.AppendLine("<table><thead><tr><th>Тип</th><th>Инфо</th><th>Тренер</th><th>Статус</th></tr></thead><tbody>");

            foreach (var g in cancelledGroups)
            {
                sb.AppendLine($"<tr><td>Групповая</td><td>{g.Title} ({g.Date:dd.MM})</td><td>{g.TrainerName}</td><td><span class='badge-cancel'>ОТМЕНА</span></td></tr>");
            }
            foreach (var p in cancelledPersonals)
            {
                sb.AppendLine($"<tr><td>Персональная</td><td>Клиент: {p.ClientName} ({p.DateTime:dd.MM})</td><td>{p.TrainerName}</td><td><span class='badge-cancel'>ОТМЕНА</span></td></tr>");
            }
            sb.AppendLine("</tbody></table>");
            sb.AppendLine("</div>");

            // 4. Загруженность
            sb.AppendLine("<div class='card'>");
            sb.AppendLine("<h2>Загруженность тренеров</h2>");
            sb.AppendLine("<table><thead><tr><th>ФИО Тренера</th><th>Групповых</th><th>Персональных</th><th>ВСЕГО</th></tr></thead><tbody>");
            foreach (var stat in trainerStats)
            {
                sb.AppendLine($"<tr><td><b>{stat.Name}</b></td><td>{stat.GroupCount}</td><td>{stat.PersonalCount}</td><td><b>{stat.Total}</b></td></tr>");
            }
            sb.AppendLine("</tbody></table>");
            sb.AppendLine("</div>");

            // 5. График
            sb.AppendLine("<div class='card'>");
            sb.AppendLine("<h2>Статистика (График)</h2>");
            sb.AppendLine("<div id='piechart' class='chart-container'></div>");
            sb.AppendLine("</div>");

            sb.AppendLine("</body></html>");
            return sb.ToString();
        }

        private void Close_Click(object sender, RoutedEventArgs e) => Close();
    }
}
