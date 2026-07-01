import AVFoundation
import Vision

enum IntruderDirection {
    case left, right, center
}

struct DetectionResult {
    let totalCount: Int
    let intruderDirection: IntruderDirection?
}

final class PersonDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onDetection: ((DetectionResult) -> Void)?

    private let session = AVCaptureSession()
    private let videoQueue = DispatchQueue(label: "com.sidemirror.videoQueue")
    private var lastProcessedAt: Date = .distantPast
    private let processInterval: TimeInterval = 1.0 / 10  // 10fps 상당으로 Vision 처리 제한

    func start() {
        videoQueue.async { [weak self] in
            guard let self else { return }
            if self.session.inputs.isEmpty {
                self.configureSession()
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        videoQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: videoQueue)
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedAt) >= processInterval else { return }
        lastProcessedAt = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let faceRequest = VNDetectFaceRectanglesRequest()
        let bodyRequest = VNDetectHumanRectanglesRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([faceRequest, bodyRequest])

        let faces = faceRequest.results ?? []
        let bodies = bodyRequest.results ?? []
        let result = Self.analyze(faces: faces, bodies: bodies)
        let dir = result.intruderDirection.map { "\($0)" } ?? "없음"
        print("[\(timestamp())] 감지: 총 \(result.totalCount)명, 침입자 방향: \(dir)")
        onDetection?(result)
    }

    // A person can be reported as a face, a body, or both (face + torso for the
    // same person) — merge them by matching each face to the body it sits above
    // so one person isn't double-counted, while a body with no matching face
    // (side/back view) still counts as an intruder.
    private static func mergedBoxes(faces: [VNFaceObservation], bodies: [VNHumanObservation]) -> [CGRect] {
        var unmatchedBodies = bodies.map(\.boundingBox)
        var boxes: [CGRect] = []

        for face in faces {
            let faceCenterX = face.boundingBox.midX
            if let index = unmatchedBodies.firstIndex(where: { $0.minX...$0.maxX ~= faceCenterX }) {
                boxes.append(unmatchedBodies.remove(at: index))
            } else {
                boxes.append(face.boundingBox)
            }
        }

        boxes.append(contentsOf: unmatchedBodies)
        return boxes
    }

    private static func analyze(faces: [VNFaceObservation], bodies: [VNHumanObservation]) -> DetectionResult {
        let people = mergedBoxes(faces: faces, bodies: bodies)

        guard let userIndex = people.indices.max(by: { people[$0].area < people[$1].area }) else {
            return DetectionResult(totalCount: 0, intruderDirection: nil)
        }
        let intruders = people.enumerated().filter { $0.offset != userIndex }.map(\.element)
        guard !intruders.isEmpty else {
            return DetectionResult(totalCount: people.count, intruderDirection: nil)
        }

        let avgX = intruders.map(\.midX).reduce(0, +) / CGFloat(intruders.count)
        let direction: IntruderDirection
        if avgX < 0.4 {
            direction = .left
        } else if avgX > 0.6 {
            direction = .right
        } else {
            direction = .center
        }
        return DetectionResult(totalCount: people.count, intruderDirection: direction)
    }
}

private func timestamp() -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss.SSS"
    return f.string(from: Date())
}

private extension CGRect {
    var area: CGFloat { width * height }
}
