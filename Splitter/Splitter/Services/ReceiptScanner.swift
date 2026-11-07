import UIKit
import Vision

/// Reads a receipt photo on the device with Apple's Vision text recognition. Nothing is uploaded.
enum ReceiptScanner {
    enum ScanError: LocalizedError {
        case unreadableImage
        var errorDescription: String? { "That image couldn't be read." }
    }

    static func scan(_ image: UIImage) async throws -> ScannedReceipt {
        guard let cgImage = image.cgImage else { throw ScanError.unreadableImage }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        let boxes: [TextBox] = try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: observations.compactMap { observation in
                    observation.topCandidates(1).first.map { TextBox(text: $0.string, rect: observation.boundingBox) }
                })
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false // keeps prices like "18.00" intact

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        return ReceiptParser.parse(lines: ReceiptParser.rows(from: boxes))
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
