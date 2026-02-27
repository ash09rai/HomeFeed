import Foundation

public struct HomeFeedValidationResult {
    public var validSections: [SectionMeta]
    public var skippedSections: [(SectionMeta, SectionSkipReason)]
    public var partiallySupportedSections: [(SectionMeta, [ContentType])]

    public init(
        validSections: [SectionMeta],
        skippedSections: [(SectionMeta, SectionSkipReason)],
        partiallySupportedSections: [(SectionMeta, [ContentType])]
    ) {
        self.validSections = validSections
        self.skippedSections = skippedSections
        self.partiallySupportedSections = partiallySupportedSections
    }

}

public struct HomeFeedCapabilityValidator {
    public init() {}

    public func validate(
        config: HomeConfig,
        capabilities: HomeFeedCapabilities
    ) throws -> HomeFeedValidationResult {
        var validSections: [SectionMeta] = []
        var skippedSections: [(SectionMeta, SectionSkipReason)] = []
        var partialSections: [(SectionMeta, [ContentType])] = []

        for section in config.sections {
            if !section.unknownParameters.isEmpty {
                throw ConfigurationValidationError.unknownParameters(section.unknownParameters.sorted())
            }

            let unsupportedParameters = section.declaredParameters.subtracting(capabilities.supportedSectionParameters)
            if !unsupportedParameters.isEmpty {
                throw ConfigurationValidationError.unsupportedParameters(unsupportedParameters.sorted())
            }

            if !section.showSection {
                skippedSections.append((section, .hiddenByConfiguration))
                continue
            }

            if (section.endpoint ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                skippedSections.append((section, .invalidEndpoint))
                continue
            }

            if section.containers.contains(where: { !capabilities.supportedLayouts.contains($0.layout) }) {
                skippedSections.append((section, .unsupportedLayout))
                continue
            }

            if section.containers.contains(where: { !capabilities.supportedCardTypes.contains($0.cardType) }) {
                skippedSections.append((section, .unsupportedCardType))
                continue
            }

            if section.containers.contains(where: { !capabilities.supportedScrollDirections.contains($0.scrollDirection) }) {
                skippedSections.append((section, .unsupportedScrollDirection))
                continue
            }

            if !section.supportedContents.isEmpty {
                let supported = section.supportedContents.filter { capabilities.supportedContentTypes.contains($0) }
                if supported.isEmpty {
                    skippedSections.append((section, .unsupportedContentType))
                    continue
                }

                if supported.count < section.supportedContents.count {
                    let unsupported = section.supportedContents.filter { !capabilities.supportedContentTypes.contains($0) }
                    partialSections.append((section, unsupported))
                }
            }

            validSections.append(section)
        }

        validSections.sort {
            if $0.rank == $1.rank {
                return $0.originalOrder < $1.originalOrder
            }
            return $0.rank < $1.rank
        }

        return HomeFeedValidationResult(
            validSections: validSections,
            skippedSections: skippedSections,
            partiallySupportedSections: partialSections
        )
    }
}
