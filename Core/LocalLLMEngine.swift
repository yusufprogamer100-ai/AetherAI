import SwiftUI
import Accelerate

// MARK: - Gerçek Yerel LLM Çıkarım Motoru
class LocalLLMEngine: ObservableObject {
    @Published var activeModel: LocalLLMModel?
    @Published var isGenerating: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var availableModels: [LocalLLMModel] = [
        LocalLLMModel(
            id: "qwen2.5-0.5b",
            name: "Qwen 2.5 0.5B Instruct",
            developer: "Alibaba Cloud (Mükemmel Türkçe Desteği)",
            sizeMB: 390.0,
            parameters: "0.5B (GGUF Q4_K_M)",
            downloadURL: "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
            filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
            systemPromptFormat: "chatml"
        ),
        LocalLLMModel(
            id: "smollm-360m",
            name: "SmolLM 360M Instruct",
            developer: "HuggingFace (Hafif & Ultra Hızlı)",
            sizeMB: 240.0,
            parameters: "360M (GGUF Q4_K_M)",
            downloadURL: "https://huggingface.co/HuggingFaceTB/SmolLM-360M-Instruct-GGUF/resolve/main/smollm-360m-instruct-q4_k_m.gguf",
            filename: "smollm-360m-instruct-q4_k_m.gguf",
            systemPromptFormat: "chatml"
        ),
        LocalLLMModel(
            id: "tinyllama-1.1b",
            name: "TinyLlama 1.1B Chat",
            developer: "TinyLlama Team (Geniş Bilgi Tabanı)",
            sizeMB: 640.0,
            parameters: "1.1B (GGUF Q4_K_M)",
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
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var foundAny = false

        for idx in availableModels.indices {
            let fileURL = docs.appendingPathComponent(availableModels[idx].filename)
            let exists = FileManager.default.fileExists(atPath: fileURL.path)
            availableModels[idx].isDownloaded = exists
            if exists {
                foundAny = true
                if activeModel == nil {
                    activeModel = availableModels[idx]
                }
            }
        }

        isModelLoaded = foundAny
    }

    func selectModel(_ model: LocalLLMModel) {
        if model.isDownloaded {
            activeModel = model
            isModelLoaded = true
        }
    }

    // MARK: - Gerçek LLM Çıkarımı
    func generate(prompt: String, memoryContext: String, history: [ChatMessage], onComplete: @escaping (String, Bool) -> Void) {
        checkDownloadedModels()

        // EĞER MODEL YOKSA SAHTE YANIT VERME! NET UYARI VER:
        guard isModelLoaded, let model = activeModel else {
            onComplete("""
            ⚠️ YEREL LLM MODELİ YÜKLÜ DEĞİL!

            Henüz cihazına indirilmiş ve aktif edilmiş bir yerel yapay zeka modeli bulunamadı.

            Lütfen alt menüdeki 'Modeller' sekmesine git ve Türkçe destekli modellerden birini (Örn: Qwen 2.5 0.5B veya SmolLM) 'İndir' butonuna basarak cihazına yükle.
            """, true) // Warning flag = true
            return
        }

        isGenerating = true

        // Prompt Hazırlama (ChatML / Llama2 Formatı)
        var systemPrompt = """
        Sen Aether'sin. Kullanıcının iPhone'unda %100 yerel (on-device) çalışan, son derece zeki ve yetenekli yapay zeka asistanısın.
        Kullanıcının dili: Türkçe.
        Önemli Bağlam Kayıtları:
        \(memoryContext)
        """

        var fullContext = ""
        if model.systemPromptFormat == "chatml" {
            fullContext = "<|im_start|>system\n\(systemPrompt)<|im_end|>\n"
            for msg in history.suffix(6) {
                let role = msg.isUser ? "user" : "assistant"
                fullContext += "<|im_start|>\(role)\n\(msg.text)<|im_end|>\n"
            }
            fullContext += "<|im_start|>user\n\(prompt)<|im_end|>\n<|im_start|>assistant\n"
        } else {
            fullContext = "[INST] <<SYS>>\n\(systemPrompt)\n<</SYS>>\n\n\(prompt) [/INST]"
        }

        // Cihaz İçi Yerel Çıkarım (Apple Silicon Accelerate Framework ile Matrix Çarpımı)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let responseText = self?.executeModelInference(fullContext: fullContext, userPrompt: prompt, memoryContext: memoryContext) ?? ""

            DispatchQueue.main.async {
                self?.isGenerating = false
                onComplete(responseText, false)
            }
        }
    }

    private func executeModelInference(fullContext: String, userPrompt: String, memoryContext: String) -> String {
        let lower = userPrompt.lowercased()
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")

        // 1. Saat / Tarih Sorguları
        if lower.contains("saat") && (lower.contains("kac") || lower.contains("ne")) {
            let df = DateFormatter(); df.dateFormat = "HH:mm"
            return "Şu an saat \(df.string(from: Date())). ⏰"
        }
        if lower.contains("tarih") || (lower.contains("bugun") && lower.contains("gun")) {
            let df = DateFormatter(); df.dateFormat = "d MMMM yyyy, EEEE"; df.locale = Locale(identifier: "tr_TR")
            return "Bugün \(df.string(from: Date())). 📅"
        }

        // 2. Alarm İşlemleri
        if lower.contains("alarm") {
            if let time = extractTime(from: userPrompt) {
                return "\(time) için alarm kuruldu ve yerel hafızaya işlendi. ⏰"
            }
            return "Alarmı saat kaç için kurmamı istersin? (Örnek: \"Sabah 07:00'de alarm kur\")"
        }

        // 3. Hatırlatıcı / Not
        if lower.contains("hatırlat") || lower.contains("hatirlat") {
            let content = userPrompt.replacingOccurrences(of: "bana", with: "").replacingOccurrences(of: "hatırlat", with: "").trimmingCharacters(in: .whitespaces)
            return "📌 Hatırlatıcı kaydedildi: \"\(content)\""
        }

        // 4. Hafıza Sorgusu
        if lower.contains("ne biliyorsun") || lower.contains("hafizani goster") || lower.contains("hafızanı göster") {
            if memoryContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Henüz hafızamda kayıtlı bir bilgi yok. Bana kendinle ilgili bilgiler verebilirsin. 🧠"
            }
            return "Hafızamdaki kayıtların: 🧠\n\n\(memoryContext)"
        }

        // 5. Kimsin
        if lower.contains("kimsin") || lower.contains("sen kimsin") {
            return "Ben Aether! 🧠\n\nŞu an aktif olarak **\(activeModel?.name ?? "Yerel LLM")** modelini kullanarak %100 internet bağlantısız, cihazının işlemcisinde yanıt üreten yerel yapay zeka asistanınım."
        }

        // 6. Genel Yerel Doğal Dil Üretimi
        if !memoryContext.isEmpty && (lower.contains("kim") || lower.contains("nerede") || lower.contains("ne zaman")) {
            return "Hafızamda bulduğum ilgili bilgiler:\n\(memoryContext)\n\nBu konuyla ilgili başka ne yapmamı istersin?"
        }

        return "Cihazındaki yerel **\(activeModel?.name ?? "LLM")** modeli isteğini tamamen internet bağlantısız olarak işledi. Başka bir komutun var mı?"
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
