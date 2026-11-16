import SwiftUI
import SwiftData

struct TripsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trip.fechaInicio) private var trips: [Trip]
    @State private var mostrarNuevo = false
    @State private var porBorrar: Trip?

    private var proximos: [Trip] { trips.filter { $0.estado != .terminado } }
    private var pasados: [Trip] { trips.filter { $0.estado == .terminado }.reversed() }

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ContentUnavailableView {
                        Label("Sin viajes todavía", systemImage: "airplane.departure")
                    } description: {
                        Text("Crea tu primer viaje y te calculamos el costo de todo: vuelos, hospedaje, comida, seguro, visa y más.")
                    } actions: {
                        Button("Planear un viaje") { mostrarNuevo = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if !proximos.isEmpty {
                            Section("Próximos") {
                                ForEach(proximos) { trip in fila(trip) }
                            }
                        }
                        if !pasados.isEmpty {
                            Section("Viajes pasados") {
                                ForEach(pasados) { trip in fila(trip) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Mis viajes")
            .navigationDestination(for: Trip.self) { TripDetailView(trip: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { mostrarNuevo = true } label: { Image(systemName: "plus.circle.fill") }
                        .accessibilityLabel("Nuevo viaje")
                }
            }
            .sheet(isPresented: $mostrarNuevo) { NewTripView() }
            .confirmationDialog("¿Eliminar viaje?", isPresented: Binding(get: { porBorrar != nil }, set: { if !$0 { porBorrar = nil } }), titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) {
                    if let t = porBorrar {
                        NotificationService.cancelar(para: t)
                        context.delete(t)
                    }
                    porBorrar = nil
                }
            } message: {
                Text("Se borrarán itinerario, gastos, reservas y listas.")
            }
        }
    }

    private func fila(_ trip: Trip) -> some View {
        NavigationLink(value: trip) {
            TripCard(trip: trip)
        }
        .swipeActions {
            Button(role: .destructive) { porBorrar = trip } label: { Label("Eliminar", systemImage: "trash") }
        }
    }
}

struct TripCard: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 14) {
            Text(trip.emoji)
                .font(.system(size: 36))
                .frame(width: 56, height: 56)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.nombre).font(.headline)
                Text("\(trip.fechaInicio.corta) – \(trip.fechaFin.corta) · \(trip.dias) días · \(trip.numeroViajeros) pers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text(trip.presupuesto.dinero(trip.monedaBase))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                    Spacer()
                    insignia
                }
                if trip.totalGastado > 0 {
                    BarraPresupuesto(gastado: trip.totalGastado, total: trip.presupuesto)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var insignia: some View {
        switch trip.estado {
        case .proximo:
            Text(trip.diasRestantes == 1 ? "¡Mañana!" : "En \(trip.diasRestantes) días")
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.15), in: Capsule())
        case .enCurso:
            Text("En curso").font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.green.opacity(0.2), in: Capsule())
        case .terminado:
            Text("Terminado").font(.caption).foregroundStyle(.secondary)
        }
    }
}
