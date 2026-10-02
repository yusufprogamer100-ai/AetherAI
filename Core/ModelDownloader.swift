import Foundation

class ModelDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progressInfo = DownloadProgressInfo()

    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var lastBytes: Int64 = 0
    private var lastTime: Date = Date()
    private var currentModel: LocalLLMModel?
    private var onComplete: ((Bool) -> Void)?

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 3600.0
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }

    static var modelsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelsDir = docs.appendingPathComponent("models", isDirectory: true)
        if !FileManager.default.fileExists(atPath: modelsDir.path) {
            try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
        return modelsDir
    }

    func startDownload(model: LocalLLMModel, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: model.downloadURL) else {
            addLog("❌ Hata: İndirme URL'i geçersiz.")
            completion(false)
            return
        }

        self.currentModel = model
        self.onComplete = completion
        self.lastBytes = 0
        self.lastTime = Date()

        progressInfo = DownloadProgressInfo(
            isDownloading: true,
            modelId: model.id,
            downloadedBytes: 0,
            totalBytes: Int64(model.sizeMB * 1024 * 1024),
            speedMBps: 0.0,
            percentage: 0.0,
            logs: [],
            errorMessage: nil
        )

        addLog("🌐 HuggingFace sunucusuna bağlanılıyor...")
        addLog("📦 Model: \(model.name) (\(model.parameters))")

        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        progressInfo.isDownloading = false
        addLog("🛑 İndirme iptal edildi.")
        onComplete?(false)
    }

    private func addLog(_ text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let formatted = "[\(timestamp)] \(text)"
        DispatchQueue.main.async {
            self.progressInfo.logs.append(formatted)
            if self.progressInfo.logs.count > 80 {
                self.progressInfo.logs.removeFirst()
            }
        }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let now = Date()
        let timeDiff = now.timeIntervalSince(lastTime)

        var currentSpeed = progressInfo.speedMBps
        if timeDiff >= 0.4 {
            let bytesDiff = totalBytesWritten - lastBytes
            currentSpeed = (Double(bytesDiff) / (1024.0 * 1024.0)) / timeDiff
            lastBytes = totalBytesWritten
            lastTime = now
        }

        let total = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : Int64((currentModel?.sizeMB ?? 300) * 1024 * 1024)
        let percent = (Double(totalBytesWritten) / Double(total)) * 100.0

        DispatchQueue.main.async {
            self.progressInfo.downloadedBytes = totalBytesWritten
            self.progressInfo.totalBytes = total
            self.progressInfo.speedMBps = currentSpeed
            self.progressInfo.percentage = min(max(percent, 0.0), 100.0)
        }

        if totalBytesWritten % (1024 * 1024 * 5) == 0 {
            let writtenMB = String(format: "%.1f", Double(totalBytesWritten) / (1024.0 * 1024.0))
            let totalMB = String(format: "%.1f", Double(total) / (1024.0 * 1024.0))
            let speedStr = String(format: "%.2f", currentSpeed)
            addLog("⚡ İndiriliyor: \(writtenMB) MB / \(totalMB) MB (%\(Int(percent))) @ \(speedStr) MB/s")
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        addLog("✅ Model indirildi. Yerel depolama alanına kuruluyor...")

        guard let model = currentModel else {
            finish(success: false)
            return
        }

        let destination = ModelDownloader.modelsDirectory.appendingPathComponent(model.filename)

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            addLog("🎉 Model başarıyla yüklendi: \(model.name)")
            finish(success: true)
        } catch {
            addLog("❌ Dosya kaydetme hatası: \(error.localizedDescription)")
            finish(success: false)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            addLog("❌ İndirme Hatası: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.progressInfo.errorMessage = error.localizedDescription
            }
            finish(success: false)
        }
    }

    private func finish(success: Bool) {
        DispatchQueue.main.async {
            self.progressInfo.isDownloading = false
            self.onComplete?(success)
        }
    }
}
