import Foundation

public enum PingoBrand {
    public static let name = "Pingo"
    public static let tagline = "Play right here."
    public static let launchGameCount = 10

    /// Brand colors as sRGB hex values so non-UI layers can refer to the same palette.
    public enum Hex {
        public static let ink = "19172B"
        public static let primary = "6657E8"
        public static let secondary = "28C7B7"
        public static let surface = "F7F6FF"
        public static let highlight = "FFCC66"
    }
}
