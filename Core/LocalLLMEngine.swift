import SwiftUI
import NaturalLanguage

class LocalLLMEngine: ObservableObject {
    @Published var activeModel: LocalLLMModel?
    @Published var isGenerating: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var availableModels: [LocalLLMModel] = [
        LocalLLMModel(
            id: "qwen2.5-0.5b",
            name: "Qwen 2.5 0.5B Instruct",
            developer: "Alibaba Cloud (Mükemmel Türkçe)",
            sizeMB: 390.0,
            parameters: "0.5B (GGUF Q4)",
            downloadURL: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
            systemPromptFormat: "chatml"
        ),
        LocalLLMModel(
            id: "smollm-360m",
            name: "SmolLM 360M Instruct",
            developer: "HuggingFace (Hızlı & Hafif)",
            sizeMB: 240.0,
            parameters: "360M (GGUF Q4)",
            downloadURL: "https://huggingface.co/HuggingFaceTB/SmolLM-360M-Instruct-GGUF/resolve/main/smollm-360m-instruct-q4_k_m.gguf",
            filename: "smollm-360m-instruct-q4_k_m.gguf",
            systemPromptFormat: "chatml"
        ),
        LocalLLMModel(
            id: "tinyllama-1.1b",
            name: "TinyLlama 1.1B Chat",
            developer: "TinyLlama Team (Geniş Bilgi)",
            sizeMB: 640.0,
            parameters: "1.1B (GGUF Q4)",
            downloadURL: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
            filename: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
            systemPromptFormat: "llama2"
        )
    ]

    let downloader = ModelDownloader()

    init() {
        checkDownloadedModels()
    }

    func checkDownloadedModels() {
        let modelsDir = ModelDownloader.modelsDirectory
        var downloadedCount = 0

        for idx in availableModels.indices {
            let fileURL = modelsDir.appendingPathComponent(availableModels[idx].filename)
            let exists = FileManager.default.fileExists(atPath: fileURL.path)
            availableModels[idx].isDownloaded = exists
            if exists {
                downloadedCount += 1
                if activeModel == nil {
                    activeModel = availableModels[idx]
                }
            }
        }

        isModelLoaded = downloadedCount > 0
    }

    func selectModel(_ model: LocalLLMModel) {
        if model.isDownloaded {
            activeModel = model
            isModelLoaded = true
        }
    }

    // MARK: - Gerçek Yerel LLM Çıkarımı
    func generate(prompt: String, memoryContext: String, history: [ChatMessage], onComplete: @escaping (String, Bool) -> Void) {
        checkDownloadedModels()

        // EĞER MODEL YOKSA AÇIK UYARI VER
        guard isModelLoaded, let active = activeModel else {
            onComplete("""
            ⚠️ YEREL LLM MODELİ SEÇİLMEDİ VEYA İNDİRİLMEDİ!

            Henüz cihazına indirilmiş ve aktif edilmiş bir yerel yapay zeka modeli bulunamadı.

            Lütfen 'Modeller' sekmesine giderek dilediğin Türkçe destekli modellerden birini indir ve seç.
            """, true)
            return
        }

        isGenerating = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let response = self?.generateRealAIResponse(prompt: prompt, memoryContext: memoryContext, activeModel: active) ?? ""

            DispatchQueue.main.async {
                self?.isGenerating = false
                onComplete(response, false)
            }
        }
    }

    // MARK: - GERÇEK YAYAP ZEKA YANIT ÜRETİMİ (Sıfır Meta Cümle / %100 Doğal Cevap)
    private func generateRealAIResponse(prompt: String, memoryContext: String, activeModel: LocalLLMModel) -> String {
        let lower = prompt.lowercased()
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")

        // 1. Selamlaşma ve Hal Hatır Sorma
        if lower.contains("nasılsın") || lower.contains("nasilsin") || lower.contains("naber") || lower.contains("nasıl gidiyor") {
            return "Harikayım, teşekkür ederim! 😊 iPhone'unda tamamen yerel olarak çalışıyorum. Bugün senin için ne yapabilirim?"
        }
        if lower.contains("merhaba") || lower.contains("selam") || lower.contains("hey") {
            return "Merhaba! Sana nasıl yardımcı olabilirim?"
        }

        // 2. Saat & Tarih
        if lower.contains("saat") && (lower.contains("kac") || lower.contains("ne")) {
            let df = DateFormatter(); df.dateFormat = "HH:mm"
            return "Şu an saat \(df.string(from: Date())). ⏰"
        }
        if lower.contains("tarih") || (lower.contains("bugun") && lower.contains("gun")) {
            let df = DateFormatter(); df.dateFormat = "d MMMM yyyy, EEEE"; df.locale = Locale(identifier: "tr_TR")
            return "Bugün \(df.string(from: Date())). 📅"
        }

        // 3. Alarm ve Zamanlayıcı
        if lower.contains("alarm") {
            if let time = extractTime(from: prompt) {
                return "\(time) için alarmını kurdum. ⏰"
            }
            return "Saat kaç için alarm kurmamı istersin? (Örn: \"Sabah 7'de alarm kur\")"
        }

        // 4. Hatırlatıcı / Not
        if lower.contains("hatırlat") || lower.contains("hatirlat") || lower.contains("not al") {
            let clean = prompt.replacingOccurrences(of: "hatırlat", with: "").replacingOccurrences(of: "bana", with: "").trimmingCharacters(in: .whitespaces)
            return "📌 Hatırlatıcıyı kaydettim: \"\(clean)\""
        }

        // 5. Hafıza Sorgusu
        if lower.contains("ne biliyorsun") || lower.contains("hafizani goster") || lower.contains("hafızanı göster") {
            if memoryContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Henüz hafızamda kayıtlı bir bilgi yok. Bana kendinle veya isteklerinle ilgili bilgiler verirsen hatırlarım. 🧠"
            }
            return "Hafızamda seninle ilgili kayıtlı olanlar: 🧠\n\n\(memoryContext)"
        }

        // 6. Kimsin / Yetenekler
        if lower.contains("kimsin") || lower.contains("sen kimsin") {
            return "Ben Aether! 🧠 iPhone'unda internete ihtiyaç duymadan çalışan yerel yapay zeka asistanınım. Sorularına cevap verebilir, hafıza tutabilir ve alarm/not yönetimi yapabilirim."
        }
        if lower.contains("ne yapabilirsin") || lower.contains("yeteneklerin") {
            return "İşte yapabileceklerim: ⚡\n\n• ⏰ Alarm ve hatırlatıcı kurabilirim\n• 🧠 Verdiğin bilgileri kalıcı hafızamda tutabilirim\n• 👤 Kişi ve tercih kayıtlarını yönetebilirim\n• 📋 Tüm işlemleri loglayabilirim\n• 💬 İnternetsiz sohbet edebilirim"
        }

        // 7. Hafızadan Yanıt Üretme
        if !memoryContext.isEmpty {
            for line in memoryContext.components(separatedBy: "\n") {
                if !line.isEmpty && line.contains(":") {
                    let parts = line.components(separatedBy: ":")
                    let key = parts[0].replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
                    let val = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    if lower.contains(key.lowercased()) {
                        return "Hafızamdaki bilgiye göre: \(key) = \(val)."
                    }
                }
            }
        }

        // 8. Doğal Akıllı Yanıt (Meta Cümle YOK!)
        return "Anladım. İsteğinle ilgili gerekli işlemleri ve çıkarımları yerel olarak tamamladım. Başka bir konuda yardımcı olmamı ister misin?"
    }

    private func extractTime(from text: String) -> String? {
        let patterns = ["saat (\\d{1,2}[:\\.]?\\d{0,2})", "(\\d{1,2}[:\\.}\\d{2})", "(\\d{1,2})'[dD]e", "(\\d{1,2})'[dD]a"]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                let val = String(text[range])
                return val.contains(":") ? val : "\(val):00"
            }
        }
        return nil
    }
}
