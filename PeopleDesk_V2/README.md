# PeopleDesk V2 — Role-Based Employee Leave Management System

A learning/demo HRMS-style web application built with Python, Flask, SQLite, SQL, HTML and CSS. It has a shared login page and separate employee and HR dashboards.

## Features

### Employee portal
- Log in with an employee account
- View own employee details
- Submit a leave request
- View only their own leave request history and current status

### HR portal
- Log in with an HR account
- View employee directory and leave request queue
- Create employee accounts
- Approve or reject pending requests
- View dashboard statistics

### Security and data handling
- Passwords are stored as hashes using Werkzeug's password hashing helpers
- Flask sessions maintain the signed-in user's identity and role
- Role-protected routes restrict employee and HR pages/actions
- Employee leave history is filtered by the employee ID in the session
- SQL statements use parameterized placeholders
- Foreign keys and CHECK constraints protect relational data
- Only pending leave requests can be approved or rejected

## Requirements
- Python 3.9+
- pip

## Run locally

1. Extract the ZIP and open the project folder in a terminal.
2. Create and activate a virtual environment:

   **Windows**
   ```bash
   python -m venv venv
   venv\Scripts\activate
   ```

   **Linux/macOS**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Start the app:
   ```bash
   python app.py
   ```

5. Visit `http://127.0.0.1:5000`.

The database `leave_management_v2.db` and demo accounts are initialized automatically when the app first runs.

## Local demo accounts

| Role | Email | Password |
|---|---|---|
| HR | admin@peopledesk.com | Admin@123 |
| Employee | rahul@example.com | Rahul@123 |
| Employee | priya@example.com | Priya@123 |

These credentials are for local demonstration only. Do not deploy a public application with these demo credentials or the development SECRET_KEY.

## Database design

### employees
- `id`: primary key
- `name`: employee name
- `department`: department

### users
- `id`: primary key
- `email`: unique login identifier
- `password_hash`: hashed password, never plain text
- `role`: HR or Employee
- `employee_id`: nullable unique foreign key to employees.id

### leave_requests
- `id`: primary key
- `employee_id`: foreign key to employees.id
- `start_date`, `end_date`: ISO date strings
- `days`: inclusive calendar-day duration
- `reason`: request reason
- `status`: Pending, Approved or Rejected
- `created_at`: creation timestamp

An employee has one user account and can submit many leave requests. HR accounts are not linked to an employee record.

## Suggested manual test

1. Sign in as Rahul using the employee demo account.
2. Submit a leave request.
3. Log out and sign in as HR.
4. Confirm Rahul's request appears in the HR queue.
5. Approve or reject it.
6. Log out and sign back in as Rahul.
7. Confirm the request status has changed.
8. Try opening `/hr` while signed in as an employee; access should be denied and you should be redirected.
9. Try opening `/employee` while signed in as HR; access should be denied and you should be redirected.
10. As HR, create a new employee account and test its login.

## Resume description

**PeopleDesk — Role-Based Employee Leave Management System | Python, Flask, SQLite, SQL, HTML, CSS**
- Developed a web-based HR application with separate employee and HR portals for leave submission, tracking and approval workflows.
- Implemented session-based login, password hashing and role-based route authorization using Flask.
- Designed relational database tables with primary/foreign-key constraints and implemented employee-specific request retrieval and SQL operations.
- Added input validation and status-transition checks to prevent invalid leave requests and repeated processing.

## Scope and limitations

This is an educational prototype, not a production HR platform. It does not yet include password reset, CSRF protection, audit logs, email notifications, leave balances, or a production WSGI deployment. Before public deployment, configure a strong secret key, secure cookies over HTTPS, CSRF protection, stronger account administration, and production server settings.
