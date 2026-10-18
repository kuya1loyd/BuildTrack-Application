# BuildTrack

A modern Flutter application for construction project tracking, material management, worker logs, task schedules, and progress reporting backed by Neon PostgreSQL.

## Features

- 🏗️ **Project Management**: Track construction sites, timelines, budgets, and milestones.
- 📋 **Daily Logs & Activities**: Record progress, weather conditions, worker hours, and updates.
- 📦 **Material Inventory**: Track quantities, suppliers, reorder levels, and costs.
- ✅ **Task Management**: Prioritized tasks with due dates, assignees, and real-time statuses.
- 👤 **User Profiles & Avatars**: Upload profile pictures or pick presets with instant cloud sync.
- ⚡ **Cross-Platform**: Runs on Flutter Web, Windows Desktop, and Android.

## Architecture

- **Frontend**: Flutter (Dart) with responsive UI, Provider state management, and smooth micro-animations.
- **Backend API**: Node.js bridge server (`server/api.mjs`) communicating with Neon PostgreSQL.
- **Database**: Neon Serverless PostgreSQL with auto-provisioned migrations.

## Getting Started

### 1. Start the API Bridge
```bash
cd server
npm install
node api.mjs
```

### 2. Run the Flutter App
```bash
cd flutter
flutter run -d chrome --web-port=5173 --dart-define-from-file=env.json
```
