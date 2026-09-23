import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

// MARK: - Refresh Widget Intent

@available(iOS 16.0, *)
struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget"
    static var description = IntentDescription("Refreshes the family hydration widget data")

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Data Models

struct FamilyMemberData: Codable {
    let name: String
    let consumed: Int
    let target: Int
    let percentage: Int
    let accentColor: String
}

struct FamilyEntry: TimelineEntry {
    let date: Date
    let intake: Int
    let goal: Int
    let battery: Int
    let expectedPercent: Double
    let upcomingSlotTime: String
    let upcomingSlotName: String
    let familyMembers: [FamilyMemberData]
}

// MARK: - Timeline Provider

struct FamilyProvider: TimelineProvider {
    func placeholder(in context: Context) -> FamilyEntry {
        FamilyEntry(
            date: Date(), intake: 2280, goal: 3000, battery: 72, expectedPercent: 76.0,
            upcomingSlotTime: "4:00 PM", upcomingSlotName: "Afternoon",
            familyMembers: [
                FamilyMemberData(name: "Mom", consumed: 1900, target: 2500, percentage: 76, accentColor: "#F97316"),
                FamilyMemberData(name: "Dad", consumed: 1800, target: 3000, percentage: 60, accentColor: "#2563EB"),
                FamilyMemberData(name: "Alex", consumed: 600, target: 2500, percentage: 24, accentColor: "#10B981"),
                FamilyMemberData(name: "Brother", consumed: 1900, target: 2500, percentage: 80, accentColor: "#8B5CF6")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FamilyEntry) -> ()) {
        completion(placeholder(in: context))
    }

    private func createEntry(for date: Date, userDefaults: UserDefaults?) -> FamilyEntry {
        let lastUpdateDateStr = userDefaults?.string(forKey: "last_update_date") ?? ""
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let todayStr = formatter.string(from: date)
        let isNewDay = lastUpdateDateStr != todayStr && !lastUpdateDateStr.isEmpty

        var intake = userDefaults?.integer(forKey: "current_intake") ?? 0
        if isNewDay { intake = 0 }

        let storedGoal = (userDefaults?.object(forKey: "daily_goal") as? NSNumber)?.intValue
            ?? userDefaults?.integer(forKey: "daily_goal") ?? 0
        let goal = storedGoal > 0 ? storedGoal : 3000

        let storedBattery = userDefaults?.object(forKey: "battery") as? Int ?? userDefaults?.integer(forKey: "battery") ?? 0
        let battery = storedBattery > 0 ? storedBattery : 72

        let upcomingSlotTime = userDefaults?.string(forKey: "upcoming_slot_time") ?? "4:00 PM"
        let upcomingSlotName = userDefaults?.string(forKey: "upcoming_slot_name") ?? "Afternoon"

        var expectedPercent: Double = 0.0
        if !isNewDay {
            expectedPercent = userDefaults?.double(forKey: "expected_percent") ?? 0.0
        }

        // Parse family members from App Group UserDefaults
        var familyMembers: [FamilyMemberData] = []
        if let familyJson = userDefaults?.string(forKey: "family_members_json"),
           let data = familyJson.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([FamilyMemberData].self, from: data) {
            familyMembers = Array(decoded.prefix(4))
        }

        return FamilyEntry(
            date: date, intake: intake, goal: goal, battery: battery,
            expectedPercent: expectedPercent, upcomingSlotTime: upcomingSlotTime,
            upcomingSlotName: upcomingSlotName, familyMembers: familyMembers
        )
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FamilyEntry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.sipnudge.sipnudge")
        let now = Date()

        let compileTimeline: () -> Timeline<FamilyEntry> = {
            return self.createTimeline(userDefaults: userDefaults)
        }

        guard let userId = userDefaults?.string(forKey: "flutter.user_id")
                ?? userDefaults?.string(forKey: "user_id") else {
            completion(compileTimeline())
            return
        }

        // Fetch user's own data from server
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfToday) ?? startOfToday.addingTimeInterval(86399)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let startDateStr = isoFormatter.string(from: startOfToday)
        let endDateStr = isoFormatter.string(from: endOfToday)

        let urlString = "https://api.sipnudge.com/api/database/today-widget-data/\(userId)?startDate=\(startDateStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&endDate=\(endDateStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if error == nil, let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let summary = json["data"] as? [String: Any] {
                    let consumed = summary["consumed"] as? Double ?? Double(summary["consumed"] as? Int ?? 0)
                    let target = summary["target"] as? Double ?? Double(summary["target"] as? Int ?? 3000)
                    userDefaults?.set(Int(consumed), forKey: "current_intake")
                    let currentStoredGoal = userDefaults?.integer(forKey: "daily_goal") ?? 0
                    if currentStoredGoal <= 0 && target > 0 {
                        userDefaults?.set(Int(target), forKey: "daily_goal")
                    }
                    if let batteryFromServer = summary["battery"] as? Int, batteryFromServer > 0 {
                        userDefaults?.set(batteryFromServer, forKey: "battery")
                    }
                    let todayFormatter = DateFormatter()
                    todayFormatter.dateFormat = "yyyy-MM-dd"
                    todayFormatter.timeZone = .current
                    userDefaults?.set(todayFormatter.string(from: now), forKey: "last_update_date")
                    userDefaults?.synchronize()
                }

                // Fetch family members from connections API (independent of Flutter)
                self.fetchFamilyMembers(userId: userId, userDefaults: userDefaults, completion: completion)
            }
            task.resume()
        } else {
            completion(compileTimeline())
        }
    }

    private func fetchFamilyMembers(userId: String, userDefaults: UserDefaults?, completion: @escaping (Timeline<FamilyEntry>) -> ()) {
        let connectionsUrl = "https://api.sipnudge.com/api/database/connections/\(userId)"

        guard let url = URL(string: connectionsUrl) else {
            completion(createTimeline(userDefaults: userDefaults))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error == nil, let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                let parsed = json["data"] as? [String: Any] ?? [:]
                let connectedMembers = parsed["connectedMembers"] as? [[String: Any]] ?? []

                let familyMembers: [[String: Any]] = connectedMembers.prefix(4).map { member in
                    return [
                        "name": member["name"] ?? member["userName"] ?? "Connection",
                        "consumed": member["consumed"] ?? 0,
                        "target": member["target"] ?? 2000,
                        "percentage": member["percentage"] ?? 0,
                        "accentColor": member["themeAccentColor"] ?? "#F97316"
                    ]
                }

                if let familyData = try? JSONSerialization.data(withJSONObject: familyMembers),
                   let familyJson = String(data: familyData, encoding: .utf8) {
                    userDefaults?.set(familyJson, forKey: "family_members_json")
                    userDefaults?.synchronize()
                }
            }
            completion(self.createTimeline(userDefaults: userDefaults))
        }
        task.resume()
    }

    private func createTimeline(userDefaults: UserDefaults?) -> Timeline<FamilyEntry> {
        let now = Date()
        let calendar = Calendar.current
        let midnight: Date
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: now) {
            midnight = calendar.startOfDay(for: nextDay)
        } else {
            midnight = now.addingTimeInterval(86400)
        }

        var entries: [FamilyEntry] = []
        entries.append(self.createEntry(for: now, userDefaults: userDefaults))
        entries.append(self.createEntry(for: midnight, userDefaults: userDefaults))

        let bleTimestamp = userDefaults?.double(forKey: "ble_update_timestamp") ?? 0
        let secondsSinceBle = now.timeIntervalSince1970 - bleTimestamp
        let refreshAfter: TimeInterval
        if secondsSinceBle >= 0 && secondsSinceBle < 30 {
            refreshAfter = 30
        } else {
            refreshAfter = 300
        }
        let nextUpdate = now.addingTimeInterval(refreshAfter)
        return Timeline(entries: entries, policy: .after(nextUpdate))
    }
}

// MARK: - Widget View

struct SipnudgeFamilyWidgetEntryView: View {
    var entry: FamilyProvider.Entry
    @Environment(\.widgetFamily) var family

    var progress: Double {
        guard entry.goal > 0 else { return 0.0 }
        return min(Double(entry.intake) / Double(entry.goal), 1.0)
    }

    var percentageString: String {
        guard entry.goal > 0 else { return "0%" }
        let pct = Int((Double(entry.intake) / Double(entry.goal)) * 100)
        return "\(pct)%"
    }

    var isOnTrack: Bool {
        guard entry.goal > 0 else { return false }
        return entry.intake > 0 && Double(entry.intake) >= (Double(entry.goal) * entry.expectedPercent / 100.0)
    }

    var batteryIconName: String {
        switch entry.battery {
        case 0..<10:  return "battery.0"
        case 10..<35: return "battery.25"
        case 35..<60: return "battery.50"
        case 60..<85: return "battery.75"
        default:      return "battery.100"
        }
    }

    var batteryColor: Color {
        switch entry.battery {
        case 0..<20:  return Color(red: 0.94, green: 0.27, blue: 0.27)
        case 20..<50: return Color(red: 1.00, green: 0.60, blue: 0.00)
        default:      return Color(red: 0.06, green: 0.73, blue: 0.51)
        }
    }

    func formatNumber(_ val: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: val)) ?? "\(val)"
    }

    var body: some View {
        if family == .systemLarge {
            largeLayout
                .environment(\.colorScheme, .light)
                .containerBackground(Color.white, for: .widget)
        } else {
            largeLayout
                .environment(\.colorScheme, .light)
                .containerBackground(Color.white, for: .widget)
        }
    }

    // MARK: - Large Layout (matching screenshot)

    private var largeLayout: some View {
        VStack(spacing: 0) {
            // Top section - Main hydration data
            topSection

            Spacer(minLength: 12)

            // Bottom section - Family members
            bottomSection
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
    }

    // MARK: - Top Section

    private var topSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: Circular Progress Ring (smaller to fit right content)
            VStack(spacing: 6) {
                ZStack {
                    // Background track (300 degrees arc with gap at 12 o'clock)
                    Circle()
                        .trim(from: 0.0, to: 0.833)
                        .stroke(Color(red: 0.92, green: 0.93, blue: 0.95), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(Angle(degrees: 300))

                    // Yellow progress (Expected cumulative schedule target progress)
                    if entry.expectedPercent > 0 {
                        Circle()
                            .trim(from: 0.0, to: CGFloat(min(entry.expectedPercent / 100.0, 1.0)) * 0.833)
                            .stroke(
                                Color(red: 255/255.0, green: 199/255.0, blue: 30/255.0), // #FFC71E
                                style: StrokeStyle(lineWidth: 7, lineCap: .round)
                            )
                            .rotationEffect(Angle(degrees: 300))
                    }

                    // Blue progress (Actual intake) — #1C8DBB
                    if progress > 0 {
                        Circle()
                            .trim(from: 0.0, to: CGFloat(min(progress, 1.0)) * 0.833)
                            .stroke(
                                Color(red: 28/255.0, green: 141/255.0, blue: 187/255.0), // #1C8DBB
                                style: StrokeStyle(lineWidth: 7, lineCap: .round)
                            )
                            .rotationEffect(Angle(degrees: 300))
                    }

                    VStack(spacing: 2) {
                        Text(percentageString)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                    }
                }
                .frame(width: 85, height: 85)

                // Remaining text below ring
                Text("\(formatNumber(max(0, entry.goal - entry.intake))) mL remaining")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.45, green: 0.50, blue: 0.60))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 6)
            }

            // Right side: Stats + Info
            VStack(alignment: .leading, spacing: 5) {
                // On Track badge + Refresh button — aligned to trailing
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isOnTrack ? Color(red: 0.06, green: 0.73, blue: 0.51) : Color(red: 0.94, green: 0.27, blue: 0.27))
                                .frame(width: 8, height: 8)
                            Text(isOnTrack ? "On Track" : "Off Track")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(isOnTrack ? Color(red: 0.06, green: 0.55, blue: 0.35) : Color(red: 0.94, green: 0.27, blue: 0.27))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isOnTrack ? Color(red: 0.90, green: 0.98, blue: 0.93) : Color(red: 1.0, green: 0.94, blue: 0.94))
                                .overlay(
                                    Capsule()
                                        .stroke(isOnTrack ? Color(red: 0.06, green: 0.73, blue: 0.51).opacity(0.4) : Color(red: 0.94, green: 0.27, blue: 0.27).opacity(0.4), lineWidth: 1)
                                )
                        )

                        // Refresh button
                        #if canImport(AppIntents)
                        if #available(iOS 17.0, *) {
                            Button(intent: RefreshWidgetIntent()) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 0.40, green: 0.45, blue: 0.55))
                                    .frame(width: 22, height: 22)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 0.92, green: 0.93, blue: 0.95))
                                    )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Link(destination: URL(string: "sipnudge://refresh")!) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 0.40, green: 0.45, blue: 0.55))
                                    .frame(width: 22, height: 22)
                                    .background(
                                        Circle()
                                            .fill(Color(red: 0.92, green: 0.93, blue: 0.95))
                                    )
                            }
                        }
                        #else
                        Link(destination: URL(string: "sipnudge://refresh")!) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(red: 0.40, green: 0.45, blue: 0.55))
                                .frame(width: 22, height: 22)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.92, green: 0.93, blue: 0.95))
                                )
                        }
                        #endif
                    }
                }

                // Battery
                if entry.battery > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: batteryIconName)
                                .font(.system(size: 10))
                                .foregroundColor(batteryColor)
                            Text("BATTERY")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.40, green: 0.45, blue: 0.55))
                            Spacer()
                            Text("\(entry.battery)%")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(red: 0.92, green: 0.93, blue: 0.95))
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(batteryColor)
                                    .frame(width: geo.size.width * CGFloat(min(Double(entry.battery), 100.0) / 100.0), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }

                // Stats lines
                (Text(percentageString)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                 + Text(" / ")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.50, green: 0.55, blue: 0.65))
                 + Text("\(formatNumber(entry.goal)) mL")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.50, green: 0.55, blue: 0.65))
                )

                (Text("\(formatNumber(entry.intake)) mL")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                 + Text(" LOGGED")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.50, green: 0.55, blue: 0.65))
                )

                // Next Sip row
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.0/255.0, green: 163/255.0, blue: 255/255.0)) // #00A3FF
                                .frame(width: 22, height: 22)
                            Image(systemName: "clock")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Next Sip")
                                .font(.system(size: 8, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.55, green: 0.60, blue: 0.70))
                            Text(entry.upcomingSlotTime)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }

                    Spacer(minLength: 4)

                    // +250 mL button
                    #if canImport(AppIntents)
                    if #available(iOS 17.0, *) {
                        Button(intent: LogDrinkIntent(drinkType: "Water", amount: 250)) {
                            plusButtonContent
                        }
                        .buttonStyle(.plain)
                    } else {
                        Link(destination: URL(string: "sipnudge://quick-add?type=water&amount=250")!) {
                            plusButtonContent
                        }
                    }
                    #else
                    Link(destination: URL(string: "sipnudge://quick-add?type=water&amount=250")!) {
                        plusButtonContent
                    }
                    #endif
                }
            }
        }
    }

    private var plusButtonContent: some View {
        HStack(spacing: 4) {
            Text("+")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("250 mL")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color(red: 0.0/255.0, green: 163/255.0, blue: 255/255.0)) // #00A3FF
                .overlay(
                    Capsule()
                        .stroke(Color(red: 120/255.0, green: 200/255.0, blue: 255/255.0), lineWidth: 1.5)
                )
                .shadow(color: Color(red: 0.0/255.0, green: 163/255.0, blue: 255/255.0).opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Bottom Section (Family Members)

    private var bottomSection: some View {
        VStack(spacing: 14) {
            // Divider text only — no lines
            Text("Lets Hydrate Together")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.45, green: 0.50, blue: 0.60))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Family member mini rings
            if entry.familyMembers.isEmpty {
                Text("Connect with family to see their progress")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.60, green: 0.65, blue: 0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(entry.familyMembers.prefix(4).enumerated()), id: \.offset) { index, member in
                        FamilyMemberRing(member: member)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - Family Member Mini Ring

struct FamilyMemberRing: View {
    let member: FamilyMemberData

    var memberProgress: Double {
        guard member.target > 0 else { return 0.0 }
        return min(Double(member.consumed) / Double(member.target), 1.0)
    }

    var expectedForMember: Double {
        // Estimate expected progress based on time of day (0-100% over waking hours 7AM-10PM)
        let hour = Calendar.current.component(.hour, from: Date())
        let startHour = 7.0
        let endHour = 22.0
        guard hour >= Int(startHour) else { return 0.0 }
        let elapsed = Double(hour) - startHour
        let total = endHour - startHour
        return min(elapsed / total, 1.0)
    }

    var memberPercentageString: String {
        return "\(member.percentage)%"
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background track
                Circle()
                    .trim(from: 0.0, to: 0.833)
                    .stroke(Color(red: 0.92, green: 0.93, blue: 0.95), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(Angle(degrees: 300))

                // Yellow expected progress — #FFC71E (always visible based on time of day)
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(expectedForMember, 1.0)) * 0.833)
                    .stroke(
                        Color(red: 255/255.0, green: 199/255.0, blue: 30/255.0), // #FFC71E
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: 300))

                // Actual progress — #1C8DBB
                if memberProgress > 0 {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(memberProgress, 1.0)) * 0.833)
                        .stroke(
                            Color(red: 28/255.0, green: 141/255.0, blue: 187/255.0), // #1C8DBB
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(Angle(degrees: 300))
                }

                Text(memberPercentageString)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
            }
            .frame(width: 56, height: 56)

            Text(member.name)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("\(formatVolume(member.consumed)) / \(formatVolume(member.target))")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 88/255.0, green: 87/255.0, blue: 87/255.0)) // #585757
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func formatVolume(_ ml: Int) -> String {
        if ml >= 1000 {
            let liters = Double(ml) / 1000.0
            return String(format: "%.1fL", liters)
        }
        return "\(ml)ml"
    }
}

// MARK: - Widget Configuration

struct SipnudgeFamilyWidget: Widget {
    let kind: String = "SipnudgeFamilyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FamilyProvider()) { entry in
            SipnudgeFamilyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Family Hydration")
        .description("Track your and your family's hydration progress together.")
        .supportedFamilies([.systemLarge])
    }
}
