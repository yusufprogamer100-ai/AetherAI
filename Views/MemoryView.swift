import SwiftUI

struct MemoryView: View {
    @EnvironmentObject var memoryManager: MemoryManager
    @State private var searchText: String = ""

    var filteredMemories: [(String, [MemoryEntry])] {
        if searchText.isEmpty { return memoryManager.categorizedMemories }
        let q = searchText.lowercased()
        let filtered = memoryManager.memories.filter { $0.key.lowercased().contains(q) || $0.value.lowercased().contains(q) }
        return Dictionary(grouping: filtered) { $0.category }.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationView {
            List {
                if memoryManager.memories.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Hafıza Boş")
                            .font(.headline)
                        Text("Sohbet ederken Aether'e verdiğin bilgiler (isimler, notlar, tercihler) otomatik olarak burada saklanır.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredMemories, id: \.0) { category, entries in
                        Section(header: Text(category)) {
                            ForEach(entries) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.key)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(entry.value)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        withAnimation {
                                            memoryManager.delete(id: entry.id)
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.subheadline)
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Hafızada ara...")
            .listStyle(.insetGrouped)
            .navigationTitle("Kalıcı Hafıza")
        }
        .navigationViewStyle(.stack)
    }
}
