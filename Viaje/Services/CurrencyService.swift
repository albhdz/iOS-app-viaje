import Foundation
import Observation

/// Tipos de cambio con respecto al USD. Usa tasas de respaldo integradas y
/// puede actualizarse en línea (open.er-api.com, gratuito y sin API key).
@Observable
final class CurrencyService {
    static let shared = CurrencyService()

    /// Unidades de la moneda por 1 USD.
    private(set) var tasas: [String: Double]
    private(set) var ultimaActualizacion: Date?
    private(set) var actualizando = false
    var error: String?

    static let respaldo: [String: Double] = [
        "USD": 1, "MXN": 18.5, "EUR": 0.92, "GBP": 0.78, "CAD": 1.38, "JPY": 150,
        "COP": 4000, "ARS": 1400, "BRL": 5.5, "CLP": 940, "PEN": 3.7, "CRC": 505,
        "GTQ": 7.7, "DOP": 62, "CHF": 0.86, "CZK": 23, "HUF": 360, "PLN": 3.9,
        "TRY": 41, "AED": 3.67, "MAD": 9.8, "EGP": 49, "ZAR": 18, "KRW": 1380,
        "THB": 34, "IDR": 16000, "VND": 25500, "SGD": 1.32, "INR": 85, "AUD": 1.52,
        "NZD": 1.68, "ISK": 135, "CNY": 7.2, "UYU": 40, "BOB": 6.9,
    ]

    static let nombres: [String: String] = [
        "USD": "Dólar estadounidense", "MXN": "Peso mexicano", "EUR": "Euro", "GBP": "Libra esterlina",
        "CAD": "Dólar canadiense", "JPY": "Yen japonés", "COP": "Peso colombiano", "ARS": "Peso argentino",
        "BRL": "Real brasileño", "CLP": "Peso chileno", "PEN": "Sol peruano", "CRC": "Colón costarricense",
        "GTQ": "Quetzal", "DOP": "Peso dominicano", "CHF": "Franco suizo", "CZK": "Corona checa",
        "HUF": "Florín húngaro", "PLN": "Esloti polaco", "TRY": "Lira turca", "AED": "Dírham EAU",
        "MAD": "Dírham marroquí", "EGP": "Libra egipcia", "ZAR": "Rand", "KRW": "Won surcoreano",
        "THB": "Baht", "IDR": "Rupia indonesia", "VND": "Dong", "SGD": "Dólar de Singapur",
        "INR": "Rupia india", "AUD": "Dólar australiano", "NZD": "Dólar neozelandés",
        "ISK": "Corona islandesa", "CNY": "Yuan", "UYU": "Peso uruguayo", "BOB": "Boliviano",
    ]

    static var monedas: [String] { respaldo.keys.sorted() }

    private let claveCache = "tasasCambio"
    private let claveFecha = "tasasCambioFecha"

    init() {
        tasas = Self.respaldo
        if let data = UserDefaults.standard.data(forKey: claveCache),
           let guardadas = try? JSONDecoder().decode([String: Double].self, from: data) {
            tasas.merge(guardadas) { _, nueva in nueva }
            ultimaActualizacion = UserDefaults.standard.object(forKey: claveFecha) as? Date
        }
    }

    /// Convierte un monto entre dos monedas.
    func convertir(_ monto: Double, de origen: String, a destino: String) -> Double {
        guard origen != destino else { return monto }
        let tOrigen = tasas[origen] ?? 1
        let tDestino = tasas[destino] ?? 1
        return monto / tOrigen * tDestino
    }

    func tasa(de origen: String, a destino: String) -> Double {
        convertir(1, de: origen, a: destino)
    }

    func desdeUSD(_ monto: Double, a destino: String) -> Double {
        convertir(monto, de: "USD", a: destino)
    }

    private struct Respuesta: Decodable {
        let result: String
        let rates: [String: Double]
    }

    @MainActor
    func actualizar() async {
        guard !actualizando else { return }
        actualizando = true
        defer { actualizando = false }
        do {
            let url = URL(string: "https://open.er-api.com/v6/latest/USD")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let r = try JSONDecoder().decode(Respuesta.self, from: data)
            guard r.result == "success" else { throw URLError(.badServerResponse) }
            tasas.merge(r.rates) { _, nueva in nueva }
            ultimaActualizacion = Date()
            error = nil
            if let encoded = try? JSONEncoder().encode(tasas) {
                UserDefaults.standard.set(encoded, forKey: claveCache)
                UserDefaults.standard.set(ultimaActualizacion, forKey: claveFecha)
            }
        } catch {
            self.error = "No se pudieron actualizar las tasas. Se usan las guardadas."
        }
    }

    /// Actualiza si las tasas tienen más de 12 horas.
    @MainActor
    func actualizarSiEsNecesario() async {
        if let f = ultimaActualizacion, Date().timeIntervalSince(f) < 12 * 3600 { return }
        await actualizar()
    }
}

// MARK: - Formato de dinero

enum Dinero {
    static func formato(_ monto: Double, _ moneda: String, decimales: Bool = false) -> String {
        monto.formatted(
            .currency(code: moneda)
            .precision(.fractionLength(decimales ? 2 : 0))
            .locale(Locale(identifier: "es_MX"))
        )
    }
}

extension Double {
    func dinero(_ moneda: String, decimales: Bool = false) -> String {
        Dinero.formato(self, moneda, decimales: decimales)
    }
}
