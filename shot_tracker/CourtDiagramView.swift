import SwiftUI

enum CourtDiagramMode {
    case selection
    case readOnly
    case trackingLocked
}

struct CourtDiagramView: View {
    let mode: CourtDiagramMode
    let selectedZoneIDs: Set<Int>
    let activeZoneID: Int?
    let onZoneTapped: (Int) -> Void
    var zoneIntensity: [Int: Double] = [:]

    private let layout: [(Int, CGFloat, CGFloat)] = [
        (1, 0.12, 0.84), (2, 0.13, 0.55), (3, 0.50, 0.36), (4, 0.87, 0.55), (5, 0.88, 0.84),
        (6, 0.28, 0.62), (7, 0.50, 0.60), (8, 0.72, 0.62), (9, 0.34, 0.78), (10, 0.66, 0.78),
        (11, 0.40, 0.88), (12, 0.50, 0.88), (13, 0.60, 0.88), (14, 0.50, 0.70), (15, 0.45, 0.94), (16, 0.55, 0.94)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CourtLines().stroke(.primary.opacity(0.75), lineWidth: 2)
                ForEach(layout, id: \.0) { item in
                    if let zone = zone(for: item.0) {
                        zoneButton(zone, at: CGPoint(x: item.1 * proxy.size.width, y: item.2 * proxy.size.height))
                    }
                }
            }
            .background(Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(.orange.opacity(0.5), lineWidth: 1) }
        }
        .aspectRatio(0.72, contentMode: .fit)
    }

    private func zoneButton(_ zone: CourtZone, at point: CGPoint) -> some View {
        let selected = selectedZoneIDs.contains(zone.id)
        let active = activeZoneID == zone.id
        let heat = zoneIntensity[zone.id] ?? 0
        return Button {
            guard mode == .selection else { return }
            onZoneTapped(zone.id)
        } label: {
            Text("\(zone.id)")
                .font(.caption.bold()).frame(width: 30, height: 30)
                .background(active || selected ? color(for: zone.category) : heat > 0 ? color(for: zone.category).opacity(0.25 + heat * 0.7) : Color(.systemGray5))
                .foregroundStyle(active || selected || heat > 0.5 ? .white : color(for: zone.category))
                .clipShape(Circle())
                .overlay { Circle().stroke(color(for: zone.category), lineWidth: active ? 3 : 2) }
                .shadow(color: active ? color(for: zone.category).opacity(0.65) : .clear, radius: 8)
        }
        .position(point).disabled(mode != .selection)
        .accessibilityLabel(accessibilityLabel(for: zone, selected: selected, active: active))
        .accessibilityHint(mode == .selection ? "Double tap to select this zone." : "Unavailable during active drill.")
    }

    private func accessibilityLabel(for zone: CourtZone, selected: Bool, active: Bool) -> String {
        if active { return "\(zone.name), active tracking zone" }
        if selected { return "\(zone.name), selected" }
        if mode == .trackingLocked { return "\(zone.name), unavailable during active drill" }
        return zone.name
    }

    private func color(for category: ZoneCategory) -> Color {
        switch category {
        case .three: .blue
        case .midrange: .orange
        case .paint: .red
        }
    }
}

struct CourtLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h)); path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h)); path.addLine(to: CGPoint(x: 0, y: h * 0.60))
        path.move(to: CGPoint(x: w, y: h)); path.addLine(to: CGPoint(x: w, y: h * 0.60))
        path.addRect(CGRect(x: w * 0.30, y: h * 0.70, width: w * 0.40, height: h * 0.30))
        path.move(to: CGPoint(x: w * 0.30, y: h * 0.70)); path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.70))
        path.addEllipse(in: CGRect(x: w * 0.36, y: h * 0.62, width: w * 0.28, height: h * 0.20))
        path.addArc(center: CGPoint(x: w * 0.50, y: h * 0.88), radius: w * 0.12, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addArc(center: CGPoint(x: w * 0.50, y: h * 0.90), radius: w * 0.43, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        path.move(to: CGPoint(x: w * 0.07, y: h)); path.addLine(to: CGPoint(x: w * 0.07, y: h * 0.80))
        path.move(to: CGPoint(x: w * 0.93, y: h)); path.addLine(to: CGPoint(x: w * 0.93, y: h * 0.80))
        path.addRect(CGRect(x: w * 0.40, y: h * 0.94, width: w * 0.20, height: 3))
        path.addEllipse(in: CGRect(x: w * 0.47, y: h * 0.90, width: w * 0.06, height: w * 0.06))
        return path
    }
}
