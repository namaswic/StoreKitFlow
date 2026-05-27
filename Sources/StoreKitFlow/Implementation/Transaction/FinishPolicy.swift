import StoreKit

/// Returns the human-readable reason why a verified transaction should be finished.
///
/// All verified transactions must be finished — this function explains why based on
/// product type and transaction state, making the decision auditable in the Logs explorer.
///
/// | Transaction type          | Finish? | Reason |
/// |---------------------------|---------|--------|
/// | Active renewal            | ✅ Yes  | Confirm delivery and clear queue |
/// | Expired renewal           | ✅ Yes  | Prevents silent .success on re-subscribe |
/// | Revoked subscription      | ✅ Yes  | Clear from queue, stop re-delivery |
/// | Non-consumable            | ✅ Yes  | Finish once — entitlement is permanent |
/// | Consumable                | ✅ Yes  | Finish after granting consumable content |
/// | Non-renewing subscription | ✅ Yes  | Finish after granting access for the period |
/// | Unverified                | ❌ No   | Cryptographic check failed — never grant access |
/// | Pending (Ask to Buy)      | ❌ No   | Awaiting parental approval — finishing discards it |
/// | Pending (billing issue)   | ❌ No   | Payment not resolved — do not finish |
///
/// The ❌ cases never reach this function — they are rejected upstream before `finishReason`
/// is called. See `skipFinishReason(for:)` for their explanations.
///
/// See https://stackoverflow.com/q/77355821 for why finishing expired renewals is critical.
public func finishReason(for transaction: Transaction) -> String {
    switch transaction.productType {
    case .autoRenewable:
        if transaction.revocationDate != nil {
            return "Revoked subscription — finish to clear from queue and stop re-delivery"
        }
        if let expiry = transaction.expirationDate, expiry < Date() {
            return "Expired renewal — finishing prevents silent .success on re-subscribe"
        }
        return "Active renewal — finish to confirm delivery and clear queue"
    case .nonConsumable:
        return "Non-consumable — finish once, entitlement is permanent"
    case .consumable:
        return "Consumable — finish after granting the consumable content"
    case .nonRenewable:
        return "Non-renewing subscription — finish after granting access for the purchased period"
    default:
        return "Unknown product type — finish to avoid queue buildup"
    }
}

/// Returns the human-readable reason why a transaction should NOT be finished.
///
/// These cases are rejected upstream and never reach `finishReason(for:)`.
/// This function is used for logging so the reason is still visible in the Logs explorer.
///
/// | Scenario                  | Reason |
/// |---------------------------|--------|
/// | Unverified transaction    | Cryptographic check failed — do not grant access or finish |
/// | Pending — Ask to Buy      | Awaiting parental approval — finishing permanently discards it |
/// | Pending — billing issue   | Payment not resolved — wait for Transaction.updates to deliver the outcome |
/// | Pending — Family Sharing  | Awaiting organizer approval — do not finish until resolved |
public func skipFinishReason(for scenario: SkipFinishScenario) -> String {
    switch scenario {
    case .unverified:
        return "Unverified — StoreKit cryptographic check failed. Do not grant access or finish."
    case .pendingAskToBuy:
        return "Pending (Ask to Buy) — awaiting parental approval. Finishing would permanently discard the transaction."
    case .pendingBillingIssue:
        return "Pending (billing issue) — payment not resolved. Wait for Transaction.updates to deliver the final outcome."
    case .pendingFamilySharing:
        return "Pending (Family Sharing) — awaiting organizer approval. Do not finish until approved or declined."
    }
}

/// The scenario in which a transaction is not finished.
public enum SkipFinishScenario: Sendable {
    case unverified
    case pendingAskToBuy
    case pendingBillingIssue
    case pendingFamilySharing
}
