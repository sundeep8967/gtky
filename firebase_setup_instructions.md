# Firebase Setup Instructions for GTKY App

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `gtky-app` (or your preferred name)
4. Enable Google Analytics (recommended)
5. Choose or create a Google Analytics account
6. Click "Create project"

## Step 2: Add Android App

1. In Firebase console, click "Add app" and select Android
2. Enter Android package name: `com.example.gtky` (or your package name)
3. Enter app nickname: `GTKY Android`
4. Download `google-services.json`
5. Place the file in `android/app/` directory

## Step 3: Add iOS App

1. In Firebase console, click "Add app" and select iOS
2. Enter iOS bundle ID: `com.example.gtky` (or your bundle ID)
3. Enter app nickname: `GTKY iOS`
4. Download `GoogleService-Info.plist`
5. Place the file in `ios/Runner/` directory

## Step 4: Configure Android

Add to `android/build.gradle` (project level):
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-analytics'
}
```

## Step 5: Configure iOS

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on Runner and select "Add Files to Runner"
3. Select the `GoogleService-Info.plist` file
4. Make sure it's added to the Runner target

## Step 6: Enable Firebase Services

### Authentication
1. Go to Authentication > Sign-in method
2. Enable Google sign-in
3. Add your app's SHA-1 fingerprint for Android
4. Download updated `google-services.json` if needed

### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in test mode (for development)
4. Choose a location close to your users

### Cloud Messaging
1. Go to Cloud Messaging
2. No additional setup required for basic functionality

### Storage (Optional)
1. Go to Storage
2. Click "Get started"
3. Start in test mode

## Step 7: Security Rules

### Firestore Rules (Development)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Restaurants are readable by authenticated users
    match /restaurants/{restaurantId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins can write (via Cloud Functions)
    }
    
    // Dining plans
    match /dining_plans/{planId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == resource.data.creatorId;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.creatorId || 
         request.auth.uid in resource.data.memberIds);
    }
  }
}
```

### Storage Rules (Development)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /user_photos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 8: Test Configuration

Run the following command to test Firebase connection:
```bash
flutter pub get
flutter run
```

## Step 9: Production Setup (Later)

### Security Rules (Production)
- Implement proper validation rules
- Add rate limiting
- Restrict read/write access based on user roles

### API Keys
- Restrict API keys to specific apps/domains
- Enable only required APIs

### Monitoring
- Set up Firebase Performance Monitoring
- Configure Crashlytics
- Set up alerts for errors and performance issues

## Troubleshooting

### Common Issues:

1. **Build errors**: Make sure all configuration files are in correct locations
2. **Authentication not working**: Check SHA-1 fingerprints and package names
3. **Firestore permission denied**: Check security rules and authentication state
4. **iOS build issues**: Ensure GoogleService-Info.plist is added to Runner target

### Getting SHA-1 Fingerprint:

For debug builds:
```bash
cd android
./gradlew signingReport
```

For release builds, use your keystore fingerprint.

## Next Steps

After Firebase setup:
1. Test Google Sign-In
2. Test Firestore read/write operations
3. Implement proper error handling
4. Set up Cloud Functions for backend logic
5. Configure push notifications