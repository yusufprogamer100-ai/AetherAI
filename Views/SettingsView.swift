import SwiftUI

struct AetherSettingsView: View {
    @EnvironmentObject var theme: AetherThemeManager
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var logManager: LogManager
    @State private var showClearMemoryAlert = false
    @State private var showClearLogsAlert = false

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Başlık
                    HStack {
                        Image(systemName: "gearshape.fill").font(.system(size: 22)).foregroundColor(theme.accentColor)
                        Text("Ayarlar").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.top, 12)

                    // Profil kartı
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(theme.accentColor.opacity(0.15)).frame(width: 80, height: 80)
                            Image(systemName: "brain.head.profile").font(.system(size: 36)).foregroundColor(theme.accentColor)
                        }
                        Text("Aether v3.2").font(.system(size: 18, weight: .bold)).foregroundColor(theme.textPrimary)
                        Text("Yerel Yapay Zeka Asistanı").font(.caption).foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
                    .background(theme.cardBackground).cornerRadius(16).padding(.horizontal, 16)

                    // Tema seçimi
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TEMA").font(.system(size: 12, weight: .semibold)).foregroundColor(theme.textSecondary).padding(.leading, 4)
                        HStack(spacing: 12) {
                            ForEach(theme.themes, id: \.self) { themeName in
                                Button(action: { theme.currentTheme = themeName }) {
                                    VStack(spacing: 6) {
                                        Circle().fill(themeColor(themeName)).frame(width: 40, height: 40)
                                            .overlay(Circle().stroke(theme.currentTheme == themeName ? Color.white : Color.clear, lineWidth: 2))
                                        Text(themeDisplayName(themeName)).font(.system(size: 9)).foregroundColor(theme.textSecondary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(theme.cardBackground).cornerRadius(12)
                    }
                    .padding(.horizontal, 16)

                    // İstatistikler
                    VStack(alignment: .leading, spacing: 12) {
                        Text("İSTATİSTİKLER").font(.system(size: 12, weight: .semibold)).foregroundColor(theme.textSecondary).padding(.leading, 4)
                        VStack(spacing: 0) {
                            SettingsStatRow(icon: "brain", label: "Hafıza Kayıtları", valueStr: "\(memoryManager.memories.count)")
                            Divider().background(Color.white.opacity(0.1))
                            SettingsStatRow(icon: "doc.text", label: "Toplam Log", valueStr: "\(logManager.logs.count)")
                            Divider().background(Color.white.opacity(0.1))
                            SettingsStatRow(icon: "clock", label: "Bugünkü İşlem", valueStr: "\(logManager.todayLogs().count)")
                        }
                        .background(theme.cardBackground).cornerRadius(12)
                    }
                    .padding(.horizontal, 16)

                    // Veri yönetimi
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VERİ YÖNETİMİ").font(.system(size: 12, weight: .semibold)).foregroundColor(theme.textSecondary).padding(.leading, 4)
                        VStack(spacing: 0) {
                            Button(action: { showClearMemoryAlert = true }) {
                                SettingsDangerRow(icon: "brain", label: "Hafızayı Temizle")
                            }
                            Divider().background(Color.white.opacity(0.1))
                            Button(action: { showClearLogsAlert = true }) {
                                SettingsDangerRow(icon: "trash", label: "Logları Temizle")
                            }
                        }
                        .background(theme.cardBackground).cornerRadius(12)
                    }
                    .padding(.horizontal, 16)

                    // Hakkında
                    VStack(spacing: 8) {
                        Text("Aether AI v3.2").font(.system(size: 13, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("Tamamen yerel. Tamamen gizli. Tamamen senin.").font(.system(size: 11)).foregroundColor(theme.textSecondary.opacity(0.6))
                        Text("Hiçbir verin cihazdan dışarı çıkmaz.").font(.system(size: 11)).foregroundColor(theme.textSecondary.opacity(0.6))
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .alert("Hafızayı Temizle", isPresented: $showClearMemoryAlert) {
            Button("İptal", role: .cancel) {}
            Button("Temizle", role: .destructive) { memoryManager.clearAll() }
        } message: { Text("Tüm hafıza kayıtları silinecek. Bu işlem geri alınamaz.") }
        .alert("Logları Temizle", isPresented: $showClearLogsAlert) {
            Button("İptal", role: .cancel) {}
            Button("Temizle", role: .destructive) { logManager.clearAll() }
        } message: { Text("Tüm işlem logları silinecek. Bu işlem geri alınamaz.") }
    }

    private func themeColor(_ name: String) -> Color {
        switch name {
        case "midnight": return Color(red: 0.3, green: 0.3, blue: 0.8)
        case "ocean": return Color(red: 0.1, green: 0.5, blue: 0.8)
        case "aurora": return Color(red: 0.1, green: 0.7, blue: 0.5)
        case "crimson": return Color(red: 0.8, green: 0.2, blue: 0.2)
        case "obsidian": return Color(red: 0.4, green: 0.4, blue: 0.45)
        default: return .gray
        }
    }

    private func themeDisplayName(_ name: String) -> String {
        switch name {
        case "midnight": return "Gece"
        case "ocean": return "Okyanus"
        case "aurora": return "Aurora"
        case "crimson": return "Kızıl"
        case "obsidian": return "Obsidyen"
        default: return name
        }
    }
}

struct SettingsStatRow: View {
    let icon: String
    let label: String
    let valueStr: String
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(theme.accentColor).frame(width: 30)
            Text(label).font(.system(size: 14)).foregroundColor(theme.textPrimary)
            Spacer()
            Text(valueStr).font(.system(size: 14, weight: .medium, design: .monospaced)).foregroundColor(theme.accentColor)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }
}

struct SettingsDangerRow: View {
    let icon: String
    let label: String
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        HStack {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.red.opacity(0.7)).frame(width: 30)
            Text(label).font(.system(size: 14)).foregroundColor(.red.opacity(0.7))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }
}
