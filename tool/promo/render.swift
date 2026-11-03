import AppKit
import AVFoundation
import CoreVideo
import CoreMedia
import CoreText

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let out = root.appendingPathComponent("output/promo")
let width = 1080, height = 1920, fps = 30
let green = NSColor(srgbRed: 0.0, green: 0.73, blue: 0.37, alpha: 1)
let ink = NSColor(srgbRed: 0.02, green: 0.20, blue: 0.15, alpha: 1)
let blue = NSColor(srgbRed: 0.13, green: 0.64, blue: 0.98, alpha: 1)
let gold = NSColor(srgbRed: 1, green: 0.76, blue: 0.13, alpha: 1)
func asset(_ path: String) -> NSImage { NSImage(contentsOf: root.appendingPathComponent(path))! }
let logo = asset("assets/brand/picnutri_wordmark_green.png")
let screen = asset("output/home-reference.png")
let food = asset("output/instagram/01-conheca-picnutri.png")
func clamp(_ v: Double) -> Double { max(0, min(1,v)) }
func ease(_ x: Double) -> Double { let x = clamp(x); return 1-pow(1-x,3) }
func round(_ r: CGRect, _ radius: Double, _ color: NSColor) {
    color.setFill(); NSBezierPath(roundedRect:r, xRadius:radius, yRadius:radius).fill()
}
func text(_ value:String, _ rect:CGRect, size:Double, color:NSColor=ink, weight:NSFont.Weight = .bold, align:NSTextAlignment = .left) {
    let p=NSMutableParagraphStyle(); p.alignment=align; p.lineSpacing=5
    let f=NSFont(name: weight == .regular ? "Inter-Regular" : "Inter-Bold", size:size) ?? NSFont.systemFont(ofSize:size, weight:weight)
    (value as NSString).draw(in:rect, withAttributes:[.font:f,.foregroundColor:color,.paragraphStyle:p])
}
func image(_ img:NSImage, _ rect:CGRect, alpha:Double=1) {
    img.draw(in:rect, from:.zero, operation:.sourceOver, fraction:alpha, respectFlipped:true, hints:[.interpolation:NSImageInterpolation.high])
}
func symbol(_ name:String, _ rect:CGRect, color:NSColor) {
    guard let img=NSImage(systemSymbolName:name, accessibilityDescription:nil) else{return}
    let config=NSImage.SymbolConfiguration(pointSize:rect.width, weight:.medium).applying(.init(paletteColors:[color]))
    image(img.withSymbolConfiguration(config) ?? img,rect)
}
func pill(_ label:String, _ rect:CGRect, tint:NSColor=green) {
    round(rect,rect.height/2,tint.withAlphaComponent(0.12)); text(label,rect.insetBy(dx:24,dy:14),size:30,color:tint,align:.center)
}
func phone(_ rect:CGRect, pan:Double) {
    NSGraphicsContext.saveGraphicsState()
    let shadow=NSShadow(); shadow.shadowColor=ink.withAlphaComponent(0.16);shadow.shadowBlurRadius=35;shadow.shadowOffset=NSSize(width:0,height:18);shadow.set()
    round(rect.insetBy(dx:-12,dy:-12),62,ink)
    NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect:rect,xRadius:50,yRadius:50).addClip()
    let h=rect.width*screen.size.height/screen.size.width
    image(screen,CGRect(x:rect.minX,y:rect.minY-pan,width:rect.width,height:h))
    NSGraphicsContext.restoreGraphicsState()
    round(CGRect(x:rect.midX-73,y:rect.minY+14,width:146,height:28),14,ink)
}
func cropFood() -> NSImage {
    var rect=CGRect(origin:.zero,size:food.size)
    let cg=food.cgImage(forProposedRect:&rect,context:nil,hints:nil)!
    let crop=cg.cropping(to:CGRect(x:0,y:Double(cg.height)*0.39,width:Double(cg.width),height:Double(cg.height)*0.52))!
    return NSImage(cgImage:crop,size:NSSize(width:crop.width,height:crop.height))
}
let mealArt=cropFood()
for name in ["Regular","Bold"] {
    CTFontManagerRegisterFontsForURL(root.appendingPathComponent("assets/fonts/Inter-\(name).ttf") as CFURL,.process,nil)
}
let silent=out.appendingPathComponent("picnutri-silent.mp4")
try? FileManager.default.removeItem(at:silent)
let writer=try AVAssetWriter(outputURL:silent,fileType:.mp4)
let input=AVAssetWriterInput(mediaType:.video,outputSettings:[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:width,AVVideoHeightKey:height,AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:6500000,AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel]])
let adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32ARGB,kCVPixelBufferWidthKey as String:width,kCVPixelBufferHeightKey as String:height,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
writer.add(input);writer.startWriting();writer.startSession(atSourceTime:.zero)
for frame in 0..<(30*fps) {
    while !input.isReadyForMoreMediaData { Thread.sleep(forTimeInterval:0.002) }
    autoreleasepool {
        var pixel:CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil,adaptor.pixelBufferPool!,&pixel)
        let px=pixel!;CVPixelBufferLockBaseAddress(px,[])
        let ctx=CGContext(data:CVPixelBufferGetBaseAddress(px),width:width,height:height,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(px),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipFirst.rawValue)!
        ctx.translateBy(x:0,y:CGFloat(height));ctx.scaleBy(x:1,y:-1)
        NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:ctx,flipped:true)
        let t=Double(frame)/Double(fps), scene=min(5,Int(t/5)), local=t-Double(scene)*5
        let entry=ease(local/0.7), offset=(1-entry)*70
        let bg=NSGradient(starting:NSColor(srgbRed:0.95,green:0.99,blue:0.97,alpha:1),ending:NSColor(srgbRed:0.83,green:0.97,blue:0.89,alpha:1))!
        bg.draw(in:CGRect(x:0,y:0,width:width,height:height),angle:65)
        green.withAlphaComponent(0.065).setFill()
        NSBezierPath(ovalIn:CGRect(x:650+sin(t*0.4)*30,y:570,width:650,height:900)).fill()
        image(logo,CGRect(x:82,y:170,width:335,height:74))
        text("SUA EVOLUÇÃO, NO SEU RITMO",CGRect(x:84,y:278,width:900,height:45),size:24,color:ink.withAlphaComponent(0.6),weight:.regular)
        NSGraphicsContext.saveGraphicsState();ctx.translateBy(x:0,y:offset);ctx.setAlpha(entry)
        switch scene {
        case 0:
            text("Seu cuidado.\nSeu ritmo.",CGRect(x:80,y:390,width:930,height:240),size:91)
            text("Alimentação, água e conquistas\nem um só aplicativo.",CGRect(x:84,y:654,width:900,height:120),size:40,weight:.regular)
            let scale=1+0.025*local/5
            phone(CGRect(x:300-(scale-1)*240,y:850,width:480*scale,height:780*scale),pan:0)
            pill("Mais simples. Mais seu.",CGRect(x:160,y:1680,width:760,height:78))
        case 1:
            text("Sua alimentação\nem um clique.",CGRect(x:80,y:385,width:930,height:250),size:82)
            text("Fotografe seu prato.\nVeja calorias e macros estimados.",CGRect(x:84,y:657,width:920,height:130),size:40,weight:.regular)
            NSGraphicsContext.saveGraphicsState();NSBezierPath(roundedRect:CGRect(x:55,y:850,width:970,height:775),xRadius:60,yRadius:60).addClip()
            image(mealArt,CGRect(x:45-local*4,y:835,width:1000+local*8,height:820+local*6))
            NSGraphicsContext.restoreGraphicsState()
            pill("Fotografe • Revise • Registre",CGRect(x:140,y:1645,width:800,height:80))
        case 2:
            text("Seu dia em\nequilíbrio.",CGRect(x:80,y:385,width:930,height:250),size:86)
            text("Calorias e nutrientes organizados\npara acompanhar sua rotina.",CGRect(x:84,y:657,width:920,height:130),size:40,weight:.regular)
            phone(CGRect(x:210,y:835,width:660,height:760),pan:260+ease(local/5)*8)
            pill("Calorias",CGRect(x:82,y:1650,width:280,height:78))
            pill("Proteínas",CGRect(x:386,y:1650,width:300,height:78),tint:blue)
            pill("Macros",CGRect(x:710,y:1650,width:280,height:78))
        case 3:
            text("Água em dia.\nUm toque por vez.",CGRect(x:80,y:385,width:940,height:250),size:77)
            text("Registre seus copos de água\ne acompanhe sua meta diária.",CGRect(x:84,y:657,width:920,height:130),size:40,weight:.regular)
            round(CGRect(x:100,y:870,width:880,height:690),55,NSColor.white)
            let amount=ease(local/3.5)
            round(CGRect(x:220,y:970,width:250,height:400),45,blue.withAlphaComponent(0.12))
            NSGraphicsContext.saveGraphicsState();NSBezierPath(roundedRect:CGRect(x:237,y:987,width:216,height:366),xRadius:32,yRadius:32).addClip()
            round(CGRect(x:237,y:1353-310*amount,width:216,height:320),0,blue.withAlphaComponent(0.65));NSGraphicsContext.restoreGraphicsState()
            symbol("drop.fill",CGRect(x:298,y:1090,width:90,height:120),color:.white)
            text("Hidratação",CGRect(x:530,y:980,width:400,height:70),size:43)
            text(String(format:"%.1f",0.8+amount).replacingOccurrences(of:".",with:",") + " L",CGRect(x:530,y:1080,width:380,height:90),size:65,color:blue)
            pill("+200 ml",CGRect(x:530,y:1210,width:320,height:80),tint:blue)
            pill("+300 ml",CGRect(x:530,y:1320,width:320,height:80),tint:blue)
            pill("Cada copo conta.",CGRect(x:220,y:1650,width:640,height:80),tint:blue)
        case 4:
            text("Pequenos hábitos.\nNovas conquistas.",CGRect(x:80,y:385,width:950,height:250),size:75)
            text("Complete missões diárias.\nGanhe estrelas e suba de nível.",CGRect(x:84,y:657,width:920,height:130),size:40,weight:.regular)
            round(CGRect(x:100,y:865,width:880,height:710),55,NSColor.white)
            let pulse=1+sin(local*2.4)*0.035
            symbol("trophy.fill",CGRect(x:540-165*pulse,y:935,width:330*pulse,height:330*pulse),color:gold)
            for i in 0..<3 { symbol("star.fill",CGRect(x:350+Double(i)*135,y:1300,width:95,height:95),color:gold) }
            text("3 dias de cuidado!",CGRect(x:140,y:1435,width:800,height:80),size:45,align:.center)
            pill("Bronze → Prata → Ouro → Diamante",CGRect(x:90,y:1645,width:900,height:80))
        default:
            text("Seu próximo cuidado\ncomeça aqui.",CGRect(x:80,y:400,width:960,height:270),size:79)
            text("Uma refeição. Um copo de água.\nUma conquista de cada vez.",CGRect(x:84,y:705,width:920,height:130),size:40,weight:.regular)
            round(CGRect(x:130,y:990,width:820,height:400),60,.white)
            image(logo,CGRect(x:225,y:1100,width:630,height:145))
            round(CGRect(x:140,y:1500,width:800,height:115),57,green)
            text("Conheça o PicNutri",CGRect(x:165,y:1527,width:750,height:80),size:46,color:.white,align:.center)
            text("Sua evolução, no seu ritmo.",CGRect(x:100,y:1675,width:880,height:60),size:33,weight:.regular,align:.center)
        }
        NSGraphicsContext.restoreGraphicsState()
        // Progresso discreto e transições suaves entre cenas.
        round(CGRect(x:84,y:1800,width:912,height:5),2,ink.withAlphaComponent(0.08))
        round(CGRect(x:84,y:1800,width:912*t/30,height:5),2,green)
        let fade=max(1-clamp(local/0.23),clamp((local-4.7)/0.3))
        if fade>0 { round(CGRect(x:0,y:0,width:width,height:height),0,NSColor(srgbRed:0.94,green:0.99,blue:0.96,alpha:fade)) }
        NSGraphicsContext.restoreGraphicsState()
        CVPixelBufferUnlockBaseAddress(px,[])
        if !adaptor.append(px,withPresentationTime:CMTime(value:Int64(frame),timescale:Int32(fps))) { fatalError("Frame: \(String(describing:writer.error))") }
    }
    if frame % 150 == 0 { print("Cena \(frame/150+1)/6");fflush(stdout) }
}
input.markAsFinished()
let done=DispatchSemaphore(value:0);writer.finishWriting {done.signal()};done.wait()
guard writer.status == .completed else {fatalError("Writer \(String(describing:writer.error))")}
print("Vídeo renderizado")
