import SwiftUI

/// Estilo de viaje: determina el nivel de gasto diario estimado.
enum TravelStyle: String, Codable, CaseIterable, Identifiable {
    case mochilero
    case economico
    case medio
    case confort
    case lujo

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .mochilero: "Mochilero"
        case .economico: "Económico"
        case .medio: "Medio"
        case .confort: "Confort"
        case .lujo: "Lujo"
        }
    }

    var descripcion: String {
        switch self {
        case .mochilero: "Hostales en dormitorio, comida callejera, transporte público"
        case .economico: "Hostal privado o hotel 2★, comida local, algún tour"
        case .medio: "Hotel 3★ / Airbnb, restaurantes, tours y taxis"
        case .confort: "Hotel 4★, buenos restaurantes, actividades guiadas"
        case .lujo: "Hotel 5★, alta cocina, traslados privados"
        }
    }

    var icono: String {
        switch self {
        case .mochilero: "backpack"
        case .economico: "bed.double"
        case .medio: "building.2"
        case .confort: "star"
        case .lujo: "crown"
        }
    }

    /// Multiplicador sobre el costo "medio" del destino.
    var multiplicador: Double {
        switch self {
        case .mochilero: 0.40
        case .economico: 0.65
        case .medio: 1.0
        case .confort: 1.7
        case .lujo: 3.2
        }
    }

    /// Clase de vuelo asociada (multiplicador sobre turista).
    var multiplicadorVuelo: Double {
        switch self {
        case .mochilero, .economico, .medio: 1.0
        case .confort: 1.35   // turista premium / mejor horario
        case .lujo: 3.5       // business
        }
    }
}

/// Categorías de gasto usadas en presupuesto y gastos reales.
enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case vuelos
    case hospedaje
    case comida
    case transporteLocal
    case actividades
    case seguro
    case visaDocumentos
    case conectividad
    case compras
    case propinas
    case salud
    case otros

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .vuelos: "Vuelos"
        case .hospedaje: "Hospedaje"
        case .comida: "Comida y bebida"
        case .transporteLocal: "Transporte local"
        case .actividades: "Actividades y tours"
        case .seguro: "Seguro de viaje"
        case .visaDocumentos: "Visa y documentos"
        case .conectividad: "eSIM / Internet"
        case .compras: "Compras y souvenirs"
        case .propinas: "Propinas"
        case .salud: "Salud y vacunas"
        case .otros: "Otros / Imprevistos"
        }
    }

    var icono: String {
        switch self {
        case .vuelos: "airplane"
        case .hospedaje: "bed.double.fill"
        case .comida: "fork.knife"
        case .transporteLocal: "tram.fill"
        case .actividades: "ticket.fill"
        case .seguro: "cross.case.fill"
        case .visaDocumentos: "doc.text.fill"
        case .conectividad: "simcard.fill"
        case .compras: "bag.fill"
        case .propinas: "hand.thumbsup.fill"
        case .salud: "syringe.fill"
        case .otros: "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .vuelos: .blue
        case .hospedaje: .indigo
        case .comida: .orange
        case .transporteLocal: .teal
        case .actividades: .pink
        case .seguro: .red
        case .visaDocumentos: .brown
        case .conectividad: .cyan
        case .compras: .purple
        case .propinas: .yellow
        case .salud: .green
        case .otros: .gray
        }
    }
}

/// Tipos de reservación.
enum BookingType: String, Codable, CaseIterable, Identifiable {
    case vuelo, hotel, auto, tren, bus, ferry, tour, restaurante, evento, seguro, otro

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .vuelo: "Vuelo"
        case .hotel: "Hospedaje"
        case .auto: "Renta de auto"
        case .tren: "Tren"
        case .bus: "Autobús"
        case .ferry: "Ferry / Barco"
        case .tour: "Tour / Excursión"
        case .restaurante: "Restaurante"
        case .evento: "Evento / Entradas"
        case .seguro: "Seguro"
        case .otro: "Otro"
        }
    }

    var icono: String {
        switch self {
        case .vuelo: "airplane.departure"
        case .hotel: "building.2.fill"
        case .auto: "car.fill"
        case .tren: "tram.fill"
        case .bus: "bus.fill"
        case .ferry: "ferry.fill"
        case .tour: "figure.hiking"
        case .restaurante: "fork.knife.circle.fill"
        case .evento: "ticket.fill"
        case .seguro: "shield.fill"
        case .otro: "bookmark.fill"
        }
    }

    /// Categoría de gasto a la que se asigna el costo de la reservación.
    var categoriaGasto: ExpenseCategory {
        switch self {
        case .vuelo: .vuelos
        case .hotel: .hospedaje
        case .auto, .tren, .bus, .ferry: .transporteLocal
        case .tour, .evento: .actividades
        case .restaurante: .comida
        case .seguro: .seguro
        case .otro: .otros
        }
    }
}

/// Categoría de una actividad del itinerario.
enum ActivityCategory: String, Codable, CaseIterable, Identifiable {
    case traslado, visita, comida, tour, aventura, playa, compras, vidaNocturna, descanso, otro

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .traslado: "Traslado"
        case .visita: "Visita / Museo"
        case .comida: "Comida"
        case .tour: "Tour"
        case .aventura: "Aventura"
        case .playa: "Playa"
        case .compras: "Compras"
        case .vidaNocturna: "Vida nocturna"
        case .descanso: "Descanso"
        case .otro: "Otro"
        }
    }

    var icono: String {
        switch self {
        case .traslado: "car.fill"
        case .visita: "building.columns.fill"
        case .comida: "fork.knife"
        case .tour: "map.fill"
        case .aventura: "figure.climbing"
        case .playa: "beach.umbrella.fill"
        case .compras: "bag.fill"
        case .vidaNocturna: "music.note"
        case .descanso: "cup.and.saucer.fill"
        case .otro: "star.fill"
        }
    }

    var categoriaGasto: ExpenseCategory {
        switch self {
        case .traslado: .transporteLocal
        case .comida, .vidaNocturna: .comida
        case .compras: .compras
        default: .actividades
        }
    }

    var color: Color {
        switch self {
        case .traslado: .teal
        case .visita: .brown
        case .comida: .orange
        case .tour: .blue
        case .aventura: .green
        case .playa: .cyan
        case .compras: .purple
        case .vidaNocturna: .indigo
        case .descanso: .gray
        case .otro: .pink
        }
    }
}

/// Tipo de viaje (para plantillas de equipaje).
enum TripType: String, Codable, CaseIterable, Identifiable {
    case ciudad, playa, montana, nieve, negocios, aventura, crucero

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .ciudad: "Ciudad"
        case .playa: "Playa"
        case .montana: "Montaña / Senderismo"
        case .nieve: "Nieve / Ski"
        case .negocios: "Negocios"
        case .aventura: "Aventura / Mochila"
        case .crucero: "Crucero"
        }
    }

    var icono: String {
        switch self {
        case .ciudad: "building.2.fill"
        case .playa: "sun.max.fill"
        case .montana: "mountain.2.fill"
        case .nieve: "snowflake"
        case .negocios: "briefcase.fill"
        case .aventura: "figure.hiking"
        case .crucero: "ferry.fill"
        }
    }
}

enum Region: String, Codable, CaseIterable, Identifiable {
    case norteamerica, centroamericaCaribe, sudamerica, europaOccidental, europaOriental,
         asiaSudeste, asiaEste, asiaSur, medioOriente, africa, oceania

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .norteamerica: "Norteamérica"
        case .centroamericaCaribe: "Centroamérica y Caribe"
        case .sudamerica: "Sudamérica"
        case .europaOccidental: "Europa Occidental"
        case .europaOriental: "Europa del Este"
        case .asiaSudeste: "Sudeste Asiático"
        case .asiaEste: "Asia del Este"
        case .asiaSur: "Asia del Sur"
        case .medioOriente: "Medio Oriente"
        case .africa: "África"
        case .oceania: "Oceanía"
        }
    }
}
