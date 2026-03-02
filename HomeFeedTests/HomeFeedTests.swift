#if canImport(UIKit)
import Combine
import SwiftUI
import UIKit
#if canImport(SwiftData)
import SwiftData
#endif
import XCTest
@testable import HomeFeed

final class HomeFeedTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func testConfigParserHandlesCardTypeAndCardtypeAndNulls() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "a",
            "endpoint": null,
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "containers": [
              {
                "layout": "HORIZONTAL_LIST",
                "cardtype": "COMPACT_HEIGHT_CARD",
                "showImage": false,
                "cardCount": 3,
                "imagePaginationEnabled": null,
                "scrollDirection": "HORIZONTAL"
              }
            ]
          },
          {
            "rank": 2,
            "section_type": "b",
            "endpoint": "/b",
            "supportedContents": ["AUDIO"],
            "showSection": true,
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 1,
                "imagePaginationEnabled": true,
                "scrollDirection": "VERTICAL"
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))

        XCTAssertEqual(config.sections.count, 2)
        XCTAssertNil(config.sections[0].endpoint)
        XCTAssertEqual(config.sections[0].containers[0].cardType, .compactHeightCard)
        XCTAssertFalse(config.sections[0].containers[0].imagePaginationEnabled)
        XCTAssertEqual(config.sections[1].containers[0].cardType, .standardCard)
    }

    func testConfigParserThrowsUnknownTopLevelProperty() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "a",
            "endpoint": "/a",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "unknown_property": "boom",
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 1,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          }
        ]
        """

        XCTAssertThrowsError(try HomeFeedConfigParser().parse(data: Data(json.utf8))) { error in
            guard case let ConfigurationValidationError.unknownParameters(parameters) = error else {
                XCTFail("Expected unknown parameters error")
                return
            }
            XCTAssertEqual(parameters, ["unknown_property"])
        }
    }

    func testConfigParserThrowsUnknownNestedProperty() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "a",
            "endpoint": "/a",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 1,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL",
                "unknownInner": true
              }
            ]
          }
        ]
        """

        XCTAssertThrowsError(try HomeFeedConfigParser().parse(data: Data(json.utf8))) { error in
            guard case let ConfigurationValidationError.unknownParameters(parameters) = error else {
                XCTFail("Expected unknown parameters error")
                return
            }
            XCTAssertEqual(parameters, ["containers.unknownInner"])
        }
    }

    func testCapabilityValidatorSortsByRankAfterValidation() throws {
        let config = try loadFixtureConfig(named: "MockHomeFeedConfig.json")
        let validator = HomeFeedCapabilityValidator()

        let result = try validator.validate(config: config, capabilities: .default)

        XCTAssertEqual(result.validSections.map(\.sectionType), ["last_activity", "recommended", "unsupported_layout"])
        XCTAssertEqual(result.validSections.map(\.rank), [1, 2, 3])
        XCTAssertEqual(Set(result.skippedSections.map { $0.0.sectionType }), ["hidden"])
    }

    func testCapabilityValidatorFailsForUnsupportedSectionParameters() throws {
        let config = try loadFixtureConfig(named: "MockHomeFeedConfig.json")
        let capabilities = HomeFeedCapabilities(
            supportedContentTypes: HomeFeedCapabilities.default.supportedContentTypes,
            supportedCardTypes: HomeFeedCapabilities.default.supportedCardTypes,
            supportedLayouts: HomeFeedCapabilities.default.supportedLayouts,
            supportedScrollDirections: HomeFeedCapabilities.default.supportedScrollDirections,
            supportedSectionParameters: ["rank", "section_type", "endpoint", "supportedContents", "showSection", "containers"]
        )

        XCTAssertThrowsError(try HomeFeedCapabilityValidator().validate(config: config, capabilities: capabilities)) { error in
            guard case ConfigurationValidationError.unsupportedParameters = error else {
                XCTFail("Expected unsupported parameters")
                return
            }
        }
    }

    func testViewModelSkipsUnsupportedSectionsBeforeFetch() throws {
        let config = try loadFixtureConfig(named: "MockHomeFeedConfig.json")
        let sectionData = try loadFixtureSectionData(named: "MockSectionResponse.json")

        let provider = RecordingMockProvider(config: .success(config), sectionData: sectionData)
        let viewModel = HomeFeedViewModel(networkingProvider: provider, capabilities: .default, chunkSize: 2)

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)

        viewModel.load()
        wait(for: [done], timeout: 2.0)

        XCTAssertEqual(provider.fetchSectionCallTypes.sorted(), ["last_activity", "recommended", "unsupported_layout"])
        XCTAssertEqual(viewModel.skippedSections.count, 1)
        XCTAssertEqual(viewModel.sections.count, 3)
    }

    func testViewModelSupportsMockDataSourceMode() throws {
        let viewModel = try HomeFeedViewModel(
            dataSource: .mock(
                HomeFeedMockDataSourceConfiguration(
                    configFileName: fixtureURL(name: "MockHomeFeedConfig.json").path,
                    sectionFileName: fixtureURL(name: "MockSectionResponse.json").path,
                    configDelay: 0.01,
                    sectionDelay: 0.01
                )
            ),
            capabilities: .default,
            persistenceMode: .inMemoryOnly
        )

        let done = expectation(description: "mock datasource load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)
        viewModel.load()
        wait(for: [done], timeout: 2.0)

        XCTAssertFalse(viewModel.sections.isEmpty)
        XCTAssertEqual(viewModel.sections.first?.meta.sectionType, "last_activity")
    }

    func testViewModelEmitsNoRenderableSectionsWhenAllSectionsSkipped() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "skip_me",
            "endpoint": "/skip",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "containers": [
              {
                "layout": "MASONRY",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 2,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))
        let provider = RecordingMockProvider(config: .success(config), sectionData: [:])

        var homeFeedError: HomeFeedError?
        let callbacks = HomeFeedCallbacks(onHomeFeedFailed: { error in
            homeFeedError = error
        })

        let viewModel = HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: .default,
            callbacks: callbacks
        )

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)

        viewModel.load()
        wait(for: [done], timeout: 2.0)

        XCTAssertEqual(homeFeedError, .noRenderableSections)
        XCTAssertTrue(provider.fetchSectionCallTypes.isEmpty)
    }

    func testConfigParserStoresGridColumns() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "grid_section",
            "endpoint": "/grid",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "containers": [
              {
                "layout": "GRID",
                "cardType": "COMPACT_WIDTH_CARD",
                "columns": 2,
                "showImage": true,
                "cardCount": 4,
                "imagePaginationEnabled": false
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))
        let container = try XCTUnwrap(config.sections.first?.containers.first)

        XCTAssertEqual(container.layout, .grid)
        XCTAssertEqual(container.columns, 2)
        XCTAssertEqual(container.scrollDirection, .vertical)
    }

    func testViewModelEmitsAllSectionsFailedWhenAllSectionsFail() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "a",
            "endpoint": "/a",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 2,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          },
          {
            "rank": 2,
            "section_type": "b",
            "endpoint": "/b",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 2,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))
        let provider = RecordingMockProvider(
            config: .success(config),
            sectionData: [
                "a": .failure(TestFailure.sectionFailed),
                "b": .failure(TestFailure.sectionFailed)
            ]
        )

        var homeFeedError: HomeFeedError?
        let callbacks = HomeFeedCallbacks(onHomeFeedFailed: { error in
            homeFeedError = error
        })

        let viewModel = HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: .default,
            callbacks: callbacks
        )

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)

        viewModel.load()
        wait(for: [done], timeout: 2.0)

        XCTAssertEqual(homeFeedError, .allSectionsFailed)
        XCTAssertTrue(viewModel.sections.allSatisfy {
            if case .failed = $0.state {
                return true
            }
            return false
        })
    }

    func testViewModelFiltersUnsupportedItemsForPartialContentSupport() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "a",
            "endpoint": "/a",
            "supportedContents": ["VIDEO", "AUDIO"],
            "showSection": true,
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 2,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))
        let sectionData = SectionData(items: [
            FeedItem(id: "1", contentType: .video, title: "Supported"),
            FeedItem(id: "2", contentType: .audio, title: "Unsupported")
        ])
        let provider = RecordingMockProvider(config: .success(config), sectionData: ["a": .success(sectionData)])

        var partialEvents = 0
        let callbacks = HomeFeedCallbacks(onSectionPartiallySupported: { _, _ in
            partialEvents += 1
        })

        let capabilities = HomeFeedCapabilities(
            supportedContentTypes: [.video],
            supportedCardTypes: HomeFeedCapabilities.default.supportedCardTypes,
            supportedLayouts: HomeFeedCapabilities.default.supportedLayouts,
            supportedScrollDirections: HomeFeedCapabilities.default.supportedScrollDirections,
            supportedSectionParameters: HomeFeedCapabilities.default.supportedSectionParameters
        )

        let viewModel = HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: capabilities,
            callbacks: callbacks
        )

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)

        viewModel.load()
        wait(for: [done], timeout: 2.0)

        guard case let .loaded(data)? = viewModel.sections.first?.state else {
            XCTFail("Section should be loaded")
            return
        }

        XCTAssertEqual(data.items.count, 1)
        XCTAssertEqual(data.items.first?.contentType, .video)
        XCTAssertGreaterThanOrEqual(partialEvents, 1)
    }

    func testViewModelHonorsChunkSizeConcurrency() throws {
        let config = HomeConfig(sections: (1...5).map {
            SectionMeta(
                id: "s\($0)",
                originalOrder: $0,
                rank: $0,
                sectionType: "s\($0)",
                endpoint: "/s\($0)",
                supportedContents: [.video],
                showSection: true,
                groupCount: nil,
                cardCount: nil,
                containers: [
                    ContainerMeta(
                        layout: .verticalList,
                        cardType: .standardCard,
                        scrollDirection: .vertical,
                        showImage: true,
                        cardCount: 1,
                        imagePaginationEnabled: false
                    )
                ],
                behaviour: nil,
                declaredParameters: ["rank", "section_type", "endpoint", "supportedContents", "showSection", "containers"],
                unknownParameters: []
            )
        })

        let data: [String: Result<SectionData, Error>] = Dictionary(uniqueKeysWithValues: (1...5).map {
            ("s\($0)", .success(SectionData(items: [FeedItem(id: "\($0)", contentType: .video, title: "Item \($0)")])))
        })

        let provider = RecordingMockProvider(config: .success(config), sectionData: data, delay: 0.06)
        let viewModel = HomeFeedViewModel(networkingProvider: provider, capabilities: .default, chunkSize: 2)

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)

        viewModel.load()
        wait(for: [done], timeout: 3.0)

        XCTAssertLessThanOrEqual(provider.maxConcurrentSectionRequests, 2)
        XCTAssertEqual(provider.fetchSectionCallTypes.count, 5)
    }

    func testBehaviourUpdateChangesRankAndResorts() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "a",
            "endpoint": "/a",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "behaviour": {
              "parameter": "rank",
              "updatedValue": "99",
              "action": "VIEWED"
            },
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 1,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          },
          {
            "rank": 2,
            "section_type": "b",
            "endpoint": "/b",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 1,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))
        let provider = RecordingMockProvider(config: .success(config), sectionData: [
            "a": .success(SectionData(items: [FeedItem(id: "1", contentType: .video, title: "A")])),
            "b": .success(SectionData(items: [FeedItem(id: "2", contentType: .video, title: "B")]))
        ])

        var behaviourEventCount = 0
        let callbacks = HomeFeedCallbacks(onBehaviourTriggered: { _, _ in
            behaviourEventCount += 1
        })

        let viewModel = HomeFeedViewModel(networkingProvider: provider, capabilities: .default, callbacks: callbacks)

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)

        viewModel.load()
        wait(for: [done], timeout: 2.0)

        XCTAssertEqual(viewModel.sections.map(\.meta.sectionType), ["a", "b"])

        guard let sectionA = viewModel.sections.first else {
            XCTFail("Expected section A")
            return
        }

        viewModel.triggerBehaviour(for: sectionA.id, action: .viewed)

        XCTAssertEqual(viewModel.sections.map(\.meta.sectionType), ["b", "a"])
        XCTAssertEqual(behaviourEventCount, 1)
    }

    func testStateTransitionsIdleLoadingLoaded() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "a",
            "endpoint": "/a",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 1,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))
        let provider = RecordingMockProvider(
            config: .success(config),
            sectionData: ["a": .success(SectionData(items: [FeedItem(id: "1", contentType: .video, title: "A")] ))],
            delay: 0.05
        )

        let viewModel = HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: .default,
            persistenceMode: .inMemoryOnly
        )

        let sawLoading = expectation(description: "saw loading")
        let sawLoaded = expectation(description: "saw loaded")

        viewModel.$sections
            .sink { sections in
                guard let state = sections.first?.state else {
                    return
                }

                if case .loading = state {
                    sawLoading.fulfill()
                }

                if case .loaded = state {
                    sawLoaded.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.load()
        wait(for: [sawLoading, sawLoaded], timeout: 2.0)
    }

    func testConfigurationValidationFailureCallbacksAreEmitted() throws {
        let config = try loadFixtureConfig(named: "MockHomeFeedConfig.json")
        let provider = RecordingMockProvider(config: .success(config), sectionData: [:])

        var validationError: ConfigurationValidationError?
        var homeError: HomeFeedError?

        let callbacks = HomeFeedCallbacks(
            onConfigurationValidationFailed: { error in
                validationError = error
            },
            onHomeFeedFailed: { error in
                homeError = error
            }
        )

        let restrictiveCapabilities = HomeFeedCapabilities(
            supportedContentTypes: HomeFeedCapabilities.default.supportedContentTypes,
            supportedCardTypes: HomeFeedCapabilities.default.supportedCardTypes,
            supportedLayouts: HomeFeedCapabilities.default.supportedLayouts,
            supportedScrollDirections: HomeFeedCapabilities.default.supportedScrollDirections,
            supportedSectionParameters: ["rank", "section_type", "endpoint", "supportedContents", "showSection", "containers"]
        )

        let viewModel = HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: restrictiveCapabilities,
            callbacks: callbacks
        )

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)

        viewModel.load()
        wait(for: [done], timeout: 2.0)

        XCTAssertNotNil(validationError)
        guard case .configurationValidationFailed = homeError else {
            XCTFail("Expected configuration validation failure")
            return
        }
        XCTAssertTrue(provider.fetchSectionCallTypes.isEmpty)
    }

    func testSnapshotBuilderCoversSkeletonLayoutAndSkippedSections() throws {
        let section = FeedSectionState(
            meta: SectionMeta(
                id: "s1",
                originalOrder: 0,
                rank: 1,
                sectionType: "last_activity",
                endpoint: "/a",
                supportedContents: [.video],
                showSection: true,
                groupCount: nil,
                cardCount: nil,
                containers: [],
                behaviour: nil,
                declaredParameters: [],
                unknownParameters: []
            ),
            state: .loading
        )

        let skipped = FeedSectionState(
            meta: SectionMeta(
                id: "s2",
                originalOrder: 1,
                rank: 2,
                sectionType: "hidden",
                endpoint: "/b",
                supportedContents: [.video],
                showSection: false,
                groupCount: nil,
                cardCount: nil,
                containers: [],
                behaviour: nil,
                declaredParameters: [],
                unknownParameters: []
            ),
            state: .skipped(.hiddenByConfiguration)
        )

        let snapshot = HomeFeedSnapshotBuilder.snapshot(
            sections: [section],
            skippedSections: [skipped],
            isLoading: true
        )

        XCTAssertEqual(
            snapshot,
            """
            isLoading=true
            section:last_activity:rank=1:state=loading
            skipped:hidden:skipped(hiddenByConfiguration)
            """
        )
    }

    func testSnapshotBuilderCoversLoadedCardsAndMixedContentTypes() throws {
        let loaded = FeedSectionState(
            meta: SectionMeta(
                id: "s1",
                originalOrder: 0,
                rank: 1,
                sectionType: "recommended",
                endpoint: "/a",
                supportedContents: [.video],
                showSection: true,
                groupCount: nil,
                cardCount: nil,
                containers: [],
                behaviour: nil,
                declaredParameters: [],
                unknownParameters: []
            ),
            state: .loaded(SectionData(items: [
                FeedItem(id: "1", contentType: .video, title: "Video"),
                FeedItem(id: "2", contentType: .podcast, title: "Audio")
            ]))
        )

        let snapshot = HomeFeedSnapshotBuilder.snapshot(
            sections: [loaded],
            skippedSections: [],
            isLoading: false
        )

        XCTAssertEqual(
            snapshot,
            """
            isLoading=false
            section:recommended:rank=1:state=loaded
            cards:1:VIDEO,2:PODCAST
            """
        )
    }

    func testConfigParserParsesStringPrimitivesAndDefaultDirection() throws {
        let json = """
        [
          {
            "rank": "10",
            "section_type": "string_values",
            "endpoint": "/string-values",
            "supportedContents": ["VIDEO"],
            "showSection": "false",
            "groupCount": "2",
            "cardCount": "3",
            "containers": [
              {
                "layout": "CUSTOM_LAYOUT",
                "cardType": "STANDARD_CARD",
                "showImage": "true",
                "cardCount": "4",
                "imagePaginationEnabled": "true"
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))
        guard let section = config.sections.first else {
            XCTFail("Expected parsed section")
            return
        }

        XCTAssertEqual(section.rank, 10)
        XCTAssertEqual(section.groupCount, 2)
        XCTAssertEqual(section.cardCount, 3)
        XCTAssertFalse(section.showSection)
        XCTAssertEqual(section.containers.first?.showImage, true)
        XCTAssertEqual(section.containers.first?.imagePaginationEnabled, true)
        XCTAssertEqual(section.containers.first?.scrollDirection, .vertical)
    }

    func testFeedTypeCodableRoundTrips() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let contentData = try encoder.encode(ContentType("video"))
        let decodedContent = try decoder.decode(ContentType.self, from: contentData)
        XCTAssertEqual(decodedContent, .video)

        let cardData = try encoder.encode(CardType(rawValue: "compact_height_card"))
        let decodedCard = try decoder.decode(CardType.self, from: cardData)
        XCTAssertEqual(decodedCard, .compactHeightCard)

        let layoutData = try encoder.encode(LayoutType(rawValue: "horizontal_list"))
        let decodedLayout = try decoder.decode(LayoutType.self, from: layoutData)
        XCTAssertEqual(decodedLayout, .horizontalList)

        let directionData = try encoder.encode(ScrollDirection(rawValue: "horizontal"))
        let decodedDirection = try decoder.decode(ScrollDirection.self, from: directionData)
        XCTAssertEqual(decodedDirection, .horizontal)
    }

    func testMockNetworkingProviderAndBulkCheckPublishers() throws {
        let config = HomeConfig(sections: [
            SectionMeta(
                id: "section-1",
                originalOrder: 0,
                rank: 1,
                sectionType: "section_a",
                endpoint: "/a",
                supportedContents: [.video],
                showSection: true,
                groupCount: nil,
                cardCount: nil,
                containers: [
                    ContainerMeta(
                        layout: .verticalList,
                        cardType: .standardCard,
                        scrollDirection: .vertical,
                        showImage: true,
                        cardCount: nil,
                        imagePaginationEnabled: false
                    )
                ],
                behaviour: nil,
                declaredParameters: [],
                unknownParameters: []
            )
        ])

        let sectionData = SectionData(items: [FeedItem(id: "1", contentType: .video, title: "Item")])
        let provider = MockHomeFeedNetworkingProvider(
            config: config,
            sectionResults: ["section_a": .success(sectionData)]
        )

        let fetchedConfig = try awaitValue(provider.fetchHomeConfiguration())
        let fetchedSection = try awaitValue(provider.fetchSectionData(for: config.sections[0]))
        let skim = try awaitValue(provider.performBulkSkimCheck(ids: ["1"]))
        let listen = try awaitValue(provider.performBulkListenCheck(ids: ["1"]))
        let save = try awaitValue(provider.performSaveCheck(ids: ["1"]))

        XCTAssertEqual(fetchedConfig.sections.count, 1)
        XCTAssertEqual(fetchedSection.items.count, 1)
        XCTAssertTrue(skim.isEmpty)
        XCTAssertTrue(listen.isEmpty)
        XCTAssertTrue(save.isEmpty)

        let failingProvider = MockHomeFeedNetworkingProvider(configResult: .failure(TestFailure.sectionFailed))
        XCTAssertThrowsError(try awaitValue(failingProvider.fetchHomeConfiguration()))
    }

    func testMockNetworkingProviderLoadsFixtureFilesFromExplicitPaths() throws {
        let provider = try MockHomeFeedNetworkingProvider(
            bundleConfiguration: HomeFeedMockDataSourceConfiguration(
                configFileName: fixtureURL(name: "MockHomeFeedConfig.json").path,
                sectionFileName: fixtureURL(name: "MockSectionResponse.json").path,
                configDelay: 0.01,
                sectionDelay: 0.01
            )
        )

        let config = try awaitValue(provider.fetchHomeConfiguration())
        XCTAssertFalse(config.sections.isEmpty)

        let firstSection = try XCTUnwrap(config.sections.first)
        let sectionData = try awaitValue(provider.fetchSectionData(for: firstSection))
        XCTAssertFalse(sectionData.items.isEmpty)
    }

    func testMockSectionDataParserSupportsDataWrapperFormat() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/ashishrai/Desktop/Projects/Personal Frameworks/HomeFeed/HomeFeed/Mocks/MockSectionResponse.json"))
        let parsed = try MockSectionDataParser.parse(data: data)

        let defaultItems = parsed["default"]?.items ?? []
        XCTAssertFalse(defaultItems.isEmpty)
        XCTAssertTrue(defaultItems.contains(where: { $0.contentType == .video }))
        XCTAssertTrue(defaultItems.contains(where: { $0.contentType == .onDemandWebinar || $0.contentType == .upcomingWebinar }))
    }

    func testMockSectionDataParserSupportsNestedGroupedWrappers() throws {
        let json = """
        {
          "data": {
            "groups": [
              {
                "items": [
                  {
                    "title": "Nested Video Payload",
                    "contentId": "vid-1",
                    "contentType": "VIDEO",
                    "pubDate": "01 January 2026"
                  }
                ]
              }
            ]
          }
        }
        """

        let parsed = try MockSectionDataParser.parse(data: Data(json.utf8))
        let item = try XCTUnwrap(parsed["default"]?.items.first)

        XCTAssertEqual(item.id, "vid-1")
        XCTAssertEqual(item.contentType, .video)
        XCTAssertEqual(item.publishedDate, "01 January 2026")
    }

    func testMockSectionDataParserMapsFeedItemBehaviourFromUpdatedPayload() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/ashishrai/Desktop/Projects/Personal Frameworks/HomeFeed/HomeFeed/Mocks/MockSectionResponse.json"))
        let parsed = try MockSectionDataParser.parse(data: data)
        let defaultItems = parsed["default"]?.items ?? []

        let document = try XCTUnwrap(defaultItems.first(where: { $0.contentType == .document && $0.id == "7234330" }))
        XCTAssertEqual(document.publishedDate, "02 December 2025")
        XCTAssertEqual(document.imageURL, "https://www.gartner.com/resources/836200/836261/Figure_1_CIO_Leadership_of_People_Culture_and_Change_Overview.png")
        XCTAssertTrue(document.showImage)

        let upcoming = try XCTUnwrap(defaultItems.first(where: { $0.contentType == .upcomingWebinar && $0.title.contains("Accelerate Product Delivery") }))
        XCTAssertEqual(upcoming.id, "7154530")
        XCTAssertEqual(upcoming.eventDate, "24 February 2026")
        XCTAssertEqual(upcoming.eventTime, "11:00 AM - 11:45 AM EST")
        XCTAssertEqual(upcoming.primaryAction?.title, "Register")

        let inquiry = try XCTUnwrap(defaultItems.first(where: { $0.contentType == .inquiry && $0.id == "18565652" }))
        XCTAssertEqual(inquiry.statusText, "In Progress")
        XCTAssertEqual(inquiry.primaryAction?.title, "Scheduled")
        XCTAssertEqual(inquiry.secondaryAction?.title, "Edit Inquiry")
        XCTAssertNotNil(inquiry.eventDate)
        XCTAssertEqual(inquiry.displayTimeZone, "EST")
    }

    func testMockSectionDataParserMapsConferencePayloadIntoFeedItem() throws {
        let json = """
        [
          {
            "type": "Conference",
            "bannerTitle": "Upcoming",
            "subTitle": "Customize your experience based on your mission-critical priorities with Conference Navigator.",
            "primaryCTA": {
              "title": "Build Agenda",
              "url": "https://www.gartner.com"
            },
            "secondaryCTA": {
              "title": "See Highlights",
              "url": "https://www.gartner.com"
            },
            "title": "ReimagineHR Conference",
            "city": "Sydney, Australia",
            "dateStart": "2024-09-17",
            "dateEnd": "",
            "eventDay": "Monday",
            "eventTime": "11:00 AM - 12:00 PM EDT",
            "eventURL": "/en/conferences/emea/human-resource-uk"
          }
        ]
        """

        let parsed = try MockSectionDataParser.parse(data: Data(json.utf8))
        let conference = try XCTUnwrap(parsed["default"]?.items.first)

        XCTAssertEqual(conference.contentType, .conference)
        XCTAssertEqual(conference.id, "/en/conferences/emea/human-resource-uk")
        XCTAssertEqual(conference.eventStartDate, "17 September 2024")
        XCTAssertEqual(conference.eventLocation, "Sydney, Australia")
        XCTAssertEqual(conference.statusText, "Upcoming")
        XCTAssertEqual(conference.primaryAction?.title, "Build Agenda")
        XCTAssertEqual(conference.secondaryAction?.title, "See Highlights")
    }

    func testUpdatedMockConfigParsesWithKnownParameters() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/ashishrai/Desktop/Projects/Personal Frameworks/HomeFeed/HomeFeed/Mocks/MockHomeFeedConfig.json"))
        let config = try HomeFeedConfigParser().parse(data: data)
        let section = try XCTUnwrap(config.sections.first(where: { $0.sectionType == "last_activity" }))

        XCTAssertFalse(config.sections.isEmpty)
        XCTAssertEqual(section.displayTitle, "Continue with")
        XCTAssertEqual(section.header?.titleColorHex, "#5A5B66")
        XCTAssertEqual(section.theme?.primaryColorHex, "#E0F1FF")
        XCTAssertEqual(section.sectionHeaderCta?.text, "View More")
        XCTAssertNil(section.preferredFooterCta)
    }

    func testCardTypeContentTypeViewsRenderAllCombinations() {
        let items: [FeedItem] = [
            FeedItem(id: "d", contentType: .document, title: "Document"),
            FeedItem(id: "odw", contentType: .onDemandWebinar, title: "OnDemandWebinar"),
            FeedItem(id: "uw", contentType: .upcomingWebinar, title: "UpcomingWebinar"),
            FeedItem(id: "v", contentType: .video, title: "Video"),
            FeedItem(id: "p", contentType: .podcast, title: "Podcast"),
            FeedItem(id: "i", contentType: .inquiry, title: "Inquiry"),
            FeedItem(id: "c", contentType: .conference, title: "Conference")
        ]
        let cardTypes: [CardType] = [.compactHeight, .compactWidth, .topThumbnail, .insight]

        for cardType in cardTypes {
            for item in items {
                render(card_type_content_type_view(cardType: cardType, item: item))
            }
        }
    }

    func testViewModelLoadIfNeededOnlyLoadsOnceAndUpdatedCallbacksAreUsed() throws {
        let json = """
        [
          {
            "rank": 1,
            "section_type": "a",
            "endpoint": "/a",
            "supportedContents": ["VIDEO"],
            "showSection": true,
            "behaviour": {
              "parameter": "rank",
              "updatedValue": "50",
              "action": "VIEWED"
            },
            "containers": [
              {
                "layout": "VERTICAL_LIST",
                "cardType": "STANDARD_CARD",
                "showImage": true,
                "cardCount": 1,
                "imagePaginationEnabled": false,
                "scrollDirection": "VERTICAL"
              }
            ]
          }
        ]
        """

        let config = try HomeFeedConfigParser().parse(data: Data(json.utf8))
        let provider = RecordingMockProvider(
            config: .success(config),
            sectionData: ["a": .success(SectionData(items: [FeedItem(id: "1", contentType: .video, title: "A")]))]
        )

        var legacyCallbackCount = 0
        var updatedCallbackCount = 0
        let initialCallbacks = HomeFeedCallbacks(onBehaviourTriggered: { _, _ in
            legacyCallbackCount += 1
        })
        let viewModel = HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: .default,
            callbacks: initialCallbacks
        )

        viewModel.updateCallbacks(
            HomeFeedCallbacks(onBehaviourTriggered: { _, _ in
                updatedCallbackCount += 1
            })
        )

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)
        viewModel.loadIfNeeded()
        viewModel.loadIfNeeded()
        wait(for: [done], timeout: 2.0)

        XCTAssertEqual(provider.configFetchCount, 1)
        guard let sectionID = viewModel.sections.first?.id else {
            XCTFail("Expected section")
            return
        }

        viewModel.triggerBehaviour(for: sectionID, action: .viewed)
        XCTAssertEqual(legacyCallbackCount, 0)
        XCTAssertEqual(updatedCallbackCount, 1)
    }

    func testViewModelEmitsCardTapCallback() {
        let provider = RecordingMockProvider(
            config: .failure(TestFailure.sectionFailed),
            sectionData: [:]
        )

        let section = SectionMeta(
            id: "tap-section",
            originalOrder: 0,
            rank: 1,
            sectionType: "tap_section",
            endpoint: "/tap",
            supportedContents: [.document],
            showSection: true,
            groupCount: nil,
            cardCount: 1,
            containers: [
                ContainerMeta(
                    layout: .verticalList,
                    cardType: .compactHeight,
                    scrollDirection: .vertical,
                    showImage: true,
                    cardCount: 1,
                    imagePaginationEnabled: false
                )
            ],
            behaviour: nil,
            declaredParameters: [],
            unknownParameters: []
        )
        let item = FeedItem(id: "tap-item", contentType: .document, title: "Tap Item")

        var tappedSectionID: String?
        var tappedItemID: String?

        let viewModel = HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: .default,
            callbacks: HomeFeedCallbacks(
                onCardTapped: { section, item in
                    tappedSectionID = section.id
                    tappedItemID = item.id
                }
            ),
            persistenceMode: .inMemoryOnly
        )

        viewModel.handleCardTap(item, in: section)

        XCTAssertEqual(tappedSectionID, "tap-section")
        XCTAssertEqual(tappedItemID, "tap-item")
    }

    func testViewModelEmitsNetworkingErrorForConfigFailure() {
        let provider = RecordingMockProvider(
            config: .failure(TestFailure.sectionFailed),
            sectionData: [:]
        )

        var captured: HomeFeedError?
        let viewModel = HomeFeedViewModel(
            networkingProvider: provider,
            capabilities: .default,
            callbacks: HomeFeedCallbacks(onHomeFeedFailed: { error in
                captured = error
            })
        )

        let done = expectation(description: "load complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)
        viewModel.load()
        wait(for: [done], timeout: 2.0)

        guard case .networking = captured else {
            XCTFail("Expected networking error")
            return
        }
    }

    func testSwiftUIViewsRenderAcrossStates() throws {
        let meta = SectionMeta(
            id: "render-section",
            originalOrder: 0,
            rank: 1,
            sectionType: "render_section",
            endpoint: "/render",
            supportedContents: [.video, .audio],
            showSection: true,
            groupCount: nil,
            cardCount: nil,
            containers: [
                ContainerMeta(
                    layout: .horizontalList,
                    cardType: .compactHeightCard,
                    scrollDirection: .horizontal,
                    showImage: true,
                    cardCount: 2,
                    imagePaginationEnabled: false
                ),
                ContainerMeta(
                    layout: .verticalList,
                    cardType: .standardCard,
                    scrollDirection: .vertical,
                    showImage: true,
                    cardCount: 2,
                    imagePaginationEnabled: false
                )
            ],
            behaviour: nil,
            declaredParameters: [],
            unknownParameters: []
        )
        let data = SectionData(items: [
            FeedItem(id: "1", contentType: .video, title: "Video"),
            FeedItem(id: "2", contentType: .audio, title: "Audio")
        ])

        let config = HomeConfig(sections: [meta])
        let loadedProvider = RecordingMockProvider(
            config: .success(config),
            sectionData: ["render_section": .success(data)]
        )
        let loadedVM = HomeFeedViewModel(networkingProvider: loadedProvider, capabilities: .default)
        let loadedDone = expectation(description: "loaded view model")
        observeLoadingCompletion(viewModel: loadedVM, done: loadedDone)
        loadedVM.load()
        wait(for: [loadedDone], timeout: 2.0)
        render(HomeFeedView(viewModel: loadedVM, showsSkippedDebug: true))

        let failedProvider = RecordingMockProvider(
            config: .success(config),
            sectionData: ["render_section": .failure(TestFailure.sectionFailed)]
        )
        let failedVM = HomeFeedViewModel(networkingProvider: failedProvider, capabilities: .default)
        let failedDone = expectation(description: "failed view model")
        observeLoadingCompletion(viewModel: failedVM, done: failedDone)
        failedVM.load()
        wait(for: [failedDone], timeout: 2.0)
        render(HomeFeedView(viewModel: failedVM, showsSkippedDebug: true))

        let loadingProvider = RecordingMockProvider(
            config: .success(config),
            sectionData: ["render_section": .success(data)],
            delay: 0.2,
            configDelay: 0.1
        )
        let loadingVM = HomeFeedViewModel(networkingProvider: loadingProvider, capabilities: .default)
        loadingVM.load()
        render(HomeFeedView(viewModel: loadingVM, showsSkippedDebug: true))

        let loadingDone = expectation(description: "loading view model completed")
        observeLoadingCompletion(viewModel: loadingVM, done: loadingDone)
        wait(for: [loadingDone], timeout: 2.0)
    }

    func testHomeFeedSectionResponseParserDelegatesToMockParser() throws {
        let data = try Data(contentsOf: fixtureURL(name: "MockSectionResponse.json"))
        let parsed = try HomeFeedSectionResponseParser.parse(data: data)

        XCTAssertFalse(parsed.isEmpty)
        XCTAssertNotNil(parsed["last_activity"])
    }

    func testSystemDesignAndReusableViewsCoverageHarness() {
        let typographyTokens: [SystemDesign.Typography] = [
            .sectionTitle,
            .cardTitle,
            .cardDescription,
            .cardContentType,
            .location,
            .caption,
            .primaryButton,
            .secondaryButton,
            .dateMonth,
            .dateDay
        ]

        for token in typographyTokens {
            _ = SystemDesign.font(token)
            _ = SystemDesign.lineSpacing(token)
            _ = SystemDesign.color(token)
            _ = token.foregroundColor
        }

        let paletteTokens: [SystemDesign.Palette] = [
            .surface,
            .border,
            .mutedText,
            .imagePlaceholder,
            .statusBackground
        ]

        for token in paletteTokens {
            _ = SystemDesign.color(token)
        }

        _ = SystemDesign.color(hex: "#FF0000", fallback: .clear)
        _ = SystemDesign.color(hex: "00FF00FF", fallback: .clear)
        _ = SystemDesign.color(hex: "invalid", fallback: .blue)
        _ = SystemDesign.buttonForegroundColor
        _ = SystemDesign.buttonSize
        _ = SystemDesign.registeredButtonColor

        let allContentTypes: [ContentType] = [
            .document,
            .onDemandWebinar,
            .upcomingWebinar,
            .video,
            .podcast,
            .inquiry,
            .conference,
            .audio
        ]

        for contentType in allContentTypes {
            _ = SystemDesign.accent(for: contentType)
            touchBody(ContentLabel(contentType: contentType))
        }

        let integration = HomeFeedImageIntegration(
            requestBuilder: { URLRequest(url: $0) },
            userScopeId: { "coverage-user" },
            cachePolicyResolver: { _ in .cacheDisabled(allowMemoryCache: true) }
        )
        let imageURL = URL(string: "https://example.com/image.png")!

        _ = integration.requestBuilder(imageURL)
        XCTAssertEqual(integration.userScopeId(), "coverage-user")
        XCTAssertEqual(integration.cachePolicyResolver(imageURL), .cacheDisabled(allowMemoryCache: true))

        var environment = EnvironmentValues()
        XCTAssertNil(environment.homeFeedImageIntegration)
        environment.homeFeedImageIntegration = integration
        XCTAssertNotNil(environment.homeFeedImageIntegration)
        _ = Text("Image").homeFeedImageIntegration(integration)

        touchBody(home_feed_managed_image_content_view(urls: [imageURL], integration: integration, accent: .red))
        touchBody(home_feed_remote_image_fallback_view(url: imageURL, accent: .blue))
        touchBody(home_feed_remote_image_fallback_view(url: nil, accent: .blue))
        touchBody(home_feed_remote_image_placeholder_view(accent: .green))
        touchBody(CompactHeightDocumentImageView(item: content_card_preview_item.document, showRadius: false))

        let parsedDate = home_feed_parse_date("24 February 2026")
        XCTAssertNotNil(parsedDate)
        touchBody(CalendarView(startDate: parsedDate, endDate: nil))
        touchBody(CalendarView(startDate: nil, endDate: parsedDate).calendarView)
        _ = CalendarView_Previews.previews

        ListenHandler().listenContent()
        PlayHandler().playContent()
        SaveHandler().saveContent()
        touchBody(ListenButtonView(handler: TrackingListenHandler()))
        touchBody(PlayButtonView(handler: TrackingPlayHandler()))
        touchBody(SaveButton(handler: TrackingSaveHandler()))
        touchBody(RegisteredButtonView(buttonText: "Scheduled"))
        touchBody(FullTextButtonView(buttonText: "View Schedule"))
        touchBody(PublishedDateLabelView(dateText: "08 April 2025"))
        _ = ListenButtonView_Previews.previews
        _ = PlayButtonView_Previews.previews
        _ = SaveButton_Previews.previews
    }

    func testCardViewsCoverageHarness() {
        let horizontalCompactHeight = ContainerMeta(
            layout: .horizontalList,
            cardType: .compactHeight,
            scrollDirection: .horizontal,
            showImage: true,
            cardCount: 3,
            imagePaginationEnabled: false
        )
        let gridCompactWidth = ContainerMeta(
            layout: .grid,
            cardType: .compactWidth,
            scrollDirection: .vertical,
            showImage: true,
            cardCount: 4,
            columns: 2,
            imagePaginationEnabled: true
        )
        let verticalInsight = ContainerMeta(
            layout: .verticalList,
            cardType: .insight,
            scrollDirection: .vertical,
            showImage: false,
            cardCount: 2,
            imagePaginationEnabled: false
        )
        let topThumbnailContainer = ContainerMeta(
            layout: .verticalList,
            cardType: .topThumbnail,
            scrollDirection: .vertical,
            showImage: true,
            cardCount: 1,
            imagePaginationEnabled: false
        )

        let mediaItems: [FeedItem] = [
            content_card_preview_item.document,
            content_card_preview_item.on_demand_webinar,
            content_card_preview_item.video,
            content_card_preview_item.podcast
        ]
        let eventItems: [FeedItem] = [
            content_card_preview_item.upcoming_webinar,
            content_card_preview_item.inquiry,
            content_card_preview_item.conference
        ]

        touchBody(CompactHeightDocumentView(item: content_card_preview_item.document, container: horizontalCompactHeight))
        touchBody(CompactWidthDocumentView(item: content_card_preview_item.document, container: gridCompactWidth))
        touchBody(TopThumbnailDocumentView(item: content_card_preview_item.document, container: topThumbnailContainer))
        touchBody(InsightDocumentView(item: content_card_preview_item.document, container: verticalInsight))
        touchBody(CompactHeightOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar, container: horizontalCompactHeight))
        touchBody(CompactWidthOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar, container: gridCompactWidth))
        touchBody(TopThumbnailOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar, container: topThumbnailContainer))
        touchBody(InsightOnDemandWebinarView(item: content_card_preview_item.on_demand_webinar, container: verticalInsight))
        touchBody(CompactHeightUpcomingWebinarView(item: content_card_preview_item.upcoming_webinar, container: horizontalCompactHeight))
        touchBody(CompactWidthUpcomingWebinarView(item: content_card_preview_item.upcoming_webinar, container: gridCompactWidth))
        touchBody(TopThumbnailUpcomingWebinarView(item: content_card_preview_item.upcoming_webinar, container: topThumbnailContainer))
        touchBody(InsightUpcomingWebinarView(item: content_card_preview_item.upcoming_webinar, container: verticalInsight))
        touchBody(CompactHeightVideoView(item: content_card_preview_item.video, container: horizontalCompactHeight))
        touchBody(CompactWidthVideoView(item: content_card_preview_item.video, container: gridCompactWidth))
        touchBody(TopThumbnailVideoView(item: content_card_preview_item.video, container: topThumbnailContainer))
        touchBody(InsightVideoView(item: content_card_preview_item.video, container: verticalInsight))
        touchBody(CompactHeightPodcastView(item: content_card_preview_item.podcast, container: horizontalCompactHeight))
        touchBody(CompactWidthPodcastView(item: content_card_preview_item.podcast, container: gridCompactWidth))
        touchBody(TopThumbnailPodcastView(item: content_card_preview_item.podcast, container: topThumbnailContainer))
        touchBody(InsightPodcastView(item: content_card_preview_item.podcast, container: verticalInsight))
        touchBody(CompactHeightInquiryView(item: content_card_preview_item.inquiry, container: horizontalCompactHeight))
        touchBody(CompactWidthInquiryView(item: content_card_preview_item.inquiry, container: gridCompactWidth))
        touchBody(TopThumbnailInquiryView(item: content_card_preview_item.inquiry, container: topThumbnailContainer))
        touchBody(InsightInquiryView(item: content_card_preview_item.inquiry, container: verticalInsight))
        touchBody(CompactHeightConferenceView(item: content_card_preview_item.conference, container: horizontalCompactHeight))
        touchBody(CompactWidthConferenceView(item: content_card_preview_item.conference, container: gridCompactWidth))
        touchBody(TopThumbnailConferenceView(item: content_card_preview_item.conference, container: topThumbnailContainer))
        touchBody(InsightConferenceView(item: content_card_preview_item.conference, container: verticalInsight))

        _ = CompactHeightDocumentView_Previews.previews
        _ = CompactWidthDocumentView_Previews.previews
        _ = TopThumbnailDocumentView_Previews.previews
        _ = InsightDocumentView_Previews.previews
        _ = CompactHeightOnDemandWebinarView_Previews.previews
        _ = CompactWidthOnDemandWebinarView_Previews.previews
        _ = TopThumbnailOnDemandWebinarView_Previews.previews
        _ = InsightOnDemandWebinarView_Previews.previews
        _ = CompactHeightUpcomingWebinarView_Previews.previews
        _ = CompactWidthUpcomingWebinarView_Previews.previews
        _ = TopThumbnailUpcomingWebinarView_Previews.previews
        _ = InsightUpcomingWebinarView_Previews.previews
        _ = CompactHeightVideoView_Previews.previews
        _ = CompactWidthVideoView_Previews.previews
        _ = TopThumbnailVideoView_Previews.previews
        _ = InsightVideoView_Previews.previews
        _ = CompactHeightPodcastView_Previews.previews
        _ = CompactWidthPodcastView_Previews.previews
        _ = TopThumbnailPodcastView_Previews.previews
        _ = InsightPodcastView_Previews.previews
        _ = CompactHeightInquiryView_Previews.previews
        _ = CompactWidthInquiryView_Previews.previews
        _ = TopThumbnailInquiryView_Previews.previews
        _ = InsightInquiryView_Previews.previews
        _ = CompactHeightConferenceView_Previews.previews
        _ = CompactWidthConferenceView_Previews.previews
        _ = TopThumbnailConferenceView_Previews.previews
        _ = InsightConferenceView_Previews.previews

        for cardType in [CardType.compactHeight, .compactWidth, .topThumbnail, .insight] {
            for item in mediaItems + eventItems {
                touchBody(card_type_content_type_view(cardType: cardType, item: item, container: horizontalCompactHeight))
            }
        }

        for cardType in [CardType.compactHeight, .compactWidth, .topThumbnail, .insight] {
            for item in mediaItems {
                touchBody(home_feed_media_card_view(item: item, cardType: cardType, container: gridCompactWidth))
            }
            for item in eventItems {
                touchBody(home_feed_event_card_view(item: item, cardType: cardType, container: verticalInsight))
            }
        }

        let imageHeavyDocument = FeedItem(
            id: "doc-gallery",
            contentType: .document,
            title: "Gallery Doc",
            behaviour: FeedItemBehaviour(
                summary: "Summary",
                media: FeedItemMedia(
                    imageURL: "https://example.com/one.png",
                    imageURLs: [
                        "https://example.com/one.png",
                        "https://example.com/two.png"
                    ],
                    showImage: true,
                    multipleImageSupport: true
                ),
                schedule: FeedItemSchedule(publishedDate: "24 February 2026"),
                primaryAction: FeedItemAction(title: "Read")
            )
        )

        let context = home_feed_card_context(item: imageHeavyDocument, cardType: .compactWidth, container: gridCompactWidth)
        _ = context.accent
        XCTAssertTrue(context.shouldShowImage)
        XCTAssertTrue(context.hasImage)
        XCTAssertEqual(context.primaryMetaText, "24 February 2026")
        XCTAssertNil(context.preferredWidth)
        XCTAssertEqual(context.accessibilityID, "COMPACT_WIDTH_DOCUMENT")

        let horizontalContext = home_feed_card_context(
            item: content_card_preview_item.conference,
            cardType: .insight,
            container: ContainerMeta(
                layout: .horizontalList,
                cardType: .insight,
                scrollDirection: .horizontal,
                showImage: false,
                cardCount: 1,
                imagePaginationEnabled: false
            )
        )
        XCTAssertEqual(horizontalContext.preferredWidth, 315)

        touchBody(home_feed_card_chrome(
            accent: .orange,
            minHeight: 120,
            preferredWidth: 200,
            accessibilityID: "coverage-card"
        ) {
            Text("Card")
        })
        touchBody(home_feed_media_copy_block_view(
            item: imageHeavyDocument,
            showsSummary: true,
            titleLineLimit: 3,
            summaryLineLimit: 2
        ))
        touchBody(home_feed_media_copy_block_view(
            item: imageHeavyDocument,
            showsSummary: false,
            titleLineLimit: 1,
            summaryLineLimit: 0
        ))
        touchBody(home_feed_media_image_container_view(
            item: imageHeavyDocument,
            container: gridCompactWidth,
            height: 94,
            width: nil,
            showRadius: true
        ))
        touchBody(home_feed_gallery_indicator_view())
        touchBody(home_feed_media_action_bar_view(item: content_card_preview_item.document))
        touchBody(home_feed_media_action_bar_view(item: content_card_preview_item.video))
        touchBody(home_feed_calendar_badge_view(item: content_card_preview_item.upcoming_webinar, size: 70))
        touchBody(home_feed_event_copy_block_view(
            item: content_card_preview_item.conference,
            showsSummary: true,
            titleLineLimit: 3,
            metaLineLimit: 2
        ))
        touchBody(home_feed_event_copy_block_view(
            item: content_card_preview_item.inquiry,
            showsSummary: false,
            titleLineLimit: 2,
            metaLineLimit: 1
        ))
        touchBody(home_feed_meta_text_view(text: "Sydney, Australia", lineLimit: 2))
        touchBody(home_feed_event_action_bar_view(item: content_card_preview_item.inquiry, vertical: true))
        touchBody(home_feed_event_action_bar_view(item: content_card_preview_item.conference, vertical: false))

        let noActionItem = FeedItem(id: "na", contentType: .conference, title: "No Action")
        touchBody(home_feed_event_action_bar_view(item: noActionItem, vertical: false))

        XCTAssertNotNil(home_feed_parse_date("24 February 2026"))
        XCTAssertNotNil(home_feed_parse_date("2024-09-17"))
        XCTAssertNotNil(home_feed_parse_date("Sep 17, 2024"))
        XCTAssertNil(home_feed_parse_date("not-a-date"))
    }

    func testHomeFeedSectionViewsAndPreviewCoverageHarness() throws {
        let previewLoading = feed_section_state_preview_fixture.loading
        let previewLoadedMedia = feed_section_state_preview_fixture.loadedMedia
        let previewLoadedEvent = feed_section_state_preview_fixture.loadedEvent
        let previewFailed = feed_section_state_preview_fixture.failed
        let previewSkipped = feed_section_state_preview_fixture.skipped

        touchBody(feed_section_state_preview_case_view(
            title: "Loading",
            note: "Coverage",
            section: previewLoading
        ))
        touchBody(feed_section_state_preview_case_view(
            title: "Loaded",
            note: nil,
            section: previewLoadedMedia
        ))
        _ = FeedSectionStateCases_Previews.previews

        let meta = previewLoadedMedia.meta
        let data = try XCTUnwrap({
            if case let .loaded(sectionData) = previewLoadedMedia.state {
                return sectionData
            }
            return nil
        }())

        let viewModel = HomeFeedViewModel(
            networkingProvider: RecordingMockProvider(
                config: .success(HomeConfig(sections: [meta])),
                sectionData: [meta.sectionType: .success(data)]
            ),
            capabilities: .default,
            persistenceMode: .inMemoryOnly
        )
        let done = expectation(description: "coverage home feed load")
        observeLoadingCompletion(viewModel: viewModel, done: done)
        viewModel.load()
        wait(for: [done], timeout: 2.0)

        touchBody(HomeFeedView(viewModel: viewModel, showsSkippedDebug: true))
        touchBody(section_view(section: previewLoading))
        touchBody(section_view(section: previewLoadedMedia))
        touchBody(section_view(section: previewFailed))
        touchBody(section_view(section: previewSkipped))
        touchBody(loading_section_content_view(meta: meta))
        touchBody(failed_section_content_view(message: "Unable to load"))
        touchBody(loaded_section_content_view(meta: meta, data: data))
        touchBody(section_chrome_view(meta: meta) {
            Text("Content")
        })
        touchBody(section_header_row_view(meta: meta))
        if let cta = meta.sectionHeaderCta {
            touchBody(section_cta_label_view(cta: cta))
        }
        if let footer = previewLoadedEvent.meta.preferredFooterCta {
            touchBody(section_cta_label_view(cta: footer))
        }
        touchBody(section_background_fill_view(meta: meta))
        touchBody(section_background_fill_view(meta: previewLoadedEvent.meta))

        let horizontal = try XCTUnwrap(meta.containers.first)
        let vertical = try XCTUnwrap(previewLoadedEvent.meta.containers.first)
        let grid = ContainerMeta(
            layout: .grid,
            cardType: .compactWidth,
            scrollDirection: .vertical,
            showImage: true,
            cardCount: 4,
            columns: 2,
            imagePaginationEnabled: false
        )

        touchBody(loading_container_list_view(container: horizontal, placeholderCount: 2))
        touchBody(loading_container_list_view(container: vertical, placeholderCount: 2))
        touchBody(loading_container_list_view(container: grid, placeholderCount: 2))
        touchBody(container_list_view(meta: meta, container: horizontal, items: data.items))
        touchBody(container_list_view(meta: previewLoadedEvent.meta, container: vertical, items: try XCTUnwrap({
            if case let .loaded(sectionData) = previewLoadedEvent.state {
                return sectionData.items
            }
            return nil
        }())))
        touchBody(container_list_view(meta: meta, container: grid, items: data.items))
        touchBody(loading_card_placeholder_view(container: horizontal))
        touchBody(loading_card_placeholder_view(container: vertical))
        touchBody(loading_card_placeholder_view(container: grid))
        touchBody(FeedSectionStatePreviewView(section: previewLoadedMedia))
        touchBody(FeedSectionStatePreviewView(section: previewSkipped))

        let metricsCompactHeight = loading_card_metrics(container: horizontal)
        let metricsCompactWidth = loading_card_metrics(container: grid)
        let metricsTopThumbnail = loading_card_metrics(container: ContainerMeta(
            layout: .verticalList,
            cardType: .topThumbnail,
            scrollDirection: .vertical,
            showImage: true,
            cardCount: 1,
            imagePaginationEnabled: false
        ))
        let metricsInsight = loading_card_metrics(container: ContainerMeta(
            layout: .verticalList,
            cardType: .insight,
            scrollDirection: .vertical,
            showImage: false,
            cardCount: 1,
            imagePaginationEnabled: false
        ))

        XCTAssertEqual(metricsCompactHeight.width, SystemDesign.CardMetrics.compactHeightWidth)
        XCTAssertNil(metricsCompactWidth.width)
        XCTAssertEqual(metricsTopThumbnail.minHeight, SystemDesign.CardMetrics.topThumbnailMinHeight)
        XCTAssertEqual(metricsInsight.minHeight, SystemDesign.CardMetrics.insightMinHeight)
    }

    func testRepositoryFactoryFallsBackToInMemoryForIOS16Runtime() {
        let store = HomeFeedRepositoryFactory.makeStoreDataSource(
            persistenceMode: .automatic,
            runtime: StubRuntime(isSwiftDataSupported: false)
        )

        XCTAssertTrue(store is InMemoryHomeFeedStoreDataSource)
    }

    func testRepositoryFactoryUsesInMemoryWhenForced() {
        let store = HomeFeedRepositoryFactory.makeStoreDataSource(
            persistenceMode: .inMemoryOnly,
            runtime: StubRuntime(isSwiftDataSupported: true)
        )

        XCTAssertTrue(store is InMemoryHomeFeedStoreDataSource)
    }

    func testCachedSectionsRenderBeforeBackgroundRefreshCompletes() throws {
        let cachedSection = makeSectionState(
            id: "cached",
            rank: 1,
            sectionType: "cached_section",
            title: "Cached item"
        )

        let store = InMemoryHomeFeedStoreDataSource(initialSections: [cachedSection])
        let config = HomeConfig(sections: [cachedSection.meta])
        let provider = RecordingMockProvider(
            config: .success(config),
            sectionData: ["cached_section": .success(SectionData(items: [FeedItem(id: "fresh_item", contentType: .video, title: "Fresh item")]))],
            delay: 0.2,
            configDelay: 0.05
        )

        let repository = HomeFeedRepositoryImpl(
            remoteDataSource: NetworkingHomeFeedRemoteDataSource(provider: provider),
            storeDataSource: store,
            capabilities: .default,
            chunkSize: 2
        )

        let viewModel = HomeFeedViewModel(
            observeSectionsUseCase: ObserveHomeFeedSectionsUseCase(repository: repository),
            observeSkippedSectionsUseCase: ObserveHomeFeedSkippedSectionsUseCase(repository: repository),
            observeEventsUseCase: ObserveHomeFeedEventsUseCase(repository: repository),
            refreshHomeFeedUseCase: RefreshHomeFeedUseCase(repository: repository),
            triggerSectionBehaviourUseCase: TriggerSectionBehaviourUseCase(repository: repository)
        )

        XCTAssertEqual(viewModel.sections.first?.meta.sectionType, "cached_section")
        XCTAssertEqual(firstLoadedItemTitle(in: viewModel.sections.first), "Cached item")

        let done = expectation(description: "refresh complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)
        viewModel.load()

        XCTAssertEqual(viewModel.sections.first?.meta.sectionType, "cached_section")
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(firstLoadedItemTitle(in: viewModel.sections.first), "Cached item")

        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        XCTAssertEqual(viewModel.sections.first?.meta.sectionType, "cached_section")
        XCTAssertEqual(firstLoadedItemTitle(in: viewModel.sections.first), "Cached item")

        wait(for: [done], timeout: 3.0)
        XCTAssertEqual(viewModel.sections.first?.meta.sectionType, "cached_section")
        XCTAssertEqual(firstLoadedItemTitle(in: viewModel.sections.first), "Fresh item")
    }

    func testBackgroundRefreshFailureKeepsCachedLoadedSectionVisible() {
        let cachedSection = makeSectionState(
            id: "cached",
            rank: 1,
            sectionType: "cached_section",
            title: "Cached item"
        )

        let store = InMemoryHomeFeedStoreDataSource(initialSections: [cachedSection])
        let config = HomeConfig(sections: [cachedSection.meta])
        let provider = RecordingMockProvider(
            config: .success(config),
            sectionData: ["cached_section": .failure(TestFailure.sectionFailed)]
        )

        let repository = HomeFeedRepositoryImpl(
            remoteDataSource: NetworkingHomeFeedRemoteDataSource(provider: provider),
            storeDataSource: store,
            capabilities: .default,
            chunkSize: 2
        )

        let viewModel = HomeFeedViewModel(
            observeSectionsUseCase: ObserveHomeFeedSectionsUseCase(repository: repository),
            observeSkippedSectionsUseCase: ObserveHomeFeedSkippedSectionsUseCase(repository: repository),
            observeEventsUseCase: ObserveHomeFeedEventsUseCase(repository: repository),
            refreshHomeFeedUseCase: RefreshHomeFeedUseCase(repository: repository),
            triggerSectionBehaviourUseCase: TriggerSectionBehaviourUseCase(repository: repository)
        )

        let done = expectation(description: "refresh complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)
        viewModel.load()

        wait(for: [done], timeout: 2.0)
        XCTAssertEqual(viewModel.sections.first?.meta.sectionType, "cached_section")
        XCTAssertEqual(firstLoadedItemTitle(in: viewModel.sections.first), "Cached item")
    }

    func testViewModelReflectsStoreChangesWithoutManualRefresh() {
        let sectionA = makeSectionState(id: "a", rank: 1, sectionType: "a", title: "A")
        let sectionB = makeSectionState(id: "b", rank: 2, sectionType: "b", title: "B")
        let store = InMemoryHomeFeedStoreDataSource(initialSections: [sectionA])
        let provider = RecordingMockProvider(config: .failure(TestFailure.sectionFailed), sectionData: [:])

        let repository = HomeFeedRepositoryImpl(
            remoteDataSource: NetworkingHomeFeedRemoteDataSource(provider: provider),
            storeDataSource: store,
            capabilities: .default,
            chunkSize: 2
        )

        let viewModel = HomeFeedViewModel(
            observeSectionsUseCase: ObserveHomeFeedSectionsUseCase(repository: repository),
            observeSkippedSectionsUseCase: ObserveHomeFeedSkippedSectionsUseCase(repository: repository),
            observeEventsUseCase: ObserveHomeFeedEventsUseCase(repository: repository),
            refreshHomeFeedUseCase: RefreshHomeFeedUseCase(repository: repository),
            triggerSectionBehaviourUseCase: TriggerSectionBehaviourUseCase(repository: repository)
        )

        XCTAssertEqual(viewModel.sections.map(\.meta.sectionType), ["a"])
        store.replaceSections([sectionA, sectionB])
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(viewModel.sections.map(\.meta.sectionType), ["a", "b"])
    }

#if canImport(SwiftData)
    @available(iOS 17.0, *)
    func testSwiftDataStorePersistsAndRestoresSections() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: HomeFeedStateRecord.self, configurations: configuration)
        let initialStore = try SwiftDataHomeFeedStoreDataSource(container: container)

        let section = makeSectionState(id: "swiftdata", rank: 1, sectionType: "swiftdata", title: "Persisted")
        initialStore.replace(sections: [section], skippedSections: [])
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        let reloadStore = try SwiftDataHomeFeedStoreDataSource(container: container)
        XCTAssertEqual(reloadStore.currentSections().first?.meta.sectionType, "swiftdata")
        XCTAssertEqual(reloadStore.currentSections().first?.state, section.state)
    }
#endif

    private func touchBody<V: View>(_ view: V, depth: Int = 6) {
        guard depth > 0 else {
            return
        }

        if V.Body.self == Never.self {
            return
        }

        let nested = view.body
        touchBody(nested, depth: depth - 1)
    }

    private func observeLoadingCompletion(viewModel: HomeFeedViewModel, done: XCTestExpectation) {
        viewModel.$isLoading
            .dropFirst()
            .sink { loading in
                if !loading {
                    done.fulfill()
                }
            }
            .store(in: &cancellables)
    }

    private func loadFixtureConfig(named name: String) throws -> HomeConfig {
        let data = try Data(contentsOf: fixtureURL(name: name))
        return try HomeFeedConfigParser().parse(data: data)
    }

    private func loadFixtureSectionData(named name: String) throws -> [String: Result<SectionData, Error>] {
        let data = try Data(contentsOf: fixtureURL(name: name))
        let parsed = try MockSectionDataParser.parse(data: data)
        return parsed.mapValues { .success($0) }
    }

    private func fixtureURL(name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(name)
    }

    private func awaitValue<T>(_ publisher: AnyPublisher<T, Error>, timeout: TimeInterval = 2.0) throws -> T {
        let done = expectation(description: "await publisher")
        var output: T?
        var outputError: Error?

        publisher
            .sink { completion in
                if case let .failure(error) = completion {
                    outputError = error
                }
                done.fulfill()
            } receiveValue: { value in
                output = value
            }
            .store(in: &cancellables)

        wait(for: [done], timeout: timeout)

        if let outputError {
            throw outputError
        }
        guard let output else {
            throw TestFailure.sectionFailed
        }
        return output
    }

    private func render<V: View>(_ view: V) {
        let host = UIHostingController(rootView: view)
        host.loadViewIfNeeded()
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    private func makeSectionState(id: String, rank: Int, sectionType: String, title: String) -> FeedSectionState {
        let meta = SectionMeta(
            id: id,
            originalOrder: rank,
            rank: rank,
            sectionType: sectionType,
            endpoint: "/\(sectionType)",
            supportedContents: [.video],
            showSection: true,
            groupCount: nil,
            cardCount: nil,
            containers: [
                ContainerMeta(
                    layout: .verticalList,
                    cardType: .standardCard,
                    scrollDirection: .vertical,
                    showImage: true,
                    cardCount: 1,
                    imagePaginationEnabled: false
                )
            ],
            behaviour: nil,
            declaredParameters: ["rank", "section_type", "endpoint", "supportedContents", "showSection", "containers"],
            unknownParameters: []
        )

        return FeedSectionState(
            meta: meta,
            state: .loaded(SectionData(items: [FeedItem(id: "\(id)_item", contentType: .video, title: title)]))
        )
    }

    private func firstLoadedItemTitle(in section: FeedSectionState?) -> String? {
        guard let section else {
            return nil
        }

        guard case let .loaded(data) = section.state else {
            return nil
        }

        return data.items.first?.title
    }
}

private enum TestFailure: Error {
    case sectionFailed
}

private struct StubRuntime: HomeFeedRuntime {
    let isSwiftDataSupported: Bool
}

private final class TrackingListenHandler: ListenButtonHandler {
    func listenContent() {}
}

private final class TrackingPlayHandler: PlayButtonHandler {
    func playContent() {}
}

private final class TrackingSaveHandler: SaveButtonHandler {
    func saveContent() {}
}

private final class RecordingMockProvider: HomeFeedNetworkingProvider {
    private let configResult: Result<HomeConfig, Error>
    private var sectionData: [String: Result<SectionData, Error>]
    private let delay: TimeInterval
    private let configDelay: TimeInterval

    private let lock = NSLock()
    private(set) var configFetchCount: Int = 0
    private(set) var fetchSectionCallTypes: [String] = []
    private(set) var maxConcurrentSectionRequests: Int = 0
    private var concurrentSectionRequests: Int = 0

    init(
        config: Result<HomeConfig, Error>,
        sectionData: [String: Result<SectionData, Error>],
        delay: TimeInterval = 0,
        configDelay: TimeInterval = 0
    ) {
        self.configResult = config
        self.sectionData = sectionData
        self.delay = delay
        self.configDelay = configDelay
    }

    func fetchHomeConfiguration() -> AnyPublisher<HomeConfig, Error> {
        lock.lock()
        configFetchCount += 1
        lock.unlock()

        if configDelay == 0 {
            return configResult.publisher.eraseToAnyPublisher()
        }

        return Deferred { [weak self] in
            Future { promise in
                guard let self else {
                    promise(.failure(TestFailure.sectionFailed))
                    return
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + self.configDelay) {
                    promise(self.configResult)
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchSectionData(for section: SectionMeta) -> AnyPublisher<SectionData, Error> {
        Deferred { [weak self] in
            Future { promise in
                guard let self else {
                    promise(.failure(TestFailure.sectionFailed))
                    return
                }

                self.lock.lock()
                self.fetchSectionCallTypes.append(section.sectionType)
                self.concurrentSectionRequests += 1
                self.maxConcurrentSectionRequests = max(
                    self.maxConcurrentSectionRequests,
                    self.concurrentSectionRequests
                )
                self.lock.unlock()

                let result = self.sectionData[section.sectionType] ?? .success(SectionData(items: []))
                DispatchQueue.global().asyncAfter(deadline: .now() + self.delay) {
                    self.lock.lock()
                    self.concurrentSectionRequests -= 1
                    self.lock.unlock()
                    promise(result)
                }
            }
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
#endif
