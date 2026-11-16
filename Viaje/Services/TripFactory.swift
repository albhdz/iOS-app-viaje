import Foundation
import SwiftData

/// Crea un viaje completo: presupuesto estimado, equipaje, checklist y participantes.
enum TripFactory {

    struct Datos {
        var nombre: String
        var destino: Destination?
        var destinoNombre: String
        var destinoPais: String
        var latitud: Double
        var longitud: Double
        var monedaLocal: String
        var costoPersonalizado: DailyCosts?
        var origen: OriginCity?
        var fechaInicio: Date
        var fechaFin: Date
        var viajeros: Int
        var nombresViajeros: [String]
        var estilo: TravelStyle
        var tipo: TripType
        var monedaBase: String
        var incluirVuelos: Bool
        var incluirSeguro: Bool
    }

    static func input(_ d: Datos) -> EstimateInput {
        EstimateInput(destino: d.destino, costoDiarioPersonalizado: d.costoPersonalizado,
                      paisDestino: d.destinoPais, origen: d.origen,
                      latDestino: d.latitud, lonDestino: d.longitud,
                      fechaInicio: d.fechaInicio, fechaFin: d.fechaFin,
                      viajeros: d.viajeros, estilo: d.estilo,
                      incluirVuelos: d.incluirVuelos, incluirSeguro: d.incluirSeguro)
    }

    @discardableResult
    static func crear(_ d: Datos, context: ModelContext, currency: CurrencyService) -> Trip {
        let trip = Trip(nombre: d.nombre, destinoNombre: d.destinoNombre, destinoPais: d.destinoPais,
                        fechaInicio: d.fechaInicio, fechaFin: d.fechaFin)
        trip.destinoID = d.destino?.id
        trip.emoji = d.destino?.emoji ?? "✈️"
        trip.latitud = d.latitud
        trip.longitud = d.longitud
        trip.monedaLocal = d.monedaLocal
        trip.origenNombre = d.origen?.nombre ?? ""
        trip.origenLatitud = d.origen?.latitud ?? 0
        trip.origenLongitud = d.origen?.longitud ?? 0
        trip.numeroViajeros = d.viajeros
        trip.estilo = d.estilo
        trip.tipo = d.tipo
        trip.monedaBase = d.monedaBase
        context.insert(trip)

        // Presupuesto
        let estimate = CostEstimator.estimar(input(d))
        CostEstimator.aplicar(estimate, a: trip, monedaBase: d.monedaBase, currency: currency, context: context)

        // Participantes
        for i in 0..<max(1, d.viajeros) {
            let nombre = i < d.nombresViajeros.count && !d.nombresViajeros[i].isEmpty
                ? d.nombresViajeros[i]
                : (i == 0 ? "Yo" : "Viajero \(i + 1)")
            trip.participantes.append(Traveler(nombre: nombre))
        }

        // Equipaje
        let internacional = d.monedaLocal != d.monedaBase
        for (nombre, grupo, cantidad) in Templates.equipaje(tipo: d.tipo, dias: trip.dias, internacional: internacional) {
            trip.equipaje.append(PackingItem(nombre: nombre, grupo: grupo, cantidad: cantidad))
        }

        // Checklist
        for c in Templates.checklist(internacional: internacional, conVuelo: d.incluirVuelos) {
            trip.checklist.append(ChecklistItem(titulo: c.titulo, seccion: c.seccion, diasAntes: c.diasAntes, nota: c.nota))
        }

        // Itinerario base: llegada y regreso
        let cal = Calendar.current
        if d.incluirVuelos {
            let llegada = ItineraryItem(dia: trip.fechaInicio.inicioDelDia,
                                        hora: cal.date(bySettingHour: 10, minute: 0, second: 0, of: trip.fechaInicio) ?? trip.fechaInicio,
                                        titulo: "Llegada a \(d.destinoNombre)", categoria: .traslado)
            llegada.notas = "Traslado del aeropuerto al hospedaje"
            trip.itinerario.append(llegada)
            if trip.dias > 1 {
                let regreso = ItineraryItem(dia: trip.fechaFin.inicioDelDia,
                                            hora: cal.date(bySettingHour: 12, minute: 0, second: 0, of: trip.fechaFin) ?? trip.fechaFin,
                                            titulo: "Check-out y regreso", categoria: .traslado)
                trip.itinerario.append(regreso)
            }
        }

        try? context.save()
        NotificationService.programar(para: trip)
        return trip
    }
}
