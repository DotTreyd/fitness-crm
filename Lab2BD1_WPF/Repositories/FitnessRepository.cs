using Lab2BD1_WPF.Models;
using Npgsql;
using System;
using System.Collections.ObjectModel;
using System.Linq;

namespace Lab2BD1_WPF.Repositories
{
    public class FitnessRepository
    {
        private readonly string _connString = "Host=localhost;Username=postgres;Password=student;Database=GymDB";

        private const string AdminPassword = "admin123";
        private const string TrainerPassword = "trainer123";

        public User? AuthenticateUser(string login, string password, out int? instructorId)
        {
            instructorId = null;
            login = (login ?? string.Empty).Trim();
            password = password ?? string.Empty;

            using var conn = new NpgsqlConnection(_connString);
            conn.Open();

            if (password == AdminPassword)
            {
                const string adminSql = @"SELECT admin_id, admin_email, admin_full_name
                                          FROM admin
                                          WHERE LOWER(admin_email) = LOWER(@login)";
                using var cmd = new NpgsqlCommand(adminSql, conn);
                cmd.Parameters.AddWithValue("login", login);
                using var r = cmd.ExecuteReader();
                if (r.Read())
                {
                    return new User(r.GetString(1), password, Role.Admin, r.GetInt32(0));
                }
            }

            if (password == TrainerPassword && int.TryParse(login, out var instructorNumber))
            {
                const string trainerSql = @"SELECT instructor_number, instructor_full_name
                                            FROM instructor
                                            WHERE instructor_number = @id";
                using var cmd = new NpgsqlCommand(trainerSql, conn);
                cmd.Parameters.AddWithValue("id", instructorNumber);
                using var r = cmd.ExecuteReader();
                if (r.Read())
                {
                    instructorId = Convert.ToInt32(r.GetDecimal(0));
                    return new User(instructorId.Value.ToString(), password, Role.Trainer);
                }
            }

            return null;
        }

        public ObservableCollection<TrainingSession> GetSchedule()
        {
            var list = new ObservableCollection<TrainingSession>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"
                SELECT s.schedule_id, s.schedule_name, i.instructor_full_name, s.schedule_time, s.schedule_number_of_seats, s.schedule_type, s.instructor_number, s.admin_id
                FROM schedule s
                JOIN instructor i ON s.instructor_number = i.instructor_number
                ORDER BY s.schedule_time DESC, s.schedule_id DESC";

            using var cmd = new NpgsqlCommand(sql, conn);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new TrainingSession
                {
                    Id = r.GetInt32(0),
                    Title = r.GetString(1),
                    TrainerName = r.GetString(2),
                    Date = r.GetDateTime(3),
                    Seats = Convert.ToInt32(r.GetDecimal(4)),
                    Type = r.GetString(5),
                    InstructorId = Convert.ToInt32(r.GetDecimal(6)),
                    AdminId = r.GetInt32(7)
                });
            }
            return list;
        }

        public ObservableCollection<InstructorShort> GetInstructors()
        {
            var list = new ObservableCollection<InstructorShort>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "SELECT instructor_number, instructor_full_name FROM instructor ORDER BY instructor_full_name";
            using var cmd = new NpgsqlCommand(sql, conn);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new InstructorShort { Id = Convert.ToInt32(r.GetDecimal(0)), Name = r.GetString(1) });
            }
            return list;
        }

        public string GetUserFullName(User user, int? instructorId)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();

            if (user.Role == Role.Trainer && instructorId.HasValue)
            {
                const string trainerSql = "SELECT instructor_full_name FROM instructor WHERE instructor_number = @id";
                using var trainerCmd = new NpgsqlCommand(trainerSql, conn);
                trainerCmd.Parameters.AddWithValue("id", instructorId.Value);
                return trainerCmd.ExecuteScalar()?.ToString() ?? user.Login;
            }

            if (user.Role == Role.Admin && user.AdminId.HasValue)
            {
                const string adminSql = "SELECT admin_full_name FROM admin WHERE admin_id = @id";
                using var adminCmd = new NpgsqlCommand(adminSql, conn);
                adminCmd.Parameters.AddWithValue("id", user.AdminId.Value);
                return adminCmd.ExecuteScalar()?.ToString() ?? user.Login;
            }

            return user.Login;
        }

        public string? GetInstructorName(int instructorId)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "SELECT instructor_full_name FROM instructor WHERE instructor_number = @id";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("id", instructorId);
            return cmd.ExecuteScalar()?.ToString();
        }

        public string GetPrimaryAdminFullName()
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "SELECT admin_full_name FROM admin ORDER BY admin_id LIMIT 1";
            using var cmd = new NpgsqlCommand(sql, conn);
            return cmd.ExecuteScalar()?.ToString() ?? "администратору фитнес-клуба";
        }

        public ObservableCollection<ClientShort> GetClients()
        {
            var list = new ObservableCollection<ClientShort>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "SELECT client_id, client_full_name FROM client ORDER BY client_full_name";
            using var cmd = new NpgsqlCommand(sql, conn);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new ClientShort { Id = r.GetInt32(0), FullName = r.GetString(1) });
            }
            return list;
        }

        public ObservableCollection<PaymentWithClient> GetAllPayments()
        {
            var list = new ObservableCollection<PaymentWithClient>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"SELECT p.payments_number, p.client_id, c.client_full_name, c.client_contacts,
                                        p.payments_date, p.payments_purpose, p.payments_amounts, p.payments_method
                                 FROM payments p
                                 JOIN client c ON p.client_id = c.client_id
                                 ORDER BY p.payments_date DESC, p.payments_number DESC";
            using var cmd = new NpgsqlCommand(sql, conn);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new PaymentWithClient
                {
                    Number = r.GetInt32(0),
                    ClientId = r.GetInt32(1),
                    ClientName = r.GetString(2),
                    ClientContacts = r.GetString(3),
                    Date = r.GetDateTime(4),
                    Purpose = r.GetString(5),
                    Amount = r.GetDecimal(6),
                    Method = r.GetString(7)
                });
            }
            return list;
        }

        public ObservableCollection<Payment> GetClientPayments(int clientId)
        {
            var list = new ObservableCollection<Payment>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"SELECT payments_number, payments_date, payments_purpose, payments_amounts, payments_method
                                 FROM payments
                                 WHERE client_id = @clientId
                                 ORDER BY payments_date DESC, payments_number DESC";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("clientId", clientId);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new Payment
                {
                    Number = r.GetInt32(0),
                    Date = r.GetDateTime(1),
                    Purpose = r.GetString(2),
                    Amount = r.GetDecimal(3),
                    Method = r.GetString(4)
                });
            }
            return list;
        }

        public ObservableCollection<ClientEditModel> GetClientsForInlineEdit()
        {
            var list = new ObservableCollection<ClientEditModel>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"SELECT client_id, client_full_name, client_contacts, client_birthday, client_registration_date
                                 FROM client ORDER BY client_full_name";
            using var cmd = new NpgsqlCommand(sql, conn);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new ClientEditModel
                {
                    Id = r.GetInt32(0),
                    FullName = r.GetString(1),
                    Contacts = r.GetString(2),
                    Birthday = r.GetDateTime(3),
                    RegistrationDate = r.GetDateTime(4)
                });
            }
            return list;
        }

        public void UpdateClientContact(int clientId, string contacts)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "UPDATE client SET client_contacts = @contacts WHERE client_id = @id";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("contacts", contacts ?? string.Empty);
            cmd.Parameters.AddWithValue("id", clientId);
            cmd.ExecuteNonQuery();
        }

        public void UpdateClient(ClientEditModel item)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"UPDATE client
                                 SET client_full_name = @name,
                                     client_contacts = @contacts,
                                     client_birthday = @birthday,
                                     client_registration_date = @reg
                                 WHERE client_id = @id";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("name", item.FullName);
            cmd.Parameters.AddWithValue("contacts", item.Contacts);
            cmd.Parameters.AddWithValue("birthday", item.Birthday.Date);
            cmd.Parameters.AddWithValue("reg", item.RegistrationDate.Date);
            cmd.Parameters.AddWithValue("id", item.Id);
            cmd.ExecuteNonQuery();
        }

        public void AddClient(string fullName, string contacts, DateTime birthday, DateTime registrationDate, int adminId)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"INSERT INTO client (client_full_name, client_contacts, client_birthday, client_registration_date, admin_id)
                                 VALUES (@name, @contacts, @birthday, @registration, @adminId)";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("name", fullName);
            cmd.Parameters.AddWithValue("contacts", contacts);
            cmd.Parameters.AddWithValue("birthday", birthday.Date);
            cmd.Parameters.AddWithValue("registration", registrationDate.Date);
            cmd.Parameters.AddWithValue("adminId", adminId);
            cmd.ExecuteNonQuery();
        }

        public void AddTraining(string title, DateTime date, int seats, string type, int instructorId, int adminId)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"
                INSERT INTO schedule (schedule_name, schedule_time, schedule_number_of_seats, schedule_type, instructor_number, admin_id)
                VALUES (@title, @date, @seats, @type, @instr, @adminId)";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("title", title);
            cmd.Parameters.AddWithValue("date", date.Date);
            cmd.Parameters.AddWithValue("seats", seats);
            cmd.Parameters.AddWithValue("type", type);
            cmd.Parameters.AddWithValue("instr", instructorId);
            cmd.Parameters.AddWithValue("adminId", adminId);
            cmd.ExecuteNonQuery();
        }

        public void UpdateTraining(TrainingSession item)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"
                UPDATE schedule
                SET schedule_name = @title,
                    schedule_time = @date,
                    schedule_number_of_seats = @seats,
                    schedule_type = @type,
                    instructor_number = @instr
                WHERE schedule_id = @id";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("title", item.Title);
            cmd.Parameters.AddWithValue("date", item.Date.Date);
            cmd.Parameters.AddWithValue("seats", item.Seats);
            cmd.Parameters.AddWithValue("type", item.Type);
            cmd.Parameters.AddWithValue("instr", item.InstructorId);
            cmd.Parameters.AddWithValue("id", item.Id);
            cmd.ExecuteNonQuery();
        }

        public void CancelByProcedure(int scheduleId)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            using var cmd = new NpgsqlCommand("CALL cancel_activity(@id)", conn);
            cmd.Parameters.AddWithValue("id", scheduleId);
            cmd.ExecuteNonQuery();
        }

        public ObservableCollection<EnrolledClientInfo> GetEnrolledClients(int scheduleId)
        {
            var list = new ObservableCollection<EnrolledClientInfo>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"SELECT c.client_id, c.client_full_name, c.client_contacts
                                 FROM participates p
                                 JOIN client c ON c.client_id = p.client_id
                                 WHERE p.schedule_id = @sid
                                 ORDER BY c.client_full_name";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("sid", scheduleId);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new EnrolledClientInfo
                {
                    ClientId = r.GetInt32(0),
                    FullName = r.GetString(1),
                    Contacts = r.GetString(2)
                });
            }
            return list;
        }

        public bool IsClientEnrolledInGroupSession(int scheduleId, int clientId)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "SELECT 1 FROM participates WHERE schedule_id = @sid AND client_id = @cid";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("sid", scheduleId);
            cmd.Parameters.AddWithValue("cid", clientId);
            return cmd.ExecuteScalar() != null;
        }

        public void AddClientToGroupSession(int scheduleId, int clientId)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "INSERT INTO participates (schedule_id, client_id) VALUES (@sid, @cid)";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("sid", scheduleId);
            cmd.Parameters.AddWithValue("cid", clientId);
            cmd.ExecuteNonQuery();
        }

        public ObservableCollection<SubscriptionReportRow> GetSubscriptionSalesReport(DateTime start, DateTime end)
        {
            var list = new ObservableCollection<SubscriptionReportRow>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"
                WITH payment_scope AS (
                    SELECT p.payments_number,
                           p.client_id,
                           p.payments_date,
                           p.payments_purpose,
                           p.payments_amounts,
                           p.payments_method,
                           c.client_full_name,
                           c.client_contacts,
                           CASE
                               WHEN p.payments_purpose ILIKE '%месяч%' OR p.payments_purpose ILIKE '%месяц%' THEN 'Месячный'
                               WHEN p.payments_purpose ILIKE '%полугод%' OR p.payments_purpose ILIKE '%полгода%' THEN 'Полгода'
                               WHEN p.payments_purpose ILIKE '%годов%' OR p.payments_purpose ILIKE '%годовой%' THEN 'Годовой'
                               WHEN p.payments_purpose ILIKE '%разов%' THEN 'Разовый'
                               WHEN p.payments_purpose ILIKE '%бонус%' THEN 'Бонус'
                               WHEN p.payments_purpose ILIKE '%продлен%' THEN 'Продление'
                               ELSE NULL
                           END AS payment_kind
                    FROM payments p
                    INNER JOIN client c ON c.client_id = p.client_id
                    WHERE p.payments_date >= @start
                      AND p.payments_date <= @end
                      AND (
                          p.payments_purpose ILIKE '%оплат%'
                          OR p.payments_purpose ILIKE '%продлен%'
                          OR p.payments_purpose ILIKE '%бонус%'
                      )
                )
                SELECT s.subscription_id,
                       p.client_full_name,
                       p.client_contacts,
                       s.subscription_type,
                       s.subscription_price,
                       s.subscription_discount_price,
                       s.subscription_period,
                       s.subscription_status,
                       a.admin_full_name,
                       p.payments_number,
                       p.payments_date,
                       p.payments_purpose,
                       p.payments_amounts,
                       p.payments_method
                FROM payment_scope p
                INNER JOIN LATERAL (
                    SELECT s.subscription_id,
                           s.subscription_type,
                           s.subscription_price,
                           s.subscription_discount_price,
                           s.subscription_period,
                           s.subscription_status,
                           s.admin_id
                    FROM subscription s
                    WHERE s.client_id = p.client_id
                      AND (
                          p.payment_kind = 'Продление'
                          OR (p.payment_kind = 'Месячный' AND s.subscription_type ILIKE '%месяч%')
                          OR (p.payment_kind = 'Полгода' AND (
                              s.subscription_type ILIKE '%полугод%'
                              OR s.subscription_type ILIKE '%полгода%'
                          ))
                          OR (p.payment_kind = 'Годовой' AND s.subscription_type ILIKE '%годов%')
                          OR (p.payment_kind = 'Бонус' AND s.subscription_type ILIKE '%бонус%')
                      )
                    ORDER BY
                        CASE
                            WHEN s.subscription_price = p.payments_amounts THEN 0
                            WHEN s.subscription_discount_price IS NOT NULL AND s.subscription_discount_price = p.payments_amounts THEN 0
                            ELSE 1
                        END,
                        CASE
                            WHEN p.payment_kind = 'Продление' THEN LEAST(
                                ABS(s.subscription_price - p.payments_amounts),
                                ABS(COALESCE(s.subscription_discount_price, s.subscription_price) - p.payments_amounts)
                            )
                            ELSE LEAST(
                                ABS(s.subscription_price - p.payments_amounts),
                                ABS(COALESCE(s.subscription_discount_price, s.subscription_price) - p.payments_amounts)
                            )
                        END,
                        s.subscription_status DESC,
                        s.subscription_id DESC
                    LIMIT 1
                ) s ON TRUE
                LEFT JOIN admin a ON a.admin_id = s.admin_id
                ORDER BY p.payments_date DESC, p.payments_number DESC";

            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("start", start.Date);
            cmd.Parameters.AddWithValue("end", end.Date);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new SubscriptionReportRow
                {
                    SubscriptionId = r.GetInt32(0),
                    ClientName = r.GetString(1),
                    ClientContacts = r.GetString(2),
                    SubscriptionType = r.GetString(3),
                    SubscriptionPrice = r.GetDecimal(4),
                    DiscountPrice = r.GetDecimal(5),
                    PeriodDays = Convert.ToInt32(r.GetDecimal(6)),
                    StatusText = r.GetBoolean(7) ? "Активен" : "Неактивен",
                    AdminName = r.IsDBNull(8) ? string.Empty : r.GetString(8),
                    PaymentNumber = r.IsDBNull(9) ? null : r.GetInt32(9),
                    PaymentDate = r.IsDBNull(10) ? null : r.GetDateTime(10),
                    PaymentPurpose = r.IsDBNull(11) ? string.Empty : r.GetString(11),
                    PaymentAmount = r.IsDBNull(12) ? null : r.GetDecimal(12),
                    PaymentMethod = r.IsDBNull(13) ? string.Empty : r.GetString(13)
                });
            }
            return list;
        }

        public ObservableCollection<PersonalSession> GetPersonalSchedule()
        {
            var list = new ObservableCollection<PersonalSession>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"
                SELECT r.registration_id, r.instructor_number, c.client_full_name, i.instructor_full_name, r.registration_timestamp, r.registration_status
                FROM registration r
                JOIN client c ON r.client_id = c.client_id
                JOIN instructor i ON r.instructor_number = i.instructor_number
                ORDER BY r.registration_timestamp DESC";

            using var cmd = new NpgsqlCommand(sql, conn);
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new PersonalSession
                {
                    Id = r.GetInt32(0),
                    InstructorId = Convert.ToInt32(r.GetDecimal(1)),
                    ClientName = r.GetString(2),
                    TrainerName = r.GetString(3),
                    DateTime = r.GetDateTime(4),
                    Status = r.GetBoolean(5)
                });
            }
            return list;
        }

        public void AddPersonalTraining(int clientId, int instructorId, DateTime fullDateTime)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"
                INSERT INTO registration (client_id, instructor_number, registration_date, registration_time, registration_status)
                VALUES (@cid, @iid, @date, @time, TRUE)";

            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("cid", clientId);
            cmd.Parameters.AddWithValue("iid", instructorId);
            cmd.Parameters.AddWithValue("date", fullDateTime.Date);
            cmd.Parameters.AddWithValue("time", fullDateTime.TimeOfDay);
            cmd.ExecuteNonQuery();
        }

        public void CancelPersonalTraining(int id)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "UPDATE registration SET registration_status = FALSE WHERE registration_id = @id";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("id", id);
            cmd.ExecuteNonQuery();
        }

        public void SetPersonalTrainingStatus(int id, bool status)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = "UPDATE registration SET registration_status = @status WHERE registration_id = @id";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("status", status);
            cmd.Parameters.AddWithValue("id", id);
            cmd.ExecuteNonQuery();
        }

        public void UpdatePersonalTraining(int id, int clientId, int instructorId, DateTime fullDateTime, bool status)
        {
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"UPDATE registration
                                 SET client_id = @cid,
                                     instructor_number = @iid,
                                     registration_date = @date,
                                     registration_time = @time,
                                     registration_status = @status
                                 WHERE registration_id = @id";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("cid", clientId);
            cmd.Parameters.AddWithValue("iid", instructorId);
            cmd.Parameters.AddWithValue("date", fullDateTime.Date);
            cmd.Parameters.AddWithValue("time", fullDateTime.TimeOfDay);
            cmd.Parameters.AddWithValue("status", status);
            cmd.Parameters.AddWithValue("id", id);
            cmd.ExecuteNonQuery();
        }

        public ObservableCollection<TrainingSession> GetScheduleReport(DateTime start, DateTime end)
        {
            var list = new ObservableCollection<TrainingSession>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"
                SELECT s.schedule_id, s.schedule_name, i.instructor_full_name, s.schedule_time, s.schedule_number_of_seats, s.schedule_type
                FROM schedule s
                JOIN instructor i ON s.instructor_number = i.instructor_number
                WHERE s.schedule_time >= @start AND s.schedule_time <= @end
                ORDER BY s.schedule_time";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("start", start.Date);
            cmd.Parameters.AddWithValue("end", end.Date.AddDays(1).AddTicks(-1));
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new TrainingSession
                {
                    Id = r.GetInt32(0),
                    Title = r.GetString(1),
                    TrainerName = r.GetString(2),
                    Date = r.GetDateTime(3),
                    Seats = Convert.ToInt32(r.GetDecimal(4)),
                    Type = r.GetString(5)
                });
            }
            return list;
        }

        public ObservableCollection<PersonalSession> GetPersonalReport(DateTime start, DateTime end)
        {
            var list = new ObservableCollection<PersonalSession>();
            using var conn = new NpgsqlConnection(_connString);
            conn.Open();
            const string sql = @"
                SELECT r.registration_id, r.instructor_number, c.client_full_name, i.instructor_full_name, r.registration_timestamp, r.registration_status
                FROM registration r
                JOIN client c ON r.client_id = c.client_id
                JOIN instructor i ON r.instructor_number = i.instructor_number
                WHERE r.registration_timestamp >= @start AND r.registration_timestamp <= @end
                ORDER BY r.registration_timestamp";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("start", start.Date);
            cmd.Parameters.AddWithValue("end", end.Date.AddDays(1).AddTicks(-1));
            using var r = cmd.ExecuteReader();
            while (r.Read())
            {
                list.Add(new PersonalSession
                {
                    Id = r.GetInt32(0),
                    InstructorId = Convert.ToInt32(r.GetDecimal(1)),
                    ClientName = r.GetString(2),
                    TrainerName = r.GetString(3),
                    DateTime = r.GetDateTime(4),
                    Status = r.GetBoolean(5)
                });
            }
            return list;
        }
    }
}
