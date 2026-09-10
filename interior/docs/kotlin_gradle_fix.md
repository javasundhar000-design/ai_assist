# Fixing "Android Gradle plugin supports only Kotlin Gradle plugin
version 1.5.20 and higher" (ar_flutter_plugin) — and the Flutter
upgrade that followed

## Timeline of this issue

1. **Attempt 1** — added `resolutionStrategy.force` to the root
   `android/build.gradle`'s `buildscript` block. Confirmed insufficient:
   same error persisted. Likely cause: this project's template uses
   Flutter's newer plugin-loading architecture, and `ar_flutter_plugin`
   requests `kotlin-android` through Gradle's plugin-resolution
   mechanism, not the classic buildscript classpath this fix targeted.

2. **Attempt 2** — pre-registered a modern Kotlin plugin version
   (`org.jetbrains.kotlin.android` `1.7.10`) in `android/settings.gradle`'s
   top-level `plugins { }` block, before any subproject could request
   its own. Reasoned fix, not independently verified at the time.

3. **Flutter was upgraded** from 3.16.7 (Dart 3.2.4) to **3.47.1**
   (Dart 3.13.1) in between attempts. This surfaced a *different* error:
   ```
   Kotlin Gradle Plugin <-> Gradle compatibility issue:
   The applied Kotlin Gradle is not compatible with the used Gradle
   version (Gradle 7.5). Solution: Please update the Gradle version to
   at least Gradle 7.6.3.
   ```
   This error comes from **Flutter's own internal build script**
   (`flutter_tools/gradle/build.gradle.kts`), not from `ar_flutter_plugin`.
   It means: the project's `android/gradle/wrapper/gradle-wrapper.properties`
   still specifies Gradle 7.5 (correct for the old Flutter 3.16.7
   template), but Flutter 3.47.1's bundled tooling now requires a newer
   Gradle to even run its own build scripts.

## The fix: regenerate `android/` from scratch, now that Flutter is current

I don't have training data on Flutter 3.47.1's template specifics (it
postdates my knowledge), so guessing at more individual version numbers
(Gradle wrapper, AGP, Kotlin) risks a fourth round of trial and error.
Letting Flutter generate its own template is guaranteed self-consistent
with whatever you have installed:

```powershell
# from the project root
rmdir /s /q android
flutter create --org com.yourcompany --project-name interior_ar_app .
```

This only touches `android/` (and `ios/` if you do the same for iOS) —
your `lib/` code is untouched.

### Checklist: re-apply after regenerating

A fresh `android/` folder won't have any of this project's earlier
native setup. Re-apply, in this order:

1. **Firebase**: re-run `flutterfire configure` (this both regenerates
   `lib/firebase_options.dart` with real values AND wires
   `google-services.json` + the Gradle plugin into the new `android/`
   automatically — more reliable than manually copying the old
   `google-services.json` into the new folder).
2. **Camera permission** (`android/app/src/main/AndroidManifest.xml`,
   inside `<manifest>`):
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-feature android:name="android.hardware.camera" android:required="false" />
   ```
3. **ARCore support** (same file, inside `<application>`):
   ```xml
   <meta-data android:name="com.google.ar.core" android:value="optional" />
   ```
4. **`minSdkVersion`**: set to at least `24` in
   `android/app/build.gradle` (ARCore's requirement; higher than the
   camera plugin's own minimum of 21).
5. **The `ar_flutter_plugin` Kotlin fix (Attempt 2)**: re-apply the
   `settings.gradle` pre-registration —
   ```groovy
   plugins {
       id "dev.flutter.flutter-plugin-loader" version "1.0.0"
       id "com.android.application" version "..." apply false   // whatever the fresh template generated
       id "org.jetbrains.kotlin.android" version "1.9.20" apply false   // bump target version; see note below
       id "com.google.gms.google-services" version "..." apply false   // added by flutterfire configure
   }
   ```
   and in `android/app/build.gradle`'s `plugins { }` block, use
   `id "org.jetbrains.kotlin.android"` instead of `id "kotlin-android"`.
   **Note**: with Flutter 3.47.1, the fresh template's own Kotlin
   version is likely already well above 1.7.10 — check what
   `flutter create` generated first, and only add the explicit
   `apply false` line if `ar_flutter_plugin` still complains after
   regenerating (it may not need it at all if the fresh template's
   default Kotlin version already satisfies whatever `ar_flutter_plugin`
   needs — try running first *without* this step, and only add it back
   if the original 1.3.50 error reappears).

Then: `flutter clean && flutter pub get && flutter run`.

## Worth stepping back on

This is now the **third** Gradle-related failure in a row, and all
three trace back to the same root cause: `ar_flutter_plugin` is old and
poorly maintained, clashing harder with modern tooling each time the
surrounding ecosystem moves forward. Two reasoned fixes have already
gone into patching around it. If regenerating `android/` and reapplying
the Attempt 2 fix *still* doesn't resolve the original Kotlin version
error, the better use of time is very likely migrating off
`ar_flutter_plugin` entirely — to platform-specific
`arcore_flutter_plugin` (Android) + `arkit_plugin` (iOS) behind the
same `ArSessionService` interface already built in this project
(`lib/features/ar_visualization/services/ar_session_service.dart`).
That interface exists specifically so this is a contained rewrite of
one file's internals, not a redesign of the AR feature — bounded work
I can execute reliably, versus continued Gradle archaeology I can't
verify. Say the word if you'd rather do that now instead of another
round of patching.
