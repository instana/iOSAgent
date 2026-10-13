//
//  Copyright © 2026 IBM Corp. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import AVKit
import PDFKit
import SwiftUI
//import CryptoKit
import Accelerate   //pHash
import SDWebImageWebPCoder  //save image into webp format
@_spi(Internal) import InstanaAgent

@available(iOS 13.0, *)
internal class ScreenCapture: NSObject {
    static let IdleLeewayMs = 3000.0  // 3 seconds
    weak var sessionReplay: InstanaSessionReplay?
    let config: InstanaSessionReplayConfig
    weak let stagingManager: StagingManager?
    var timer: Timer?

    let imageQueue = DispatchQueue(label: "com.instana.ios.agent.sessionreplay.image", qos: .utility)

    lazy var useFastDrawing: Bool = {
        if config.useFastScreenCapture != nil {
            return config.useFastScreenCapture!.boolValue
        }
//        if !isSwiftUIOnScreenNow() { return true }
        return false
    }()

    var windowProvider: ActiveWindowProvider

    var screenshotCache: TrackedNSCache //pHash
    var lastHash: UInt64?


    init(config: InstanaSessionReplayConfig, stagingManager: StagingManager, windowProvider: ActiveWindowProvider? = nil) {
        self.config = config
        self.stagingManager = stagingManager
        self.windowProvider = windowProvider ?? AppWindowProvider()
        screenshotCache = TrackedNSCache()
        super.init()
    }

    func startCapture() {
        if Thread.isMainThread {
            startCaptureInMainThread()
        } else {
            // Force it onto the main thread
            DispatchQueue.main.async {
                self.startCaptureInMainThread()
            }
        }
    }

    func stopCapture() {
        if Thread.isMainThread {
            stopCaptureInMainThread()
        } else {
            // Force it onto the main thread
            DispatchQueue.main.async {
                self.stopCaptureInMainThread()
            }
        }
    }

    private func stopCaptureInMainThread() {
        self.timer?.invalidate()
        self.timer = nil
    }

    func onLowMemory() {
        imageQueue.async { [weak self] in
            self?.screenshotCache.removeAll()
            self?.lastHash = nil
        }
    }

    private func startCaptureInMainThread() {
        if windowProvider.activeKeyWindow != nil {
            startTimer()
        } else {
            // wait till scene available to start the screen capture
            NotificationCenter.default.addObserver(self, selector: #selector(newSceneActivate),
                                                   name: UIScene.didActivateNotification, object: nil)
        }
    }

    @objc private func newSceneActivate() {
        Instana.log("Session replay: UIScene available, start creenCapture timer", level: .debug)
        NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
        startTimer()
    }

    @objc func takeSnapshot() {
        guard let replay = sessionReplay else { return }
        guard let window = windowProvider.activeKeyWindow else {
            Instana.log("Session replay: No window to take screenshot", level: .warning)
            return
        }

        let currentTime = Date().millisecondsSince1970
        let lastTime = replay.userEvent.lastTouchTime
        if currentTime - lastTime < Instana.Types.Milliseconds(config.getScreenshotsCaptureIntervalInSeconds() * 1000.0 + ScreenCapture.IdleLeewayMs) {
            // If no user activity over 3 seconds, do not capture screen
            takeSnapshotForWindow(window)
        }
    }

    func takeSnapshotForWindow(_ window: UIWindow) {
//        let avPlayerViewController = window.findAVPlayerViewController()
//        if avPlayerViewController != nil {
//            print("hjtest found AVPlayerViewController \(avPlayerViewController!)")
//        }

        let timestamp = Date().millisecondsSince1970
        let screenshotImage = captureScreenImage(window: window)

        let rectsToMask = getMaskableRects(window)
//        print("hjtest number of rects to mask: \(rectsToMask.count)")
        let maskedScreenshotImage = maskImage(screenshotImage, rects: rectsToMask)

        imageQueue.async { [weak self] in
            self?.stageScreenshot(timestamp: timestamp, image: maskedScreenshotImage)
        }
    }

    private func startTimer() {
        guard timer == nil else { return }

        let interval = config.getScreenshotsCaptureIntervalInSeconds()
        self.timer = Timer.scheduledTimer(timeInterval: interval, target: self,
                                          selector: #selector(self.takeSnapshot),
                                          userInfo: nil, repeats: true)
        self.timer?.tolerance = interval * 0.1
        self.timer?.fire()
    }

    private func captureScreenImage(window: UIWindow) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds, format: format)
        let image = renderer.image { context in
            if useFastDrawing {
                window.layer.render(in: context.cgContext)
            } else {
                // for better SwiftUI compatibility
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
        }
//        print("hjtest captured screenshot at \(Date().description(with: nil))")
        return image
    }

    private func maskImage(_ image: UIImage, rects: [CGRect], scale: CGFloat = 0) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale > 0 ? scale : image.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            image.draw(at: .zero)
            config.maskingColor.setFill()
            //hjtest, remove following line but use above line!!!
//            context.cgContext.setFillColor(config.maskingColor.withAlphaComponent(0.6).cgColor)
            for rect in rects {
//                print("hjtest masked UIView with rect: \(rect)")
                context.cgContext.fill(rect)
                //hjtest, draw a rectangle frame
//                let cgCtx = context.cgContext
//                cgCtx.setStrokeColor(UIColor.purple.cgColor)
//                cgCtx.stroke(rect)
            }
        }
    }

    private func isVisible(_ view: UIView) -> Bool {
        guard !view.isHidden, view.alpha > 0, view.bounds.width > 0, view.bounds.height > 0 else {
            return false
        }
        return true
    }

    private func containVisibleInfo(_ view: UIView) -> Bool {
        // No sensitive information could be seen from the view
        switch view {
        case let textField as UITextField:
            if textField.text?.isEmpty ?? true {
                return false
            }
        case let textView as UITextView:
            if textView.text.isEmpty {
                return false
            }
        case let label as UILabel:
            if label.text?.isEmpty ?? true {
                return false
            }
        case let imageView as UIImageView:
            if imageView.image == nil {
                return false
            }
        default:
            return true
        }
        return true
    }

    private func getMaskableRects(_ window: UIWindow) -> [CGRect] {
        guard config.maskStrategy != .mask_none else {
            return []
        }

        var visibleRects: [CGRect] = []
        var maskedViewsProgress: [UIView]?
        if config.maskStrategy == .mask_sensitive {
            maskedViewsProgress = InstanaSessionReplay.current?.retrieveMaskedUIViews()
        }

        func traverse(_ view: UIView, clippingRect: CGRect?) {
            if maskedViewsProgress != nil && maskedViewsProgress!.count == 0 {
                return // Nothing to mask
            }
            guard isVisible(view) else { return }

            // Convert view's bounds to window coordinates
            let rectInWindow = view.convert(view.bounds, to: window)

            // Determine the effective clipping rectangle
            let effectiveClipRect: CGRect
            if let clippingRect = clippingRect {
                effectiveClipRect = rectInWindow.intersection(clippingRect)
            } else {
                effectiveClipRect = rectInWindow
            }

            var viewIsMasked = false
            // Check if visible on screen
            if !effectiveClipRect.isNull && window.bounds.intersects(effectiveClipRect) {
                if maskedViewsProgress != nil { // mask sensitive
                    if maskedViewsProgress!.contains(view) {
                        visibleRects.append(effectiveClipRect)
                        maskedViewsProgress!.removeAll { $0 == view }
                        viewIsMasked = true
                    }
                } else { //mask all or input fields
                    if shouldMaskView(view) && containVisibleInfo(view) {
                        visibleRects.append(effectiveClipRect)
                        viewIsMasked = true
                    }
                }
            }
            if viewIsMasked && view.clipsToBounds {
                // no need to check subviews
                return
            }

            // If view clips to bounds (like scrollViews), use its bounds as a clip region
            let newClip: CGRect?
            if view.clipsToBounds {
                newClip = view.convert(view.bounds, to: window).intersection(effectiveClipRect)
            } else {
                newClip = clippingRect
            }

            for subview in view.subviews {
                traverse(subview, clippingRect: newClip)
            }
        }

        func shouldMaskView(_ view: UIView) -> Bool {
            // Always mask WebViews, video players, and camera views for security/privacy
            switch config.maskStrategy {
            case .mask_input_fields:
                return view is UITextField || view is UITextView || view is UILabel
                    || view is WKWebView || isAVPlayerView(view)
            case .mask_all:
                // UIButton consists UILabel and UIImageView
                return view is UITextField || view is UITextView || view is UILabel
                    || view is PDFView || view is UIImageView
                    || view is WKWebView || isAVPlayerView(view)
            case .mask_sensitive, .mask_none:
                return false
            }
        }

        func isAVPlayerView(_ view: UIView) -> Bool {
            if let className = String.className(of: view),
               className.contains("AVPlayerView") || className.contains("_AVPlayerView") {
                return true
            }
            return false
        }

//        guard let rootViewController = window.rootViewController else { return visibleRects }
//        traverse(rootViewController.view, clippingRect: nil)
        traverse(window, clippingRect: nil)
        return visibleRects
    }
/*
    /// Returns true if any visible window is rendering SwiftUI content right now.
    private func isSwiftUIOnScreenNow() -> Bool {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows where !window.isHidden && window.alpha > 0 {
                if containsSwiftUI(in: window) { return true }
                if containsSwiftUIViewController(window.rootViewController) { return true }
            }
        }
        return false
    }

    private func containsSwiftUI(in view: UIView) -> Bool {
        let name = NSStringFromClass(type(of: view))
        if name.hasPrefix("SwiftUI.") || name.contains("UIHosting") {
            return true
        }

        for subview in view.subviews {
            if containsSwiftUI(in: subview) {
                return true }
        }
        return false
    }

    private func containsSwiftUIViewController(_ viewController: UIViewController?) -> Bool {
        guard let viewController = viewController else { return false }

        let vcName = NSStringFromClass(type(of: viewController))
        if vcName.contains("UIHostingController") { return true }

        // Check its view tree too
        if viewController.isViewLoaded, containsSwiftUI(in: viewController.view) {
            return true }

        if containsSwiftUIViewController(viewController.presentedViewController) {
            return true }
        for child in viewController.children {
            if containsSwiftUIViewController(child) {
                return true }
        }
        return false
    }
*/
/*
    func getVisibleRects_plain(_ window: UIWindow) -> [CGRect] {
        var visibleRects: [CGRect] = []

        func traverse(_ view: UIView, clippingRect: CGRect?) {
            guard isVisible(view) else { return }

            // Convert view's bounds to window coordinates
            let rectInWindow = view.convert(view.bounds, to: window)

            // Determine the effective clipping rectangle
            let effectiveClipRect: CGRect
            if let clippingRect = clippingRect {
                effectiveClipRect = rectInWindow.intersection(clippingRect)
            } else {
                effectiveClipRect = rectInWindow
            }

            // Check if visible on screen
            if !effectiveClipRect.isNull, window.bounds.intersects(effectiveClipRect) {
                visibleRects.append(effectiveClipRect)
            }

            // If view clips to bounds (like scrollViews), use its bounds as a clip region
            let newClip: CGRect?
            if view.clipsToBounds {
                newClip = view.convert(view.bounds, to: window).intersection(effectiveClipRect)
            } else {
                newClip = clippingRect
            }

            for subview in view.subviews {
                traverse(subview, clippingRect: newClip)
            }
        }

        guard let rootViewController = window.rootViewController else { return visibleRects }
        traverse(rootViewController.view, clippingRect: nil)
        return visibleRects
    }

    func getAllVisibleViews_NotUsed(_ keyWindow: UIWindow) -> [UIView] { //works well though not needed!!!
        var result: [UIView] = []
        guard let rootViewController = keyWindow.rootViewController else { return result }
        collectVisibleUIViews(from: rootViewController.view, into: &result)
        return result
    }

    func collectVisibleUIViews(from view: UIView, into result: inout [UIView]) {
        guard !view.isHidden, view.alpha > 0, view.window != nil else { return }

        // Check if the view is on screen
        let screenBounds = UIScreen.main.bounds
        let frameInWindow = view.convert(view.bounds, to: nil)

        if screenBounds.intersects(frameInWindow) {
            result.append(view)
        }

        for subview in view.subviews {
            collectVisibleUIViews(from: subview, into: &result)
        }
    }
*/
}

@available(iOS 13.0, *)
extension ScreenCapture {
    private func stageScreenshot(timestamp: Instana.Types.Milliseconds, image: UIImage) {
/*
        let imageHash = calculateSHA256Hash(imageData)
        if imageHash == lastHash {
            print("hjtest imageHash not change to lastHash")
            return
        }
        lastHash = imageHash

        let hashDate = screenshotCache.getObject(for: imageHash)
        if hashDate != nil {
            screenshotCache.setObject(Date(), for: imageHash)   // update hash access time
            Instana.log("ImageHash \(imageHash) exists", level: .debug)
        } else {
            screenshotCache.setObject(Date(), for: imageHash)
            imageToSend = imageData
        }
*/

        // perceptual hash
        guard let imageHash = calculatePHash(image) else {  //size: (64, 64)
            Instana.log("Failed to calculate pHash of UIImage", level: .warning)
            return
        }

        // image meta data
        var imageMeta: [String: String] = ["sessionId": Instana.sessionID!,
                       "imageId": pHashToImageId(imageHash),
                       "type":"screenshot", "mobileAppId": Instana.key!,
//                    "scalingRatio": "1:1"
                        ]
        var imageToSend: Data?
        if let similarHash = screenshotCache.findSimilarKey(for: imageHash,
                hammingDistance: config.hammingDistance) {
            screenshotCache.insert(similarHash, value: timestamp)   // update access time
            if similarHash == lastHash {
//                print("hjtest image same as most recent one, do nothing")
                return
            }
            lastHash = similarHash
        } else {
            let (imageData, dataFormat) = imageToData(image)
            screenshotCache.insert(imageHash, value: timestamp)
            imageToSend = imageData
            imageMeta["imageFormat"] = dataFormat
            lastHash = imageHash
        }

        // report or save image
        let imageBeacon = ImageBeacon(image: imageToSend, meta: imageMeta, timestamp: Instana.Types.Milliseconds(timestamp))
        stagingManager?.stageScreenshot(timestamp: timestamp, beacon: imageBeacon)
    }

    private func imageToData(_ image: UIImage) -> (Data?, String) {
        let options: [SDImageCoderOption: Any] = [
                .encodeWebPMethod: 4, // better quality/speed balance
                .encodeCompressionQuality: 0.3, // better reliability
                .encodeWebPAlphaCompression: 100
            ]
        guard let imageData = SDImageWebPCoder.shared.encodedData(with: image, format: .webP, options: options) else {
            Instana.log("Failed to convert UIImage to webp format", level: .warning)
            // Next try to convert the image to jpeg format
            guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                Instana.log("Failed to convert UIImage to jpeg format", level: .warning)
                return (nil, "unknown")
            }
            return (imageData, "jpeg")
        }
        return (imageData, "webp")
    }

//    private func calculateSHA256Hash(_ data: Data) -> String {
//        let digest = SHA256.hash(data: data)
//        let hashString = digest.compactMap { String(format: "%02x", $0) }.joined()
//        return hashString
//    }

    /// Calculates the Perceptual Hash (pHash) of a UIImage.
    /// - Parameters:
    ///   - image: The input image.
    ///   - size: The size to which the image is scaled for DCT (standard is 32).
    ///   - lowFreqSize: The size of the top-left DCT block used for the hash (standard is 8).
    /// - Returns: A 64-bit perceptual hash.
    func calculatePHash(_ image: UIImage, size: Int = 32, lowFreqSize: Int = 8) -> UInt64? {
        guard let cgImage = image.cgImage else { return nil }

        // 1. Resize and Grayscale
        let width = size
        let height = size
        let totalPixels = width * height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else { return nil }

        // Convert UInt8 pixels to Float
        var floatPixels = [Float](repeating: 0, count: totalPixels)
        let uint8Ptr = pixelData.bindMemory(to: UInt8.self, capacity: totalPixels)
        vDSP_vfltu8(uint8Ptr, 1, &floatPixels, 1, vDSP_Length(totalPixels))

        // 2. & 3. 2D DCT (Discrete Cosine Transform)
        if let rowDCT = vDSP.DCT(count: width, transformType: .II),
           let colDCT = vDSP.DCT(count: height, transformType: .II) {

            floatPixels.withUnsafeMutableBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }

                // --- Transform Rows ---
                for row in 0..<height {
                    let offset = row * width
                    let rowStartPtr = baseAddress + offset
                    var rowBuffer = UnsafeMutableBufferPointer(start: rowStartPtr, count: width)
                    rowDCT.transform(rowBuffer, result: &rowBuffer)
                }

                // --- Transform Columns ---
                var columnTmp = [Float](repeating: 0, count: height)
                for col in 0..<width {
                    // Manually extract column (Safe and fast within pointer block)
                    for row in 0..<height {
                        columnTmp[row] = baseAddress[row * width + col]
                    }

                    // DCT transform the column
                    colDCT.transform(columnTmp, result: &columnTmp)

                    // Write back
                    for row in 0..<height {
                        baseAddress[row * width + col] = columnTmp[row]
                    }
                }
            }
        }

        // 4. Extract low-frequency block (Top-Left 8x8)
        // We skip [0,0] (the DC component) to focus on structural patterns
        var dctLowFreq = [Float]()
        dctLowFreq.reserveCapacity(lowFreqSize * lowFreqSize)

        for row in 0..<lowFreqSize {
            for col in 0..<lowFreqSize {
                if row == 0 && col == 0 { continue }
                dctLowFreq.append(floatPixels[row * width + col])
            }
        }

        // 5. Compute median and generate hash bits
        let sortedFreq = dctLowFreq.sorted()
        let median = sortedFreq[sortedFreq.count / 2]

        var hash: UInt64 = 0
        for value in dctLowFreq {
            hash <<= 1
            if value > median {
                hash |= 1
            }
        }

        return hash
    }

    private func pHashToImageId(_ hash: UInt64) -> String {
        let str = String(hash, radix: 10)
        let paddingCount = 20 - str.count
        let paddedStr = String(repeating: "0", count: paddingCount) + str
        return paddedStr
    }

}

//extension UIView {
//    func findAVPlayerViewController() -> AVPlayerViewController? {
//        // Responder chain
//        var responder: UIResponder? = self
//        while let r = responder {
//            if let playerVC = r as? AVPlayerViewController {
//                return playerVC
//            }
//            responder = r.next
//        }
//
//        // Recurse subviews
//        for subview in subviews {
//            if let playerVC = subview.findAVPlayerViewController() {
//                return playerVC
//            }
//        }
//        return nil
//    }
//}
