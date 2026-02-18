# Swipe Photo Cleaner

A minimalistic Android app built with Flutter to clean your photo gallery by swiping.

## How It Works

- **Swipe right** → Keep the photo
- **Swipe left** → Mark for deletion
- Tap the **Delete / Keep** buttons as an alternative to swiping
- Photos marked for deletion are batched — confirm deletion when you're done

## Features

- **Swipe to decide** — Tinder-style card swiping for photos
- **Shuffle mode** — Randomize photo order with the shuffle button
- **Fast loading** — Thumbnails are preloaded and cached for instant transitions
- **Smooth animations** — Quick 200ms swipe transitions with fade-in
- **Batch delete** — Review and confirm all deletions at once
- **Live counter** — See how many photos remain, kept, and marked for deletion
- **Dark mode** — Follows system theme automatically
- **Haptic feedback** — Subtle vibration on each swipe

## Build

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

## Requirements

- Flutter SDK 3.10+
- Android SDK (min API 21)

## Project Structure

```
lib/
├── main.dart                  # App entry, theme config
├── screens/
│   └── home_screen.dart       # Main swipe UI, stats, done screen
├── services/
│   └── gallery_service.dart   # Photo loading & deletion via photo_manager
└── widgets/
    ├── photo_card.dart        # Image card with cache & preloading
    └── swipe_overlay.dart     # Keep/delete visual feedback overlay
```

## Permissions

- `READ_MEDIA_IMAGES` — Access photos (Android 13+)
- `READ_EXTERNAL_STORAGE` — Access photos (Android 12 and below)
- `ACCESS_MEDIA_LOCATION` — Photo metadata

## License

MIT
