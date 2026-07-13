# Models

This directory contains all data models used in the UNparche app.

## Available Models

### User (`user.dart`)
Represents a user in the system with:
- Personal information (name, email, career)
- Authentication details
- Profile data

### Event (`event.dart`)
Represents an event with:
- Event details (title, description, dates)
- Location information
- Organizer and group associations
- Attendance status

### Group (`group.dart`)
Represents a group with:
- Group information (name, description, category)
- Admin and member data
- Verification status

### EventType (`event_type.dart`)
Represents event categories:
- Académico
- Cultural
- Deportivo
- Social
- Otro

### GroupInvitation (`group_invitation.dart`)
Represents invitations to join groups with:
- Invitation status (pending, accepted, rejected)
- Inviter and invitee information
- Associated group data

## Usage

All models include:
- `fromJson()` factory constructor for API deserialization
- `toJson()` method for API serialization
- Proper typing for all fields
- Null safety

Example:
```dart
// Parse from API response
final user = User.fromJson(apiResponse['usuario']);

// Serialize for API request
final json = user.toJson();
```

## API Integration

Models are designed to work with the UNparche backend API endpoints.
See `../services/api_client.dart` for API integration.
