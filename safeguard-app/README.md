# Safeguard app (Flutter)

Mobile app for Safeguard Safety & Management Center. Talks to the `safeguard-backend` API.

## Set it up
1. Install Flutter (https://docs.flutter.dev/get-started/install).
2. Create a fresh project, then copy this folder's `lib/` and `pubspec.yaml` over it:
   ```bash
   flutter create --org net.safeguardsafety --project-name safeguard_app safeguard_app_project
   cp -r lib pubspec.yaml safeguard_app_project/
   cd safeguard_app_project && flutter pub get
   ```
3. Android needs permission to use the internet. In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```
   While testing against a local `http://` server, also add `android:usesCleartextTraffic="true"` to the `<application>` tag. Remove it for release.
4. Start the backend (see its README), then run the app:
   ```bash
   flutter run                                   # Android emulator talks to http://10.0.2.2:3000/api
   flutter run --dart-define=API_BASE=https://api.yourdomain.com/api   # real phone or production
   ```

## Screens
- **Everyone (no login needed):** Courses (search, categories, detail with dates), Training Calendar, Verify Certificate
- **Individual / staff:** register for a date, My Training (bookings, cancel, certificates)
- **Company admin:** Company tab (join code, staff list, all bookings, quote request) and "Register staff" on any training date

## Not built yet
QR scanning for certificates, online payment, push notifications, and a Safeguard admin section.
