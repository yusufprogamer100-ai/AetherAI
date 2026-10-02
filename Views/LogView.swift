import SwiftUI

struct LogView: View {
    @EnvironmentObject var logManager: LogManager

    var body: some View {
        NavigationView {
            List {
                if logManager.logs.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Henüz Log Yok")
                            .font(.headline)
                        Text("Yapılan tüm cihaz içi işlemler burada kayıt altına alınır.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    Section(header: Text("İŞLEM KÜTÜĞÜ (\(logManager.logs.count))")) {
                        ForEach(logManager.logs) { log in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(statusColor(log.result))
                                    .frame(width: 8, height: 8)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.action)
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.semibold)
                                    Text(log.detail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(timeString(log.timestamp))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Loglar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !logManager.logs.isEmpty {
                        Button("Temizle") {
                            withAnimation {
                                logManager.clearAll()
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func statusColor(_ result: String) -> Color {
        switch result {
        case "BASARILI": return .green
        case "MODEL_YOK": return .orange
        case "BASARISIZ": return .red
        default: return .gray
        }
    }

    private func timeString(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "HH:mm:ss"; return df.string(from: date)
    }
}
