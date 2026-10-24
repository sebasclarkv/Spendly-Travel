import Foundation

enum L10n {
    @inline(__always)
    static func text(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
        guard !args.isEmpty else {
            return String(localized: key)
        }

        return String(format: String(localized: key), locale: .current, arguments: args)
    }
}
