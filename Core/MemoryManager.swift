import SwiftUI

class MemoryManager: ObservableObject {
    @Published var memories: [MemoryEntry] = []
    private let storageKey = "aether_memories"

    init() { load() }

    func save(category: String, key: String, value: String, importance: Double = 0.5) {
        if let index = memories.firstIndex(where: { $0.key.lowercased() == key.lowercased() && $0.category == category }) {
            memories[index].value = value
            memories[index].importance = importance
            memories[index].updatedAt = Date()
        } else {
            memories.append(MemoryEntry(category: category, key: key, value: value, importance: importance))
        }
        persist()
    }

    func find(query: String) -> [MemoryEntry] {
        let q = query.lowercased()
        return memories.filter { $0.key.lowercased().contains(q) || $0.value.lowercased().contains(q) || $0.category.lowercased().contains(q) }
    }

    func getByCategory(_ category: String) -> [MemoryEntry] {
        return memories.filter { $0.category == category }
    }

    func delete(id: UUID) { memories.removeAll { $0.id == id }; persist() }
    func deleteByKey(_ key: String) { memories.removeAll { $0.key.lowercased() == key.lowercased() }; persist() }
    func clearAll() { memories.removeAll(); persist() }

    var categorizedMemories: [(String, [MemoryEntry])] {
        let grouped = Dictionary(grouping: memories) { $0.category }
        return grouped.sorted { $0.key < $1.key }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([MemoryEntry].self, from: data) {
            memories = saved
        }
    }
}
