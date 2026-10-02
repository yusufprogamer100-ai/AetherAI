import SwiftUI

class AetherBrain: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isThinking: Bool = false

    let memoryManager: MemoryManager
    let logManager: LogManager

    init(memoryManager: MemoryManager, logManager: LogManager) {
        self.memoryManager = memoryManager
        self.logManager = logManager
        messages.append(ChatMessage(
            text: "Merhaba! Ben Aether, senin kişisel yapay zeka asistanın. 🧠\n\nTamamen yerel çalışıyorum — hiçbir verin dışarı çıkmaz.\n\n\"Ne yapabilirsin?\" diyerek başlayabilirsin!",
            isUser: false
        ))
    }

    func processInput(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(ChatMessage(text: trimmed, isUser: true))
        isThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self = self else { return }
            let response = self.generateResponse(for: trimmed)
            self.messages.append(ChatMessage(text: response, isUser: false))
            self.isThinking = false
        }
    }

    private func generateResponse(for input: String) -> String {
        let lower = normalize(input)

        // Selamlama
        if containsAny(lower, ["merhaba", "selam", "hey", "naber", "nasilsin", "iyi misin"]) {
            logManager.log(action: "SELAMLASMA", detail: input, result: "BASARILI")
            return randomFrom(["Merhaba! Bugün sana nasıl yardımcı olabilirim? 😊", "Selam! Bir isteğin var mı?", "Hey! Hazırım, ne yapmamı istersin?"])
        }

        // Saat
        if containsAny(lower, ["saat kac", "saat ne", "su an saat"]) {
            let df = DateFormatter(); df.dateFormat = "HH:mm"; df.locale = Locale(identifier: "tr_TR")
            logManager.log(action: "SAAT_SORGU", detail: "Saat soruldu", result: "BASARILI")
            return "Şu an saat \(df.string(from: Date())). ⏰"
        }

        // Tarih
        if containsAny(lower, ["bugun ne gun", "tarih ne", "hangi gun", "bugunun tarihi"]) {
            let df = DateFormatter(); df.dateFormat = "d MMMM yyyy, EEEE"; df.locale = Locale(identifier: "tr_TR")
            logManager.log(action: "TARIH_SORGU", detail: "Tarih soruldu", result: "BASARILI")
            return "Bugün \(df.string(from: Date())). 📅"
        }

        // Alarm
        if containsAny(lower, ["alarm kur", "uyandır", "alarm ayarla", "alarm"]) && containsAny(lower, ["kur", "ayarla", "uyandır"]) {
            if let time = extractTime(from: input) {
                logManager.log(action: "ALARM_KUR", detail: time, result: "BASARILI")
                memoryManager.save(category: MemoryCategory.routines.rawValue, key: "Son Alarm", value: time, importance: 0.7)
                return "\(time) için alarm kurdum. ⏰\nHafızama da kaydettim."
            }
            return "Saat kaç için alarm kurmamı istersin? Örnek: \"Sabah 7'de alarm kur\""
        }

        // Hatırlatıcı
        if containsAny(lower, ["hatırlat", "hatırlatıcı", "unutma"]) {
            let content = input.replacingOccurrences(of: "bana", with: "").replacingOccurrences(of: "hatırlatıcı", with: "").replacingOccurrences(of: "hatırlat", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if content.count > 2 {
                memoryManager.save(category: MemoryCategory.general.rawValue, key: "Hatırlatıcı", value: content, importance: 0.8)
                logManager.log(action: "HATIRLATICI", detail: content, result: "BASARILI")
                return "Tamam, hatırlatıcı oluşturdum: \"\(content)\" 📌\nKalıcı hafızama kaydettim."
            }
            return "Neyi hatırlatmamı istersin?"
        }

        // Kaydet / not al
        if containsAny(lower, ["kaydet", "not al", "hafizaya al", "bunu hatirla"]) {
            memoryManager.save(category: MemoryCategory.general.rawValue, key: "Not", value: input, importance: 0.6)
            logManager.log(action: "HAFIZA_KAYIT", detail: input, result: "BASARILI")
            return "Hafızama kaydettim. 🧠\n\"Hafızanı göster\" diyerek istediğin zaman hatırlayabilirsin."
        }

        // Kişi bilgisi kaydetme
        let relations: [(key: String, variants: [String])] = [
            ("Kardeş", ["kardesim", "kardeşim"]),
            ("Anne", ["annem"]),
            ("Baba", ["babam"]),
            ("Arkadaş", ["arkadasim", "arkadaşım"]),
            ("Sevgili", ["sevgilim"]),
            ("Abi", ["abim"]),
            ("Abla", ["ablam"])
        ]
        for rel in relations {
            if containsAny(lower, rel.variants) {
                let words = input.components(separatedBy: " ")
                if let last = words.last, last.count > 1 {
                    memoryManager.save(category: MemoryCategory.people.rawValue, key: rel.key, value: last.capitalized, importance: 0.9)
                    logManager.log(action: "KISI_KAYIT", detail: "\(rel.key): \(last.capitalized)", result: "BASARILI")
                    return "Anlaşıldı! \(rel.key) olarak \(last.capitalized)'i kaydettim. 👤"
                }
            }
        }

        // Tercih
        if containsAny(lower, ["sevdigim", "favorim", "tercihim", "en sevdigim"]) {
            memoryManager.save(category: MemoryCategory.preferences.rawValue, key: "Tercih", value: input, importance: 0.6)
            logManager.log(action: "TERCIH_KAYIT", detail: input, result: "BASARILI")
            return "Tercihini kaydettim! ❤️"
        }

        // Hafızayı göster
        if containsAny(lower, ["ne biliyorsun", "hafizani goster", "hafızanı göster", "neler biliyorsun", "kayıtları göster"]) {
            if memoryManager.memories.isEmpty { return "Henüz hafızamda kayıtlı bir bilgi yok. Bana bir şeyler söylersen hatırlarım! 🧠" }
            var response = "İşte hafızamdaki kayıtlar: 🧠\n\n"
            for (category, entries) in memoryManager.categorizedMemories {
                response += "📂 \(category):\n"
                for entry in entries { response += "  • \(entry.key): \(entry.value)\n" }
                response += "\n"
            }
            logManager.log(action: "HAFIZA_SORGU", detail: "Tüm hafıza gösterildi", result: "BASARILI")
            return response
        }

        // Logları göster
        if containsAny(lower, ["loglari goster", "logları göster", "gecmisi goster", "ne yaptik"]) {
            let recent = logManager.getRecent(count: 10)
            if recent.isEmpty { return "Henüz kayıtlı bir işlem yok." }
            var response = "Son işlemler: 📋\n\n"
            for l in recent { response += "\(l.formattedLog)\n" }
            logManager.log(action: "LOG_SORGU", detail: "Son 10 log gösterildi", result: "BASARILI")
            return response
        }

        // Hafızayı sil
        if containsAny(lower, ["hafızayı temizle", "hepsini unut", "her seyi unut", "hepsini sil"]) {
            memoryManager.clearAll()
            logManager.log(action: "HAFIZA_TEMIZLE", detail: "Tüm hafıza silindi", result: "BASARILI")
            return "Tüm hafızamı temizledim. 🗑️ Artık hiçbir şey hatırlamıyorum."
        }

        // Kimsin
        if containsAny(lower, ["kimsin", "sen kimsin", "nesin", "aether ne", "kendin hakkinda"]) {
            return "Ben Aether! 🌟\n\nSenin iPhone'unda tamamen yerel olarak çalışan kişisel yapay zeka asistanın.\n\n• 🧠 Hafızam var — söylediklerini hatırlarım\n• 📋 Loglarım var — her şeyi kaydederim\n• 🔒 Tamamen gizliyim — hiçbir verin dışarı çıkmaz\n• ⚡ Sadece sana hizmet ederim\n\nBana istediğini sorabilir veya komut verebilirsin!"
        }

        // Teşekkür
        if containsAny(lower, ["tesekkur", "teşekkür", "sagol", "sağol", "eyv", "eyw"]) {
            return randomFrom(["Rica ederim! Her zaman buradayım. 😊", "Ne demek, bu benim görevim! ✨", "Her zaman! Başka bir isteğin olursa söyle. 🙌"])
        }

        // Yetenekler
        if containsAny(lower, ["ne yapabilirsin", "neler yapabilirsin", "yeteneklerin", "komutlar", "yardim", "yardım"]) {
            return "İşte yapabileceklerim: ⚡\n\n⏰ Alarm ve hatırlatıcı kurma\n🧠 Bilgi hafızaya alma ve hatırlama\n👤 Kişi bilgisi kaydetme\n❤️ Tercihlerini öğrenme\n📋 İşlem loglarını gösterme\n🗑️ İstediğin bilgiyi unutma\n⏰ Saat ve tarih söyleme\n💬 Seninle sohbet etme\n\nÖrnekler:\n• \"Kardeşimin adı Ayşe\"\n• \"Sabah 7'de alarm kur\"\n• \"Ne biliyorsun?\"\n• \"Logları göster\"\n• \"Bunu hatırla: yarın toplantı var\""
        }

        // Varsayılan
        logManager.log(action: "BILINMEYEN", detail: input, result: "ANLASILAMADI")
        return randomFrom([
            "Hmm, bunu tam anlayamadım. Farklı bir şekilde söyler misin? 🤔",
            "Bu komutu henüz bilmiyorum. \"Ne yapabilirsin\" diyerek yeteneklerimi görebilirsin.",
            "Anlayamadım. Daha basit bir şekilde ifade edebilir misin?"
        ])
    }

    // MARK: - Yardımcı Fonksiyonlar
    private func normalize(_ text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")
    }

    private func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        return keywords.contains { text.contains($0) }
    }

    private func randomFrom(_ options: [String]) -> String {
        return options.randomElement() ?? options[0]
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
        // Manuel: sayı + keyword
        let words = text.components(separatedBy: " ")
        for (i, word) in words.enumerated() {
            if let num = Int(word), num >= 0, num <= 23 {
                let context = words.dropFirst(i).prefix(3).joined(separator: " ").lowercased()
                if context.contains("de") || context.contains("da") || context.contains("sabah") || context.contains("akşam") {
                    return "\(String(format: "%02d", num)):00"
                }
            }
        }
        return nil
    }
}
