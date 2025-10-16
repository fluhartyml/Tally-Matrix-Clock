//
//  ContentView.swift
//  Tally Matrix Clock
//
//  tvOS Tally Matrix Clock with 12/24hr toggle and pattern animations
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var currentTime = Date()
    @State private var showSettings = false
    @State private var showBase10 = true
    @State private var use24Hour = true
    @State private var colorScheme: ColorSchemeOption = .randomRGB
    @State private var patternInterval: Double = 60.0
    
    @State private var patterns: [Int: Set<Int>] = [:]
    @State private var colors: [Int: [Color]] = [:]
    @State private var lastPatternChange = Date()
    
    @FocusState private var isFocused: Bool
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                HStack(spacing: 0) {
                    TallyMatrix1x3(value: hoursTens, pattern: patterns[0] ?? [], colors: colors[0] ?? [], isPMIndicator: !use24Hour, showPM: isPM)
                    Spacer().frame(width: 40)
                    TallyMatrix3x3(value: hoursOnes, pattern: patterns[1] ?? [], colors: colors[1] ?? [])
                    Spacer().frame(width: 120)
                    TallyMatrix3x3(value: minutesTens, pattern: patterns[2] ?? [], colors: colors[2] ?? [])
                    Spacer().frame(width: 40)
                    TallyMatrix3x3(value: minutesOnes, pattern: patterns[3] ?? [], colors: colors[3] ?? [])
                }
                
                Spacer()
                
                if showBase10 {
                    Text(baseTimeString)
                        .font(.system(size: 60, weight: .thin, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer().frame(height: 100)
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
            updatePatterns()
            lastPatternChange = Date()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            
            let elapsed = Date().timeIntervalSince(lastPatternChange)
            if elapsed >= patternInterval {
                withAnimation(.easeInOut(duration: 0.5)) {
                    updatePatterns()
                }
                lastPatternChange = Date()
            }
        }
        .onMoveCommand { direction in
            showSettings = true
        }
        .onPlayPauseCommand {
            showSettings = true
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(showBase10: $showBase10, use24Hour: $use24Hour, colorScheme: $colorScheme, patternInterval: $patternInterval)
                .onDisappear {
                    currentTime = Date()
                    updatePatterns()
                    lastPatternChange = Date()
                    isFocused = true
                }
        }
    }
    
    var displayHour: Int {
        let hour = Calendar.current.component(.hour, from: currentTime)
        if use24Hour {
            return hour
        } else {
            let hour12 = hour % 12
            return hour12 == 0 ? 12 : hour12
        }
    }
    
    var isPM: Bool {
        Calendar.current.component(.hour, from: currentTime) >= 12
    }
    
    var hoursTens: Int { displayHour / 10 }
    var hoursOnes: Int { displayHour % 10 }
    var minutesTens: Int { Calendar.current.component(.minute, from: currentTime) / 10 }
    var minutesOnes: Int { Calendar.current.component(.minute, from: currentTime) % 10 }

    var baseTimeString: String {
        let format = use24Hour ? "HH:mm" : "h:mm a"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter.string(from: currentTime)
    }
    
    func updatePatterns() {
        patterns[0] = randomPattern(for: hoursTens, totalSquares: 3)
        patterns[1] = randomPattern(for: hoursOnes, totalSquares: 9)
        patterns[2] = randomPattern(for: minutesTens, totalSquares: 9)
        patterns[3] = randomPattern(for: minutesOnes, totalSquares: 9)
        colors[0] = generateColors(for: 0, count: 3)
        colors[1] = generateColors(for: 1, count: 9)
        colors[2] = generateColors(for: 2, count: 9)
        colors[3] = generateColors(for: 3, count: 9)
    }
    
    func randomPattern(for value: Int, totalSquares: Int) -> Set<Int> {
        guard value > 0 else { return [] }
        var pattern = Set<Int>()
        while pattern.count < value {
            pattern.insert(Int.random(in: 0..<totalSquares))
        }
        return pattern
    }
    
    func generateColors(for matrixIndex: Int, count: Int) -> [Color] {
        let primaryColors: [Color] = [.red, .green, .blue]
        switch colorScheme {
        case .randomRGB:
            return (0..<count).map { _ in primaryColors.randomElement()! }
        case .matrixColors:
            let c = primaryColors.randomElement()!
            return Array(repeating: c, count: count)
        case .singleColor:
            let c = primaryColors.randomElement()!
            return Array(repeating: c, count: count)
        }
    }
}

struct TallyMatrix1x3: View {
    let value: Int
    let pattern: Set<Int>
    let colors: [Color]
    var isPMIndicator: Bool = false
    var showPM: Bool = false
    
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
                    color: colors.indices.contains(i) ? colors[i] : .red
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
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { col in
                        let i = row * 3 + col
                        SquareView(
                            isLit: pattern.contains(i),
                            color: colors.indices.contains(i) ? colors[i] : .red
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
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isLit ? color : Color(white: 0.08))
            .animation(.easeInOut(duration: 0.5), value: isLit)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showBase10: Bool
    @Binding var use24Hour: Bool
    @Binding var colorScheme: ColorSchemeOption
    @Binding var patternInterval: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Settings")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        HStack {
                            Text("Show Base-10 Time")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $showBase10)
                                .labelsHidden()
                        }
                        
                        HStack {
                            Text("24-Hour Clock")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $use24Hour)
                                .labelsHidden()
                        }
                        
                        Divider().background(Color.white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Color Scheme")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            
                            ForEach(ColorSchemeOption.allCases, id: \.self) { opt in
                                Button {
                                    colorScheme = opt
                                } label: {
                                    HStack {
                                        Image(systemName: colorScheme == opt ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 28))
                                        Text(opt.rawValue)
                                            .font(.system(size: 30))
                                        Spacer()
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Divider().background(Color.white.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Pattern Change Interval")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                IntervalButton(interval: 5.0, currentInterval: $patternInterval)
                                IntervalButton(interval: 15.0, currentInterval: $patternInterval)
                                IntervalButton(interval: 30.0, currentInterval: $patternInterval)
                                IntervalButton(interval: 60.0, currentInterval: $patternInterval)
                            }
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.bottom, 30)
                }
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 60)
                .padding(.vertical, 20)
                .background(Color.blue)
                .cornerRadius(12)
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
    }
}

struct IntervalButton: View {
    let interval: Double
    @Binding var currentInterval: Double
    
    var body: some View {
        Button {
            currentInterval = interval
        } label: {
            Text("\(Int(interval))s")
                .font(.system(size: 32))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(currentInterval == interval ? Color.blue : Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

enum ColorSchemeOption: String, CaseIterable {
    case randomRGB = "Random RGB (Each Square)"
    case matrixColors = "Matrix Colors (Per Matrix)"
    case singleColor = "Single Color (All Matrices)"
}

#Preview {
    ContentView()
}
