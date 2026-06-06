# Fitness Customer Relationship Management

Система управления фитнес-клубом — это десктопное WPF-приложение, разработанное для автоматизации процессов управления расписанием, клиентами и финансовой отчетностью.

# Технологии
* **C# 12**
* **.NET 8.0**
* **PostgreSQL 15.x**
* **Npgsql** 
* **MaterialDesignThemes** 

### Требования
Для сборки и запуска приложения необходимо:
* .NET 8.0 SDK / Desktop Runtime
* PostgreSQL

---

### Установка и запуск

#### 1. Клонируйте репозиторий:
```bash
git clone https://github.com/DotTreyd/fitness-crm.git
cd fitness-crm
```

#### 2. Создайте базу данных
```bash
CREATE DATABASE "GymDB";
```
После создания базы данных необходимо выполнить SQL-скрипт инициализации, чтобы создать таблицы, представления, триггеры и хранимые процедуры.

#### 3. Настройте подключение к БД
Откройте файл FitnessRepository.cs и проверьте правильность строки подключения _connString:
```c#
private readonly string _connString = "Host=localhost;Port=5432;Username=postgres;Password=student;Database=GymDB";
```
При необходимости замените Username и Password на актуальные для вашей локальной базы данных.

#### 4. Запуск приложения
С помощью интерфейса командной строки (CLI):
```bash
dotnet run
```
Или откройте файл решения .sln в Visual Studio 2022 и нажмите F5 для запуска с отладкой.
