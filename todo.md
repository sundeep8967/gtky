# GTKY (Get To Know You) - Development Todo

## 🎯 App Overview
A social dining platform where people from different companies can meet over food with verified matching and restaurant discounts.

## 🚀 DEVELOPMENT MILESTONES

### ✅ Milestone 1: Foundation Setup
**Goal**: Secure and verified onboarding

#### Authentication & Profile Setup
- [x] **Google Sign-In Integration**
  - [x] Add google_sign_in package
  - [x] Configure Android/iOS Google Sign-In
  - [x] Implement Google authentication flow
  - [x] Handle authentication state management

- [x] **LinkedIn Integration** 
  - [x] Add LinkedIn OAuth package
  - [x] Implement LinkedIn login flow (simulated for now)
  - [x] Extract company name from LinkedIn profile
  - [x] Make LinkedIn connection mandatory after Google sign-in

- [x] **User Profile Creation**
  - [x] Create user model (name, age, photo, food preferences, company)
  - [x] Build profile setup screens
  - [ ] Image picker for profile photo (basic implementation done)
  - [x] Food preference selection UI
  - [x] Profile validation and storage

- [x] **Location Services**
  - [x] Add location permission handling
  - [x] Implement location access
  - [x] Get user's current location
  - [x] Location-based restaurant discovery

#### Backend Setup
- [x] **Firebase Configuration**
  - [x] Setup Firebase project (instructions provided)
  - [x] Configure Firebase Auth
  - [x] Setup Firestore database
  - [ ] Configure Firebase Cloud Functions (will be added in later milestones)
  - [x] Setup Firebase Cloud Messaging

- [x] **Database Schema Design**
  - [x] Users collection structure
  - [x] Restaurants collection structure
  - [x] Dining plans collection structure
  - [x] Matches collection structure
  - [ ] Ratings collection structure (will be added in Milestone 6)

---

### ✅ Milestone 2: Restaurant Partnership + Plan Creation - COMPLETED!
**Goal**: Partner restaurants onboarded and dining plans start populating

- [x] **Restaurant Partnership System**
  - [x] Create partner restaurant service and data models
  - [x] Add sample partner restaurants for testing
  - [x] Implement restaurant verification system
  - [x] Create partner restaurant profiles with benefits

- [x] **Restaurant Discovery (Partner-Only)**
  - [x] Display only partner restaurants
  - [x] Build restaurant search functionality
  - [x] List view with partnership badges and discounts
  - [x] Restaurant details with partnership benefits
  - [x] Distance-based sorting and filtering

- [x] **Plan Creation**
  - [x] "Create Dining Plan" UI for partner restaurants only
  - [x] Restaurant selection interface (partners only)
  - [x] Time selection (30 mins - 2 hours from now)
  - [x] Plan submission and storage
  - [x] Plan validation logic with partner verification
  - [x] Group size selection (2-4 people)
  - [x] Optional plan descriptions

- [x] **Plan Management**
  - [x] "My Plans" screen with real-time updates
  - [x] Plan status tracking (Open, Matched, Confirmed, etc.)
  - [x] Plan cancellation functionality
  - [x] Company verification for cross-company matching
  - [x] Stream-based real-time plan updates

---

### ✅ Milestone 3: Plan Discovery + Join Requests - COMPLETED!
**Goal**: Successful, rule-based group formation

- [x] **Plan Discovery**
  - [x] "Browse Open Plans" screen with beautiful UI
  - [x] Filter plans by time and cuisine type
  - [x] Show plan details (restaurant, time, current members)
  - [x] Real-time updates for plan availability
  - [x] Distance-based sorting and restaurant integration

- [x] **Join Request System**
  - [x] "Request to Join" functionality with confirmation dialog
  - [x] Company verification before joining (cross-company only)
  - [x] Group size limit enforcement (2-4 people max)
  - [x] Auto-lock groups when full
  - [x] Simplified auto-join system (MVP approach)

- [x] **Match Management**
  - [x] Enhanced plan details screen
  - [x] Group member display with company information
  - [x] Plan status tracking and validation
  - [x] Cross-company matching enforcement

---

### ✅ Milestone 4: Unique Code + Arrival Verification - COMPLETED!
**Goal**: Real-world validation of group + discount mechanism

- [x] **Code Generation System**
  - [x] Generate unique 2-digit codes for each user
  - [x] Code distribution to matched group members
  - [x] Code display in app with beautiful UI
  - [x] Automatic code generation when plans are full

- [x] **Arrival Verification (User Side)**
  - [x] User arrival confirmation screen
  - [x] Manual arrival confirmation
  - [x] All-arrived confirmation and celebration
  - [x] Real-time group status tracking
  - [x] Beautiful verification interface

- [x] **Restaurant Staff Interface**
  - [x] Staff mobile view/dashboard
  - [x] Code verification interface
  - [x] Mark users as "Arrived"
  - [x] Group completion tracking
  - [x] Discount activation system

- [ ] **Advanced Arrival Features**
  - [ ] QR code scanning option
  - [ ] Manual code entry for staff
  - [ ] All-arrived confirmation (restaurant side)
  - [ ] Discount calculation and application
  - [ ] Bill integration (optional)

---

### 🔹 Milestone 5: Restaurant Panel / Admin Portal
**Goal**: Restaurant becomes a partner in the loop

- [ ] **Restaurant Onboarding**
  - [ ] Restaurant signup/login system
  - [ ] Restaurant profile creation
  - [ ] Verification process
  - [ ] Partnership agreement flow

- [ ] **Restaurant Dashboard**
  - [ ] View upcoming GTKY plans
  - [ ] Group arrival management
  - [ ] Code verification interface
  - [ ] Bill input system
  - [ ] Analytics dashboard

- [ ] **Analytics & Reporting**
  - [ ] Daily GTKY visits tracking
  - [ ] Discount analytics
  - [ ] Revenue impact reports
  - [ ] Customer feedback aggregation

---

### 🔹 Milestone 6: Ratings & Feedback
**Goal**: Trust & quality layer

- [ ] **Post-Meal Rating System**
  - [ ] User-to-user rating (optional)
  - [ ] Restaurant rating (mandatory)
  - [ ] Experience feedback
  - [ ] Photo sharing option

- [ ] **Safety & Moderation**
  - [ ] Report user functionality
  - [ ] Block user feature
  - [ ] Content moderation system
  - [ ] Safety guidelines and tips

- [ ] **Trust Score System**
  - [ ] User reliability scoring
  - [ ] Restaurant quality scoring
  - [ ] Verified user badges
  - [ ] Trust-based matching priority

---

### 🔹 Milestone 7: Monetization Systems
**Goal**: Begin generating revenue 💸

- [ ] **Restaurant Subscription**
  - [ ] ₹1999/₹3999 monthly plans
  - [ ] Featured listing system
  - [ ] Premium restaurant badges
  - [ ] Analytics access tiers
  - [ ] Payment integration

- [ ] **User Premium Features**
  - [ ] ₹199/month premium plan
  - [ ] Match priority boost
  - [ ] Advanced filters
  - [ ] Unlimited plans per day
  - [ ] Premium user badges

- [ ] **Referral System**
  - [ ] Referral code generation
  - [ ] Credit system
  - [ ] Reward tracking
  - [ ] Referral analytics

---

### 🔹 Milestone 8: Notifications + Advanced Matching
**Goal**: Fully automated GTKY engine running

- [ ] **Real-time Notifications**
  - [ ] Firebase Cloud Messaging setup
  - [ ] Match found notifications
  - [ ] Plan updates
  - [ ] Arrival reminders
  - [ ] Rating reminders

- [ ] **Advanced Matching Engine**
  - [ ] Machine learning for better matches
  - [ ] User preference learning
  - [ ] Success rate optimization
  - [ ] Geographic optimization
  - [ ] Time preference analysis

- [ ] **Smart Features**
  - [ ] Auto-suggest restaurants
  - [ ] Optimal timing recommendations
  - [ ] Weather-based suggestions
  - [ ] Cuisine preference matching

---

## 🛠️ Technical Implementation Plan

### Phase 1: Setup & Dependencies
```yaml
# Key packages to add to pubspec.yaml
dependencies:
  # Authentication
  google_sign_in: ^6.1.5
  firebase_auth: ^4.15.3
  
  # LinkedIn (custom implementation needed)
  oauth2: ^2.0.2
  
  # Firebase
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.10
  firebase_storage: ^11.5.6
  
  # Location & Maps
  geolocator: ^10.1.0
  google_maps_flutter: ^2.5.0
  geocoding: ^2.1.1
  
  # UI & State Management
  provider: ^6.1.1
  cached_network_image: ^3.3.0
  image_picker: ^1.0.4
  
  # Utilities
  http: ^1.1.0
  shared_preferences: ^2.2.2
  permission_handler: ^11.1.0
```

### Phase 2: Project Structure
```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── restaurant_model.dart
│   ├── dining_plan_model.dart
│   └── match_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
├── screens/
│   ├── auth/
│   ├── profile/
│   ├── restaurants/
│   ├── plans/
│   └── matches/
├── widgets/
│   └── common/
└── utils/
    ├── constants.dart
    └── helpers.dart
```

### Phase 3: Development Priorities
1. **Week 1-2**: Authentication & Profile Setup
2. **Week 3-4**: Restaurant Discovery & Plan Creation
3. **Week 5-6**: Matching Engine & Group Formation
4. **Week 7-8**: Code System & Verification
5. **Week 9-10**: Restaurant Dashboard
6. **Week 11-12**: Ratings & Safety Features
7. **Week 13-14**: Monetization Features
8. **Week 15-16**: Advanced Features & Polish

---

## 🔐 Security & Verification Strategy

### User Verification
- [x] Google OAuth for primary authentication
- [x] LinkedIn integration for company verification
- [ ] Phone number verification (optional)
- [ ] Email verification

### Anti-Fraud Measures
- [ ] Company domain verification
- [ ] Arrival confirmation system
- [ ] Code-based discount validation
- [ ] User behavior monitoring
- [ ] Report/block functionality

### Data Privacy
- [ ] GDPR compliance
- [ ] Data encryption
- [ ] Secure API endpoints
- [ ] Privacy policy implementation
- [ ] User consent management

---

## 📱 Platform Considerations

### iOS Specific
- [ ] App Store guidelines compliance
- [ ] iOS location permissions
- [ ] Apple Sign-In integration
- [ ] Push notification certificates

### Android Specific
- [ ] Google Play Store requirements
- [ ] Android location permissions
- [ ] Firebase configuration
- [ ] APK optimization

---

## 🧪 Testing Strategy

### Unit Tests
- [ ] Model validation tests
- [ ] Service layer tests
- [ ] Utility function tests

### Integration Tests
- [ ] Authentication flow tests
- [ ] Matching algorithm tests
- [ ] Payment flow tests

### User Acceptance Tests
- [ ] Complete user journey tests
- [ ] Restaurant partner flow tests
- [ ] Edge case handling

---

## 📈 Success Metrics

### User Engagement
- [ ] Daily active users
- [ ] Successful matches per day
- [ ] Restaurant visits completed
- [ ] User retention rate

### Business Metrics
- [ ] Restaurant partner signups
- [ ] Revenue from subscriptions
- [ ] Discount redemption rate
- [ ] Customer satisfaction scores

---

## 🚀 Launch Strategy

### Beta Testing
- [ ] Internal testing with team
- [ ] Closed beta with select restaurants
- [ ] Open beta with limited users
- [ ] Feedback collection and iteration

### Marketing Launch
- [ ] Restaurant partnership program
- [ ] Social media campaign
- [ ] Influencer partnerships
- [ ] PR and media outreach

---

**Next Steps**: Start with Milestone 1 - Foundation Setup, beginning with Firebase configuration and Google Sign-In implementation.