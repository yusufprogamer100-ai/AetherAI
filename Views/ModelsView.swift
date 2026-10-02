import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var llmEngine: LocalLLMEngine
    @EnvironmentObject var theme: AetherThemeManager
    @State private var showLogsTerminal: Bool = false

    var body: some View {
        NavigationView {
            List {
                // MARK: - CANLI İNDİRME BÖLÜMÜ
                if llmEngine.downloader.progressInfo.isDownloading {
                    let info = llmEngine.downloader.progressInfo
                    Section(header: Text("MODEL İNDİRİLİYOR")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Model İndiriliyor...")
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.1f MB/s", info.speedMBps))
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.accentColor)
                            }

                            // Yüzde Çubuğu
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(uiColor: .systemGray5))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.accentColor)
                                        .frame(width: geo.size.width * CGFloat(info.percentage / 100.0), height: 8)
                                }
                            }
                            .frame(height: 8)

                            HStack {
                                Text(String(format: "%.1f MB / %.1f MB", info.downloadedMB, info.totalMB))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%%%.1f", info.percentage))
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                            }

                            HStack {
                                Button(action: { showLogsTerminal.toggle() }) {
                                    Label(showLogsTerminal ? "İndirme Loglarını Gizle" : "İndirme Loglarını Gör", systemImage: "terminal")
                                        .font(.caption)
                                }

                                Spacer()

                                Button(action: { llmEngine.downloader.cancelDownload() }) {
                                    Text("İptal Et")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            if showLogsTerminal {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(info.logs, id: \.self) { log in
                                            Text(log)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .padding(8)
                                }
                                .frame(height: 120)
                                .background(Color(uiColor: .tertiarySystemGroupedBackground))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - AKTİF SEÇİLİ MODEL
                Section(header: Text("AKTİF YEREL MODEL")) {
                    if let active = llmEngine.activeModel, active.isDownloaded {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(active.name)
                                        .font(.headline)
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                }
                                Text(active.developer)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("\(active.parameters) • \(String(format: "%.0f MB", active.sizeMB))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("Çevrimdışı")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Henüz model seçilmedi veya indirilmedi.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // MARK: - KULLANILABİLİR HUGGINGFACE MODELLERİ
                Section(header: Text("KULLANILABİLİR HUGGINGFACE MODELLERİ"), footer: Text("İndirdiğiniz tüm modeller iPhone'unuzda saklanır. İstediğiniz an aralarında geçiş yapabilirsiniz.")) {
                    ForEach(llmEngine.availableModels) { model in
                        NativeModelRow(model: model)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Modeller")
        }
        .navigationViewStyle(.stack)
    }
}

struct NativeModelRow: View {
    let model: LocalLLMModel
    @EnvironmentObject var llmEngine: LocalLLMEngine

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text("\(model.developer) • \(String(format: "%.0f MB", model.sizeMB))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if model.isDownloaded {
                if llmEngine.activeModel?.id == model.id {
                    Text("Seçili")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        withAnimation(.spring()) {
                            llmEngine.selectModel(model)
                        }
                    }) {
                        Text("Seç")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.accentColor)
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
                        Image(systemName: "arrow.down.circle")
                        Text("İndir")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                }
                .disabled(llmEngine.downloader.progressInfo.isDownloading)
            }
        }
        .padding(.vertical, 4)
    }
}
