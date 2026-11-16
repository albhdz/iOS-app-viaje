import SwiftUI
import SwiftData

struct BookingsView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: Trip
    @State private var nuevo = false
    @State private var editando: Booking?

    private var ordenadas: [Booking] { trip.reservas.sorted { $0.fechaInicio < $1.fechaInicio } }
    private var pendientesPago: Double { trip.reservas.filter { !$0.pagado }.reduce(0) { $0 + $1.costo } }

    var body: some View {
        List {
            Section {
                HStack {
                    StatCard(titulo: "Total reservado", valor: trip.totalReservado.dinero(trip.monedaBase), icono: "ticket", color: .orange)
                    StatCard(titulo: "Por pagar", valor: pendientesPago.dinero(trip.monedaBase), icono: "clock", color: pendientesPago > 0 ? .red : .green)
                }
            }
            if ordenadas.isEmpty {
                ContentUnavailableView("Sin reservaciones", systemImage: "ticket",
                                       description: Text("Guarda vuelos, hoteles, autos, tours y entradas con su código de confirmación y costo."))
            }
            ForEach(ordenadas) { r in
                Button { editando = r } label: { BookingRow(reserva: r, moneda: trip.monedaBase) }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading) {
                        Button { r.pagado.toggle() } label: {
                            Label(r.pagado ? "No pagado" : "Pagado", systemImage: "checkmark")
                        }.tint(.green)
                    }
            }
            .onDelete { idx in for i in idx { context.delete(ordenadas[i]) } }
        }
        .navigationTitle("Reservaciones")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { nuevo = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $nuevo) { BookingEditor(trip: trip, reserva: nil) }
        .sheet(item: $editando) { BookingEditor(trip: trip, reserva: $0) }
    }
}

struct BookingRow: View {
    let reserva: Booking
    let moneda: String

    var body: some View {
        HStack(spacing: 12) {
            IconoCategoria(icono: reserva.tipo.icono, color: reserva.tipo.categoriaGasto.color, tamano: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(reserva.titulo).font(.headline)
                if !reserva.desde.isEmpty || !reserva.hacia.isEmpty {
                    Text("\(reserva.desde) → \(reserva.hacia)").font(.caption)
                }
                Text(reserva.fechaInicio.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                if !reserva.codigoConfirmacion.isEmpty {
                    Text("Código: \(reserva.codigoConfirmacion)")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(reserva.costo.dinero(moneda)).monospacedDigit()
                Text(reserva.pagado ? "Pagado" : "Pendiente")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background((reserva.pagado ? Color.green : Color.orange).opacity(0.2), in: Capsule())
            }
        }
        .contentShape(Rectangle())
    }
}

struct BookingEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var trip: Trip
    var reserva: Booking?

    @State private var tipo: BookingType = .vuelo
    @State private var titulo = ""
    @State private var proveedor = ""
    @State private var codigo = ""
    @State private var desde = ""
    @State private var hacia = ""
    @State private var inicio = Date()
    @State private var tieneFin = false
    @State private var fin = Date()
    @State private var costo: Double = 0
    @State private var pagado = false
    @State private var registrarGasto = true
    @State private var tieneCancelacion = false
    @State private var cancelacion = Date()
    @State private var enlace = ""
    @State private var notas = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Tipo", selection: $tipo) {
                        ForEach(BookingType.allCases) { Label($0.nombre, systemImage: $0.icono).tag($0) }
                    }
                    TextField("Título (ej. Aeroméxico AM 1)", text: $titulo)
                    TextField("Proveedor / aerolínea / hotel", text: $proveedor)
                    TextField("Código de confirmación", text: $codigo)
                        .textInputAutocapitalization(.characters)
                }
                if [.vuelo, .tren, .bus, .ferry, .auto].contains(tipo) {
                    Section("Ruta") {
                        TextField("Desde", text: $desde)
                        TextField("Hacia", text: $hacia)
                    }
                }
                Section("Fechas") {
                    DatePicker(tipo == .hotel ? "Check-in" : "Inicio", selection: $inicio)
                    Toggle(tipo == .hotel ? "Check-out" : "Tiene fecha de fin", isOn: $tieneFin)
                    if tieneFin { DatePicker("Fin", selection: $fin, in: inicio...) }
                    Toggle("Cancelación gratuita", isOn: $tieneCancelacion)
                    if tieneCancelacion { DatePicker("Hasta", selection: $cancelacion, displayedComponents: .date) }
                }
                Section {
                    CampoMonto(titulo: "Costo total", monto: $costo, moneda: trip.monedaBase)
                    Toggle("Pagado", isOn: $pagado)
                    if pagado && reserva?.pagado != true {
                        Toggle("Registrar también como gasto", isOn: $registrarGasto)
                    }
                } header: {
                    Text("Costo")
                }
                Section("Más") {
                    TextField("Enlace (URL)", text: $enlace)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                    if let url = URL(string: enlace), !enlace.isEmpty {
                        Link("Abrir enlace", destination: url)
                    }
                    TextField("Notas", text: $notas, axis: .vertical)
                }
            }
            .navigationTitle(reserva == nil ? "Nueva reservación" : "Reservación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }.disabled(titulo.isEmpty)
                }
            }
            .onAppear(perform: cargar)
        }
    }

    private func cargar() {
        guard let r = reserva else {
            inicio = trip.fechaInicio
            fin = trip.fechaFin
            return
        }
        tipo = r.tipo; titulo = r.titulo; proveedor = r.proveedor; codigo = r.codigoConfirmacion
        desde = r.desde; hacia = r.hacia; inicio = r.fechaInicio
        tieneFin = r.fechaFin != nil; fin = r.fechaFin ?? r.fechaInicio
        costo = r.costo; pagado = r.pagado
        tieneCancelacion = r.cancelacionGratisHasta != nil; cancelacion = r.cancelacionGratisHasta ?? Date()
        enlace = r.enlace; notas = r.notas
    }

    private func guardar() {
        let estabaPagado = reserva?.pagado ?? false
        let r = reserva ?? Booking(tipo: tipo, titulo: titulo, fechaInicio: inicio)
        r.tipo = tipo; r.titulo = titulo; r.proveedor = proveedor; r.codigoConfirmacion = codigo
        r.desde = desde; r.hacia = hacia; r.fechaInicio = inicio
        r.fechaFin = tieneFin ? fin : nil
        r.costo = costo; r.pagado = pagado
        r.cancelacionGratisHasta = tieneCancelacion ? cancelacion : nil
        r.enlace = enlace; r.notas = notas
        if reserva == nil { trip.reservas.append(r) }

        if pagado && !estabaPagado && registrarGasto && costo > 0 {
            let g = Expense(titulo: titulo, monto: costo, moneda: trip.monedaBase, tasaABase: 1,
                            categoria: tipo.categoriaGasto, fecha: Date())
            g.pagadoPorID = trip.participantes.first?.id
            g.compartidoEntreIDs = trip.participantes.map(\.id)
            g.notas = "Reservación \(codigo)"
            trip.gastos.append(g)
        }
        dismiss()
    }
}
