# StudyDiary

A simple Flutter app that helps students keep track of how they study their hardest subjects.

**Course:** STTPK2143 Mobile Application Development (Assignment 1)

**Name:** HIMAKARTINI A/P JEEVAN 

**Matric Number:** 309751



## 1. App Purpose

Many students find some subjects harder than others but they rarely record how they studied those subjects or whether the study method worked. StudyDiary lets a student log each study session like what they studied, the subject, method they used to studied (watch video, write notes, practice questions, ask for help) how long it took and how well they understood the topic afterwards (using rating of 1 to 5).

Low understanding scores appear as red circles in the list, so weak subjects and ineffective study methods are easy to spot. All data is stored locally on the device with SQLite.

**Intended users:** school and university students

## 2. Record Fields

Each study log has the following fields.

| Field | Input control | Rules |
|---|---|---|
| Title (topic) | Text field | Required, 3 to 50 characters |
| Subject | Dropdown | Required: Mathematics, Science, Programming, Languages, Business, Other |
| Study method | Radio buttons | Watch video, Write notes, Practice questions, Ask for help (default: Watch video) |
| Time spent | Number field | Required, whole number from 1 to 600 minutes |
| Understanding | Slider | 1 to 5 (default: 3) |
| Notes | Multi-line text field | Optional |

## 3. Database Structure

The app uses the `sqflite` package. The database file is `studydiary.db` and it contains one table.

**Table: `study_logs`**

| Column | Type | Description |
|---|---|---|
| id | INTEGER PRIMARY KEY AUTOINCREMENT | Unique record ID |
| title | TEXT NOT NULL | Topic studied |
| subject | TEXT NOT NULL | Selected subject |
| activity | TEXT NOT NULL | Study method |
| minutes | INTEGER NOT NULL | Time spent in minutes |
| understanding | INTEGER NOT NULL | Understanding score from 1 to 5 |
| notes | TEXT NOT NULL | Notes (empty string if none) |
| created_at | TEXT NOT NULL | ISO 8601 timestamp of creation |

The database methods are in `lib/study_database.dart`: `insertLog`, `getLogs` (with `LIMIT` and `OFFSET`), `getLogCount`, `updateLog`, and `deleteLog`.

## 4. Project Structure

```
lib/
  main.dart            Starts the app and switches from the splash screen after 3 seconds
  splashscreen.dart    Welcome screen
  mainscreen.dart      Paginated list, details dialog, delete, refresh
  studyform.dart       Add and edit form with validation and confirmation
  study_database.dart  SQLite database access
```

## 5. Setup Steps

1. Install the Flutter SDK and an Android emulator or a physical device.
2. Clone the repository:
   ```
   git clone https://github.com/himz-27/Study-Track-App-flutter-.git
   cd Study-Track-App-flutter-
   ```
3. Install the dependencies:
   ```
   flutter pub get
   ```
4. Run the app:
   ```
   flutter run
   ```

**Dependencies** (in `pubspec.yaml`):
- `sqflite` for local SQLite storage
- `path` for building the database file path

## 6. Main Flow

1. **Splash screen:** shown for 3 seconds, then the home screen appears.
2. **Home screen:** shows saved study logs, newest first, 10 per page. The bottom controls show the current page and Previous and Next buttons. With no records, an empty message is shown and both buttons are disabled.
3. **Add a log:** tap the **+** button, fill in the form, and tap **Add log**. Invalid input shows error messages. When the input is valid, a confirmation dialog appears. **Confirm** saves the record and returns to page 1. **Cancel** leaves the record unsaved.
4. **View details:** tap a record to see all its fields.
5. **Edit a log:** tap **Edit** in the details dialog. The form is prefilled. After validation and confirmation, only that record is updated.
6. **Delete a log:** long-press a record and confirm. Cancel keeps the record. If the last page becomes empty, the app moves to the nearest valid page.
7. **Refresh:** the refresh button in the app bar reloads the current page.

## 7. Credits

**Code**
- The overall project structure and coding style (splash screen, main list screen with pagination, form screen with validation and confirmation dialog, and a singleton SQLite database class) follow the example budget app provided by my lecturer Encik Ahmad Hanis Bin Mohd Shabli. The code was rewritten for a different app idea, with a different data model and an edit feature was added.
- Flutter and the Material 3 widgets are from the Flutter framework
- Database access uses the `sqflite` ,`path` packages from pub.dev.

**Icons and images**
- All icons come from Flutter's built-in Material Icons. No external images, fonts or other assets are used.
