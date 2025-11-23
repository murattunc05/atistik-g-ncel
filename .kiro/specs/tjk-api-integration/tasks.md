# Implementation Plan

- [ ] 1. Add required dependencies to pubspec.yaml
  - Add `http: ^1.1.0` package for HTTP requests
  - Add `html: ^0.15.4` package for HTML parsing
  - Run `flutter pub get` to install dependencies
  - _Requirements: 1.1, 2.2_

- [ ] 2. Create data models for type-safe data handling
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 2.1 Create Result class for error handling
  - Create `lib/models/result.dart` file
  - Implement Result<T> class with success and failure constructors
  - Add isSuccess getter and data/error fields
  - _Requirements: 5.4_

- [ ] 2.2 Create Horse model
  - Create `lib/models/horse.dart` file
  - Define Horse class with all required fields (name, breed, gender, age, origin, owner, trainer, lastRaceSummary, prizeMoneySummary, detailLink)
  - Implement fromHtmlRow factory constructor that parses HTML table row elements
  - Handle missing or null values with default empty strings
  - _Requirements: 5.1, 5.4, 5.5_

- [ ] 2.3 Create RaceHistory model
  - Create `lib/models/race_history.dart` file
  - Define RaceHistory class with fields (date, city, distance, trackCondition, position, grade, jockey, prizeMoney)
  - Implement fromHtmlRow factory constructor for parsing race history table rows
  - Handle missing data gracefully with null safety
  - _Requirements: 5.2, 5.4, 5.5_

- [ ] 2.4 Create HorseDetail model with calculated statistics
  - Create `lib/models/horse_detail.dart` file
  - Define HorseDetail class containing Horse object and List<RaceHistory>
  - Implement calculated fields: totalRaces, totalEarnings, winPercentage, podiumFinishes
  - Write private helper methods for statistics calculations
  - _Requirements: 5.3, 5.4, 2.5_

- [ ] 3. Implement TJK API Service for web scraping
  - _Requirements: 1.1, 1.2, 1.5, 2.2, 2.3, 4.4_

- [ ] 3.1 Create TjkApiService class structure
  - Create `lib/services/tjk_api_service.dart` file
  - Define class constants for URLs, timeout duration, and HTTP headers
  - Set up User-Agent and Referer headers to mimic browser requests
  - _Requirements: 1.5_

- [ ] 3.2 Implement searchHorses method
  - Create searchHorses method with parameters for all search filters (horseName, breedId, genderId, age, fatherId, motherId, ownerId, trainerName, countryId, includeDeceased)
  - Build query parameters map from provided filters
  - Make HTTP GET request to TJK search URL with proper headers
  - Implement timeout handling (10 seconds)
  - Return Result<List<Horse>> with success or error
  - _Requirements: 1.1, 1.5, 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 3.3 Implement HTML parsing for search results
  - Create private _parseSearchResults method
  - Parse HTML response using html package
  - Find table with id="queryTable" and tbody with id="tbody0"
  - Extract each row and create Horse objects using fromHtmlRow
  - Skip rows with class "hidable"
  - Return list of Horse objects
  - _Requirements: 1.2_

- [ ] 3.4 Implement fetchHorseDetails method
  - Create fetchHorseDetails method that accepts relative detail URL
  - Convert relative URL to absolute URL using Uri.parse and resolve
  - Replace HTML entities (&amp; to &)
  - Make HTTP GET request to detail page
  - Return Result<HorseDetail> with parsed data or error
  - _Requirements: 2.2, 2.3_

- [ ] 3.5 Implement HTML parsing for detail page
  - Create private _parseDetailPage method
  - Find div with id="dataDiv" containing race history table
  - Parse table with id="queryTable" and tbody with id="tbody0"
  - Extract race history rows and create RaceHistory objects
  - Create HorseDetail object with horse data and race history list
  - _Requirements: 2.3_

- [ ] 3.6 Add comprehensive error handling
  - Wrap HTTP requests in try-catch blocks
  - Handle TimeoutException with appropriate error message
  - Handle SocketException for network errors
  - Handle HTTP status codes != 200
  - Handle parsing errors when HTML structure is unexpected
  - Return Result.failure with Turkish error messages
  - _Requirements: 3.1, 3.2, 3.4_

- [ ] 4. Update Horse Search Screen to use real API
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.3, 3.5, 4.1, 4.2, 4.3, 4.4_

- [ ] 4.1 Add state management for API integration
  - Add TjkApiService instance to _HorseSearchScreenState
  - Add state variables: _searchResults (List<Horse>), _isLoading (bool), _errorMessage (String?)
  - Create _performSearch async method that calls API service
  - Update setState to handle loading, success, and error states
  - _Requirements: 1.1, 3.5_

- [ ] 4.2 Add loading indicator during search
  - Show CircularProgressIndicator when _isLoading is true
  - Display loading indicator in center of results area
  - Hide results and error messages while loading
  - _Requirements: 3.5_

- [ ] 4.3 Display error messages to user
  - Show error message in red text when _errorMessage is not null
  - Add "Tekrar Dene" (Retry) button below error message
  - Clear error message when starting new search
  - _Requirements: 3.3, 3.4_

- [ ] 4.4 Update search results display with real data
  - Replace mock _buildSearchResults with dynamic list from _searchResults
  - Update _buildResultCard to accept Horse object and display real data
  - Show horse name, breed, gender, age in result cards
  - Display "Aramanızla eşleşen bir at bulunamadı" when results are empty
  - _Requirements: 1.2, 1.3, 1.4_

- [ ] 4.5 Update navigation to pass Horse object
  - Modify onTap in result cards to pass selected Horse object to detail screen
  - Use Navigator.pushNamed with arguments parameter
  - _Requirements: 2.1_

- [ ] 5. Update Horse Detail Screen to display real data
  - _Requirements: 2.1, 2.4, 2.5, 2.6_

- [ ] 5.1 Update screen to accept Horse parameter
  - Change HorseDetailScreen from StatelessWidget to StatefulWidget
  - Add Horse parameter to constructor
  - Update route configuration in main.dart to extract arguments
  - _Requirements: 2.1_

- [ ] 5.2 Add state management for detail page loading
  - Add TjkApiService instance to state
  - Add state variables: _horseDetail (HorseDetail?), _isLoading (bool), _errorMessage (String?)
  - Create _loadHorseDetails async method in initState
  - Call fetchHorseDetails with horse.detailLink
  - _Requirements: 2.2_

- [ ] 5.3 Display loading state while fetching details
  - Show shimmer or skeleton screen while _isLoading is true
  - Keep app bar visible during loading
  - _Requirements: 2.2_

- [ ] 5.4 Update identity section with real horse data
  - Replace hardcoded values in _buildIdentitySection with data from _horseDetail
  - Display age, gender, color (from breed), father/mother (parse from origin), owner, trainer
  - Handle null values gracefully
  - _Requirements: 2.4_

- [ ] 5.5 Update statistics section with calculated data
  - Replace mock statistics with calculated values from HorseDetail
  - Display totalRaces, totalEarnings, winPercentage, podiumFinishes
  - Format numbers appropriately (e.g., ₺ symbol for money, % for percentage)
  - _Requirements: 2.5_

- [ ] 5.6 Update race history section with real data
  - Replace mock race history with data from _horseDetail.raceHistory
  - Update _buildRaceHistoryCard to accept RaceHistory object
  - Display date, city, position, track condition, jockey, distance
  - Show position badge with color (gold for 1st, silver for 2nd, bronze for 3rd)
  - _Requirements: 2.6_

- [ ] 5.7 Add error handling for detail page
  - Display error message if detail fetch fails
  - Add retry button for failed requests
  - Show fallback UI if race history is empty
  - _Requirements: 3.3_

- [ ] 6. Update main.dart route configuration
  - Modify '/horse-detail' route to extract Horse argument from ModalRoute
  - Pass Horse object to HorseDetailScreen constructor
  - Handle case where arguments are null (navigate back or show error)
  - _Requirements: 2.1_

- [ ] 7. Test the complete integration flow
  - _Requirements: All_

- [ ] 7.1 Test search functionality with various inputs
  - Test search with valid horse name (e.g., "GÜNTAY")
  - Test search with non-existent horse name
  - Test search with Turkish characters (ğ, ü, ş, ı, ö, ç)
  - Verify search results display correctly
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 7.2 Test detail page navigation and data display
  - Select a horse from search results
  - Verify navigation to detail page works
  - Verify all identity information displays correctly
  - Verify statistics are calculated and displayed
  - Verify race history shows all races
  - _Requirements: 2.1, 2.4, 2.5, 2.6_

- [ ] 7.3 Test error scenarios
  - Test with airplane mode (no internet)
  - Verify timeout handling (if possible to simulate)
  - Verify error messages display in Turkish
  - Test retry functionality
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 7.4 Test edge cases
  - Test with horses that have no race history
  - Test with horses that have 20+ races
  - Test with special characters in search
  - Test rapid consecutive searches
  - _Requirements: All_
