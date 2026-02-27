import Combine
import Foundation

public protocol HomeFeedRemoteDataSource {
    func fetchConfiguration() -> AnyPublisher<HomeConfig, Error>
    func fetchSectionData(for section: SectionMeta) -> AnyPublisher<SectionData, Error>
}

public final class NetworkingHomeFeedRemoteDataSource: HomeFeedRemoteDataSource {
    private let provider: HomeFeedNetworkingProvider

    public init(provider: HomeFeedNetworkingProvider) {
        self.provider = provider
    }

    public func fetchConfiguration() -> AnyPublisher<HomeConfig, Error> {
        provider.fetchHomeConfiguration()
    }

    public func fetchSectionData(for section: SectionMeta) -> AnyPublisher<SectionData, Error> {
        provider.fetchSectionData(for: section)
    }
}
