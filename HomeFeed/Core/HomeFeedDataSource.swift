import Foundation

public enum HomeFeedDataSource {
    case api(HomeFeedNetworkingProvider)
    #if DEBUG || HOMEFEED_QA
    case mock(HomeFeedMockDataSourceConfiguration = .bundled)
    #endif
}

#if DEBUG || HOMEFEED_QA
public struct HomeFeedMockDataSourceConfiguration: Sendable {
    public let configFileName: String
    public let sectionFileName: String
    public let configDelay: TimeInterval
    public let sectionDelay: TimeInterval
    let bundleOverride: Bundle?

    public init(
        configFileName: String = "MockHomeFeedConfig.json",
        sectionFileName: String = "MockSectionResponse.json",
        configDelay: TimeInterval = 0,
        sectionDelay: TimeInterval = 0,
        bundle: Bundle? = nil
    ) {
        self.configFileName = configFileName
        self.sectionFileName = sectionFileName
        self.configDelay = max(0, configDelay)
        self.sectionDelay = max(0, sectionDelay)
        self.bundleOverride = bundle
    }

    public static let bundled = HomeFeedMockDataSourceConfiguration()
}

public enum HomeFeedMockDataSourceError: LocalizedError {
    case missingResource(String)

    public var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            return "Missing mock resource: \(name)"
        }
    }
}
#endif
