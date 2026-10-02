import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var llmEngine: LocalLLMEngine
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Başlık
                HStack {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 22))
                        .foregroundColor(theme.accentColor)
                    Text("Yerel AI Modelleri")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Aktif Model Kartı
                        if let active = llmEngine.activeModel {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("AKTİF YEREL MOTOR")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(theme.accentColor)
                                    Spacer()
                                    Circle().fill(Color.green).frame(width: 8, height: 8)
                                    Text("Hazır")
                                        .font(.caption2)
                                        .foregroundColor(.green)
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
                                    Label("\(active.sizeMB) MB", systemImage: "internaldrive")
                                }
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary)
                                .padding(.top, 4)
                            }
                            .padding(16)
                            .background(theme.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.accentColor, lineWidth: 1.5)
                            )
                        }

                        Text("KULLANILABİLİR YEREL MODELLER")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .padding(.leading, 4)
                            .padding(.top, 8)

                        ForEach(llmEngine.availableModels) { model in
                            ModelRowView(model: model)
                        }

                        VStack(spacing: 8) {
                            Text("🔒 %100 Cihaz İçi (On-Device)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(theme.textSecondary)
                            Text("Tüm modeller internet bağlantısı olmadan doğrudan iPhone'unun işlemcisinde (NPU/CPU) çalışır. Hiçbir veri telefonundan dışarı çıkmaz.")
                                .font(.caption2)
                                .foregroundColor(theme.textSecondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 20)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct ModelRowView: View {
    let model: LocalLLMModel
    @EnvironmentObject var llmEngine: LocalLLMEngine
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text("\(model.parameters) • \(model.sizeMB) MB")
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            if model.isDownloaded {
                if llmEngine.activeModel?.id == model.id {
                    Text("Seçili")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accentColor.opacity(0.15))
                        .cornerRadius(12)
                } else {
                    Button(action: { llmEngine.activeModel = model }) {
                        Text("Seç")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(theme.cardBackground)
                            .cornerRadius(12)
                    }
                }
            } else {
                Button(action: {
                    llmEngine.downloadModel(model) { _ in }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("İndir")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.accentColor)
                    .cornerRadius(12)
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}
