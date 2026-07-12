# Environment Variables Setup

## Using .env File (Recommended for Development)

The app now supports loading environment variables from a `.env` file, making it easier to run from the IDE without command-line arguments.

### Setup Steps:

1. **The `.env` file is already configured** in `app/.env`:
   ```env
   ACCESS_TOKEN=pk...
   API_BASE_URL=https://...
   ```

2. **Install dependencies** (already done):
   ```bash
   cd app
   flutter pub get
   ```

3. **Run from IDE**:
   - **VS Code**: Press F5 or click the Run button
   - **Android Studio**: Click Run button or Shift+F10
   - **Important**: Make sure your working directory is set to `app/` folder

### Important for Multi-Folder Workspaces:

If you're in a workspace with multiple folders (like this project), ensure the Flutter app runs with `app/` as the working directory. You may need to:

1. Open the `app/` folder directly in VS Code: `File → Open Folder → Select 'app'`
2. Or create a launch configuration (see Alternative section below)

### How It Works:

The app loads variables in this order:
1. First checks `.env` file
2. Falls back to `--dart-define` arguments
3. Finally uses default values

**Code:**
```dart
// In main.dart
await dotenv.load(fileName: ".env");
String get _mapboxAccessToken => 
    dotenv.env['ACCESS_TOKEN'] ?? const String.fromEnvironment('ACCESS_TOKEN');
```

## Alternative: VS Code Launch Configuration (Recommended for Multi-Folder Workspaces)

If you're working in a multi-folder workspace, create `.vscode/launch.json` at the workspace root:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter: UNparche App",
      "request": "launch",
      "type": "dart",
      "program": "app/lib/main.dart",
      "cwd": "app"
    }
  ]
}
```

This ensures Flutter runs with the correct working directory where the `.env` file is located.

**How to use:**
1. Create `.vscode/launch.json` with the configuration above
2. In VS Code, go to Run → Start Debugging (F5)
3. Select "Flutter: UNparche App" from the dropdown if needed

### Manual Arguments (if .env doesn't work):

If you need to provide arguments manually, use this configuration:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (with args)",
      "request": "launch",
      "type": "dart",
      "program": "app/lib/main.dart",
      "cwd": "app",
      "args": [
        "--dart-define=ACCESS_TOKEN=pk....",
        "--dart-define=API_BASE_URL=https:..."
      ]
    }
  ]
}
```

## Available Variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `ACCESS_TOKEN` | Mapbox access token for maps | *(empty)* |
| `API_BASE_URL` | Backend API URL | `http://localhost:8787` |
| `EMAIL` | Email for notifications | - |
| `EMAIL_PASSWORD` | Email password | - |
| `GOOGLE_ANDROID_CLIENT_ID` | Google Sign-In Android | - |
| `GOOGLE_IOS_CLIENT_ID` | Google Sign-In iOS | - |

## Security Notes:

**IMPORTANT:** 
- The `.env` file contains sensitive tokens
- **DO NOT commit** `.env` to version control
- Already added to `.gitignore`
- For production, use secure environment variables

## Production Build:

For production builds, use command-line arguments:

```bash
flutter build apk --release \
  --dart-define=ACCESS_TOKEN=your_token \
  --dart-define=API_BASE_URL=your_api_url
```

## Troubleshooting:

### Variables not loading from .env?

**1. Check working directory:**
   - The `.env` file must be in the `app/` folder
   - Your IDE must run the app with `app/` as the working directory
   - **Solution for multi-folder workspaces:** Create a launch configuration (see Alternative section above)

**2. Open just the app folder:**
   - In VS Code: `File → Open Folder → Select 'app' folder`
   - This ensures the working directory is correct

**3. Verify dependencies installed:**
   ```bash
   cd app
   flutter pub get
   ```

**4. Hot restart (not just reload):**
   - Press Shift+R or click the restart button
   - Environment variables are loaded at app startup only

**5. Check console output:**
   - Look for "Note: .env file not loaded" message
   - If you see this, the working directory is wrong

### Still not working?

Use `--dart-define` explicitly from command line:
```bash
cd app
flutter run \
  --dart-define=ACCESS_TOKEN=pk... \
  --dart-define=API_BASE_URL=https://...
```

### Debug .env loading:

Add this to verify which variables are loaded:
```dart
print('ACCESS_TOKEN loaded: ${dotenv.env['ACCESS_TOKEN']?.substring(0, 10)}...');
print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
```

## Dependencies Added:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

---

**Now you can simply run the app from your IDE without command-line arguments! **
