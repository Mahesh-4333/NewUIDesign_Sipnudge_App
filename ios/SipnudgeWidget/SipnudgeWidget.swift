import WidgetKit
import SwiftUI

struct SlotItem: Codable {
    let label: String
    let hour: Int
    let minute: Int
    let target: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), intake: 0, goal: 2000, upcomingSlotName: "Wakeup Time", upcomingSlotTarget: 500, upcomingSlotTime: "07:00 AM", streak: 7,
                    dbgUUID: "-", dbgConnected: "-", dbgSubscribed: "-", dbgBleRx: "-")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), intake: 750, goal: 2500, upcomingSlotName: "Lunch Time", upcomingSlotTarget: 300, upcomingSlotTime: "01:00 PM", streak: 7,
                                dbgUUID: "-", dbgConnected: "-", dbgSubscribed: "-", dbgBleRx: "-")
        completion(entry)
    }

    private func createEntry(for date: Date, userDefaults: UserDefaults?) -> SimpleEntry {
        let lastUpdateDateStr = userDefaults?.string(forKey: "last_update_date") ?? ""
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let todayStr = formatter.string(from: date)
        
        var intake = userDefaults?.integer(forKey: "current_intake") ?? 0
        if lastUpdateDateStr != todayStr {
            intake = 0
        }
        
        let goal = userDefaults?.integer(forKey: "daily_goal") ?? 2000
        let streak = userDefaults?.integer(forKey: "streak") ?? 0
        
        var upcomingSlotName = userDefaults?.string(forKey: "upcoming_slot_name") ?? "Next Slot"
        var upcomingSlotTarget = userDefaults?.integer(forKey: "upcoming_slot_target") ?? 0
        var upcomingSlotTime = userDefaults?.string(forKey: "upcoming_slot_time") ?? "--:--"
        
        // Dynamically compute the upcoming slot if slots JSON is available
        if let slotsJsonString = userDefaults?.string(forKey: "all_slots_json"),
           let data = slotsJsonString.data(using: .utf8) {
            let decoder = JSONDecoder()
            if let slots = try? decoder.decode([SlotItem].self, from: data), !slots.isEmpty {
                let calendar = Calendar.current
                let nowHour = calendar.component(.hour, from: date)
                let nowMinute = calendar.component(.minute, from: date)
                let nowTotalMinutes = nowHour * 60 + nowMinute
                
                // Sort slots by time
                let sortedSlots = slots.sorted { (a, b) -> Bool in
                    let aMin = a.hour * 60 + a.minute
                    let bMin = b.hour * 60 + b.minute
                    return aMin < bMin
                }
                
                // Find first slot that starts after now
                var foundSlot: SlotItem?
                for slot in sortedSlots {
                    let slotTotalMinutes = slot.hour * 60 + slot.minute
                    if slotTotalMinutes > nowTotalMinutes {
                        foundSlot = slot
                        break
                    }
                }
                
                // Fallback to first slot of the next day
                let upcomingSlot = foundSlot ?? sortedSlots.first!
                
                upcomingSlotName = upcomingSlot.label
                upcomingSlotTarget = upcomingSlot.target
                
                // Format time string
                let hour12 = upcomingSlot.hour % 12 == 0 ? 12 : upcomingSlot.hour % 12
                let period = upcomingSlot.hour < 12 ? "AM" : "PM"
                let minStr = String(format: "%02d", upcomingSlot.minute)
                upcomingSlotTime = "\(hour12):\(minStr) \(period)"
            }
        }
        
        return SimpleEntry(date: date, intake: intake, goal: goal, upcomingSlotName: upcomingSlotName, upcomingSlotTarget: upcomingSlotTarget, upcomingSlotTime: upcomingSlotTime, streak: streak,
                           dbgUUID: userDefaults?.string(forKey: "dbg_uuid") ?? "nil",
                           dbgConnected: userDefaults?.string(forKey: "dbg_connected") ?? "nil",
                           dbgSubscribed: userDefaults?.string(forKey: "dbg_subscribed") ?? "nil",
                           dbgBleRx: userDefaults?.string(forKey: "dbg_ble_rx") ?? "nil")
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Access shared UserDefaults via the App Group
        let userDefaults = UserDefaults(suiteName: "group.com.sipnudge.sipnudge")
        let now = Date()
        
        let calendar = Calendar.current
        let midnight: Date
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: now) {
            midnight = calendar.startOfDay(for: nextDay)
        } else {
            midnight = now.addingTimeInterval(86400) // 24 hours fallback
        }
        
        // Define fallback timeline compilation
        let compileTimeline: () -> Timeline<Entry> = {
            let entryNow = self.createEntry(for: now, userDefaults: userDefaults)
            let entryMidnight = self.createEntry(for: midnight, userDefaults: userDefaults)
            let nextUpdate = calendar.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(300)
            return Timeline(entries: [entryNow, entryMidnight], policy: .after(nextUpdate))
        }

        // Try getting userId to fetch from server
        guard let userId = userDefaults?.string(forKey: "flutter.user_id")
                ?? userDefaults?.string(forKey: "user_id") else {
            completion(compileTimeline())
            return
        }

        // Format dates for API query
        let todayStart = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart.addingTimeInterval(86400)
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let startDateStr = isoFormatter.string(from: todayStart)
        let endDateStr = isoFormatter.string(from: tomorrowStart)
        
        var components = URLComponents(string: "https://api.sipnudge.com/api/database/daily-summaries/\(userId)")
        components?.queryItems = [
            URLQueryItem(name: "startDate", value: startDateStr),
            URLQueryItem(name: "endDate", value: endDateStr)
        ]
        
        guard let url = components?.url else {
            completion(compileTimeline())
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error == nil,
               let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let list = json["data"] as? [[String: Any]],
               let first = list.first {
                
                let consumed = first["consumed"] as? Double ?? Double(first["consumed"] as? Int ?? 0)
                let target = first["target"] as? Double ?? Double(first["target"] as? Int ?? 2500)
                
                userDefaults?.set(Int(consumed), forKey: "current_intake")
                userDefaults?.set(Int(target), forKey: "daily_goal")
                
                let todayFormatter = DateFormatter()
                todayFormatter.dateFormat = "yyyy-MM-dd"
                todayFormatter.timeZone = .current
                userDefaults?.set(todayFormatter.string(from: now), forKey: "last_update_date")
                userDefaults?.synchronize()
            }
            completion(compileTimeline())
        }
        task.resume()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let intake: Int
    let goal: Int
    let upcomingSlotName: String
    let upcomingSlotTarget: Int
    let upcomingSlotTime: String
    let streak: Int
    // Diagnostics — only populated in debug builds
    let dbgUUID: String
    let dbgConnected: String
    let dbgSubscribed: String
    let dbgBleRx: String
}

struct SipnudgeWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var progress: Double {
        guard entry.goal > 0 else { return 0.0 }
        return min(Double(entry.intake) / Double(entry.goal), 1.0)
    }

    var headingText: String {
        progress >= 0.5 ? "You're on track" : "Keep sipping 💧"
    }

    var percentageString: String {
        guard entry.goal > 0 else { return "0%" }
        let pct = Int((Double(entry.intake) / Double(entry.goal)) * 100)
        return "\(pct)%"
    }

    var body: some View {
        switch family {
        case .systemSmall:
            smallLayout
                .environment(\.colorScheme, .light)
                .containerBackground(Color.white, for: .widget)
        case .systemMedium:
            mediumLayout
                .environment(\.colorScheme, .light)
                .containerBackground(Color.white, for: .widget)
        case .accessoryCircular:
            accessoryCircularLayout
                .containerBackground(Color.clear, for: .widget)
        case .accessoryRectangular:
            accessoryRectangularLayout
                .containerBackground(Color.clear, for: .widget)
        case .accessoryInline:
            accessoryInlineLayout
                .containerBackground(Color.clear, for: .widget)
        default:
            smallLayout
                .environment(\.colorScheme, .light)
                .containerBackground(Color.white, for: .widget)
        }
    }

    // MARK: - Lock Screen Layouts
    private var accessoryCircularLayout: some View {
        Gauge(value: progress, in: 0...1) {
            Image(systemName: "drop.fill")
        } currentValueLabel: {
            Text(percentageString)
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var accessoryRectangularLayout: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                Text("\(entry.intake)/\(entry.goal)ml")
                    .font(.system(.headline, design: .rounded))
                    .bold()
            }
            
            Text("Next: \(entry.upcomingSlotName) (\(entry.upcomingSlotTime))")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
            
            ProgressView(value: progress, total: 1.0)
        }
    }

    private var accessoryInlineLayout: some View {
        Text("💧 \(entry.intake)ml (\(percentageString))")
    }

    func formatNumber(_ val: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: val)) ?? "\(val)"
    }

    // MARK: - Medium Layout
    private var mediumLayout: some View {
        HStack(spacing: 40) {
            // Left Side: Circular Progress Ring
            VStack(spacing: 10) {
                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color(red: 0.92, green: 0.93, blue: 0.95), lineWidth: 8)
                    
                    // Progress arc
                    Circle()
                        .trim(from: 0.0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 180/255.0, green: 217/255.0, blue: 255/255.0),
                                    Color(red: 0.00, green: 0.48, blue: 1.00)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(Angle(degrees: -90))
                    
                    VStack(spacing: 1) {
                        Text(percentageString)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                        
                        Text("TODAY")
                            .font(.system(size: 7, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.70))
                            .tracking(1.0)
                    }
                }
                .frame(width: 86, height: 86)
                
                // ml count below ring
                (Text(formatNumber(entry.intake))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                 + Text(" / \(formatNumber(entry.goal)) ml")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 85/255.0, green: 104/255.0, blue: 127/255.0)))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 6)
            }
            
            // Right Side: Details
            VStack(alignment: .leading, spacing: 4) {
                // Streak Badge
                HStack(spacing: 4) {
                    Image(systemName: "drop")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color(red: 0.00, green: 0.48, blue: 1.00))
                    Text("\(entry.streak) DAY STREAK")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.00, green: 0.48, blue: 1.00))
                        .tracking(0.5)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(red: 0.92, green: 0.96, blue: 1.00))
                .cornerRadius(20)
                
                // Heading
                Text(headingText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Info rows
                VStack(alignment: .leading, spacing: 0) {
                    // Row 1: Next Sip
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.92, green: 0.96, blue: 1.00))
                                .frame(width: 28, height: 28)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.00, green: 0.48, blue: 1.00))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Next sip")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 77/255.0, green: 117/255.0, blue: 139/255.0))
                            Text(entry.upcomingSlotTime)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 77/255.0, green: 117/255.0, blue: 139/255.0))
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                        .padding(.leading, 36)
                        .padding(.vertical, 2)
                    
                    // Row 2: Water Left
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.92, green: 0.96, blue: 1.00))
                                .frame(width: 28, height: 28)
                            Image(systemName: "drop")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.00, green: 0.48, blue: 1.00))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Only")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 77/255.0, green: 117/255.0, blue: 139/255.0))
                            Text("\(formatNumber(max(0, entry.goal - entry.intake))) ml left")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 77/255.0, green: 117/255.0, blue: 139/255.0))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Small Layout
    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Header row
            HStack(alignment: .center) {
                Text("💧")
                    .font(.system(size: 11))
                Text("Hydration")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.70))
                Spacer()
                Text(percentageString)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.10, green: 0.48, blue: 0.96))
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.90, green: 0.93, blue: 0.98))
                        .frame(height: 7)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.10, green: 0.48, blue: 0.96),
                                    Color(red: 0.0, green: 0.78, blue: 0.97)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(7, geometry.size.width * CGFloat(progress)), height: 7)
                }
            }
            .frame(height: 7)
            
            // ml count
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(formatNumber(entry.intake))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.04, green: 0.10, blue: 0.20))
                Text(" / \(formatNumber(entry.goal)) ml")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.70))
            }
            .padding(.bottom, 1)
            
            // Next Nudge card
            VStack(alignment: .leading, spacing: 2) {
                Text("NEXT NUDGE")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.10, green: 0.48, blue: 0.96))
                    .tracking(0.5)
                
                Text(entry.upcomingSlotName)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.04, green: 0.10, blue: 0.20))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.70))
                    Text("\(entry.upcomingSlotTime)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.70))
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.75, green: 0.78, blue: 0.85))
                    Text("\(entry.upcomingSlotTarget) ml")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.70))
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.91, green: 0.95, blue: 1.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0.10, green: 0.48, blue: 0.96).opacity(0.18), lineWidth: 1.0)
                    )
            )
        }
        .padding(12)
    }
}

struct SipnudgeWidget: Widget {
    let kind: String = "SipnudgeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SipnudgeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hydration Widget")
        .description("Shows your current hydration progress.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// Extension to handle backwards compatibility for container background
extension View {
    func containerBackground(_ color: Color, for widget: WidgetBackground) -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(for: .widget) { color }
        } else {
            return self.background(color)
        }
    }
}

enum WidgetBackground {}
