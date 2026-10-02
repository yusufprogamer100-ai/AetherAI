import SwiftUI

// MARK: - Ana Sohbet Ekranı
struct ChatView: View {
    @EnvironmentObject var brain: AetherBrain
    @EnvironmentObject var theme: AetherThemeManager
    @State private var inputText: String = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Üst bar
                HStack {
                    ZStack {
                        Circle().fill(theme.accentColor.opacity(0.2)).frame(width: 40, height: 40)
                        Image(systemName: "brain.head.profile").font(.system(size: 20)).foregroundColor(theme.accentColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aether").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text(brain.isThinking ? "Düşünüyor..." : "Çevrimiçi").font(.caption2).foregroundColor(theme.textSecondary)
                        }
                    }
                    Spacer()
                    Button(action: { theme.cycleTheme() }) {
                        Image(systemName: "paintpalette.fill").font(.system(size: 18)).foregroundColor(theme.accentColor)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                Divider().background(Color.white.opacity(0.1))

                // Mesajlar
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(brain.messages) { message in
                                MessageBubbleView(message: message).id(message.id)
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
                        .padding(.vertical, 12)
                    }
                    .onChange(of: brain.messages.count) { _ in
                        withAnimation {
                            if let last = brain.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onChange(of: brain.isThinking) { thinking in
                        if thinking { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                    }
                }

                // Giriş
                HStack(spacing: 10) {
                    TextField("Bir şey yaz...", text: $inputText)
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(theme.inputBackground)
                        .cornerRadius(24)
                        .foregroundColor(theme.textPrimary)
                        .submitLabel(.send)
                        .onSubmit { sendMessage() }

                    Button(action: { sendMessage() }) {
                        ZStack {
                            Circle()
                                .fill(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : theme.accentColor)
                                .frame(width: 44, height: 44)
                            Image(systemName: "arrow.up").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 12).padding(.vertical, 10).background(Color.black.opacity(0.3))
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

// MARK: - Mesaj Baloncuğu
struct MessageBubbleView: View {
    let message: ChatMessage
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(message.isUser ? theme.userBubbleColor : theme.botBubbleColor)
                    .cornerRadius(18)
                Text(timeString(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(theme.textSecondary)
                    .padding(.horizontal, 6)
            }
            if !message.isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
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
        HStack(spacing: 4) {
            Circle().fill(theme.accentColor).frame(width: 8, height: 8).opacity(dot1)
            Circle().fill(theme.accentColor).frame(width: 8, height: 8).opacity(dot2)
            Circle().fill(theme.accentColor).frame(width: 8, height: 8).opacity(dot3)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(theme.botBubbleColor).cornerRadius(18)
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
