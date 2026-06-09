import Testing
import StoreKit
@testable import StoreKitFlow

@Suite("PurchaseAttributes")
struct PurchaseAttributesTests {

    @Test("default attributes produce empty option set")
    func defaultAttributesEmpty() {
        let options = PurchaseAttributes().toPurchaseOptions()
        #expect(options.isEmpty)
    }

    @Test("appAccountToken is included in options")
    func appAccountTokenIncluded() {
        let token = UUID()
        let options = PurchaseAttributes(appAccountToken: token).toPurchaseOptions()
        #expect(!options.isEmpty)
    }

    @Test("quantity is included in options")
    func quantityIncluded() {
        let options = PurchaseAttributes(quantity: 3).toPurchaseOptions()
        #expect(!options.isEmpty)
    }

    @Test("simulatesAskToBuy is included in options")
    func simulatesAskToBuyIncluded() {
        let options = PurchaseAttributes(simulatesAskToBuy: true).toPurchaseOptions()
        #expect(!options.isEmpty)
    }

    @Test("custom string values add one option per pair")
    func customStringValuesAdded() {
        let attrs = PurchaseAttributes(customStringValues: ["campaign": "summer24", "source": "push"])
        let options = attrs.toPurchaseOptions()
        #expect(options.count == 2)
    }

    @Test("custom double values add one option per pair")
    func customDoubleValuesAdded() {
        let attrs = PurchaseAttributes(customDoubleValues: ["score": 99.5])
        let options = attrs.toPurchaseOptions()
        #expect(options.count == 1)
    }

    @Test("custom bool values add one option per pair")
    func customBoolValuesAdded() {
        let attrs = PurchaseAttributes(customBoolValues: ["isPro": true])
        let options = attrs.toPurchaseOptions()
        #expect(options.count == 1)
    }

    @Test("onStorefrontChange true adds option")
    func onStorefrontChangeAdded() {
        let options = PurchaseAttributes(onStorefrontChange: true).toPurchaseOptions()
        #expect(!options.isEmpty)
    }

    @Test("combined attributes produce correct count")
    func combinedAttributesCount() {
        let attrs = PurchaseAttributes(
            appAccountToken: UUID(),
            quantity: 2,
            customStringValues: ["key": "value"]
        )
        let options = attrs.toPurchaseOptions()
        #expect(options.count == 3)
    }

    @Test("winBackOfferID alone produces empty options — resolved in PurchaseService")
    func winBackOfferIDNotInOptions() {
        let options = PurchaseAttributes(winBackOfferID: "win_back_offer").toPurchaseOptions()
        #expect(options.isEmpty)
    }

    @Test("introductoryOfferJWS alone produces empty options — resolved in PurchaseService")
    func introductoryOfferJWSNotInOptions() {
        let options = PurchaseAttributes(introductoryOfferJWS: "jws_token").toPurchaseOptions()
        #expect(options.isEmpty)
    }
}
