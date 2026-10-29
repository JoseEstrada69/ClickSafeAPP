//
//  Theme.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 05/10/26.
//

import SwiftUI

extension Color {
    static let csBackground = Color("csBackground")
    static let csSurface = Color("csSurface")
    static let csBorder = Color("csBorder")
    static let csNavy = Color("csNavy")
    static let csOnNavy = Color("csOnNavy")
    static let csNavBar = Color("csNavBar")
    static let csBlue = Color("csBlue")
    static let csGold = Color("csGold")
    static let csTextPrimary = Color("csTextPrimary")
    static let csTextSecondary = Color("csTextSecondary")
    static let csPlaceholderImage = Color("csPlaceholderImage")
    static let csPendingBg = Color("csPendingBg")
    static let csPendingFg = Color("csPendingFg")
    static let csValidatedBg = Color("csValidatedBg")
    static let csValidatedFg = Color("csValidatedFg")
    static let csRejectedBg = Color("csRejectedBg")
    static let csRejectedFg = Color("csRejectedFg")
    static let csDanger = Color("csDanger")
    static let csSuccess = Color("csSuccess")
}

enum Theme {
    enum Spacing {
        static let screenMargin: CGFloat = 20
        static let betweenBlocks: CGFloat = 16
        static let withinCard: CGFloat = 12
        static let cardPadding: CGFloat = 16
    }

    enum CornerRadius {
        static let button: CGFloat = 12
        static let field: CGFloat = 12
        static let card: CGFloat = 14
        static let thumbnail: CGFloat = 10
    }

    enum Size {
        static let minimumButtonHeight: CGFloat = 50
        static let minimumTouchTarget: CGFloat = 44
        static let evidenceThumbnail: CGFloat = 96
    }

    enum BorderWidth {
        static let standard: CGFloat = 1
        static let focused: CGFloat = 1.5
    }

    static let disabledOpacity: Double = 0.4
}
