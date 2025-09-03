# Orkestrade Mobile

Flutter mobile app for the Orkestrade business management system with Locative-style geofencing capabilities.

## Features

- 🌐 **Webhook-based Geofencing**: Exact Locative architecture implementation
- ⏰ **Automatic Time Tracking**: Start/stop timers based on location
- 📱 **Receipt Capture**: Camera integration for expense management  
- 🏗️ **Project Integration**: Supabase backend synchronization
- 🔄 **Real-time Updates**: Live data sync between web and mobile

## Architecture

This app implements the exact webhook architecture used by Locative:

- HTTP server on port 8080 for webhook payloads
- Device tracking with enter/exit geofence events
- Automatic timer management based on location
- Integration with Supabase for data persistence

## Setup

### Prerequisites

- Flutter 3.x
- iOS/Android development environment
- Supabase project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/camdent1/orkestrade-mobile.git
   cd orkestrade-mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` with your Supabase credentials:
   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Webhook Format

The app accepts Locative-compatible webhook payloads:

```json
{
  "latitude": "37.7749",
  "longitude": "-122.4194",
  "device": "device-identifier", 
  "trigger": "enter|exit|test",
  "id": "project-geofence-id"
}
```

### Webhook Endpoint

POST requests to: `http://device-ip:8080`

## Database Schema

Requires these Supabase tables:

- `projects` - Project definitions with geofence coordinates
- `time_entries` - Automatic time tracking records
- `location_events` - Geofence trigger event log

## Development

### Testing Webhooks

Use the included test utility:

```dart
import 'lib/services/webhook_test.dart';

// Test webhook endpoint
await WebhookTest.testWebhookEndpoint();

// Print example payloads  
WebhookTest.printWebhookExample();
```

### iOS Configuration

Enable location permissions in `ios/Runner/Info.plist`:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access for automatic time tracking</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for automatic time tracking</string>
```

## Related Projects

- **Web Dashboard**: React-based project management interface
- **Supabase Backend**: PostgreSQL with RLS and real-time subscriptions

## License

Private project for Takumi Finish Carpentry business management.
