using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Lab2BD1_WPF.Models
{
    public class TrainingSession
    {
        public int Id { get; set; }          // schedule_id
        public string Title { get; set; }    // schedule_name
        public int InstructorId { get; set; }
        public string TrainerName { get; set; } // Имя тренера
        public DateTime Date { get; set; }   // schedule_time
        public int Seats { get; set; }       // schedule_number_of_seats
        public string Type { get; set; }     // schedule_type
        public int AdminId { get; set; }
        public bool CanCancel { get; set; } = true;
        public bool IsCancelled => !string.IsNullOrWhiteSpace(Title) && Title.StartsWith("ОТМЕНА:");
    }
}
