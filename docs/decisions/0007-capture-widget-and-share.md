# 0007: The capture dialog is a small Flutter screen; the widget and share target are plain Android

- **Status:** Accepted
- **Date:** 2026-11-16
- **Decided by:** FINUSAM, 2026-11-16 (after trying both approaches on the phone: "both A and B is very good, so lets go with A"); the record, including its manifest changes, approved by the owner 2026-11-16
- **Related:** M6; PRD 8.5, 10, 13; [E-009](../PRD_Edits.md#e-009-the-v1-home-screen-widget-opens-a-lightweight-text-capture-dialog), [E-017](../PRD_Edits.md#e-017-shared-text-opens-the-capture-dialog-filled-in); AT-099, AT-100; wireframes 13 to 17 in [`docs/design/m6-capture/`](../design/m6-capture/); [plan 0008](../plans/0008-m6-capture.md); #48, #50

## Context

An Android home-screen widget can't hold a text field, so the v1 widget is a button that opens a small capture dialog over whatever is on screen, without opening the full app (E-009). Text shared from another app opens the same dialog, filled in (E-017). Save stores a capture and its `captured` event in one transaction (PRD 13).

Three things had to be found out on the phone (OnePlus, OxygenOS) before writing PR 2:

1. Whether the dialog can be a second, small Flutter screen, and how fast it opens.
2. How it reaches `sahai.sqlite` safely while the main app may have the same file open.
3. Whether the packages named in the tech plan (`home_widget` 0.10.0, `receive_sharing_intent` 1.9.0) are needed at all.

The rules that apply: no network, no telemetry, data stays on the device, no new permission or package without the owner's approval, and capture text is never logged.

## What the spike tried

The spike (branch `spike/m6-widget-share`, never merged) installed as a separate app, "Sahai spike" (`com.finusam.sahai.spike`), with its own empty database, next to the real Sahai. It built both approaches side by side, each with its own widget and its own share entry. With the owner's agreement, it tried our own Kotlin before the packages, and came back to the packages only if both failed. Neither failed.

- **A: a small Flutter screen.** A see-through Android activity runs a second Dart entry point, `captureMain`, which shows only the dialog, not the whole app. Save writes straight into the database.
- **B: a plain Android dialog.** An `AlertDialog` in Kotlin. Save appends the text to a hand-off file, and the app moves it into the database by id when it opens or comes back on screen.

Measured on the phone through adb. "Opened" is from the tap or share to the dialog on screen.

| | A (Flutter) | B (Android) |
|---|---|---|
| Opened, app not running | 648 ms, 969 ms (first run after an install) | 212 ms |
| Opened, app running | 117 to 153 ms | 47 ms |
| Save | 13 to 78 ms | Not timed; shows in the app when it opens or comes back |
| Shows over the current app, filled in | Yes | Yes |
| Keyboard up on open | Yes, after a fix (below) | Yes |
| Saved while the app's Capture list was open | Showed straight away | Showed straight away |
| Duplicates after leaving and coming back | None | None |

The owner then used both widgets and shared from Chrome, and found both very good. WhatsApp has no "share to another app" for a chat message (its own Forward stays inside WhatsApp), so WhatsApp text was covered by opening a link in Chrome and sharing from there. Dark mode was not tried.

## Decision

**Approach A.** The dialog looks like the rest of Sahai, writes straight into the database (so no hand-off file and no import step), and opens fast enough that the owner was happy with it.

1. **The dialog** is a `FlutterActivity` subclass that starts the Dart entry point `captureMain` (marked `@pragma('vm:entry-point')` in `lib/main.dart`, so release builds keep it) with a transparent background. It's its own small task: it doesn't appear in Recents, and closing it returns to whatever was on screen.
2. **The database.** The main app's `databaseProvider` opens the file with `driftDatabase(name: 'sahai', native: const DriftNativeOptions(shareAcrossIsolates: true))`. The dialog opens it the same way and closes it after Save. Both run in the same Android process, so drift gives them one shared connection, and the file is never written through two connections at once. In the spike, a capture saved while the app's list was open showed in the list as soon as the dialog closed. It wasn't checked whether drift told the list about the change or the list simply read again when the app came back; PR 2's tests should settle it. This is an option of `drift_flutter` 0.3.1, which is already a dependency.
3. **The keyboard.** The text field asks for the keyboard on Flutter's first frame, which comes before Android gives the see-through window focus, so Android ignores it. The activity tells the dialog over a method channel when its window first gets focus, and the dialog asks again then.
4. **The widget** is a plain `AppWidgetProvider`: a fixed layout (frame 13) whose tap opens the dialog through an immutable `PendingIntent`. It never updates, so there's no update schedule and nothing for Flutter to push to it.
5. **The share target** is an intent filter (`SEND`, `text/plain`) on the dialog activity. The activity hands the shared text and the source (`widget` or `share`) to Dart over the same channel, and the source goes in the `captured` event's payload.
6. **No packages and no permissions.** `home_widget` and `receive_sharing_intent` aren't added.
7. **No logging of text.** The spike logged timings to Logcat to measure them. PR 2 logs nothing (tech plan, logging).

### Android changes PR 2 makes (for the owner's approval)

Class, resource and label names are the ones PR 2 will use; the spike's are prefixed "Spike". The application ID, app name and permissions don't change.

`AndroidManifest.xml`, inside `<application>`:

```xml
<activity
    android:name=".CaptureActivity"
    android:label="Sahai"
    android:exported="true"
    android:excludeFromRecents="true"
    android:taskAffinity=""
    android:theme="@style/CaptureTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize|stateVisible">
    <intent-filter>
        <action android:name="android.intent.action.SEND"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <data android:mimeType="text/plain"/>
    </intent-filter>
</activity>
<receiver
    android:name=".CaptureWidget"
    android:label="Capture a thought"
    android:exported="false">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/capture_widget_info"/>
</receiver>
```

- `exported="true"` on the activity is what lets other apps share to it. It accepts only plain text, and Save is always the user's tap. The widget receiver isn't exported.
- `res/values/styles.xml` gains `CaptureTheme`: parent `@android:style/Theme.Translucent.NoTitleBar`, with a transparent window background, `windowIsTranslucent` true and no system dim (the dialog draws its own).
- New resources: `res/xml/capture_widget_info.xml` (4 × 1 cells, resizes sideways, `updatePeriodMillis="0"`, home screen only), `res/layout/capture_widget.xml` (frame 13), and its rounded background drawable.
- New Kotlin: `CaptureActivity.kt` and `CaptureWidget.kt`, about 80 lines together.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| B: a plain Android dialog with a hand-off file | Opens in about 0.2 s cold, 0.05 s warm | Looks like stock Android, not Sahai; a second save path in Kotlin; captures only appear once the app opens, so a capture lives in a file outside the database until then | The owner preferred A; one save path, in Dart, with the database's transaction and event |
| `home_widget` 0.10.0 | Ready-made bridge for pushing data from Flutter to a widget | Our widget never shows data, so the bridge isn't used; one more dependency to keep up to date | Not needed |
| `receive_sharing_intent` 1.9.0 | Handles many share types (files, images) | We only take plain text, which is one intent filter and a few lines; one more dependency | Not needed |
| The dialog opens the full app instead | Nothing new to build | Breaks E-009's "without opening the full app" | Ruled out by E-009 |

## Consequences

- **A cold open takes about 0.65 to 1 s** on the owner's phone, because a Flutter engine has to start. That was acceptable to the owner. If it ever isn't, B's approach (shown working in the spike) is the fallback, and this record would be superseded.
- **The database setting changes for the whole app** (`shareAcrossIsolates: true`). It's an option of the package we already use, and changes nothing on disk, so there's no migration. If the dialog is ever moved to its own Android process, this no longer covers it and must be revisited.
- **`lib/main.dart` gets a second entry point.** It must stay small (theme, database, the dialog) so it opens quickly; it mustn't start notifications or the full router.
- **Tests:** the dialog screen and its save are Flutter code, so they get widget tests. Opening from the widget, opening over another app, the keyboard, and sharing from Chrome are device-only checks, listed in PR 2.
- **OxygenOS is the only test phone.** Other phone makers treat see-through activities and widgets differently; that's a risk for later releases, not v1.
