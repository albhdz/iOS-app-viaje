import Foundation

/// Plantillas de equipaje y checklist, basadas en las listas más recomendadas
/// por guías de viaje (documentos primero, regla de 5-4-3-2-1 para ropa, etc.).
enum Templates {

    static func equipaje(tipo: TripType, dias: Int, internacional: Bool) -> [(String, String, Int)] {
        var items: [(String, String, Int)] = []
        func add(_ n: String, _ g: String, _ c: Int = 1) { items.append((n, g, c)) }
        let mudas = min(max(dias, 1), 7)

        // Documentos
        if internacional { add("Pasaporte (vigencia ≥ 6 meses)", "📄 Documentos") }
        add("Identificación oficial", "📄 Documentos")
        if internacional { add("Visa / ETA / ETIAS impresa", "📄 Documentos") }
        add("Pases de abordar (app + PDF)", "📄 Documentos")
        add("Confirmaciones de hotel", "📄 Documentos")
        add("Póliza de seguro de viaje", "📄 Documentos")
        add("Licencia de conducir", "📄 Documentos")
        add("Copias digitales de documentos", "📄 Documentos")

        // Dinero
        add("Tarjeta de crédito sin comisión extranjera", "💳 Dinero")
        add("Tarjeta de débito de respaldo", "💳 Dinero")
        add("Efectivo en moneda local", "💳 Dinero")

        // Electrónica
        add("Teléfono", "🔌 Electrónica")
        add("Cargador y cable", "🔌 Electrónica")
        add("Batería externa (power bank)", "🔌 Electrónica")
        if internacional { add("Adaptador de enchufe universal", "🔌 Electrónica") }
        add("Audífonos", "🔌 Electrónica")
        add("eSIM instalada / roaming activado", "🔌 Electrónica")

        // Ropa (regla 5-4-3-2-1 adaptada)
        add("Ropa interior", "👕 Ropa", mudas + 1)
        add("Calcetines", "👕 Ropa", mudas + 1)
        add("Camisetas / blusas", "👕 Ropa", max(2, mudas - 1))
        add("Pantalones / shorts", "👕 Ropa", max(2, mudas / 2))
        add("Pijama", "👕 Ropa")
        add("Zapatos cómodos para caminar", "👕 Ropa")
        add("Chamarra ligera", "👕 Ropa")

        // Higiene
        add("Cepillo y pasta de dientes", "🧴 Higiene")
        add("Desodorante", "🧴 Higiene")
        add("Shampoo (≤100 ml en mano)", "🧴 Higiene")
        add("Protector solar", "🧴 Higiene")
        add("Medicamentos personales", "🧴 Higiene")
        add("Botiquín básico", "🧴 Higiene")

        // Para el vuelo
        add("Almohada de viaje", "✈️ Para el vuelo")
        add("Botella de agua reutilizable (vacía)", "✈️ Para el vuelo")
        add("Snacks", "✈️ Para el vuelo")

        switch tipo {
        case .playa:
            add("Traje de baño", "🏖️ Playa", 2)
            add("Sandalias", "🏖️ Playa")
            add("Lentes de sol", "🏖️ Playa")
            add("Sombrero / gorra", "🏖️ Playa")
            add("Bloqueador biodegradable", "🏖️ Playa")
            add("Toalla de microfibra", "🏖️ Playa")
            add("Funda impermeable para celular", "🏖️ Playa")
            add("Repelente de insectos", "🏖️ Playa")
        case .montana, .aventura:
            add("Botas de senderismo", "🥾 Aventura")
            add("Mochila de día", "🥾 Aventura")
            add("Impermeable", "🥾 Aventura")
            add("Capas térmicas", "🥾 Aventura", 2)
            add("Lámpara frontal", "🥾 Aventura")
            add("Navaja multiusos (documentada)", "🥾 Aventura")
            add("Pastillas potabilizadoras", "🥾 Aventura")
            add("Repelente de insectos", "🥾 Aventura")
        case .nieve:
            add("Chamarra para nieve", "❄️ Nieve")
            add("Pantalón impermeable", "❄️ Nieve")
            add("Primera capa térmica", "❄️ Nieve", 2)
            add("Guantes", "❄️ Nieve")
            add("Gorro y bufanda", "❄️ Nieve")
            add("Goggles", "❄️ Nieve")
            add("Calcetines de lana", "❄️ Nieve", 3)
            add("Bálsamo labial", "❄️ Nieve")
        case .negocios:
            add("Traje / ropa formal", "💼 Negocios", 2)
            add("Zapatos formales", "💼 Negocios")
            add("Laptop y cargador", "💼 Negocios")
            add("Tarjetas de presentación", "💼 Negocios")
            add("Presentación en USB / nube", "💼 Negocios")
        case .crucero:
            add("Ropa formal para cena de gala", "🚢 Crucero")
            add("Pastillas para el mareo", "🚢 Crucero")
            add("Traje de baño", "🚢 Crucero", 2)
            add("Lanyard para tarjeta de cabina", "🚢 Crucero")
        case .ciudad:
            add("Mochila / bolso antirrobo", "🏙️ Ciudad")
            add("Paraguas plegable", "🏙️ Ciudad")
            add("Atuendo para salir de noche", "🏙️ Ciudad")
        }
        return items
    }

    /// Checklist de preparación con días de anticipación recomendados.
    static func checklist(internacional: Bool, conVuelo: Bool) -> [(titulo: String, seccion: String, diasAntes: Int, nota: String)] {
        var c: [(String, String, Int, String)] = []
        func add(_ t: String, _ s: String, _ d: Int, _ n: String = "") { c.append((t, s, d, n)) }

        // 3+ meses antes
        if internacional {
            add("Revisar vigencia del pasaporte (≥6 meses)", "3 meses antes", 90, "Trámite en México: 1–3 semanas para cita")
            add("Revisar requisitos de visa / ETA", "3 meses antes", 90, "Algunas visas tardan meses en tener cita")
            add("Consultar vacunas recomendadas", "3 meses antes", 60, "Algunas requieren varias dosis")
        }
        add("Definir presupuesto y meta de ahorro", "3 meses antes", 90)
        if conVuelo { add("Comprar vuelos (activar alertas de precio)", "3 meses antes", 75) }
        add("Reservar hospedaje con cancelación gratuita", "3 meses antes", 70)
        add("Pedir vacaciones en el trabajo", "3 meses antes", 90)

        // 1 mes antes
        add("Contratar seguro de viaje", "1 mes antes", 30)
        add("Reservar tours y entradas que se agotan", "1 mes antes", 30, "Ej. Machu Picchu, Sagrada Familia, Alhambra")
        add("Reservar renta de auto", "1 mes antes", 30)
        if internacional { add("Licencia internacional de conducir (si rentas auto)", "1 mes antes", 30) }
        add("Planear itinerario día por día", "1 mes antes", 25)
        add("Revisar tarjetas: sin comisión y con viaje notificado", "1 mes antes", 21)

        // 1 semana antes
        if internacional { add("Comprar e instalar eSIM", "1 semana antes", 7) }
        add("Descargar mapas offline", "1 semana antes", 5)
        add("Revisar pronóstico del clima", "1 semana antes", 5)
        add("Cambiar algo de efectivo a moneda local", "1 semana antes", 5)
        add("Hacer el equipaje con la lista", "1 semana antes", 3)
        add("Organizar cuidado de mascotas / plantas", "1 semana antes", 7)
        add("Compartir itinerario con familiar de confianza", "1 semana antes", 3)
        if internacional { add("Registrarse en programa consular de tu país", "1 semana antes", 7, "Ej. SIRME (México)") }

        // Último día
        if conVuelo { add("Check-in en línea (24–48 h antes)", "Día anterior", 1) }
        add("Cargar teléfono, batería externa y audífonos", "Día anterior", 1)
        add("Pesar maletas", "Día anterior", 1, "Turista: 23 kg documentada / 10 kg mano (varía por aerolínea)")
        add("Apagar gas, desconectar aparatos, sacar basura", "Día de salida", 0)
        if conVuelo { add("Llegar al aeropuerto con anticipación", "Día de salida", 0, "Nacional 2 h · Internacional 3 h") }
        return c.map { (titulo: $0.0, seccion: $0.1, diasAntes: $0.2, nota: $0.3) }
    }

    static let ordenSecciones = ["3 meses antes", "1 mes antes", "1 semana antes", "Día anterior", "Día de salida", "General"]
}
