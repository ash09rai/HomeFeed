# ``HomeFeed``

A reusable, configuration-driven home feed module for consumer iOS applications.

## Overview

`HomeFeed` is built with SwiftUI and Combine and is designed to be embedded inside an app-owned shell. The client application owns networking and maps backend DTOs into module models. The module handles capability validation, section orchestration, persistence selection, and UI rendering.

Use this module when you need:

- backend-driven home feed sections
- capability-gated rendering
- chunk-based incremental loading
- cached-first rendering with conditional persistence
- a shared card UI built on top of `FeedItem`

## Key Symbols

- ``HomeFeedView``
- ``HomeFeedViewModel``
- ``HomeFeedNetworkingProvider``
- ``HomeFeedCapabilities``
- ``HomeFeedConfigParser``
- ``HomeFeedCallbacks``
- ``FeedItem``
- ``HomeFeedRepositoryFactory``

## Runtime Behavior

The module performs the following pipeline:

1. Reads the current store snapshot and publishes cached sections.
2. Fetches configuration from the client provider.
3. Validates configuration against declared capabilities.
4. Removes skipped sections before chunk execution.
5. Sorts valid sections by `rank`.
6. Loads sections in chunks.
7. Updates the store.
8. Reflects store changes in SwiftUI automatically.

Persistence is selected at runtime:

- iOS 17+: SwiftData store when persistence mode is `.automatic`
- iOS 16: in-memory store only

## Integration

For client integration details, use the repository root documentation:

- `README.md`
- `INTEGRATION_GUIDE.md`
