import Foundation

/// Optional barcode lookup. Off by one switch in Settings. The barcode is the only thing sent.
/// Data: Open Food Facts contributors, Open Database License. Attribution shown in-app.
struct ProductInfo: Equatable {
    let barcode: String
    let name: String
    let brand: String
    let quantityText: String
    /// kcal for the whole package when Open Food Facts knows both energy per 100 g and the package size.
    let caloriesPerPackage: Double?
}

final class OpenFoodFactsClient {
    static let shared = OpenFoodFactsClient()

    static let attribution = "Product names from Open Food Facts contributors (ODbL)."
    static let termsURL = URL(string: "https://world.openfoodfacts.org/terms-of-use")!

    private let session: URLSession
    private let userAgent = "Lantern/0.1 (iOS; features@castlewise.app)"

    init(session: URLSession = .shared) { self.session = session }

    private struct Response: Decodable {
        struct Product: Decodable {
            let product_name: String?
            let product_name_en: String?
            let brands: String?
            let quantity: String?
            let product_quantity: Double?
            let nutriments: Nutriments?
            struct Nutriments: Decodable {
                let energyKcal100g: Double?
                enum CodingKeys: String, CodingKey { case energyKcal100g = "energy-kcal_100g" }
            }
        }
        let status: Int?
        let product: Product?
    }

    func lookup(barcode: String) async throws -> ProductInfo? {
        let clean = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.allSatisfy(\.isNumber) else { return nil }
        var comps = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(clean).json")!
        comps.queryItems = [URLQueryItem(name: "fields", value: "product_name,product_name_en,brands,quantity,product_quantity,nutriments")]
        var req = URLRequest(url: comps.url!)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 8
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.status == 1, let p = decoded.product else { return nil }
        let name = (p.product_name_en?.isEmpty == false ? p.product_name_en : p.product_name) ?? ""
        guard !name.isEmpty else { return nil }
        var kcal: Double? = nil
        if let per100 = p.nutriments?.energyKcal100g, let grams = p.product_quantity, grams > 0 {
            kcal = (per100 * grams / 100).rounded()
        }
        return ProductInfo(barcode: clean, name: name, brand: p.brands ?? "", quantityText: p.quantity ?? "", caloriesPerPackage: kcal)
    }
}
