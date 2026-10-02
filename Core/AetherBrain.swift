import SwiftUI

class AetherBrain: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isThinking: Bool = false

    let memoryManager: MemoryManager
    let logManager: LogManager
    let llmEngine: LocalLLMEngine

    init(memoryManager: MemoryManager, logManager: LogManager, llmEngine: LocalLLMEngine) {
        self.memoryManager = memoryManager
        self.logManager = logManager
        self.llmEngine = llmEngine

        messages.append(ChatMessage(
            text: "Merhaba! Ben Aether v3.2. 🧠\n\niPhone'unda %100 yerel (on-device) çalışan yapay zeka asistanınım. Hiçbir verin sunuculara gitmez.\n\nBana bir emrin var mı?",
            isUser: false
        ))
    }

    func processInput(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Kullanıcı mesajı
        messages.append(ChatMessage(text: trimmed, isUser: true))
        isThinking = true

        // Otomatik Hafıza Analizi (Kişiler, Notlar, Tercihler)
        parseAndSaveMemories(trimmed)

        // Bağlam Hazırla
        var memoryContext = ""
        for (category, entries) in memoryManager.categorizedMemories {
            memoryContext += "[\(category)]:\n"
            for entry in entries {
                memoryContext += "- \(entry.key): \(entry.value)\n"
            }
        }

        // Yerel LLM Çıkarımı Çalıştır
        llmEngine.generate(
            prompt: trimmed,
            memoryContext: memoryContext,
            history: messages,
            onToken: { _ in },
            onComplete: { [weak self] response in
                guard let self = self else { return }
                self.messages.append(ChatMessage(text: response, isUser: false))
                self.isThinking = false
                self.logManager.log(action: "LLM_INFERENCE", detail: trimmed, result: "BASARILI")
            }
        )
    }

    private func parseAndSaveMemories(_ text: String) {
        let lower = text.lowercased()

        // Kişi bilgisi
        let relations = [("Kardeş", ["kardeşim", "kardesim"]), ("Anne", ["annem"]), ("Baba", ["babam"]), ("Arkadaş", ["arkadaşım", "arkadasim"]), ("Sevgili", ["sevgilim"])]
        for (key, variants) in relations {
            if variants.contains(where: { lower.contains($0) }) {
                let parts = text.components(separatedBy: " ")
                if let name = parts.last, name.count > 1 {
                    memoryManager.save(category: MemoryCategory.people.rawValue, key: key, value: name.capitalized, importance: 0.9)
                    logManager.log(action: "HAFIZA_KISI", detail: "\(key): \(name.capitalized)", result: "BASARILI")
                }
            }
        }

        // Hatırlatıcı / Not
        if lower.contains("hatırlat") || lower.contains("kaydet") || lower.contains("not al") {
            memoryManager.save(category: MemoryCategory.general.rawValue, key: "Not", value: text, importance: 0.7)
            logManager.log(action: "HAFIZA_NOT", detail: text, result: "BASARILI")
        }

        // Alarm
        if lower.contains("alarm") {
            memoryManager.save(category: MemoryCategory.routines.rawValue, key: "Alarm İsteği", value: text, importance: 0.8)
            logManager.log(action: "HAFIZA_ALARM", detail: text, result: "BASARILI")
        }
    }
}
