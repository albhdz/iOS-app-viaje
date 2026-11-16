import SwiftUI
import SwiftData
import CoreLocation

struct NewTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(CurrencyService.self) private var currency

    @AppStorage(Ajustes.claveMoneda) private var monedaPreferida = "MXN"
    @AppStorage(Ajustes.claveOrigen) private var origenPreferido = "Ciudad de México"

    var destinoInicial: Destination?

    @State private var personalizado = false
    @State private var destino: Destination?
    @State private var nombre = ""

    // Destino personalizado
    @State private var nombreCustom = ""
    @State private var paisCustom = ""
    @State private var monedaCustom = "USD"
    @State private var latCustom: Double?
    @State private var lonCustom: Double?
    @State private var costoCustom = DailyCosts(hospedaje: 70, comida: 35, transporte: 10, actividades: 20)
    @State private var buscandoUbicacion = false

    @State private var origenNombre = "Ciudad de México"
    @State private var fechaInicio = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
    @State private var fechaFin = Calendar.current.date(byAdding: .day, value: 66, to: Date()) ?? Date()
    @State private var viajeros = 2
    @State private var nombres: [String] = ["", "", "", "", "", "", "", "", "", ""]
    @State private var estilo: TravelStyle = .medio
    @State private var tipo: TripType = .ciudad
    @State private var monedaBase = "MXN"
    @State private var incluirVuelos = true
    @State private var incluirSeguro = true
    @State private var verDesglose = false

    private var diasViaje: Int {
        max(0, Calendar.current.dateComponents([.day], from: fechaInicio.inicioDelDia, to: fechaFin.inicioDelDia).day ?? 0) + 1
    }

    private var origen: OriginCity? { DestinationCatalog.origenes.first { $0.nombre == origenNombre } }

    private var datos: TripFactory.Datos? {
        if personalizado {
            guard !nombreCustom.isEmpty else { return nil }
            return .init(nombre: nombre.isEmpty ? nombreCustom : nombre, destino: nil,
                         destinoNombre: nombreCustom, destinoPais: paisCustom,
                         latitud: latCustom ?? 0, longitud: lonCustom ?? 0, monedaLocal: monedaCustom,
                         costoPersonalizado: costoCustom, origen: latCustom == nil ? nil : origen,
                         fechaInicio: fechaInicio, fechaFin: fechaFin, viajeros: viajeros,
                         nombresViajeros: Array(nombres.prefix(viajeros)), estilo: estilo, tipo: tipo,
                         monedaBase: monedaBase, incluirVuelos: incluirVuelos, incluirSeguro: incluirSeguro)
        }
        guard let d = destino else { return nil }
        return .init(nombre: nombre.isEmpty ? "Viaje a \(d.nombre)" : nombre, destino: d,
                     destinoNombre: d.nombre, destinoPais: d.pais, latitud: d.latitud, longitud: d.longitud,
                     monedaLocal: d.moneda, costoPersonalizado: nil, origen: origen,
                     fechaInicio: fechaInicio, fechaFin: fechaFin, viajeros: viajeros,
                     nombresViajeros: Array(nombres.prefix(viajeros)), estilo: estilo, tipo: tipo,
                     monedaBase: monedaBase, incluirVuelos: incluirVuelos, incluirSeguro: incluirSeguro)
    }

    private var estimate: Estimate? {
        guard let datos else { return nil }
        return CostEstimator.estimar(TripFactory.input(datos))
    }

    var body: some View {
        NavigationStack {
            Form {
                seccionDestino
                seccionFechas
                seccionViajeros
                seccionEstilo
                seccionOpciones
                if let estimate { seccionEstimado(estimate) }
            }
            .navigationTitle("Nuevo viaje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") { crear() }.bold().disabled(datos == nil)
                }
            }
            .onAppear {
                monedaBase = monedaPreferida
                origenNombre = origenPreferido
                if let d = destinoInicial {
                    destino = d
                    tipo = d.tags.first ?? .ciudad
                }
            }
        }
    }

    // MARK: Secciones

    private var seccionDestino: some View {
        Section {
            Picker("Tipo de destino", selection: $personalizado) {
                Text("Catálogo").tag(false)
                Text("Otro lugar").tag(true)
            }
            .pickerStyle(.segmented)

            if personalizado {
                TextField("Ciudad o lugar", text: $nombreCustom)
                TextField("País", text: $paisCustom)
                SelectorMoneda(titulo: "Moneda local", moneda: $monedaCustom)
                Button {
                    Task { await geocodificar() }
                } label: {
                    HStack {
                        Label(latCustom == nil ? "Ubicar en el mapa (para calcular vuelo)" : "Ubicación encontrada ✓", systemImage: "mappin.and.ellipse")
                        if buscandoUbicacion { Spacer(); ProgressView() }
                    }
                }
                .disabled(nombreCustom.isEmpty)
                DisclosureGroup("Costo diario por persona (USD, nivel medio)") {
                    CampoMonto(titulo: "Hospedaje", monto: $costoCustom.hospedaje, moneda: "USD")
                    CampoMonto(titulo: "Comida", monto: $costoCustom.comida, moneda: "USD")
                    CampoMonto(titulo: "Transporte", monto: $costoCustom.transporte, moneda: "USD")
                    CampoMonto(titulo: "Actividades", monto: $costoCustom.actividades, moneda: "USD")
                }
            } else {
                NavigationLink {
                    DestinationPickerView(seleccion: $destino, estilo: estilo, moneda: monedaBase)
                } label: {
                    HStack {
                        Text("Destino")
                        Spacer()
                        if let d = destino {
                            Text("\(d.emoji) \(d.nombre)").foregroundStyle(.secondary)
                        } else {
                            Text("Elegir").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            TextField("Nombre del viaje (opcional)", text: $nombre)
            Picker("Salgo desde", selection: $origenNombre) {
                ForEach(DestinationCatalog.origenes) { Text($0.nombre).tag($0.nombre) }
            }
        } header: {
            Text("¿A dónde vas?")
        }
    }

    private var seccionFechas: some View {
        Section("Fechas") {
            DatePicker("Ida", selection: $fechaInicio, displayedComponents: .date)
                .onChange(of: fechaInicio) { _, nueva in
                    if fechaFin < nueva { fechaFin = Calendar.current.date(byAdding: .day, value: 5, to: nueva) ?? nueva }
                }
            DatePicker("Regreso", selection: $fechaFin, in: fechaInicio..., displayedComponents: .date)
            LabeledContent("Duración", value: "\(diasViaje) días · \(diasViaje - 1) noches")
        }
    }

    private var seccionViajeros: some View {
        Section("Viajeros") {
            Stepper("\(viajeros) viajero\(viajeros == 1 ? "" : "s")", value: $viajeros, in: 1...10)
            ForEach(0..<viajeros, id: \.self) { i in
                TextField(i == 0 ? "Tu nombre (opcional)" : "Viajero \(i + 1)", text: $nombres[i])
            }
        }
    }

    private var seccionEstilo: some View {
        Section {
            Picker("Estilo", selection: $estilo) {
                ForEach(TravelStyle.allCases) { e in
                    Label(e.nombre, systemImage: e.icono).tag(e)
                }
            }
            Text(estilo.descripcion).font(.caption).foregroundStyle(.secondary)
            Picker("Tipo de viaje", selection: $tipo) {
                ForEach(TripType.allCases) { t in
                    Label(t.nombre, systemImage: t.icono).tag(t)
                }
            }
        } header: {
            Text("Estilo de viaje")
        } footer: {
            Text("El tipo de viaje se usa para armar tu lista de equipaje.")
        }
    }

    private var seccionOpciones: some View {
        Section("Opciones") {
            Toggle("Incluir vuelos", isOn: $incluirVuelos)
            Toggle("Incluir seguro de viaje", isOn: $incluirSeguro)
            SelectorMoneda(titulo: "Moneda del presupuesto", moneda: $monedaBase)
        }
    }

    private func seccionEstimado(_ e: Estimate) -> some View {
        let total = currency.desdeUSD(e.totalUSD * 1.10, a: monedaBase)
        return Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Costo estimado total").font(.subheadline).foregroundStyle(.secondary)
                Text(total.dinero(monedaBase))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                HStack {
                    StatCard(titulo: "Por persona", valor: (total / Double(viajeros)).dinero(monedaBase), icono: "person.fill")
                    StatCard(titulo: "Por día", valor: (total / Double(diasViaje)).dinero(monedaBase), icono: "calendar")
                }
                if e.distanciaKm > 300 {
                    Text("✈️ \(Int(e.distanciaKm)) km · ≈\(String(format: "%.1f", e.horasVuelo)) h de vuelo por trayecto")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("Incluye 10 % de colchón para imprevistos.").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            DisclosureGroup("Ver desglose de costos", isExpanded: $verDesglose) {
                ForEach(ExpenseCategory.allCases) { cat in
                    let v = e.total(de: cat)
                    if v > 0 {
                        HStack {
                            IconoCategoria(icono: cat.icono, color: cat.color, tamano: 26)
                            Text(cat.nombre).font(.subheadline)
                            Spacer()
                            Text(currency.desdeUSD(v, a: monedaBase).dinero(monedaBase))
                                .font(.subheadline).monospacedDigit()
                        }
                    }
                }
            }
            if !e.consejos.isEmpty {
                DisclosureGroup("Consejos para ahorrar") {
                    ForEach(e.consejos, id: \.self) { c in
                        Label(c, systemImage: "lightbulb.fill")
                            .font(.caption)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        } header: {
            Text("Estimación")
        } footer: {
            Text("Precios aproximados 2026 basados en promedios por destino. Podrás editar cada partida después.")
        }
    }

    // MARK: Acciones

    private func geocodificar() async {
        buscandoUbicacion = true
        defer { buscandoUbicacion = false }
        let texto = [nombreCustom, paisCustom].filter { !$0.isEmpty }.joined(separator: ", ")
        if let lugar = try? await CLGeocoder().geocodeAddressString(texto).first, let loc = lugar.location {
            latCustom = loc.coordinate.latitude
            lonCustom = loc.coordinate.longitude
            if paisCustom.isEmpty { paisCustom = lugar.country ?? "" }
        }
    }

    private func crear() {
        guard let datos else { return }
        TripFactory.crear(datos, context: context, currency: currency)
        dismiss()
    }
}

/// Lista buscable de destinos del catálogo con su costo diario.
struct DestinationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrencyService.self) private var currency
    @Binding var seleccion: Destination?
    var estilo: TravelStyle
    var moneda: String
    @State private var busqueda = ""

    private var filtrados: [Destination] {
        guard !busqueda.isEmpty else { return DestinationCatalog.todos }
        return DestinationCatalog.todos.filter {
            $0.nombre.localizedCaseInsensitiveContains(busqueda) || $0.pais.localizedCaseInsensitiveContains(busqueda)
        }
    }

    var body: some View {
        List {
            ForEach(Region.allCases) { region in
                let items = filtrados.filter { $0.region == region }
                if !items.isEmpty {
                    Section(region.nombre) {
                        ForEach(items) { d in
                            Button {
                                seleccion = d
                                dismiss()
                            } label: {
                                HStack {
                                    Text(d.emoji).font(.title2)
                                    VStack(alignment: .leading) {
                                        Text(d.nombre).foregroundStyle(.primary)
                                        Text(d.pais).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(currency.desdeUSD(d.costoDiario(estilo).total, a: moneda).dinero(moneda))
                                            .font(.subheadline.bold()).monospacedDigit()
                                        Text("por día/pers.").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    if seleccion?.id == d.id {
                                        Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $busqueda, prompt: "Buscar ciudad o país")
        .navigationTitle("Destino")
    }
}
