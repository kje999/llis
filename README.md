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

## 5. PCSO Scraping Architecture & CORS Gateway
Browser CORS policies prevent direct client-side scraping of `https://www.pcso.gov.ph/searchlottoresult.aspx`.
A dedicated microservice is provided in `backend_sync_service/server.dart` that fetches, parses, validates, and serves standardized JSON with CORS headers:

```bash
# Run the synchronization backend service:
dart run backend_sync_service/server.dart
```

When offline or in standalone web mode, the Flutter application includes an automated resilient fallback mechanism to simulate and process the latest official draws.

---

## 6. How to Run the Application

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
