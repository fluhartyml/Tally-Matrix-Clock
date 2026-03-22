//
//  ContentView.swift
//  Tally Matrix Clock
//
//  tvOS Tally Matrix Clock with 12/24hr toggle and pattern animations
//

import SwiftUI
import Combine
import WeatherKit
import CoreLocation

struct ContentView: View {
    @State private var currentTime = Date()
    @State private var showSettings = false
    @State private var showBase10 = true
    @State private var use24Hour = true
    @State private var showDate = false
    @State private var showWeather = false
    @State private var colorScheme: ColorSchemeOption = .randomRGB
    @State private var patternInterval: Double = 60.0

    @State private var patterns: [Int: Set<Int>] = [:]
    @State private var colors: [Int: [Color]] = [:]
    @State private var lastPatternChange = Date()
    @State private var lastDigits: [Int] = [-1, -1, -1, -1]

    @State private var weatherCondition: String = ""
    @State private var weatherTemp: String = ""
    @State private var weatherSymbol: String = ""
    @State private var lastWeatherFetch = Date.distantPast

    @StateObject private var locationManager = LocationManager()

    @FocusState private var isFocused: Bool

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                HStack(spacing: 0) {
                    TallyMatrix1x3(value: hoursTens, pattern: patterns[0] ?? [], colors: colors[0] ?? [], isPMIndicator: !use24Hour, showPM: isPM, glow: colorScheme == .phosphorGreen || colorScheme == .phosphorAmber || colorScheme == .cgaPhosphor)
                    Spacer().frame(width: 40)
                    TallyMatrix3x3(value: hoursOnes, pattern: patterns[1] ?? [], colors: colors[1] ?? [], glow: colorScheme == .phosphorGreen || colorScheme == .phosphorAmber || colorScheme == .cgaPhosphor)
                    Spacer().frame(width: 120)
                    TallyMatrix3x3(value: minutesTens, pattern: patterns[2] ?? [], colors: colors[2] ?? [], glow: colorScheme == .phosphorGreen || colorScheme == .phosphorAmber || colorScheme == .cgaPhosphor)
                    Spacer().frame(width: 40)
                    TallyMatrix3x3(value: minutesOnes, pattern: patterns[3] ?? [], colors: colors[3] ?? [], glow: colorScheme == .phosphorGreen || colorScheme == .phosphorAmber || colorScheme == .cgaPhosphor)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    if showBase10 {
                        Text(baseTimeString)
                            .font(.system(size: 60, weight: .thin, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    if showDate {
                        Text(dateString)
                            .font(.system(size: 40, weight: .thin))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    if showWeather && !weatherTemp.isEmpty {
                        HStack(spacing: 12) {
                            if !weatherSymbol.isEmpty {
                                Image(systemName: weatherSymbol)
                                    .font(.system(size: 36))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Text(weatherTemp)
                                .font(.system(size: 40, weight: .thin, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text(weatherCondition)
                                .font(.system(size: 36, weight: .thin))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
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
            fetchWeather()
        }
        .onReceive(timer) { _ in
            currentTime = Date()

            // Check if any digit changed — if so, update patterns immediately
            let currentDigits = [hoursTens, hoursOnes, minutesTens, minutesOnes]
            let digitsChanged = currentDigits != lastDigits

            if digitsChanged {
                lastDigits = currentDigits
                withAnimation(.easeInOut(duration: 0.5)) {
                    updatePatterns()
                }
                lastPatternChange = Date()
            } else {
                // Still shuffle patterns on the interval for visual variety
                let elapsed = Date().timeIntervalSince(lastPatternChange)
                if elapsed >= patternInterval {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        updatePatterns()
                    }
                    lastPatternChange = Date()
                }
            }

            // Refresh weather periodically
            fetchWeather()
        }
        .onMoveCommand { direction in
            showSettings = true
        }
        .onPlayPauseCommand {
            showSettings = true
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(showBase10: $showBase10, use24Hour: $use24Hour, showDate: $showDate, showWeather: $showWeather, colorScheme: $colorScheme, patternInterval: $patternInterval)
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

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }

    func fetchWeather() {
        guard showWeather else { return }
        guard let location = locationManager.location else { return }
        // Only fetch every 15 minutes
        guard Date().timeIntervalSince(lastWeatherFetch) > 900 else { return }
        lastWeatherFetch = Date()

        Task {
            do {
                let weather = try await WeatherService.shared.weather(for: location)
                let current = weather.currentWeather
                let temp = current.temperature
                let tempString = String(format: "%.0f°%@", temp.converted(to: .fahrenheit).value, "F")
                let condition = current.condition.description
                let symbol = current.symbolName

                await MainActor.run {
                    weatherTemp = tempString
                    weatherCondition = condition
                    weatherSymbol = symbol
                }
            } catch {
                // Silently fail — weather is optional
            }
        }
    }
    
    func updatePatterns() {
        patterns[0] = randomPattern(for: hoursTens, totalSquares: 3)
        patterns[1] = randomPattern(for: hoursOnes, totalSquares: 9)
        patterns[2] = randomPattern(for: minutesTens, totalSquares: 9)
        patterns[3] = randomPattern(for: minutesOnes, totalSquares: 9)

        // For singleColor, pick one color and share across all matrices
        let sharedColor: Color? = colorScheme == .singleColor
            ? [Color.red, .green, .blue].randomElement()!
            : nil

        colors[0] = generateColors(for: 0, count: 3, shared: sharedColor)
        colors[1] = generateColors(for: 1, count: 9, shared: sharedColor)
        colors[2] = generateColors(for: 2, count: 9, shared: sharedColor)
        colors[3] = generateColors(for: 3, count: 9, shared: sharedColor)
    }
    
    func randomPattern(for value: Int, totalSquares: Int) -> Set<Int> {
        guard value > 0 else { return [] }
        var pattern = Set<Int>()
        while pattern.count < value {
            pattern.insert(Int.random(in: 0..<totalSquares))
        }
        return pattern
    }
    
    func generateColors(for matrixIndex: Int, count: Int, shared: Color? = nil) -> [Color] {
        let primaryColors: [Color] = [.red, .green, .blue]
        switch colorScheme {
        case .randomRGB:
            return (0..<count).map { _ in primaryColors.randomElement()! }
        case .matrixColors:
            let c = primaryColors.randomElement()!
            return Array(repeating: c, count: count)
        case .singleColor:
            return Array(repeating: shared ?? primaryColors.randomElement()!, count: count)
        case .phosphorGreen:
            return Array(repeating: Color(red: 0.0, green: 1.0, blue: 0.0), count: count)
        case .phosphorAmber:
            return Array(repeating: Color(red: 1.0, green: 0.75, blue: 0.0), count: count)
        case .cgaPhosphor:
            let cgaPalette: [Color] = [
                Color(red: 0.0, green: 0.0, blue: 0.67),   // Blue
                Color(red: 0.0, green: 0.67, blue: 0.0),   // Green
                Color(red: 0.0, green: 0.67, blue: 0.67),  // Cyan
                Color(red: 0.67, green: 0.0, blue: 0.0),   // Red
                Color(red: 0.67, green: 0.0, blue: 0.67),  // Magenta
                Color(red: 0.67, green: 0.33, blue: 0.0),  // Brown
                Color(red: 0.33, green: 0.33, blue: 1.0),  // Light Blue
                Color(red: 0.33, green: 1.0, blue: 0.33),  // Light Green
                Color(red: 0.33, green: 1.0, blue: 1.0),   // Light Cyan
                Color(red: 1.0, green: 0.33, blue: 0.33),  // Light Red
                Color(red: 1.0, green: 0.33, blue: 1.0),   // Light Magenta
                Color(red: 1.0, green: 1.0, blue: 0.33),   // Yellow
                Color(red: 1.0, green: 1.0, blue: 1.0),    // White
            ]
            return (0..<count).map { _ in cgaPalette.randomElement()! }
        }
    }
}

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

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showBase10: Bool
    @Binding var use24Hour: Bool
    @Binding var showDate: Bool
    @Binding var showWeather: Bool
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

                        HStack {
                            Text("Show Date")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $showDate)
                                .labelsHidden()
                        }

                        HStack {
                            Text("Show Weather")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $showWeather)
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
    case phosphorGreen = "Phosphor Green (Glow)"
    case phosphorAmber = "Amber Phosphor (Glow)"
    case cgaPhosphor = "CGA Phosphor (Glow)"
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location is optional — silently fail
    }
}

#Preview {
    ContentView()
}
