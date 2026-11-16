import SwiftUI
import SwiftData
import Charts

struct ExpensesView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: Trip
    @State private var nuevo = false
    @State private var editando: Expense?
    @State private var filtro: ExpenseCategory?

    private var gastosFiltrados: [Expense] {
        trip.gastos
            .filter { filtro == nil || $0.categoria == filtro }
            .sorted { $0.fecha > $1.fecha }
    }

    private var porDia: [(dia: Date, gastos: [Expense])] {
        Dictionary(grouping: gastosFiltrados) { $0.fecha.inicioDelDia }
            .map { (dia: $0.key, gastos: $0.value) }
            .sorted { $0.dia > $1.dia }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        StatCard(titulo: "Total gastado", valor: trip.totalGastado.dinero(trip.monedaBase), icono: "sum", color: .pink)
                        StatCard(titulo: "Disponible", valor: trip.restante.dinero(trip.monedaBase), icono: "wallet.pass", color: trip.restante >= 0 ? .green : .red)
                    }
                    if !trip.gastos.isEmpty {
                        Chart(porDia.reversed(), id: \.dia) { d in
                            BarMark(x: .value("Día", d.dia, unit: .day),
                                    y: .value("Gasto", d.gastos.reduce(0) { $0 + $1.montoBase }))
                            .foregroundStyle(Color.pink.gradient)
                        }
                        .frame(height: 120)
                    }
                }
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        chip(nil, "Todos", "square.grid.2x2")
                        ForEach(ExpenseCategory.allCases) { c in
                            if trip.gastos.contains(where: { $0.categoria == c }) {
                                chip(c, c.nombre, c.icono)
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            if gastosFiltrados.isEmpty {
                ContentUnavailableView("Sin gastos", systemImage: "creditcard",
                                       description: Text("Registra lo que gastas en cualquier moneda; se convierte automáticamente a \(trip.monedaBase)."))
            }

            ForEach(porDia, id: \.dia) { grupo in
                Section {
                    ForEach(grupo.gastos) { g in
                        Button { editando = g } label: { ExpenseRow(gasto: g, trip: trip) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { idx in for i in idx { context.delete(grupo.gastos[i]) } }
                } header: {
                    HStack {
                        Text(grupo.dia.larga)
                        Spacer()
                        Text(grupo.gastos.reduce(0) { $0 + $1.montoBase }.dinero(trip.monedaBase)).monospacedDigit()
                    }
                }
            }
        }
        .navigationTitle("Gastos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { nuevo = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $nuevo) { ExpenseEditor(trip: trip, gasto: nil) }
        .sheet(item: $editando) { g in ExpenseEditor(trip: trip, gasto: g) }
    }

    private func chip(_ c: ExpenseCategory?, _ texto: String, _ icono: String) -> some View {
        Button { filtro = c } label: {
            Label(texto, systemImage: icono)
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background((filtro == c ? Color.accentColor : Color.secondary.opacity(0.15)), in: Capsule())
                .foregroundStyle(filtro == c ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

struct ExpenseRow: View {
    let gasto: Expense
    let trip: Trip

    var body: some View {
        HStack(spacing: 12) {
            IconoCategoria(icono: gasto.categoria.icono, color: gasto.categoria.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(gasto.titulo)
                if let pagador = trip.participantes.first(where: { $0.id == gasto.pagadoPorID }) {
                    Text("Pagó \(pagador.nombre)" + (gasto.compartidoEntreIDs.count > 1 ? " · entre \(gasto.compartidoEntreIDs.count)" : ""))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(gasto.montoBase.dinero(trip.monedaBase)).monospacedDigit()
                if gasto.moneda != trip.monedaBase {
                    Text(gasto.monto.dinero(gasto.moneda, decimales: true)).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

struct ExpenseEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CurrencyService.self) private var currency
    var trip: Trip
    var gasto: Expense?

    @State private var titulo = ""
    @State private var monto: Double = 0
    @State private var moneda = "USD"
    @State private var categoria: ExpenseCategory = .comida
    @State private var fecha = Date()
    @State private var pagadoPor: UUID?
    @State private var compartido: Set<UUID> = []
    @State private var notas = ""
    @State private var propina: Double = 0

    private var tasa: Double { currency.tasa(de: moneda, a: trip.monedaBase) }
    private var total: Double { monto * (1 + propina / 100) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Concepto (ej. Cena en…)", text: $titulo)
                    HStack {
                        TextField("0", value: $monto, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .font(.title.bold())
                        Picker("", selection: $moneda) {
                            ForEach(CurrencyService.monedas, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                    }
                    Picker("Agregar propina", selection: $propina) {
                        Text("Sin propina").tag(0.0)
                        Text("10 %").tag(10.0)
                        Text("15 %").tag(15.0)
                        Text("18 %").tag(18.0)
                        Text("20 %").tag(20.0)
                    }
                    if moneda != trip.monedaBase || propina > 0 {
                        LabeledContent("Equivale a", value: (total * tasa).dinero(trip.monedaBase, decimales: true))
                    }
                }
                Section {
                    Picker("Categoría", selection: $categoria) {
                        ForEach(ExpenseCategory.allCases) { Label($0.nombre, systemImage: $0.icono).tag($0) }
                    }
                    DatePicker("Fecha", selection: $fecha)
                }
                if !trip.participantes.isEmpty {
                    Section("¿Quién pagó y entre quiénes se divide?") {
                        Picker("Pagó", selection: $pagadoPor) {
                            Text("—").tag(UUID?.none)
                            ForEach(trip.participantes) { Text($0.nombre).tag(Optional($0.id)) }
                        }
                        ForEach(trip.participantes) { p in
                            Button {
                                if compartido.contains(p.id) { compartido.remove(p.id) } else { compartido.insert(p.id) }
                            } label: {
                                HStack {
                                    Text(p.nombre).foregroundStyle(.primary)
                                    Spacer()
                                    if compartido.contains(p.id) {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                                    } else {
                                        Image(systemName: "circle").foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        if !compartido.isEmpty {
                            Text("\((total * tasa / Double(compartido.count)).dinero(trip.monedaBase, decimales: true)) por persona")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Notas") {
                    TextField("Opcional", text: $notas, axis: .vertical)
                }
            }
            .navigationTitle(gasto == nil ? "Nuevo gasto" : "Editar gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }.disabled(titulo.isEmpty || monto <= 0)
                }
            }
            .onAppear(perform: cargar)
        }
    }

    private func cargar() {
        if let g = gasto {
            titulo = g.titulo; monto = g.monto; moneda = g.moneda; categoria = g.categoria
            fecha = g.fecha; pagadoPor = g.pagadoPorID; compartido = Set(g.compartidoEntreIDs); notas = g.notas
        } else {
            moneda = trip.estado == .enCurso ? trip.monedaLocal : trip.monedaBase
            pagadoPor = trip.participantes.first?.id
            compartido = Set(trip.participantes.map(\.id))
            if trip.estado == .enCurso { fecha = Date() } else { fecha = trip.fechaInicio }
        }
    }

    private func guardar() {
        let g = gasto ?? Expense(titulo: titulo, monto: total, moneda: moneda, tasaABase: tasa, categoria: categoria, fecha: fecha)
        g.titulo = titulo
        g.monto = total
        g.moneda = moneda
        // Conserva la tasa original si no cambió la moneda al editar.
        if gasto == nil || gasto?.moneda != moneda || propina > 0 { g.tasaABase = tasa }
        g.categoria = categoria
        g.fecha = fecha
        g.pagadoPorID = pagadoPor
        g.compartidoEntreIDs = Array(compartido)
        g.notas = notas
        if gasto == nil { trip.gastos.append(g) }
        dismiss()
    }
}

// MARK: - Dividir cuentas

struct SplitView: View {
    @Bindable var trip: Trip

    struct Transferencia: Identifiable {
        let id = UUID()
        let de: String
        let a: String
        let monto: Double
    }

    struct Saldo: Identifiable {
        let persona: Traveler
        let saldo: Double
        var id: UUID { persona.id }
    }

    /// Balance de cada participante: positivo = le deben, negativo = debe.
    private var balances: [Saldo] {
        var b: [UUID: Double] = [:]
        for g in trip.gastos {
            guard let pagador = g.pagadoPorID else { continue }
            let entre = g.compartidoEntreIDs.isEmpty ? trip.participantes.map(\.id) : g.compartidoEntreIDs
            guard !entre.isEmpty else { continue }
            b[pagador, default: 0] += g.montoBase
            let parte = g.montoBase / Double(entre.count)
            for id in entre { b[id, default: 0] -= parte }
        }
        return trip.participantes.map { Saldo(persona: $0, saldo: b[$0.id] ?? 0) }
    }

    private func pagadoPor(_ t: Traveler) -> Double {
        trip.gastos.filter { $0.pagadoPorID == t.id }.reduce(0) { $0 + $1.montoBase }
    }

    /// Algoritmo greedy: minimiza el número de transferencias.
    private var transferencias: [Transferencia] {
        var deudores = balances.filter { $0.saldo < -0.01 }.map { ($0.persona.nombre, -$0.saldo) }
        var acreedores = balances.filter { $0.saldo > 0.01 }.map { ($0.persona.nombre, $0.saldo) }
        deudores.sort { $0.1 > $1.1 }
        acreedores.sort { $0.1 > $1.1 }
        var res: [Transferencia] = []
        var i = 0, j = 0
        while i < deudores.count && j < acreedores.count {
            let m = min(deudores[i].1, acreedores[j].1)
            res.append(.init(de: deudores[i].0, a: acreedores[j].0, monto: m))
            deudores[i].1 -= m
            acreedores[j].1 -= m
            if deudores[i].1 < 0.01 { i += 1 }
            if acreedores[j].1 < 0.01 { j += 1 }
        }
        return res
    }

    var body: some View {
        List {
            if trip.participantes.count < 2 {
                ContentUnavailableView("Agrega participantes", systemImage: "person.2",
                                       description: Text("Desde “Editar” en el viaje puedes agregar a tus acompañantes para dividir gastos."))
            } else {
                Section("Balance") {
                    ForEach(balances) { item in
                        let p = item.persona
                        let saldo = item.saldo
                        HStack {
                            Image(systemName: "person.crop.circle.fill").font(.title2).foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(p.nombre)
                                Text("Pagó \(pagadoPor(p).dinero(trip.monedaBase))").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(saldo >= 0 ? "+\(saldo.dinero(trip.monedaBase))" : saldo.dinero(trip.monedaBase))
                                .monospacedDigit()
                                .foregroundStyle(saldo >= 0 ? .green : .red)
                        }
                    }
                }
                Section("Para quedar a mano") {
                    if transferencias.isEmpty {
                        Label("¡Todos están a mano!", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    }
                    ForEach(transferencias) { t in
                        HStack {
                            Text(t.de).bold()
                            Image(systemName: "arrow.right")
                            Text(t.a).bold()
                            Spacer()
                            Text(t.monto.dinero(trip.monedaBase, decimales: true)).monospacedDigit()
                        }
                    }
                }
                if !transferencias.isEmpty {
                    Section {
                        ShareLink(item: resumenTexto) { Label("Compartir resumen", systemImage: "square.and.arrow.up") }
                    }
                }
            }
        }
        .navigationTitle("Dividir cuentas")
    }

    private var resumenTexto: String {
        var s = "💸 Cuentas de \(trip.nombre)\nTotal: \(trip.totalGastado.dinero(trip.monedaBase))\n\n"
        for t in transferencias {
            s += "• \(t.de) → \(t.a): \(t.monto.dinero(trip.monedaBase, decimales: true))\n"
        }
        return s
    }
}
