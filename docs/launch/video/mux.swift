// swiftc -O mux.swift -o mux && ./mux <framesDir> <fps> <vo.mp3> <music.mp3> <out.mp4>
// 1. Writes the PNG frames to a silent H.264 movie with AVAssetWriter.
// 2. Lays the narration and the music under it, music ducked, and exports the final MP4.
import Foundation
import AVFoundation
import AppKit

let args = CommandLine.arguments
guard args.count >= 6 else { print("usage: mux framesDir fps vo.mp3 music.mp3 out.mp4"); exit(1) }
let framesDir = args[1], fps = Int32(args[2])!, voURL = URL(fileURLWithPath: args[3]), musicURL = URL(fileURLWithPath: args[4]), outURL = URL(fileURLWithPath: args[5])
let silentURL = outURL.deletingLastPathComponent().appendingPathComponent("silent.mp4")

func pixelBuffer(from image: NSImage, width: Int, height: Int, pool: CVPixelBufferPool) -> CVPixelBuffer? {
    var pb: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pb)
    guard let buffer = pb else { return nil }
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    let ctx = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8,
                        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)!
    var rect = CGRect(x: 0, y: 0, width: width, height: height)
    guard let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
    ctx.draw(cg, in: rect)
    return buffer
}

// --- 1. frames -> silent movie (skipped when framesDir is "-")
if framesDir != "-" {
let files = try! FileManager.default.contentsOfDirectory(atPath: framesDir).filter { $0.hasSuffix(".png") }.sorted()
guard let first = NSImage(contentsOfFile: framesDir + "/" + files[0]) else { print("no frames"); exit(1) }
let w = Int(first.size.width), h = Int(first.size.height)
try? FileManager.default.removeItem(at: silentURL)
let writer = try! AVAssetWriter(outputURL: silentURL, fileType: .mp4)
let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: w, AVVideoHeightKey: h,
    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 12_000_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel, AVVideoMaxKeyFrameIntervalKey: Int(fps) * 2]]
let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA, kCVPixelBufferWidthKey as String: w, kCVPixelBufferHeightKey as String: h])
writer.add(input)
writer.startWriting(); writer.startSession(atSourceTime: .zero)
var i = 0
for f in files {
    while !input.isReadyForMoreMediaData { usleep(2000) }
    autoreleasepool {
        if let img = NSImage(contentsOfFile: framesDir + "/" + f), let pb = pixelBuffer(from: img, width: w, height: h, pool: adaptor.pixelBufferPool!) {
            adaptor.append(pb, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: fps))
        }
    }
    i += 1
    if i % 300 == 0 { print("encoded", i, "of", files.count) }
}
input.markAsFinished()
let sem = DispatchSemaphore(value: 0)
writer.finishWriting { sem.signal() }; sem.wait()
print("silent movie written:", silentURL.path, "frames:", i, "status:", writer.status.rawValue)

}

// --- 2. composition with narration + ducked music
func loaded(_ url: URL) -> AVURLAsset {
    let a = AVURLAsset(url: url)
    let sem = DispatchSemaphore(value: 0)
    a.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { sem.signal() }
    sem.wait()
    var err: NSError?
    if a.statusOfValue(forKey: "tracks", error: &err) != .loaded { print("could not load", url.lastPathComponent, err?.localizedDescription ?? ""); exit(2) }
    return a
}
let videoAsset = loaded(silentURL), voAsset = loaded(voURL), musicAsset = loaded(musicURL)
guard let vSrc = videoAsset.tracks(withMediaType: .video).first, let voSrc = voAsset.tracks(withMediaType: .audio).first, let mSrc = musicAsset.tracks(withMediaType: .audio).first else { print("missing track"); exit(3) }
print("video", CMTimeGetSeconds(videoAsset.duration), "vo", CMTimeGetSeconds(voAsset.duration), "music", CMTimeGetSeconds(musicAsset.duration))
let comp = AVMutableComposition()
let duration = videoAsset.duration
let vTrack = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
let voTrack = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
let mTrack = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
do {
    try vTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: vSrc, at: .zero)
    let voDur = CMTimeMinimum(voAsset.duration, duration)
    try voTrack.insertTimeRange(CMTimeRange(start: .zero, duration: voDur), of: voSrc, at: .zero)
    let mDur = CMTimeMinimum(musicAsset.duration, duration)
    try mTrack.insertTimeRange(CMTimeRange(start: .zero, duration: mDur), of: mSrc, at: .zero)
} catch { print("insert failed:", error.localizedDescription); exit(4) }

let mix = AVMutableAudioMix()
let voParams = AVMutableAudioMixInputParameters(track: voTrack); voParams.setVolume(1.0, at: .zero)
let mParams = AVMutableAudioMixInputParameters(track: mTrack)
let bed: Float = 0.16, tailBed: Float = 0.30
let voEnd = CMTimeGetSeconds(CMTimeMinimum(voAsset.duration, duration)), total = CMTimeGetSeconds(duration)
func t(_ s: Double) -> CMTime { CMTime(seconds: s, preferredTimescale: 600) }
mParams.setVolumeRamp(fromStartVolume: 0, toEndVolume: bed, timeRange: CMTimeRange(start: .zero, duration: t(1.2)))
mParams.setVolume(bed, at: t(1.2))
mParams.setVolumeRamp(fromStartVolume: bed, toEndVolume: tailBed, timeRange: CMTimeRange(start: t(voEnd), duration: t(0.6)))
let fadeStart = max(voEnd + 0.7, total - 2.3)
mParams.setVolumeRamp(fromStartVolume: tailBed, toEndVolume: 0, timeRange: CMTimeRange(start: t(fadeStart), duration: t(total - fadeStart)))
mix.inputParameters = [voParams, mParams]

try? FileManager.default.removeItem(at: outURL)
guard let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality) else { print("no export session"); exit(5) }
export.outputURL = outURL; export.outputFileType = .mp4; export.audioMix = mix; export.shouldOptimizeForNetworkUse = true
let sem2 = DispatchSemaphore(value: 0)
export.exportAsynchronously { sem2.signal() }; sem2.wait()
print("export:", export.status.rawValue, export.error?.localizedDescription ?? "ok", "->", outURL.path)
