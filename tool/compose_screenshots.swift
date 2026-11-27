import Foundation
import AppKit
import CoreGraphics
import CoreText

let projDir = CommandLine.arguments[1]
let rawDir = "\(projDir)/build/raw_screenshots"
let outBase = "\(projDir)/screenshots"

// Register bundled Poppins font for crisp marketing headlines
let poppinsURL = URL(fileURLWithPath: "\(projDir)/assets/fonts/Poppins-Regular.ttf") as CFURL
CTFontManagerRegisterFontsForURL(poppinsURL, .process, nil)

struct RGB {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    var cgColor: CGColor {
        CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r, g, b, 1.0])!
    }
    func alpha(_ a: CGFloat) -> CGColor {
        CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r, g, b, a])!
    }
}

let bgDark = RGB(r: 0.020, g: 0.027, b: 0.047)
let bgMid = RGB(r: 0.045, g: 0.065, b: 0.115)
let accentBlue = RGB(r: 0.133, g: 0.533, b: 1.000)
let accentCrimson = RGB(r: 1.000, g: 0.165, b: 0.231)
let accentGold = RGB(r: 0.961, g: 0.722, b: 0.000)
let accentViolet = RGB(r: 0.545, g: 0.361, b: 0.965)
let accentCyan = RGB(r: 0.000, g: 0.831, b: 1.000)

func loadCGImage(_ path: String) -> CGImage {
    guard let img = NSImage(contentsOfFile: path),
          let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fatalError("Could not load image at \(path)")
    }
    return cg
}

func saveOpaquePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        fatalError("Failed creating destination \(path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        fatalError("Failed saving \(path)")
    }
}

func makeContext(width: Int, height: Int) -> CGContext {
    let cs = CGColorSpaceCreateDeviceRGB()
    // noneSkipLast -> strictly opaque RGB PNG (no alpha channel for Apple App Store)
    guard let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { fatalError("Context creation failed") }
    ctx.interpolationQuality = .high
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    return ctx
}

func drawBackdrop(ctx: CGContext, width: CGFloat, height: CGFloat, accent: RGB) {
    let cs = CGColorSpaceCreateDeviceRGB()
    // Base obsidian vertical gradient
    let grad = CGGradient(
        colorsSpace: cs,
        colors: [bgMid.cgColor, bgDark.cgColor, RGB(r: 0.012, g: 0.018, b: 0.032).cgColor] as CFArray,
        locations: [0.0, 0.55, 1.0]
    )!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: height), end: CGPoint(x: 0, y: 0), options: [])

    // Top radial dark-aura glow
    let topAura = CGGradient(
        colorsSpace: cs,
        colors: [accent.alpha(0.38), accent.alpha(0.10), accent.alpha(0.0)] as CFArray,
        locations: [0.0, 0.45, 1.0]
    )!
    ctx.drawRadialGradient(
        topAura,
        startCenter: CGPoint(x: width * 0.5, y: height * 0.88),
        startRadius: 0,
        endCenter: CGPoint(x: width * 0.5, y: height * 0.88),
        endRadius: width * 0.85,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    // Mid-behind-device energy aura glow
    let midAura = CGGradient(
        colorsSpace: cs,
        colors: [accent.alpha(0.28), accent.alpha(0.06), accent.alpha(0.0)] as CFArray,
        locations: [0.0, 0.5, 1.0]
    )!
    ctx.drawRadialGradient(
        midAura,
        startCenter: CGPoint(x: width * 0.5, y: height * 0.38),
        startRadius: 0,
        endCenter: CGPoint(x: width * 0.5, y: height * 0.38),
        endRadius: width * 0.72,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    // Subtle tactical cyber grid
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(colorSpace: cs, components: [1, 1, 1, 0.035])!)
    ctx.setLineWidth(1.5)
    let step = width / 16.0
    var x: CGFloat = 0
    while x <= width {
        ctx.move(to: CGPoint(x: x, y: 0))
        ctx.addLine(to: CGPoint(x: x, y: height))
        x += step
    }
    var y: CGFloat = 0
    while y <= height {
        ctx.move(to: CGPoint(x: 0, y: y))
        ctx.addLine(to: CGPoint(x: width, y: y))
        y += step
    }
    ctx.strokePath()
    ctx.restoreGState()
}

func drawCenteredText(
    ctx: CGContext,
    text: String,
    centerX: CGFloat,
    topYFromBottom: CGFloat,
    maxWidth: CGFloat,
    fontSize: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    letterSpacing: CGFloat = 0.0,
    lineSpacing: CGFloat = 6.0
) {
    let font = NSFont.systemFont(ofSize: fontSize, weight: weight)
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineSpacing = lineSpacing
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: para,
        .kern: letterSpacing,
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let framesetter = CTFramesetterCreateWithAttributedString(attrStr)
    let boxHeight: CGFloat = fontSize * 3.8
    let rect = CGRect(x: centerX - maxWidth / 2, y: topYFromBottom - boxHeight, width: maxWidth, height: boxHeight)
    let path = CGPath(rect: rect, transform: nil)
    let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: attrStr.length), path, nil)
    CTFrameDraw(frame, ctx)
}

func drawPillBadge(
    ctx: CGContext,
    text: String,
    centerX: CGFloat,
    yFromBottom: CGFloat,
    fontSize: CGFloat,
    accent: RGB
) {
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(red: accent.r, green: accent.g, blue: accent.b, alpha: 1.0),
        .kern: 2.2,
    ]
    let attrStr = NSAttributedString(string: text, attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrStr)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    let padX = fontSize * 1.15
    let padY = fontSize * 0.55
    let pillW = bounds.width + padX * 2
    let pillH = bounds.height + padY * 2
    let pillRect = CGRect(x: centerX - pillW / 2, y: yFromBottom - pillH / 2, width: pillW, height: pillH)

    ctx.saveGState()
    let pillPath = CGPath(roundedRect: pillRect, cornerWidth: pillH / 2, cornerHeight: pillH / 2, transform: nil)
    ctx.addPath(pillPath)
    ctx.setFillColor(accent.alpha(0.16))
    ctx.fillPath()
    ctx.addPath(pillPath)
    ctx.setStrokeColor(accent.alpha(0.62))
    ctx.setLineWidth(2.2)
    ctx.strokePath()

    ctx.textPosition = CGPoint(
        x: centerX - bounds.width / 2,
        y: yFromBottom - bounds.height / 2 - bounds.origin.y
    )
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

func drawDeviceFrame(
    ctx: CGContext,
    screenImage: CGImage,
    rect: CGRect,
    cornerRadius: CGFloat,
    bezelThickness: CGFloat,
    accent: RGB,
    isPhone: Bool,
    rotationDegrees: CGFloat = 0.0
) {
    ctx.saveGState()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    if rotationDegrees != 0 {
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: rotationDegrees * .pi / 180.0)
        ctx.translateBy(x: -center.x, y: -center.y)
    }

    let outerRect = rect.insetBy(dx: -bezelThickness, dy: -bezelThickness)
    let outerRadius = cornerRadius + bezelThickness * 0.82
    let outerPath = CGPath(roundedRect: outerRect, cornerWidth: outerRadius, cornerHeight: outerRadius, transform: nil)

    // Deep drop shadow + neon rim aura
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: 54, color: CGColor(gray: 0, alpha: 0.78))
    ctx.addPath(outerPath)
    ctx.setFillColor(RGB(r: 0.075, g: 0.088, b: 0.120).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Metallic bezel gradient border
    ctx.saveGState()
    ctx.addPath(outerPath)
    ctx.setStrokeColor(accent.alpha(0.65))
    ctx.setLineWidth(3.5)
    ctx.strokePath()
    ctx.restoreGState()

    // Inner black glass margin
    let innerGlass = rect.insetBy(dx: -bezelThickness * 0.35, dy: -bezelThickness * 0.35)
    let glassPath = CGPath(roundedRect: innerGlass, cornerWidth: cornerRadius + 4, cornerHeight: cornerRadius + 4, transform: nil)
    ctx.addPath(glassPath)
    ctx.setFillColor(CGColor(gray: 0.02, alpha: 1.0))
    ctx.fillPath()

    // Screen image clipped inside rounded display
    ctx.saveGState()
    let screenPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(screenPath)
    ctx.clip()
    ctx.draw(screenImage, in: rect)

    // Dynamic Island pill for iPhone
    if isPhone {
        let islandW = rect.width * 0.29
        let islandH = rect.width * 0.078
        let islandRect = CGRect(
            x: rect.midX - islandW / 2,
            y: rect.maxY - islandH - rect.width * 0.032,
            width: islandW,
            height: islandH
        )
        let islandPath = CGPath(roundedRect: islandRect, cornerWidth: islandH / 2, cornerHeight: islandH / 2, transform: nil)
        ctx.addPath(islandPath)
        ctx.setFillColor(CGColor(gray: 0.0, alpha: 1.0))
        ctx.fillPath()
    }
    ctx.restoreGState()

    ctx.restoreGState()
}

struct SlideSpec {
    let filename: String
    let rawPhone: String
    let rawPad: String
    let badge: String
    let headline: String
    let subtitle: String
    let accent: RGB
}

let slides: [SlideSpec] = [
    SlideSpec(
        filename: "01_home_routine.png",
        rawPhone: "iphone_01_home.png",
        rawPad: "ipad_01_home.png",
        badge: "AURABUNNY · AIM ROUTINE",
        headline: "MASTER YOUR\nDAILY AIM",
        subtitle: "Track accuracy trends, daily goals & personal bests",
        accent: accentBlue
    ),
    SlideSpec(
        filename: "02_aim_drills.png",
        rawPhone: "iphone_02_aim.png",
        rawPad: "ipad_02_aim.png",
        badge: "4 PRO AIM TRAINERS",
        headline: "PRECISION &\nRAPID DRAG",
        subtitle: "Aim Basics, Moving Targets, Drag Headshot & One-Tap",
        accent: accentCrimson
    ),
    SlideSpec(
        filename: "03_drag_headshot.png",
        rawPhone: "iphone_03_drag_arena.png",
        rawPad: "ipad_03_drag_arena.png",
        badge: "LIVE DRAG SIMULATOR",
        headline: "DIAL IN EVERY\nHEADSHOT",
        subtitle: "Real chest-to-head swipe feedback & reaction timing",
        accent: accentCrimson
    ),
    SlideSpec(
        filename: "04_five_finger_hud.png",
        rawPhone: "iphone_04_hud.png",
        rawPad: "ipad_04_hud.png",
        badge: "5-FINGER CLAW LAB",
        headline: "BUILD YOUR\nCUSTOM HUD",
        subtitle: "Drag 2F–5F layouts & train all 5 control zones",
        accent: accentGold
    ),
    SlideSpec(
        filename: "05_sensitivity_lab.png",
        rawPhone: "iphone_05_sens.png",
        rawPad: "ipad_05_sens.png",
        badge: "SENSITIVITY LAB",
        headline: "FIND YOUR\nPERFECT SENSI",
        subtitle: "Tune 6 scopes & test live with the practice cursor",
        accent: accentViolet
    ),
]

// 1. Generate iPhone 6.1" screenshots (1179 x 2556 px)
for slide in slides {
    let W = 1179, H = 2556
    let ctx = makeContext(width: W, height: H)
    let w = CGFloat(W), h = CGFloat(H)
    drawBackdrop(ctx: ctx, width: w, height: h, accent: slide.accent)
    drawPillBadge(ctx: ctx, text: slide.badge, centerX: w / 2, yFromBottom: h - 130, fontSize: 27, accent: slide.accent)
    drawCenteredText(
        ctx: ctx,
        text: slide.headline,
        centerX: w / 2,
        topYFromBottom: h - 195,
        maxWidth: w - 110,
        fontSize: 94,
        weight: .heavy,
        color: .white,
        letterSpacing: -1.5,
        lineSpacing: 2
    )
    drawCenteredText(
        ctx: ctx,
        text: slide.subtitle,
        centerX: w / 2,
        topYFromBottom: h - 445,
        maxWidth: w - 140,
        fontSize: 36,
        weight: .medium,
        color: NSColor(white: 0.80, alpha: 1.0),
        lineSpacing: 4
    )

    let screen = loadCGImage("\(rawDir)/\(slide.rawPhone)")
    let devW: CGFloat = 860
    let devH: CGFloat = devW * (2556.0 / 1179.0)
    let devRect = CGRect(x: (w - devW) / 2, y: 80, width: devW, height: devH)
    drawDeviceFrame(
        ctx: ctx,
        screenImage: screen,
        rect: devRect,
        cornerRadius: 88,
        bezelThickness: 22,
        accent: slide.accent,
        isPhone: true
    )

    saveOpaquePNG(ctx.makeImage()!, to: "\(outBase)/iphone_6_1/\(slide.filename)")
}
print("Generated 5 iPhone 6.1\" screenshots (1179x2556)")

// 2. Generate iPad 12.9" screenshots (2048 x 2732 px)
for slide in slides {
    let W = 2048, H = 2732
    let ctx = makeContext(width: W, height: H)
    let w = CGFloat(W), h = CGFloat(H)
    drawBackdrop(ctx: ctx, width: w, height: h, accent: slide.accent)
    drawPillBadge(ctx: ctx, text: slide.badge, centerX: w / 2, yFromBottom: h - 135, fontSize: 34, accent: slide.accent)
    drawCenteredText(
        ctx: ctx,
        text: slide.headline.replacingOccurrences(of: "\n", with: " "),
        centerX: w / 2,
        topYFromBottom: h - 205,
        maxWidth: w - 180,
        fontSize: 108,
        weight: .heavy,
        color: .white,
        letterSpacing: -1.5
    )
    drawCenteredText(
        ctx: ctx,
        text: slide.subtitle,
        centerX: w / 2,
        topYFromBottom: h - 355,
        maxWidth: w - 260,
        fontSize: 44,
        weight: .medium,
        color: NSColor(white: 0.82, alpha: 1.0)
    )

    let screen = loadCGImage("\(rawDir)/\(slide.rawPad)")
    let devW: CGFloat = 1560
    let devH: CGFloat = devW * (1024.0 / 768.0) // 2080
    let devRect = CGRect(x: (w - devW) / 2, y: 110, width: devW, height: devH)
    drawDeviceFrame(
        ctx: ctx,
        screenImage: screen,
        rect: devRect,
        cornerRadius: 56,
        bezelThickness: 28,
        accent: slide.accent,
        isPhone: false
    )

    saveOpaquePNG(ctx.makeImage()!, to: "\(outBase)/ipad_12_9/\(slide.filename)")
}
print("Generated 5 iPad 12.9\" screenshots (2048x2732)")

// 3. Generate new `iphone_duo` screenshots (exact 2007 x 2853 px)
struct DuoSpec {
    let filename: String
    let leftRaw: String
    let rightRaw: String
    let badge: String
    let headline: String
    let subtitle: String
    let accent: RGB
}

let duoSlides: [DuoSpec] = [
    DuoSpec(
        filename: "01_duo_aim_and_drag.png",
        leftRaw: "iphone_01_home.png",
        rightRaw: "iphone_03_drag_arena.png",
        badge: "AURABUNNY · SENSI & AIM TRAINER",
        headline: "TRAIN FASTER.\nHIT CLEANER.",
        subtitle: "Personalized daily routines + live chest-to-head drag simulator",
        accent: accentBlue
    ),
    DuoSpec(
        filename: "02_duo_hud_and_sensi.png",
        leftRaw: "iphone_04_hud.png",
        rightRaw: "iphone_05_sens.png",
        badge: "CLAW HUD & SENSITIVITY LAB",
        headline: "YOUR HUD.\nYOUR SENSI.",
        subtitle: "5-Finger Claw workspace & 6-scope live sensitivity calibration",
        accent: accentGold
    ),
    DuoSpec(
        filename: "03_duo_drills_and_sys.png",
        leftRaw: "iphone_02_aim.png",
        rightRaw: "iphone_06_sys.png",
        badge: "ALL-IN-ONE ESPORTS COMPANION",
        headline: "PRO DRILLS &\nLIVE TELEMETRY",
        subtitle: "4 Aim trainers, 60s Reaction Lab & real-time Hz / TLS tools",
        accent: accentCyan
    ),
]

for duo in duoSlides {
    let W = 2007, H = 2853
    let ctx = makeContext(width: W, height: H)
    let w = CGFloat(W), h = CGFloat(H)
    drawBackdrop(ctx: ctx, width: w, height: h, accent: duo.accent)

    // Subtle app icon crest at top
    let appIcon = loadCGImage("\(projDir)/assets/images/AppIcon.png")
    let iconSize: CGFloat = 132
    let iconRect = CGRect(x: (w - iconSize) / 2, y: h - 220, width: iconSize, height: iconSize)
    ctx.saveGState()
    let iconPath = CGPath(roundedRect: iconRect, cornerWidth: 30, cornerHeight: 30, transform: nil)
    ctx.addPath(iconPath)
    ctx.clip()
    ctx.draw(appIcon, in: iconRect)
    ctx.restoreGState()

    drawPillBadge(ctx: ctx, text: duo.badge, centerX: w / 2, yFromBottom: h - 285, fontSize: 32, accent: duo.accent)
    drawCenteredText(
        ctx: ctx,
        text: duo.headline,
        centerX: w / 2,
        topYFromBottom: h - 355,
        maxWidth: w - 180,
        fontSize: 122,
        weight: .heavy,
        color: .white,
        letterSpacing: -2.0,
        lineSpacing: 2
    )
    drawCenteredText(
        ctx: ctx,
        text: duo.subtitle,
        centerX: w / 2,
        topYFromBottom: h - 670,
        maxWidth: w - 220,
        fontSize: 44,
        weight: .medium,
        color: NSColor(white: 0.82, alpha: 1.0),
        lineSpacing: 6
    )

    let phoneW: CGFloat = 820
    let phoneH: CGFloat = phoneW * (2556.0 / 1179.0) // ~1777

    // Back-left iPhone (slight counter-clockwise tilt)
    let leftImg = loadCGImage("\(rawDir)/\(duo.leftRaw)")
    let leftRect = CGRect(x: 135, y: 175, width: phoneW, height: phoneH)
    drawDeviceFrame(
        ctx: ctx,
        screenImage: leftImg,
        rect: leftRect,
        cornerRadius: 82,
        bezelThickness: 22,
        accent: duo.accent,
        isPhone: true,
        rotationDegrees: 4.0
    )

    // Front-right iPhone (slight clockwise tilt, overlapping cleanly)
    let rightImg = loadCGImage("\(rawDir)/\(duo.rightRaw)")
    let rightRect = CGRect(x: w - phoneW - 135, y: 95, width: phoneW, height: phoneH)
    drawDeviceFrame(
        ctx: ctx,
        screenImage: rightImg,
        rect: rightRect,
        cornerRadius: 82,
        bezelThickness: 22,
        accent: duo.accent,
        isPhone: true,
        rotationDegrees: -3.5
    )

    saveOpaquePNG(ctx.makeImage()!, to: "\(outBase)/iphone_duo/\(duo.filename)")
}
print("Generated 3 iphone_duo screenshots (2007x2853)")
