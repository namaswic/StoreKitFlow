import Combine
import StoreKit

public final class ProductService: ProductFetchable {
    public init() {}

    public func fetchProducts(ids: [String]) async throws -> [StoreProduct] {
        let products = try await Product.products(for: ids)
        return products.map(StoreProduct.init)
    }

    public func fetchProductsPublisher(ids: [String]) -> AnyPublisher<[StoreProduct], Error> {
        Future { promise in
            Task {
                do {
                    let products = try await Product.products(for: ids)
                    promise(.success(products.map(StoreProduct.init)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

private extension StoreProduct {
    init(_ product: Product) {
        let subscription = product.subscription
        self.init(
            id: product.id,
            displayName: product.displayName,
            description: product.description,
            displayPrice: product.displayPrice,
            price: product.price,
            type: ProductType(product.type),
            familyShareable: product.isFamilyShareable,
            introductoryOffer: subscription?.introductoryOffer.map(IntroductoryOffer.init),
            promotionalOffers: subscription?.promotionalOffers.map(PromotionalOffer.init) ?? [],
            winBackOffers: {
                if #available(iOS 18.0, macOS 15.0, *) {
                    return subscription?.winBackOffers.map(WinBackOffer.init) ?? []
                }
                return []
            }()
        )
    }
}

private extension IntroductoryOffer {
    init(_ offer: Product.SubscriptionOffer) {
        self.init(
            paymentMode: PaymentMode(offer.paymentMode),
            displayPrice: offer.displayPrice,
            period: offer.period.debugDescription
        )
    }
}

private extension PromotionalOffer {
    init(_ offer: Product.SubscriptionOffer) {
        self.init(
            id: offer.id ?? "",
            displayName: offer.id ?? "",
            paymentMode: PaymentMode(offer.paymentMode),
            displayPrice: offer.displayPrice,
            period: offer.period.debugDescription
        )
    }
}

private extension WinBackOffer {
    init(_ offer: Product.SubscriptionOffer) {
        self.init(
            id: offer.id ?? "",
            paymentMode: PaymentMode(offer.paymentMode),
            displayPrice: offer.displayPrice,
            period: offer.period.debugDescription
        )
    }
}

private extension PaymentMode {
    init(_ mode: Product.SubscriptionOffer.PaymentMode) {
        switch mode {
        case .freeTrial:    self = .free
        case .payAsYouGo:   self = .payAsYouGo
        case .payUpFront:   self = .payUpFront
        default:            self = .free
        }
    }
}

private extension ProductType {
    init(_ type: Product.ProductType) {
        switch type {
        case .consumable:       self = .consumable
        case .nonConsumable:    self = .nonConsumable
        case .autoRenewable:    self = .autoRenewable
        default:                self = .nonRenewing
        }
    }
}
