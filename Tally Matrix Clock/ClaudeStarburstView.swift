//
//  ClaudeStarburstView.swift
//  Tally Matrix Clock
//

import SwiftUI

struct ClaudeStarburstView: View {
    let terracotta = Color(red: 0.85, green: 0.55, blue: 0.35)

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerRadius = min(size.width, size.height) / 2
            let innerRadius = outerRadius * 0.35
            let points = 8

            var path = Path()
            for i in 0..<(points * 2) {
                let angle = (Double(i) * .pi / Double(points)) - .pi / 2
                let radius = i % 2 == 0 ? outerRadius : innerRadius
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()

            context.fill(path, with: .color(terracotta))
        }
    }
}
