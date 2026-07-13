# App configuration

The Flutter app receives environment-specific values through `--dart-define`.
No credentials or local `.env` files are committed to the repository.

Required values for maps and Google Sign-In:

```powershell
flutter run `
  --dart-define=ACCESS_TOKEN=your_mapbox_public_token `
  --dart-define=API_BASE_URL=https://your-worker.workers.dev `
  --dart-define=GOOGLE_WEB_CLIENT_ID=your_web_client_id
```

For iOS, also provide:

```powershell
--dart-define=GOOGLE_IOS_CLIENT_ID=your_ios_client_id
```

The same Google web client ID must be configured in the Cloudflare Worker as
`GOOGLE_WEB_CLIENT_ID`, because the backend validates the token audience.
