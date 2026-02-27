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

        XCTAssertEqual(result.validSections.map(\.sectionType), ["last_activity", "recommended"])
        XCTAssertEqual(result.validSections.map(\.rank), [1, 2])
        XCTAssertEqual(Set(result.skippedSections.map { $0.0.sectionType }), ["unsupported_layout", "hidden"])
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

        XCTAssertEqual(provider.fetchSectionCallTypes.sorted(), ["last_activity", "recommended"])
        XCTAssertEqual(viewModel.skippedSections.count, 2)
        XCTAssertEqual(viewModel.sections.count, 2)
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
                "layout": "GRID",
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

        let viewModel = HomeFeedViewModel(networkingProvider: provider, capabilities: .default)

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

    func testMockSectionDataParserSupportsDataWrapperFormat() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/ashishrai/Desktop/Projects/Personal Frameworks/HomeFeed/HomeFeed/Mocks/MockSectionResponse.json"))
        let parsed = try MockSectionDataParser.parse(data: data)

        let defaultItems = parsed["default"]?.items ?? []
        XCTAssertFalse(defaultItems.isEmpty)
        XCTAssertTrue(defaultItems.contains(where: { $0.contentType == .video }))
        XCTAssertTrue(defaultItems.contains(where: { $0.contentType == .onDemandWebinar || $0.contentType == .upcomingWebinar }))
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
        XCTAssertEqual(conference.eventStartDate, "2024-09-17")
        XCTAssertEqual(conference.eventLocation, "Sydney, Australia")
        XCTAssertEqual(conference.statusText, "Registered")
        XCTAssertEqual(conference.primaryAction?.title, "Build Agenda")
        XCTAssertEqual(conference.secondaryAction?.title, "See Highlights")
    }

    func testUpdatedMockConfigParsesWithKnownParameters() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/ashishrai/Desktop/Projects/Personal Frameworks/HomeFeed/HomeFeed/Mocks/MockHomeFeedConfig.json"))
        let config = try HomeFeedConfigParser().parse(data: data)

        XCTAssertFalse(config.sections.isEmpty)
        XCTAssertTrue(config.sections.contains(where: { $0.sectionType == "last_activity" }))
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
        let refreshedSection = makeSectionState(
            id: "fresh",
            rank: 1,
            sectionType: "fresh_section",
            title: "Fresh item"
        )

        let store = InMemoryHomeFeedStoreDataSource(initialSections: [cachedSection])
        let config = HomeConfig(sections: [refreshedSection.meta])
        let provider = RecordingMockProvider(
            config: .success(config),
            sectionData: ["fresh_section": .success(SectionData(items: [FeedItem(id: "fresh_item", contentType: .video, title: "Fresh item")]))],
            delay: 0.2,
            configDelay: 0.1
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

        let done = expectation(description: "refresh complete")
        observeLoadingCompletion(viewModel: viewModel, done: done)
        viewModel.load()

        XCTAssertEqual(viewModel.sections.first?.meta.sectionType, "cached_section")
        XCTAssertTrue(viewModel.isLoading)

        wait(for: [done], timeout: 3.0)
        XCTAssertEqual(viewModel.sections.first?.meta.sectionType, "fresh_section")
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
}

private enum TestFailure: Error {
    case sectionFailed
}

private struct StubRuntime: HomeFeedRuntime {
    let isSwiftDataSupported: Bool
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
