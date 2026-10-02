import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var llmEngine: LocalLLMEngine
    @EnvironmentObject var theme: AetherThemeManager
    @State private var showLogTerminal: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    HStack {
                        ZStack {
                            Circle().fill(theme.accentColor.opacity(0.15)).frame(width: 44, height: 44)
                            Image(systemName: "cpu.fill")
                                .font(.system(size: 22))
                                .foregroundColor(theme.accentColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yerel LLM Modelleri")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(theme.textPrimary)
                            Text("HuggingFace GGUF Modelleri")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // CANLI İNDİRME KARTI (İndirme Olunca Otomatik Açılır)
                    if llmEngine.downloader.progressInfo.isDownloading {
                        let info = llmEngine.downloader.progressInfo
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .tint(theme.accentColor)
                                    Text("MODEL İNDİRİLİYOR...")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(theme.accentColor)
                                }
                                Spacer()
                                Text(String(format: "%.1f MB/s", info.speedMBps))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                            }

                            // Yüzde Çubuğu
                            VStack(spacing: 6) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 10)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(colors: [theme.accentColor, .green], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .frame(width: geo.size.width * CGFloat(info.percentage / 100.0), height: 10)
                                    }
                                }
                                .frame(height: 10)

                                HStack {
                                    Text(String(format: "%.1f MB / %.1f MB", info.downloadedMB, info.totalMB))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(theme.textSecondary)
                                    Spacer()
                                    Text(String(format: "%%%.1f", info.percentage))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(theme.textPrimary)
                                }
                            }

                            // Terminal İptal & Gizle Butonları
                            HStack {
                                Button(action: { showLogTerminal.toggle() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "terminal.fill")
                                        Text(showLogTerminal ? "Logları Gizle" : "İndirme Loglarını Gör (\(info.logs.count))")
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(theme.accentColor)
                                }

                                Spacer()

                                Button(action: { llmEngine.downloader.cancelDownload() }) {
                                    Text("İptal Et")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.15))
                                        .cornerRadius(8)
                                }
                            }

                            // CANLI TERMINAL LOG PENCERESİ (Gerçek HTTP Bağlantı Verileri)
                            if showLogTerminal {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(info.logs, id: \.self) { logLine in
                                            Text(logLine)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(logLine.contains("❌") ? .red : (logLine.contains("⚡") ? .yellow : .green))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .padding(10)
                                }
                                .frame(height: 140)
                                .background(Color.black.opacity(0.85))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            }
                        }
                        .padding(16)
                        .background(theme.cardBackground)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.accentColor.opacity(0.5), lineWidth: 1.5))
                        .padding(.horizontal, 16)
                    }

                    // AKTİF MODEL KARTI
                    if let active = llmEngine.activeModel, active.isDownloaded {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("ŞU ANKİ AKTİF YEREL MOTOR", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.green)
                                Spacer()
                                Text("RAM: Ready")
                                    .font(.caption2)
                                    .foregroundColor(theme.textSecondary)
                            }

                            Text(active.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(theme.textPrimary)

                            Text(active.developer)
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)

                            HStack {
                                Label(active.parameters, systemImage: "memorychip")
                                Spacer()
                                Label(String(format: "%.0f MB", active.sizeMB), systemImage: "internaldrive")
                            }
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary)
                        }
                        .padding(16)
                        .background(theme.cardBackground)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.6), lineWidth: 1.5))
                        .padding(.horizontal, 16)
                    } else {
                        // UYARI KARTI (Hiç Model Yoksa)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("MODEL SEÇİLMEDİ VEYA YÜKLÜ DEĞİL")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.orange)
                            }

                            Text("Aşağıdaki modellerden birini indirerek cihazında internet bağlantısız yerel yapay zekayı başlatabilirsin.")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(16)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal, 16)
                    }

                    // MODELLER LİSTESİ
                    VStack(alignment: .leading, spacing: 12) {
                        Text("KULLANILABİLİR HUGGINGFACE MODELLERİ")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .padding(.leading, 4)

                        ForEach(llmEngine.availableModels) { model in
                            ModelCardView(model: model)
                        }
                    }
                    .padding(.horizontal, 16)

                    // BİLGİ DİPNOTU
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("%100 Cihaz İçi & İnternetsiz")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(theme.textPrimary)
                        }
                        Text("Modeller bir kez indirildikten sonra telefonun uçak modunda olsa bile doğrudan Apple Silicon işlemcisinde yanıt üretir.")
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
        }
    }
}

// MARK: - Model Satır Kartı
struct ModelCardView: View {
    let model: LocalLLMModel
    @EnvironmentObject var llmEngine: LocalLLMEngine
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(theme.accentColor.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: "brain")
                    .font(.system(size: 20))
                    .foregroundColor(theme.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                Text(model.developer)
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)

                HStack(spacing: 8) {
                    Text(model.parameters)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(4)

                    Text(String(format: "%.0f MB", model.sizeMB))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.accentColor)
                }
            }

            Spacer()

            if model.isDownloaded {
                if llmEngine.activeModel?.id == model.id {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Aktif")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(12)
                } else {
                    Button(action: { llmEngine.selectModel(model) }) {
                        Text("Seç")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(theme.accentColor)
                            .cornerRadius(12)
                    }
                }
            } else {
                Button(action: {
                    llmEngine.downloader.startDownload(model: model) { success in
                        if success {
                            llmEngine.checkDownloadedModels()
                            llmEngine.selectModel(model)
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("İndir")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.accentColor)
                    .cornerRadius(12)
                }
                .disabled(llmEngine.downloader.progressInfo.isDownloading)
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(16)
    }
}
