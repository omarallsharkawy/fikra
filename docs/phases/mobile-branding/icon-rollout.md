# Brand icon rollout

## Scope

Apply the supplied light/dark FIKRAH artworks to the Android launcher and visible app branding. Preserve user data, account behavior, navigation and the existing production identifiers. The user approved both launcher and in-app placement.

## Steps

1. Bundle the original artwork and expose one theme-aware decorative widget.
2. Add it to product headers and the legacy welcome/About surfaces.
3. Replace Flutter launcher placeholders with day/night bitmap resources and masked adaptive icons.
4. Validate image loading, theme changes and narrow/large-text layouts; build and install the APK on the attached Xiaomi device.

See [appearance and resource details](../../features/themed-brand-icons/appearance.md).

## Development machine resources

The physical Xiaomi phone is the Android runtime target over USB. No desktop Android emulator or IDE is required. Flutter and Gradle compile on the laptop before ADB installs the result on the phone.

Following the user's resource concern, the validation build uses low CPU/I/O priority, two allowed CPU cores, one Gradle worker, a 1024 MiB Java heap, 384 MiB metaspace and one native build worker. These are development-machine limits, not application behavior or production configuration. A lower limit can take longer to finish. Use a retained debug session and hot reload for later Dart-only UI iteration; launcher/native resource changes still require a rebuild.

## Verification

- Focused brand, welcome and product-navigation widget tests: 19 passed.
- Flutter analysis: no issues.
- Android profile APK built successfully from `da29dbe` in 113 seconds with the resource limits above. The initial build session was interrupted by a laptop restart; the completed build used the limited settings.
- APK SHA-256: `9c3acfd96358a4c93457d2b98e1d34b3aed03d53af9926a736ad5e44263faa18`.
- `adb install -r` succeeded on the attached Xiaomi M2010J19SG. A cold launch reported `Status: ok`. The original application package was not replaced; the existing profile identifier remains `com.fikra.app.stress`.
- Device screenshots verified the lime dark-theme mark beside FIKRAH in the account header and the native icon in Android's App info screen. The application was returned to the foreground afterwards. Device system appearance was not changed; light-mode selection is covered by widget/image checks and packaged resource inspection.
- `aapt2 dump resources` confirmed the day/night artwork/backgrounds and the standard/adaptive launcher resources. No emulator or Android Studio was installed or run.
