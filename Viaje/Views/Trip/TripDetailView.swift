import SwiftUI
import SwiftData

struct TripDetailView: View {
    @Bindable var trip: Trip
    @State private var editar = false

    var body: some View {
        List {
            Section { encabezado }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            Section("Planeación") {
                enlace("Presupuesto", icono: "chart.pie.fill", color: .green,
                       detalle: "\(trip.totalGastado.dinero(trip.monedaBase)) de \(trip.presupuesto.dinero(trip.monedaBase))") {
                    BudgetView(trip: trip)
                }
                enlace("Itinerario", icono: "calendar", color: .blue,
                       detalle: "\(trip.itinerario.count) actividades · \(trip.totalItinerario.dinero(trip.monedaBase))") {
                    ItineraryView(trip: trip)
                }
                enlace("Reservaciones", icono: "ticket.fill", color: .orange,
                       detalle: "\(trip.reservas.count) · \(trip.totalReservado.dinero(trip.monedaBase))") {
                    BookingsView(trip: trip)
                }
                enlace("Mapa", icono: "map.fill", color: .teal, detalle: trip.destinoNombre) {
                    TripMapView(trip: trip)
                }
            }

            Section("Durante el viaje") {
                enlace("Gastos", icono: "creditcard.fill", color: .pink,
                       detalle: "\(trip.gastos.count) registrados") {
                    ExpensesView(trip: trip)
                }
                enlace("Dividir cuentas", icono: "person.3.fill", color: .purple,
                       detalle: "\(trip.participantes.count) participantes") {
                    SplitView(trip: trip)
                }
            }

            Section("Preparación") {
                enlace("Checklist", icono: "checklist", color: .indigo,
                       detalle: "\(Int(trip.progresoChecklist * 100)) % completado") {
                    ChecklistView(trip: trip)
                }
                enlace("Equipaje", icono: "suitcase.fill", color: .brown,
                       detalle: "\(trip.equipaje.filter(\.empacado).count)/\(trip.equipaje.count) empacado") {
                    PackingView(trip: trip)
                }
                if let d = trip.destino {
                    enlace("Guía del destino", icono: "info.circle.fill", color: .cyan, detalle: d.pais) {
                        DestinationDetailView(destino: d, desdeViaje: true)
                    }
                }
            }

            Section("Notas") {
                TextField("Ideas, direcciones, contactos…", text: $trip.notas, axis: .vertical)
                    .lineLimit(3...10)
            }
        }
        .navigationTitle(trip.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Editar") { editar = true }
            }
        }
        .sheet(isPresented: $editar) { EditTripView(trip: trip) }
    }

    private var encabezado: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(trip.emoji) \(trip.destinoNombre)")
                        .font(.title2.bold())
                    Text("\(trip.fechaInicio.corta) – \(trip.fechaFin.corta) · \(trip.dias) días")
                        .foregroundStyle(.secondary)
                    Text("\(trip.numeroViajeros) viajero(s) · \(trip.estilo.nombre)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                cuentaRegresiva
            }
            HStack(spacing: 10) {
                StatCard(titulo: "Presupuesto", valor: trip.presupuesto.dinero(trip.monedaBase), icono: "banknote", color: .green)
                StatCard(titulo: "Por persona", valor: trip.costoPorPersona.dinero(trip.monedaBase), icono: "person.fill", color: .blue)
            }
            HStack(spacing: 10) {
                StatCard(titulo: "Gastado", valor: trip.totalGastado.dinero(trip.monedaBase), icono: "creditcard", color: .pink)
                StatCard(titulo: trip.restante >= 0 ? "Disponible" : "Excedido",
                         valor: abs(trip.restante).dinero(trip.monedaBase),
                         icono: trip.restante >= 0 ? "checkmark.seal" : "exclamationmark.triangle",
                         color: trip.restante >= 0 ? .mint : .red)
            }
            if trip.estado == .proximo && trip.faltaPorAhorrar > 0 {
                HStack {
                    Image(systemName: "piggybank.fill").foregroundStyle(.pink)
                    Text("Ahorra \(trip.ahorroMensualNecesario.dinero(trip.monedaBase)) al mes para llegar a tu meta")
                        .font(.footnote)
                    Spacer()
                }
                .padding(10)
                .background(Color.pink.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }

    @ViewBuilder private var cuentaRegresiva: some View {
        if trip.estado == .proximo {
            VStack(spacing: 0) {
                Text("\(trip.diasRestantes)").font(.system(size: 28, weight: .heavy, design: .rounded))
                Text("días").font(.caption2)
            }
            .frame(width: 64, height: 64)
            .background(Color.accentColor.opacity(0.15), in: Circle())
        } else if trip.estado == .enCurso {
            Label("En curso", systemImage: "location.fill").font(.caption.bold())
                .padding(8).background(Color.green.opacity(0.2), in: Capsule())
        }
    }

    private func enlace<D: View>(_ titulo: String, icono: String, color: Color, detalle: String,
                                 @ViewBuilder destino: @escaping () -> D) -> some View {
        NavigationLink {
            destino()
        } label: {
            HStack(spacing: 12) {
                IconoCategoria(icono: icono, color: color)
                VStack(alignment: .leading) {
                    Text(titulo)
                    Text(detalle).font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
            }
        }
    }
}

/// Edición de datos generales del viaje y participantes.
struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(CurrencyService.self) private var currency
    @Bindable var trip: Trip
    @State private var nuevoParticipante = ""
    @State private var confirmarRecalculo = false

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Nombre", text: $trip.nombre)
                    TextField("Emoji", text: $trip.emoji)
                    DatePicker("Ida", selection: $trip.fechaInicio, displayedComponents: .date)
                    DatePicker("Regreso", selection: $trip.fechaFin, in: trip.fechaInicio..., displayedComponents: .date)
                    Stepper("\(trip.numeroViajeros) viajero(s)", value: $trip.numeroViajeros, in: 1...20)
                    Picker("Estilo", selection: $trip.estilo) {
                        ForEach(TravelStyle.allCases) { Text($0.nombre).tag($0) }
                    }
                    Picker("Tipo", selection: $trip.tipo) {
                        ForEach(TripType.allCases) { Text($0.nombre).tag($0) }
                    }
                }
                Section("Monedas") {
                    SelectorMoneda(titulo: "Moneda local", moneda: $trip.monedaLocal)
                    LabeledContent("Moneda del presupuesto", value: trip.monedaBase)
                }
                Section {
                    ForEach(trip.participantes) { p in
                        Text(p.nombre)
                    }
                    .onDelete { idx in
                        for i in idx { context.delete(trip.participantes[i]) }
                    }
                    HStack {
                        TextField("Agregar participante", text: $nuevoParticipante)
                        Button("Agregar") {
                            trip.participantes.append(Traveler(nombre: nuevoParticipante))
                            nuevoParticipante = ""
                        }
                        .disabled(nuevoParticipante.isEmpty)
                    }
                } header: {
                    Text("Participantes")
                } footer: {
                    Text("Se usan para registrar quién pagó y dividir gastos.")
                }
                Section {
                    Button("Recalcular presupuesto estimado") { confirmarRecalculo = true }
                } footer: {
                    Text("Vuelve a estimar todas las partidas con las fechas, viajeros y estilo actuales. Tus gastos reales no se modifican.")
                }
            }
            .navigationTitle("Editar viaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        NotificationService.programar(para: trip)
                        dismiss()
                    }
                }
            }
            .confirmationDialog("¿Reemplazar el presupuesto estimado?", isPresented: $confirmarRecalculo, titleVisibility: .visible) {
                Button("Recalcular", role: .destructive) { recalcular() }
            }
        }
    }

    private func recalcular() {
        let origen = DestinationCatalog.origenes.first { $0.nombre == trip.origenNombre }
        let input = EstimateInput(destino: trip.destino, costoDiarioPersonalizado: nil,
                                  paisDestino: trip.destinoPais, origen: origen,
                                  latDestino: trip.latitud, lonDestino: trip.longitud,
                                  fechaInicio: trip.fechaInicio, fechaFin: trip.fechaFin,
                                  viajeros: trip.numeroViajeros, estilo: trip.estilo,
                                  incluirVuelos: origen != nil, incluirSeguro: true)
        CostEstimator.aplicar(CostEstimator.estimar(input), a: trip, monedaBase: trip.monedaBase,
                              currency: currency, context: context)
    }
}
