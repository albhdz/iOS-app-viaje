import Foundation
import CoreLocation

/// Costos diarios por persona en USD para un viajero de estilo "medio".
/// El hospedaje está calculado por persona en habitación doble.
/// Fuentes de referencia: índices de costo de viaje 2025-2026 (Budget Your Trip, Numbeo,
/// guías de presupuesto por país). Son aproximaciones: úsalas como punto de partida.
struct DailyCosts: Hashable {
    var hospedaje: Double
    var comida: Double
    var transporte: Double
    var actividades: Double

    var total: Double { hospedaje + comida + transporte + actividades }
}

struct Destination: Identifiable, Hashable {
    let id: String
    let nombre: String
    let pais: String
    let emoji: String
    let region: Region
    let latitud: Double
    let longitud: Double
    let moneda: String
    let costoMedio: DailyCosts
    let mejorEpoca: String
    let idioma: String
    let enchufe: String
    let propinas: String
    let imperdibles: [Imperdible]
    let tags: [TripType]

    var coordenada: CLLocationCoordinate2D { .init(latitude: latitud, longitude: longitud) }

    func costoDiario(_ estilo: TravelStyle) -> DailyCosts {
        // El hospedaje escala más que la comida o el transporte entre estilos.
        let m = estilo.multiplicador
        let mh = estilo == .mochilero ? 0.30 : (estilo == .lujo ? 4.0 : m)
        return DailyCosts(
            hospedaje: costoMedio.hospedaje * mh,
            comida: costoMedio.comida * m,
            transporte: costoMedio.transporte * (estilo == .lujo ? 2.5 : m),
            actividades: costoMedio.actividades * max(0.5, m)
        )
    }
}

/// Atracción o experiencia recomendada con costo aproximado por persona en USD.
struct Imperdible: Hashable, Identifiable {
    var id: String { nombre }
    let nombre: String
    let costoUSD: Double
    let categoria: ActivityCategory
    let horas: Double
}

struct OriginCity: Identifiable, Hashable {
    var id: String { nombre }
    let nombre: String
    let latitud: Double
    let longitud: Double
    let moneda: String
}

enum DestinationCatalog {

    static let origenes: [OriginCity] = [
        .init(nombre: "Ciudad de México", latitud: 19.4361, longitud: -99.0719, moneda: "MXN"),
        .init(nombre: "Guadalajara", latitud: 20.5218, longitud: -103.3112, moneda: "MXN"),
        .init(nombre: "Monterrey", latitud: 25.7785, longitud: -100.1069, moneda: "MXN"),
        .init(nombre: "Tijuana", latitud: 32.5411, longitud: -116.9700, moneda: "MXN"),
        .init(nombre: "Cancún", latitud: 21.0365, longitud: -86.8771, moneda: "MXN"),
        .init(nombre: "Bogotá", latitud: 4.7016, longitud: -74.1469, moneda: "COP"),
        .init(nombre: "Medellín", latitud: 6.1645, longitud: -75.4231, moneda: "COP"),
        .init(nombre: "Lima", latitud: -12.0219, longitud: -77.1143, moneda: "PEN"),
        .init(nombre: "Santiago de Chile", latitud: -33.3930, longitud: -70.7858, moneda: "CLP"),
        .init(nombre: "Buenos Aires", latitud: -34.8222, longitud: -58.5358, moneda: "ARS"),
        .init(nombre: "São Paulo", latitud: -23.4356, longitud: -46.4731, moneda: "BRL"),
        .init(nombre: "Ciudad de Panamá", latitud: 9.0714, longitud: -79.3835, moneda: "USD"),
        .init(nombre: "San José (CR)", latitud: 9.9939, longitud: -84.2088, moneda: "CRC"),
        .init(nombre: "Guatemala", latitud: 14.5833, longitud: -90.5275, moneda: "GTQ"),
        .init(nombre: "Santo Domingo", latitud: 18.4297, longitud: -69.6689, moneda: "DOP"),
        .init(nombre: "Madrid", latitud: 40.4983, longitud: -3.5676, moneda: "EUR"),
        .init(nombre: "Barcelona", latitud: 41.2974, longitud: 2.0833, moneda: "EUR"),
        .init(nombre: "Los Ángeles", latitud: 33.9416, longitud: -118.4085, moneda: "USD"),
        .init(nombre: "Houston", latitud: 29.9902, longitud: -95.3368, moneda: "USD"),
        .init(nombre: "Miami", latitud: 25.7959, longitud: -80.2870, moneda: "USD"),
        .init(nombre: "Nueva York", latitud: 40.6413, longitud: -73.7781, moneda: "USD"),
        .init(nombre: "Chicago", latitud: 41.9742, longitud: -87.9073, moneda: "USD"),
    ]

    static func destino(id: String?) -> Destination? {
        guard let id else { return nil }
        return todos.first { $0.id == id }
    }

    static let todos: [Destination] = [
        // MARK: Norteamérica
        .init(id: "cdmx", nombre: "Ciudad de México", pais: "México", emoji: "🇲🇽", region: .norteamerica,
              latitud: 19.4326, longitud: -99.1332, moneda: "MXN",
              costoMedio: .init(hospedaje: 55, comida: 30, transporte: 8, actividades: 15),
              mejorEpoca: "Oct–Abr (temporada seca)", idioma: "Español", enchufe: "A / B (127 V)",
              propinas: "10–15 % en restaurantes",
              imperdibles: [
                .init(nombre: "Teotihuacán (entrada + transporte)", costoUSD: 25, categoria: .visita, horas: 6),
                .init(nombre: "Museo Nacional de Antropología", costoUSD: 6, categoria: .visita, horas: 3),
                .init(nombre: "Trajinera en Xochimilco (por persona)", costoUSD: 15, categoria: .tour, horas: 2),
                .init(nombre: "Lucha libre en Arena México", costoUSD: 20, categoria: .vidaNocturna, horas: 3),
                .init(nombre: "Tour de tacos", costoUSD: 45, categoria: .comida, horas: 3),
              ], tags: [.ciudad, .negocios]),
        .init(id: "cancun", nombre: "Cancún / Riviera Maya", pais: "México", emoji: "🏝️", region: .norteamerica,
              latitud: 21.1619, longitud: -86.8515, moneda: "MXN",
              costoMedio: .init(hospedaje: 85, comida: 40, transporte: 15, actividades: 35),
              mejorEpoca: "Dic–Abr (evitar temporada de huracanes Ago–Oct)", idioma: "Español", enchufe: "A / B (127 V)",
              propinas: "10–15 %; USD aceptado en zona hotelera",
              imperdibles: [
                .init(nombre: "Chichén Itzá (tour)", costoUSD: 80, categoria: .tour, horas: 10),
                .init(nombre: "Xcaret (entrada básica)", costoUSD: 130, categoria: .aventura, horas: 9),
                .init(nombre: "Isla Mujeres en ferry", costoUSD: 30, categoria: .playa, horas: 6),
                .init(nombre: "Cenotes (tour de 3)", costoUSD: 65, categoria: .aventura, horas: 5),
                .init(nombre: "Ruinas de Tulum", costoUSD: 15, categoria: .visita, horas: 3),
              ], tags: [.playa, .aventura]),
        .init(id: "oaxaca", nombre: "Oaxaca", pais: "México", emoji: "🌶️", region: .norteamerica,
              latitud: 17.0732, longitud: -96.7266, moneda: "MXN",
              costoMedio: .init(hospedaje: 45, comida: 25, transporte: 6, actividades: 15),
              mejorEpoca: "Oct–Nov (Día de Muertos) y Mar–May", idioma: "Español", enchufe: "A / B (127 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Monte Albán", costoUSD: 6, categoria: .visita, horas: 3),
                .init(nombre: "Hierve el Agua (tour)", costoUSD: 30, categoria: .tour, horas: 8),
                .init(nombre: "Clase de cocina oaxaqueña", costoUSD: 75, categoria: .comida, horas: 4),
                .init(nombre: "Tour de mezcal", costoUSD: 40, categoria: .tour, horas: 5),
              ], tags: [.ciudad]),
        .init(id: "nyc", nombre: "Nueva York", pais: "Estados Unidos", emoji: "🗽", region: .norteamerica,
              latitud: 40.7128, longitud: -74.0060, moneda: "USD",
              costoMedio: .init(hospedaje: 160, comida: 70, transporte: 15, actividades: 40),
              mejorEpoca: "Abr–Jun y Sep–Nov", idioma: "Inglés", enchufe: "A / B (120 V)",
              propinas: "18–22 % obligatorio en la práctica",
              imperdibles: [
                .init(nombre: "Mirador Top of the Rock / Edge", costoUSD: 45, categoria: .visita, horas: 2),
                .init(nombre: "Estatua de la Libertad + Ellis Island", costoUSD: 25, categoria: .visita, horas: 4),
                .init(nombre: "Musical en Broadway", costoUSD: 150, categoria: .vidaNocturna, horas: 3),
                .init(nombre: "MET Museum", costoUSD: 30, categoria: .visita, horas: 3),
                .init(nombre: "Central Park en bici", costoUSD: 25, categoria: .aventura, horas: 2),
              ], tags: [.ciudad, .negocios]),
        .init(id: "la", nombre: "Los Ángeles", pais: "Estados Unidos", emoji: "🌴", region: .norteamerica,
              latitud: 34.0522, longitud: -118.2437, moneda: "USD",
              costoMedio: .init(hospedaje: 120, comida: 55, transporte: 30, actividades: 35),
              mejorEpoca: "Mar–May y Sep–Nov", idioma: "Inglés", enchufe: "A / B (120 V)",
              propinas: "18–22 %",
              imperdibles: [
                .init(nombre: "Universal Studios Hollywood", costoUSD: 120, categoria: .aventura, horas: 9),
                .init(nombre: "Disneyland (1 día)", costoUSD: 165, categoria: .aventura, horas: 10),
                .init(nombre: "Griffith Observatory", costoUSD: 0, categoria: .visita, horas: 2),
                .init(nombre: "Getty Center", costoUSD: 25, categoria: .visita, horas: 3),
              ], tags: [.ciudad, .playa]),
        .init(id: "vegas", nombre: "Las Vegas", pais: "Estados Unidos", emoji: "🎰", region: .norteamerica,
              latitud: 36.1699, longitud: -115.1398, moneda: "USD",
              costoMedio: .init(hospedaje: 80, comida: 55, transporte: 15, actividades: 50),
              mejorEpoca: "Mar–May y Oct–Nov", idioma: "Inglés", enchufe: "A / B (120 V)",
              propinas: "18–22 %; resort fees de 35–50 USD/noche",
              imperdibles: [
                .init(nombre: "Show del Cirque du Soleil", costoUSD: 120, categoria: .vidaNocturna, horas: 2),
                .init(nombre: "Gran Cañón (tour en bus)", costoUSD: 130, categoria: .tour, horas: 13),
                .init(nombre: "Sphere", costoUSD: 100, categoria: .vidaNocturna, horas: 2),
              ], tags: [.ciudad]),
        .init(id: "orlando", nombre: "Orlando", pais: "Estados Unidos", emoji: "🎢", region: .norteamerica,
              latitud: 28.5383, longitud: -81.3792, moneda: "USD",
              costoMedio: .init(hospedaje: 90, comida: 50, transporte: 25, actividades: 120),
              mejorEpoca: "Ene–Mar y Sep–Nov (menos filas)", idioma: "Inglés", enchufe: "A / B (120 V)",
              propinas: "18–22 %",
              imperdibles: [
                .init(nombre: "Magic Kingdom (1 día)", costoUSD: 150, categoria: .aventura, horas: 12),
                .init(nombre: "Universal Epic Universe", costoUSD: 160, categoria: .aventura, horas: 11),
                .init(nombre: "Kennedy Space Center", costoUSD: 80, categoria: .visita, horas: 7),
              ], tags: [.ciudad]),
        .init(id: "toronto", nombre: "Toronto", pais: "Canadá", emoji: "🇨🇦", region: .norteamerica,
              latitud: 43.6532, longitud: -79.3832, moneda: "CAD",
              costoMedio: .init(hospedaje: 100, comida: 50, transporte: 12, actividades: 30),
              mejorEpoca: "May–Oct", idioma: "Inglés / Francés", enchufe: "A / B (120 V)",
              propinas: "15–20 %",
              imperdibles: [
                .init(nombre: "Cataratas del Niágara + barco", costoUSD: 90, categoria: .tour, horas: 9),
                .init(nombre: "CN Tower", costoUSD: 32, categoria: .visita, horas: 2),
              ], tags: [.ciudad, .negocios]),
        .init(id: "banff", nombre: "Banff", pais: "Canadá", emoji: "🏔️", region: .norteamerica,
              latitud: 51.1784, longitud: -115.5708, moneda: "CAD",
              costoMedio: .init(hospedaje: 120, comida: 50, transporte: 35, actividades: 40),
              mejorEpoca: "Jun–Sep (lagos) / Dic–Mar (ski)", idioma: "Inglés", enchufe: "A / B (120 V)",
              propinas: "15–20 %",
              imperdibles: [
                .init(nombre: "Lake Louise + Moraine Lake (shuttle)", costoUSD: 20, categoria: .visita, horas: 6),
                .init(nombre: "Banff Gondola", costoUSD: 55, categoria: .visita, horas: 2),
                .init(nombre: "Pase de parque nacional (diario)", costoUSD: 8, categoria: .otro, horas: 0),
                .init(nombre: "Pase de ski (1 día)", costoUSD: 140, categoria: .aventura, horas: 7),
              ], tags: [.montana, .nieve]),

        // MARK: Centroamérica y Caribe
        .init(id: "habana", nombre: "La Habana", pais: "Cuba", emoji: "🇨🇺", region: .centroamericaCaribe,
              latitud: 23.1136, longitud: -82.3666, moneda: "USD",
              costoMedio: .init(hospedaje: 45, comida: 25, transporte: 10, actividades: 15),
              mejorEpoca: "Nov–Abr", idioma: "Español", enchufe: "A / B / C (110/220 V)",
              propinas: "10 %; lleva efectivo (euros/dólares)",
              imperdibles: [
                .init(nombre: "Paseo en auto clásico", costoUSD: 40, categoria: .tour, horas: 1),
                .init(nombre: "Viñales (tour de día)", costoUSD: 60, categoria: .tour, horas: 10),
              ], tags: [.ciudad, .playa]),
        .init(id: "puntacana", nombre: "Punta Cana", pais: "República Dominicana", emoji: "🇩🇴", region: .centroamericaCaribe,
              latitud: 18.5601, longitud: -68.3725, moneda: "DOP",
              costoMedio: .init(hospedaje: 120, comida: 15, transporte: 10, actividades: 30),
              mejorEpoca: "Dic–Abr", idioma: "Español", enchufe: "A / B (120 V)",
              propinas: "10 % incluido + 5–10 % extra; hospedaje aprox. todo incluido",
              imperdibles: [
                .init(nombre: "Isla Saona (tour)", costoUSD: 95, categoria: .playa, horas: 9),
                .init(nombre: "Hoyo Azul / Scape Park", costoUSD: 110, categoria: .aventura, horas: 6),
              ], tags: [.playa]),
        .init(id: "costarica", nombre: "Costa Rica (La Fortuna / Manuel Antonio)", pais: "Costa Rica", emoji: "🦥", region: .centroamericaCaribe,
              latitud: 10.4679, longitud: -84.6427, moneda: "CRC",
              costoMedio: .init(hospedaje: 65, comida: 30, transporte: 20, actividades: 55),
              mejorEpoca: "Dic–Abr (seca)", idioma: "Español", enchufe: "A / B (120 V)",
              propinas: "10 % de servicio ya incluido",
              imperdibles: [
                .init(nombre: "Volcán Arenal + aguas termales", costoUSD: 85, categoria: .aventura, horas: 6),
                .init(nombre: "Canopy / tirolesa", costoUSD: 75, categoria: .aventura, horas: 3),
                .init(nombre: "Parque Nacional Manuel Antonio", costoUSD: 20, categoria: .visita, horas: 4),
              ], tags: [.aventura, .playa, .montana]),
        .init(id: "antigua", nombre: "Antigua Guatemala", pais: "Guatemala", emoji: "🌋", region: .centroamericaCaribe,
              latitud: 14.5586, longitud: -90.7295, moneda: "GTQ",
              costoMedio: .init(hospedaje: 35, comida: 18, transporte: 8, actividades: 20),
              mejorEpoca: "Nov–Abr", idioma: "Español", enchufe: "A / B (120 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Subida al Acatenango (2 días)", costoUSD: 90, categoria: .aventura, horas: 30),
                .init(nombre: "Lago Atitlán", costoUSD: 40, categoria: .tour, horas: 10),
              ], tags: [.aventura, .montana, .ciudad]),

        // MARK: Sudamérica
        .init(id: "cartagena", nombre: "Cartagena", pais: "Colombia", emoji: "🇨🇴", region: .sudamerica,
              latitud: 10.3910, longitud: -75.4794, moneda: "COP",
              costoMedio: .init(hospedaje: 50, comida: 25, transporte: 8, actividades: 20),
              mejorEpoca: "Dic–Abr", idioma: "Español", enchufe: "A / B (110 V)",
              propinas: "10 % sugerido en la cuenta",
              imperdibles: [
                .init(nombre: "Islas del Rosario (tour)", costoUSD: 55, categoria: .playa, horas: 8),
                .init(nombre: "Castillo San Felipe", costoUSD: 10, categoria: .visita, horas: 2),
              ], tags: [.playa, .ciudad]),
        .init(id: "medellin", nombre: "Medellín", pais: "Colombia", emoji: "🌺", region: .sudamerica,
              latitud: 6.2442, longitud: -75.5812, moneda: "COP",
              costoMedio: .init(hospedaje: 40, comida: 20, transporte: 6, actividades: 15),
              mejorEpoca: "Todo el año (Feria de las Flores en Ago)", idioma: "Español", enchufe: "A / B (110 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Guatapé y Peñol", costoUSD: 35, categoria: .tour, horas: 10),
                .init(nombre: "Comuna 13 graffiti tour", costoUSD: 15, categoria: .tour, horas: 3),
              ], tags: [.ciudad]),
        .init(id: "cusco", nombre: "Cusco y Machu Picchu", pais: "Perú", emoji: "🦙", region: .sudamerica,
              latitud: -13.5320, longitud: -71.9675, moneda: "PEN",
              costoMedio: .init(hospedaje: 45, comida: 22, transporte: 10, actividades: 45),
              mejorEpoca: "May–Sep (seca)", idioma: "Español / Quechua", enchufe: "A / C (220 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Machu Picchu (tren + bus + entrada)", costoUSD: 230, categoria: .tour, horas: 14),
                .init(nombre: "Montaña de 7 Colores", costoUSD: 45, categoria: .aventura, horas: 12),
                .init(nombre: "Boleto turístico Valle Sagrado", costoUSD: 40, categoria: .visita, horas: 8),
              ], tags: [.montana, .aventura]),
        .init(id: "buenosaires", nombre: "Buenos Aires", pais: "Argentina", emoji: "🇦🇷", region: .sudamerica,
              latitud: -34.6037, longitud: -58.3816, moneda: "ARS",
              costoMedio: .init(hospedaje: 50, comida: 35, transporte: 5, actividades: 15),
              mejorEpoca: "Mar–May y Sep–Nov", idioma: "Español", enchufe: "C / I (220 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Show de tango con cena", costoUSD: 90, categoria: .vidaNocturna, horas: 3),
                .init(nombre: "Partido en La Bombonera", costoUSD: 120, categoria: .vidaNocturna, horas: 4),
                .init(nombre: "Tigre (delta)", costoUSD: 25, categoria: .tour, horas: 6),
              ], tags: [.ciudad]),
        .init(id: "rio", nombre: "Río de Janeiro", pais: "Brasil", emoji: "🇧🇷", region: .sudamerica,
              latitud: -22.9068, longitud: -43.1729, moneda: "BRL",
              costoMedio: .init(hospedaje: 55, comida: 30, transporte: 10, actividades: 20),
              mejorEpoca: "Dic–Mar (verano) / Carnaval", idioma: "Portugués", enchufe: "N (127/220 V)",
              propinas: "10 % incluido",
              imperdibles: [
                .init(nombre: "Cristo Redentor (tren)", costoUSD: 25, categoria: .visita, horas: 3),
                .init(nombre: "Pan de Azúcar (teleférico)", costoUSD: 32, categoria: .visita, horas: 2),
              ], tags: [.playa, .ciudad]),
        .init(id: "patagonia", nombre: "Patagonia (Torres del Paine)", pais: "Chile", emoji: "🏔️", region: .sudamerica,
              latitud: -51.0, longitud: -73.0, moneda: "CLP",
              costoMedio: .init(hospedaje: 80, comida: 40, transporte: 25, actividades: 50),
              mejorEpoca: "Nov–Mar", idioma: "Español", enchufe: "C / L (220 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Entrada Parque Torres del Paine", costoUSD: 49, categoria: .visita, horas: 0),
                .init(nombre: "Trekking Base Torres", costoUSD: 0, categoria: .aventura, horas: 9),
                .init(nombre: "Navegación Glaciar Grey", costoUSD: 120, categoria: .tour, horas: 3),
              ], tags: [.montana, .aventura]),

        // MARK: Europa Occidental
        .init(id: "madrid", nombre: "Madrid", pais: "España", emoji: "🇪🇸", region: .europaOccidental,
              latitud: 40.4168, longitud: -3.7038, moneda: "EUR",
              costoMedio: .init(hospedaje: 75, comida: 40, transporte: 8, actividades: 20),
              mejorEpoca: "Abr–Jun y Sep–Oct", idioma: "Español", enchufe: "C / F (230 V)",
              propinas: "No obligatoria; redondear 5–10 %",
              imperdibles: [
                .init(nombre: "Museo del Prado", costoUSD: 16, categoria: .visita, horas: 3),
                .init(nombre: "Palacio Real", costoUSD: 15, categoria: .visita, horas: 2),
                .init(nombre: "Toledo (excursión)", costoUSD: 40, categoria: .tour, horas: 8),
                .init(nombre: "Tour Bernabéu", costoUSD: 30, categoria: .visita, horas: 2),
              ], tags: [.ciudad, .negocios]),
        .init(id: "barcelona", nombre: "Barcelona", pais: "España", emoji: "⛪", region: .europaOccidental,
              latitud: 41.3874, longitud: 2.1686, moneda: "EUR",
              costoMedio: .init(hospedaje: 90, comida: 45, transporte: 9, actividades: 25),
              mejorEpoca: "May–Jun y Sep", idioma: "Español / Catalán", enchufe: "C / F (230 V)",
              propinas: "No obligatoria; tasa turística 4–8 €/noche",
              imperdibles: [
                .init(nombre: "Sagrada Familia (con torres)", costoUSD: 40, categoria: .visita, horas: 2),
                .init(nombre: "Park Güell", costoUSD: 20, categoria: .visita, horas: 2),
                .init(nombre: "Casa Batlló", costoUSD: 38, categoria: .visita, horas: 1.5),
                .init(nombre: "Montserrat (excursión)", costoUSD: 50, categoria: .tour, horas: 7),
              ], tags: [.ciudad, .playa]),
        .init(id: "paris", nombre: "París", pais: "Francia", emoji: "🇫🇷", region: .europaOccidental,
              latitud: 48.8566, longitud: 2.3522, moneda: "EUR",
              costoMedio: .init(hospedaje: 130, comida: 60, transporte: 12, actividades: 35),
              mejorEpoca: "Abr–Jun y Sep–Oct", idioma: "Francés", enchufe: "C / E (230 V)",
              propinas: "Servicio incluido; redondear",
              imperdibles: [
                .init(nombre: "Torre Eiffel (cima)", costoUSD: 40, categoria: .visita, horas: 2),
                .init(nombre: "Museo del Louvre", costoUSD: 25, categoria: .visita, horas: 4),
                .init(nombre: "Versalles", costoUSD: 35, categoria: .visita, horas: 6),
                .init(nombre: "Crucero por el Sena", costoUSD: 20, categoria: .tour, horas: 1),
                .init(nombre: "Disneyland París", costoUSD: 110, categoria: .aventura, horas: 10),
              ], tags: [.ciudad, .negocios]),
        .init(id: "roma", nombre: "Roma", pais: "Italia", emoji: "🇮🇹", region: .europaOccidental,
              latitud: 41.9028, longitud: 12.4964, moneda: "EUR",
              costoMedio: .init(hospedaje: 100, comida: 50, transporte: 10, actividades: 30),
              mejorEpoca: "Abr–Jun y Sep–Oct", idioma: "Italiano", enchufe: "C / F / L (230 V)",
              propinas: "Coperto incluido; propina opcional",
              imperdibles: [
                .init(nombre: "Coliseo + Foro Romano", costoUSD: 25, categoria: .visita, horas: 4),
                .init(nombre: "Museos Vaticanos + Capilla Sixtina", costoUSD: 30, categoria: .visita, horas: 4),
                .init(nombre: "Clase de pasta", costoUSD: 70, categoria: .comida, horas: 3),
              ], tags: [.ciudad]),
        .init(id: "londres", nombre: "Londres", pais: "Reino Unido", emoji: "🇬🇧", region: .europaOccidental,
              latitud: 51.5074, longitud: -0.1278, moneda: "GBP",
              costoMedio: .init(hospedaje: 140, comida: 60, transporte: 15, actividades: 30),
              mejorEpoca: "May–Sep", idioma: "Inglés", enchufe: "G (230 V)",
              propinas: "12,5 % suele venir incluido",
              imperdibles: [
                .init(nombre: "Torre de Londres", costoUSD: 45, categoria: .visita, horas: 3),
                .init(nombre: "London Eye", costoUSD: 40, categoria: .visita, horas: 1),
                .init(nombre: "Warner Bros. Studio Tour (Harry Potter)", costoUSD: 75, categoria: .tour, horas: 5),
                .init(nombre: "Musical en el West End", costoUSD: 90, categoria: .vidaNocturna, horas: 3),
              ], tags: [.ciudad, .negocios]),
        .init(id: "amsterdam", nombre: "Ámsterdam", pais: "Países Bajos", emoji: "🇳🇱", region: .europaOccidental,
              latitud: 52.3676, longitud: 4.9041, moneda: "EUR",
              costoMedio: .init(hospedaje: 130, comida: 55, transporte: 12, actividades: 30),
              mejorEpoca: "Abr–May (tulipanes) y Sep", idioma: "Neerlandés", enchufe: "C / F (230 V)",
              propinas: "5–10 %; tasa turística 12,5 %",
              imperdibles: [
                .init(nombre: "Museo Van Gogh", costoUSD: 25, categoria: .visita, horas: 2),
                .init(nombre: "Casa de Ana Frank", costoUSD: 18, categoria: .visita, horas: 1.5),
                .init(nombre: "Paseo por canales", costoUSD: 22, categoria: .tour, horas: 1),
              ], tags: [.ciudad]),
        .init(id: "lisboa", nombre: "Lisboa", pais: "Portugal", emoji: "🇵🇹", region: .europaOccidental,
              latitud: 38.7223, longitud: -9.1393, moneda: "EUR",
              costoMedio: .init(hospedaje: 75, comida: 35, transporte: 8, actividades: 18),
              mejorEpoca: "Mar–Jun y Sep–Oct", idioma: "Portugués", enchufe: "C / F (230 V)",
              propinas: "5–10 %",
              imperdibles: [
                .init(nombre: "Sintra (palacios)", costoUSD: 45, categoria: .visita, horas: 8),
                .init(nombre: "Torre de Belém + Jerónimos", costoUSD: 25, categoria: .visita, horas: 3),
                .init(nombre: "Tranvía 28", costoUSD: 4, categoria: .traslado, horas: 1),
              ], tags: [.ciudad, .playa]),
        .init(id: "reikiavik", nombre: "Islandia (Reikiavik)", pais: "Islandia", emoji: "🇮🇸", region: .europaOccidental,
              latitud: 64.1466, longitud: -21.9426, moneda: "ISK",
              costoMedio: .init(hospedaje: 150, comida: 70, transporte: 45, actividades: 60),
              mejorEpoca: "Jun–Ago (sol) / Sep–Mar (auroras)", idioma: "Islandés", enchufe: "C / F (230 V)",
              propinas: "No se acostumbra",
              imperdibles: [
                .init(nombre: "Blue Lagoon", costoUSD: 85, categoria: .descanso, horas: 3),
                .init(nombre: "Círculo Dorado (tour)", costoUSD: 90, categoria: .tour, horas: 8),
                .init(nombre: "Tour de auroras boreales", costoUSD: 75, categoria: .tour, horas: 4),
              ], tags: [.aventura, .nieve, .montana]),
        .init(id: "suiza", nombre: "Alpes Suizos (Interlaken / Zermatt)", pais: "Suiza", emoji: "🇨🇭", region: .europaOccidental,
              latitud: 46.6863, longitud: 7.8632, moneda: "CHF",
              costoMedio: .init(hospedaje: 160, comida: 75, transporte: 40, actividades: 70),
              mejorEpoca: "Jun–Sep (senderismo) / Dic–Mar (ski)", idioma: "Alemán / Francés", enchufe: "J (230 V)",
              propinas: "Incluida; redondear",
              imperdibles: [
                .init(nombre: "Jungfraujoch", costoUSD: 250, categoria: .visita, horas: 8),
                .init(nombre: "Swiss Travel Pass (3 días)", costoUSD: 270, categoria: .traslado, horas: 0),
                .init(nombre: "Parapente en Interlaken", costoUSD: 190, categoria: .aventura, horas: 2),
              ], tags: [.montana, .nieve]),

        // MARK: Europa del Este y Mediterráneo
        .init(id: "praga", nombre: "Praga", pais: "Chequia", emoji: "🇨🇿", region: .europaOriental,
              latitud: 50.0755, longitud: 14.4378, moneda: "CZK",
              costoMedio: .init(hospedaje: 60, comida: 30, transporte: 6, actividades: 15),
              mejorEpoca: "Abr–Jun y Sep–Oct; mercados navideños en Dic", idioma: "Checo", enchufe: "C / E (230 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Castillo de Praga", costoUSD: 20, categoria: .visita, horas: 3),
                .init(nombre: "Tour de cerveza", costoUSD: 40, categoria: .vidaNocturna, horas: 3),
              ], tags: [.ciudad]),
        .init(id: "budapest", nombre: "Budapest", pais: "Hungría", emoji: "🇭🇺", region: .europaOriental,
              latitud: 47.4979, longitud: 19.0402, moneda: "HUF",
              costoMedio: .init(hospedaje: 55, comida: 30, transporte: 6, actividades: 15),
              mejorEpoca: "Abr–Jun y Sep–Oct", idioma: "Húngaro", enchufe: "C / F (230 V)",
              propinas: "10–15 %",
              imperdibles: [
                .init(nombre: "Baños Széchenyi", costoUSD: 35, categoria: .descanso, horas: 3),
                .init(nombre: "Parlamento (visita guiada)", costoUSD: 30, categoria: .visita, horas: 1),
                .init(nombre: "Crucero nocturno por el Danubio", costoUSD: 25, categoria: .tour, horas: 1),
              ], tags: [.ciudad]),
        .init(id: "grecia", nombre: "Atenas y Santorini", pais: "Grecia", emoji: "🇬🇷", region: .europaOriental,
              latitud: 37.9838, longitud: 23.7275, moneda: "EUR",
              costoMedio: .init(hospedaje: 95, comida: 40, transporte: 15, actividades: 25),
              mejorEpoca: "May–Jun y Sep–Oct", idioma: "Griego", enchufe: "C / F (230 V)",
              propinas: "5–10 %",
              imperdibles: [
                .init(nombre: "Acrópolis", costoUSD: 32, categoria: .visita, horas: 3),
                .init(nombre: "Ferry Atenas–Santorini", costoUSD: 90, categoria: .traslado, horas: 6),
                .init(nombre: "Catamarán al atardecer (Santorini)", costoUSD: 140, categoria: .playa, horas: 5),
              ], tags: [.playa, .ciudad]),
        .init(id: "estambul", nombre: "Estambul", pais: "Turquía", emoji: "🇹🇷", region: .europaOriental,
              latitud: 41.0082, longitud: 28.9784, moneda: "TRY",
              costoMedio: .init(hospedaje: 60, comida: 25, transporte: 6, actividades: 25),
              mejorEpoca: "Abr–May y Sep–Nov", idioma: "Turco", enchufe: "C / F (230 V)",
              propinas: "5–10 %",
              imperdibles: [
                .init(nombre: "Santa Sofía + Mezquita Azul", costoUSD: 28, categoria: .visita, horas: 3),
                .init(nombre: "Palacio Topkapi", costoUSD: 50, categoria: .visita, horas: 3),
                .init(nombre: "Crucero por el Bósforo", costoUSD: 20, categoria: .tour, horas: 2),
                .init(nombre: "Globo en Capadocia (extensión)", costoUSD: 250, categoria: .aventura, horas: 4),
              ], tags: [.ciudad]),

        // MARK: Medio Oriente y África
        .init(id: "dubai", nombre: "Dubái", pais: "Emiratos Árabes", emoji: "🇦🇪", region: .medioOriente,
              latitud: 25.2048, longitud: 55.2708, moneda: "AED",
              costoMedio: .init(hospedaje: 120, comida: 50, transporte: 20, actividades: 50),
              mejorEpoca: "Nov–Mar", idioma: "Árabe / Inglés", enchufe: "G (230 V)",
              propinas: "10–15 %",
              imperdibles: [
                .init(nombre: "Burj Khalifa (piso 124)", costoUSD: 45, categoria: .visita, horas: 2),
                .init(nombre: "Safari en el desierto con cena", costoUSD: 70, categoria: .aventura, horas: 6),
              ], tags: [.ciudad, .playa, .negocios]),
        .init(id: "marrakech", nombre: "Marrakech", pais: "Marruecos", emoji: "🇲🇦", region: .africa,
              latitud: 31.6295, longitud: -7.9811, moneda: "MAD",
              costoMedio: .init(hospedaje: 50, comida: 20, transporte: 6, actividades: 20),
              mejorEpoca: "Mar–May y Sep–Nov", idioma: "Árabe / Francés", enchufe: "C / E (220 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Excursión al Sahara (3 días)", costoUSD: 150, categoria: .aventura, horas: 72),
                .init(nombre: "Jardín Majorelle", costoUSD: 16, categoria: .visita, horas: 1.5),
                .init(nombre: "Hammam tradicional", costoUSD: 30, categoria: .descanso, horas: 2),
              ], tags: [.aventura, .ciudad]),
        .init(id: "elcairo", nombre: "El Cairo y Luxor", pais: "Egipto", emoji: "🇪🇬", region: .africa,
              latitud: 30.0444, longitud: 31.2357, moneda: "EGP",
              costoMedio: .init(hospedaje: 40, comida: 15, transporte: 8, actividades: 35),
              mejorEpoca: "Oct–Abr", idioma: "Árabe", enchufe: "C / F (220 V)",
              propinas: "Baksheesh: lleva billetes pequeños",
              imperdibles: [
                .init(nombre: "Pirámides de Giza", costoUSD: 25, categoria: .visita, horas: 4),
                .init(nombre: "Gran Museo Egipcio", costoUSD: 25, categoria: .visita, horas: 4),
                .init(nombre: "Crucero por el Nilo (3 noches)", costoUSD: 350, categoria: .tour, horas: 72),
              ], tags: [.aventura, .ciudad]),
        .init(id: "capetown", nombre: "Ciudad del Cabo", pais: "Sudáfrica", emoji: "🇿🇦", region: .africa,
              latitud: -33.9249, longitud: 18.4241, moneda: "ZAR",
              costoMedio: .init(hospedaje: 60, comida: 30, transporte: 20, actividades: 30),
              mejorEpoca: "Nov–Mar", idioma: "Inglés / Afrikáans", enchufe: "M / N (230 V)",
              propinas: "10–15 %",
              imperdibles: [
                .init(nombre: "Table Mountain (teleférico)", costoUSD: 25, categoria: .visita, horas: 3),
                .init(nombre: "Safari (2 días, reserva privada)", costoUSD: 450, categoria: .aventura, horas: 48),
              ], tags: [.aventura, .playa]),

        // MARK: Asia
        .init(id: "tokio", nombre: "Tokio", pais: "Japón", emoji: "🇯🇵", region: .asiaEste,
              latitud: 35.6762, longitud: 139.6503, moneda: "JPY",
              costoMedio: .init(hospedaje: 95, comida: 40, transporte: 12, actividades: 25),
              mejorEpoca: "Mar–Abr (sakura) y Oct–Nov", idioma: "Japonés", enchufe: "A / B (100 V)",
              propinas: "No se da propina",
              imperdibles: [
                .init(nombre: "teamLab Planets", costoUSD: 25, categoria: .visita, horas: 2),
                .init(nombre: "Shibuya Sky", costoUSD: 17, categoria: .visita, horas: 1),
                .init(nombre: "Tokyo DisneySea", costoUSD: 65, categoria: .aventura, horas: 10),
                .init(nombre: "Monte Fuji / Hakone (excursión)", costoUSD: 80, categoria: .tour, horas: 10),
                .init(nombre: "Japan Rail Pass 7 días", costoUSD: 335, categoria: .traslado, horas: 0),
              ], tags: [.ciudad, .negocios]),
        .init(id: "kioto", nombre: "Kioto y Osaka", pais: "Japón", emoji: "⛩️", region: .asiaEste,
              latitud: 35.0116, longitud: 135.7681, moneda: "JPY",
              costoMedio: .init(hospedaje: 85, comida: 35, transporte: 10, actividades: 20),
              mejorEpoca: "Mar–Abr y Nov", idioma: "Japonés", enchufe: "A / B (100 V)",
              propinas: "No se da propina",
              imperdibles: [
                .init(nombre: "Fushimi Inari", costoUSD: 0, categoria: .visita, horas: 3),
                .init(nombre: "Ceremonia del té", costoUSD: 35, categoria: .visita, horas: 1.5),
                .init(nombre: "Universal Studios Japan", costoUSD: 65, categoria: .aventura, horas: 10),
                .init(nombre: "Nara (ciervos)", costoUSD: 10, categoria: .visita, horas: 5),
              ], tags: [.ciudad]),
        .init(id: "seul", nombre: "Seúl", pais: "Corea del Sur", emoji: "🇰🇷", region: .asiaEste,
              latitud: 37.5665, longitud: 126.9780, moneda: "KRW",
              costoMedio: .init(hospedaje: 75, comida: 30, transporte: 8, actividades: 20),
              mejorEpoca: "Abr–May y Sep–Nov", idioma: "Coreano", enchufe: "C / F (220 V)",
              propinas: "No se acostumbra",
              imperdibles: [
                .init(nombre: "Palacio Gyeongbokgung (con hanbok gratis)", costoUSD: 3, categoria: .visita, horas: 2),
                .init(nombre: "Tour DMZ", costoUSD: 70, categoria: .tour, horas: 8),
                .init(nombre: "N Seoul Tower", costoUSD: 20, categoria: .visita, horas: 2),
              ], tags: [.ciudad]),
        .init(id: "bangkok", nombre: "Bangkok y Tailandia", pais: "Tailandia", emoji: "🇹🇭", region: .asiaSudeste,
              latitud: 13.7563, longitud: 100.5018, moneda: "THB",
              costoMedio: .init(hospedaje: 40, comida: 18, transporte: 7, actividades: 15),
              mejorEpoca: "Nov–Feb", idioma: "Tailandés", enchufe: "A / B / C (220 V)",
              propinas: "Opcional; redondear",
              imperdibles: [
                .init(nombre: "Gran Palacio", costoUSD: 15, categoria: .visita, horas: 3),
                .init(nombre: "Mercado flotante", costoUSD: 30, categoria: .tour, horas: 6),
                .init(nombre: "Masaje tailandés", costoUSD: 12, categoria: .descanso, horas: 1),
                .init(nombre: "Islas Phi Phi (tour)", costoUSD: 60, categoria: .playa, horas: 9),
              ], tags: [.ciudad, .playa, .aventura]),
        .init(id: "bali", nombre: "Bali", pais: "Indonesia", emoji: "🇮🇩", region: .asiaSudeste,
              latitud: -8.3405, longitud: 115.0920, moneda: "IDR",
              costoMedio: .init(hospedaje: 40, comida: 18, transporte: 10, actividades: 20),
              mejorEpoca: "Abr–Oct (seca)", idioma: "Indonesio", enchufe: "C / F (230 V)",
              propinas: "5–10 %; tasa turística de 150k IDR",
              imperdibles: [
                .init(nombre: "Amanecer en el Monte Batur", costoUSD: 45, categoria: .aventura, horas: 8),
                .init(nombre: "Terrazas de arroz Tegallalang", costoUSD: 5, categoria: .visita, horas: 2),
                .init(nombre: "Nusa Penida (tour)", costoUSD: 55, categoria: .playa, horas: 10),
              ], tags: [.playa, .aventura]),
        .init(id: "vietnam", nombre: "Hanói y Bahía de Ha Long", pais: "Vietnam", emoji: "🇻🇳", region: .asiaSudeste,
              latitud: 21.0278, longitud: 105.8342, moneda: "VND",
              costoMedio: .init(hospedaje: 30, comida: 15, transporte: 5, actividades: 15),
              mejorEpoca: "Oct–Abr", idioma: "Vietnamita", enchufe: "A / C (220 V)",
              propinas: "Opcional",
              imperdibles: [
                .init(nombre: "Crucero Ha Long (1 noche)", costoUSD: 150, categoria: .tour, horas: 24),
                .init(nombre: "Tour de comida callejera", costoUSD: 25, categoria: .comida, horas: 3),
              ], tags: [.aventura, .ciudad]),
        .init(id: "singapur", nombre: "Singapur", pais: "Singapur", emoji: "🇸🇬", region: .asiaSudeste,
              latitud: 1.3521, longitud: 103.8198, moneda: "SGD",
              costoMedio: .init(hospedaje: 120, comida: 35, transporte: 10, actividades: 30),
              mejorEpoca: "Feb–Abr", idioma: "Inglés / Mandarín / Malayo", enchufe: "G (230 V)",
              propinas: "10 % incluido",
              imperdibles: [
                .init(nombre: "Gardens by the Bay (domos)", costoUSD: 40, categoria: .visita, horas: 3),
                .init(nombre: "Universal Studios Singapore", costoUSD: 65, categoria: .aventura, horas: 9),
              ], tags: [.ciudad, .negocios]),
        .init(id: "india", nombre: "Triángulo de Oro (Delhi–Agra–Jaipur)", pais: "India", emoji: "🇮🇳", region: .asiaSur,
              latitud: 28.6139, longitud: 77.2090, moneda: "INR",
              costoMedio: .init(hospedaje: 35, comida: 12, transporte: 8, actividades: 12),
              mejorEpoca: "Oct–Mar", idioma: "Hindi / Inglés", enchufe: "C / D / M (230 V)",
              propinas: "10 %",
              imperdibles: [
                .init(nombre: "Taj Mahal", costoUSD: 15, categoria: .visita, horas: 3),
                .init(nombre: "Fuerte Amber", costoUSD: 6, categoria: .visita, horas: 3),
              ], tags: [.aventura, .ciudad]),
        .init(id: "maldivas", nombre: "Maldivas", pais: "Maldivas", emoji: "🇲🇻", region: .asiaSur,
              latitud: 3.2028, longitud: 73.2207, moneda: "USD",
              costoMedio: .init(hospedaje: 220, comida: 70, transporte: 60, actividades: 60),
              mejorEpoca: "Nov–Abr", idioma: "Dhivehi / Inglés", enchufe: "D / G (230 V)",
              propinas: "10 % servicio + impuesto 17 %",
              imperdibles: [
                .init(nombre: "Snorkel con mantarrayas", costoUSD: 90, categoria: .aventura, horas: 3),
                .init(nombre: "Hidroavión al resort (ida y vuelta)", costoUSD: 700, categoria: .traslado, horas: 2),
              ], tags: [.playa]),

        // MARK: Oceanía
        .init(id: "sidney", nombre: "Sídney", pais: "Australia", emoji: "🇦🇺", region: .oceania,
              latitud: -33.8688, longitud: 151.2093, moneda: "AUD",
              costoMedio: .init(hospedaje: 120, comida: 55, transporte: 12, actividades: 30),
              mejorEpoca: "Sep–Nov y Mar–May", idioma: "Inglés", enchufe: "I (230 V)",
              propinas: "No obligatoria",
              imperdibles: [
                .init(nombre: "Ópera de Sídney (tour)", costoUSD: 30, categoria: .visita, horas: 1),
                .init(nombre: "Blue Mountains", costoUSD: 90, categoria: .tour, horas: 10),
                .init(nombre: "Bondi a Coogee (caminata)", costoUSD: 0, categoria: .playa, horas: 3),
              ], tags: [.ciudad, .playa]),
        .init(id: "queenstown", nombre: "Queenstown", pais: "Nueva Zelanda", emoji: "🇳🇿", region: .oceania,
              latitud: -45.0312, longitud: 168.6626, moneda: "NZD",
              costoMedio: .init(hospedaje: 100, comida: 50, transporte: 30, actividades: 70),
              mejorEpoca: "Dic–Mar (verano) / Jun–Ago (ski)", idioma: "Inglés", enchufe: "I (230 V)",
              propinas: "No obligatoria",
              imperdibles: [
                .init(nombre: "Milford Sound (crucero)", costoUSD: 160, categoria: .tour, horas: 12),
                .init(nombre: "Bungee Kawarau", costoUSD: 170, categoria: .aventura, horas: 2),
              ], tags: [.aventura, .montana, .nieve]),
    ]
}
