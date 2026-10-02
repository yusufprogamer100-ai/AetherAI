import SwiftUI

struct LogView: View {
    @EnvironmentObject var logManager: LogManager
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass").font(.system(size: 22)).foregroundColor(theme.accentColor)
                    Text("İşlem Logları").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                    Spacer()
                    if !logManager.logs.isEmpty {
                        Button(action: { logManager.clearAll() }) {
                            Text("Temizle").font(.caption).foregroundColor(.red.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                if logManager.logs.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text").font(.system(size: 48)).foregroundColor(theme.textSecondary)
                        Text("Henüz Log Yok").font(.headline).foregroundColor(theme.textPrimary)
                        Text("İşlem yaptıkça loglar\nburada görünecek").font(.subheadline).foregroundColor(theme.textSecondary).multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(logManager.logs) { log in LogRowView(log: log) }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

struct LogRowView: View {
    let log: ActionLog
    @EnvironmentObject var theme: AetherThemeManager

    var resultColor: Color {
        switch log.result {
        case "BASARILI": return .green
        case "BASARISIZ": return .red
        case "ONAY_BEKLIYOR": return .yellow
        case "ANLASILAMADI": return .orange
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(resultColor).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(log.action).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(theme.textPrimary)
                Text(log.detail).font(.system(size: 11)).foregroundColor(theme.textSecondary).lineLimit(1)
            }
            Spacer()
            Text(timeString(log.timestamp)).font(.system(size: 10, design: .monospaced)).foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(theme.cardBackground).cornerRadius(8)
    }

    private func timeString(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "HH:mm:ss"; return df.string(from: date)
    }
}
