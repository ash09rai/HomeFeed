import Combine
import Foundation

#if DEBUG || HOMEFEED_QA
public final class MockHomeFeedNetworkingProvider: HomeFeedNetworkingProvider {
    public var configResult: Result<HomeConfig, Error>
    public var sectionResults: [String: Result<SectionData, Error>]
    public var configDelay: TimeInterval
    public var sectionDelay: TimeInterval

    public init(
        config: HomeConfig,
        sectionResults: [String: Result<SectionData, Error>],
        configDelay: TimeInterval = 0,
        sectionDelay: TimeInterval = 0
    ) {
        self.configResult = .success(config)
        self.sectionResults = sectionResults
        self.configDelay = max(0, configDelay)
        self.sectionDelay = max(0, sectionDelay)
    }

    public init(
        configResult: Result<HomeConfig, Error>,
        sectionResults: [String: Result<SectionData, Error>] = [:],
        configDelay: TimeInterval = 0,
        sectionDelay: TimeInterval = 0
    ) {
        self.configResult = configResult
        self.sectionResults = sectionResults
        self.configDelay = max(0, configDelay)
        self.sectionDelay = max(0, sectionDelay)
    }

    public convenience init(
        bundleConfiguration: HomeFeedMockDataSourceConfiguration = .bundled
    ) throws {
        let bundle = bundleConfiguration.bundleOverride ?? Bundle.main
        let configData = try Self.loadResource(
            named: bundleConfiguration.configFileName,
            bundle: bundle
        )
        let sectionData = try Self.loadResource(
            named: bundleConfiguration.sectionFileName,
            bundle: bundle
        )

        let config = try HomeFeedConfigParser().parse(data: configData)
        let sectionResults = try MockSectionDataParser.parse(data: sectionData)
            .mapValues { Result<SectionData, Error>.success($0) }

        self.init(
            config: config,
            sectionResults: sectionResults,
            configDelay: bundleConfiguration.configDelay,
            sectionDelay: bundleConfiguration.sectionDelay
        )
    }

    public func fetchHomeConfiguration() -> AnyPublisher<HomeConfig, Error> {
        resultPublisher(for: configResult, delay: configDelay)
    }

    public func fetchSectionData(for section: SectionMeta) -> AnyPublisher<SectionData, Error> {
        let result = sectionResults[section.sectionType]
            ?? sectionResults["default"]
            ?? .success(SectionData(items: []))
        return resultPublisher(for: result, delay: sectionDelay)
    }

    public func performBulkSkimCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error> {
        Just([:]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    public func performBulkListenCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error> {
        Just([:]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    public func performSaveCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error> {
        Just([:]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    private func resultPublisher<T>(
        for result: Result<T, Error>,
        delay: TimeInterval
    ) -> AnyPublisher<T, Error> {
        guard delay > 0 else {
            return result.publisher.eraseToAnyPublisher()
        }

        return Deferred {
            Future { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    promise(result)
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private static func loadResource(named fileName: String, bundle: Bundle) throws -> Data {
        let fileURL = URL(fileURLWithPath: fileName)
        if fileURL.path.hasPrefix("/") && FileManager.default.fileExists(atPath: fileURL.path) {
            return try Data(contentsOf: fileURL)
        }

        let resource = resourceComponents(for: fileName)
        guard let url = bundle.url(forResource: resource.name, withExtension: resource.extension) else {
            throw HomeFeedMockDataSourceError.missingResource(fileName)
        }
        return try Data(contentsOf: url)
    }

    private static func resourceComponents(for fileName: String) -> (name: String, extension: String?) {
        let resourceURL = URL(fileURLWithPath: fileName)
        let pathExtension = resourceURL.pathExtension
        let name = pathExtension.isEmpty
            ? resourceURL.lastPathComponent
            : resourceURL.deletingPathExtension().lastPathComponent

        return (name: name, extension: pathExtension.isEmpty ? nil : pathExtension)
    }
}

public enum MockSectionDataParser {
    public static func parse(data: Data) throws -> [String: SectionData] {
        try HomeFeedSectionResponseParser.parse(data: data)
    }
}
#endif
