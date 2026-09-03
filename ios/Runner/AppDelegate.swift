import Flutter
import ImageIO
import PDFKit
import UIKit
import UserNotifications
import Vision
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MedLicenseCertificateOcr") {
      CertificateOcrPlugin.register(with: registrar)
    }
  }
}

private final class CertificateOcrPlugin: NSObject, FlutterPlugin {
  private static let channelName = "jp.sachikosaga.medlicense/ocr"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(CertificateOcrPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "recognize" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String,
      !path.isEmpty
    else {
      result(FlutterError(code: "invalid_path", message: "読み取り対象のファイルがありません。", details: nil))
      return
    }
    let contentType = arguments["contentType"] as? String ?? ""
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let images = try self.loadImages(
          path: path,
          isPDF: contentType.localizedCaseInsensitiveContains("pdf") || path.lowercased().hasSuffix(".pdf")
        )
        var pageTexts: [String] = []
        var blockCount = 0
        for image in images {
          let recognized = try self.recognize(image: image)
          pageTexts.append(recognized.text)
          blockCount += recognized.blockCount
        }
        DispatchQueue.main.async {
          result([
            "text": pageTexts.joined(separator: "\n\n"),
            "engine": images.count > 1 ? "apple-vision-pdf" : "apple-vision",
            "blockCount": blockCount,
          ])
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "ocr_failed",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    }
  }

  private func loadImages(path: String, isPDF: Bool) throws -> [UIImage] {
    if !isPDF {
      guard let image = UIImage(contentsOfFile: path) else {
        throw OcrError.fileUnreadable
      }
      return [image]
    }
    guard let document = PDFDocument(url: URL(fileURLWithPath: path)) else {
      throw OcrError.fileUnreadable
    }
    return try (0..<min(document.pageCount, 5)).map { index in
      guard let page = document.page(at: index) else { throw OcrError.fileUnreadable }
      let bounds = page.bounds(for: .mediaBox)
      let scale = min(2.0, 2200.0 / max(bounds.width, 1))
      return page.thumbnail(
        of: CGSize(width: bounds.width * scale, height: bounds.height * scale),
        for: .mediaBox
      )
    }
  }

  private func recognize(image: UIImage) throws -> (text: String, blockCount: Int) {
    guard let cgImage = image.cgImage else { throw OcrError.fileUnreadable }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["ja-JP", "en-US"]
    let handler = VNImageRequestHandler(
      cgImage: cgImage,
      orientation: CGImagePropertyOrientation(image.imageOrientation),
      options: [:]
    )
    try handler.perform([request])
    let observations = (request.results ?? []).sorted {
      if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.015 {
        return $0.boundingBox.midY > $1.boundingBox.midY
      }
      return $0.boundingBox.minX < $1.boundingBox.minX
    }
    let lines = observations.compactMap { $0.topCandidates(1).first?.string }
    return (lines.joined(separator: "\n"), observations.count)
  }
}

private enum OcrError: LocalizedError {
  case fileUnreadable

  var errorDescription: String? {
    switch self {
    case .fileUnreadable: return "参加証の画像またはPDFを開けませんでした。"
    }
  }
}

private extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
