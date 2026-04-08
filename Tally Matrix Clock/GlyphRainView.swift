//
//  GlyphRainView.swift
//  Tally Matrix Clock
//

import SwiftUI
import Combine

struct GlyphRainView: View {
    let colorScheme: ColorSchemeOption
    var textTargets: [TextTarget] = []
    var rainSize: GlyphRainSize = .medium
    @State private var columns: [RainColumn] = []
    let timer = Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()

    private let glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$%&*+=?/<>~^{}[]|\\:;ァカサタナハマヤラワアイウエオ"

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for column in columns {
                    for (index, glyph) in column.glyphs.enumerated() {
                        let y = column.y + CGFloat(index) * column.fontSize * 1.2
                        guard y > -column.fontSize && y < size.height + column.fontSize else { continue }

                        // Head glyph is brightest, trail fades
                        let trailLength = column.glyphs.count
                        let distFromHead = trailLength - 1 - index
                        let brightness = max(0.05, 1.0 - (Double(distFromHead) / Double(max(trailLength, 1))))

                        let color = colorForColumn(column, brightness: brightness)

                        var text = Text(String(glyph))
                            .font(.system(size: column.fontSize, weight: .light, design: .monospaced))
                            .foregroundColor(color)
                        // Head glyph gets a glow effect via brighter color
                        if index == column.glyphs.count - 1 {
                            text = Text(String(glyph))
                                .font(.system(size: column.fontSize, weight: .bold, design: .monospaced))
                                .foregroundColor(color)
                        }

                        context.drawLayer { ctx in
                            let resolved = ctx.resolve(text)
                            ctx.draw(resolved, at: CGPoint(x: column.x, y: y))
                        }
                    }
                }
            }
            .onAppear {
                initializeColumns(width: geo.size.width, height: geo.size.height)
            }
            .onReceive(timer) { _ in
                updateColumns(height: geo.size.height)
            }
        }
    }

    func initializeColumns(width: CGFloat, height: CGFloat) {
        let columnCount = Int(width / rainSize.columnSpacing)
        columns = (0..<columnCount).map { i in
            let fontSize: CGFloat = CGFloat.random(in: rainSize.fontSizeRange)
            let x = CGFloat(i) * (width / CGFloat(columnCount)) + CGFloat.random(in: -5...5)
            let trailLength = Int.random(in: 8...25)
            let speed: CGFloat = CGFloat.random(in: 3...10)
            let startY = -CGFloat.random(in: 0...height * 1.5)

            return RainColumn(
                x: x,
                y: startY,
                speed: speed,
                fontSize: fontSize,
                trailLength: trailLength,
                glyphs: (0..<trailLength).map { _ in randomGlyph() },
                columnColor: randomColumnColor()
            )
        }
    }

    func updateColumns(height: CGFloat) {
        for i in columns.indices {
            columns[i].y += columns[i].speed

            // Check text collisions — head glyph picks up characters it passes through
            let headIndex = columns[i].glyphs.count - 1
            let headY = columns[i].y + CGFloat(headIndex) * columns[i].fontSize * 1.2

            for target in textTargets {
                // Check if the head is passing through this text's vertical band
                if headY >= target.frame.minY && headY <= target.frame.maxY {
                    if let char = target.characterAt(x: columns[i].x) {
                        // Morph the head glyph to match the text character
                        columns[i].glyphs[headIndex] = char
                        // Also stamp a few trailing glyphs with the same character
                        for j in max(0, headIndex - 3)..<headIndex {
                            columns[i].glyphs[j] = char
                        }
                    }
                }
            }

            // Randomly mutate glyphs in the trail (but not recently morphed ones near head)
            if Int.random(in: 0...3) == 0 {
                let idx = Int.random(in: 0..<max(1, columns[i].glyphs.count - 4))
                columns[i].glyphs[idx] = randomGlyph()
            }

            // Reset column when fully off screen
            let totalHeight = CGFloat(columns[i].glyphs.count) * columns[i].fontSize * 1.2
            if columns[i].y - totalHeight > height {
                columns[i].y = -totalHeight - CGFloat.random(in: 0...300)
                columns[i].speed = CGFloat.random(in: 3...10)
                columns[i].fontSize = CGFloat.random(in: rainSize.fontSizeRange)

                // Easter eggs: rare chance a column carries a hidden message
                let roll = Int.random(in: 0...100)
                if roll == 0 {
                    // Apple Weather attribution
                    let msg = Array(" Weather")
                    columns[i].trailLength = msg.count
                    columns[i].glyphs = msg
                } else if roll == 1 {
                    // Claude credit
                    let msg = Array("Engineered by Claude")
                    columns[i].trailLength = msg.count
                    columns[i].glyphs = msg
                } else if roll == 2 {
                    // The developer
                    let msg = Array("Michael Lee Fluharty")
                    columns[i].trailLength = msg.count
                    columns[i].glyphs = msg
                } else {
                    columns[i].trailLength = Int.random(in: 8...25)
                    columns[i].glyphs = (0..<columns[i].trailLength).map { _ in randomGlyph() }
                }
                columns[i].columnColor = randomColumnColor()
            }
        }
    }

    func randomGlyph() -> Character {
        glyphs.randomElement()!
    }

    func randomColumnColor() -> Color {
        let primaryColors: [Color] = [.red, .green, .blue]
        let cgaPalette: [Color] = [
            Color(red: 0.0, green: 0.0, blue: 0.67),
            Color(red: 0.0, green: 0.67, blue: 0.0),
            Color(red: 0.0, green: 0.67, blue: 0.67),
            Color(red: 0.67, green: 0.0, blue: 0.0),
            Color(red: 0.67, green: 0.0, blue: 0.67),
            Color(red: 0.67, green: 0.33, blue: 0.0),
            Color(red: 0.33, green: 0.33, blue: 1.0),
            Color(red: 0.33, green: 1.0, blue: 0.33),
            Color(red: 0.33, green: 1.0, blue: 1.0),
            Color(red: 1.0, green: 0.33, blue: 0.33),
            Color(red: 1.0, green: 0.33, blue: 1.0),
            Color(red: 1.0, green: 1.0, blue: 0.33),
            Color(red: 1.0, green: 1.0, blue: 1.0),
        ]

        switch colorScheme {
        case .randomRGB: return primaryColors.randomElement()!
        case .matrixColors: return primaryColors.randomElement()!
        case .singleColor: return primaryColors.randomElement()!
        case .phosphorGreen: return Color(red: 0.0, green: 1.0, blue: 0.0)
        case .phosphorAmber: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .phosphorBlue: return Color(red: 0.2, green: 0.4, blue: 1.0)
        case .crimson: return Color(red: 0.6, green: 0.0, blue: 0.05)
        case .cgaPhosphor: return cgaPalette.randomElement()!
        }
    }

    func colorForColumn(_ column: RainColumn, brightness: Double) -> Color {
        column.columnColor.opacity(brightness * 0.7)
    }
}

struct RainColumn {
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var fontSize: CGFloat
    var trailLength: Int
    var glyphs: [Character]
    var columnColor: Color
}
