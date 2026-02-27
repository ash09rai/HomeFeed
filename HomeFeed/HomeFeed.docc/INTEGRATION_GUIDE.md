# HomeFeed Integration Guide

This guide describes how to integrate `HomeFeed` into a client iOS application using the current module architecture.

## 1. Integration Preconditions

Before integration:

- the app target must support iOS 16+
- the app must be able to host SwiftUI views
- the client team must own the backend networking implementation
- the client team must map backend DTOs into `HomeConfig` and `SectionData`

`HomeFeed` is not a networking SDK. The integration boundary is `HomeFeedNetworkingProvider`.

## 2. Recommended Integration Path

Use the convenience initializer on `HomeFeedViewModel` unless you need custom repository wiring.

```swift
public convenience init(
    networkingProvider: HomeFeedNetworkingProvider,
    capabilities: HomeFeedCapabilities,
    chunkSize: Int = 2,
    validator: HomeFeedCapabilityValidator = HomeFeedCapabilityValidator(),
    callbacks: HomeFeedCallbacks = HomeFeedCallbacks(),
    persistenceMode: HomeFeedPersistenceMode = .automatic,
    runtime: HomeFeedRuntime = LiveHomeFeedRuntime()
)
```

This initializer builds:

- `NetworkingHomeFeedRemoteDataSource`
- runtime-selected store data source
- `HomeFeedRepositoryImpl`
- default use cases

## 3. Step-By-Step Setup

### Step 1: Add The Framework To The Client App

Add the `HomeFeed` project/target to the client workspace and link the framework to the application target.

The module currently ships as an Xcode framework target. It is not packaged as a Swift Package.

### Step 2: Implement `HomeFeedNetworkingProvider`

Your client app must provide the module with already-mapped models.

```swift
import Combine
import Foundation
import HomeFeed

final class ClientHomeFeedProvider: HomeFeedNetworkingProvider {
    private let apiClient: APIClient
    private let configParser = HomeFeedConfigParser()

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchHomeConfiguration() -> AnyPublisher<HomeConfig, Error> {
        apiClient
            .get(path: "/home-feed/config")
            .tryMap { data in
                try self.configParser.parse(data: data)
            }
            .eraseToAnyPublisher()
    }

    func fetchSectionData(for section: SectionMeta) -> AnyPublisher<SectionData, Error> {
        let endpoint = section.endpoint ?? ""

        return apiClient
            .get(path: endpoint)
            .tryMap { data in
                let dto = try JSONDecoder().decode(ClientSectionResponse.self, from: data)
                return SectionData(items: dto.items.map { item in
                    ClientFeedItemMapper.map(item, section: section)
                })
            }
            .eraseToAnyPublisher()
    }

    func performBulkSkimCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error> {
        Just([:]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func performBulkListenCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error> {
        Just([:]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func performSaveCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error> {
        Just([:]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
```

Notes:

- `fetchHomeConfiguration()` can use `HomeFeedConfigParser` directly if the backend config JSON matches the module contract.
- `fetchSectionData(for:)` must map raw section DTOs into `FeedItem` values.
- the bulk-check methods are part of the contract but are currently not orchestrated by the module; returning empty dictionaries is acceptable until those flows are adopted.

### Step 3: Declare Client Capabilities

Capabilities are mandatory. Validation happens before the module makes section API calls.

```swift
let capabilities = HomeFeedCapabilities(
    supportedContentTypes: [
        .document,
        .onDemandWebinar,
        .upcomingWebinar,
        .video,
        .podcast,
        .inquiry,
        .conference
    ],
    supportedCardTypes: [
        .compactHeight,
        .compactWidth,
        .topThumbnail,
        .insight
    ],
    supportedLayouts: [
        .horizontalList,
        .verticalList
    ],
    supportedScrollDirections: [
        .horizontal,
        .vertical
    ],
    supportedSectionParameters: HomeFeedCapabilities.default.supportedSectionParameters
)
```

If you already support the full module feature set, use `.default`.

### Step 4: Configure Callbacks

Use callbacks to observe validation failures, skipped sections, partial support, behaviour triggers, and terminal errors.

```swift
let callbacks = HomeFeedCallbacks(
    onConfigurationValidationFailed: { error in
        logger.error("Configuration validation failed: \(String(describing: error))")
    },
    onSectionSkipped: { section, reason in
        analytics.track("home_feed_section_skipped", properties: [
            "section": section.sectionType,
            "reason": reason.rawValue
        ])
    },
    onSectionPartiallySupported: { section, unsupported in
        analytics.track("home_feed_partial_support", properties: [
            "section": section.sectionType,
            "unsupported": unsupported.map(\.rawValue)
        ])
    },
    onBehaviourTriggered: { section, behaviour in
        analytics.track("home_feed_behaviour_triggered", properties: [
            "section": section.sectionType,
            "parameter": behaviour.parameter,
            "action": behaviour.action.rawValue
        ])
    },
    onHomeFeedFailed: { error in
        logger.error("Home feed failed: \(String(describing: error))")
    }
)
```

### Step 5: Create And Host The View Model

```swift
import HomeFeed
import SwiftUI

struct ClientHomeContainer: View {
    @StateObject private var viewModel: HomeFeedViewModel

    init(apiClient: APIClient) {
        let provider = ClientHomeFeedProvider(apiClient: apiClient)
        _viewModel = StateObject(wrappedValue: HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: .default,
            chunkSize: 2,
            callbacks: HomeFeedCallbacks(),
            persistenceMode: .automatic
        ))
    }

    var body: some View {
        HomeFeedView(viewModel: viewModel)
    }
}
```

Supported hosting contexts:

- `NavigationStack`
- `TabView`
- sheet / full-screen modal flows

### Step 6: Trigger Behaviour Rules When Needed

Section-level behaviour rules are defined in configuration and executed through the view model.

```swift
viewModel.triggerBehaviour(for: sectionID, action: .viewed)
```

Current built-in behavior support:

- `parameter == "rank"`: updates section rank and re-sorts the rendered section list

Use `onBehaviourTriggered` to notify the client app of side effects such as analytics or persistence of user interactions.

## 4. `FeedItem` Mapping Contract

The module renders cards from `FeedItem`, not from client DTOs.

Current bridge shape:

```text
Client API DTOs <-> FeedItem <-> ContentCardsUI
```

At minimum, every mapped item should provide:

- `id`
- `contentType`
- `title`

Use `FeedItemBehaviour` for UI-facing metadata that cards reuse across content types.

### Shared `FeedItemBehaviour` Fields

- `summary`: descriptive copy shown under the title
- `media.imageURL`: card image URL
- `media.showImage`: explicit image toggle
- `media.multipleImageSupport`: enables gallery-style UI hints
- `schedule.publishedDate`: static published date
- `schedule.eventDate`: event date for webinars and inquiries
- `schedule.eventStartDate`: event start date for conferences
- `schedule.eventEndDate`: event end date for conferences
- `schedule.eventTime`: event time or time range
- `schedule.eventLocation`: event location
- `schedule.displayTimeZone`: timezone label for inquiry/webinar rendering
- `statusText`: rendered as the primary chip when present
- `isRegistered`: registration state for upcoming webinars
- `primaryAction`: primary CTA label and optional URL
- `secondaryAction`: secondary CTA label and optional URL

### Recommended Mapping By Content Type

#### Document

Map:

- `title`
- `schedule.publishedDate`
- `id` from `resId`
- `summary` from `description`
- `media.imageURL`
- `media.showImage`
- `media.multipleImageSupport`

#### On-Demand Webinar

Map:

- `title`
- `schedule.publishedDate`
- `id` from `contentId` (fallback to linked document id if needed)
- `media.imageURL`
- `summary`
- `statusText` from `webinarStatus`

#### Upcoming Webinar

Map:

- `title`
- `schedule.eventDate`
- `schedule.eventTime`
- `summary`
- `isRegistered`
- `id` from linked document id or webinar identifier
- `primaryAction` (`Register` or `Registered`)
- optional registration URL on `primaryAction.url`

#### Video

Map:

- `title`
- `schedule.publishedDate`
- `id` from `contentId`
- `media.imageURL`
- `summary`

#### Podcast

Map:

- `title`
- `schedule.publishedDate`
- `id` from `contentId`
- `media.imageURL`
- `summary`
- `primaryAction` as `Listen` with playback URL when available

#### Inquiry

Map:

- `title`
- `schedule.eventDate` from epoch milliseconds
- `schedule.eventTime` from epoch milliseconds
- `schedule.displayTimeZone`
- `summary`
- `statusText` from `inquiryStatus`
- `id` from `inquiryRefNum`
- `primaryAction` as `Scheduled`
- `secondaryAction` as `Edit Inquiry`

#### Conference

Map:

- `title`
- `schedule.eventStartDate`
- `schedule.eventEndDate`
- `schedule.eventLocation`
- `schedule.eventTime`
- `summary` from subtitle/description copy
- `statusText` as `Registered`
- `id` from `eventURL`
- `primaryAction` from primary CTA
- `secondaryAction` from secondary CTA

## 5. Configuration Parsing And Validation

The configuration parser supports:

- `cardType` and `cardtype`
- missing optional fields
- `null` values
- unknown property detection
- behaviour object parsing

Validation rules:

- unsupported section parameters -> configuration failure
- hidden sections -> skipped before execution
- empty endpoints -> skipped before execution
- unsupported layouts -> skipped before execution
- unsupported card types -> skipped before execution
- unsupported scroll directions -> skipped before execution
- fully unsupported content support -> skipped before execution
- partially supported declared content types -> section remains valid and emits callback

Valid sections are sorted by ascending `rank` after validation.

## 6. Persistence Behavior

The repository chooses the store implementation at runtime.

### `.automatic`

- iOS 17+: `SwiftDataHomeFeedStoreDataSource`
- iOS 16: `InMemoryHomeFeedStoreDataSource`

### `.inMemoryOnly`

- forces in-memory mode on all OS versions

Behavioral impact:

- cached sections are emitted immediately from the store
- network refresh runs in the background
- store updates propagate to the UI automatically through Combine
- there is no manual UI refresh step after store writes

## 7. Mock-First Integration Strategy

Use mocks before wiring production networking.

Recommended order:

1. parse `MockHomeFeedConfig.json`
2. parse `MockSectionResponse.json`
3. verify the full feed renders in the client shell
4. confirm capability gating and skipped section handling
5. replace the mock provider with the real client provider

Useful test/dev utilities:

- `MockHomeFeedNetworkingProvider`
- `MockSectionDataParser`

## 8. Production Integration Checklist

Complete this before rollout:

- framework is linked into the app target
- client provider returns valid `HomeConfig`
- client provider returns mapped `SectionData`
- capability declaration reflects actual supported UI
- callbacks are wired to client analytics/logging
- `.automatic` persistence mode is used unless in-memory is intentionally required
- iOS 16 path is validated on a real iOS 16 simulator/device
- iOS 17+ persistence path is validated on a real iOS 17+ simulator/device
- section skipping does not result in unexpected empty screens
- empty-feed and all-failed states are handled in the client shell if needed

## 9. Common Integration Mistakes

Avoid these:

- passing raw backend DTOs directly into the UI layer
- calling section APIs for unsupported sections outside the module
- omitting capability declarations and assuming all content is supported
- using empty section endpoints in config
- relying on SwiftData-only behavior when testing on iOS 16
- expecting the module to perform auth refresh or retry failed requests

## 10. When To Use Custom Wiring

Use the convenience `HomeFeedViewModel` initializer for standard client integration.

Use direct repository + use case wiring only if you need:

- a custom store implementation
- a custom remote data source layer
- alternate repository composition for testing or feature flags
- non-standard runtime selection logic
