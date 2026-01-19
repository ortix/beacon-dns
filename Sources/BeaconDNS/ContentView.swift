import SwiftUI

struct ContentView: View {
    @StateObject private var interfaceManager = NetworkInterfaceManager()
    @StateObject private var reflectorService = ReflectorService()
    
    @State private var selectedInterface1: NetworkInterface?
    @State private var selectedInterface2: NetworkInterface?
    
    var body: some View {
        VStack(spacing: 16) {
            headerSection
            interfaceSelectionSection
            controlSection
            outputSection
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var headerSection: some View {
        HStack {
            Text("Beacon DNS")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            Button(action: { interfaceManager.refreshInterfaces() }) {
                Image(systemName: "arrow.clockwise")
            }
            .help("Refresh interfaces")
        }
    }
    
    private var interfaceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select two interfaces to bridge:")
                .font(.headline)
            
            HStack(spacing: 20) {
                interfacePicker(title: "Interface 1", selection: $selectedInterface1)
                interfacePicker(title: "Interface 2", selection: $selectedInterface2)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func interfacePicker(title: String, selection: Binding<NetworkInterface?>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("", selection: selection) {
                Text("Select...").tag(nil as NetworkInterface?)
                ForEach(interfaceManager.interfaces) { iface in
                    VStack(alignment: .leading) {
                        Text("\(iface.displayName) (\(iface.name))")
                        Text("\(iface.ipAddress)/\(iface.subnet)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(iface as NetworkInterface?)
                }
            }
            .pickerStyle(.menu)
            .frame(minWidth: 200)
        }
    }
    
    private var controlSection: some View {
        HStack {
            switch reflectorService.state {
            case .running(let pid):
                Button("Stop Reflector") {
                    reflectorService.stop()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Running (PID: \(pid))")
                        .foregroundColor(.secondary)
                }
            case .idle, .failed:
                Button("Start Reflector") {
                    guard let iface1 = selectedInterface1,
                          let iface2 = selectedInterface2 else { return }
                    reflectorService.start(interface1: iface1.name, interface2: iface2.name)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedInterface1 == nil || selectedInterface2 == nil || 
                         selectedInterface1 == selectedInterface2)
                
                if case .failed(let error) = reflectorService.state {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            if selectedInterface1 != nil && selectedInterface2 != nil && 
               selectedInterface1 == selectedInterface2 {
                Text("Please select different interfaces")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var outputSection: some View {
        VStack(alignment: .leading) {
            Text("Output")
                .font(.headline)
            
            ScrollView {
                Text(reflectorService.output.isEmpty ? "No output yet..." : reflectorService.output)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 150)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(4)
        }
    }
}
