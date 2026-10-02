import SwiftUI

struct ChatView: View {
    @EnvironmentObject var brain: AetherBrain
    @EnvironmentObject var theme: AetherThemeManager
    @EnvironmentObject var llmEngine: LocalLLMEngine
    @State private var inputText: String = ""

    // Hızlı Komut Çipleri
    let promptChips = [
        "👋 Merhaba",
        "🧠 Ne biliyorsun?",
        "⏰ Sabah 07:00 alarm kur",
        "📌 Not al: Toplantı var",
        "📋 Logları göster"
    ]

    var body: some View {
        ZStack {
            // Arka Plan Gradyanı
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Üst Bar (Header)
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.accentColor.opacity(0.18))
                            .frame(width: 44, height: 44)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 22))
                            .foregroundColor(theme.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Aether AI")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(theme.textPrimary)

                            Text("v3.2")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.accentColor.opacity(0.2))
                                .foregroundColor(theme.accentColor)
                                .cornerRadius(6)
                        }

                        HStack(spacing: 6) {
                            Circle()
                                .fill(llmEngine.isModelLoaded ? Color.green : Color.red)
                                .frame(width: 6, height: 6)

                            if llmEngine.isModelLoaded, let model = llmEngine.activeModel {
                                Text("Yerel: \(model.name)")
                                    .font(.caption2)
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(1)
                            } else {
                                Text("MODEL SEÇİLMEDİ (Çevrimdışı)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    Spacer()

                    // Tema Değiştirici Buton
                    Button(action: { theme.cycleTheme() }) {
                        ZStack {
                            Circle()
                                .fill(theme.cardBackground)
                                .frame(width: 38, height: 38)
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.accentColor)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().background(Color.white.opacity(0.08))

                // MARK: - Model Yok Uyarısı Banner'ı (Model indirilmeyince çıkar)
                if !llmEngine.isModelLoaded {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Yerel yapay zeka modeli yüklü değil. 'Modeller' sekmesinden ücretsiz model indir.")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.2))
                }

                // MARK: - Mesaj Listesi
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(brain.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }

                            if brain.isThinking {
                                HStack {
                                    TypingIndicatorView()
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .id("typing")
                            }
                        }
                        .padding(.vertical, 14)
                    }
                    .onChange(of: brain.messages.count) { _ in
                        withAnimation {
                            if let last = brain.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // MARK: - Hızlı Komut Çipleri
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(promptChips, id: \.self) { chip in
                            Button(action: {
                                inputText = chip.replacingOccurrences(of: "👋 ", with: "").replacingOccurrences(of: "🧠 ", with: "").replacingOccurrences(of: "⏰ ", with: "").replacingOccurrences(of: "📌 ", with: "").replacingOccurrences(of: "📋 ", with: "")
                                sendMessage()
                            }) {
                                Text(chip)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(theme.cardBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }

                // MARK: - Giriş Alanı (Input Box)
                HStack(spacing: 10) {
                    TextField("Aether'e bir emrin veya sorun var mı?...", text: $inputText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(theme.inputBackground)
                        .cornerRadius(24)
                        .foregroundColor(theme.textPrimary)
                        .submitLabel(.send)
                        .onSubmit { sendMessage() }

                    Button(action: { sendMessage() }) {
                        ZStack {
                            Circle()
                                .fill(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.25) : theme.accentColor)
                                .frame(width: 44, height: 44)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.4))
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        brain.processInput(text)
        inputText = ""
    }
}

// MARK: - Şık Mesaj Baloncuğu
struct MessageBubbleView: View {
    let message: ChatMessage
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 50) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isWarning {
                    // UYARI MESAJI KARTI
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("UYARI")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        Text(message.text)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .padding(14)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(18)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.red.opacity(0.4), lineWidth: 1))
                } else {
                    // NORMAL MESAJ
                    Text(message.text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(message.isUser ? theme.userBubbleColor : theme.botBubbleColor)
                        .cornerRadius(20)
                }

                Text(timeString(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 6)
            }

            if !message.isUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal, 14)
    }

    private func timeString(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "HH:mm"; return df.string(from: date)
    }
}

// MARK: - Yazıyor Göstergesi
struct TypingIndicatorView: View {
    @State private var dot1: Double = 0.3
    @State private var dot2: Double = 0.3
    @State private var dot3: Double = 0.3
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(theme.accentColor).frame(width: 8, height: 8).opacity(dot1)
            Circle().fill(theme.accentColor).frame(width: 8, height: 8).opacity(dot2)
            Circle().fill(theme.accentColor).frame(width: 8, height: 8).opacity(dot3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.botBubbleColor)
        .cornerRadius(20)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) { dot1 = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) { dot2 = 1.0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever()) { dot3 = 1.0 }
            }
        }
    }
}
