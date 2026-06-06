using Lab2BD1_WPF.Models;
using Lab2BD1_WPF.Repositories;
using Microsoft.Win32;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;

namespace Lab2BD1_WPF.Views
{
    public partial class SubscriptionReportWindow : Window
    {
        private readonly FitnessRepository _repo = new();
        private List<SubscriptionReportRow> _data = new();
        private SubscriptionReportAnalytics? _analytics;

        public SubscriptionReportWindow()
        {
            InitializeComponent();
            dpStart.SelectedDate = new DateTime(DateTime.Now.Year, 1, 1);
            dpEnd.SelectedDate = DateTime.Now;
            SetupGridColumns(dgAll);
            SetupGridColumns(dgActive);
            SetupGridColumns(dgInactive);
        }

        private static void SetupGridColumns(DataGrid grid)
        {
            grid.Columns.Add(new DataGridTextColumn { Header = "Клиент", Binding = new System.Windows.Data.Binding("ClientName"), Width = new DataGridLength(2, DataGridLengthUnitType.Star) });
            grid.Columns.Add(new DataGridTextColumn { Header = "Тип", Binding = new System.Windows.Data.Binding("SubscriptionType"), Width = 100 });
            grid.Columns.Add(new DataGridTextColumn { Header = "Цена", Binding = new System.Windows.Data.Binding("PaymentAmount") { StringFormat = "{0:N0} ₽" }, Width = 90 });
            grid.Columns.Add(new DataGridTextColumn { Header = "Срок", Binding = new System.Windows.Data.Binding("PeriodDays"), Width = 60 });
            grid.Columns.Add(new DataGridTextColumn { Header = "Статус", Binding = new System.Windows.Data.Binding("StatusText"), Width = 100 });
            grid.Columns.Add(new DataGridTextColumn { Header = "Админ", Binding = new System.Windows.Data.Binding("AdminName"), Width = new DataGridLength(1, DataGridLengthUnitType.Star) });
            grid.Columns.Add(new DataGridTextColumn { Header = "Дата оплаты", Binding = new System.Windows.Data.Binding("PaymentDate") { StringFormat = "dd.MM.yyyy" }, Width = 100 });
            grid.Columns.Add(new DataGridTextColumn { Header = "Способ", Binding = new System.Windows.Data.Binding("PaymentMethod"), Width = 90 });
        }

        private void Generate_Click(object sender, RoutedEventArgs e)
        {
            if (dpStart.SelectedDate == null || dpEnd.SelectedDate == null)
            {
                MessageBox.Show("Укажите период отчёта.");
                return;
            }

            try
            {
                var start = dpStart.SelectedDate.Value.Date;
                var end = dpEnd.SelectedDate.Value.Date;
                if (start > end)
                {
                    MessageBox.Show("Дата начала не может быть позже даты окончания.");
                    return;
                }

                _data = _repo.GetSubscriptionSalesReport(start, end).ToList();
                _analytics = SubscriptionReportAnalytics.From(_data);

                dgAll.ItemsSource = _data;
                dgActive.ItemsSource = _analytics.ActiveRows;
                dgInactive.ItemsSource = _analytics.InactiveRows;
                BuildByTypePanel();
                // вкладка "Диаграммы" удалена из UI

                txtActiveCount.Text = _analytics.ActiveSubscriptionCount.ToString();
                txtInactiveCount.Text = _analytics.InactiveSubscriptionCount.ToString();
                txtTotalRevenue.Text = $"{_analytics.TotalPaymentAmount:N0} ₽";
                txtTopType.Text = _analytics.TopSubscriptionType;
                txtSummary.Text = $"Всего строк: {_data.Count}  •  Уникальных абонементов: {_analytics.UniqueSubscriptionCount}  •  Платежей: {_analytics.PaymentCount}";
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка формирования отчёта: " + ex.Message);
            }
        }

        private void BuildByTypePanel()
        {
            pnlByType.Children.Clear();
            if (_analytics == null) return;

            foreach (var group in _analytics.ByType)
            {
                var card = new Border
                {
                    Margin = new Thickness(0, 0, 0, 12),
                    Padding = new Thickness(16),
                    CornerRadius = new CornerRadius(8),
                    Background = System.Windows.Media.Brushes.White,
                    BorderBrush = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(232, 235, 239)),
                    BorderThickness = new Thickness(1)
                };
                var stack = new StackPanel();
                stack.Children.Add(new TextBlock
                {
                    Text = $"{group.Type} — {group.SubscriptionCount} абон., платежей на {group.PaymentSum:N0} ₽",
                    FontSize = 15,
                    FontWeight = FontWeights.SemiBold,
                    Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(44, 62, 80))
                });
                stack.Children.Add(new TextBlock
                {
                    Text = $"Активных: {group.ActiveCount}  •  Неактивных: {group.InactiveCount}",
                    Margin = new Thickness(0, 6, 0, 8),
                    Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(127, 140, 141))
                });

                var grid = new DataGrid
                {
                    AutoGenerateColumns = false,
                    IsReadOnly = true,
                    ItemsSource = group.Rows,
                    MaxHeight = 220,
                    HeadersVisibility = DataGridHeadersVisibility.Column
                };
                SetupGridColumns(grid);
                stack.Children.Add(grid);
                card.Child = stack;
                pnlByType.Children.Add(card);
            }
        }

        private void ExportHtml_Click(object sender, RoutedEventArgs e) => ExportReport(isPdf: false);
        private void ExportPdf_Click(object sender, RoutedEventArgs e) => ExportReport(isPdf: true);

        private void ExportReport(bool isPdf)
        {
            if (_data.Count == 0 || _analytics == null)
            {
                MessageBox.Show("Сначала сформируйте отчёт.");
                return;
            }

            var start = dpStart.SelectedDate!.Value;
            var end = dpEnd.SelectedDate!.Value;
            var dialog = new SaveFileDialog
            {
                Filter = isPdf ? "PDF (*.pdf)|*.pdf" : "HTML (*.html)|*.html",
                FileName = $"Абонементы_{DateTime.Now:yyyy-MM-dd}" + (isPdf ? ".pdf" : ".html")
            };

            if (dialog.ShowDialog() != true) return;

            try
            {
                if (isPdf)
                    GeneratePdf(dialog.FileName, start, end, _data, _analytics);
                else
                    File.WriteAllText(dialog.FileName, BuildFullHtml(start, end, _data, _analytics), Encoding.UTF8);

                MessageBox.Show("Отчёт сохранён.");
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(dialog.FileName) { UseShellExecute = true });
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка сохранения: " + ex.Message);
            }
        }

        private static string BuildChartsHtml(DateTime start, DateTime end, SubscriptionReportAnalytics analytics)
        {
            var statusPie = $"['Активные', {analytics.ActiveSubscriptionCount}],['Неактивные', {analytics.InactiveSubscriptionCount}]";
            var typeBar = string.Join(",", analytics.ByType.Select(t => $"['{EscapeJs(t.Type)}', {t.SubscriptionCount}]"));
            var monthBar = string.Join(",", analytics.PaymentsByMonth.Select(m => $"['{EscapeJs(m.Label)}', {m.Amount}]"));
            var methodPie = string.Join(",", analytics.ByPaymentMethod.Select(m => $"['{EscapeJs(m.Method)}', {m.Count}]"));

            var sb = new StringBuilder();
            sb.AppendLine("<!DOCTYPE html><html><head><meta charset='UTF-8'>");
            sb.AppendLine("<script src='https://www.gstatic.com/charts/loader.js'></script>");
            sb.AppendLine("<style>body{font-family:Segoe UI,sans-serif;margin:16px;background:#f7f9fc}h2{color:#27ae60}</style>");
            sb.AppendLine("<script>google.charts.load('current',{packages:['corechart']});google.charts.setOnLoadCallback(draw);");
            sb.AppendLine("function draw(){");
            sb.AppendLine($"drawPie('chartStatus',[{statusPie}],'Статус абонементов');");
            sb.AppendLine($"drawBar('chartType',[{typeBar}],'Абонементы по типу');");
            sb.AppendLine($"drawBar('chartMonth',[{monthBar}],'Платежи по месяцам');");
            sb.AppendLine($"drawPie('chartMethod',[{methodPie}],'Способы оплаты');");
            sb.AppendLine("}");
            sb.AppendLine("function drawPie(id,data,title){var t=google.visualization.arrayToDataTable([['Категория','Кол-во']].concat(data));");
            sb.AppendLine("new google.visualization.PieChart(document.getElementById(id)).draw(t,{title:title,pieHole:0.4,colors:['#27ae60','#e74c3c','#4a90e2','#f39c12']});}");
            sb.AppendLine("function drawBar(id,data,title){var t=google.visualization.arrayToDataTable([['Категория','Значение']].concat(data));");
            sb.AppendLine("new google.visualization.ColumnChart(document.getElementById(id)).draw(t,{title:title,colors:['#4a90e2'],legend:'none'});}");
            sb.AppendLine("</script></head><body>");
            sb.AppendLine($"<h2>Аналитика абонементов ({start:dd.MM.yyyy} — {end:dd.MM.yyyy})</h2>");
            sb.AppendLine("<div style='display:grid;grid-template-columns:1fr 1fr;gap:16px'>");
            sb.AppendLine("<div id='chartStatus' style='height:320px;background:#fff;border-radius:8px;padding:8px'></div>");
            sb.AppendLine("<div id='chartMethod' style='height:320px;background:#fff;border-radius:8px;padding:8px'></div>");
            sb.AppendLine("<div id='chartType' style='height:320px;background:#fff;border-radius:8px;padding:8px'></div>");
            sb.AppendLine("<div id='chartMonth' style='height:320px;background:#fff;border-radius:8px;padding:8px'></div>");
            sb.AppendLine("</div></body></html>");
            return sb.ToString();
        }

        private static string BuildFullHtml(DateTime start, DateTime end, List<SubscriptionReportRow> data, SubscriptionReportAnalytics analytics)
        {
            var sb = new StringBuilder();
            sb.AppendLine("<!DOCTYPE html><html lang='ru'><head><meta charset='UTF-8'><title>Отчёт по абонементам</title>");
            sb.AppendLine("<script src='https://www.gstatic.com/charts/loader.js'></script>");
            sb.AppendLine("<style>");
            sb.AppendLine("body{font-family:'Segoe UI',sans-serif;padding:24px;background:#f4f5f7;color:#2c3e50}");
            sb.AppendLine("h1,h2{color:#27ae60}.card{background:#fff;padding:16px;border-radius:8px;margin-bottom:16px;box-shadow:0 1px 4px rgba(0,0,0,.08)}");
            sb.AppendLine("table{width:100%;border-collapse:collapse}th,td{padding:10px;border-bottom:1px solid #eee;text-align:left}");
            sb.AppendLine("th{background:#27ae60;color:#fff}.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:16px 0}");
            sb.AppendLine(".stat{background:#fff;padding:14px;border-radius:8px}.stat b{font-size:22px;color:#27ae60;display:block}");
            sb.AppendLine(".badge-a{background:#e8f8f0;color:#27ae60;padding:3px 8px;border-radius:4px}.badge-i{background:#fdecea;color:#c62828;padding:3px 8px;border-radius:4px}");
            sb.AppendLine(".charts{display:grid;grid-template-columns:1fr 1fr;gap:16px}");
            sb.AppendLine("</style></head><body>");
            sb.AppendLine("<h1>Отчёт по проданным абонементам</h1>");
            sb.AppendLine($"<p>Период: <b>{start:dd.MM.yyyy}</b> — <b>{end:dd.MM.yyyy}</b></p>");
            sb.AppendLine("<div class='stats'>");
            sb.AppendLine($"<div class='stat'>Активные<b>{analytics.ActiveSubscriptionCount}</b></div>");
            sb.AppendLine($"<div class='stat'>Неактивные<b>{analytics.InactiveSubscriptionCount}</b></div>");
            sb.AppendLine($"<div class='stat'>Сумма платежей<b>{analytics.TotalPaymentAmount:N0} ₽</b></div>");
            sb.AppendLine($"<div class='stat'>Популярный тип<b>{analytics.TopSubscriptionType}</b></div>");
            sb.AppendLine("</div>");

            AppendChartScripts(sb, analytics);
            sb.AppendLine("<div class='card'><h2>Диаграммы</h2><div class='charts'>");
            sb.AppendLine("<div id='c1' style='height:300px'></div><div id='c2' style='height:300px'></div>");
            sb.AppendLine("<div id='c3' style='height:300px'></div><div id='c4' style='height:300px'></div></div></div>");

            AppendTableSection(sb, "Активные абонементы", analytics.ActiveRows);
            AppendTableSection(sb, "Неактивные абонементы", analytics.InactiveRows);
            foreach (var g in analytics.ByType)
                AppendTableSection(sb, $"Тип: {g.Type} ({g.SubscriptionCount} шт.)", g.Rows);

            sb.AppendLine("</body></html>");
            return sb.ToString();
        }

        private static void AppendChartScripts(StringBuilder sb, SubscriptionReportAnalytics a)
        {
            var status = $"['Активные',{a.ActiveSubscriptionCount}],['Неактивные',{a.InactiveSubscriptionCount}]";
            var types = string.Join(",", a.ByType.Select(t => $"['{EscapeJs(t.Type)}',{t.SubscriptionCount}]"));
            var months = string.Join(",", a.PaymentsByMonth.Select(m => $"['{EscapeJs(m.Label)}',{m.Amount}]"));
            var methods = string.Join(",", a.ByPaymentMethod.Select(m => $"['{EscapeJs(m.Method)}',{m.Count}]"));
            sb.AppendLine("<script>google.charts.load('current',{packages:['corechart']});google.charts.setOnLoadCallback(function(){");
            sb.AppendLine($"pie('c1',[{status}],'Статус');bar('c3',[{types}],'По типам');bar('c4',[{months}],'По месяцам');pie('c2',[{methods}],'Оплата');}});");
            sb.AppendLine("function pie(id,d,t){var dt=google.visualization.arrayToDataTable([['X','Y']].concat(d));new google.visualization.PieChart(document.getElementById(id)).draw(dt,{title:t,pieHole:.35,colors:['#27ae60','#e74c3c','#4a90e2']});}");
            sb.AppendLine("function bar(id,d,t){var dt=google.visualization.arrayToDataTable([['X','Y']].concat(d));new google.visualization.ColumnChart(document.getElementById(id)).draw(dt,{title:t,colors:['#4a90e2'],legend:'none'});}");
            sb.AppendLine("</script>");
        }

        private static void AppendTableSection(StringBuilder sb, string title, List<SubscriptionReportRow> rows)
        {
            sb.AppendLine($"<div class='card'><h2>{title}</h2>");
            if (rows.Count == 0) { sb.AppendLine("<p>Нет данных.</p></div>"); return; }
            sb.AppendLine("<table><thead><tr><th>Клиент</th><th>Тип</th><th>Цена</th><th>Срок</th><th>Статус</th><th>Оплата</th><th>Способ</th></tr></thead><tbody>");
            foreach (var r in rows)
            {
                var badge = r.StatusText == "Активен" ? "badge-a" : "badge-i";
                sb.AppendLine($"<tr><td>{r.ClientName}</td><td>{r.SubscriptionType}</td>");
                sb.AppendLine($"<td>{(r.PaymentAmount.HasValue ? $"{r.PaymentAmount:N0} ₽" : "—")}</td><td>{r.PeriodDays}</td>");
                sb.AppendLine($"<td><span class='{badge}'>{r.StatusText}</span></td>");
                sb.AppendLine($"<td>{r.PaymentDate?.ToString("dd.MM.yyyy") ?? "—"}</td><td>{r.PaymentMethod}</td></tr>");
            }
            sb.AppendLine("</tbody></table></div>");
        }

        private static void GeneratePdf(string path, DateTime start, DateTime end, List<SubscriptionReportRow> data, SubscriptionReportAnalytics analytics)
        {
            QuestPDF.Settings.License = LicenseType.Community;
            var text = TextStyle.Default.FontFamily("Segoe UI").FontSize(9);
            var header = text.SemiBold().FontColor(Colors.White);

            Document.Create(doc =>
            {
                doc.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(28);
                    page.DefaultTextStyle(text);
                    page.Content().Column(col =>
                    {
                        col.Spacing(10);
                        col.Item().Text("DDX-48 Фитнес").Style(text.FontSize(10).FontColor("#7F8C8D"));
                        col.Item().Text("Отчёт по проданным абонементам").Style(text.FontSize(16).SemiBold());
                        col.Item().Text($"Период: {start:dd.MM.yyyy} — {end:dd.MM.yyyy}");

                        col.Item().Row(row =>
                        {
                            row.RelativeItem().Element(c => StatBox(c, "Активные", analytics.ActiveSubscriptionCount.ToString(), "#27AE60"));
                            row.RelativeItem().Element(c => StatBox(c, "Неактивные", analytics.InactiveSubscriptionCount.ToString(), "#E74C3C"));
                            row.RelativeItem().Element(c => StatBox(c, "Платежи", $"{analytics.TotalPaymentAmount:N0} ₽", "#4A90E2"));
                            row.RelativeItem().Element(c => StatBox(c, "Топ тип", analytics.TopSubscriptionType, "#2C3E50"));
                        });

                        col.Item().PaddingTop(8).Text("Распределение по типам абонементов").SemiBold();
                        col.Item().Element(c => DrawBarChart(c, analytics.ByType.Select(x => (x.Type, (float)x.SubscriptionCount)).ToList(), "#4A90E2"));

                        col.Item().PaddingTop(8).Text("Платежи по месяцам").SemiBold();
                        col.Item().Element(c => DrawBarChart(c, analytics.PaymentsByMonth.Select(x => (x.Label, (float)x.Amount)).ToList(), "#27AE60"));

                        col.Item().PageBreak();
                        col.Item().Text("Активные абонементы").Style(text.FontSize(12).SemiBold().FontColor("#27AE60"));
                        col.Item().Element(c => BuildPdfTable(c, analytics.ActiveRows, header));

                        col.Item().PaddingTop(12).Text("Неактивные абонементы").Style(text.FontSize(12).SemiBold().FontColor("#E74C3C"));
                        col.Item().Element(c => BuildPdfTable(c, analytics.InactiveRows, header));
                    });
                    page.Footer().AlignCenter().Text(t => { t.Span("Стр. "); t.CurrentPageNumber(); t.TotalPages(); });
                });
            }).GeneratePdf(path);
        }

        private static void StatBox(IContainer c, string label, string value, string color)
        {
            c.Border(1).BorderColor("#E8EBEF").Padding(8).Column(col =>
            {
                col.Item().Text(label).FontSize(8).FontColor("#7F8C8D");
                col.Item().Text(value).FontSize(14).SemiBold().FontColor(color);
            });
        }

        private static void DrawBarChart(IContainer container, List<(string Label, float Value)> items, string color)
        {
            if (items.Count == 0) { container.Text("Нет данных."); return; }
            var max = items.Max(i => i.Value);
            if (max <= 0) max = 1;
            container.Column(col =>
            {
                foreach (var item in items.Take(8))
                {
                    var share = (int)Math.Round(item.Value / max * 100);
                    col.Item().PaddingVertical(2).Text($"{item.Label}: {item.Value:N0} ({share}%)").FontSize(8);
                    col.Item().Row(row =>
                    {
                        row.RelativeItem(share).Height(12).Background(color);
                        row.RelativeItem(100 - share);
                    });
                }
            });
        }

        private static void BuildPdfTable(IContainer container, List<SubscriptionReportRow> rows, TextStyle headerStyle)
        {
            if (rows.Count == 0) { container.Text("Нет данных.").Italic(); return; }
            container.Table(table =>
            {
                table.ColumnsDefinition(c =>
                {
                    c.RelativeColumn(2); c.ConstantColumn(55); c.ConstantColumn(60); c.ConstantColumn(45);
                    c.ConstantColumn(50); c.RelativeColumn(1); c.ConstantColumn(60);
                });
                table.Header(h =>
                {
                    void H(string t) => h.Cell().Element(x => PdfHead(x)).Text(t).Style(headerStyle);
                    H("Клиент"); H("Тип"); H("Цена"); H("Срок"); H("Статус"); H("Оплата"); H("Способ");
                });
                foreach (var r in rows.Take(40))
                {
                    table.Cell().Element(PdfBody).Text(r.ClientName);
                    table.Cell().Element(PdfBody).Text(r.SubscriptionType);
                    table.Cell().Element(PdfBody).Text(r.PaymentAmount.HasValue ? $"{r.PaymentAmount:N0}" : "—");
                    table.Cell().Element(PdfBody).Text(r.PeriodDays.ToString());
                    table.Cell().Element(PdfBody).Text(r.StatusText);
                    table.Cell().Element(PdfBody).Text(r.PaymentDate?.ToString("dd.MM.yyyy") ?? "—");
                    table.Cell().Element(PdfBody).Text(r.PaymentMethod);
                }
            });
        }

        private static IContainer PdfHead(IContainer c) => c.Background("#27AE60").Padding(4);
        private static IContainer PdfBody(IContainer c) => c.BorderBottom(1).BorderColor("#EEE").Padding(3);
        private static string EscapeJs(string s) => s.Replace("'", "\\'");

        private void Close_Click(object sender, RoutedEventArgs e) => Close();
    }

    internal sealed class SubscriptionReportAnalytics
    {
        public List<SubscriptionReportRow> ActiveRows { get; init; } = new();
        public List<SubscriptionReportRow> InactiveRows { get; init; } = new();
        public List<SubscriptionTypeGroup> ByType { get; init; } = new();
        public List<PaymentMonthGroup> PaymentsByMonth { get; init; } = new();
        public List<PaymentMethodGroup> ByPaymentMethod { get; init; } = new();
        public int ActiveSubscriptionCount { get; init; }
        public int InactiveSubscriptionCount { get; init; }
        public int UniqueSubscriptionCount { get; init; }
        public int PaymentCount { get; init; }
        public decimal TotalPaymentAmount { get; init; }
        public string TopSubscriptionType { get; init; } = "—";

        public static SubscriptionReportAnalytics From(List<SubscriptionReportRow> data)
        {
            var subscriptionRows = data.Where(x => x.SubscriptionId > 0).ToList();
            var unique = subscriptionRows.GroupBy(x => x.SubscriptionId).Select(g => g.First()).ToList();
            var activeRows = subscriptionRows.Where(x => x.StatusText == "Активен").ToList();
            var inactiveRows = subscriptionRows.Where(x => x.StatusText == "Неактивен").ToList();
            var uniquePayments = data.Where(x => x.PaymentNumber.HasValue)
                .GroupBy(x => x.PaymentNumber!.Value)
                .Select(g => g.First())
                .ToList();

            var byType = subscriptionRows.Where(x => !string.IsNullOrWhiteSpace(x.SubscriptionType)).GroupBy(x => x.SubscriptionType).Select(g => new SubscriptionTypeGroup
            {
                Type = g.Key,
                Rows = g.ToList(),
                SubscriptionCount = g.Select(x => x.SubscriptionId).Distinct().Count(),
                ActiveCount = g.Where(x => x.StatusText == "Активен").Select(x => x.SubscriptionId).Distinct().Count(),
                InactiveCount = g.Where(x => x.StatusText == "Неактивен").Select(x => x.SubscriptionId).Distinct().Count(),
                PaymentSum = g.Where(x => x.PaymentNumber.HasValue && x.PaymentAmount.HasValue)
                    .GroupBy(x => x.PaymentNumber!.Value)
                    .Sum(pg => pg.First().PaymentAmount!.Value)
            }).OrderByDescending(x => x.SubscriptionCount).ToList();

            var paymentsByMonth = uniquePayments.Where(x => x.PaymentDate.HasValue && x.PaymentAmount.HasValue)
                .GroupBy(x => new { x.PaymentDate!.Value.Year, x.PaymentDate!.Value.Month })
                .OrderBy(x => x.Key.Year).ThenBy(x => x.Key.Month)
                .Select(g => new PaymentMonthGroup
                {
                    Label = $"{g.Key.Month:00}.{g.Key.Year}",
                    Amount = g.Sum(x => x.PaymentAmount!.Value)
                }).ToList();

            var byMethod = uniquePayments.Where(x => !string.IsNullOrWhiteSpace(x.PaymentMethod))
                .GroupBy(x => x.PaymentMethod)
                .Select(g => new PaymentMethodGroup { Method = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count).ToList();

            return new SubscriptionReportAnalytics
            {
                ActiveRows = activeRows,
                InactiveRows = inactiveRows,
                ByType = byType,
                PaymentsByMonth = paymentsByMonth,
                ByPaymentMethod = byMethod,
                ActiveSubscriptionCount = unique.Count(x => x.StatusText == "Активен"),
                InactiveSubscriptionCount = unique.Count(x => x.StatusText == "Неактивен"),
                UniqueSubscriptionCount = unique.Count,
                PaymentCount = uniquePayments.Count,
                TotalPaymentAmount = uniquePayments.Where(x => x.PaymentAmount.HasValue).Sum(x => x.PaymentAmount!.Value),
                TopSubscriptionType = byType.FirstOrDefault()?.Type ?? "—"
            };
        }
    }

    internal sealed class SubscriptionTypeGroup
    {
        public string Type { get; init; } = string.Empty;
        public List<SubscriptionReportRow> Rows { get; init; } = new();
        public int SubscriptionCount { get; init; }
        public int ActiveCount { get; init; }
        public int InactiveCount { get; init; }
        public decimal PaymentSum { get; init; }
    }

    internal sealed class PaymentMonthGroup
    {
        public string Label { get; init; } = string.Empty;
        public decimal Amount { get; init; }
    }

    internal sealed class PaymentMethodGroup
    {
        public string Method { get; init; } = string.Empty;
        public int Count { get; init; }
    }
}
