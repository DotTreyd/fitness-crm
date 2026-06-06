using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Lab2BD1_WPF.Models
{
    public class PersonalSession
    {
        public int Id { get; set; }           // registration_id
        public int InstructorId { get; set; } // instructor_number
        public string ClientName { get; set; } // Имя клиента 
        public string TrainerName { get; set; } // Имя тренера 
        public DateTime DateTime { get; set; } // registration_timestamp
        public bool Status { get; set; }       // registration_status
        public bool CanEditStatus { get; set; } = true;

        public string TimeStr => DateTime.ToString("HH:mm");
        public string DateStr => DateTime.ToString("dd.MM.yyyy");
    }
}
