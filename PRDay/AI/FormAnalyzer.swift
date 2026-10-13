import Foundation
import Vision
import AVFoundation
import CoreGraphics
import UIKit

struct PoseFeatures: Equatable {
    let time: Double
    let kneeAngleDeg: Double
    let trunkLeanDeg: Double
    let hipDropDeg: Double
}

final class FormAnalyzer {
    func extractFeatures(from url: URL) async throws -> [PoseFeatures] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 640)
        let end = min(duration, 6.0)
        var times: [CMTime] = []
        var t = 0.5
        while t <= end {
            times.append(CMTime(seconds: t, preferredTimescale: 600))
            t += 0.5
        }
        var frames: [PoseFeatures] = []
        for time in times {
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil),
               let features = Self.analyzeFrame(cgImage: cgImage, time: time.seconds) {
                frames.append(features)
            }
        }
        guard !frames.isEmpty else {
            throw AIServiceError(message: "No usable frames found. Film from the side, full body in frame.")
        }
        return frames
    }

    func annotatedFrameJPEGs(from url: URL, count: Int = 3) async throws -> [String] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 512, height: 512)
        let end = min(duration, 6.0)
        let step = max(end / Double(count + 1), 0.4)
        var jpegs: [String] = []
        for i in 1...count {
            let time = CMTime(seconds: step * Double(i), preferredTimescale: 600)
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil),
               let annotated = Self.drawSkeleton(cgImage: cgImage),
               let data = UIImage(cgImage: annotated).jpegData(compressionQuality: 0.6) {
                jpegs.append(data.base64EncodedString())
            }
        }
        return jpegs
    }

    static func analyzeFrame(cgImage: CGImage, time: Double) -> PoseFeatures? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
        guard let pose = request.results?.first else { return nil }
        let points = try? pose.recognizedPoints(.all)
        guard let points else { return nil }

        func point(_ name: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let p = points[name], p.confidence > 0.2 else { return nil }
            return CGPoint(x: p.location.x, y: p.location.y)
        }

        func angle(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
            let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
            let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
            let dot = Double(v1.dx * v2.dx + v1.dy * v2.dy)
            let mag1 = Double(sqrt(v1.dx * v1.dx + v1.dy * v1.dy))
            let mag2 = Double(sqrt(v2.dx * v2.dx + v2.dy * v2.dy))
            guard mag1 > 0, mag2 > 0 else { return 0 }
            return acos(min(max(dot / (mag1 * mag2), -1), 1)) * 180 / Double.pi
        }

        guard
            let hipL = point(.leftHip), let hipR = point(.rightHip),
            let kneeL = point(.leftKnee), let kneeR = point(.rightKnee),
            let ankleL = point(.leftAnkle), let ankleR = point(.rightAnkle),
            let shoulderL = point(.leftShoulder), let shoulderR = point(.rightShoulder),
            let nose = point(.nose)
        else { return nil }

        let hipMid = CGPoint(x: (hipL.x + hipR.x) / 2, y: (hipL.y + hipR.y) / 2)
        let kneeMid = CGPoint(x: (kneeL.x + kneeR.x) / 2, y: (kneeL.y + kneeR.y) / 2)
        let ankleMid = CGPoint(x: (ankleL.x + ankleR.x) / 2, y: (ankleL.y + ankleR.y) / 2)
        let shoulderMid = CGPoint(x: (shoulderL.x + shoulderR.x) / 2, y: (shoulderL.y + shoulderR.y) / 2)

        let kneeAngle = (angle(a: hipL, b: kneeL, c: ankleL) + angle(a: hipR, b: kneeR, c: ankleR)) / 2
        let trunkVector = CGVector(dx: hipMid.x - shoulderMid.x, dy: hipMid.y - shoulderMid.y)
        let vertical = CGVector(dx: 0, dy: -1)
        let dot = Double(trunkVector.dx * vertical.dx + trunkVector.dy * vertical.dy)
        let mag = Double(sqrt(trunkVector.dx * trunkVector.dx + trunkVector.dy * trunkVector.dy))
        let trunkLean = mag > 0 ? acos(min(max(dot / mag, -1), 1)) * 180 / Double.pi : 0
        let hipDrop = abs(hipL.y - hipR.y) * 90

        return PoseFeatures(
            time: time,
            kneeAngleDeg: kneeAngle,
            trunkLeanDeg: trunkLean,
            hipDropDeg: min(hipDrop, 30)
        )
    }

    static func drawSkeleton(cgImage: CGImage) -> CGImage? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
        guard let pose = request.results?.first,
              let points = try? pose.recognizedPoints(.all) else { return cgImage }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        context.setStrokeColor(CGColor(red: 1.0, green: 0.42, blue: 0.17, alpha: 1))
        context.setLineWidth(max(2, Double(width) / 160))

        let joints: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck, .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip, .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]
        var converted: [CGPoint] = []
        for joint in joints {
            if let p = points[joint], p.confidence > 0.2 {
                let point = CGPoint(x: p.location.x * CGFloat(width), y: p.location.y * CGFloat(height))
                converted.append(point)
                context.fillEllipse(in: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
            }
        }
        context.beginPath()
        for (i, p) in converted.enumerated() {
            if i == 0 { context.move(to: p) } else { context.addLine(to: p) }
        }
        context.strokePath()

        return context.makeImage()
    }

    static func summarize(frames: [PoseFeatures]) -> PoseFeatures {
        let n = Double(frames.count)
        let avgKnee = frames.map { $0.kneeAngleDeg }.reduce(0, +) / n
        let avgTrunk = frames.map { $0.trunkLeanDeg }.reduce(0, +) / n
        let avgHip = frames.map { $0.hipDropDeg }.reduce(0, +) / n
        return PoseFeatures(time: 0, kneeAngleDeg: avgKnee, trunkLeanDeg: avgTrunk, hipDropDeg: avgHip)
    }
}
