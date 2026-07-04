# ASCookBook

A personal cookbook app for managing recipes on iOS.

ASCookBook is a native iOS app built with SwiftUI and SwiftData. It lets you browse, search, create, and edit recipes, and import new recipes from photos or pasted text using on-device OCR and the OpenAI API.

> **Note:** The app UI is in German.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Project Structure](#project-structure)
- [Recipe Import](#recipe-import)
- [Permissions](#permissions)
- [Known Limitations](#known-limitations)
- [License](#license)

## Features

- **Recipe list** with alphabetical index bar for quick navigation
- **Search** by recipe name and ingredients
- **Advanced search** with filters for category, season, dietary kind, course type, and up to three ingredients
- **Recipe detail view** with inline editing, photo support, and metadata (category, season, kinds, specials)
- **Manual recipe creation**
- **Photo import** from camera or photo library using Apple Vision OCR and OpenAI
- **Text import** by pasting recipe text, parsed via OpenAI
- **SwiftData persistence** for recipes, categories, and seasons
- **Legacy SQLite migration helpers** for importing data from an older cookbook database (currently disabled in the app entry point)

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5 |
| UI | SwiftUI |
| Persistence | SwiftData |
| On-device OCR | Apple Vision (`VNRecognizeTextRequest`) |
| Recipe parsing | OpenAI API (`gpt-4o-mini`) |
| Minimum iOS | 26.0 |
| Bundle ID | `de.klausdresbach.ASCookBook` |
| Xcode project | `ASCookBook.xcodeproj` |

## Prerequisites

- macOS with Xcode that supports the iOS 26 SDK
- An [OpenAI API key](https://platform.openai.com/api-keys) for photo and text import

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/Taufi/ASCookBook.git
cd ASCookBook
```

### 2. Open the project in Xcode

Open `ASCookBook.xcodeproj` in Xcode.

### 3. Configure the OpenAI API key

The app reads the API key from the `OPENAI_API_KEY` environment variable at runtime (see `ASCookBook/Helpers/Constants.swift`). Do not hardcode API keys in source code.

1. In Xcode, choose **Product → Scheme → Edit Scheme…**
2. Select **Run** in the sidebar
3. Open the **Arguments** tab
4. Under **Environment Variables**, add:
   - **Name:** `OPENAI_API_KEY`
   - **Value:** your OpenAI API key

### 4. Build and run

Select a simulator or connected device, then press **⌘R**.

Photo and text import require a valid `OPENAI_API_KEY`. Other features work without it.

## Project Structure

```
ASCookBook/
├── ASCookBookApp.swift          # App entry point and SwiftData container
├── ContentView.swift            # Main recipe list and navigation
├── RecipeDetailView.swift       # Recipe viewing and editing
├── AdvancedSearchView.swift     # Multi-criteria recipe search
├── RecipeImportViewModel.swift  # Photo and text import orchestration
├── RecipeFromTextView.swift     # Paste-text import UI
├── RecipeListIndexBar.swift     # Alphabetical index bar
├── RecipeRowView.swift          # Recipe list row
├── Models/                      # SwiftData models and enums
├── TextRecognition/             # Vision OCR and OpenAI parsing
├── MigrationHelpers/            # Legacy SQLite import utilities
└── Helpers/                     # Shared utilities (camera, constants, bindings)
```

## Recipe Import

### From a photo

1. The user captures or selects an image.
2. Apple Vision extracts text from the image on device.
3. The recognized text is sent to the OpenAI API.
4. OpenAI returns structured fields (title, ingredients, instructions, servings).
5. A new recipe is created and saved with SwiftData.

### From text

1. The user pastes recipe text (for example from a website or notes).
2. The text is sent directly to the OpenAI API for parsing.
3. A new recipe is created from the structured response.

Imported recipe content is normalized to German, regardless of the source language.

## Permissions

The app requests the following permissions when needed:

- **Camera** — to photograph recipe pages
- **Photo Library** — to attach images to recipes and import from existing photos

## Known Limitations

- The user interface is German-only.
- Photo and text import require a valid `OPENAI_API_KEY`.
- Legacy database migration code exists under `MigrationHelpers/` but is commented out in `ContentView.swift` and is not active by default.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
