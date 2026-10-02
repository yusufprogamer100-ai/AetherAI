import SwiftUI

@main
struct AetherApp: App {
    @StateObject private var memoryManager: MemoryManager
    @StateObject private var logManager: LogManager
    @StateObject private var themeManager: AetherThemeManager
    @StateObject private var llmEngine: LocalLLMEngine
    @StateObject private var brain: AetherBrain

    init() {
        let mm = MemoryManager()
        let lm = LogManager()
        let tm = AetherThemeManager()
        let llm = LocalLLMEngine()
        let br = AetherBrain(memoryManager: mm, logManager: lm, llmEngine: llm)

        _memoryManager = StateObject(wrappedValue: mm)
        _logManager = StateObject(wrappedValue: lm)
        _themeManager = StateObject(wrappedValue: tm)
        _llmEngine = StateObject(wrappedValue: llm)
        _brain = StateObject(wrappedValue: br)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(brain)
                .environmentObject(memoryManager)
                .environmentObject(logManager)
                .environmentObject(themeManager)
                .environmentObject(llmEngine)
                .preferredColorScheme(.dark)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var theme: AetherThemeManager

    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Sohbet")
                }

            ModelsView()
                .tabItem {
                    Image(systemName: "cpu.fill")
                    Text("Modeller")
                }

            MemoryView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Hafıza")
                }

            LogView()
                .tabItem {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("Loglar")
                }

            AetherSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Ayarlar")
                }
        }
        .accentColor(theme.accentColor)
    }
}
