## 💬 Aqua Talk
A modern, real-time messaging and social status-sharing Flutter application built with Firebase. Aqua Talk combines seamless chat functionality with an engaging story/status feature, wrapped in a beautiful glassmorphism UI design.

## ✨ Features
# 🔐 Authentication
 > Phone number-based authentication via Firebase Auth
 > OTP verification flow
 > Single device login enforcement with session management
 > Secure user profiles with photo upload support
# 💬 Real-Time Chat
 > One-on-one and group messaging
 >Text, image, video, and voice message support
 > Real-time message delivery and read receipts
 > Typing indicators and online/offline status
 > Message reactions and replies
 > Push notifications for new messages
# 📸 Stories / Status Updates
> My Status — Share photo/video updates that disappear after 24 hours
 > View your own status with full viewer analytics
 > Recent Updates — Browse friends' stories with elegant ring indicators
 > Tap to view full-screen stories with auto-progress
 > Reply to stories directly
 > Download and report stories
 > Privacy controls: My Contacts, My Contacts Except..., Only Share With...
# 🎨 UI/UX
 > Glassmorphism design with frosted glass effects
 > Dynamic gradient backgrounds (light/dark mode support)
 > Smooth animations and transitions
 > Bottom sheet menus and modal dialogs
 > Responsive layout for all screen sizes
# ⚙️ Settings & Privacy
 > Dark/Light theme toggle
 > Status privacy controls
 > Account management

# Packages used 
 > cupertino_icons: ^1.0.8
 >assets: ^0.0.2
 >provider: ^6.1.5+1
 >intl: ^0.20.2
 >uuid: ^4.5.3
 >glassmorphism: ^3.0.0
 >animations: ^2.1.2
 >image_picker: ^1.2.1
 >emoji_picker_flutter: ^4.4.0
 >shared_preferences: ^2.5.5
 >firebase_core: ^4.7.0
 >firebase_auth: ^6.4.0
 >cloud_firestore: ^6.3.0
 >flutter_keyboard_visibility: ^6.0.0
 >rxdart: ^0.28.0
 >path_provider: ^2.0.15 # New ADDED
 >firebase_storage: ^13.3.0 # New ADDED
 >flutter_contacts: ^2.0.2 # New ADDED
 >permission_handler: ^12.0.1 # New ADDED
 >http: ^1.6.0
 >hive: ^2.2.3
 >hive_flutter: ^1.1.0
 >hive_generator: ^2.0.1
 >build_runner: ^2.4.13
 >flutter_markdown: ^0.7.7+1
 >firebase_crashlytics: ^5.2.1


# Aqua Talk Structure
lib/
├── main.dart                          # App entry point & MultiProvider setup
│
├── models/                            # Data models
│   ├── user_model.dart                # User profile data
│   ├── story_model.dart               # Story/status data
│   ├── message_model.dart             # Chat message data
│   ├── chat_model.dart                # Chat room/conversation data
│   └── friend_model.dart              # Friend request & relationship data
│
├── provider/                          # State management (Provider)
│   ├── auth_provider.dart             # Auth state & user session
│   ├── story_provider.dart            # Stories feed & CRUD
│   ├── chat_provider.dart             # Conversations & messages
│   ├── theme_provider.dart            # Light/Dark theme toggle
│   ├── gradient_provider.dart         # Background gradients
│   └── profile_provider.dart          # User profile & settings state
│
├── services/                          # Firebase & API services
│   ├── auth_service.dart              # Phone OTP, login, logout
│   ├── story_service.dart             # Story upload, fetch, delete
│   ├── chat_service.dart              # Send/receive messages
│   ├── notification_service.dart      # FCM push notifications
│   ├── storage_service.dart           # Firebase Storage uploads
│   └── friend_service.dart            # Friend requests, search, block
│
├── screens/                           # UI Screens
│   ├── splash/                        # Splash & onboarding
│   │   └── splash_screen.dart
│   │
│   ├── auth/                          # Authentication flow
│   │   ├── login_screen.dart          # Phone number input
│   │   ├── otp_screen.dart            # OTP verification
│   │   └── onboarding_screen.dart     # First-time user intro
│   │
│   ├── home/                          # Main tab container
│   │   └── home_screen.dart           # BottomNavigationBar with tabs
│   │
│   ├── chat/                          # Chat module
│   │   ├── chat_list_screen.dart      # All conversations list
│   │   ├── chat_room_screen.dart      # Individual chat thread
│   │   ├── media_viewer_screen.dart   # Full-screen image/video
│   │   └── group_info_screen.dart     # Group details & members
│   │
│   ├── story/                         # Stories/Status module
│   │   ├── story_screen.dart          # Main story feed (My Status + Recent)
│   │   ├── story_viewer.dart          # Full-screen story viewer
│   │   ├── caption_screen.dart        # Chat-style caption overlay
│   │   └── story_privacy_screen.dart  # Privacy settings for stories
│   │
│   ├── contacts/                      # Contact discovery
│   │   ├── contacts_screen.dart       # Phone contacts on Aqua Talk
│   │   └── invite_screen.dart         # Invite friends via SMS/share
│   │
│   ├── profile/                       # 👤 PROFILE MODULE
│   │   ├── profile_screen.dart        # Main profile view (self)
│   │   ├── edit_profile_screen.dart   # Edit name, bio, photo
│   │   ├── my_status_screen.dart      # My all active stories list
│   │   └── qr_code_screen.dart        # Share profile via QR
│   │
│   ├── friends/                       # 🤝 FRIEND MANAGEMENT MODULE
│   │   ├── friends_screen.dart        # All friends list with search
│   │   ├── friend_requests_screen.dart # Incoming/outgoing requests
│   │   ├── add_friend_screen.dart     # Search & send friend requests
│   │   ├── blocked_users_screen.dart  # Manage blocked users
│   │   └── mutual_friends_screen.dart # See mutual connections
│   │
│   └── settings/                      # ⚙️ Settings & Privacy
│       ├── settings_screen.dart       # Main settings menu
│       ├── privacy_screen.dart        # Privacy controls
│       ├── notifications_screen.dart  # Notification preferences
│       ├── storage_data_screen.dart   # Cache & media management
│       ├── help_screen.dart           # FAQs & support
│       └── about_screen.dart          # App version & credits
│
├── widgets/                           # Reusable UI components
│   ├── glass_container.dart           # Glassmorphism card/container
│   ├── glass_app_bar.dart             # Frosted glass app bar
│   ├── chat_bubble.dart               # Message bubble widget
│   ├── story_ring.dart                # Status ring indicator
│   ├── user_avatar.dart               # Avatar with online indicator
│   ├── shimmer_loader.dart            # Loading skeleton
│   ├── empty_state.dart               # Empty list illustration
│   ├── bottom_sheet_wrapper.dart      # Glassy bottom sheet base
│   ├── confirmation_dialog.dart       # Styled alert dialogs
│   └── search_bar.dart                # Custom search input
│
├── utils/                             # Helpers & utilities
│   ├── constants.dart                   # App colors, strings, durations
│   ├── extensions.dart                # Dart extensions (String, DateTime)
│   ├── helpers.dart                   # Formatters, validators
│   ├── routes.dart                    # Named route definitions
│   └── theme.dart                     # Light & dark theme data
│
└── generated/                         # Auto-generated files
    └── assets.dart                    # Asset paths (flutter_gen)

    
 ![Splash](assets/screenshots/) 
 ![Signup](assets/screenshots/) 
 ![Login](assets/screenshots/) 
 ![Home](assets/screenshots/) 
 ![Home](assets/screenshots/) 
 ![Library](assets/screenshots/)  
 ![Progress](assets/screenshots/) 
 ![Profile](assets/screenshots/) 
