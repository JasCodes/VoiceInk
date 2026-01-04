
import Foundation

struct AppBuildInfo {
    static var subsystem: String {
        Bundle.main.bundleIdentifier ?? AppBuildInfo.subsystem
    }
    
    // Helper to get the organization prefix if strictly needed, 
    // but usually subsystem (bundle ID) is what's used for logging/files.
    static var organizationPrefix: String {
        let components = subsystem.split(separator: ".")
        if components.count >= 2 {
            return components.dropLast().joined(separator: ".")
        }
        return "com.organization"
    }
}
