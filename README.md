# AB Chat

WhatsApp-style chat app. Flutter (Android / iOS) + NestJS + Socket.IO.

```
backend/   NestJS API + realtime server
app/       Flutter mobile app
```

## Status

| Step | Feature | Status |
|---|---|---|
| 1 | Phone + OTP login, profile, 1-to-1 realtime text chat, delivered/read ticks, typing, online/last seen, offline queue | ✅ done |
| 2 | End-to-end encryption (Signal Protocol) | next |
| 3 | Images, video, voice notes (encrypted, S3 storage) | |
| 4 | Push notifications (FCM / APNs) | |
| 5 | Group chats | |
| 6 | Voice & video calls (WebRTC + TURN) | |
| 7 | Production deploy (Postgres, Redis, HTTPS, SMS provider), Play Store / iOS | |

> Messages are **not yet end-to-end encrypted** — the server can read them. Don't use it for real private chats until step 2.

## Run it locally

1. **Start the server:** double-click `start-server.bat` (keep the window open).
2. **Allow phones through the firewall (once):** right-click `allow-phone-access.bat` → *Run as administrator*.
3. **Install the app:** copy `app/build/app/outputs/flutter-apk/app-release.apk` to your Android phone and open it
   (allow "Install unknown apps" when asked).
4. Phone and PC must be on the **same Wi-Fi**. On the login screen, open **Server** and check it is
   `http://<your PC's Wi-Fi IP>:3000` (run `ipconfig` on the PC to find it).
5. Log in with your number (with country code, e.g. `+919876543210`). No SMS is sent in development:
   the code is shown on screen and in the server window.
6. On a second phone, log in with another number, tap the green button, enter the first number and chat.

## Development

Tools live on D: (C: is nearly full): Flutter `D:\dev\flutter`, Android SDK `D:\dev\android-sdk`,
Gradle cache `D:\dev\gradle`, Dart packages `D:\dev\pub-cache`.

```bash
# backend
cd backend
npm run build && npm start      # server on :3000
npm run smoke                   # two simulated users chat end to end (server must be running)

# app
cd app
flutter run -d chrome           # quick test in the browser (server at localhost)
flutter run                     # on a USB-connected Android phone
flutter build apk --release     # installable APK
```

Backend config is in `backend/.env` (see `.env.example`). Local dev uses SQLite; set `DB_TYPE=postgres`
and `DATABASE_URL` for production.
