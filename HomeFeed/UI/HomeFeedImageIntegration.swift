import Foundation
import SwiftUI

public enum HomeFeedImageCachePolicy: Hashable, Sendable {
    case cacheEnabled
    case cacheDisabled(allowMemoryCache: Bool = false)
}

public struct HomeFeedImageIntegration: Sendable {
    public let requestBuilder: @Sendable (URL) -> URLRequest
    public let userScopeId: @Sendable () -> String
    public let cachePolicyResolver: @Sendable (URL) -> HomeFeedImageCachePolicy

    public init(
        requestBuilder: @escaping @Sendable (URL) -> URLRequest,
        userScopeId: @escaping @Sendable () -> String,
        cachePolicyResolver: @escaping @Sendable (URL) -> HomeFeedImageCachePolicy = { _ in .cacheEnabled }
    ) {
        self.requestBuilder = requestBuilder
        self.userScopeId = userScopeId
        self.cachePolicyResolver = cachePolicyResolver
    }
}

private struct HomeFeedImageIntegrationKey: EnvironmentKey {
    static let defaultValue: HomeFeedImageIntegration? = nil
}

public extension EnvironmentValues {
    var homeFeedImageIntegration: HomeFeedImageIntegration? {
        get { self[HomeFeedImageIntegrationKey.self] }
        set { self[HomeFeedImageIntegrationKey.self] = newValue }
    }
}

public extension View {
    func homeFeedImageIntegration(_ integration: HomeFeedImageIntegration?) -> some View {
        environment(\.homeFeedImageIntegration, integration)
    }
}

struct home_feed_managed_image_content_view: View {
    let urls: [URL]
    let integration: HomeFeedImageIntegration?
    let accent: Color

    var body: some View {
        home_feed_remote_image_fallback_view(url: urls.first, accent: accent)
    }
}

struct home_feed_remote_image_fallback_view: View {
    let url: URL?
    let accent: Color

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    home_feed_remote_image_placeholder_view(accent: accent)
                }
            }
        } else {
            home_feed_remote_image_placeholder_view(accent: accent)
        }
    }
}

struct home_feed_remote_image_placeholder_view: View {
    let accent: Color

    var body: some View {
        Rectangle()
            .fill(accent.opacity(0.12))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(accent)
            )
    }
}

struct CompactHeightDocumentImageView: View {
    let item: FeedItem
    @Environment(\.homeFeedImageIntegration) private var imageIntegration
    var showRadius: Bool = true
    
    private var resolvedURLs: [URL] {
        item.imageURLs.compactMap { value in
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else {
                return nil
            }
            return URL(string: normalized)
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: showRadius ? SystemDesign.CornerRadius.imageCornerRadius : 0, style: .continuous)

        home_feed_managed_image_content_view(
            urls: resolvedURLs,
            integration: imageIntegration,
            accent: SystemDesign.accent(for: item.contentType)
        )
        .clipShape(shape)
        .overlay(
            shape.stroke(SystemDesign.color(.border), lineWidth: SystemDesign.Border.thin)
        )
    }
}
