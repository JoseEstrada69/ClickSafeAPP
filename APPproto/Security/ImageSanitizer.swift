//
//  ImageSanitizer.swift
//  APPproto
//
//  Created by Uriel Suarez Lopez on 08/10/26.
//

import Foundation
import UIKit

@MainActor
enum ImageSanitizer {
    private static let maximumDimension: CGFloat = 2048
    private static let maximumBytes = 5 * 1024 * 1024

    static func sanitize(_ data: Data) throws -> Data {
        try Task.checkCancellation()

        guard let image = UIImage(data: data),
              image.size.width > 0,
              image.size.height > 0 else {
            throw ImageSanitizationError.invalidImage
        }

        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale

        guard pixelWidth.isFinite,
              pixelHeight.isFinite else {
            throw ImageSanitizationError.invalidImage
        }

        let resizeFactor = min(
            1,
            maximumDimension / max(pixelWidth, pixelHeight)
        )

        let outputSize = CGSize(
            width: max(1, floor(pixelWidth * resizeFactor)),
            height: max(1, floor(pixelHeight * resizeFactor))
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(
            size: outputSize,
            format: format
        )

        let sanitizedImage = renderer.image { context in
            let bounds = CGRect(
                origin: .zero,
                size: outputSize
            )

            context.cgContext.setFillColor(
                UIColor.white.cgColor
            )
            context.cgContext.fill(bounds)

            image.draw(in: bounds)
        }

        try Task.checkCancellation()

        guard let jpeg = sanitizedImage.jpegData(
            compressionQuality: 0.8
        ) else {
            throw ImageSanitizationError.invalidImage
        }

        if jpeg.count <= maximumBytes {
            return jpeg
        }

        guard let smallerJPEG = sanitizedImage.jpegData(
            compressionQuality: 0.6
        ) else {
            throw ImageSanitizationError.invalidImage
        }

        try Task.checkCancellation()

        guard smallerJPEG.count <= maximumBytes else {
            throw ImageSanitizationError.imageTooLarge
        }

        return smallerJPEG
    }
}

nonisolated enum ImageSanitizationError: LocalizedError {
    case invalidImage
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "La imagen no es válida. Selecciona otra fotografía."

        case .imageTooLarge:
            return "La imagen supera los 5 MB después de procesarla. Selecciona otra fotografía."
        }
    }
}
