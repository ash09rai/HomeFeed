import Combine
import Foundation

public protocol HomeFeedNetworkingProvider {
    func fetchHomeConfiguration() -> AnyPublisher<HomeConfig, Error>
    func fetchSectionData(for section: SectionMeta) -> AnyPublisher<SectionData, Error>
    func performBulkSkimCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error>
    func performBulkListenCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error>
    func performSaveCheck(ids: [String]) -> AnyPublisher<[String: Bool], Error>
}
