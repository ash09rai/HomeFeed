import Foundation

public final class HomeFeedConfigParser {
    public static let knownSectionParameters: Set<String> = [
        "rank",
        "section_type",
        "endpoint",
        "header",
        "supportedContents",
        "theme",
        "analytics",
        "showSection",
        "groupCount",
        "cardCount",
        "sectionHeaderCta",
        "sectionFooterCta",
        "footerCta",
        "contentHeaderCta",
        "contentFooterCta",
        "sectionStyle",
        "placement",
        "containers",
        "behaviour"
    ]

    private static let knownContainerParameters: Set<String> = [
        "layout",
        "cardType",
        "cardtype",
        "showImage",
        "cardCount",
        "columns",
        "showViewedStatus",
        "imagePaginationEnabled",
        "scrollDirection"
    ]

    private static let knownBehaviourParameters: Set<String> = [
        "parameter",
        "updatedValue",
        "action"
    ]

    public init() {}

    public func parse(data: Data) throws -> HomeConfig {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let sectionObjects = json as? [[String: Any]] else {
            throw ConfigurationValidationError.malformedConfiguration("Expected top-level array of section objects")
        }

        let sections = try sectionObjects.enumerated().map { index, section in
            try parseSection(section, at: index)
        }

        return HomeConfig(sections: sections)
    }

    private func parseSection(_ section: [String: Any], at index: Int) throws -> SectionMeta {
        let unknownSectionParameters = Set(section.keys).subtracting(Self.knownSectionParameters)
        if !unknownSectionParameters.isEmpty {
            throw ConfigurationValidationError.unknownParameters(unknownSectionParameters.sorted())
        }

        guard let rank = intValue(section["rank"]) else {
            throw ConfigurationValidationError.malformedConfiguration("Section at index \(index) is missing rank")
        }

        let sectionType = stringValue(section["section_type"]) ?? "unknown"
        let endpoint = stringValue(section["endpoint"])
        let supportedContents: [ContentType] = (section["supportedContents"] as? [Any] ?? []).compactMap { value in
            guard let parsed = stringValue(value) else {
                return nil
            }
            return ContentType(rawValue: parsed)
        }
        let showSection = boolValue(section["showSection"]) ?? true
        let groupCount = intValue(section["groupCount"])
        let cardCount = intValue(section["cardCount"])

        let rawContainers = section["containers"] as? [[String: Any]] ?? []
        var unknownContainerKeys: Set<String> = []
        let containers = try rawContainers.map { container -> ContainerMeta in
            let unknown = Set(container.keys).subtracting(Self.knownContainerParameters)
            unknownContainerKeys.formUnion(unknown.map { "containers.\($0)" })

            guard let layoutValue = stringValue(container["layout"]) else {
                throw ConfigurationValidationError.malformedConfiguration("Container layout is required")
            }

            let cardTypeValue = stringValue(container["cardType"]) ?? stringValue(container["cardtype"])
            guard let cardTypeValue else {
                throw ConfigurationValidationError.malformedConfiguration("Container cardType/cardtype is required")
            }

            let direction = stringValue(container["scrollDirection"]) ?? defaultDirection(for: layoutValue)

            return ContainerMeta(
                layout: LayoutType(rawValue: layoutValue),
                cardType: CardType(rawValue: cardTypeValue),
                scrollDirection: ScrollDirection(rawValue: direction),
                showImage: boolValue(container["showImage"]) ?? true,
                cardCount: intValue(container["cardCount"]),
                imagePaginationEnabled: boolValue(container["imagePaginationEnabled"]) ?? false
            )
        }

        var unknownBehaviourKeys: Set<String> = []
        let behaviour: BehaviourRule?
        if let rawBehaviour = section["behaviour"] as? [String: Any] {
            let unknown = Set(rawBehaviour.keys).subtracting(Self.knownBehaviourParameters)
            unknownBehaviourKeys.formUnion(unknown.map { "behaviour.\($0)" })

            if
                let parameter = stringValue(rawBehaviour["parameter"]),
                let updatedValue = stringValue(rawBehaviour["updatedValue"]),
                let action = stringValue(rawBehaviour["action"])
            {
                behaviour = BehaviourRule(
                    parameter: parameter,
                    updatedValue: updatedValue,
                    action: BehaviourAction(rawValue: action)
                )
            } else {
                behaviour = nil
            }
        } else {
            behaviour = nil
        }

        let unknownNested = unknownContainerKeys.union(unknownBehaviourKeys)
        if !unknownNested.isEmpty {
            throw ConfigurationValidationError.unknownParameters(unknownNested.sorted())
        }

        return SectionMeta(
            id: "\(sectionType)-\(index)-\(rank)",
            originalOrder: index,
            rank: rank,
            sectionType: sectionType,
            endpoint: endpoint,
            supportedContents: supportedContents,
            showSection: showSection,
            groupCount: groupCount,
            cardCount: cardCount,
            containers: containers,
            behaviour: behaviour,
            declaredParameters: Set(section.keys),
            unknownParameters: []
        )
    }

    private func stringValue(_ value: Any?) -> String? {
        guard let value, !(value is NSNull) else {
            return nil
        }

        if let string = value as? String {
            return string
        }

        if let int = value as? Int {
            return String(int)
        }

        return nil
    }

    private func intValue(_ value: Any?) -> Int? {
        guard let value, !(value is NSNull) else {
            return nil
        }

        if let int = value as? Int {
            return int
        }

        if let string = value as? String {
            return Int(string)
        }

        return nil
    }

    private func boolValue(_ value: Any?) -> Bool? {
        guard let value, !(value is NSNull) else {
            return nil
        }

        if let bool = value as? Bool {
            return bool
        }

        if let string = value as? String {
            return NSString(string: string).boolValue
        }

        return nil
    }

    private func defaultDirection(for layout: String) -> String {
        switch layout.uppercased() {
        case LayoutType.horizontalList.rawValue:
            return ScrollDirection.horizontal.rawValue
        case LayoutType.verticalList.rawValue:
            return ScrollDirection.vertical.rawValue
        default:
            return ScrollDirection.vertical.rawValue
        }
    }
}
