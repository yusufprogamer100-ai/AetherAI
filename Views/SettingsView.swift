import SwiftUI

struct AetherSettingsView: View {
    @EnvironmentObject var theme: AetherThemeManager
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var logManager: LogManager
    @State private var showClearMemoryAlert = false
    @State private var showClearLogsAlert = false

    var body: some View {
        NavigationView {
            List {
                // MARK: - PROFİL BÖLÜMÜ
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                            .frame(width: 60, height: 60)
                            .background(Color.accentColor.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Aether AI v3.2")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Tamamen Yerel Yapay Zeka")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // MARK: - İSTATİSTİKLER
                Section(header: Text("SİSTEM İSTATİSTİKLERİ")) {
                    HStack {
                        Label("Kalıcı Hafıza Kayıtları", systemImage: "brain")
                        Spacer()
                        Text("\(memoryManager.memories.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Toplam İşlem Logları", systemImage: "doc.text")
                        Spacer()
                        Text("\(logManager.logs.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Bugünkü İşlemler", systemImage: "clock")
                        Spacer()
                        Text("\(logManager.todayLogs().count)")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - TEMİZLİK & VERİ YÖNETİMİ
                Section(header: Text("VERİ YÖNETİMİ")) {
                    Button(role: .destructive, action: { showClearMemoryAlert = true }) {
                        Label("Hafızayı Temizle", systemImage: "brain.head.profile")
                    }
                    Button(role: .destructive, action: { showClearLogsAlert = true }) {
                        Label("İşlem Loglarını Sil", systemImage: "trash")
                    }
                }

                // MARK: - GİZLİLİK BİLGİSİ
                Section(footer: Text("Aether AI, kişisel verilerinizi asla hiçbir sunucuya göndermez. Tüm çıkarım ve hafıza kayıtları yalnızca cihazınızın şifreli yerel depolama alanında gerçekleşir.")) {
                    HStack {
                        Label("Gizlilik Modu", systemImage: "lock.shield.fill")
                            .foregroundColor(.green)
                        Spacer()
                        Text("%100 Cihaz İçi")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Ayarlar")
            .alert("Hafızayı Temizle", isPresented: $showClearMemoryAlert) {
                Button("İptal", role: .cancel) {}
                Button("Temizle", role: .destructive) {
                    withAnimation { memoryManager.clearAll() }
                }
            } message: {
                Text("Kalıcı hafızadaki tüm kayıtlar silinecek. Bu işlem geri alınamaz.")
            }
            .alert("Logları Sil", isPresented: $showClearLogsAlert) {
                Button("İptal", role: .cancel) {}
                Button("Temizle", role: .destructive) {
                    withAnimation { logManager.clearAll() }
                }
            } message: {
                Text("Tüm işlem kütüğü silinecek.")
            }
        }
        .navigationViewStyle(.stack)
    }
}
