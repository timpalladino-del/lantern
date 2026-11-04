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
    /// Servings in the package when the label's serving size and the package size are both known.
    let servingsPerPackage: Double?
    /// The label panel, per serving, when Open Food Facts has it.
    let nutrition: NutritionFacts?
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
            let product_quantity: LenientNumber?
            let serving_quantity: LenientNumber?
            let serving_size: String?
            let nutriments: Nutriments?
            struct Nutriments: Decodable {
                let energyKcal100g: LenientNumber?
                let energyKcalServing: LenientNumber?
                let proteins100g: LenientNumber?
                let proteinsServing: LenientNumber?
                let carbohydrates100g: LenientNumber?
                let carbohydratesServing: LenientNumber?
                let fat100g: LenientNumber?
                let fatServing: LenientNumber?
                let fiber100g: LenientNumber?
                let fiberServing: LenientNumber?
                let sugars100g: LenientNumber?
                let sugarsServing: LenientNumber?
                let sodium100g: LenientNumber?
                let sodiumServing: LenientNumber?
                enum CodingKeys: String, CodingKey {
                    case energyKcal100g = "energy-kcal_100g", energyKcalServing = "energy-kcal_serving"
                    case proteins100g = "proteins_100g", proteinsServing = "proteins_serving"
                    case carbohydrates100g = "carbohydrates_100g", carbohydratesServing = "carbohydrates_serving"
                    case fat100g = "fat_100g", fatServing = "fat_serving"
                    case fiber100g = "fiber_100g", fiberServing = "fiber_serving"
                    case sugars100g = "sugars_100g", sugarsServing = "sugars_serving"
                    case sodium100g = "sodium_100g", sodiumServing = "sodium_serving"
                }
            }
        }
        /// Open Food Facts sends numbers as numbers or as strings depending on who entered them.
        struct LenientNumber: Decodable {
            let value: Double?
            init(from decoder: Decoder) throws {
                let c = try decoder.singleValueContainer()
                if let d = try? c.decode(Double.self) { value = d }
                else if let s = try? c.decode(String.self) { value = Double(s.trimmingCharacters(in: .whitespaces)) }
                else { value = nil }
            }
        }
        let status: Int?
        let product: Product?
    }

    func lookup(barcode: String) async throws -> ProductInfo? {
        let clean = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.allSatisfy(\.isNumber) else { return nil }
        var comps = URLComponents(string: "https://world.openfoodfacts.org/api/v2/product/\(clean).json")!
        comps.queryItems = [URLQueryItem(name: "fields", value: "product_name,product_name_en,brands,quantity,product_quantity,serving_quantity,serving_size,nutriments")]
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
        if let per100 = p.nutriments?.energyKcal100g?.value, let grams = p.product_quantity?.value, grams > 0 {
            kcal = (per100 * grams / 100).rounded()
        }
        var servings: Double? = nil
        if let grams = p.product_quantity?.value, let serving = p.serving_quantity?.value, serving > 0, grams > 0 {
            servings = (grams / serving * 10).rounded() / 10
        }
        let nutrition = Self.nutrition(from: p.nutriments, servingGrams: p.serving_quantity?.value, servingSize: p.serving_size ?? "")
        return ProductInfo(barcode: clean, name: name, brand: p.brands ?? "", quantityText: p.quantity ?? "", caloriesPerPackage: kcal, servingsPerPackage: servings, nutrition: nutrition)
    }

    /// Per-serving figures straight from the record, or scaled from per-100 g when the serving size is known.
    private static func nutrition(from n: Response.Product.Nutriments?, servingGrams: Double?, servingSize: String) -> NutritionFacts? {
        guard let n else { return nil }
        func per(_ serving: Response.LenientNumber?, _ per100: Response.LenientNumber?) -> Double? {
            if let v = serving?.value { return v }
            if let v = per100?.value, let g = servingGrams, g > 0 { return (v * g / 100 * 10).rounded() / 10 }
            return nil
        }
        var facts = NutritionFacts(servingSize: servingSize, source: "Open Food Facts")
        facts.calories = per(n.energyKcalServing, n.energyKcal100g).map { $0.rounded() }
        facts.proteinG = per(n.proteinsServing, n.proteins100g)
        facts.carbsG = per(n.carbohydratesServing, n.carbohydrates100g)
        facts.fatG = per(n.fatServing, n.fat100g)
        facts.fiberG = per(n.fiberServing, n.fiber100g)
        facts.sugarG = per(n.sugarsServing, n.sugars100g)
        facts.sodiumMg = per(n.sodiumServing, n.sodium100g).map { ($0 * 1000).rounded() }   // OFF stores sodium in grams
        return facts.isEmpty ? nil : facts
    }
}
