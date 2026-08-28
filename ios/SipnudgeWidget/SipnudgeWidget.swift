import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

struct SlotItem: Codable {
    let label: String
    let hour: Int
    let minute: Int
    let endHour: Int
    let endMinute: Int
    let target: Int
}

#if canImport(AppIntents)
@available(iOS 16.0, *)
struct LogDrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Drink"
    static var description = IntentDescription("Quickly log water or coffee from the widget")
    
    @Parameter(title: "Drink Type")
    var drinkType: String
    
    @Parameter(title: "Amount")
    var amount: Int
    
    init() {
        self.drinkType = "Water"
        self.amount = 250
    }
    
    init(drinkType: String, amount: Int) {
        self.drinkType = drinkType
        self.amount = amount
    }
    
    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.sipnudge.sipnudge")
        let currentIntake = userDefaults?.integer(forKey: "current_intake") ?? 0
        
        let isCoffee = drinkType.lowercased() == "coffee"
        let coefficient: Double = isCoffee ? 0.8 : 1.0
        let effectiveWater = Int(Double(amount) * coefficient)
        let newIntake = currentIntake + effectiveWater
        
        userDefaults?.set(newIntake, forKey: "current_intake")
        
        if isCoffee {
            let currentCoffee = userDefaults?.integer(forKey: "coffee_intake") ?? 0
            userDefaults?.set(currentCoffee + amount, forKey: "coffee_intake")
        } else {
            let currentWater = userDefaults?.integer(forKey: "water_intake") ?? 0
            userDefaults?.set(currentWater + amount, forKey: "water_intake")
        }
        
        userDefaults?.set(drinkType, forKey: "latest_drink_type")
        userDefaults?.set(amount, forKey: "latest_drink_amount")
        
        // Save latest added indication for the circular indicator (+ 250 ml / + 150 ml)
        userDefaults?.set(amount, forKey: "recent_added_amount")
        userDefaults?.set(Date().timeIntervalSince1970, forKey: "recent_added_time")
        
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let utcTimestamp = isoFormatter.string(from: now)
        
        let localDateFormatter = DateFormatter()
        localDateFormatter.dateFormat = "yyyy-MM-dd"
        localDateFormatter.timeZone = TimeZone.current
        let localDate = localDateFormatter.string(from: now)
        
        // Asynchronously post to backend server directly so data is saved even if the app is never opened
        var serverId: String? = nil
        if let userId = userDefaults?.string(forKey: "flutter.user_id") ?? userDefaults?.string(forKey: "user_id"),
           !userId.isEmpty, userId != "guest_user" {
            if let url = URL(string: "https://api.sipnudge.com/api/database/create-manual-log-v2") {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 10.0
                
                let bodyDict: [String: Any] = [
                    "userId": userId,
                    "type": drinkType,
                    "consumed": Double(amount),
                    "timestamp": utcTimestamp,
                    "localDate": localDate
                ]
                
                if let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict) {
                    request.httpBody = bodyData
                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)
                        if let httpResponse = response as? HTTPURLResponse,
                           (httpResponse.statusCode == 200 || httpResponse.statusCode == 201),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let success = json["success"] as? Bool, success {
                            serverId = json["serverId"] as? String
                        }
                    } catch {
                        // Offline or network error; will be synced via pendingLogs when app opens
                    }
                }
            }
        }
        
        // Save to pending logs JSON in shared App Group UserDefaults for Flutter SQLite sync
        var pendingLogs: [[String: Any]] = []
        if let existingJson = userDefaults?.string(forKey: "pending_widget_logs_json"),
           let data = existingJson.data(using: .utf8),
           let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            pendingLogs = array
        }
        
        var logEntry: [String: Any] = [
            "type": drinkType,
            "amount": amount,
            "effective_water": effectiveWater,
            "timestamp": utcTimestamp,
            "localDate": localDate
        ]
        if let serverId = serverId {
            logEntry["server_id"] = serverId
        }
        pendingLogs.append(logEntry)
        
        if let updatedData = try? JSONSerialization.data(withJSONObject: pendingLogs),
           let updatedJson = String(data: updatedData, encoding: .utf8) {
            userDefaults?.set(updatedJson, forKey: "pending_widget_logs_json")
        }
        
        userDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
#endif

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), intake: 0, goal: 2000, coffeeIntake: 200, waterIntake: 0, latestDrinkType: "Coffee", latestDrinkAmount: 200, recentAddedAmount: nil, upcomingSlotName: "Wakeup Time", upcomingSlotTarget: 500, upcomingSlotTime: "07:00 AM", streak: 7,
                    battery: 72, expectedPercent: 30.0,
                    dbgUUID: "-", dbgConnected: "-", dbgSubscribed: "-", dbgBleRx: "-")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), intake: 750, goal: 2500, coffeeIntake: 200, waterIntake: 0, latestDrinkType: "Coffee", latestDrinkAmount: 200, recentAddedAmount: nil, upcomingSlotName: "Lunch Time", upcomingSlotTarget: 300, upcomingSlotTime: "01:00 PM", streak: 7,
                                battery: 72, expectedPercent: 40.0,
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
        var coffeeIntake = userDefaults?.integer(forKey: "coffee_intake") ?? 0
        var waterIntake = userDefaults?.integer(forKey: "water_intake") ?? 0
        var latestDrinkType = userDefaults?.string(forKey: "latest_drink_type") ?? ""
        var latestDrinkAmount = userDefaults?.integer(forKey: "latest_drink_amount") ?? 0

        if lastUpdateDateStr != todayStr && !lastUpdateDateStr.isEmpty {
            intake = 0
            coffeeIntake = 0
            waterIntake = 0
            latestDrinkType = ""
            latestDrinkAmount = 0
        }
        
        var recentAddedAmount: Int? = nil
        if let recentTime = userDefaults?.double(forKey: "recent_added_time"), recentTime > 0 {
            let elapsed = date.timeIntervalSince1970 - recentTime
            // Show + xxx ml indicator if added recently (within 5 seconds)
            if elapsed >= 0 && elapsed < 5.0 {
                let amt = userDefaults?.integer(forKey: "recent_added_amount") ?? 0
                if amt > 0 {
                    recentAddedAmount = amt
                }
            }
        }
        
        let goal = userDefaults?.integer(forKey: "daily_goal") ?? 2000
        let streak = userDefaults?.integer(forKey: "streak") ?? 0
        
        var upcomingSlotName = userDefaults?.string(forKey: "upcoming_slot_name") ?? "Next Slot"
        var upcomingSlotTarget = userDefaults?.integer(forKey: "upcoming_slot_target") ?? 0
        var upcomingSlotTime = userDefaults?.string(forKey: "upcoming_slot_time") ?? "--:--"
        
        let battery = userDefaults?.integer(forKey: "battery") ?? 72
        
        // Dynamically compute the upcoming slot and cumulative target if slots JSON is available
        var expectedCumulative: Double = 0.0
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

                // Calculate cumulative expected targets at current date/time (Slot-by-slot)
                for slot in sortedSlots {
                    let startMin = slot.hour * 60 + slot.minute
                    let endMin = slot.endHour * 60 + slot.endMinute
                    
                    if nowTotalMinutes >= endMin {
                        // Slot has passed -> add full slot target
                        expectedCumulative += Double(slot.target)
                    } else if nowTotalMinutes >= startMin && nowTotalMinutes < endMin {
                        // Currently active slot -> progress smoothly during its active window
                        let duration = endMin - startMin
                        if duration > 0 {
                            let elapsed = nowTotalMinutes - startMin
                            expectedCumulative += Double(slot.target) * (Double(elapsed) / Double(duration))
                        }
                        break
                    } else {
                        // Next slots haven't started yet
                        break
                    }
                }
            }
        }
        
        var expectedPercent = goal > 0 ? (expectedCumulative / Double(goal)) * 100.0 : 0.0
        if expectedPercent == 0.0 {
            expectedPercent = userDefaults?.double(forKey: "expected_percent") ?? 0.0
        }
        
        return SimpleEntry(date: date, intake: intake, goal: goal, coffeeIntake: coffeeIntake, waterIntake: waterIntake, latestDrinkType: latestDrinkType, latestDrinkAmount: latestDrinkAmount, recentAddedAmount: recentAddedAmount, upcomingSlotName: upcomingSlotName, upcomingSlotTarget: upcomingSlotTarget, upcomingSlotTime: upcomingSlotTime, streak: streak,
                           battery: battery, expectedPercent: expectedPercent,
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
        
        // Define timeline compilation with 5-second indicator transition
        let compileTimeline: () -> Timeline<Entry> = {
            var entries: [SimpleEntry] = []
            let entryNow = self.createEntry(for: now, userDefaults: userDefaults)
            entries.append(entryNow)
            
            // If drink was added within the last 5 seconds, schedule an entry at 5.0 seconds to automatically clear the indicator
            if let recentTime = userDefaults?.double(forKey: "recent_added_time"), recentTime > 0 {
                let elapsed = now.timeIntervalSince1970 - recentTime
                if elapsed >= 0 && elapsed < 5.0 {
                    let dateAfter5Sec = Date(timeIntervalSince1970: recentTime + 5.1)
                    let entryAfter5Sec = self.createEntry(for: dateAfter5Sec, userDefaults: userDefaults)
                    entries.append(entryAfter5Sec)
                }
            }
            
            let entryMidnight = self.createEntry(for: midnight, userDefaults: userDefaults)
            entries.append(entryMidnight)
            
            let nextUpdate = calendar.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(300)
            return Timeline(entries: entries, policy: .after(nextUpdate))
        }

        // Try getting userId to fetch from server
        guard let userId = userDefaults?.string(forKey: "flutter.user_id")
                ?? userDefaults?.string(forKey: "user_id") else {
            completion(compileTimeline())
            return
        }

        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfToday) ?? startOfToday.addingTimeInterval(86399)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let startDateStr = formatter.string(from: startOfToday)
        let endDateStr = formatter.string(from: endOfToday)
        
        let urlString = "https://api.sipnudge.com/api/database/today-widget-data/\(userId)?startDate=\(startDateStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&endDate=\(endDateStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion(compileTimeline())
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error == nil,
               let data = data,
               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let summary = json["data"] as? [String: Any] {
                
                let consumed = summary["consumed"] as? Double ?? Double(summary["consumed"] as? Int ?? 0)
                let target = summary["target"] as? Double ?? Double(summary["target"] as? Int ?? 2500)
                let coffeeIntake = summary["coffeeIntake"] as? Int ?? 0
                let waterIntake = summary["waterIntake"] as? Int ?? 0
                let latestDrinkType = summary["latestDrinkType"] as? String ?? ""
                let latestDrinkAmount = summary["latestDrinkAmount"] as? Int ?? 0
                
                userDefaults?.set(Int(consumed), forKey: "current_intake")
                userDefaults?.set(Int(target), forKey: "daily_goal")
                userDefaults?.set(coffeeIntake, forKey: "coffee_intake")
                userDefaults?.set(waterIntake, forKey: "water_intake")
                userDefaults?.set(latestDrinkType, forKey: "latest_drink_type")
                userDefaults?.set(latestDrinkAmount, forKey: "latest_drink_amount")
                
                // Battery comes from HydrationLog (latest bottle sync) — not DailySummary
                if let batteryFromServer = summary["battery"] as? Int {
                    userDefaults?.set(batteryFromServer, forKey: "battery")
                }
                
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
    let coffeeIntake: Int
    let waterIntake: Int
    let latestDrinkType: String
    let latestDrinkAmount: Int
    let recentAddedAmount: Int?
    let upcomingSlotName: String
    let upcomingSlotTarget: Int
    let upcomingSlotTime: String
    let streak: Int
    let battery: Int
    let expectedPercent: Double
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

    var isCurrentlyOnTrack: Bool {
        guard entry.goal > 0 else { return false }
        return entry.intake > 0 && Double(entry.intake) >= (Double(entry.goal) * entry.expectedPercent / 100.0)
    }

    var headingText: String {
        if entry.intake <= 0 {
            return "Time to drink!"
        } else if isCurrentlyOnTrack {
            return "You’re on track"
        } else {
            return "You’re not on track"
        }
    }

    var headingColor: Color {
        isCurrentlyOnTrack ? Color(red: 0.09, green: 0.15, blue: 0.27) : Color(red: 0.94, green: 0.27, blue: 0.27)
    }

    var percentageString: String {
        guard entry.goal > 0 else { return "0%" }
        let pct = Int((Double(entry.intake) / Double(entry.goal)) * 100)
        return "\(pct)%"
    }

    // MARK: - Battery helpers
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
        case 0..<20:  return Color(red: 0.94, green: 0.27, blue: 0.27)   // red
        case 20..<50: return Color(red: 1.00, green: 0.60, blue: 0.00)   // orange
        default:      return Color(red: 0.06, green: 0.73, blue: 0.51)   // green
        }
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
        HStack(spacing: 12) {
            // Left Side: Circular Progress Ring with top gap and double progress arcs (Blue and Yellow)
            VStack(spacing: 4) {
                ZStack {
                    // Background track (300 degrees arc with gap at 12 o'clock)
                    Circle()
                        .trim(from: 0.0, to: 0.833)
                        .stroke(Color(red: 0.92, green: 0.93, blue: 0.95), style: StrokeStyle(lineWidth: 7.5, lineCap: .round))
                        .rotationEffect(Angle(degrees: 300))
                    
                    // Yellow progress (Expected cumulative schedule target progress)
                    if entry.expectedPercent > 0 {
                        Circle()
                            .trim(from: 0.0, to: CGFloat(min(entry.expectedPercent / 100.0, 1.0)) * 0.833)
                            .stroke(
                                Color(red: 245/255.0, green: 185/255.0, blue: 30/255.0), // Amber/Yellow
                                style: StrokeStyle(lineWidth: 7.5, lineCap: .round)
                            )
                            .rotationEffect(Angle(degrees: 300))
                    }
                    
                    // Blue progress (Actual intake completion progress)
                    if progress > 0 {
                        Circle()
                            .trim(from: 0.0, to: CGFloat(min(progress, 1.0)) * 0.833)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 180/255.0, green: 217/255.0, blue: 255/255.0),
                                        Color(red: 28/255.0, green: 141/255.0, blue: 187/255.0) // 1C8DBB
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                style: StrokeStyle(lineWidth: 7.5, lineCap: .round)
                            )
                            .rotationEffect(Angle(degrees: 300))
                    }
                    
                    VStack(spacing: 1) {
                        Text(percentageString)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                        
                        if let recentAmt = entry.recentAddedAmount {
                            VStack(spacing: 0) {
                                Text("+")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.64, green: 0.48, blue: 0.32))
                                Text("\(recentAmt) ml")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.64, green: 0.48, blue: 0.32))
                            }
                        }
                    }
                }
                .frame(width: 82, height: 82)
                
                // ml count below ring
                (Text(formatNumber(entry.intake))
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                 + Text(" / \(formatNumber(entry.goal)) ml")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 85/255.0, green: 104/255.0, blue: 127/255.0)))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, 1)
            }
            
            // Right Side: Details (Battery progress, status, Next sip & Coffee/Water quick actions)
            VStack(alignment: .leading, spacing: 5) {
                // Battery indicator
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
                    
                    // Green battery bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(red: 0.92, green: 0.93, blue: 0.95))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(batteryColor)
                                .frame(width: geo.size.width * CGFloat(Double(entry.battery) / 100.0), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                
                // Heading (Dynamic color depending on "on-track" state)
                Text(headingText)
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundColor(headingColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Next Sip & Only Left Row
                HStack(spacing: 0) {
                    // Next Sip
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.94, green: 0.97, blue: 1.00))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color(red: 0.82, green: 0.90, blue: 0.98), lineWidth: 1)
                                )
                            Image(systemName: "clock")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(red: 0.00, green: 0.48, blue: 1.00))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Next Sip")
                                .font(.system(size: 8.5, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 120/255.0, green: 135/255.0, blue: 155/255.0))
                            Text(entry.upcomingSlotTime)
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Only Left
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.94, green: 0.97, blue: 1.00))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color(red: 0.82, green: 0.90, blue: 0.98), lineWidth: 1)
                                )
                            Image(systemName: "drop")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(red: 0.00, green: 0.48, blue: 1.00))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Only Left")
                                .font(.system(size: 8.5, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 120/255.0, green: 135/255.0, blue: 155/255.0))
                            Text("\(formatNumber(max(0, entry.goal - entry.intake))) ml")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.09, green: 0.15, blue: 0.27))
                                .lineLimit(1)
                        }
                    }
                }
                
                // Quick Action Buttons Row (Coffee 150ml & Water 250ml)
                HStack {
                    #if canImport(AppIntents)
                    if #available(iOS 17.0, *) {
                        Button(intent: LogDrinkIntent(drinkType: "Coffee", amount: 150)) {
                            coffeeButtonContent
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(intent: LogDrinkIntent(drinkType: "Water", amount: 250)) {
                            waterButtonContent
                        }
                        .buttonStyle(.plain)
                    } else {
                        Link(destination: URL(string: "sipnudge://quick-add?type=coffee&amount=150")!) {
                            coffeeButtonContent
                        }
                        Spacer()
                        Link(destination: URL(string: "sipnudge://quick-add?type=water&amount=250")!) {
                            waterButtonContent
                        }
                    }
                    #else
                    Link(destination: URL(string: "sipnudge://quick-add?type=coffee&amount=150")!) {
                        coffeeButtonContent
                    }
                    Spacer()
                    Link(destination: URL(string: "sipnudge://quick-add?type=water&amount=250")!) {
                        waterButtonContent
                    }
                    #endif
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
    }

    private var coffeeButtonContent: some View {
        HStack(spacing: 6) {
            Text("Coffee")
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 70/255.0, green: 70/255.0, blue: 70/255.0))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            ZStack {
                Circle()
                    .fill(Color(red: 139/255.0, green: 80/255.0, blue: 35/255.0)) // Rich coffee brown
                    .frame(width: 20, height: 20)
                
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 3)
        .padding(.vertical, 2.5)
        .frame(height: 26)
        .background(
            Capsule()
                .fill(Color(red: 243/255.0, green: 213/255.0, blue: 181/255.0)) // Warm soft beige/tan
                .overlay(
                    Capsule()
                        .stroke(Color(red: 230/255.0, green: 196/255.0, blue: 158/255.0), lineWidth: 1)
                )
        )
    }

    private var waterButtonContent: some View {
        HStack(spacing: 6) {
            Text("Water")
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 70/255.0, green: 70/255.0, blue: 70/255.0))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            ZStack {
                Circle()
                    .fill(Color(red: 0/255.0, green: 153/255.0, blue: 255/255.0)) // Electric vibrant blue
                    .frame(width: 20, height: 20)
                
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 3)
        .padding(.vertical, 2.5)
        .frame(height: 26)
        .background(
            Capsule()
                .fill(Color(red: 214/255.0, green: 243/255.0, blue: 255/255.0)) // Soft pastel sky blue
                .overlay(
                    Capsule()
                        .stroke(Color(red: 175/255.0, green: 228/255.0, blue: 255/255.0), lineWidth: 1)
                )
        )
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
                // Battery mini-indicator
                if entry.battery > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: batteryIconName)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(batteryColor)
                        Text("\(entry.battery)%")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(batteryColor)
                    }
                    Text("·")
                        .foregroundColor(Color(red: 0.75, green: 0.78, blue: 0.85))
                        .font(.system(size: 10))
                }
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
