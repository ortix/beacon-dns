import Foundation
import Combine

@MainActor
class ReflectorService: ObservableObject {
    
    enum State: Equatable {
        case idle
        case running(pid: Int32)
        case failed(String)
    }
    
    @Published private(set) var state: State = .idle
    @Published private(set) var output: String = ""
    
    private var process: Process?
    private var pipe: Pipe?
    
    // Memory safety: Limit log size
    private let maxLogCharacters = 20_000
    
    func start(interface1: String, interface2: String) {
        // Prevent starting if already running
        if case .running = state { return }
        
        output = "" // Clear previous output
        
        // 1. Locate Binary
        let binaryURL: URL
        if let moduleURL = Bundle.module.url(forResource: "mdns-reflector", withExtension: nil) {
            binaryURL = moduleURL
        } else if let mainURL = Bundle.main.resourceURL?.appendingPathComponent("mdns-reflector") {
            binaryURL = mainURL
        } else {
            state = .failed("Error: mdns-reflector binary not found in bundle")
            appendLog("Error: Could not locate mdns-reflector binary.\n")
            return
        }
        
        // 2. Setup Process
        let process = Process()
        process.executableURL = binaryURL
        process.arguments = ["-d", interface1, interface2]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // 3. Handle Termination
        process.terminationHandler = { [weak self] proc in
            Task { @MainActor [weak self] in
                self?.handleTermination(proc)
            }
        }
        
        // 4. Handle Output
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let str = String(data: data, encoding: .utf8) {
                Task { @MainActor [weak self] in
                    self?.appendLog(str)
                }
            }
        }
        
        // 5. Run
        do {
            try process.run()
            self.process = process
            self.pipe = pipe
            self.state = .running(pid: process.processIdentifier)
            appendLog("Started mdns-reflector (PID: \(process.processIdentifier)) bridging \(interface1) <-> \(interface2)\n")
        } catch {
            self.state = .failed("Failed to start: \(error.localizedDescription)")
            appendLog("Error spawning process: \(error.localizedDescription)\n")
        }
    }
    
    func stop() {
        guard let process = process, process.isRunning else { return }
        process.terminate()
        // State update handled in terminationHandler
    }
    
    private func handleTermination(_ process: Process) {
        // Clean up pipe handler
        pipe?.fileHandleForReading.readabilityHandler = nil
        self.pipe = nil
        self.process = nil
        
        let status = process.terminationStatus
        
        // If the user requested stop, we generally expect 0 (or SIGTERM 15)
        // Adjust logic based on how `mdns-reflector` behaves.
        // For now, if code is 0, we go to idle.
        
        if status == 0 || status == 15 { // 15 is often SIGTERM
            state = .idle
            appendLog("\n[Process stopped successfully]")
        } else {
            state = .failed("Process exited with code \(status)")
            appendLog("\n[Process exited unexpectedly: \(status)]")
        }
    }
    
    private func appendLog(_ text: String) {
        let newContent = output + text
        if newContent.count > maxLogCharacters {
            output = String(newContent.suffix(maxLogCharacters))
        } else {
            output = newContent
        }
    }
}
