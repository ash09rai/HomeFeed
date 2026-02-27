# HomeFeed

A reusable, configuration-driven home feed module for iOS applications.

`HomeFeed` is built with SwiftUI and Combine, follows Clean Architecture, and keeps networking ownership in the client application. The module validates configuration before execution, skips unsupported sections safely, renders from a shared `FeedItem` bridge model, and conditionally enables persistence with SwiftData on iOS 17+.

## Requirements

- iOS 16.0+
- SwiftUI
- Combine
- SwiftData is used automatically on iOS 17+ when persistence mode is `.automatic`

## What The Module Provides

- Configuration parsing for backend-driven home feed sections
- Capability gating before any API execution or UI rendering
- Rank-based section ordering after validation
- Chunk-based section loading (`2` sections at a time by default)
- Cached-first rendering through the store layer
- SwiftData persistence on iOS 17+ with in-memory fallback on iOS 16
- A reusable `FeedItem` bridge model between API DTOs and card UI
- Card rendering for all supported `CardType x ContentType` combinations
- Mock-first development support with bundled mock fixtures
- High unit test coverage with mock providers and snapshot-style assertions

## Supported Taxonomy

### Content Types

- `DOCUMENT`
- `ON_DEMAND_WEBINAR`
- `UPCOMING_WEBINAR`
- `VIDEO`
- `PODCAST`
- `INQUIRY`
- `CONFERENCE`

### Card Types

- `COMPACT_HEIGHT`
- `COMPACT_WIDTH`
- `TOP_THUMBNAIL`
- `INSIGHT`

## Architecture

The module is split into distinct layers.

- Presentation: `HomeFeedView`, `HomeFeedViewModel`, SwiftUI card rendering
- Domain: use cases and repository abstraction
- Data: repository implementation, remote data source, store data source, runtime-based persistence selection

Core flow:

1. Client app supplies a `HomeFeedNetworkingProvider`
2. Module fetches configuration
3. Configuration is parsed and validated against `HomeFeedCapabilities`
4. Unsupported sections are skipped before chunk execution
5. Valid sections are sorted by rank
6. Cached sections render immediately from the store
7. Background refresh updates the store
8. UI reflects store changes automatically

## Quick Start

1. Add the `HomeFeed` framework target to the client workspace and link it to the app target.
2. Implement `HomeFeedNetworkingProvider` in the client app.
3. Create a `HomeFeedViewModel` with capabilities and callbacks.
4. Render `HomeFeedView(viewModel:)` inside your navigation, tab, or modal flow.

Example:

```swift
import HomeFeed
import SwiftUI

struct ClientHomeScreen: View {
    @StateObject private var viewModel = HomeFeedViewModel(
        networkingProvider: ClientHomeFeedProvider(),
        capabilities: .default,
        callbacks: HomeFeedCallbacks(
            onSectionSkipped: { section, reason in
                print("Skipped \(section.sectionType): \(reason)")
            },
            onHomeFeedFailed: { error in
                print("Home feed failed: \(error)")
            }
        ),
        persistenceMode: .automatic
    )

    var body: some View {
        HomeFeedView(viewModel: viewModel)
    }
}
```

## Integration Model

The client app owns API DTO parsing and maps raw responses into module models.

```text
Client API DTOs <-> FeedItem <-> HomeFeed Card UI
```

- `HomeConfig` / `SectionMeta` define what to render
- `FeedItem` defines what each card needs to display
- `FeedItemBehaviour` carries shared UI-facing metadata such as dates, image URL, status, and CTA labels

## Persistence Behavior

- `iOS 17+` + `.automatic`: SwiftData-backed store is enabled
- `iOS 16` + `.automatic`: in-memory store is used automatically
- `.inMemoryOnly`: disables persistence on all OS versions

The repository decides which store to use at runtime. No SwiftData dependency is initialized on iOS 16.

## Mocks And Local Development

Bundled mock assets:

- `HomeFeed/Mocks/MockHomeFeedConfig.json`
- `HomeFeed/Mocks/MockSectionResponse.json`
- `MockHomeFeedNetworkingProvider`
- `MockSectionDataParser`

Use these to validate configuration parsing, capability filtering, and UI rendering before wiring real APIs.

## Documentation

- Integration guide: [`INTEGRATION_GUIDE.md`](./INTEGRATION_GUIDE.md)
- DocC entry point: `HomeFeed/HomeFeed.docc/HomeFeed.md`

## Public Entry Points

- `HomeFeedView`
- `HomeFeedViewModel`
- `HomeFeedNetworkingProvider`
- `HomeFeedCapabilities`
- `HomeFeedConfigParser`
- `HomeFeedCallbacks`
- `FeedItem`
- `HomeFeedRepositoryFactory`

## Current Non-Goals

The module does not:

- implement networking
- handle auth refresh
- implement retry policies
- prescribe analytics transport

Those responsibilities stay with the client application.
