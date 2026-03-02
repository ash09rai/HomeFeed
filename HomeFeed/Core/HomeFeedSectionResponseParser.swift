import Foundation

public enum HomeFeedSectionResponseParser {
    public static func parse(data: Data) throws -> [String: SectionData] {
        let raw = try JSONSerialization.jsonObject(with: normalizedJSONData(from: data))

        if let dict = raw as? [String: [[String: Any]]] {
            var output: [String: SectionData] = [:]
            for (sectionType, items) in dict {
                output[sectionType] = SectionData(items: parseItems(from: items))
            }
            return output
        }

        if let dict = raw as? [String: Any] {
            if let resolved = parseSectionDictionary(dict) {
                return resolved
            }
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

    private static func parseSectionDictionary(_ dictionary: [String: Any]) -> [String: SectionData]? {
        if let items = firstItemArray(in: dictionary) {
            return ["default": SectionData(items: parseItems(from: items))]
        }

        let keyedSections = dictionary.compactMapValues { value -> SectionData? in
            guard let items = firstItemArray(in: value) else {
                return nil
            }
            return SectionData(items: parseItems(from: items))
        }

        return keyedSections.isEmpty ? nil : keyedSections
    }

    private static func firstItemArray(in value: Any?) -> [[String: Any]]? {
        guard let value else {
            return nil
        }

        if let items = value as? [[String: Any]], containsRenderableItems(items) {
            return items
        }

        if let dictionaries = value as? [[String: Any]] {
            for entry in dictionaries {
                if let items = firstItemArray(in: entry) {
                    return items
                }
            }
        }

        if let arrays = value as? [Any] {
            for entry in arrays {
                if let items = firstItemArray(in: entry) {
                    return items
                }
            }
        }

        if let dictionary = value as? [String: Any] {
            let preferredKeys = [
                "data",
                "items",
                "results",
                "content",
                "contents",
                "cards",
                "records",
                "resources",
                "response"
            ]

            for key in preferredKeys {
                if let items = firstItemArray(in: dictionary[key]) {
                    return items
                }
            }

            for nested in dictionary.values {
                if let items = firstItemArray(in: nested) {
                    return items
                }
            }
        }

        return nil
    }

    private static func containsRenderableItems(_ items: [[String: Any]]) -> Bool {
        items.contains(where: looksLikeRenderableItem)
    }

    private static func looksLikeRenderableItem(_ item: [String: Any]) -> Bool {
        guard nonEmpty(stringValue(item["title"])) != nil else {
            return false
        }

        return resolvedContentType(for: item) != nil
            || item["resId"] != nil
            || item["contentId"] != nil
            || item["webinarId"] != nil
            || item["inquiryRefNum"] != nil
            || item["eventURL"] != nil
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
                stringValue(item["docCode"]),
                stringValue(item["id"])
            ])
        case .onDemandWebinar:
            return firstNonEmptyString([
                stringValue(item["contentId"]),
                linkedDocumentIdentifier(from: item),
                stringValue(item["webinarId"]),
                stringValue(item["resId"]),
                stringValue(item["id"])
            ])
        case .upcomingWebinar:
            return firstNonEmptyString([
                linkedDocumentIdentifier(from: item),
                stringValue(item["contentId"]),
                stringValue(item["webinarId"]),
                stringValue(item["resId"]),
                stringValue(item["id"])
            ])
        case .video, .podcast:
            return firstNonEmptyString([
                stringValue(item["contentId"]),
                linkedDocumentIdentifier(from: item),
                stringValue(item["assetId"]),
                stringValue(item["resId"]),
                stringValue(item["id"])
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
                imageURLs: imageURLs.isEmpty ? nil : imageURLs,
                showImage: imageURL == nil ? nil : true,
                multipleImageSupport: imageURLs.count > 1 ? true : nil
            )
        )

        switch contentType {
        case .document:
            behaviour.schedule = FeedItemSchedule(
                publishedDate: stringValue(item["pubDate"])
            )
        case .onDemandWebinar:
            behaviour.schedule = FeedItemSchedule(
                publishedDate: stringValue(item["pubDate"])
            )
            behaviour.statusText = firstNonEmptyString([
                stringValue(item["webinarStatus"]),
                stringValue(item["status"])
            ])
            behaviour.primaryAction = FeedItemAction(title: "Watch Replay")
        case .upcomingWebinar:
            let isRegistered = boolValue(item["userRegistered"])
            behaviour.schedule = FeedItemSchedule(
                eventDate: stringValue(item["eventDate"]),
                eventStartDate: stringValue(item["eventDate"]),
                eventTime: stringValue(item["eventTime"]),
                eventLocation: stringValue(item["isVirtual"]).flatMap { $0 == "true" ? "Virtual Event" : nil }
            )
            behaviour.statusText = firstNonEmptyString([
                stringValue(item["webinarStatus"]),
                stringValue(item["status"])
            ])
            behaviour.isRegistered = isRegistered
            behaviour.primaryAction = FeedItemAction(title: isRegistered == true ? "Registered" : "Register")
        case .video:
            behaviour.schedule = FeedItemSchedule(
                publishedDate: firstNonEmptyString([
                    stringValue(item["pubDate"]),
                    linkedDocumentDate(from: item)
                ])
            )
            behaviour.primaryAction = FeedItemAction(title: "Watch")
        case .podcast:
            behaviour.schedule = FeedItemSchedule(
                publishedDate: stringValue(item["pubDate"])
            )
            behaviour.primaryAction = FeedItemAction(title: "Listen")
        case .inquiry:
            let timing = inquiryTiming(from: item)
            let statusText = normalizedStatus(from: item["inquiryStatus"])
            behaviour.schedule = FeedItemSchedule(
                eventDate: timing.date,
                eventStartDate: timing.date,
                eventTime: timing.time,
                eventLocation: firstNonEmptyString([
                    stringValue(item["type"]),
                    stringValue(item["feature"])
                ]),
                displayTimeZone: stringValue(item["displayTimeZone"])
            )
            behaviour.statusText = statusText
            behaviour.isRegistered = statusText != nil
            behaviour.primaryAction = FeedItemAction(title: "Scheduled")
            behaviour.secondaryAction = FeedItemAction(title: "Edit Inquiry")
        case .conference:
            let statusText = firstNonEmptyString([
                stringValue(item["bannerTitle"]),
                "Registered"
            ])
            behaviour.schedule = FeedItemSchedule(
                eventStartDate: normalizedDateString(from: item["dateStart"]),
                eventEndDate: normalizedDateString(from: item["dateEnd"]),
                eventTime: stringValue(item["eventTime"]),
                eventLocation: stringValue(item["city"])
            )
            behaviour.statusText = statusText
            behaviour.isRegistered = true
            behaviour.primaryAction = ctaAction(from: item["primaryCTA"])
            behaviour.secondaryAction = ctaAction(from: item["secondaryCTA"])
        default:
            break
        }

        return behaviour
    }

    private static func linkedDocumentIdentifier(from item: [String: Any]) -> String? {
        guard let linked = item["linkedDocCodes"] as? [[String: Any]] else {
            return nil
        }
        for entry in linked {
            if let value = firstNonEmptyString([
                stringValue(entry["resId"]),
                stringValue(entry["docCode"])
            ]) {
                return value
            }
        }
        return nil
    }

    private static func linkedDocumentDate(from item: [String: Any]) -> String? {
        guard let linked = item["linkedDocCodes"] as? [[String: Any]] else {
            return nil
        }
        for entry in linked {
            if let value = stringValue(entry["pubDate"]) {
                return value
            }
        }
        return nil
    }

    private static func imageAssetURLs(from item: [String: Any]) -> [String] {
        var urls: [String] = []

        if let direct = stringValue(item["image"]) {
            urls.append(direct)
        }

        if let assets = item["assets"] as? [[String: Any]] {
            for asset in assets {
                guard let url = stringValue(asset["url"]) else {
                    continue
                }

                if let type = stringValue(asset["type"])?.lowercased(),
                   type == "thumbnail" || type == "image" {
                    urls.append(url)
                }
            }
        }

        return Array(NSOrderedSet(array: urls)) as? [String] ?? urls
    }

    private static func inquiryTiming(from item: [String: Any]) -> (date: String?, time: String?) {
        guard let epochValue = doubleValue(item["startDateEpoc"]) else {
            return (
                date: stringValue(item["clientActionDate"]),
                time: firstNonEmptyString([
                    stringValue(item["clientActionTime"]),
                    stringValue(item["submittedDateTime"])
                ])
            )
        }

        let date = Date(timeIntervalSince1970: epochValue / 1000)
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd MMMM yyyy"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "h:mm a"

        let timeZone = stringValue(item["displayTimeZone"])
        let timeSuffix = timeZone.map { " \($0)" } ?? ""

        return (
            date: dateFormatter.string(from: date),
            time: timeFormatter.string(from: date) + timeSuffix
        )
    }

    private static func normalizedStatus(from rawValue: Any?) -> String? {
        guard let value = stringValue(rawValue)?.lowercased() else {
            return nil
        }

        let words = value
            .split(separator: "_")
            .map { token in
                token.prefix(1).uppercased() + token.dropFirst().lowercased()
            }

        return words.joined(separator: " ")
    }

    private static func normalizedDateString(from rawValue: Any?) -> String? {
        guard let raw = nonEmpty(stringValue(rawValue)) else {
            return nil
        }

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMMM yyyy"

        guard let date = parser.date(from: raw) else {
            return raw
        }
        return formatter.string(from: date)
    }

    private static func ctaAction(from rawValue: Any?) -> FeedItemAction? {
        guard let dictionary = rawValue as? [String: Any],
              let title = nonEmpty(stringValue(dictionary["title"])) else {
            return nil
        }

        return FeedItemAction(title: title, url: stringValue(dictionary["url"]))
    }

    private static func inferredWebinarType(for item: [String: Any]) -> ContentType? {
        let status = firstNonEmptyString([
            stringValue(item["webinarStatus"]),
            stringValue(item["wbnrStatus"])
        ])?.lowercased()

        if status?.contains("upcoming") == true {
            return .upcomingWebinar
        }
        if status?.contains("on demand") == true || status?.contains("ondemand") == true {
            return .onDemandWebinar
        }

        if item["eventDate"] != nil || item["eventTime"] != nil || boolValue(item["showRegisterOption"]) == true {
            return .upcomingWebinar
        }

        if item["playbackURL"] != nil || boolValue(item["showReplayOption"]) == true || item["watchedTime"] != nil {
            return .onDemandWebinar
        }

        return nil
    }

    private static func isInquiry(_ item: [String: Any]) -> Bool {
        item["inquiryRefNum"] != nil || stringValue(item["inquiryStatus"]) != nil
    }

    private static func isConference(_ item: [String: Any]) -> Bool {
        if let type = stringValue(item["type"])?.lowercased(), type == "conference" {
            return true
        }
        return item["eventURL"] != nil && item["city"] != nil
    }

    private static func normalizedJSONData(from data: Data) -> Data {
        guard var string = String(data: data, encoding: .utf8) else {
            return data
        }

        string = string.replacingOccurrences(of: "\u{00A0}", with: " ")
        return Data(string.utf8)
    }

    private static func stringValue(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return nonEmpty(string)
        case let number as NSNumber:
            return number.stringValue
        case let integer as Int:
            return String(integer)
        case let double as Double:
            return String(double)
        default:
            return nil
        }
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        switch value {
        case let bool as Bool:
            return bool
        case let string as String:
            let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if ["true", "y", "yes", "1"].contains(normalized) {
                return true
            }
            if ["false", "n", "no", "0"].contains(normalized) {
                return false
            }
            return nil
        case let number as NSNumber:
            return number.boolValue
        default:
            return nil
        }
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        switch value {
        case let double as Double:
            return double
        case let integer as Int:
            return Double(integer)
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            return nil
        }
    }

    private static func firstNonEmptyString(_ values: [String?]) -> String? {
        values.first(where: { nonEmpty($0) != nil }) ?? nil
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}
