import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins


func analyzeVideoCharacteristics(url: URL, sampleCount: Int = 8) async -> VideoAttrs? {
    let asset = AVAsset(url: url)
    
    do {
        let duration = try await asset.load(.duration)
        guard duration.seconds > 0.5 else { return nil }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Key optimizations:
        imageGenerator.requestedTimeToleranceBefore = .positiveInfinity  // Use keyframes
        imageGenerator.requestedTimeToleranceAfter = .positiveInfinity   // Use keyframes
        imageGenerator.maximumSize = CGSize(width: 320, height: 320)     // Reduced resolution
        
        var brightnessSum = 0.0
        var saturationSum = 0.0
        var warmthSum = 0.0
        var validSamples = 0
        
        // Avoid first and last 5%
        let startCutoff = duration.seconds * 0.05
        let endCutoff = duration.seconds * 0.95
        let effectiveDuration = endCutoff - startCutoff
        
        for i in 0..<sampleCount {
            // Distribute samples evenly in the middle 90%
            let seconds = startCutoff + (effectiveDuration * (Double(i) + 0.5) / Double(sampleCount))
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            
            do {
                // Capture at keyframe with reduced resolution
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let ciImage = CIImage(cgImage: cgImage)
                let extent = ciImage.extent
                
                guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
                    kCIInputImageKey: ciImage,
                    kCIInputExtentKey: CIVector(cgRect: extent)
                ]), let output = filter.outputImage else { continue }
                
                let context = CIContext(options: [.useSoftwareRenderer: false])
                var pixel = [UInt8](repeating: 0, count: 4)
                context.render(
                    output,
                    toBitmap: &pixel,
                    rowBytes: 4,
                    bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                    format: .RGBA8,
                    colorSpace: nil
                )
                
                let r = Double(pixel[0]) / 255.0
                let g = Double(pixel[1]) / 255.0
                let b = Double(pixel[2]) / 255.0
                
                // Skip black/dark frames
                guard (r + g + b) > 0.3 else { continue }
                
                let brightness = (0.2126 * r) + (0.7152 * g) + (0.114 * b)
                let maxVal = max(r, g, b)
                let minVal = min(r, g, b)
                let saturation = maxVal > 0.01 ? (maxVal - minVal) / maxVal : 0.0
                let warmth = (r - b) / (r + b + 0.01)
                
                brightnessSum += brightness
                saturationSum += saturation
                warmthSum += warmth
                validSamples += 1
            } catch {
                print("Frame capture error: \(error.localizedDescription)")
            }
        }
        
        guard validSamples > 0 else { return nil }
        return VideoAttrs(
            brightness: brightnessSum / Double(validSamples),
            saturation: saturationSum / Double(validSamples),
            warmth: warmthSum / Double(validSamples)
        )
    } catch {
        print("Duration load error: \(error.localizedDescription)")
        return nil
    }
}

func createAdaptiveDarkModeOverlay(rect: CGRect, characteristics: VideoAttrs? = nil) -> CALayer {
    let attrs = characteristics ?? VideoAttrs.default
    let brightness = attrs.brightness
    let saturation = attrs.saturation
    let warmth = attrs.warmth
    
    let overlayLayer = CALayer()
    overlayLayer.frame = rect
    overlayLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
    
    // Brightness adjustment curve (more aggressive for bright content)
    let baseDarkening = min(0.4, brightness * 0.6)
    let extraDarkening = brightness > 0.3 ? (brightness - 0.3) * 0.5 : 0
    let brightnessAdj = Float(baseDarkening + extraDarkening)
    
    let saturationAdj = Float(0.85 - (saturation * 0.2))
    let warmthReduction = Float(min(0.2, max(0, warmth * 0.4)))
    
    // Color adjustment
    let colorFilter = CIFilter.colorControls()
    colorFilter.brightness = -brightnessAdj
    colorFilter.contrast = 1.08
    colorFilter.saturation = saturationAdj
    
    // Warm color reduction
    let warmAdjustment = CIFilter.colorMatrix()
    warmAdjustment.rVector = CIVector(x: 1.0 - Double(warmthReduction), y: 0, z: 0, w: 0)
    warmAdjustment.gVector = CIVector(x: 0, y: 1.0 - Double(warmthReduction * 0.6), z: 0, w: 0)
    warmAdjustment.bVector = CIVector(x: 0, y: 0, z: 1.0 + Double(warmthReduction * 0.4), w: 0)
    
    // Temperature correction
    let tempFilter = CIFilter.temperatureAndTint()
    tempFilter.neutral = CIVector(x: 6500, y: 0)
    let tempAdjust = brightness > 0.35 ? 5500 : 6000 - (warmth * 1000)
    tempFilter.targetNeutral = CIVector(
        x: max(5000, min(7000, tempAdjust)),
        y: min(0, warmth * -20)
    )
    
    // Apply filters
    overlayLayer.backgroundFilters = [colorFilter, warmAdjustment, tempFilter]
    overlayLayer.compositingFilter = "multiplyBlendMode"
    
    // Vignette
//    let vignetteLayer = CALayer()
//    vignetteLayer.frame = overlayLayer.bounds
//    vignetteLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
//    
//    let vignette = CIFilter.vignetteEffect()
//    vignette.radius = 1.8
//    vignette.intensity = Float(0.3 + (brightness * 0.25))
//    vignette.falloff = 0.8
//    
//    vignetteLayer.backgroundFilters = [vignette]
//    vignetteLayer.compositingFilter = "multiplyBlendMode"
//    vignetteLayer.opacity = Float(0.6 - (brightness * 0.2))
//    
//    overlayLayer.addSublayer(vignetteLayer)
    
    return overlayLayer
}
