import Foundation
import Network

struct NetworkInterface: Identifiable, Hashable {
    let id: String
    let name: String
    let displayName: String
    let ipAddress: String
    let subnet: String
    let isUp: Bool
    
    var description: String {
        "\(displayName) (\(name)) - \(ipAddress)/\(subnet)"
    }
}

class NetworkInterfaceManager: ObservableObject {
    @Published var interfaces: [NetworkInterface] = []
    
    init() {
        refreshInterfaces()
    }
    
    func refreshInterfaces() {
        interfaces = getNetworkInterfaces()
    }
    
    private func getNetworkInterfaces() -> [NetworkInterface] {
        var result: [NetworkInterface] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return result
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            
            if !isLoopback, let addr = interface.ifa_addr {
                let family = addr.pointee.sa_family
                
                if family == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, 0, NI_NUMERICHOST)
                    let ipAddress = String(cString: hostname)
                    
                    var subnetMask = ""
                    if let netmask = interface.ifa_netmask {
                        var maskHostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(netmask, socklen_t(netmask.pointee.sa_len),
                                   &maskHostname, socklen_t(maskHostname.count),
                                   nil, 0, NI_NUMERICHOST)
                        subnetMask = String(cString: maskHostname)
                    }
                    
                    let cidr = subnetMaskToCIDR(subnetMask)
                    let displayName = friendlyName(for: name)
                    
                    let netInterface = NetworkInterface(
                        id: "\(name)-\(ipAddress)",
                        name: name,
                        displayName: displayName,
                        ipAddress: ipAddress,
                        subnet: cidr,
                        isUp: isUp
                    )
                    result.append(netInterface)
                }
            }
            
            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    private func subnetMaskToCIDR(_ mask: String) -> String {
        let parts = mask.split(separator: ".").compactMap { UInt8($0) }
        guard parts.count == 4 else { return mask }
        
        var cidr = 0
        for part in parts {
            var byte = part
            while byte != 0 {
                cidr += Int(byte & 1)
                byte >>= 1
            }
        }
        return "\(cidr)"
    }
    
    private func friendlyName(for interface: String) -> String {
        if interface.hasPrefix("en") {
            if interface == "en0" { return "Wi-Fi / Ethernet" }
            return "Ethernet \(interface)"
        }
        if interface.hasPrefix("bridge") { return "Bridge \(interface)" }
        if interface.hasPrefix("utun") { return "VPN Tunnel" }
        if interface.hasPrefix("awdl") { return "AirDrop" }
        if interface.hasPrefix("llw") { return "Low Latency WLAN" }
        if interface.hasPrefix("vmnet") { return "VM Network" }
        if interface.hasPrefix("veth") { return "Virtual Ethernet" }
        return interface
    }
}
