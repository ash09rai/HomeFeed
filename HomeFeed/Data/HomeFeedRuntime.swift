import Foundation

public protocol HomeFeedRuntime {
    var isSwiftDataSupported: Bool { get }
}

public struct LiveHomeFeedRuntime: HomeFeedRuntime {
    public init() {}

    public var isSwiftDataSupported: Bool {
        if #available(iOS 17.0, *) {
            return true
        }
        return false
    }
}
