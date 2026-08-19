import Foundation

extension Date {
    /// Texto relativo e amigável para exibir na UI (ex.: "agora", "há 5 min", "há 2 h").
    var relativeShort: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
