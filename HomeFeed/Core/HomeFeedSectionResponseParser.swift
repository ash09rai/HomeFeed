import Foundation

public enum HomeFeedSectionResponseParser {
    public static func parse(data: Data) throws -> [String: SectionData] {
        try MockSectionDataParser.parse(data: data)
    }
}
