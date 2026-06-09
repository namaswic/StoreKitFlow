import Testing
@testable import StoreKitFlow

@Suite("FinishPolicy - skipFinishReason")
struct FinishPolicyTests {

    @Test("skipFinishReason for unverified mentions Unverified")
    func skipFinishReasonUnverified() {
        let reason = skipFinishReason(for: .unverified)
        #expect(reason.localizedCaseInsensitiveContains("Unverified"))
        #expect(!reason.isEmpty)
    }

    @Test("skipFinishReason for pendingAskToBuy mentions Ask to Buy")
    func skipFinishReasonAskToBuy() {
        let reason = skipFinishReason(for: .pendingAskToBuy)
        #expect(reason.localizedCaseInsensitiveContains("Ask to Buy"))
        #expect(!reason.isEmpty)
    }

    @Test("skipFinishReason for pendingBillingIssue mentions billing")
    func skipFinishReasonBillingIssue() {
        let reason = skipFinishReason(for: .pendingBillingIssue)
        #expect(reason.localizedCaseInsensitiveContains("billing"))
        #expect(!reason.isEmpty)
    }

    @Test("skipFinishReason for pendingFamilySharing mentions Family Sharing")
    func skipFinishReasonFamilySharing() {
        let reason = skipFinishReason(for: .pendingFamilySharing)
        #expect(reason.localizedCaseInsensitiveContains("Family Sharing"))
        #expect(!reason.isEmpty)
    }

    @Test("skipFinishReason returns non-empty string for all cases")
    func skipFinishReasonAllCasesNonEmpty() {
        for scenario in [SkipFinishScenario.unverified, .pendingAskToBuy, .pendingBillingIssue, .pendingFamilySharing] {
            #expect(!skipFinishReason(for: scenario).isEmpty, "Expected non-empty reason for \(scenario)")
        }
    }
}
