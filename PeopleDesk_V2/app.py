from datetime import date
from functools import wraps
import sqlite3

from flask import (
    Flask, render_template, request, redirect, url_for,
    flash, session, g
)
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.config.update(
    SECRET_KEY="replace-this-with-a-long-random-secret-before-deployment",
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
)
DATABASE = "leave_management_v2.db"


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DATABASE)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


@app.teardown_appcontext
def close_db(error=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db():
    db = sqlite3.connect(DATABASE)
    db.execute("PRAGMA foreign_keys = ON")
    db.executescript("""
        CREATE TABLE IF NOT EXISTS employees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            department TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL CHECK(role IN ('HR', 'Employee')),
            employee_id INTEGER UNIQUE,
            FOREIGN KEY(employee_id) REFERENCES employees(id)
        );

        CREATE TABLE IF NOT EXISTS leave_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            days INTEGER NOT NULL CHECK(days > 0),
            reason TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'Pending'
                CHECK(status IN ('Pending', 'Approved', 'Rejected')),
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(employee_id) REFERENCES employees(id)
        );
    """)

    # Create demonstration accounts only when the database has no users.
    user_count = db.execute("SELECT COUNT(*) FROM users").fetchone()[0]
    if user_count == 0:
        demo_employees = [
            ("Rahul Sharma", "Engineering", "rahul@example.com", "Rahul@123"),
            ("Priya Reddy", "Human Resources", "priya@example.com", "Priya@123"),
        ]
        for name, department, email, password in demo_employees:
            cursor = db.execute(
                "INSERT INTO employees (name, department) VALUES (?, ?)",
                (name, department),
            )
            employee_id = cursor.lastrowid
            db.execute("""
                INSERT INTO users (email, password_hash, role, employee_id)
                VALUES (?, ?, 'Employee', ?)
            """, (email, generate_password_hash(password), employee_id))

        db.execute("""
            INSERT INTO users (email, password_hash, role, employee_id)
            VALUES (?, ?, 'HR', NULL)
        """, ("admin@peopledesk.com", generate_password_hash("Admin@123")))

    db.commit()
    db.close()


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if "user_id" not in session:
            flash("Please log in to continue.", "error")
            return redirect(url_for("login"))
        return view(*args, **kwargs)
    return wrapped



def role_required(role):
    def decorator(view):
        @wraps(view)
        @login_required
        def wrapped(*args, **kwargs):
            if session.get("role") != role:
                flash("You are not authorized to access that page.", "error")
                return redirect(url_for("dashboard"))
            return view(*args, **kwargs)

        return wrapped

    return decorator


@app.route("/")
def index():
    if "user_id" in session:
        return redirect(url_for("dashboard"))
    return redirect(url_for("login"))


@app.route("/login", methods=["GET", "POST"])
def login():
    if "user_id" in session:
        return redirect(url_for("dashboard"))

    if request.method == "POST":
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        user = get_db().execute(
            "SELECT * FROM users WHERE email = ?", (email,)
        ).fetchone()

        if user and check_password_hash(user["password_hash"], password):
            session.clear()
            session["user_id"] = user["id"]
            session["email"] = user["email"]
            session["role"] = user["role"]
            session["employee_id"] = user["employee_id"]
            return redirect(url_for("dashboard"))

        flash("Invalid email or password.", "error")

    return render_template("login.html")


@app.post("/logout")
@login_required
def logout():
    session.clear()
    flash("You have been logged out.", "success")
    return redirect(url_for("login"))


@app.route("/dashboard")
@login_required
def dashboard():
    if session["role"] == "HR":
        return redirect(url_for("hr_dashboard"))
    return redirect(url_for("employee_dashboard"))


@app.route("/employee")
@role_required("Employee")
def employee_dashboard():
    db = get_db()
    employee = db.execute(
        "SELECT * FROM employees WHERE id = ?", (session["employee_id"],)
    ).fetchone()
    requests = db.execute("""
        SELECT * FROM leave_requests
        WHERE employee_id = ?
        ORDER BY created_at DESC
    """, (session["employee_id"],)).fetchall()

    stats = {
        "pending": sum(r["status"] == "Pending" for r in requests),
        "approved": sum(r["status"] == "Approved" for r in requests),
        "rejected": sum(r["status"] == "Rejected" for r in requests),
    }
    return render_template(
        "employee_dashboard.html", employee=employee,
        requests=requests, stats=stats
    )


@app.post("/employee/leave-requests")
@role_required("Employee")
def create_leave_request():
    start_text = request.form.get("start_date", "")
    end_text = request.form.get("end_date", "")
    reason = request.form.get("reason", "").strip()

    if not all([start_text, end_text, reason]):
        flash("Please complete all leave request fields.", "error")
        return redirect(url_for("employee_dashboard"))

    try:
        start = date.fromisoformat(start_text)
        end = date.fromisoformat(end_text)
    except ValueError:
        flash("Please provide valid dates.", "error")
        return redirect(url_for("employee_dashboard"))

    if end < start:
        flash("End date cannot be earlier than start date.", "error")
        return redirect(url_for("employee_dashboard"))

    days = (end - start).days + 1
    db = get_db()
    db.execute("""
        INSERT INTO leave_requests
            (employee_id, start_date, end_date, days, reason)
        VALUES (?, ?, ?, ?, ?)
    """, (session["employee_id"], start.isoformat(),
          end.isoformat(), days, reason))
    db.commit()

    flash("Your leave request has been submitted to HR.", "success")
    return redirect(url_for("employee_dashboard"))


@app.route("/hr")
@role_required("HR")
def hr_dashboard():
    db = get_db()
    employees = db.execute("""
        SELECT e.id, e.name, e.department, u.email
        FROM employees e
        JOIN users u ON u.employee_id = e.id
        ORDER BY e.name
    """).fetchall()

    requests = db.execute("""
        SELECT lr.*, e.name AS employee_name, e.department
        FROM leave_requests lr
        JOIN employees e ON e.id = lr.employee_id
        ORDER BY
            CASE lr.status WHEN 'Pending' THEN 0 ELSE 1 END,
            lr.created_at DESC
    """).fetchall()

    stats = {
        "employees": len(employees),
        "pending": sum(r["status"] == "Pending" for r in requests),
        "approved": sum(r["status"] == "Approved" for r in requests),
        "rejected": sum(r["status"] == "Rejected" for r in requests),
    }
    return render_template(
        "hr_dashboard.html", employees=employees,
        requests=requests, stats=stats
    )


@app.post("/hr/employees")
@role_required("HR")
def add_employee():
    name = request.form.get("name", "").strip()
    department = request.form.get("department", "").strip()
    email = request.form.get("email", "").strip().lower()
    password = request.form.get("password", "")

    if not all([name, department, email, password]):
        flash("Please complete all employee fields.", "error")
        return redirect(url_for("hr_dashboard"))

    if len(password) < 8:
        flash("Temporary password must contain at least 8 characters.", "error")
        return redirect(url_for("hr_dashboard"))

    db = get_db()
    try:
        cursor = db.execute(
            "INSERT INTO employees (name, department) VALUES (?, ?)",
            (name, department)
        )
        employee_id = cursor.lastrowid
        db.execute("""
            INSERT INTO users (email, password_hash, role, employee_id)
            VALUES (?, ?, 'Employee', ?)
        """, (email, generate_password_hash(password), employee_id))
        db.commit()
        flash("Employee account created successfully.", "success")
    except sqlite3.IntegrityError:
        db.rollback()
        flash("That email address is already registered.", "error")

    return redirect(url_for("hr_dashboard"))


@app.post("/hr/leave-requests/<int:request_id>/<action>")
@role_required("HR")
def update_leave_status(request_id, action):
    if action not in ("approve", "reject"):
        flash("Invalid action.", "error")
        return redirect(url_for("hr_dashboard"))

    new_status = "Approved" if action == "approve" else "Rejected"
    db = get_db()
    result = db.execute("""
        UPDATE leave_requests
        SET status = ?
        WHERE id = ? AND status = 'Pending'
    """, (new_status, request_id))
    db.commit()

    if result.rowcount == 1:
        flash(f"Leave request {new_status.lower()}.", "success")
    else:
        flash("Request not found or already processed.", "error")

    return redirect(url_for("hr_dashboard"))


if __name__ == "__main__":
    init_db()
    app.run(debug=True)
