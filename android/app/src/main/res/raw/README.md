# Notification Sound Files

This directory contains notification sound files used by the app.

## Required Files

The following MP3 files must be present for notification sounds to work:

1. **alarm_sound.mp3** ✅ (Default - Already exists)
   - The default alarm sound
   - Current file: ~18KB

2. **notification_bell.mp3** ⚠️ (Missing - Add this file)
   - Classic bell notification sound
   - Suggested: Short, clear bell ring (1-2 seconds)

3. **notification_chime.mp3** ⚠️ (Missing - Add this file)
   - Gentle chime sound
   - Suggested: Pleasant musical chime (1-2 seconds)

4. **notification_gentle.mp3** ⚠️ (Missing - Add this file)
   - Soft, gentle notification
   - Suggested: Subtle, non-intrusive sound (1-2 seconds)

5. **notification_urgent.mp3** ⚠️ (Missing - Add this file)
   - Urgent/important notification
   - Suggested: More attention-grabbing, louder (2-3 seconds)

6. **notification_classic.mp3** ⚠️ (Missing - Add this file)
   - Classic notification sound
   - Suggested: Standard notification tone (1-2 seconds)

## File Requirements

- **Format**: MP3 (recommended for Android compatibility)
- **Sample Rate**: 44.1 kHz or 48 kHz
- **Bit Rate**: 128 kbps or higher
- **Duration**: 1-3 seconds (short enough to not be annoying)
- **File Size**: Keep under 100KB each for app size optimization

## Where to Find Sounds

You can find free notification sounds at:
- [Zapsplat](https://www.zapsplat.com/) - Free sound effects
- [Freesound](https://freesound.org/) - Creative Commons sounds
- [Notification Sounds](https://notificationsounds.com/) - Free notification tones
- Create your own using audio editing software

## Adding New Sounds

1. Place the MP3 file in this directory (`android/app/src/main/res/raw/`)
2. File names must be lowercase with no spaces or special characters
3. Use underscores for separation (e.g., `my_sound.mp3`)
4. No rebuild required - sound files are bundled at build time

## Testing

After adding sound files:
1. Run `flutter clean`
2. Run `flutter build apk` or `flutter run`
3. Go to Settings → Notifications in the app
4. Tap the play button next to each sound to preview
5. Select a sound and tap "Send Test Notification" to verify

## Current Status

- ✅ alarm_sound.mp3 - Working
- ⚠️ notification_bell.mp3 - **NEEDS TO BE ADDED**
- ⚠️ notification_chime.mp3 - **NEEDS TO BE ADDED**
- ⚠️ notification_gentle.mp3 - **NEEDS TO BE ADDED**
- ⚠️ notification_urgent.mp3 - **NEEDS TO BE ADDED**
- ⚠️ notification_classic.mp3 - **NEEDS TO BE ADDED**

## Fallback Behavior

If a sound file is missing, the notification will still display but may:
- Use the default system notification sound
- Play silently (no sound)
- Show an error in the debug console

For production, ensure all 6 sound files are present.
