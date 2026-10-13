//
//  MockEvidenceImageSource.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import SwiftUI
import UIKit

private struct MockEvidenceImagesEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var mockEvidenceImagesEnabled: Bool {
        get {
            self[MockEvidenceImagesEnabledKey.self]
        }
        set {
            self[MockEvidenceImagesEnabledKey.self] = newValue
        }
    }
}

@MainActor
enum MockEvidenceImageSource {
    static func image(
        from path: String?,
        enabled: Bool
    ) -> UIImage? {
        #if DEBUG
        let prefix = "mock-evidence:jpeg;base64,"
        let maximumBytes = 5 * 1024 * 1024
        let maximumEncodedLength = ((maximumBytes + 2) / 3) * 4

        guard enabled,
              let path,
              path.hasPrefix(prefix),
              path.utf8.count <= prefix.utf8.count + maximumEncodedLength
        else {
            return nil
        }

        let encoded = String(path.dropFirst(prefix.count))

        guard let data = Data(base64Encoded: encoded),
              data.count <= maximumBytes,
              data.starts(with: [0xFF, 0xD8, 0xFF]),
              let image = UIImage(data: data) else {
            return nil
        }

        let width = image.size.width * image.scale
        let height = image.size.height * image.scale

        guard width.isFinite,
              height.isFinite,
              width > 0,
              height > 0,
              width <= 2048,
              height <= 2048 else {
            return nil
        }

        return image
        #else
        return nil
        #endif
    }
}
