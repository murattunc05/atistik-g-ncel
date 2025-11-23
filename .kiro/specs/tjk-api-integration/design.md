# Design Document

## Overview

This design integrates TJK (Turkish Jockey Club) website data into the Atistik Flutter application. Since TJK doesn't provide a public REST API, we'll use HTTP requests with HTML parsing to extract horse statistics. The architecture follows a clean separation between data layer (API service), domain layer (models), and presentation layer (existing screens).

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌──────────────────────┐    ┌──────────────────────────┐  │
│  │ HorseSearchScreen    │    │  HorseDetailScreen       │  │
│  │  - Search Form       │    │  - Identity Info         │  │
│  │  - Results List      │    │  - Statistics            │  │
│  │  - Loading States    │    │  - Race History          │  │
│  └──────────────────────┘    └──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Horse Model  │  │ RaceHistory  │  │ HorseDetail      │  │
│  │              │  │ Model        │  │ Model            │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            TJK API Service                           │   │
│  │  - searchHorses()                                    │   │
│  │  - fetchHorseDetails()                               │   │
│  │  - _parseSearchResults()                             │   │
│  │  - _parseDetailPage()                                │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  TJK Website  │
                    │  (tjk.org)    │
                    └───────────────┘
```

### Technology Stack

- **HTTP Client**: `http` package for making network requests
- **HTML Parser**: `html` package for parsing HTML responses
- **State Management**: StatefulWidget with setState (keeping it simple, no external state management)
- **Error Handling**: Result pattern with custom Result<T> class

## Components and Interfaces

### 1. TJK API Service (`lib/services/tjk_api_service.dart`)

**Purpose**: Handles all communication with TJK website, including request formation, HTML parsing, and data extraction.

**Key Methods**:

```dart
class TjkApiService {
  static const String _baseUrl = 'https://www.tjk.org';
  static const String _searchUrl = '$_baseUrl/TR/YarisSever/Query/Data/Atlar';
  static const String _refererUrl = '$_baseUrl/TR/YarisSever/Query/Page/Atlar?QueryParameter_OLDUFLG=on';
  static const Duration _timeout = Duration(seconds: 10);

  // Search for horses with filters
  Future<Result<List<Horse>>> searchHorses({
    required String horseName,
    String? breedId,
    String? genderId,
    String? age,
    String? fatherId,
    String? motherId,
    String? ownerId,
    String? trainerName,
    String? countryId,
    bool includeDeceased = true,
  });

  // Fetch detailed statistics for a specific horse
  Future<Result<HorseDetail>> fetchHorseDetails(String detailUrl);

  // Private helper methods
  List<Horse> _parseSearchResults(String htmlContent);
  HorseDetail _parseDetailPage(String htmlContent, Horse baseHorse);
}
```

**HTTP Headers**:
```dart
final headers = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  'Referer': _refererUrl,
};
```

### 2. Result Pattern (`lib/models/result.dart`)

**Purpose**: Provides type-safe error handling without exceptions.

```dart
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result.success(this.data) : error = null, isSuccess = true;
  Result.failure(this.error) : data = null, isSuccess = false;
}
```

### 3. Data Models

#### Horse Model (`lib/models/horse.dart`)

```dart
class Horse {
  final String name;
  final String breed;
  final String gender;
  final String age;
  final String origin;        // Father x Mother
  final String owner;
  final String trainer;
  final String lastRaceSummary;
  final String prizeMoneySummary;
  final String detailLink;    // Relative URL for detail page

  Horse({
    required this.name,
    required this.breed,
    required this.gender,
    required this.age,
    required this.origin,
    required this.owner,
    required this.trainer,
    required this.lastRaceSummary,
    required this.prizeMoneySummary,
    required this.detailLink,
  });

  factory Horse.fromHtmlRow(dom.Element row);
}
```

#### RaceHistory Model (`lib/models/race_history.dart`)

```dart
class RaceHistory {
  final String date;
  final String city;
  final String distance;
  final String trackCondition;  // e.g., "K:Nemli" (Kum:Wet)
  final String position;        // Finishing position
  final String grade;           // Race grade/class
  final String jockey;
  final String prizeMoney;

  RaceHistory({
    required this.date,
    required this.city,
    required this.distance,
    required this.trackCondition,
    required this.position,
    required this.grade,
    required this.jockey,
    required this.prizeMoney,
  });

  factory RaceHistory.fromHtmlRow(dom.Element row);
}
```

#### HorseDetail Model (`lib/models/horse_detail.dart`)

```dart
class HorseDetail {
  final Horse horse;
  final List<RaceHistory> raceHistory;
  
  // Calculated statistics
  final int totalRaces;
  final String totalEarnings;
  final double winPercentage;
  final int podiumFinishes;  // Top 3 finishes

  HorseDetail({
    required this.horse,
    required this.raceHistory,
  }) : totalRaces = raceHistory.length,
       totalEarnings = _calculateTotalEarnings(raceHistory),
       winPercentage = _calculateWinPercentage(raceHistory),
       podiumFinishes = _calculatePodiumFinishes(raceHistory);

  static String _calculateTotalEarnings(List<RaceHistory> races);
  static double _calculateWinPercentage(List<RaceHistory> races);
  static int _calculatePodiumFinishes(List<RaceHistory> races);
}
```

### 4. Updated Horse Search Screen

**State Management**:

```dart
class _HorseSearchScreenState extends State<HorseSearchScreen> {
  final _tjkService = TjkApiService();
  final _horseNameController = TextEditingController();
  
  List<Horse> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _tjkService.searchHorses(
      horseName: _horseNameController.text,
    );

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _searchResults = result.data!;
      } else {
        _errorMessage = result.error;
      }
    });
  }
}
```

### 5. Updated Horse Detail Screen

**Navigation with Arguments**:

```dart
// From search screen
Navigator.pushNamed(
  context,
  '/horse-detail',
  arguments: selectedHorse,
);

// In detail screen
class HorseDetailScreen extends StatefulWidget {
  final Horse horse;
  
  const HorseDetailScreen({super.key, required this.horse});
}

class _HorseDetailScreenState extends State<HorseDetailScreen> {
  final _tjkService = TjkApiService();
  HorseDetail? _horseDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHorseDetails();
  }

  Future<void> _loadHorseDetails() async {
    final result = await _tjkService.fetchHorseDetails(
      widget.horse.detailLink,
    );

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _horseDetail = result.data;
      } else {
        _errorMessage = result.error;
      }
    });
  }
}
```

## Data Models

### HTML Parsing Strategy

**Search Results Table Structure**:
```html
<table id="queryTable">
  <tbody id="tbody0">
    <tr>
      <td class="sorgu-Atlar-AtIsmi"><a href="...">GÜNTAY</a></td>
      <td class="sorgu-Atlar-IrkAdi">İngiliz</td>
      <td class="sorgu-Atlar-Cinsiyet">E</td>
      <td class="sorgu-Atlar-Yas">5</td>
      <td class="sorgu-Atlar-BabaAdi">FATHER x MOTHER</td>
      <td class="sorgu-Atlar-UzerineKosanSahip">Owner Name</td>
      <td class="sorgu-Atlar-Antronoru">Trainer Name</td>
      <td class="sorgu-Atlar-SonKosu">Last Race Info</td>
      <td class="sorgu-Atlar-SadeAtKazanc">Prize Money</td>
    </tr>
  </tbody>
</table>
```

**Detail Page Race History Structure**:
```html
<div id="dataDiv">
  <table id="queryTable">
    <tbody id="tbody0">
      <tr>
        <td>01.05.2024</td>      <!-- Date -->
        <td>İstanbul</td>         <!-- City -->
        <td>1600</td>             <!-- Distance -->
        <td>K:Nemli</td>          <!-- Track Condition -->
        <td>1</td>                <!-- Position -->
        <td>G3</td>               <!-- Grade -->
        ...
        <td>Jokey Name</td>       <!-- Jockey (index 8) -->
        ...
        <td>50000</td>            <!-- Prize Money (index 17) -->
      </tr>
    </tbody>
  </table>
</div>
```

### URL Construction

**Search URL**:
```
GET https://www.tjk.org/TR/YarisSever/Query/Data/Atlar?QueryParameter_AtIsmi=GÜNTAY&QueryParameter_IrkId=-1&QueryParameter_CinsiyetId=-1&QueryParameter_OLDUFLG=on
```

**Detail URL** (relative to base URL):
```
../../YarisSever/Query/Page/AtDetay?QueryParameter_AtId=12345
```

Must be converted to absolute URL using Uri.parse and resolve.

## Error Handling

### Error Types

1. **Network Errors**: No internet connection, DNS failure
2. **Timeout Errors**: Request exceeds 10 seconds
3. **HTTP Errors**: Status code != 200
4. **Parsing Errors**: HTML structure changed or malformed
5. **No Results**: Valid response but no horses found

### Error Messages (Turkish)

```dart
class TjkErrorMessages {
  static const networkError = 'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.';
  static const timeoutError = 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
  static const serverError = 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
  static const parsingError = 'Veri işlenirken hata oluştu.';
  static const noResults = 'Aramanızla eşleşen bir at bulunamadı.';
}
```

### Error Handling Flow

```dart
try {
  final response = await http.get(uri, headers: headers)
      .timeout(_timeout);
  
  if (response.statusCode != 200) {
    return Result.failure(TjkErrorMessages.serverError);
  }
  
  final horses = _parseSearchResults(response.body);
  
  if (horses.isEmpty) {
    return Result.failure(TjkErrorMessages.noResults);
  }
  
  return Result.success(horses);
  
} on TimeoutException {
  return Result.failure(TjkErrorMessages.timeoutError);
} on SocketException {
  return Result.failure(TjkErrorMessages.networkError);
} catch (e) {
  return Result.failure(TjkErrorMessages.parsingError);
}
```

## Testing Strategy

### Unit Tests

1. **Model Tests**: Test fromHtmlRow factory constructors with sample HTML
2. **Parsing Tests**: Test HTML parsing with various edge cases (missing data, malformed HTML)
3. **Calculation Tests**: Test statistics calculations (win percentage, total earnings)

### Integration Tests

1. **API Service Tests**: Mock HTTP responses and test service methods
2. **End-to-End Flow**: Test search → select → detail flow with mock data

### Manual Testing Checklist

1. Search with valid horse name
2. Search with non-existent horse name
3. Search with special characters (Turkish characters: ğ, ü, ş, ı, ö, ç)
4. Test with no internet connection
5. Test with slow network (timeout scenario)
6. Navigate to detail page and verify all data displays correctly
7. Test with horses that have extensive race history (20+ races)
8. Test with horses that have minimal race history (1-2 races)

## Performance Considerations

### Caching Strategy

For future enhancement (not in initial implementation):
- Cache search results for 5 minutes
- Cache detail pages for 10 minutes
- Use `shared_preferences` or `hive` for local caching

### Loading States

- Show shimmer loading effect during search
- Show skeleton screens in detail page while loading
- Implement pull-to-refresh for updating cached data

### Optimization

- Parse HTML in isolate for large responses (if performance issues arise)
- Implement pagination if TJK returns paginated results
- Lazy load race history (load first 10, then "load more" button)

## Security Considerations

1. **User-Agent Spoofing**: Required to bypass bot detection, but used ethically for legitimate app functionality
2. **Rate Limiting**: Implement client-side rate limiting to avoid overwhelming TJK servers
3. **Input Sanitization**: Sanitize user input before including in URLs
4. **HTTPS Only**: All requests use HTTPS for secure communication

## Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  html: ^0.15.4
```

## Migration from Mock Data

1. Keep existing UI components unchanged
2. Replace mock data sources with API service calls
3. Add loading and error states to existing screens
4. Update navigation to pass Horse objects instead of hardcoded data
5. Remove hardcoded mock data from screens
