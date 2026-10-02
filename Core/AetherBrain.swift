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
            text: "Merhaba! Ben Aether. 🧠\n\nSenin iPhone'unda %100 yerel (on-device) çalışan yerel yapay zeka asistanınım.\n\nEğer henüz bir yerel LLM modeli indirmediysen 'Modeller' sekmesinden ücretsiz modelleri cihazına indirebilirsin!",
            isUser: false
        ))
    }

    func processInput(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Kullanıcı mesajı ekle
        messages.append(ChatMessage(text: trimmed, isUser: true))
        isThinking = true

        // Otomatik Hafıza Analizi
        parseAndSaveMemories(trimmed)

        // Bağlam Hazırla
        var memoryContext = ""
        for (category, entries) in memoryManager.categorizedMemories {
            memoryContext += "[\(category)]:\n"
            for entry in entries {
                memoryContext += "- \(entry.key): \(entry.value)\n"
            }
        }

        // Yerel LLM Çıkarımı Çağır
        llmEngine.generate(prompt: trimmed, memoryContext: memoryContext, history: messages) { [weak self] response, isWarning in
            guard let self = self else { return }
            self.messages.append(ChatMessage(text: response, isUser: false, isWarning: isWarning))
            self.isThinking = false
            self.logManager.log(action: isWarning ? "MODEL_UYARI" : "LLM_INFERENCE", detail: trimmed, result: isWarning ? "MODEL_YOK" : "BASARILI")
        }
    }

    private func parseAndSaveMemories(_ text: String) {
        let lower = text.lowercased()

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

        if lower.contains("hatırlat") || lower.contains("kaydet") || lower.contains("not al") {
            memoryManager.save(category: MemoryCategory.general.rawValue, key: "Not", value: text, importance: 0.7)
            logManager.log(action: "HAFIZA_NOT", detail: text, result: "BASARILI")
        }
    }
}
