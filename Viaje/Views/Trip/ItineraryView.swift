import SwiftUI
import SwiftData
import MapKit

struct ItineraryView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: Trip
    @State private var diaParaAgregar: Date?
    @State private var editando: ItineraryItem?

    var body: some View {
        List {
            if let d = trip.destino, !d.imperdibles.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(d.imperdibles) { imp in
                                let yaEsta = trip.itinerario.contains { $0.titulo == imp.nombre }
                                Button { agregarImperdible(imp) } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label(imp.nombre, systemImage: imp.categoria.icono)
                                            .font(.caption.bold()).lineLimit(2)
                                        Text(imp.costoUSD == 0 ? "Gratis" : "\(CurrencyService.shared.desdeUSD(imp.costoUSD, a: trip.monedaBase).dinero(trip.monedaBase)) /pers.")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .frame(width: 150, alignment: .leading)
                                    .padding(10)
                                    .background(imp.categoria.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(alignment: .topTrailing) {
                                        if yaEsta { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).padding(4) }
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(yaEsta)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                } header: {
                    Text("Imperdibles de \(d.nombre) · toca para agregar")
                }
            }

            ForEach(Array(trip.listaDias.enumerated()), id: \.element) { indice, dia in
                let items = trip.itinerario
                    .filter { Calendar.current.isDate($0.dia, inSameDayAs: dia) }
                    .sorted { $0.hora < $1.hora }
                Section {
                    ForEach(items) { item in
                        Button { editando = item } label: { ItineraryRow(item: item, moneda: trip.monedaBase) }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading) {
                                Button { item.completado.toggle() } label: {
                                    Label("Hecho", systemImage: "checkmark")
                                }.tint(.green)
                            }
                    }
                    .onDelete { idx in for i in idx { context.delete(items[i]) } }
                    Button { diaParaAgregar = dia } label: {
                        Label("Agregar actividad", systemImage: "plus").font(.subheadline)
                    }
                } header: {
                    HStack {
                        Text("Día \(indice + 1) · \(dia.larga)")
                        Spacer()
                        let costo = items.reduce(0) { $0 + $1.costoEstimado }
                        if costo > 0 { Text(costo.dinero(trip.monedaBase)).monospacedDigit() }
                    }
                }
            }
        }
        .navigationTitle("Itinerario")
        .sheet(item: Binding(get: { diaParaAgregar.map { DiaID(fecha: $0) } }, set: { diaParaAgregar = $0?.fecha })) { d in
            ItineraryItemEditor(trip: trip, item: nil, dia: d.fecha)
        }
        .sheet(item: $editando) { item in
            ItineraryItemEditor(trip: trip, item: item, dia: item.dia)
        }
    }

    /// Coloca el imperdible en el primer día con menos actividades.
    private func agregarImperdible(_ imp: Imperdible) {
        let dias = trip.listaDias
        let candidato = dias.dropFirst().dropLast().min { a, b in
            conteo(a) < conteo(b)
        } ?? dias.first ?? trip.fechaInicio
        let hora = Calendar.current.date(bySettingHour: 10 + conteo(candidato) * 3 % 10, minute: 0, second: 0, of: candidato) ?? candidato
        let item = ItineraryItem(dia: candidato, hora: hora, titulo: imp.nombre, categoria: imp.categoria)
        item.duracionMinutos = Int(imp.horas * 60)
        item.costoEstimado = CurrencyService.shared.desdeUSD(imp.costoUSD, a: trip.monedaBase) * Double(trip.numeroViajeros)
        item.ubicacion = trip.destinoNombre
        trip.itinerario.append(item)
    }

    private func conteo(_ dia: Date) -> Int {
        trip.itinerario.filter { Calendar.current.isDate($0.dia, inSameDayAs: dia) }.count
    }
}

private struct DiaID: Identifiable {
    let fecha: Date
    var id: Date { fecha }
}

struct ItineraryRow: View {
    let item: ItineraryItem
    let moneda: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Text(item.hora.hora).font(.caption.bold()).monospacedDigit()
                if item.duracionMinutos > 0 {
                    Text(duracion).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 52)
            IconoCategoria(icono: item.categoria.icono, color: item.categoria.color, tamano: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.titulo)
                    .strikethrough(item.completado)
                    .foregroundStyle(item.completado ? .secondary : .primary)
                if !item.ubicacion.isEmpty {
                    Label(item.ubicacion, systemImage: "mappin").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                if !item.notas.isEmpty {
                    Text(item.notas).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer()
            if item.costoEstimado > 0 {
                Text(item.costoEstimado.dinero(moneda)).font(.caption).monospacedDigit()
            }
        }
        .contentShape(Rectangle())
    }

    private var duracion: String {
        let h = item.duracionMinutos / 60, m = item.duracionMinutos % 60
        return h > 0 ? (m > 0 ? "\(h) h \(m)" : "\(h) h") : "\(m) min"
    }
}

struct ItineraryItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    var trip: Trip
    var item: ItineraryItem?
    var dia: Date

    @State private var titulo = ""
    @State private var categoria: ActivityCategory = .visita
    @State private var fechaDia = Date()
    @State private var hora = Date()
    @State private var duracion = 60
    @State private var costo: Double = 0
    @State private var porPersona = true
    @State private var ubicacion = ""
    @State private var lat: Double?
    @State private var lon: Double?
    @State private var notas = ""
    @State private var buscarLugar = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("¿Qué vas a hacer?", text: $titulo)
                    Picker("Categoría", selection: $categoria) {
                        ForEach(ActivityCategory.allCases) { Label($0.nombre, systemImage: $0.icono).tag($0) }
                    }
                }
                Section("Cuándo") {
                    Picker("Día", selection: $fechaDia) {
                        ForEach(Array(trip.listaDias.enumerated()), id: \.element) { i, d in
                            Text("Día \(i + 1) · \(d.corta)").tag(d)
                        }
                    }
                    DatePicker("Hora", selection: $hora, displayedComponents: .hourAndMinute)
                    Stepper("Duración: \(duracion / 60) h \(duracion % 60) min", value: $duracion, in: 0...1440, step: 15)
                }
                Section("Dónde") {
                    Button {
                        buscarLugar = true
                    } label: {
                        Label(ubicacion.isEmpty ? "Buscar lugar" : ubicacion, systemImage: lat == nil ? "magnifyingglass" : "mappin.circle.fill")
                    }
                }
                Section {
                    CampoMonto(titulo: "Costo", monto: $costo, moneda: trip.monedaBase)
                    Toggle("Es por persona (×\(trip.numeroViajeros))", isOn: $porPersona)
                    if porPersona && costo > 0 {
                        LabeledContent("Total", value: (costo * Double(trip.numeroViajeros)).dinero(trip.monedaBase))
                    }
                } header: {
                    Text("Costo estimado")
                }
                Section("Notas") {
                    TextField("Reservación, qué llevar, tips…", text: $notas, axis: .vertical)
                }
            }
            .navigationTitle(item == nil ? "Nueva actividad" : "Editar actividad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }.disabled(titulo.isEmpty)
                }
            }
            .sheet(isPresented: $buscarLugar) {
                LocationSearchView(cerca: CLLocationCoordinate2D(latitude: trip.latitud, longitude: trip.longitud)) { nombre, coord in
                    ubicacion = nombre
                    lat = coord.latitude
                    lon = coord.longitude
                    if titulo.isEmpty { titulo = nombre }
                }
            }
            .onAppear(perform: cargar)
        }
    }

    private func cargar() {
        fechaDia = trip.listaDias.first { Calendar.current.isDate($0, inSameDayAs: dia) } ?? trip.listaDias.first ?? dia
        if let item {
            titulo = item.titulo
            categoria = item.categoria
            hora = item.hora
            duracion = item.duracionMinutos
            costo = item.costoEstimado
            porPersona = false
            ubicacion = item.ubicacion
            lat = item.latitud
            lon = item.longitud
            notas = item.notas
        } else {
            hora = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: dia) ?? dia
        }
    }

    private func guardar() {
        let cal = Calendar.current
        let hm = cal.dateComponents([.hour, .minute], from: hora)
        let horaFinal = cal.date(bySettingHour: hm.hour ?? 0, minute: hm.minute ?? 0, second: 0, of: fechaDia) ?? fechaDia
        let destino = item ?? ItineraryItem(dia: fechaDia, hora: horaFinal, titulo: titulo, categoria: categoria)
        destino.dia = fechaDia
        destino.hora = horaFinal
        destino.titulo = titulo
        destino.categoria = categoria
        destino.duracionMinutos = duracion
        destino.costoEstimado = porPersona ? costo * Double(trip.numeroViajeros) : costo
        destino.ubicacion = ubicacion
        destino.latitud = lat
        destino.longitud = lon
        destino.notas = notas
        if item == nil { trip.itinerario.append(destino) }
        dismiss()
    }
}

/// Búsqueda de lugares con MapKit.
struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    var cerca: CLLocationCoordinate2D
    var alElegir: (String, CLLocationCoordinate2D) -> Void
    @State private var texto = ""
    @State private var resultados: [MKMapItem] = []
    @State private var buscando = false

    var body: some View {
        NavigationStack {
            List(resultados, id: \.self) { r in
                Button {
                    alElegir(r.name ?? texto, r.placemark.coordinate)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(r.name ?? "").foregroundStyle(.primary)
                        Text(r.placemark.title ?? "").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if buscando { ProgressView() }
                else if resultados.isEmpty {
                    ContentUnavailableView("Busca un lugar", systemImage: "mappin.and.ellipse",
                                           description: Text("Museos, restaurantes, hoteles, atracciones…"))
                }
            }
            .searchable(text: $texto, placement: .navigationBarDrawer(displayMode: .always), prompt: "Lugar o dirección")
            .onSubmit(of: .search) { Task { await buscar() } }
            .navigationTitle("Buscar lugar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
        }
    }

    private func buscar() async {
        buscando = true
        defer { buscando = false }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = texto
        if cerca.latitude != 0 || cerca.longitude != 0 {
            req.region = MKCoordinateRegion(center: cerca, latitudinalMeters: 60_000, longitudinalMeters: 60_000)
        }
        resultados = (try? await MKLocalSearch(request: req).start().mapItems) ?? []
    }
}
