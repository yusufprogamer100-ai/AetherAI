import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var memoryManager: MemoryManager
    @EnvironmentObject var theme: AetherThemeManager
    @State private var searchText: String = ""

    var filteredMemories: [(String, [MemoryEntry])] {
        if searchText.isEmpty { return memoryManager.categorizedMemories }
        let q = searchText.lowercased()
        let filtered = memoryManager.memories.filter { $0.key.lowercased().contains(q) || $0.value.lowercased().contains(q) }
        return Dictionary(grouping: filtered) { $0.category }.sorted { $0.key < $1.key }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundGradient, startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                // Başlık
                HStack {
                    Image(systemName: "brain.head.profile").font(.system(size: 22)).foregroundColor(theme.accentColor)
                    Text("Hafıza").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                    Spacer()
                    Text("\(memoryManager.memories.count) kayıt").font(.caption).foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                // Arama
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(theme.textSecondary)
                    TextField("Hafızada ara...", text: $searchText).foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(theme.inputBackground).cornerRadius(12)
                .padding(.horizontal, 16).padding(.bottom, 8)

                if memoryManager.memories.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "brain").font(.system(size: 48)).foregroundColor(theme.textSecondary)
                        Text("Hafıza Boş").font(.headline).foregroundColor(theme.textPrimary)
                        Text("Sohbette bilgi verdiğinde\nburada görünecek").font(.subheadline).foregroundColor(theme.textSecondary).multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredMemories, id: \.0) { category, entries in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        let cat = MemoryCategory.allCases.first { $0.rawValue == category }
                                        Image(systemName: cat?.icon ?? "folder.fill").foregroundColor(cat?.color ?? .gray)
                                        Text(category).font(.system(size: 14, weight: .semibold)).foregroundColor(theme.textSecondary)
                                    }.padding(.horizontal, 4)
                                    ForEach(entries) { entry in MemoryCardView(entry: entry) }
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

struct MemoryCardView: View {
    let entry: MemoryEntry
    @EnvironmentObject var theme: AetherThemeManager
    @EnvironmentObject var memoryManager: MemoryManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.key).font(.system(size: 14, weight: .semibold)).foregroundColor(theme.textPrimary)
                Text(entry.value).font(.system(size: 13)).foregroundColor(theme.textSecondary).lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle().fill(Double(i) / 5.0 < entry.importance ? theme.accentColor : Color.white.opacity(0.1)).frame(width: 6, height: 6)
                    }
                }
                Text(dateString(entry.updatedAt)).font(.system(size: 10)).foregroundColor(theme.textSecondary)
            }
            Button(action: { memoryManager.delete(id: entry.id) }) {
                Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.red.opacity(0.6))
            }.padding(.leading, 8)
        }
        .padding(12).background(theme.cardBackground).cornerRadius(12)
    }

    private func dateString(_ date: Date) -> String {
        let df = DateFormatter(); df.dateFormat = "dd.MM"; return df.string(from: date)
    }
}
