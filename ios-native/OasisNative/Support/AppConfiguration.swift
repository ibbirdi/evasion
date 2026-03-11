import Foundation

enum AppConfiguration {
    static let persistenceKey = "evasion-mixer-storage"
    static let simulatesPremium = true
    static let premiumProductID = (Bundle.main.object(forInfoDictionaryKey: "PremiumProductID") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    static let supportURL = URL(string: "https://bow-elephant-191.notion.site/ASSISTANCE-31084ba33afa801d872fc2aecc576f56?source=copy_link")!
}
