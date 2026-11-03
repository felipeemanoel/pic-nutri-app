import Foundation
import AppKit
import AVFoundation
import CoreMedia
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("output/promo")
let rate=44100, count=44100*30
var samples=[Int16]();samples.reserveCapacity(count*2)
let chords:[[Double]]=[[261.63,329.63,392],[220,261.63,329.63],[174.61,220,261.63],[196,246.94,293.66]]
let beat=0.6
for i in 0..<count {
    let t=Double(i)/Double(rate)
    let chord=chords[Int(t/(beat*4))%4]
    let phase=t.truncatingRemainder(dividingBy:beat*4)
    let env=min(1,phase/0.15)*min(1,(beat*4-phase)/0.25)
    var v=0.0
    for f in chord {v += sin(2*Double.pi*f*t)*0.035*env; v += sin(2*Double.pi*(f*1.002)*t)*0.012*env}
    let noteTime=t.truncatingRemainder(dividingBy:beat/2)
    let note=chord[Int(t/(beat/2))%3]*2
    v += (sin(2*Double.pi*note*noteTime)+0.25*sin(4*Double.pi*note*noteTime))*exp(-noteTime*14)*0.055
    let k=t.truncatingRemainder(dividingBy:beat)
    v += sin(2*Double.pi*(52*k+22*(1-exp(-k*30))/30))*exp(-k*20)*0.13
    let hat=sin(Double(i)*171.713)*sin(Double(i)*43.731)
    v += hat*exp(-noteTime*90)*0.025
    v *= min(1,t/0.8)*min(1,(30-t)/1.8)
    let left=Int16(max(-1,min(1,v))*28000)
    samples.append(left);samples.append(left)
}
var wav=Data()
func ascii(_ s:String) {wav.append(s.data(using:.ascii)!)}
func u32(_ n:UInt32) {var x=n.littleEndian;withUnsafeBytes(of:&x){wav.append(contentsOf:$0)}}
func u16(_ n:UInt16) {var x=n.littleEndian;withUnsafeBytes(of:&x){wav.append(contentsOf:$0)}}
ascii("RIFF");u32(UInt32(36+samples.count*2));ascii("WAVEfmt ");u32(16);u16(1);u16(2);u32(UInt32(rate));u32(UInt32(rate*4));u16(4);u16(16);ascii("data");u32(UInt32(samples.count*2));samples.withUnsafeBytes{wav.append(contentsOf:$0)}
let audioURL=root.appendingPathComponent("trilha-original.wav");try wav.write(to:audioURL)
let video=AVURLAsset(url:root.appendingPathComponent("picnutri-silent.mp4"))
let audio=AVURLAsset(url:audioURL)
let comp=AVMutableComposition()
let range=CMTimeRange(start:.zero,duration:CMTime(seconds:30,preferredTimescale:600))
let vt=comp.addMutableTrack(withMediaType:.video,preferredTrackID:kCMPersistentTrackID_Invalid)!
try vt.insertTimeRange(range,of:video.tracks(withMediaType:.video).first!,at:.zero)
let at=comp.addMutableTrack(withMediaType:.audio,preferredTrackID:kCMPersistentTrackID_Invalid)!
try at.insertTimeRange(range,of:audio.tracks(withMediaType:.audio).first!,at:.zero)
let finalURL=root.appendingPathComponent("PicNutri-Reels-30s.mp4")
try? FileManager.default.removeItem(at:finalURL)
let exporter=AVAssetExportSession(asset:comp,presetName:AVAssetExportPresetHighestQuality)!
exporter.outputURL=finalURL;exporter.outputFileType = .mp4;exporter.shouldOptimizeForNetworkUse=true
let sem=DispatchSemaphore(value:0)
exporter.exportAsynchronously{sem.signal()};sem.wait()
guard exporter.status == .completed else{fatalError("Export: \(String(describing:exporter.error))")}
print("MP4 com áudio exportado")
let result=AVURLAsset(url:finalURL)
let gen=AVAssetImageGenerator(asset:result);gen.appliesPreferredTrackTransform=true
let sheet=NSImage(size:NSSize(width:810,height:960));sheet.lockFocus()
for (i,s) in [2.5,7.5,12.5,17.5,22.5,27.5].enumerated() {
    let cg=try gen.copyCGImage(at:CMTime(seconds:s,preferredTimescale:600),actualTime:nil)
    let image=NSImage(cgImage:cg,size:NSSize(width:cg.width,height:cg.height))
    image.draw(in:CGRect(x:(i%3)*270,y:(1-i/3)*480,width:270,height:480))
    let bitmap=NSBitmapImageRep(cgImage:cg)
    try bitmap.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("cena-\(i+1).png"))
}
sheet.unlockFocus()
let bitmap=NSBitmapImageRep(data:sheet.tiffRepresentation!)!
try bitmap.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("preview.png"))
let track=result.tracks(withMediaType:.video).first!
let metadata:[String:Any]=["duration_seconds":CMTimeGetSeconds(result.duration),"width":track.naturalSize.width,"height":track.naturalSize.height,"fps":track.nominalFrameRate,"audio_tracks":result.tracks(withMediaType:.audio).count]
try JSONSerialization.data(withJSONObject:metadata,options:.prettyPrinted).write(to:root.appendingPathComponent("metadata.json"))
print(metadata)
