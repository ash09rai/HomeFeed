import Combine
import Foundation

public final class MockHomeFeedNetworkingProvider: HomeFeedNetworkingProvider {
    public var configResult: Result<HomeConfig, Error>
    public var sectionResults: [String: Result<SectionData, Error>]

    public init(
        config: HomeConfig,
        sectionResults: [String: Result<SectionData, Error>]
    ) {
        self.configResult = .success(config)
        self.sectionResults = sectionResults
    }

    public init(
        configResult: Result<HomeConfig, Error>,
        sectionResults: [String: Result<SectionData, Error>] = [:]
    ) {
        self.configResult = configResult
        self.sectionResults = sectionResults
    }

    public func fetchHomeConfiguration() -> AnyPublisher<HomeConfig, Error> {
        configResult.publisher.eraseToAnyPublisher()
    }

    public func fetchSectionData(for section: SectionMeta) -> AnyPublisher<SectionData, Error> {
        let result = sectionResults[section.sectionType] ?? .success(SectionData(items: []))
        return result.publisher.eraseToAnyPublisher()
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
}

public enum MockSectionDataParser {
    public static func parse(data: Data) throws -> [String: SectionData] {
        let raw = try JSONSerialization.jsonObject(with: normalizedJSONData(from: data))

        if let dict = raw as? [String: [[String: Any]]] {
            var output: [String: SectionData] = [:]
            for (sectionType, items) in dict {
                output[sectionType] = SectionData(items: parseItems(from: items))
            }
            return output
        }

        if let wrapper = raw as? [String: Any], let items = wrapper["data"] as? [[String: Any]] {
            return ["default": SectionData(items: parseItems(from: items))]
        }

        if let items = raw as? [[String: Any]] {
            return ["default": SectionData(items: parseItems(from: items))]
        }

        throw ConfigurationValidationError.malformedConfiguration(
            "Mock section response should be a dictionary, array, or data wrapper"
        )
    }

    private static func parseItems(from items: [[String: Any]]) -> [FeedItem] {
        items.compactMap { item in
            guard let title = nonEmpty(stringValue(item["title"])) else {
                return nil
            }

            guard let contentType = resolvedContentType(for: item) else {
                return nil
            }

            guard let id = resolvedIdentifier(for: item, contentType: contentType) else {
                return nil
            }

            return FeedItem(
                id: id,
                contentType: contentType,
                title: title,
                behaviour: resolvedBehaviour(for: item, contentType: contentType)
            )
        }
    }

    private static func resolvedContentType(for item: [String: Any]) -> ContentType? {
        if isInquiry(item) {
            return .inquiry
        }

        if isConference(item) {
            return .conference
        }

        if let declared = stringValue(item["contentType"]) {
            let canonical = ContentType(rawValue: declared)
            if canonical == .onDemandWebinar || canonical == .upcomingWebinar {
                return inferredWebinarType(for: item) ?? canonical
            }
            return canonical
        }

        if item["webinarId"] != nil || item["wbnrTypeCode"] != nil || item["wbnrStatus"] != nil || item["webinarStatus"] != nil {
            return inferredWebinarType(for: item) ?? .onDemandWebinar
        }

        return nil
    }

    private static func resolvedIdentifier(for item: [String: Any], contentType: ContentType) -> String? {
        switch contentType {
        case .document:
            return firstNonEmptyString([
                stringValue(item["resId"]),
                stringValue(item["contentId"]),
                stringValue(item["docCode"])
            ])
        case .onDemandWebinar:
            return firstNonEmptyString([
                stringValue(item["contentId"]),
                linkedDocumentIdentifier(from: item),
                stringValue(item["webinarId"]),
                stringValue(item["resId"])
            ])
        case .upcomingWebinar:
            return firstNonEmptyString([
                linkedDocumentIdentifier(from: item),
                stringValue(item["contentId"]),
                stringValue(item["webinarId"]),
                stringValue(item["resId"])
            ])
        case .video, .podcast:
            return firstNonEmptyString([
                stringValue(item["contentId"]),
                linkedDocumentIdentifier(from: item),
                stringValue(item["assetId"]),
                stringValue(item["resId"])
            ])
        case .inquiry:
            return firstNonEmptyString([
                stringValue(item["inquiryRefNum"]),
                stringValue(item["id"])
            ])
        case .conference:
            return firstNonEmptyString([
                stringValue(item["eventURL"]),
                stringValue(item["id"]),
                stringValue(item["title"])
            ])
        default:
            return firstNonEmptyString([
                stringValue(item["id"]),
                stringValue(item["contentId"]),
                stringValue(item["resId"]),
                stringValue(item["webinarId"])
            ])
        }
    }

    private static func resolvedBehaviour(for item: [String: Any], contentType: ContentType) -> FeedItemBehaviour {
        let imageURLs = imageAssetURLs(from: item)
        let imageURL = firstNonEmptyString([
            stringValue(item["image"]),
            stringValue(item["thumbnail"]),
            imageURLs.first
        ])

        var behaviour = FeedItemBehaviour(
            summary: firstNonEmptyString([
                stringValue(item["description"]),
                stringValue(item["feature"]),
                stringValue(item["subTitle"])
            ]),
            media: FeedItemMedia(
                imageURL: imageURL,
                showImage: imageURL == nil ? nil : true,
                multipleImageSupport: imageURLs.count > 1 ? true : nil
            )
        )

        switch contentType {
        case .document:
            behaviour.schedule = FeedItemSchedule(
                publishedDate: nonEmpty(stringValue(item["pubDate"]))
            )

        case .onDemandWebinar:
            behaviour.schedule = FeedItemSchedule(
                publishedDate: nonEmpty(stringValue(item["pubDate"]))
            )
            behaviour.statusText = normalizedLabel(from: stringValue(item["webinarStatus"]))

        case .upcomingWebinar:
            let isRegistered = boolValue(item["userRegistered"])
            let registrationURL = nonEmpty(stringValue(item["eventRegUrl"]))
            let eventDate = firstNonEmptyString([
                stringValue(item["eventDate"]),
                stringValue(item["formattedStartDate"]),
                formattedDate(fromEpochMilliseconds: epochMilliseconds(item["startDateEpoc"]), timeZoneHint: stringValue(item["timezone"]))
            ])
            let eventTime = firstNonEmptyString([
                stringValue(item["eventTime"]),
                formattedTimeRange(from: item),
                formattedTime(fromEpochMilliseconds: epochMilliseconds(item["startDateEpoc"]), timeZoneHint: stringValue(item["timezone"]))
            ])

            behaviour.schedule = FeedItemSchedule(
                eventDate: eventDate,
                eventTime: eventTime,
                displayTimeZone: nonEmpty(stringValue(item["timezone"]))
            )
            behaviour.statusText = isRegistered == true ? "Registered" : normalizedLabel(from: stringValue(item["webinarStatus"]))
            behaviour.isRegistered = isRegistered
            if boolValue(item["showRegisterOption"]) == true || isRegistered == true {
                behaviour.primaryAction = FeedItemAction(
                    title: isRegistered == true ? "Registered" : "Register",
                    url: registrationURL
                )
            }

        case .video:
            behaviour.schedule = FeedItemSchedule(
                publishedDate: nonEmpty(stringValue(item["pubDate"]))
            )

        case .podcast:
            behaviour.schedule = FeedItemSchedule(
                publishedDate: nonEmpty(stringValue(item["pubDate"]))
            )
            behaviour.primaryAction = FeedItemAction(title: "Listen", url: nonEmpty(stringValue(item["playbackURL"])))

        case .inquiry:
            let timeZoneHint = firstNonEmptyString([
                stringValue(item["displayTimeZone"]),
                stringValue(item["timezone"])
            ])
            let eventDate = firstNonEmptyString([
                stringValue(item["clientActionDate"]),
                formattedDate(fromEpochMilliseconds: epochMilliseconds(item["startDateEpoc"]), timeZoneHint: timeZoneHint)
            ])
            let eventTime = firstNonEmptyString([
                stringValue(item["clientActionTime"]),
                formattedTime(fromEpochMilliseconds: epochMilliseconds(item["startDateEpoc"]), timeZoneHint: timeZoneHint)
            ])

            behaviour.schedule = FeedItemSchedule(
                eventDate: eventDate,
                eventTime: eventTime,
                displayTimeZone: timeZoneHint
            )
            behaviour.statusText = normalizedLabel(from: stringValue(item["inquiryStatus"]))
            behaviour.primaryAction = FeedItemAction(title: "Scheduled")
            behaviour.secondaryAction = FeedItemAction(title: "Edit Inquiry")

        case .conference:
            behaviour.schedule = FeedItemSchedule(
                eventStartDate: nonEmpty(stringValue(item["dateStart"])),
                eventEndDate: nonEmpty(stringValue(item["dateEnd"])),
                eventTime: nonEmpty(stringValue(item["eventTime"])),
                eventLocation: nonEmpty(stringValue(item["city"]))
            )
            behaviour.statusText = "Registered"
            behaviour.primaryAction = action(from: item["primaryCTA"])
            behaviour.secondaryAction = action(from: item["secondaryCTA"]) ?? FeedItemAction(title: "View Schedule")

        default:
            break
        }

        return behaviour
    }

    private static func inferredWebinarType(for item: [String: Any]) -> ContentType? {
        let signals = [
            stringValue(item["webinarStatus"]),
            stringValue(item["wbnrStatus"]),
            stringValue(item["activityPeriod"])
        ]
        .compactMap { $0?.uppercased() }

        if signals.contains(where: { $0.contains("UPCOMING") }) {
            return .upcomingWebinar
        }

        if signals.contains(where: { $0.contains("ON DEMAND") || $0.contains("ON_DEMAND") || $0.contains("COMPLETED") }) {
            return .onDemandWebinar
        }

        return nil
    }

    private static func isInquiry(_ item: [String: Any]) -> Bool {
        item["inquiryRefNum"] != nil || item["inquiryStatus"] != nil
    }

    private static func isConference(_ item: [String: Any]) -> Bool {
        if item["eventURL"] != nil || item["primaryCTA"] != nil || item["secondaryCTA"] != nil || item["bannerTitle"] != nil {
            return true
        }
        guard let type = stringValue(item["type"])?.uppercased() else {
            return false
        }
        return type == "CONFERENCE"
    }

    private static func linkedDocumentIdentifier(from item: [String: Any]) -> String? {
        guard let linkedDocs = item["linkedDocCodes"] as? [[String: Any]] else {
            return nil
        }
        return linkedDocs.lazy.compactMap { entry in
            firstNonEmptyString([
                stringValue(entry["resId"]),
                stringValue(entry["docCode"])
            ])
        }.first
    }

    private static func imageAssetURLs(from item: [String: Any]) -> [String] {
        guard let assets = item["assets"] as? [[String: Any]] else {
            return []
        }

        return assets.compactMap { asset in
            guard let type = stringValue(asset["type"])?.uppercased() else {
                return nil
            }
            guard type == "THUMBNAIL" || type == "IMAGE" else {
                return nil
            }
            return nonEmpty(stringValue(asset["url"]))
        }
    }

    private static func action(from value: Any?) -> FeedItemAction? {
        guard let value = value as? [String: Any] else {
            return nil
        }
        guard let title = nonEmpty(stringValue(value["title"])) else {
            return nil
        }
        return FeedItemAction(title: title, url: nonEmpty(stringValue(value["url"])))
    }

    private static func formattedTimeRange(from item: [String: Any]) -> String? {
        guard
            let start = nonEmpty(stringValue(item["formattedStartTime"])),
            let end = nonEmpty(stringValue(item["formattedEndTime"]))
        else {
            return nil
        }

        if let suffix = timeZoneSuffix(from: stringValue(item["timezone"])) {
            return "\(start) - \(end) \(suffix)"
        }
        return "\(start) - \(end)"
    }

    private static func formattedDate(fromEpochMilliseconds value: Double?, timeZoneHint: String?) -> String? {
        guard let value else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        formatter.timeZone = resolvedTimeZone(from: timeZoneHint) ?? TimeZone(secondsFromGMT: 0)
        return formatter.string(from: Date(timeIntervalSince1970: value / 1_000))
    }

    private static func formattedTime(fromEpochMilliseconds value: Double?, timeZoneHint: String?) -> String? {
        guard let value else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = resolvedTimeZone(from: timeZoneHint) ?? TimeZone(secondsFromGMT: 0)

        let date = Date(timeIntervalSince1970: value / 1_000)
        let time = formatter.string(from: date)
        if let suffix = timeZoneSuffix(from: timeZoneHint) {
            return "\(time) \(suffix)"
        }
        return time
    }

    private static func resolvedTimeZone(from hint: String?) -> TimeZone? {
        guard let hint = nonEmpty(hint) else {
            return nil
        }

        if let zone = TimeZone(identifier: hint) {
            return zone
        }

        return TimeZone(abbreviation: hint)
    }

    private static func timeZoneSuffix(from hint: String?) -> String? {
        guard let hint = nonEmpty(hint) else {
            return nil
        }

        if TimeZone(abbreviation: hint) != nil {
            return hint
        }

        return TimeZone(identifier: hint)?.abbreviation()
    }

    private static func normalizedLabel(from value: String?) -> String? {
        guard let value = nonEmpty(value) else {
            return nil
        }

        return value
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private static func firstNonEmptyString(_ values: [String?]) -> String? {
        values.lazy.compactMap { nonEmpty($0) }.first
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func epochMilliseconds(_ value: Any?) -> Double? {
        guard let value else {
            return nil
        }
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let string = value as? String, let parsed = Double(string) {
            return parsed
        }
        return nil
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let value else {
            return nil
        }
        if let string = value as? String {
            return string
        }
        if let int = value as? Int {
            return String(int)
        }
        if let int64 = value as? Int64 {
            return String(int64)
        }
        if let double = value as? Double {
            if double.rounded() == double {
                return String(Int(double))
            }
            return String(double)
        }
        if let bool = value as? Bool {
            return bool ? "true" : "false"
        }
        return nil
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        guard let value else {
            return nil
        }
        if let bool = value as? Bool {
            return bool
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let string = value as? String {
            switch string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
            case "Y", "YES", "TRUE", "1":
                return true
            case "N", "NO", "FALSE", "0":
                return false
            default:
                return nil
            }
        }
        return nil
    }

    private static func normalizedJSONData(from data: Data) -> Data {
        guard let string = String(data: data, encoding: .utf8) else {
            return data
        }
        let normalized = string.replacingOccurrences(of: "\u{00A0}", with: " ")
        return normalized.data(using: .utf8) ?? data
    }
}
