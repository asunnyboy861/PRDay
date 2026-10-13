import SwiftUI

extension Color {
    static let prBase = Color(red: 0.043, green: 0.059, blue: 0.078)
    static let prSurface = Color(red: 0.078, green: 0.102, blue: 0.133)
    static let prSurfaceAlt = Color(red: 0.11, green: 0.14, blue: 0.18)
    static let prOrange = Color(red: 1.0, green: 0.42, blue: 0.173)
    static let prHeatGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let prHeatYellow = Color(red: 1.0, green: 0.84, blue: 0.04)
    static let prHeatOrange = Color(red: 1.0, green: 0.62, blue: 0.04)
    static let prHeatRed = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let prHeatBlack = Color(red: 0.11, green: 0.11, blue: 0.12)

    static func heat(_ flag: HeatFlag) -> Color {
        switch flag {
        case .green: return .prHeatGreen
        case .yellow: return .prHeatYellow
        case .orange: return .prHeatOrange
        case .red: return .prHeatRed
        case .black: return .prHeatBlack
        }
    }
}

extension ShapeStyle where Self == Color {
    static var prBase: Color { .init(red: 0.043, green: 0.059, blue: 0.078) }
    static var prSurface: Color { .init(red: 0.078, green: 0.102, blue: 0.133) }
    static var prSurfaceAlt: Color { .init(red: 0.11, green: 0.14, blue: 0.18) }
    static var prOrange: Color { .init(red: 1.0, green: 0.42, blue: 0.173) }
    static var prHeatGreen: Color { .init(red: 0.20, green: 0.78, blue: 0.35) }
    static var prHeatYellow: Color { .init(red: 1.0, green: 0.84, blue: 0.04) }
    static var prHeatOrange: Color { .init(red: 1.0, green: 0.62, blue: 0.04) }
    static var prHeatRed: Color { .init(red: 1.0, green: 0.23, blue: 0.19) }
    static var prHeatBlack: Color { .init(red: 0.11, green: 0.11, blue: 0.12) }
}

enum Theme {
    static let baseURL = "https://asunnyboy861.github.io/PRDay"
    static let supportURL = URL(string: "\(baseURL)/support.html")!
    static let privacyURL = URL(string: "\(baseURL)/privacy.html")!
    static let termsURL = URL(string: "\(baseURL)/terms.html")!
    static let appleWeatherLegalURL = URL(string: "https://weather.apple.com/legal")!
    static let disclaimer = "For training guidance only. Not medical advice."
}

struct FlagChip: View {
    let flag: HeatFlag

    private var label: String {
        switch flag {
        case .green: return "Green Flag"
        case .yellow: return "Yellow Flag"
        case .orange: return "Orange Flag"
        case .red: return "Red Flag"
        case .black: return "Black Flag"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.heat(flag))
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.heat(flag).opacity(0.16), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.heat(flag).opacity(0.5), lineWidth: 1))
        .accessibilityLabel("Heat risk \(label)")
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(.prOrange)
        .accessibilityLabel(title)
    }
}

struct ScoreboardText: View {
    let value: String
    var size: CGFloat = 64

    var body: some View {
        Text(value)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }
}

struct DisclaimerFooter: View {
    var body: some View {
        Text(Theme.disclaimer)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .accessibilityLabel(Theme.disclaimer)
    }
}

struct WeatherAttribution: View {
    var compact = false

    var body: some View {
        if compact {
            HStack(spacing: 4) {
                Image(systemName: "apple.logo")
                Text("Weather")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Data from Apple Weather")
        } else {
            Link(destination: Theme.appleWeatherLegalURL) {
                HStack(spacing: 4) {
                    Image(systemName: "apple.logo")
                    Text("Weather — Data Source")
                }
                .font(.footnote)
            }
        }
    }
}

struct ConfettiView: View {
    struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let duration: Double
        let size: CGFloat
        let color: Color
        let rotation: Double
    }

    let trigger: UUID

    private var pieces: [Piece] {
        let palette: [Color] = [.prOrange, .prHeatYellow, .prHeatGreen, .white, .prHeatRed]
        return (0..<70).map { i in
            Piece(
                x: CGFloat.random(in: 0...1),
                delay: Double(i) * 0.012,
                duration: Double.random(in: 1.8...3.0),
                size: CGFloat.random(in: 6...12),
                color: palette[i % palette.count],
                rotation: Double.random(in: 0...360)
            )
        }
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    for p in pieces {
                        let local = ((t + p.delay).truncatingRemainder(dividingBy: p.duration)) / p.duration
                        let y = local * (size.height + 80) - 40
                        let sway = sin((t * 3) + p.rotation) * 18
                        let rect = CGRect(x: p.x * size.width + sway, y: y, width: p.size, height: p.size * 0.6)
                        context.opacity = 1.0 - local * 0.55
                        context.rotate(by: .degrees(p.rotation * local))
                        context.fill(Path(rect), with: .color(p.color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .id(trigger)
        .accessibilityHidden(true)
    }
}
