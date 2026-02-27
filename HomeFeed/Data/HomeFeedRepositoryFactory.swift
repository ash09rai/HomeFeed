import Foundation

public enum HomeFeedPersistenceMode {
    case automatic
    case inMemoryOnly
}

public enum HomeFeedRepositoryFactory {
    public static func makeRepository(
        networkingProvider: HomeFeedNetworkingProvider,
        capabilities: HomeFeedCapabilities,
        chunkSize: Int = 2,
        persistenceMode: HomeFeedPersistenceMode = .automatic,
        runtime: HomeFeedRuntime = LiveHomeFeedRuntime()
    ) -> HomeFeedRepository {
        let remoteDataSource = NetworkingHomeFeedRemoteDataSource(provider: networkingProvider)
        let store = makeStoreDataSource(persistenceMode: persistenceMode, runtime: runtime)

        return HomeFeedRepositoryImpl(
            remoteDataSource: remoteDataSource,
            storeDataSource: store,
            capabilities: capabilities,
            chunkSize: chunkSize
        )
    }

    public static func makeStoreDataSource(
        persistenceMode: HomeFeedPersistenceMode,
        runtime: HomeFeedRuntime
    ) -> HomeFeedStoreDataSource {
        switch persistenceMode {
        case .inMemoryOnly:
            return InMemoryHomeFeedStoreDataSource()
        case .automatic:
#if canImport(SwiftData)
            if runtime.isSwiftDataSupported {
                if #available(iOS 17.0, *) {
                    if let store = try? SwiftDataHomeFeedStoreDataSource() {
                        return store
                    }
                }
            }
#endif
            return InMemoryHomeFeedStoreDataSource()
        }
    }
}
