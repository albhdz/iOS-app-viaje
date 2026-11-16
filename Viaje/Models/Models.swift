import Foundation
import SwiftData

// MARK: - Viaje

@Model
final class Trip {
    var id: UUID = UUID()
    var nombre: String = ""
    var emoji: String = "✈️"

    // Destino
    var destinoID: String?
    var destinoNombre: String = ""
    var destinoPais: String = ""
    var latitud: Double = 0
    var longitud: Double = 0
    var monedaLocal: String = "USD"

    // Origen
    var origenNombre: String = ""
    var origenLatitud: Double = 0
    var origenLongitud: Double = 0

    // Fechas y viajeros
    var fechaInicio: Date = Date()
    var fechaFin: Date = Date()
    var numeroViajeros: Int = 1
    var estilo: TravelStyle = TravelStyle.medio
    var tipo: TripType = TripType.ciudad

    // Dinero
    var monedaBase: String = "MXN"
    /// Presupuesto objetivo definido por el usuario (en moneda base). 0 = usar el estimado.
    var presupuestoObjetivo: Double = 0
    /// Lo que el usuario ya lleva ahorrado para el viaje (en moneda base).
    var ahorrado: Double = 0
    /// Porcentaje de colchón para imprevistos.
    var colchonPorcentaje: Double = 10

    var notas: String = ""
    var creado: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \BudgetLine.trip) var lineasPresupuesto: [BudgetLine] = []
    @Relationship(deleteRule: .cascade, inverse: \ItineraryItem.trip) var itinerario: [ItineraryItem] = []
    @Relationship(deleteRule: .cascade, inverse: \Expense.trip) var gastos: [Expense] = []
    @Relationship(deleteRule: .cascade, inverse: \Booking.trip) var reservas: [Booking] = []
    @Relationship(deleteRule: .cascade, inverse: \PackingItem.trip) var equipaje: [PackingItem] = []
    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.trip) var checklist: [ChecklistItem] = []
    @Relationship(deleteRule: .cascade, inverse: \Traveler.trip) var participantes: [Traveler] = []

    init(nombre: String, destinoNombre: String, destinoPais: String, fechaInicio: Date, fechaFin: Date) {
        self.nombre = nombre
        self.destinoNombre = destinoNombre
        self.destinoPais = destinoPais
        self.fechaInicio = fechaInicio
        self.fechaFin = fechaFin
    }

    // MARK: Derivados

    var noches: Int {
        max(0, Calendar.current.dateComponents([.day], from: fechaInicio.inicioDelDia, to: fechaFin.inicioDelDia).day ?? 0)
    }

    var dias: Int { noches + 1 }

    var diasRestantes: Int {
        Calendar.current.dateComponents([.day], from: Date().inicioDelDia, to: fechaInicio.inicioDelDia).day ?? 0
    }

    var estado: EstadoViaje {
        let hoy = Date().inicioDelDia
        if hoy < fechaInicio.inicioDelDia { return .proximo }
        if hoy > fechaFin.inicioDelDia { return .terminado }
        return .enCurso
    }

    /// Lista de días del viaje.
    var listaDias: [Date] {
        (0..<dias).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: fechaInicio.inicioDelDia) }
    }

    /// Suma de las líneas estimadas (sin colchón).
    var totalEstimado: Double {
        lineasPresupuesto.reduce(0) { $0 + $1.monto }
    }

    var colchon: Double { totalEstimado * colchonPorcentaje / 100 }

    /// Presupuesto con el que se trabaja: objetivo manual o estimado + colchón.
    var presupuesto: Double {
        presupuestoObjetivo > 0 ? presupuestoObjetivo : totalEstimado + colchon
    }

    var restante: Double { presupuesto - totalGastado }

    var costoPorPersona: Double { presupuesto / Double(max(1, numeroViajeros)) }

    var costoPorDia: Double { presupuesto / Double(max(1, dias)) }

    var destino: Destination? { DestinationCatalog.destino(id: destinoID) }

    var esInternacional: Bool { monedaLocal != monedaBase }

    var totalGastado: Double {
        gastos.reduce(0) { $0 + $1.montoBase }
    }

    /// Reservas no registradas aún como gasto pero comprometidas.
    var totalReservado: Double {
        reservas.reduce(0) { $0 + $1.costo }
    }

    var totalItinerario: Double {
        itinerario.reduce(0) { $0 + $1.costoEstimado }
    }

    func estimado(de categoria: ExpenseCategory) -> Double {
        lineasPresupuesto.filter { $0.categoria == categoria }.reduce(0) { $0 + $1.monto }
    }

    func gastado(en categoria: ExpenseCategory) -> Double {
        gastos.filter { $0.categoria == categoria }.reduce(0) { $0 + $1.montoBase }
    }

    var faltaPorAhorrar: Double { max(0, presupuesto - ahorrado) }

    /// Ahorro mensual necesario para llegar a la meta antes de la fecha de salida.
    var ahorroMensualNecesario: Double {
        let meses = max(1, Double(max(diasRestantes, 0)) / 30.4)
        return faltaPorAhorrar / meses
    }

    var progresoEquipaje: Double {
        guard !equipaje.isEmpty else { return 0 }
        return Double(equipaje.filter(\.empacado).count) / Double(equipaje.count)
    }

    var progresoChecklist: Double {
        guard !checklist.isEmpty else { return 0 }
        return Double(checklist.filter(\.hecho).count) / Double(checklist.count)
    }
}

enum EstadoViaje {
    case proximo, enCurso, terminado

    var nombre: String {
        switch self {
        case .proximo: "Próximo"
        case .enCurso: "En curso"
        case .terminado: "Terminado"
        }
    }
}

// MARK: - Línea de presupuesto estimado

@Model
final class BudgetLine {
    var id: UUID = UUID()
    var categoria: ExpenseCategory = ExpenseCategory.otros
    var concepto: String = ""
    /// Monto en moneda base del viaje.
    var monto: Double = 0
    var detalle: String = ""
    var trip: Trip?

    init(categoria: ExpenseCategory, concepto: String, monto: Double, detalle: String = "") {
        self.categoria = categoria
        self.concepto = concepto
        self.monto = monto
        self.detalle = detalle
    }
}

// MARK: - Itinerario

@Model
final class ItineraryItem {
    var id: UUID = UUID()
    var dia: Date = Date()
    var hora: Date = Date()
    var titulo: String = ""
    var categoria: ActivityCategory = ActivityCategory.visita
    var ubicacion: String = ""
    var latitud: Double?
    var longitud: Double?
    var duracionMinutos: Int = 60
    /// Costo estimado total (todos los viajeros) en moneda base.
    var costoEstimado: Double = 0
    var notas: String = ""
    var completado: Bool = false
    var trip: Trip?

    init(dia: Date, hora: Date, titulo: String, categoria: ActivityCategory) {
        self.dia = dia
        self.hora = hora
        self.titulo = titulo
        self.categoria = categoria
    }
}

// MARK: - Gastos reales

@Model
final class Expense {
    var id: UUID = UUID()
    var titulo: String = ""
    var monto: Double = 0
    var moneda: String = "USD"
    /// Tasa de conversión a la moneda base al momento de registrar.
    var tasaABase: Double = 1
    var categoria: ExpenseCategory = ExpenseCategory.otros
    var fecha: Date = Date()
    var pagadoPorID: UUID?
    var compartidoEntreIDs: [UUID] = []
    var notas: String = ""
    var trip: Trip?

    init(titulo: String, monto: Double, moneda: String, tasaABase: Double, categoria: ExpenseCategory, fecha: Date = Date()) {
        self.titulo = titulo
        self.monto = monto
        self.moneda = moneda
        self.tasaABase = tasaABase
        self.categoria = categoria
        self.fecha = fecha
    }

    var montoBase: Double { monto * tasaABase }
}

// MARK: - Reservaciones

@Model
final class Booking {
    var id: UUID = UUID()
    var tipo: BookingType = BookingType.otro
    var titulo: String = ""
    var proveedor: String = ""
    var codigoConfirmacion: String = ""
    var desde: String = ""
    var hacia: String = ""
    var fechaInicio: Date = Date()
    var fechaFin: Date?
    /// Costo en moneda base.
    var costo: Double = 0
    var pagado: Bool = false
    var cancelacionGratisHasta: Date?
    var enlace: String = ""
    var notas: String = ""
    var trip: Trip?

    init(tipo: BookingType, titulo: String, fechaInicio: Date) {
        self.tipo = tipo
        self.titulo = titulo
        self.fechaInicio = fechaInicio
    }
}

// MARK: - Equipaje

@Model
final class PackingItem {
    var id: UUID = UUID()
    var nombre: String = ""
    var grupo: String = "General"
    var cantidad: Int = 1
    var empacado: Bool = false
    var trip: Trip?

    init(nombre: String, grupo: String, cantidad: Int = 1) {
        self.nombre = nombre
        self.grupo = grupo
        self.cantidad = cantidad
    }
}

// MARK: - Checklist previo al viaje

@Model
final class ChecklistItem {
    var id: UUID = UUID()
    var titulo: String = ""
    var seccion: String = "General"
    var diasAntes: Int = 0
    var hecho: Bool = false
    var nota: String = ""
    var trip: Trip?

    init(titulo: String, seccion: String, diasAntes: Int, nota: String = "") {
        self.titulo = titulo
        self.seccion = seccion
        self.diasAntes = diasAntes
        self.nota = nota
    }
}

// MARK: - Participantes (para dividir gastos)

@Model
final class Traveler {
    var id: UUID = UUID()
    var nombre: String = ""
    var trip: Trip?

    init(nombre: String) {
        self.nombre = nombre
    }
}

// MARK: - Utilidades

extension Date {
    var inicioDelDia: Date { Calendar.current.startOfDay(for: self) }
}
