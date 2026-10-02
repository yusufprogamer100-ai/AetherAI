import SwiftUI

struct ChatView: View {
    @EnvironmentObject var brain: AetherBrain
    @EnvironmentObject var theme: AetherThemeManager
    @EnvironmentObject var llmEngine: LocalLLMEngine
    @State private var inputText: String = ""

    let quickActions = [
        "👋 Merhaba",
        "🧠 Hafızamı göster",
        "⏰ Sabah 07:00 alarm kur",
        "📌 Not al: Toplantı var",
        "📋 Loglar"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Öz Hakiki iOS Sistem Arka Planı
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: - Aktif Model Durumu (Apple Header Style)
                    HStack(spacing: 8) {
                        Circle()
                            .fill(llmEngine.isModelLoaded ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)

                        if llmEngine.isModelLoaded, let model = llmEngine.activeModel {
                            Text("Aktif Yerel Model: \(model.name)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        } else {
                            Text("⚠️ Model Yüklü Değil (Modeller Sekmesinden İndirin)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))

                    Divider()

                    // MARK: - Mesaj Listesi
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(brain.messages) { message in
                                    NativeMessageBubble(message: message)
                                        .id(message.id)
                                }

                                if brain.isThinking {
                                    HStack {
                                        NativeTypingBubble()
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .id("typing")
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        .onChange(of: brain.messages.count) { _ in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if let last = brain.messages.last {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // MARK: - Hızlı Eylem Çipleri (Apple Capsule Style)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickActions, id: \.self) { chip in
                                Button(action: {
                                    let clean = chip.replacingOccurrences(of: "👋 ", with: "").replacingOccurrences(of: "🧠 ", with: "").replacingOccurrences(of: "⏰ ", with: "").replacingOccurrences(of: "📌 ", with: "").replacingOccurrences(of: "📋 ", with: "")
                                    inputText = clean
                                    sendMessage()
                                }) {
                                    Text(chip)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                                        .clipShape(Capsule())
                                        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    Divider()

                    // MARK: - Giriş Alanı (iMessage Bar Style)
                    HStack(spacing: 10) {
                        TextField("Aether'e bir mesaj yaz...", text: $inputText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .submitLabel(.send)
                            .onSubmit { sendMessage() }

                        Button(action: { sendMessage() }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary.opacity(0.4) : .accentColor)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .systemBackground))
                }
            }
            .navigationTitle("Aether AI")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        brain.processInput(text)
        inputText = ""
    }
}

// MARK: - Orijinal iOS iMessage Tarzı Balon
struct NativeMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isWarning {
                    // UYARI KARTI
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Sistem Uyarısı")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        Text(message.text)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                } else {
                    // NORMAL İMESSAGE MESAJI
                    Text(message.text)
                        .font(.body)
                        .foregroundColor(message.isUser ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(message.isUser ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                }

                Text(timeString(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            if !message.isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 16)
    }

    private func timeString(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "HH:mm"; return df.string(from: date)
    }
}

// MARK: - iOS Tarzı Üç Nokta Animasyonu
struct NativeTypingBubble: View {
    @State private var dot1: Double = 0.3
    @State private var dot2: Double = 0.3
    @State private var dot3: Double = 0.3

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(Color.secondary).frame(width: 7, height: 7).opacity(dot1)
            Circle().fill(Color.secondary).frame(width: 7, height: 7).opacity(dot2)
            Circle().fill(Color.secondary).frame(width: 7, height: 7).opacity(dot3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
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
