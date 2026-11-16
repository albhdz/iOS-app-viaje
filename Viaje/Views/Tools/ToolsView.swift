import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Dinero") {
                    NavigationLink { CurrencyConverterView() } label: {
                        fila("Convertidor de divisas", "Tasas actualizadas, 35 monedas", "dollarsign.arrow.circlepath", .green)
                    }
                    NavigationLink { TipCalculatorView() } label: {
                        fila("Propinas y dividir cuenta", "Calcula cuánto le toca a cada quien", "percent", .orange)
                    }
                    NavigationLink { CompareDestinationsView() } label: {
                        fila("Comparar destinos", "¿Cuál me sale más barato?", "chart.bar.xaxis", .blue)
                    }
                }
                Section("Guías") {
                    NavigationLink { SavingTipsView() } label: {
                        fila("Trucos para ahorrar", "Vuelos, hospedaje, comida y más", "lightbulb.fill", .yellow)
                    }
                    NavigationLink { HiddenCostsView() } label: {
                        fila("Costos ocultos", "Lo que casi nadie presupuesta", "exclamationmark.triangle.fill", .red)
                    }
                    NavigationLink { BaggageRulesView() } label: {
                        fila("Equipaje y aeropuerto", "Medidas, pesos y líquidos", "suitcase.cart.fill", .brown)
                    }
                }
            }
            .navigationTitle("Herramientas")
        }
    }

    private func fila(_ t: String, _ s: String, _ i: String, _ c: Color) -> some View {
        HStack(spacing: 12) {
            IconoCategoria(icono: i, color: c, tamano: 36)
            VStack(alignment: .leading) {
                Text(t)
                Text(s).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Convertidor

struct CurrencyConverterView: View {
    @Environment(CurrencyService.self) private var currency
    @AppStorage(Ajustes.claveMoneda) private var monedaBase = "MXN"
    @State private var monto: Double = 100
    @State private var de = "USD"
    @State private var a = "MXN"

    private let rapidas = [1.0, 5, 10, 20, 50, 100, 500, 1000]

    var body: some View {
        Form {
            Section {
                TextField("Monto", value: $monto, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .font(.largeTitle.bold())
                SelectorMoneda(titulo: "De", moneda: $de)
                Button {
                    let temp = de
                    de = a
                    a = temp
                } label: {
                    Label("Invertir", systemImage: "arrow.up.arrow.down")
                }
                SelectorMoneda(titulo: "A", moneda: $a)
            }
            Section("Resultado") {
                Text(currency.convertir(monto, de: de, a: a).dinero(a, decimales: true))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("1 \(de) = \(currency.tasa(de: de, a: a).formatted(.number.precision(.fractionLength(2...6)))) \(a)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Tabla rápida") {
                ForEach(rapidas, id: \.self) { v in
                    LabeledContent(v.dinero(de), value: currency.convertir(v, de: de, a: a).dinero(a, decimales: true))
                        .monospacedDigit()
                }
            }
            Section {
                Button {
                    Task { await currency.actualizar() }
                } label: {
                    HStack {
                        Label("Actualizar tasas", systemImage: "arrow.clockwise")
                        if currency.actualizando { Spacer(); ProgressView() }
                    }
                }
                if let f = currency.ultimaActualizacion {
                    Text("Última actualización: \(f.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let e = currency.error { Text(e).font(.caption).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Convertidor")
        .onAppear { a = monedaBase }
    }
}

// MARK: - Propinas

struct TipCalculatorView: View {
    @State private var cuenta: Double = 0
    @State private var porcentaje: Double = 15
    @State private var personas = 2
    @State private var moneda = "USD"

    private var propina: Double { cuenta * porcentaje / 100 }
    private var total: Double { cuenta + propina }

    var body: some View {
        Form {
            Section {
                CampoMonto(titulo: "Cuenta", monto: $cuenta, moneda: moneda)
                SelectorMoneda(moneda: $moneda)
            }
            Section("Propina: \(Int(porcentaje)) %") {
                Slider(value: $porcentaje, in: 0...30, step: 1)
                Picker("Rápido", selection: $porcentaje) {
                    ForEach([0.0, 10, 15, 18, 20, 25], id: \.self) { Text("\(Int($0)) %").tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section {
                Stepper("\(personas) persona(s)", value: $personas, in: 1...30)
            }
            Section("Resultado") {
                LabeledContent("Propina", value: propina.dinero(moneda, decimales: true))
                LabeledContent("Total", value: total.dinero(moneda, decimales: true))
                LabeledContent("Cada quien paga", value: (total / Double(personas)).dinero(moneda, decimales: true))
                    .font(.headline)
            }
            Section("Costumbres") {
                Text("🇺🇸 🇨🇦 18–22 % · 🇲🇽 10–15 % · 🇪🇸 🇫🇷 🇮🇹 redondear · 🇯🇵 🇰🇷 no se deja · 🇬🇧 12,5 % suele venir incluido")
                    .font(.caption)
            }
        }
        .navigationTitle("Propinas")
    }
}

// MARK: - Comparador

struct CompareDestinationsView: View {
    @Environment(CurrencyService.self) private var currency
    @AppStorage(Ajustes.claveMoneda) private var moneda = "MXN"
    @AppStorage(Ajustes.claveOrigen) private var origenNombre = "Ciudad de México"
    @State private var seleccion: Set<String> = ["cancun", "madrid", "tokio"]
    @State private var dias = 7
    @State private var viajeros = 2
    @State private var estilo: TravelStyle = .medio

    private struct Resultado: Identifiable {
        let id: String
        let destino: Destination
        let estimate: Estimate
    }

    private var resultados: [Resultado] {
        let inicio = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        let fin = Calendar.current.date(byAdding: .day, value: dias - 1, to: inicio) ?? inicio
        let origen = DestinationCatalog.origenes.first { $0.nombre == origenNombre }
        return DestinationCatalog.todos.filter { seleccion.contains($0.id) }.map { d in
            Resultado(id: d.id, destino: d, estimate: CostEstimator.estimar(EstimateInput(
                destino: d, costoDiarioPersonalizado: nil, paisDestino: d.pais, origen: origen,
                latDestino: d.latitud, lonDestino: d.longitud, fechaInicio: inicio, fechaFin: fin,
                viajeros: viajeros, estilo: estilo)))
        }
        .sorted { $0.estimate.totalUSD < $1.estimate.totalUSD }
    }

    var body: some View {
        List {
            Section("Parámetros") {
                Stepper("\(dias) días", value: $dias, in: 1...60)
                Stepper("\(viajeros) viajero(s)", value: $viajeros, in: 1...10)
                Picker("Estilo", selection: $estilo) {
                    ForEach(TravelStyle.allCases) { Text($0.nombre).tag($0) }
                }
                NavigationLink("Destinos (\(seleccion.count))") {
                    List(DestinationCatalog.todos) { d in
                        Button {
                            if seleccion.contains(d.id) { seleccion.remove(d.id) } else { seleccion.insert(d.id) }
                        } label: {
                            HStack {
                                Text("\(d.emoji) \(d.nombre)").foregroundStyle(.primary)
                                Spacer()
                                if seleccion.contains(d.id) { Image(systemName: "checkmark") }
                            }
                        }
                    }
                    .navigationTitle("Elegir destinos")
                }
            }
            Section("Costo total desde \(origenNombre)") {
                ForEach(Array(resultados.enumerated()), id: \.element.id) { i, r in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(i == 0 ? "🏆" : "\(i + 1).")
                            Text("\(r.destino.emoji) \(r.destino.nombre)").font(.headline)
                            Spacer()
                            Text(currency.desdeUSD(r.estimate.totalUSD, a: moneda).dinero(moneda)).font(.headline).monospacedDigit()
                        }
                        HStack(spacing: 12) {
                            mini("airplane", r.estimate.total(de: .vuelos))
                            mini("bed.double.fill", r.estimate.total(de: .hospedaje))
                            mini("fork.knife", r.estimate.total(de: .comida))
                            mini("ticket.fill", r.estimate.total(de: .actividades))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Comparar destinos")
    }

    private func mini(_ icono: String, _ usd: Double) -> some View {
        Label(currency.desdeUSD(usd, a: moneda).dinero(moneda), systemImage: icono).monospacedDigit()
    }
}

// MARK: - Guías

struct GuideSection: Identifiable {
    let id = UUID()
    let titulo: String
    let icono: String
    let puntos: [String]
}

struct GuideView: View {
    let titulo: String
    let secciones: [GuideSection]

    var body: some View {
        List {
            ForEach(secciones) { s in
                Section {
                    ForEach(s.puntos, id: \.self) { p in
                        Text(p).font(.subheadline)
                    }
                } header: {
                    Label(s.titulo, systemImage: s.icono)
                }
            }
        }
        .navigationTitle(titulo)
    }
}

struct SavingTipsView: View {
    var body: some View {
        GuideView(titulo: "Trucos para ahorrar", secciones: [
            .init(titulo: "Vuelos", icono: "airplane", puntos: [
                "Compra con 1–4 meses de anticipación en vuelos nacionales y 2–6 meses en internacionales.",
                "Activa alertas de precio (Google Flights, Skyscanner, Kayak) y sé flexible ±3 días.",
                "Martes, miércoles y sábado suelen ser los días más baratos para volar.",
                "Compara aeropuertos alternos y vuelos con escala larga (puedes conocer otra ciudad).",
                "En aerolíneas de bajo costo, suma maleta, asiento y cargos antes de comparar.",
            ]),
            .init(titulo: "Hospedaje", icono: "bed.double.fill", puntos: [
                "Reserva con cancelación gratuita y vuelve a revisar el precio unas semanas antes.",
                "Estancias de 7+ noches en Airbnb suelen tener descuento semanal de 10–20 %.",
                "Revisa tasas turísticas y resort fees: pueden sumar 10–25 % al precio publicado.",
                "Hospedarte a 1–2 estaciones del centro puede costar 30 % menos.",
            ]),
            .init(titulo: "En destino", icono: "map.fill", puntos: [
                "Pases de ciudad y de transporte (City Pass, JR Pass, Swiss Pass) si visitarás muchas atracciones.",
                "Comida fuerte al mediodía: muchos restaurantes tienen menú del día más barato.",
                "Muchos museos son gratis ciertos días de la semana o del mes.",
                "Tours gratuitos a pie (free walking tours): solo dejas propina.",
            ]),
            .init(titulo: "Dinero", icono: "creditcard.fill", puntos: [
                "Usa tarjetas sin comisión por compras en el extranjero.",
                "Paga siempre en moneda local y rechaza la conversión dinámica (DCC).",
                "Evita casas de cambio en aeropuertos; retira de cajeros de bancos locales.",
                "Revisa si tu tarjeta incluye seguro de viaje o acceso a salas VIP.",
            ]),
        ])
    }
}

struct HiddenCostsView: View {
    var body: some View {
        GuideView(titulo: "Costos ocultos", secciones: [
            .init(titulo: "Antes de salir", icono: "doc.text.fill", puntos: [
                "Pasaporte, visa o autorización electrónica (ESTA, eTA, ETIAS, ETA UK).",
                "Vacunas y consulta médica de viaje.",
                "Transporte o estacionamiento del aeropuerto en tu ciudad.",
                "Cuidado de mascotas o casa.",
            ]),
            .init(titulo: "Aerolínea", icono: "airplane", puntos: [
                "Maleta documentada (30–80 USD por trayecto).",
                "Selección de asiento y equipaje de mano en tarifas básicas.",
                "Comida a bordo en aerolíneas de bajo costo.",
                "Impuestos de salida (en algunos países se pagan aparte).",
            ]),
            .init(titulo: "En destino", icono: "mappin.and.ellipse", puntos: [
                "Tasas turísticas por noche (Europa: 1–12 € por persona).",
                "Resort fees en EE. UU. (Las Vegas, Orlando, Miami).",
                "Propinas obligatorias en la práctica (EE. UU. 18–22 %).",
                "Comisiones bancarias por retiro y conversión (3–5 %).",
                "Datos móviles / roaming (una eSIM suele ser 5–10 veces más barata).",
                "Seguro y depósito de renta de auto, casetas, gasolina y estacionamiento.",
            ]),
        ])
    }
}

struct BaggageRulesView: View {
    var body: some View {
        GuideView(titulo: "Equipaje y aeropuerto", secciones: [
            .init(titulo: "Medidas típicas", icono: "ruler", puntos: [
                "Equipaje de mano: 55 × 40 × 25 cm, 7–10 kg (varía por aerolínea).",
                "Artículo personal: bolso o mochila pequeña bajo el asiento (≈ 40 × 30 × 15 cm).",
                "Maleta documentada en turista: 23 kg y 158 cm lineales.",
            ]),
            .init(titulo: "Líquidos (regla 3-1-1)", icono: "drop.fill", puntos: [
                "Envases de máximo 100 ml, en una bolsa transparente de 1 litro.",
                "Medicamentos y fórmula para bebé están exentos (decláralos).",
                "Baterías externas y de litio siempre en equipaje de mano.",
            ]),
            .init(titulo: "Tiempos", icono: "clock.fill", puntos: [
                "Llega 2 h antes en vuelos nacionales y 3 h en internacionales.",
                "Check-in en línea 24–48 h antes para elegir asiento sin costo.",
                "Escalas internacionales: mínimo 2 h si cambias de terminal o pasas migración.",
            ]),
        ])
    }
}
