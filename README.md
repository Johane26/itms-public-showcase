# Intelligent Transport Management System (ITMS)

A software engineering project exploring how digital technology can support combi fleet management, driver workflows, vehicle location monitoring, and passenger information in Botswana.

## Project Overview

ITMS consists of a Spring Boot backend and three Flutter applications designed for different users.

- **Driver App:** Driver authentication, trip-related workflows, and GPS location reporting.
- **Passenger App:** Passenger-facing application shell. Route search and vehicle information are not currently available in the app.
- **Owner Dashboard:** Fleet overview, trip statistics, active vehicle location monitoring, and alerts. These features depend on authenticated access and backend data.
- **Backend API:** REST endpoints, JWT authentication, account access checks, PostgreSQL persistence, trip management, and stop-detection functionality.

This is a development and portfolio project. Not all features have been validated end to end, and the project is not presented as a production-ready transport service.

## Technology Stack

| Area | Technologies |
|---|---|
| Backend | Java 21, Spring Boot |
| Database | PostgreSQL, Spring Data JPA, Hibernate |
| Authentication | Spring Security, JWT, BCrypt |
| Mobile and Dashboard Applications | Flutter, Dart |
| Build and Development Tools | Maven, Git, Android Studio |

## Repository Structure

```text
ITMS/
├── backend/          # Spring Boot REST API
├── driver-app/       # Driver-facing Flutter application
├── passenger-app/    # Passenger-facing Flutter application
└── owner-dashboard/  # Fleet owner Flutter application
```

## Prerequisites

Install the following tools before running the project:

- Java Development Kit (JDK) 21
- PostgreSQL
- Flutter SDK compatible with the project
- Android Studio or another supported Flutter development environment

## Getting Started

### 1. Configure the Database

Create a local PostgreSQL database named `transport_db`.

From PowerShell, configure the backend environment variables for your local session:

```powershell
$env:DB_URL = "jdbc:postgresql://localhost:5432/transport_db"
$env:DB_USERNAME = "postgres"
$env:DB_PASSWORD = "your-local-database-password"
$env:JWT_SECRET = "replace-with-a-random-secret-of-at-least-32-utf8-bytes"
```

Replace the example values with your own local settings. The JWT secret must contain at least 32 UTF-8 bytes. Keep real passwords and secrets out of source control.

### 2. Start the Backend

Open PowerShell in the `backend` directory and run:

```powershell
.\mvnw.cmd spring-boot:run
```

The backend uses port `8080` by default. Ensure PostgreSQL is running and the database credentials are correct.

### 3. Run a Flutter Application

Choose `driver-app`, `passenger-app`, or `owner-dashboard`, then open a terminal in that directory.

Fetch dependencies:

```powershell
flutter pub get
```

Provide the backend URL when running the app:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

**Important:** The correct URL depends on the device or platform running the Flutter app. An Android emulator, browser, simulator, or physical device may require a different address to reach the backend. Use an address that is reachable from your target environment.

Release builds require an HTTPS API URL. Do not put passwords, tokens, or other credentials in the API URL.

## Security Notes

- Database credentials and the JWT signing secret are supplied through environment variables.
- Driver and owner login endpoints issue JWTs for authenticated API access.
- Protected backend requests perform token and account access checks.
- Passwords are verified using BCrypt.
- Local development settings should not be treated as a production security configuration.
- Before any deployment, review CORS restrictions, database schema management, logging, secret management, and the complete authentication flow.

## Testing and Verification

The current verification results include:

- **Backend:** 3 automated tests passed.
- **Driver App:** 6 Flutter tests passed.
- **Passenger App:** 7 Flutter tests passed.
- **Owner Dashboard:** 9 Flutter tests passed.

Flutter static analysis reported no issues in the passenger app or owner dashboard. The driver app reported one minor style suggestion.

These checks provide a baseline for the current code. They do not establish complete end-to-end functionality, deployment readiness, or production security.

## Current Limitations

- Passenger route search and vehicle information are not currently implemented in the passenger app.
- Live tracking accuracy and ETA calculations have not been independently validated.
- Backend and frontend integrations require further end-to-end verification.
- Production deployment and operational monitoring have not been established.

## License

See the `LICENSE` file in this repository for the applicable license terms.
