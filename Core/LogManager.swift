import SwiftUI

class LogManager: ObservableObject {
    @Published var logs: [ActionLog] = []
    private let storageKey = "aether_logs"
    private let maxLogs = 500

    init() { load() }

    func log(action: String, detail: String, result: String) {
        let entry = ActionLog(action: action, detail: detail, result: result)
        logs.insert(entry, at: 0)
        if logs.count > maxLogs { logs = Array(logs.prefix(maxLogs)) }
        persist()
    }

    func getRecent(count: Int = 20) -> [ActionLog] { Array(logs.prefix(count)) }
    func getByAction(_ action: String) -> [ActionLog] { logs.filter { $0.action == action } }
    func todayLogs() -> [ActionLog] {
        let calendar = Calendar.current
        return logs.filter { calendar.isDateInToday($0.timestamp) }
    }
    func clearAll() { logs.removeAll(); persist() }

    private func persist() {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([ActionLog].self, from: data) {
            logs = saved
        }
    }
}
