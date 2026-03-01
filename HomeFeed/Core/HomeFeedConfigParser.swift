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

    private static let knownHeaderParameters: Set<String> = [
        "title",
        "subtitle",
        "titleColor",
        "subtitleColor"
    ]

    private static let knownThemeParameters: Set<String> = [
        "backgroundImage",
        "backgroundColor",
        "primaryColor",
        "secondaryColor"
    ]

    private static let knownCtaParameters: Set<String> = [
        "actionType",
        "actionName",
        "title",
        "text",
        "position"
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
        let header = parseHeader(from: section["header"])
        let supportedContents: [ContentType] = (section["supportedContents"] as? [Any] ?? []).compactMap { value in
            guard let parsed = stringValue(value) else {
                return nil
            }
            return ContentType(rawValue: parsed)
        }
        let theme = parseTheme(from: section["theme"])
        let analytics = stringValue(section["analytics"])
        let showSection = boolValue(section["showSection"]) ?? true
        let groupCount = intValue(section["groupCount"])
        let cardCount = intValue(section["cardCount"])
        let sectionHeaderCta = parseCta(from: section["sectionHeaderCta"])
        let footerCta = parseCta(from: section["footerCta"]) ?? parseCta(from: section["sectionFooterCta"])
        let contentHeaderCta = parseCta(from: section["contentHeaderCta"])
        let contentFooterCta = parseCta(from: section["contentFooterCta"])
        let sectionStyle = stringValue(section["sectionStyle"])
        let placement = stringValue(section["placement"])

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
        var unknownHeaderKeys: Set<String> = []
        var unknownThemeKeys: Set<String> = []
        var unknownCtaKeys: Set<String> = []
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

        if let rawHeader = section["header"] as? [String: Any] {
            let unknown = Set(rawHeader.keys).subtracting(Self.knownHeaderParameters)
            unknownHeaderKeys.formUnion(unknown.map { "header.\($0)" })
        }

        if let rawTheme = section["theme"] as? [String: Any] {
            let unknown = Set(rawTheme.keys).subtracting(Self.knownThemeParameters)
            unknownThemeKeys.formUnion(unknown.map { "theme.\($0)" })
        }

        [
            ("sectionHeaderCta", section["sectionHeaderCta"]),
            ("footerCta", section["footerCta"]),
            ("sectionFooterCta", section["sectionFooterCta"]),
            ("contentHeaderCta", section["contentHeaderCta"]),
            ("contentFooterCta", section["contentFooterCta"])
        ].forEach { prefix, rawValue in
            guard let rawCta = rawValue as? [String: Any] else {
                return
            }
            let unknown = Set(rawCta.keys).subtracting(Self.knownCtaParameters)
            unknownCtaKeys.formUnion(unknown.map { "\(prefix).\($0)" })
        }

        let unknownNested = unknownContainerKeys
            .union(unknownBehaviourKeys)
            .union(unknownHeaderKeys)
            .union(unknownThemeKeys)
            .union(unknownCtaKeys)
        if !unknownNested.isEmpty {
            throw ConfigurationValidationError.unknownParameters(unknownNested.sorted())
        }

        return SectionMeta(
            id: "\(sectionType)-\(index)-\(rank)",
            originalOrder: index,
            rank: rank,
            sectionType: sectionType,
            endpoint: endpoint,
            header: header,
            supportedContents: supportedContents,
            theme: theme,
            analytics: analytics,
            showSection: showSection,
            groupCount: groupCount,
            cardCount: cardCount,
            sectionHeaderCta: sectionHeaderCta,
            footerCta: footerCta,
            contentHeaderCta: contentHeaderCta,
            contentFooterCta: contentFooterCta,
            sectionStyle: sectionStyle,
            placement: placement,
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

    private func parseHeader(from value: Any?) -> SectionHeaderMeta? {
        guard let rawHeader = value as? [String: Any] else {
            return nil
        }

        return SectionHeaderMeta(
            title: stringValue(rawHeader["title"]),
            subtitle: stringValue(rawHeader["subtitle"]),
            titleColorHex: stringValue(rawHeader["titleColor"]),
            subtitleColorHex: stringValue(rawHeader["subtitleColor"])
        )
    }

    private func parseTheme(from value: Any?) -> SectionThemeMeta? {
        guard let rawTheme = value as? [String: Any] else {
            return nil
        }

        return SectionThemeMeta(
            backgroundImageURL: stringValue(rawTheme["backgroundImage"]),
            primaryColorHex: stringValue(rawTheme["primaryColor"]) ?? stringValue(rawTheme["backgroundColor"]),
            secondaryColorHex: stringValue(rawTheme["secondaryColor"]) ?? stringValue(rawTheme["backgroundColor"])
        )
    }

    private func parseCta(from value: Any?) -> SectionCtaMeta? {
        guard let rawCta = value as? [String: Any] else {
            return nil
        }

        return SectionCtaMeta(
            actionType: stringValue(rawCta["actionType"]),
            actionName: stringValue(rawCta["actionName"]),
            text: stringValue(rawCta["text"]) ?? stringValue(rawCta["title"]),
            position: stringValue(rawCta["position"])
        )
    }
}
