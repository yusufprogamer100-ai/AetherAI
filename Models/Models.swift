import SwiftUI

// MARK: - Yerel LLM Model Tanımı
struct LocalLLMModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let developer: String
    let sizeMB: Double
    let parameters: String
    let downloadURL: String
    let filename: String
    let systemPromptFormat: String
    var isDownloaded: Bool = false
}

// MARK: - Canlı İndirme Durumu
struct DownloadProgressInfo {
    var isDownloading: Bool = false
    var modelId: String = ""
    var downloadedBytes: Int64 = 0
    var totalBytes: Int64 = 0
    var speedMBps: Double = 0.0
    var percentage: Double = 0.0
    var logs: [String] = []
    var errorMessage: String? = nil

    var downloadedMB: Double {
        Double(downloadedBytes) / (1024.0 * 1024.0)
    }

    var totalMB: Double {
        Double(totalBytes) / (1024.0 * 1024.0)
    }
}

// MARK: - Sohbet Mesajı
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    let isWarning: Bool

    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date(), isWarning: Bool = false) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
        self.isWarning = isWarning
    }
}

// MARK: - Hafıza Kaydı
struct MemoryEntry: Identifiable, Codable {
    let id: UUID
    var category: String
    var key: String
    var value: String
    var importance: Double
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), category: String, key: String, value: String, importance: Double = 0.5, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.category = category
        self.key = key
        self.value = value
        self.importance = importance
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Aksiyon Logu
struct ActionLog: Identifiable, Codable {
    let id: UUID
    let action: String
    let detail: String
    let result: String
    let timestamp: Date

    init(id: UUID = UUID(), action: String, detail: String, result: String, timestamp: Date = Date()) {
        self.id = id
        self.action = action
        self.detail = detail
        self.result = result
        self.timestamp = timestamp
    }

    var formattedLog: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "[\(df.string(from: timestamp))] | \(action) | \(detail) | \(result)"
    }
}

// MARK: - Hafıza Kategorileri
enum MemoryCategory: String, CaseIterable {
    case people = "Kişiler"
    case routines = "Rutinler"
    case preferences = "Tercihler"
    case dates = "Tarihler"
    case general = "Genel"

    var icon: String {
        switch self {
        case .people: return "person.2.fill"
        case .routines: return "clock.fill"
        case .preferences: return "heart.fill"
        case .dates: return "calendar"
        case .general: return "brain.head.profile"
        }
    }

    var color: Color {
        switch self {
        case .people: return .blue
        case .routines: return .orange
        case .preferences: return .pink
        case .dates: return .green
        case .general: return .purple
        }
    }
}
