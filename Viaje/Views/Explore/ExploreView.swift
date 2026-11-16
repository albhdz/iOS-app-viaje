import SwiftUI
import Charts

struct ExploreView: View {
    @Environment(CurrencyService.self) private var currency
    @AppStorage(Ajustes.claveMoneda) private var moneda = "MXN"
    @State private var busqueda = ""
    @State private var region: Region?
    @State private var tipo: TripType?
    @State private var estilo: TravelStyle = .medio
    @State private var orden: Orden = .baratos

    enum Orden: String, CaseIterable, Identifiable {
        case baratos = "Más baratos", caros = "Más caros", nombre = "A–Z"
        var id: String { rawValue }
    }

    private var lista: [Destination] {
        var l = DestinationCatalog.todos.filter { d in
            (region == nil || d.region == region) &&
            (tipo == nil || d.tags.contains(tipo!)) &&
            (busqueda.isEmpty || d.nombre.localizedCaseInsensitiveContains(busqueda) || d.pais.localizedCaseInsensitiveContains(busqueda))
        }
        switch orden {
        case .baratos: l.sort { $0.costoMedio.total < $1.costoMedio.total }
        case .caros: l.sort { $0.costoMedio.total > $1.costoMedio.total }
        case .nombre: l.sort { $0.nombre < $1.nombre }
        }
        return l
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Estilo", selection: $estilo) {
                        ForEach(TravelStyle.allCases) { Text($0.nombre).tag($0) }
                    }
                    Picker("Región", selection: $region) {
                        Text("Todas").tag(Region?.none)
                        ForEach(Region.allCases) { Text($0.nombre).tag(Optional($0)) }
                    }
                    Picker("Tipo de viaje", selection: $tipo) {
                        Text("Todos").tag(TripType?.none)
                        ForEach(TripType.allCases) { Label($0.nombre, systemImage: $0.icono).tag(Optional($0)) }
                    }
                    Picker("Ordenar", selection: $orden) {
                        ForEach(Orden.allCases) { Text($0.rawValue).tag($0) }
                    }
                } footer: {
                    Text("Costo diario por persona: hospedaje (habitación doble), comida, transporte local y actividades. No incluye vuelos.")
                }

                Section("\(lista.count) destinos") {
                    ForEach(lista) { d in
                        NavigationLink {
                            DestinationDetailView(destino: d)
                        } label: {
                            DestinationRow(destino: d, estilo: estilo, moneda: moneda)
                        }
                    }
                }
            }
            .searchable(text: $busqueda, prompt: "Ciudad o país")
            .navigationTitle("Explorar")
        }
    }
}

struct DestinationRow: View {
    @Environment(CurrencyService.self) private var currency
    let destino: Destination
    let estilo: TravelStyle
    let moneda: String

    var body: some View {
        let c = destino.costoDiario(estilo)
        HStack(spacing: 12) {
            Text(destino.emoji).font(.largeTitle)
            VStack(alignment: .leading, spacing: 4) {
                Text(destino.nombre).font(.headline)
                Text(destino.pais).font(.caption).foregroundStyle(.secondary)
                GeometryReader { geo in
                    HStack(spacing: 1) {
                        segmento(c.hospedaje, c.total, .indigo, geo.size.width)
                        segmento(c.comida, c.total, .orange, geo.size.width)
                        segmento(c.transporte, c.total, .teal, geo.size.width)
                        segmento(c.actividades, c.total, .pink, geo.size.width)
                    }
                }
                .frame(height: 5)
                .clipShape(Capsule())
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(currency.desdeUSD(c.total, a: moneda).dinero(moneda))
                    .font(.headline).monospacedDigit()
                Text("/día").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private func segmento(_ v: Double, _ total: Double, _ color: Color, _ ancho: CGFloat) -> some View {
        color.frame(width: max(0, ancho * v / max(total, 1) - 1))
    }
}

struct DestinationDetailView: View {
    @Environment(CurrencyService.self) private var currency
    @AppStorage(Ajustes.claveMoneda) private var moneda = "MXN"
    @AppStorage(Ajustes.claveOrigen) private var origenNombre = "Ciudad de México"
    let destino: Destination
    var desdeViaje = false

    @State private var estilo: TravelStyle = .medio
    @State private var dias = 7
    @State private var viajeros = 2
    @State private var planear = false

    private struct Barra: Identifiable {
        let id: String
        let estilo: String
        let monto: Double
    }

    private var estimate: Estimate {
        let inicio = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        let fin = Calendar.current.date(byAdding: .day, value: dias - 1, to: inicio) ?? inicio
        return CostEstimator.estimar(EstimateInput(
            destino: destino, costoDiarioPersonalizado: nil, paisDestino: destino.pais,
            origen: DestinationCatalog.origenes.first { $0.nombre == origenNombre },
            latDestino: destino.latitud, lonDestino: destino.longitud,
            fechaInicio: inicio, fechaFin: fin, viajeros: viajeros, estilo: estilo))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(destino.emoji) \(destino.nombre)").font(.largeTitle.bold())
                    Text("\(destino.pais) · \(destino.region.nombre)").foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            Section("Datos prácticos") {
                LabeledContent("Mejor época", value: destino.mejorEpoca)
                LabeledContent("Idioma", value: destino.idioma)
                LabeledContent("Moneda", value: "\(destino.moneda) · 1 \(destino.moneda) = \(currency.tasa(de: destino.moneda, a: moneda).dinero(moneda, decimales: true))")
                LabeledContent("Enchufe", value: destino.enchufe)
                LabeledContent("Propinas", value: destino.propinas)
                let entrada = CostEstimator.requisitoEntrada(pais: destino.pais)
                LabeledContent("Entrada", value: entrada.nota)
            }

            Section {
                Picker("Estilo", selection: $estilo) {
                    ForEach(TravelStyle.allCases) { Text($0.nombre).tag($0) }
                }
                .pickerStyle(.segmented)
                let c = destino.costoDiario(estilo)
                filaCosto("Hospedaje", "bed.double.fill", .indigo, c.hospedaje)
                filaCosto("Comida", "fork.knife", .orange, c.comida)
                filaCosto("Transporte local", "tram.fill", .teal, c.transporte)
                filaCosto("Actividades", "ticket.fill", .pink, c.actividades)
                HStack {
                    Text("Total por día").bold()
                    Spacer()
                    Text(currency.desdeUSD(c.total, a: moneda).dinero(moneda)).bold().monospacedDigit()
                }
            } header: {
                Text("Costo diario por persona")
            }

            Section("Comparar estilos (por día/persona)") {
                Chart(TravelStyle.allCases.map { Barra(id: $0.rawValue, estilo: $0.nombre, monto: currency.desdeUSD(destino.costoDiario($0).total, a: moneda)) }) { b in
                    BarMark(x: .value("Monto", b.monto), y: .value("Estilo", b.estilo))
                        .foregroundStyle(b.id == estilo.rawValue ? Color.accentColor : Color.secondary.opacity(0.4))
                        .annotation(position: .trailing) {
                            Text(b.monto.dinero(moneda)).font(.caption2).monospacedDigit()
                        }
                }
                .chartXAxis(.hidden)
                .frame(height: 180)
            }

            Section {
                Stepper("\(dias) días", value: $dias, in: 1...60)
                Stepper("\(viajeros) viajero(s)", value: $viajeros, in: 1...10)
                ForEach(ExpenseCategory.allCases) { cat in
                    let v = estimate.total(de: cat)
                    if v > 0 {
                        HStack {
                            Image(systemName: cat.icono).foregroundStyle(cat.color).frame(width: 24)
                            Text(cat.nombre).font(.subheadline)
                            Spacer()
                            Text(currency.desdeUSD(v, a: moneda).dinero(moneda)).font(.subheadline).monospacedDigit()
                        }
                    }
                }
                HStack {
                    Text("Total del viaje").bold()
                    Spacer()
                    Text(currency.desdeUSD(estimate.totalUSD, a: moneda).dinero(moneda)).font(.title3.bold()).monospacedDigit()
                }
            } header: {
                Text("Calculadora rápida desde \(origenNombre)")
            } footer: {
                Text("Incluye vuelo redondo (salida en ~3 meses), hospedaje, comida, transporte, actividades, seguro, visa/ETA, eSIM, propinas y más.")
            }

            Section("Imperdibles y su costo") {
                ForEach(destino.imperdibles) { imp in
                    HStack {
                        IconoCategoria(icono: imp.categoria.icono, color: imp.categoria.color, tamano: 30)
                        VStack(alignment: .leading) {
                            Text(imp.nombre).font(.subheadline)
                            if imp.horas > 0 {
                                Text(imp.horas >= 24 ? "\(Int(imp.horas / 24)) día(s)" : "\(imp.horas.formatted()) h")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(imp.costoUSD == 0 ? "Gratis" : currency.desdeUSD(imp.costoUSD, a: moneda).dinero(moneda))
                            .font(.subheadline).monospacedDigit()
                    }
                }
            }

            if !desdeViaje {
                Section {
                    Button {
                        planear = true
                    } label: {
                        Label("Planear viaje a \(destino.nombre)", systemImage: "airplane.departure")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(destino.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $planear) { NewTripView(destinoInicial: destino) }
    }

    private func filaCosto(_ t: String, _ i: String, _ c: Color, _ usd: Double) -> some View {
        HStack {
            IconoCategoria(icono: i, color: c, tamano: 28)
            Text(t)
            Spacer()
            Text(currency.desdeUSD(usd, a: moneda).dinero(moneda)).monospacedDigit()
        }
    }
}
