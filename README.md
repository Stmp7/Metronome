i# Metronome App

A clean, minimal metronome app for iOS built with SwiftUI. This app helps musicians practice rhythm and timing with precise beat tracking and visual feedback.

## Features

- Start/Stop metronome with audible clicks
- Adjustable tempo (40-240 BPM)
- Visual beat indicator
- Time signature selection (2/4, 3/4, 4/4, 6/8)
- Tap tempo functionality
- Background audio support
- Clean, minimal UI design

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
2. Open `Metronome.xcodeproj` in Xcode
3. Build and run the project

## Architecture

The app is built using SwiftUI and follows MVVM architecture:

- `Views/`: Contains all SwiftUI views
- `Models/`: Contains data models and business logic
- `ViewModels/`: Contains view models for state management
- `Services/`: Contains audio and timing services
- `Resources/`: Contains sound assets and other resources

## License

MIT License 