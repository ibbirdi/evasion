import Foundation
import StoreKit

#if os(iOS)
import UIKit
#endif

enum AppReviewRequester {
    @MainActor
    static func requestReviewIfPossible() -> Bool {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return false }

        AppStore.requestReview(in: scene)
        return true
        #else
        return false
        #endif
    }
}
