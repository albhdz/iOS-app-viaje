import Foundation
import CoreLocation
import SwiftData

/// Parámetros de entrada para estimar el costo total de un viaje.
struct EstimateInput {
    var destino: Destination?
    /// Para destinos personalizados: costo diario medio por persona (USD).
    var costoDiarioPersonalizado: DailyCosts?
    var paisDestino: String
    var origen: OriginCity?
    var latDestino: Double
    var lonDestino: Double
    var fechaInicio: Date
    var fechaFin: Date
    var viajeros: Int
    var estilo: TravelStyle
    var incluirVuelos: Bool = true
    var incluirSeguro: Bool = true
}

struct EstimateLine: Identifiable, Hashable {
    let id = UUID()
    let categoria: ExpenseCategory
    let concepto: String
    let usd: Double
    let detalle: String
}

struct Estimate {
    var lineas: [EstimateLine]
    var distanciaKm: Double
    var horasVuelo: Double
    var multiplicadorTemporada: Double
    var multiplicadorAnticipacion: Double
    var consejos: [String]

    var totalUSD: Double { lineas.reduce(0) { $0 + $1.usd } }

    func total(de categoria: ExpenseCategory) -> Double {
        lineas.filter { $0.categoria == categoria }.reduce(0) { $0 + $1.usd }
    }
}

enum CostEstimator {

    // MARK: Distancia

    static func distanciaKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let a = CLLocation(latitude: lat1, longitude: lon1)
        let b = CLLocation(latitude: lat2, longitude: lon2)
        return a.distance(from: b) / 1000
    }

    // MARK: Vuelos

    /// Precio aproximado de vuelo redondo en clase turista por persona (USD), sin ajustes.
    /// Modelo por tramos de distancia calibrado con tarifas promedio 2025-2026.
    static func vueloRedondoBaseUSD(distanciaKm d: Double) -> Double {
        switch d {
        case ..<300: return 0
        case ..<1500: return 120 + 0.12 * d
        case ..<5000: return 150 + 0.09 * d
        default: return 300 + 0.065 * d
        }
    }

    static func multiplicadorTemporada(_ fecha: Date) -> (Double, String) {
        let mes = Calendar.current.component(.month, from: fecha)
        switch mes {
        case 7, 8, 12: return (1.25, "Temporada alta")
        case 3, 4: return (1.10, "Semana Santa / Primavera")
        case 1, 6: return (1.05, "Temporada media")
        default: return (0.95, "Temporada baja")
        }
    }

    static func multiplicadorAnticipacion(_ fecha: Date) -> Double {
        let dias = Calendar.current.dateComponents([.day], from: Date(), to: fecha).day ?? 90
        switch dias {
        case ..<14: return 1.45
        case ..<30: return 1.25
        case ..<60: return 1.08
        case ..<200: return 1.0
        default: return 1.05
        }
    }

    // MARK: Requisitos de entrada (visa / autorización electrónica)

    /// Costo típico de requisitos de entrada en USD por persona. Depende del pasaporte;
    /// estos valores asumen pasaporte latinoamericano y deben verificarse.
    static func requisitoEntrada(pais: String) -> (usd: Double, nota: String) {
        let schengen = ["España", "Francia", "Italia", "Países Bajos", "Portugal", "Chequia",
                        "Hungría", "Grecia", "Islandia", "Suiza", "Alemania", "Austria", "Bélgica"]
        if schengen.contains(pais) { return (23, "ETIAS 20 € (Schengen, obligatorio desde fines de 2026)") }
        switch pais {
        case "Estados Unidos": return (185, "Visa B1/B2 185 USD (o ESTA 40 USD si tu país participa)")
        case "Canadá": return (6, "eTA 7 CAD (si tienes visa de EE. UU.) o visa 100 CAD")
        case "Reino Unido": return (21, "ETA 16 £")
        case "Australia": return (14, "ETA / eVisitor 20 AUD")
        case "Nueva Zelanda": return (75, "NZeTA + IVL turístico")
        case "Cuba": return (50, "Tarjeta de turista")
        case "Egipto": return (25, "Visa a la llegada / e-Visa")
        case "India": return (25, "e-Visa turista")
        case "Vietnam": return (25, "e-Visa")
        case "Indonesia": return (42, "Visa a la llegada + tasa turística de Bali")
        case "Corea del Sur": return (8, "K-ETA (si aplica)")
        case "Turquía": return (0, "Verifica e-Visa según tu pasaporte")
        default: return (0, "Generalmente sin visa para turismo (verifica)")
        }
    }

    // MARK: Estimación completa

    static func estimar(_ i: EstimateInput) -> Estimate {
        let noches = max(0, Calendar.current.dateComponents([.day], from: i.fechaInicio.inicioDelDia, to: i.fechaFin.inicioDelDia).day ?? 0)
        let dias = noches + 1
        let p = Double(max(1, i.viajeros))
        let n = Double(noches)
        let d = Double(dias)

        let base: DailyCosts = {
            if let destino = i.destino { return destino.costoDiario(i.estilo) }
            let c = i.costoDiarioPersonalizado ?? DailyCosts(hospedaje: 70, comida: 35, transporte: 10, actividades: 20)
            let m = i.estilo.multiplicador
            return DailyCosts(hospedaje: c.hospedaje * m, comida: c.comida * m, transporte: c.transporte * m, actividades: c.actividades * m)
        }()

        var lineas: [EstimateLine] = []
        var consejos: [String] = []
        func f(_ v: Double) -> String { v.dinero("USD") }

        // Distancia y vuelos
        var distancia: Double = 0
        var horas: Double = 0
        let (mTemp, nombreTemp) = multiplicadorTemporada(i.fechaInicio)
        let mAnt = multiplicadorAnticipacion(i.fechaInicio)
        let internacional: Bool

        if let o = i.origen {
            distancia = distanciaKm(lat1: o.latitud, lon1: o.longitud, lat2: i.latDestino, lon2: i.lonDestino)
            horas = distancia / 800 + 0.6
            internacional = o.moneda != (i.destino?.moneda ?? "") || distancia > 2500
        } else {
            internacional = true
        }

        if i.incluirVuelos, i.origen != nil {
            if distancia < 300 {
                let terrestre = distancia * 2 * 0.09 * p
                lineas.append(.init(categoria: .transporteLocal, concepto: "Transporte terrestre (ida y vuelta)",
                                    usd: terrestre, detalle: "\(Int(distancia)) km aprox. en autobús/auto"))
            } else {
                let porPersona = vueloRedondoBaseUSD(distanciaKm: distancia) * mTemp * mAnt * i.estilo.multiplicadorVuelo
                lineas.append(.init(categoria: .vuelos, concepto: "Vuelo redondo",
                                    usd: porPersona * p,
                                    detalle: "\(Int(p)) × \(f(porPersona)) · \(Int(distancia)) km · \(nombreTemp)"))
                if i.estilo == .mochilero || i.estilo == .economico || i.estilo == .medio {
                    let maleta = (distancia > 5000 ? 70.0 : 40.0) * 2
                    lineas.append(.init(categoria: .vuelos, concepto: "Equipaje documentado",
                                        usd: maleta * p,
                                        detalle: "1 maleta por persona, ida y vuelta (tarifas básicas)"))
                }
                lineas.append(.init(categoria: .vuelos, concepto: "Selección de asiento / cargos extra",
                                    usd: (i.estilo == .lujo ? 0 : 25) * p,
                                    detalle: "Promedio de cargos opcionales de aerolínea"))
                let grupos = ceil(p / 4)
                let traslado = 30 * i.estilo.multiplicador * 2 * grupos
                lineas.append(.init(categoria: .transporteLocal, concepto: "Traslados aeropuerto (destino)",
                                    usd: traslado, detalle: "Ida y vuelta, \(Int(grupos)) vehículo(s)"))
                lineas.append(.init(categoria: .transporteLocal, concepto: "Ir al aeropuerto en tu ciudad",
                                    usd: 25 * 2 * grupos, detalle: "Taxi/app o estacionamiento"))

                if mAnt > 1.1 { consejos.append("Reservar con menos de 30 días encarece el vuelo hasta un 45 %. Compra cuanto antes.") }
                if mTemp >= 1.2 { consejos.append("Viajas en temporada alta: los vuelos suben ~25 %. Mover las fechas una o dos semanas puede ahorrar mucho.") }
                consejos.append("Las tarifas más baratas suelen encontrarse entre 1 y 4 meses antes (internacional: 2–6 meses). Activa alertas de precio.")
                consejos.append("Volar martes, miércoles o sábado suele ser más barato que viernes o domingo.")
            }
        }

        // Hospedaje
        let factorSolo = (p == 1 && i.estilo != .mochilero) ? 1.7 : 1.0
        let hospedaje = base.hospedaje * n * p * factorSolo
        lineas.append(.init(categoria: .hospedaje, concepto: "Hospedaje",
                            usd: hospedaje,
                            detalle: "\(noches) noches × \(Int(p)) pers. × \(f(base.hospedaje * factorSolo))" + (factorSolo > 1 ? " (habitación individual)" : "")))
        if hospedaje > 0 {
            lineas.append(.init(categoria: .hospedaje, concepto: "Impuestos y tasas turísticas",
                                usd: hospedaje * 0.12, detalle: "≈12 % sobre hospedaje (IVA, tasa municipal, resort fees)"))
        }

        // Comida
        let comida = base.comida * d * p
        lineas.append(.init(categoria: .comida, concepto: "Comidas y bebidas",
                            usd: comida, detalle: "\(dias) días × \(Int(p)) pers. × \(f(base.comida))"))

        // Transporte local
        lineas.append(.init(categoria: .transporteLocal, concepto: "Transporte en destino",
                            usd: base.transporte * d * p,
                            detalle: "Metro, buses, apps de transporte · \(f(base.transporte))/día/pers."))

        // Actividades
        lineas.append(.init(categoria: .actividades, concepto: "Entradas, tours y actividades",
                            usd: base.actividades * d * p,
                            detalle: "\(f(base.actividades))/día/pers. · revisa los imperdibles para afinar"))

        // Propinas
        let pctPropina: Double = ["Estados Unidos", "Canadá"].contains(i.paisDestino) ? 0.18 : 0.08
        lineas.append(.init(categoria: .propinas, concepto: "Propinas",
                            usd: comida * pctPropina + (i.estilo.multiplicador * 2 * d),
                            detalle: "\(Int(pctPropina * 100)) % sobre comida + guías/maleteros"))

        // Compras
        lineas.append(.init(categoria: .compras, concepto: "Souvenirs y compras",
                            usd: 6 * i.estilo.multiplicador * d * p,
                            detalle: "Recuerdos y pequeños gastos personales"))

        // Visa
        let entrada = requisitoEntrada(pais: i.paisDestino)
        if entrada.usd > 0 {
            lineas.append(.init(categoria: .visaDocumentos, concepto: "Visa / autorización de entrada",
                                usd: entrada.usd * p, detalle: entrada.nota))
        }

        // Conectividad
        if internacional {
            let esim: Double = dias <= 7 ? 12 : (dias <= 15 ? 20 : (dias <= 30 ? 32 : 50))
            lineas.append(.init(categoria: .conectividad, concepto: "eSIM de datos",
                                usd: esim * p, detalle: "Plan de \(dias <= 7 ? "1 semana" : dias <= 15 ? "15 días" : "30 días"), 5–20 GB"))
        }

        // Salud
        let regionesVacunas: [Region] = [.asiaSur, .asiaSudeste, .africa]
        if let r = i.destino?.region, regionesVacunas.contains(r) {
            lineas.append(.init(categoria: .salud, concepto: "Vacunas recomendadas y botiquín",
                                usd: 70 * p, detalle: "Hepatitis A, tifoidea (consulta a tu médico)"))
        } else {
            lineas.append(.init(categoria: .salud, concepto: "Botiquín y medicamentos",
                                usd: 20 + 5 * p, detalle: "Analgésicos, antidiarreico, curitas, repelente"))
        }

        // Seguro (porcentaje del costo prepagado)
        if i.incluirSeguro && internacional {
            let prepagado = lineas.filter { [.vuelos, .hospedaje, .actividades].contains($0.categoria) }.reduce(0) { $0 + $1.usd }
            let seguro = max(prepagado * 0.05, d * 3.5 * p)
            lineas.append(.init(categoria: .seguro, concepto: "Seguro de viaje (médico + cancelación)",
                                usd: seguro, detalle: "≈4–8 % del costo prepagado del viaje"))
            consejos.append("Algunas tarjetas de crédito incluyen seguro de viaje si pagas el boleto con ellas. Revísalo antes de contratar.")
        }

        // Consejos por destino
        if let dest = i.destino {
            consejos.append("Mejor época para \(dest.nombre): \(dest.mejorEpoca).")
            consejos.append("Propinas en \(dest.pais): \(dest.propinas).")
        }
        consejos.append("Usa una tarjeta sin comisión por transacción en el extranjero y paga siempre en moneda local (rechaza la conversión dinámica).")

        return Estimate(lineas: lineas, distanciaKm: distancia, horasVuelo: horas,
                        multiplicadorTemporada: mTemp, multiplicadorAnticipacion: mAnt, consejos: consejos)
    }

    /// Reemplaza las líneas de presupuesto de un viaje con una nueva estimación.
    static func aplicar(_ estimate: Estimate, a trip: Trip, monedaBase: String, currency: CurrencyService, context: ModelContext) {
        for l in trip.lineasPresupuesto { context.delete(l) }
        trip.lineasPresupuesto.removeAll()
        for l in estimate.lineas {
            let linea = BudgetLine(categoria: l.categoria, concepto: l.concepto,
                                   monto: currency.desdeUSD(l.usd, a: monedaBase), detalle: l.detalle)
            trip.lineasPresupuesto.append(linea)
        }
    }
}
