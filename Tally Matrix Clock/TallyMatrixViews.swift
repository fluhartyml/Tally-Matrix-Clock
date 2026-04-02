//
//  TallyMatrixViews.swift
//  Tally Matrix Clock
//

import SwiftUI

struct TallyMatrix1x3: View {
    let value: Int
    let pattern: Set<Int>
    let colors: [Color]
    var isPMIndicator: Bool = false
    var showPM: Bool = false
    var glow: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                let shouldLight: Bool = {
                    if isPMIndicator && i == 2 {
                        return showPM
                    } else {
                        return pattern.contains(i)
                    }
                }()

                SquareView(
                    isLit: shouldLight,
                    color: colors.indices.contains(i) ? colors[i] : .red,
                    glow: glow
                )
                .frame(width: 80, height: 80)
                .animation(isPMIndicator && i == 2 ? .none : .easeInOut(duration: 0.5), value: shouldLight)
            }
        }
    }
}

struct TallyMatrix3x3: View {
    let value: Int
    let pattern: Set<Int>
    let colors: [Color]
    var glow: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { col in
                        let i = row * 3 + col
                        SquareView(
                            isLit: pattern.contains(i),
                            color: colors.indices.contains(i) ? colors[i] : .red,
                            glow: glow
                        )
                        .frame(width: 80, height: 80)
                    }
                }
            }
        }
    }
}

struct SquareView: View {
    let isLit: Bool
    let color: Color
    var glow: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isLit ? color : Color(white: 0.08))
            .shadow(color: isLit && glow ? color.opacity(0.8) : .clear, radius: 16)
            .shadow(color: isLit && glow ? color.opacity(0.4) : .clear, radius: 32)
            .animation(.easeInOut(duration: 0.5), value: isLit)
    }
}
