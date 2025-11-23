# Requirements Document

## Introduction

This feature integrates real-time horse statistics from the TJK (Turkish Jockey Club) website into the Atistik mobile application. The system will fetch horse search results and detailed race history data from TJK's web platform and display them in the existing Flutter UI screens.

## Glossary

- **TJK_API_Service**: The Dart service that communicates with TJK website endpoints
- **Horse_Search_Screen**: The existing Flutter screen where users search for horses
- **Horse_Detail_Screen**: The existing Flutter screen that displays detailed horse information
- **TJK_Website**: The Turkish Jockey Club website (tjk.org) that provides horse racing data
- **Web_Scraping**: The process of extracting data from HTML responses
- **HTTP_Client**: The Dart HTTP library used to make network requests

## Requirements

### Requirement 1

**User Story:** As a user, I want to search for horses by name on TJK website, so that I can see real horse data instead of mock data

#### Acceptance Criteria

1. WHEN the user enters a horse name and taps "Atları Bul", THE TJK_API_Service SHALL send an HTTP GET request to "https://www.tjk.org/TR/YarisSever/Query/Data/Atlar" with the horse name as a query parameter
2. WHEN the TJK_Website returns search results, THE TJK_API_Service SHALL parse the HTML response and extract horse data including name, breed, gender, age, origin, owner, trainer, last race summary, and prize money
3. IF the TJK_Website returns no matching horses, THEN THE Horse_Search_Screen SHALL display a message "Aramanızla eşleşen bir at bulunamadı"
4. WHEN multiple horses match the search query, THE Horse_Search_Screen SHALL display a list of all matching horses with their names and basic information
5. THE TJK_API_Service SHALL include proper User-Agent and Referer headers to ensure requests are accepted by the TJK_Website

### Requirement 2

**User Story:** As a user, I want to view detailed race history for a selected horse, so that I can analyze the horse's past performance

#### Acceptance Criteria

1. WHEN the user taps on a horse from the search results, THE Horse_Detail_Screen SHALL navigate to the detail view with the selected horse's data
2. WHEN the Horse_Detail_Screen loads, THE TJK_API_Service SHALL fetch detailed statistics by following the horse's detail link from the search results
3. THE TJK_API_Service SHALL parse the detail page and extract race history including date, city, distance, track condition, position, grade, jockey name, and prize money for each race
4. THE Horse_Detail_Screen SHALL display the horse's identity information (age, gender, color, father, mother, owner, trainer) in the "Kimlik Bilgileri" section
5. THE Horse_Detail_Screen SHALL display calculated statistics (total races, total earnings, win percentage, podium finishes) in the "İstatistikler" section
6. THE Horse_Detail_Screen SHALL display the complete race history in chronological order in the "Geçmiş Koşuları" section

### Requirement 3

**User Story:** As a user, I want the app to handle network errors gracefully, so that I understand when data cannot be fetched

#### Acceptance Criteria

1. IF the HTTP request to TJK_Website fails due to network connectivity, THEN THE TJK_API_Service SHALL return an error result with message "İnternet bağlantısı hatası"
2. IF the HTTP request times out after 10 seconds, THEN THE TJK_API_Service SHALL cancel the request and return a timeout error
3. WHEN a network error occurs, THE Horse_Search_Screen SHALL display an error message to the user with an option to retry
4. IF the TJK_Website returns an HTTP status code other than 200, THEN THE TJK_API_Service SHALL return an error with the status code
5. THE Horse_Search_Screen SHALL show a loading indicator while the search request is in progress

### Requirement 4

**User Story:** As a user, I want to search horses using additional filters (breed, gender, age, country), so that I can narrow down my search results

#### Acceptance Criteria

1. THE Horse_Search_Screen SHALL provide dropdown fields for breed selection with option "-1" for all breeds
2. THE Horse_Search_Screen SHALL provide dropdown fields for gender selection with option "-1" for all genders
3. THE Horse_Search_Screen SHALL provide text input fields for age, father name, mother name, owner name, and trainer name
4. WHEN the user fills any combination of search filters and taps "Atları Bul", THE TJK_API_Service SHALL include all non-empty filter values in the query parameters
5. THE TJK_API_Service SHALL include the parameter "QueryParameter_OLDUFLG=on" to include deceased horses in search results

### Requirement 5

**User Story:** As a developer, I want the data models to be strongly typed, so that the code is maintainable and type-safe

#### Acceptance Criteria

1. THE TJK_API_Service SHALL define a Horse data model class with fields for all horse attributes (name, breed, gender, age, origin, owner, trainer, detailLink, lastRace, prizeMoney)
2. THE TJK_API_Service SHALL define a RaceHistory data model class with fields for all race attributes (date, city, distance, trackCondition, position, grade, jockey, prizeMoney)
3. THE TJK_API_Service SHALL define a HorseDetail data model class that includes Horse data plus a list of RaceHistory entries
4. WHEN parsing HTML responses, THE TJK_API_Service SHALL handle missing or malformed data by using default values or null safety
5. THE data model classes SHALL implement fromJson factory constructors for parsing HTML-extracted data
