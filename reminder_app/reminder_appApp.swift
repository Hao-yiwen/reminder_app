import SwiftUI
import UserNotifications

// 目标数据模型
struct Goal: Identifiable, Codable {
    let id = UUID()
    var title: String
    var checkInDates: Set<Date>
    var created: Date
    
    var consecutiveStreak: Int {
        // 计算连续打卡天数
        var count = 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentDate = today
        
        while checkInDates.contains(calendar.startOfDay(for: currentDate)) {
            count += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        return count
    }
}

// 主应用程序
@main
struct GoalTrackerApp: App {
    @StateObject private var goalManager = GoalManager()
    
    var body: some Scene {
       MenuBarExtra("Goals", systemImage: "star.fill") {
           StatusBarMenu(goalManager: goalManager)
       }
       .menuBarExtraStyle(.window)
   }
}

// 修改 StatusBarMenu 中的 sheet 展示方式
struct StatusBarMenu: View {
    @ObservedObject var goalManager: GoalManager
    @State private var newGoalTitle = ""
    @State private var isAddingGoal = false
    @State private var previewWindowController: NSWindowController?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("今日目标")
                .font(.headline)
                .padding(.top)
            
            // 活跃度热力图
            ActivityHeatmap(goals: goalManager.goals)
                .padding(.horizontal, 12)
            
            Divider()
            
            // 目标列表
            ForEach(Array(goalManager.goals.enumerated()), id: \.element.id) { index, goal in
                            GoalRow(goal: goal, goalManager: goalManager, colorTheme: GoalColor.forIndex(index))
                        }
            
            // 添加目标行
            if isAddingGoal {
                            HStack {
                                TextField("输入目标名称", text: $newGoalTitle)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        addGoal()
                                    }
                                
                                Button(action: addGoal) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(newGoalTitle.isEmpty)
                                
                                Button(action: cancelAddGoal) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal)
                        }
            
            Divider()
            
            HStack {
                            Button(action: { isAddingGoal = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("添加目标")
                                }
                            }
                            .disabled(isAddingGoal)
                            
                            Spacer()
                            
                            Button("查看统计") {
                                showPreviewWindow()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .frame(width: 330)
    }
    
    private func getRowColor(index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.97, green: 0.97, blue: 0.99), // 非常淡的蓝色
            Color(red: 0.97, green: 0.99, blue: 0.97), // 非常淡的绿色
            Color(red: 0.99, green: 0.97, blue: 0.97), // 非常淡的红色
            Color(red: 0.99, green: 0.99, blue: 0.97)  // 非常淡的黄色
        ]
        return colors[index % colors.count]
    }
    
    private func showPreviewWindow() {
           DispatchQueue.main.async {
               if let windowController = previewWindowController {
                   windowController.showWindow(nil)
                   windowController.window?.makeKeyAndOrderFront(nil)
                   NSApp.activate(ignoringOtherApps: true)
               } else {
                   let window = NSWindow(
                       contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                       styleMask: [.titled, .closable, .miniaturizable, .resizable],
                       backing: .buffered,
                       defer: false
                   )
                   window.title = "统计预览"
                   window.center()
                   window.contentView = NSHostingView(rootView: PreviewWindow(goalManager: goalManager))
                   
                   let windowController = NSWindowController(window: window)
                   previewWindowController = windowController
                   
                   windowController.showWindow(nil)
                   NSApp.activate(ignoringOtherApps: true)
               }
           }
       }
    
    private func addGoal() {
        if !newGoalTitle.isEmpty {
            let goal = Goal(title: newGoalTitle, checkInDates: [], created: Date())
            goalManager.addGoal(goal)
            resetAddGoalState()
        }
    }
    
    private func cancelAddGoal() {
        resetAddGoalState()
    }
    
    private func resetAddGoalState() {
        newGoalTitle = ""
        isAddingGoal = false
    }
}

struct GoalColor {
    let start: Color
    let end: Color
    
    static let themes: [GoalColor] = [
        GoalColor(
            start: Color(red: 0.98, green: 0.82, blue: 0.76),  // 淡珊瑚色
            end: Color(red: 0.95, green: 0.45, blue: 0.42)     // 鲜艳的珊瑚红
        ),
        GoalColor(
            start: Color(red: 0.75, green: 0.95, blue: 0.85),  // 淡薄荷绿
            end: Color(red: 0.18, green: 0.8, blue: 0.44)      // 翠绿色
        ),
        GoalColor(
            start: Color(red: 0.85, green: 0.85, blue: 0.98),  // 淡紫色
            end: Color(red: 0.6, green: 0.4, blue: 0.98)       // 亮紫色
        ),
        GoalColor(
            start: Color(red: 0.98, green: 0.9, blue: 0.75),   // 淡橙色
            end: Color(red: 0.98, green: 0.6, blue: 0.2)       // 鲜橙色
        ),
        GoalColor(
            start: Color(red: 0.75, green: 0.91, blue: 0.98),  // 淡蓝色
            end: Color(red: 0.2, green: 0.6, blue: 0.98)       // 亮蓝色
        ),
        GoalColor(
            start: Color(red: 0.98, green: 0.82, blue: 0.98),  // 淡粉色
            end: Color(red: 0.98, green: 0.4, blue: 0.8)       // 亮粉色
        )
    ]
    
    static func forIndex(_ index: Int) -> GoalColor {
        return themes[index % themes.count]
    }
}

// 目标行视图
struct GoalRow: View {
    let goal: Goal
    @ObservedObject var goalManager: GoalManager
    let colorTheme: GoalColor
    let calendar = Calendar.current
    
    var isCheckedToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return goal.checkInDates.contains(today)
    }
    
    // 计算本周打卡天数
    var weekCheckInCount: Int {
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        return goal.checkInDates.filter { date in
            date >= weekStart && date < weekEnd
        }.count
    }
    
    // 计算背景渐变色
    var backgroundGradient: LinearGradient {
        let streak = goal.consecutiveStreak
        let startOpacity = min(0.1 + (Double(streak) * 0.01), 0.2)  // 左侧较淡
        let endOpacity = min(0.2 + (Double(streak) * 0.03), 0.6)    // 右侧较浓
        
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: colorTheme.start.opacity(startOpacity), location: 0),
                .init(color: colorTheme.end.opacity(endOpacity), location: 0.7)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        ZStack {
            // 背景层
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundGradient)
                .overlay(
                    // 装饰性图案
                    ZStack {
                        Circle()
                            .fill(colorTheme.end.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .offset(x: 120, y: 0)
                        
                        Circle()
                            .fill(colorTheme.start.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .offset(x: 100, y: -10)
                    }
                )
            
            // 内容层
            HStack(spacing: 12) {
                // 左侧打卡按钮和标题
                HStack(spacing: 12) {
                    Button(action: {
                        if isCheckedToday {
                            goalManager.uncheckIn(goal)
                        } else {
                            goalManager.checkIn(goal)
                        }
                    }) {
                        Image(systemName: isCheckedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                            .foregroundColor(isCheckedToday ? colorTheme.end : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.system(size: 14, weight: .medium))
                        
                        if goal.consecutiveStreak > 0 {
                            Text("\(goal.consecutiveStreak) 天连续")
                                .font(.system(size: 12))
                                .foregroundColor(colorTheme.end.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
                
                // 右侧本周打卡统计
                ZStack {
                    Text("\(weekCheckInCount)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .italic()
                        .foregroundColor(colorTheme.end.opacity(0.15))
                        .offset(x: 2, y: 2) // 阴影效果
                    
                    Text("\(weekCheckInCount)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .italic()
                        .foregroundColor(colorTheme.end)
                        .overlay(
                            Text("本周")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(colorTheme.end.opacity(0.8))
                                .offset(y: -20)
                        )
                }
                .frame(width: 60)
                .rotationEffect(.degrees(-8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 70)
        .padding(.horizontal, 8)
        .contextMenu {
            Button(role: .destructive) {
                goalManager.removeGoal(goal)
            } label: {
                Label("删除目标", systemImage: "trash")
            }
        }
    }
}

// 目标管理器
class GoalManager: ObservableObject {
    @Published private(set) var goals: [Goal] = []
    
    init() {
        loadGoals()
    }
    
    func removeGoal(_ goal: Goal) {
            goals.removeAll { $0.id == goal.id }
            saveGoals()
        }
    
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
    }
    
    func checkIn(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            var updatedGoal = goal
            updatedGoal.checkInDates.insert(Calendar.current.startOfDay(for: Date()))
            goals[index] = updatedGoal
            saveGoals()
        }
    }
    
    func uncheckIn(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            var updatedGoal = goal
            updatedGoal.checkInDates.remove(Calendar.current.startOfDay(for: Date()))
            goals[index] = updatedGoal
            saveGoals()
        }
    }
    
    private func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: "goals") {
            if let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
                goals = decoded
            }
        }
    }
    
    private func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: "goals")
        }
    }
}

// 添加目标视图
struct AddGoalView: View {
    @ObservedObject var goalManager: GoalManager
    @Binding var isPresented: Bool
    @State private var title = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("添加新目标")
                .font(.headline)
            
            TextField("目标名称", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
            
            HStack(spacing: 16) {
                Button("取消") {
                    closeWindow()
                }
                
                Button("添加") {
                    let goal = Goal(title: title, checkInDates: [], created: Date())
                    goalManager.addGoal(goal)
                    closeWindow()
                }
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 300, height: 150)
    }
    
    private func closeWindow() {
        isPresented = false
        if let window = NSApplication.shared.windows.first(where: { $0.title == "添加目标" }) {
            window.close()
        }
    }
}

// 预览窗口
struct PreviewWindow: View {
    @ObservedObject var goalManager: GoalManager
    @State private var selectedView = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("预览类型", selection: $selectedView) {
                Text("周视图").tag(0)
                Text("月视图").tag(1)
                Text("年视图").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
            
            switch selectedView {
            case 0:
                WeekView(goals: goalManager.goals)
            case 1:
                MonthView(goals: goalManager.goals)
            case 2:
                YearView(goals: goalManager.goals)
            default:
                EmptyView()
            }
        }
        .frame(minWidth: 800, minHeight: 650)
    }
}

// 周视图
struct WeekView: View {
    let goals: [Goal]
    let calendar = Calendar.current
    
    // 将日期计算提取为属性
    var weekDates: [Date] {
        let today = Date()
        return (0..<7).map { day in
            calendar.date(byAdding: .day, value: day - 6, to: today)!
        }
    }
    
    // 提取日期格式化为独立的属性
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    // 提取日期单元格为独立的视图组件
    struct DateHeaderCell: View {
        let date: Date
        let calendar: Calendar
        let formatter: DateFormatter
        
        var body: some View {
            VStack(spacing: 4) {
                Text(formatWeekDay())
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(formatDate())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(calendar.isDateInToday(date) ? .blue : .primary)
            }
            .frame(maxWidth: .infinity)
        }
        
        private func formatWeekDay() -> String {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
        
        private func formatDate() -> String {
            formatter.dateFormat = "dd"
            return formatter.string(from: date)
        }
    }
    
    // 提取目标行为独立的视图组件
    struct GoalRowView: View {
        let goal: Goal
        let index: Int
        let weekDates: [Date]
        let calendar: Calendar
        
        var completionRate: Double {
            let checkedDays = weekDates.filter {
                goal.checkInDates.contains(calendar.startOfDay(for: $0))
            }.count
            return Double(checkedDays) / Double(weekDates.count)
        }
        
        var body: some View {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // 目标名称和完成率
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.title)
                            .font(.system(size: 14))
                        Text("本周完成率: \(Int(completionRate * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 180, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // 打卡状态
                    ForEach(weekDates, id: \.self) { date in
                        CheckInCell(
                            date: date,
                            goal: goal,
                            colorTheme: GoalColor.forIndex(index),
                            calendar: calendar
                        )
                    }
                }
                .padding(.vertical, 16)
                .background(Color(.windowBackgroundColor))
                .contentShape(Rectangle())
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.separatorColor))
                        .offset(y: 16),
                    alignment: .bottom
                )
            }
        }
    }
    
    // 提取打卡状态单元格为独立的视图组件
    struct CheckInCell: View {
        let date: Date
        let goal: Goal
        let colorTheme: GoalColor
        let calendar: Calendar
        
        var isChecked: Bool {
            goal.checkInDates.contains(calendar.startOfDay(for: date))
        }
        
        var body: some View {
            Circle()
                .fill(isChecked ? colorTheme.end : Color.clear)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .strokeBorder(isChecked ? colorTheme.end : Color.gray.opacity(0.3), lineWidth: 2)
                )
                .frame(maxWidth: .infinity)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 表头
            HStack(spacing: 0) {
                Text("目标")
                    .frame(width: 180, alignment: .leading)
                    .padding(.horizontal, 16)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                ForEach(weekDates, id: \.self) { date in
                    DateHeaderCell(
                        date: date,
                        calendar: calendar,
                        formatter: dateFormatter
                    )
                }
            }
            .padding(.vertical, 12)
            .background(Color(.windowBackgroundColor).opacity(0.05))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                        GoalRowView(
                            goal: goal,
                            index: index,
                            weekDates: weekDates,
                            calendar: calendar
                        )
                    }
                }
            }
        }
    }
}

// 月视图
struct MonthView: View {
    let goals: [Goal]
   @State private var selectedMonth = Date()
   let calendar = Calendar.current
    
    
    var monthStats: (goalCount: Int, completionRate: Int, bestGoal: Goal?) {
            let count = goals.count
            let rate = calculateMonthCompletionRate()
            let best = getBestPerformingGoal()
            return (count, rate, best)
        }
    
    var body: some View {
        VStack(spacing: 20) {
            // 月份选择器
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.plain)
                
                Text(monthYearString(from: selectedMonth))
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 150)
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            
            // 月度统计
            HStack(spacing: 20) {
               let stats = monthStats // 提取计算结果
               
               MonthStatCard(
                   title: "目标总数",
                   value: "\(stats.goalCount)",
                   icon: "target",
                   color: .blue
               )
               
               MonthStatCard(
                   title: "完成率",
                   value: "\(stats.completionRate)%",
                   icon: "chart.line.uptrend.xyaxis",
                   color: .green
               )
               
               MonthStatCard(
                   title: "最佳目标",
                   value: stats.bestGoal?.title ?? "-",
                   icon: "star.fill",
                   color: .orange
               )
           }
           .padding(.horizontal)
            
            // 日历视图
            VStack(spacing: 1) {
                // 星期标题
                HStack(spacing: 1) {
                   ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { weekday in
                       Text(weekday)
                           .font(.system(size: 14, weight: .medium))
                           .frame(maxWidth: .infinity)
                           .padding(.vertical, 8)
                           .background(Color(.windowBackgroundColor))
                   }
               }
                
                // 日历网格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 7), spacing: 1) {
                                    ForEach(daysInMonth(), id: \.self) { date in
                                        if let date = date {
                                            EnhancedDayCell(date: date, goals: goals)
                                        } else {
                                            Color(.windowBackgroundColor)
                                                .aspectRatio(1, contentMode: .fit)
                                        }
                                    }
                                }
                            }
                            .background(Color(.separatorColor))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            Spacer()

        }
    }
    
    func previousMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
    }
    
    func nextMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: date)
    }
    
    func calculateMonthCompletionRate() -> Int {
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)!.count
        let totalPossibleCheckIns = goals.count * daysInMonth
        let actualCheckIns = goals.reduce(0) { total, goal in
            total + goal.checkInDates.filter { date in
                calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
            }.count
        }
        return totalPossibleCheckIns > 0 ? Int(Double(actualCheckIns) / Double(totalPossibleCheckIns) * 100) : 0
    }
    
    func getBestPerformingGoal() -> Goal? {
        goals.max(by: { a, b in
            let aCheckIns = a.checkInDates.filter { calendar.isDate($0, equalTo: selectedMonth, toGranularity: .month) }.count
            let bCheckIns = b.checkInDates.filter { calendar.isDate($0, equalTo: selectedMonth, toGranularity: .month) }.count
            return aCheckIns < bCheckIns
        })
    }
    
    func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay)
            days.append(date)
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

// 月度统计卡片
struct MonthStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// 增强的日期单元格
struct EnhancedDayCell: View {
    let date: Date
    let goals: [Goal]
    let calendar = Calendar.current
    
    var completedGoalsCount: Int {
        goals.filter { goal in
            goal.checkInDates.contains(calendar.startOfDay(for: date))
        }.count
    }
    
    var completionRate: Double {
        Double(completedGoalsCount) / Double(goals.count)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 日期
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: calendar.isDateInToday(date) ? .bold : .regular))
                .foregroundColor(calendar.isDateInToday(date) ? .white : .primary)
            
            // 完成指示器
            if goals.count > 0 {
                            ZStack {
                                Circle()
                                    .stroke(Color(.separatorColor), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(completionRate))
                                    .stroke(
                                        completionRate > 0 ? Color.green : Color.clear,
                                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                    )
                                    .frame(width: 24, height: 24)
                                    .rotationEffect(.degrees(-90))
                                
                                if completedGoalsCount > 0 {
                                    Text("\(completedGoalsCount)")
                                        .font(.system(size: 10))
                                        .foregroundColor(calendar.isDateInToday(date) ? .white : .primary)
                                }
                            }
                        }
        }
        .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if calendar.isDateInToday(date) {
                            Color.blue
                        } else {
                            Color(.windowBackgroundColor)
                        }
                    }
                )
    }
}

    
    // 扩展 YearView 的辅助方法

// 年视图
struct YearView: View {
    let goals: [Goal]
    let calendar = Calendar.current
    @State private var selectedYear: Int
    
    init(goals: [Goal]) {
        self.goals = goals
        _selectedYear = State(initialValue: calendar.component(.year, from: Date()))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 年份选择器
            HStack {
                Button(action: { selectedYear -= 1 }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.plain)
                
                Text("\(selectedYear)年")
                    .font(.system(size: 24, weight: .bold))
                    .frame(width: 120)
                
                Button(action: { selectedYear += 1 }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            
            // 年度统计
            HStack(spacing: 20) {
                YearStatCard(
                    title: "年度完成率",
                    value: "\(calculateYearCompletionRate())%",
                    icon: "chart.pie.fill",
                    color: .blue
                )
                
                YearStatCard(
                    title: "最佳月份",
                    value: getBestPerformingMonth(),
                    icon: "crown.fill",
                    color: .yellow
                )
                
                YearStatCard(
                    title: "总打卡次数",
                    value: "\(getTotalCheckIns())",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            .padding(.horizontal)
            
            ScrollView {
                // 月份网格
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(0..<12) { month in
                        EnhancedMonthSummaryCell(
                            month: month,
                            goals: goals,
                            year: selectedYear
                        )
                        .id("\(selectedYear)-\(month)") // 添加标识符以便于年份切换时刷新
                    }
                }
                .padding(20)
                .animation(.easeInOut, value: selectedYear)
            }
        }
        .background(Color(.windowBackgroundColor))
    }
    
    func calculateYearCompletionRate() -> Int {
        var totalPossibleCheckIns = 0
        var actualCheckIns = 0
        
        for month in 0..<12 {
            var components = DateComponents()
            components.year = selectedYear
            components.month = month + 1
            components.day = 1
            
            if let monthStart = calendar.date(from: components),
               let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) {
                
                let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
                totalPossibleCheckIns += goals.count * daysInMonth
                
                actualCheckIns += goals.reduce(0) { total, goal in
                    total + goal.checkInDates.filter { date in
                        date >= monthStart && date < monthEnd
                    }.count
                }
            }
        }
        
        return totalPossibleCheckIns > 0 ? Int(Double(actualCheckIns) / Double(totalPossibleCheckIns) * 100) : 0
    }
    
    func getBestPerformingMonth() -> String {
        var bestMonth = 0
        var highestCompletionRate = 0.0
        
        for month in 0..<12 {
            var components = DateComponents()
            components.year = selectedYear
            components.month = month + 1
            components.day = 1
            
            if let monthStart = calendar.date(from: components),
               let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) {
                
                let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
                let totalPossibleCheckIns = goals.count * daysInMonth
                
                let actualCheckIns = goals.reduce(0) { total, goal in
                    total + goal.checkInDates.filter { date in
                        date >= monthStart && date < monthEnd
                    }.count
                }
                
                let completionRate = totalPossibleCheckIns > 0 ? Double(actualCheckIns) / Double(totalPossibleCheckIns) : 0
                
                if completionRate > highestCompletionRate {
                    highestCompletionRate = completionRate
                    bestMonth = month
                }
            }
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.monthSymbols[bestMonth]
    }
    
    func getTotalCheckIns() -> Int {
        var totalCheckIns = 0
        
        for month in 0..<12 {
            var components = DateComponents()
            components.year = selectedYear
            components.month = month + 1
            components.day = 1
            
            if let monthStart = calendar.date(from: components),
               let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) {
                
                totalCheckIns += goals.reduce(0) { total, goal in
                    total + goal.checkInDates.filter { date in
                        date >= monthStart && date < monthEnd
                    }.count
                }
            }
        }
        
        return totalCheckIns
    }
}

struct YearStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct EnhancedMonthSummaryCell: View {
    let month: Int
    let goals: [Goal]
    let year: Int
    let calendar = Calendar.current
    
    var monthStart: Date {
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 1
        return calendar.date(from: components)!
    }
    
    var monthStats: (completionRate: Double, totalCheckIns: Int, streaks: Int) {
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
        let totalPossibleCheckIns = goals.count * daysInMonth
        var totalCheckIns = 0
        var maxStreak = 0
        
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        for goal in goals {
            let checkInsInMonth = goal.checkInDates.filter { date in
                date >= monthStart && date < monthEnd
            }
            totalCheckIns += checkInsInMonth.count
            
            // 计算最长连续打卡天数
            var currentStreak = 0
            var maxGoalStreak = 0
            var currentDate = monthStart
            
            while currentDate < monthEnd {
                if checkInsInMonth.contains(calendar.startOfDay(for: currentDate)) {
                    currentStreak += 1
                    maxGoalStreak = max(maxGoalStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            maxStreak = max(maxStreak, maxGoalStreak)
        }
        
        let completionRate = totalPossibleCheckIns > 0 ? Double(totalCheckIns) / Double(totalPossibleCheckIns) : 0
        return (completionRate, totalCheckIns, maxStreak)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 月份标题和进度
            HStack {
                VStack(alignment: .leading) {
                    Text(monthName(month))
                        .font(.system(size: 16, weight: .semibold))
                    
                    if isCurrentMonth {
                        Text("当前")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                // 环形进度指示器
                ZStack {
                    Circle()
                                    .stroke(Color(.separatorColor), lineWidth: 3)
                                    .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(monthStats.completionRate))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .green]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(monthStats.completionRate * 100))%")
                        .font(.system(size: 10, weight: .medium))
                }
            }
            
            // 统计数据
            HStack(spacing: 12) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(monthStats.totalCheckIns)",
                    label: "打卡",
                    color: .green
                )
                
                StatItem(
                    icon: "flame.fill",
                    value: "\(monthStats.streaks)",
                    label: "连续",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    var isCurrentMonth: Bool {
        let currentDate = Date()
        return calendar.component(.month, from: currentDate) == month + 1 &&
               calendar.component(.year, from: currentDate) == year
    }
    
    func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        return dateFormatter.monthSymbols[month]
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12))
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}
struct ActivityHeatmap: View {
    let goals: [Goal]
    let calendar = Calendar.current
    let weeksToShow = 13 // 显示13周，约90天
    let cellSize: CGFloat = 16 // 增大格子尺寸
    let spacing: CGFloat = 3 // 调整间距
    
    @State private var selectedTheme = 0
    
    // 日期范围计算保持不变...
    var dateRange: [Date] {
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(weeksToShow * 7 - 1), to: endDate)!
        
        var dates: [Date] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
    
    func calculateActivityRate(for date: Date?) -> Double {
            guard let date = date, !goals.isEmpty else { return 0 }
            
            let totalGoals = goals.count
            let completedGoals = goals.filter { goal in
                goal.checkInDates.contains(calendar.startOfDay(for: date))
            }.count
            
            return Double(completedGoals) / Double(totalGoals)
        }
    
    func getColorForActivity(_ activityRate: Double) -> Color {
            let theme = HeatmapTheme.themes[selectedTheme]
            if activityRate == 0 { return theme.colors[0] }
            
            let index = Int((activityRate * 4).rounded())
            return theme.colors[min(index, 4)]
        }
    
    // 网格数据计算保持不变...
    var weekGrid: [[Date?]] {
        let totalDays = weeksToShow * 7
        var grid: [[Date?]] = Array(repeating: Array(repeating: nil, count: weeksToShow), count: 7)
        
        for (index, date) in dateRange.enumerated() {
            let weekday = calendar.component(.weekday, from: date) - 1
            let week = index / 7
            grid[weekday][week] = date
        }
        
        return grid
    }
    
    // 月份标签计算
    var monthLabels: [(String, CGFloat)] {
        var labels: [(String, CGFloat)] = []
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月"
        
        var currentMonth = -1
        for (index, date) in dateRange.enumerated() {
            let month = calendar.component(.month, from: date)
            if month != currentMonth {
                let weekNumber = CGFloat(index / 7)
                let xOffset = weekNumber * (cellSize + spacing)
                labels.append((formatter.string(from: date), xOffset))
                currentMonth = month
            }
        }
        
        return labels
    }
    
    // 计算打卡次数相关方法保持不变...
    func checkInCount(for date: Date?) -> Int {
        guard let date = date else { return 0 }
        return goals.reduce(0) { count, goal in
            goal.checkInDates.contains(calendar.startOfDay(for: date)) ? count + 1 : count
        }
    }
    
    var maxCheckInCount: Int {
        dateRange.reduce(0) { maxCount, date in
            max(maxCount, checkInCount(for: date))
        }
    }
    
    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // 顶部控制栏
                HStack {
                    Text("活跃度")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 主题选择器
                    Menu {
                        ForEach(0..<HeatmapTheme.themes.count, id: \.self) { index in
                            Button(action: { selectedTheme = index }) {
                                HStack {
                                    Text(HeatmapTheme.themes[index].name)
                                    if selectedTheme == index {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 月份标签行
                HStack(alignment: .bottom, spacing: 0) {
                    Text("")
                        .frame(width: 30)
                    
                    ZStack(alignment: .leading) {
                        ForEach(monthLabels, id: \.0) { month, xOffset in
                            Text(month)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .position(x: xOffset + cellSize/2, y: 10)
                        }
                    }
                    .frame(height: 20)
                }
                
                HStack(alignment: .top, spacing: spacing) {
                    // 星期标签
                    VStack(spacing: spacing) {
                        ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 30, height: cellSize)
                        }
                    }
                    
                    // 活跃度网格
                    HStack(spacing: spacing) {
                        ForEach(0..<weeksToShow, id: \.self) { week in
                            VStack(spacing: spacing) {
                                ForEach(0..<7) { weekday in
                                    let date = weekGrid[weekday][week]
                                    let activityRate = calculateActivityRate(for: date)
                                    HeatmapCell(
                                        date: date,
                                        activityRate: activityRate,
                                        color: getColorForActivity(activityRate),
                                        cellSize: cellSize,
                                        completedCount: date != nil ? goals.filter { $0.checkInDates.contains(calendar.startOfDay(for: date!)) }.count : 0,
                                        totalCount: goals.count
                                    )
                                }
                            }
                        }
                    }
                }
                
                // 图例
                HStack(spacing: 8) {
                    Text("完成度：")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    ForEach(0..<5) { index in
                        HeatmapCell(
                            date: nil,
                            activityRate: Double(index) / 4,
                            color: HeatmapTheme.themes[selectedTheme].colors[index],
                            cellSize: cellSize,
                            completedCount: 0,
                            totalCount: 0
                        )
                    }
                    
                    HStack(spacing: 4) {
                        Text("0%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("100%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            .cornerRadius(12)
        }
}

// 修改热力图单元格以适应新的尺寸
struct HeatmapCell: View {
    let date: Date?
    let activityRate: Double
    let color: Color
    let cellSize: CGFloat
    let completedCount: Int
    let totalCount: Int
    
    var formattedDate: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
            .help(date != nil ? "\(formattedDate)\n完成进度: \(completedCount)/\(totalCount) (\(Int(activityRate * 100))%)" : "")
    }
}


struct HeatmapTheme {
    let name: String
    let colors: [Color]
    
    static let themes = [
        HeatmapTheme(
            name: "森林绿",
            colors: [
                Color(red: 0.93, green: 0.97, blue: 0.93),
                Color(red: 0.75, green: 0.89, blue: 0.76),
                Color(red: 0.45, green: 0.76, blue: 0.47),
                Color(red: 0.24, green: 0.64, blue: 0.27),
                Color(red: 0.11, green: 0.47, blue: 0.14)
            ]
        ),
        HeatmapTheme(
            name: "海洋蓝",
            colors: [
                Color(red: 0.93, green: 0.96, blue: 0.99),
                Color(red: 0.73, green: 0.85, blue: 0.95),
                Color(red: 0.46, green: 0.67, blue: 0.88),
                Color(red: 0.27, green: 0.51, blue: 0.76),
                Color(red: 0.15, green: 0.37, blue: 0.65)
            ]
        ),
        HeatmapTheme(
            name: "紫罗兰",
            colors: [
                Color(red: 0.96, green: 0.94, blue: 0.98),
                Color(red: 0.87, green: 0.82, blue: 0.93),
                Color(red: 0.75, green: 0.64, blue: 0.87),
                Color(red: 0.62, green: 0.47, blue: 0.78),
                Color(red: 0.48, green: 0.31, blue: 0.67)
            ]
        ),
        HeatmapTheme(
            name: "珊瑚红",
            colors: [
                Color(red: 0.99, green: 0.94, blue: 0.93),
                Color(red: 0.96, green: 0.78, blue: 0.75),
                Color(red: 0.91, green: 0.57, blue: 0.54),
                Color(red: 0.84, green: 0.39, blue: 0.36),
                Color(red: 0.74, green: 0.25, blue: 0.22)
            ]
        ),
        HeatmapTheme(
            name: "日落橙",
            colors: [
                Color(red: 0.99, green: 0.95, blue: 0.90),
                Color(red: 0.98, green: 0.85, blue: 0.70),
                Color(red: 0.96, green: 0.71, blue: 0.41),
                Color(red: 0.92, green: 0.56, blue: 0.20),
                Color(red: 0.85, green: 0.43, blue: 0.10)
            ]
        )
    ]
}
