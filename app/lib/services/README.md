# Services

This directory contains service classes for API communication and business logic.

## Available Services

### ApiClient (`api_client.dart`)
Main HTTP client for communicating with the UNparche backend API.

**Features:**
- RESTful API communication
- Automatic error handling
- JSON serialization/deserialization
- Type-safe responses using models

**Endpoints:**

#### Authentication (TODO - Backend implementation pending)
- `login()` - User login with email/password
- `register()` - New user registration
- `resetPassword()` - Password recovery

#### Users
- `getUser(userId)` - Get user by ID
- `getUserEvents(userId)` - Get user's organized and attending events
- `getUserGroupInvitations(userId)` - Get user's group invitations

#### Events
- `getEvents({userId})` - Get all events (optionally filtered by user)
- `getEvent(eventId)` - Get event by ID
- `createEvent(...)` - Create new event

#### Groups
- `getGroups()` - Get all groups
- `getGroup(groupId)` - Get group by ID

#### Event Types
- `getEventTypes()` - Get all event type categories

#### Attendance
- `confirmAttendance(eventId, userId)` - Confirm attendance to event
- `cancelAttendance(eventId, userId)` - Cancel attendance

**Configuration:**

The API base URL is configured via environment variable:
```dart
// Default: http://localhost:8787
const apiClient = ApiClient();

// Custom URL:
const apiClient = ApiClient(baseUrl: 'https://api.unparche.com');
```

Set the `API_URL` environment variable in `.env` file.

**Error Handling:**

All methods throw `ApiException` on errors:
```dart
try {
  final user = await apiClient.getUser(1);
} on ApiException catch (e) {
  print('API Error: ${e.message}');
  print('Status Code: ${e.statusCode}');
}
```

## Usage Example

```dart
import 'package:app/services/api_client.dart';
import 'package:app/models/user.dart';

final apiClient = ApiClient();

// Get user data
try {
  final user = await apiClient.getUser(userId);
  print('User: ${user.fullName}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
}

// Get events
final events = await apiClient.getEvents();
for (final event in events) {
  print('Event: ${event.title}');
}
```

## Backend Integration Notes

The backend API is built with Cloudflare Workers and uses D1 database.
See `/backend/unparche-api/` for backend implementation.

**Auth Endpoints TODO:**
The following endpoints need to be implemented in the backend:
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/reset-password` - Password reset

Until these are implemented, email authentication remains disabled. Google
authentication uses `POST /auth/google`.
