# Lucky Lotto Information System (LLIS) - Modern Flutter Web

**Developed by:** Kenth Joshua Espina  
**Modernized Stack:** Flutter Web, Dart, SQLite (WASM/In-Memory), Clean Architecture, MultiProvider, Web Text-to-Speech

---

## 1. System Overview & Core Objective
The **Lucky Lotto Information System (LLIS)** is a modern, responsive web application engineered to modernize the legacy VB.NET 2013 / MySQL desktop lotto application into a modern web and offline-capable system.

### Strictly Supported PCSO 6-Number Lotto Games
The system strictly supports only the following **five fixed PCSO 6-number games**:
1. **Ultra Lotto 6/58** (Numbers: 1–58, Exactly 6 unique numbers)
2. **Grand Lotto 6/55** (Numbers: 1–55, Exactly 6 unique numbers)
3. **Super Lotto 6/49** (Numbers: 1–49, Exactly 6 unique numbers)
4. **Mega Lotto 6/45** (Numbers: 1–45, Exactly 6 unique numbers)
5. **Lotto 6/42** (Numbers: 1–42, Exactly 6 unique numbers)

*Note: 6D, 4D, Swertres (3D), EZ2 (2D), STL, and other game types are rejected and excluded by design.*

---

## 2. Lottery Disclaimer
> **"Lottery draws are random. Historical statistics, frequency analysis, and statistical suggestions do not guarantee future winning numbers. This feature is provided for informational and entertainment purposes only."**

All prediction and statistical outputs are designated strictly as **Statistical Suggestions** or **Data-Driven Rankings**, never as guaranteed or sure-win predictions.

---

## 3. Architecture & Project Structure
The solution strictly follows **Clean Architecture** and the **Repository Pattern**:

```text
lib/
├── core/
│   ├── constants/        # LottoConstants (fixed game parameters)
│   ├── database/         # DatabaseExecutor, SQLite/WASM abstraction & seeder
│   ├── errors/           # System failure definitions
│   ├── security/         # PasswordHasher (SHA-256)
│   ├── services/         # TextToSpeechService (browser Web Speech API)
│   └── theme/            # AppTheme (responsive material design)
├── features/
│   ├── authentication/   # AuthService, UserRepository, Login & Register
│   ├── dashboard/        # Client & Administrator responsive consoles
│   ├── lotto_results/    # LottoResultRepository, directory & management
│   ├── lucky_pick/       # LuckyPickService, secure generator & saved picks
│   ├── analytics/        # 1-year historical analytics engine (heatmaps, pairs)
│   ├── predictions/      # Statistical suggestion engine with explanations
│   ├── synchronization/  # PCSO scraper, parser, deduplicator & sync logs
│   ├── notifications/    # In-app match notifications & alerts
│   ├── users/            # Administrator user directory & activation
│   ├── settings/         # Audit logs, sync schedules & password security
│   └── migration/        # Legacy VB.NET MySQL to SQLite importer
├── shared/
│   ├── models/           # Domain entities (User, LottoResult, LuckyPick, etc.)
│   └── widgets/          # LottoBall (3D gradient), Cards, Disclaimer Banner
└── main.dart             # Application root with MultiProvider injection
```

---

## 4. Default Bootstrap Credentials
- **Administrator:** `ADMIN` / `ADMIN` *(Prompted to update password)*
- **Client Player:** `kenth` / `password123`

---

## 5. PCSO Scraping Architecture & Background Service
The system uses the #1 industry-standard background architecture:
- **Playwright Headless Chromium**: Bypasses Akamai WAF and renders PCSO tables with winner counts.
- **SQLite Central Cache**: `llis_central_sync.db` stores 1-year history with instant query response times.
- **Express REST API (Port 8081)**: Serves clean, normalized JSON to the Flutter Web app.
- **Automated Nightly Cron**: Triggers daily at 9:30 PM (21:30 PHT) following official PCSO 9:00 PM draws.

### Running with 1-Click Batch Files:
1. **To run the Full System (Both App + Sync Service):**
   - Double-click **`run_llis_full_system.bat`** in the project root.
   - This launches the Sync Microservice on port 8081, launches the Flutter Web app on port 8080, and opens your browser.

2. **To run only the Background Sync Service:**
   - Double-click **`run_backend_sync.bat`**.
   - Or run in terminal: `cd backend_sync_service && npm start`

---

## 6. How to Run the Application manually

### Prerequisites
- Flutter SDK 3.10+ installed
- Chrome / Edge web browser or Windows desktop runtime

### Running Flutter Web:
```bash
# Get dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome
```

### Running Tests:
```bash
flutter test
```

---

## 7. Legacy MySQL Migration Utility
In the **Administrator Console -> Legacy Import** tab, administrators can paste raw SQL dumps from the legacy VB.NET 2013 application (`Lucky Lotto Database MySQL Folder`). The system parses the tables, re-hashes passwords using SHA-256, validates numbers against game ranges, and migrates records into SQLite.
