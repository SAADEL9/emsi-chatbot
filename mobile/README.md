# EMSI Chatbot mobile app

## Supabase setup

1. Create a Supabase project and enable **Email** under **Authentication → Providers**.
2. Copy the project URL and anon/publishable key from **Project Settings → API**.
3. Create `supabase.json` from the example and enter those public client values:

   ```sh
   cp supabase.json.example supabase.json
   ```

   This local file is ignored by Git. Never put a Supabase service-role key in the app.
4. In **Authentication → URL Configuration**, set the Site URL to the destination where recovery links should open. For local development, Supabase email confirmation can be disabled; otherwise users must confirm their address before signing in.
5. Start the backend with `SUPABASE_JWT_SECRET` set in `backend/.env` if API requests should require a valid Supabase session.

## Run

```sh
flutter pub get
flutter run --dart-define-from-file=supabase.json
```

For a physical phone, pass the computer's LAN address as the API URL:

```sh
flutter run --dart-define-from-file=supabase.json --dart-define=API_URL=http://<computer-lan-ip>:8000
```

Without Supabase values the app starts in an unconfigured state and disables authentication.
