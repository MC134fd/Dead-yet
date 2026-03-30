import SwiftUI

enum DeadYetFonts {
    static func hero(size: CGFloat) -> Font {
        .custom("SpaceGrotesk-Bold", size: size, relativeTo: .largeTitle)
    }

    static func body(size: CGFloat) -> Font {
        .custom("Inter-Regular", size: size, relativeTo: .body)
    }

    static func bodyMedium(size: CGFloat) -> Font {
        .custom("Inter-Medium", size: size, relativeTo: .body)
    }

    static func countdown(size: CGFloat) -> Font {
        .custom("SpaceGrotesk-Bold", size: size, relativeTo: .largeTitle)
            .monospacedDigit()
    }
}
