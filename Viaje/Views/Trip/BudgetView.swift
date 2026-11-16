import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: Trip
    @State private var editando: BudgetLine?
    @State private var nueva = false

    private struct ResumenCategoria: Identifiable {
        let cat: ExpenseCategory
        let estimado: Double
        let gastado: Double
        var id: ExpenseCategory { cat }
    }

    private var categoriasConDatos: [ResumenCategoria] {
        ExpenseCategory.allCases.compactMap { c in
            let e = trip.estimado(de: c), g = trip.gastado(en: c)
            return (e > 0 || g > 0) ? ResumenCategoria(cat: c, estimado: e, gastado: g) : nil
        }
    }

    var body: some View {
        List {
            Section { resumen }

            Section("Distribución estimada") {
                Chart(categoriasConDatos) { item in
                    SectorMark(angle: .value("Monto", item.estimado), innerRadius: .ratio(0.6), angularInset: 1.5)
                        .foregroundStyle(item.cat.color)
                        .cornerRadius(3)
                }
                .chartBackground { _ in
                    VStack {
                        Text("Total").font(.caption).foregroundStyle(.secondary)
                        Text(trip.totalEstimado.dinero(trip.monedaBase)).font(.headline).monospacedDigit()
                    }
                }
                .frame(height: 220)
                .padding(.vertical)
            }

            Section("Estimado vs. gastado") {
                ForEach(categoriasConDatos) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            IconoCategoria(icono: item.cat.icono, color: item.cat.color, tamano: 26)
                            Text(item.cat.nombre).font(.subheadline)
                            Spacer()
                            Text("\(item.gastado.dinero(trip.monedaBase)) / \(item.estimado.dinero(trip.monedaBase))")
                                .font(.caption).monospacedDigit()
                                .foregroundStyle(item.gastado > item.estimado && item.estimado > 0 ? .red : .secondary)
                        }
                        BarraPresupuesto(gastado: item.gastado, total: item.estimado, color: item.cat.color)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section {
                ForEach(ExpenseCategory.allCases) { cat in
                    let lineas = trip.lineasPresupuesto.filter { $0.categoria == cat }
                    ForEach(lineas) { linea in
                        Button { editando = linea } label: {
                            HStack {
                                Image(systemName: cat.icono).foregroundStyle(cat.color).frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(linea.concepto).foregroundStyle(.primary)
                                    if !linea.detalle.isEmpty {
                                        Text(linea.detalle).font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(linea.monto.dinero(trip.monedaBase)).monospacedDigit().foregroundStyle(.primary)
                            }
                        }
                    }
                    .onDelete { idx in
                        for i in idx { context.delete(lineas[i]) }
                    }
                }
                Button { nueva = true } label: { Label("Agregar partida", systemImage: "plus") }
            } header: {
                Text("Partidas del presupuesto")
            } footer: {
                Text("Toca una partida para ajustar el monto con tus cotizaciones reales.")
            }

            Section("Colchón e imprevistos") {
                Stepper("Colchón: \(Int(trip.colchonPorcentaje)) %", value: $trip.colchonPorcentaje, in: 0...30, step: 5)
                LabeledContent("Monto del colchón", value: trip.colchon.dinero(trip.monedaBase))
            }

            Section {
                CampoMonto(titulo: "Presupuesto objetivo", monto: $trip.presupuestoObjetivo, moneda: trip.monedaBase)
            } header: {
                Text("Tope personal")
            } footer: {
                Text("Déjalo en 0 para usar el estimado + colchón (\((trip.totalEstimado + trip.colchon).dinero(trip.monedaBase))).")
            }

            Section("Plan de ahorro") {
                CampoMonto(titulo: "Ya ahorrado", monto: $trip.ahorrado, moneda: trip.monedaBase)
                ProgressView(value: min(trip.ahorrado, trip.presupuesto), total: max(trip.presupuesto, 1))
                    .tint(.pink)
                LabeledContent("Falta", value: trip.faltaPorAhorrar.dinero(trip.monedaBase))
                if trip.estado == .proximo {
                    LabeledContent("Ahorro mensual necesario", value: trip.ahorroMensualNecesario.dinero(trip.monedaBase))
                    LabeledContent("Ahorro semanal necesario", value: (trip.faltaPorAhorrar / max(1, Double(trip.diasRestantes) / 7)).dinero(trip.monedaBase))
                }
            }
        }
        .navigationTitle("Presupuesto")
        .sheet(item: $editando) { linea in EditBudgetLineView(linea: linea, moneda: trip.monedaBase) }
        .sheet(isPresented: $nueva) { NewBudgetLineView(trip: trip) }
    }

    private var resumen: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                ZStack {
                    ProgressRing(progreso: trip.presupuesto > 0 ? trip.totalGastado / trip.presupuesto : 0,
                                 color: trip.restante >= 0 ? .green : .red, grosor: 12)
                    VStack(spacing: 0) {
                        Text("\(Int(trip.presupuesto > 0 ? trip.totalGastado / trip.presupuesto * 100 : 0)) %")
                            .font(.title3.bold())
                        Text("gastado").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent("Presupuesto", value: trip.presupuesto.dinero(trip.monedaBase))
                    LabeledContent("Gastado", value: trip.totalGastado.dinero(trip.monedaBase))
                    LabeledContent(trip.restante >= 0 ? "Disponible" : "Excedido", value: abs(trip.restante).dinero(trip.monedaBase))
                        .foregroundStyle(trip.restante >= 0 ? Color.primary : Color.red)
                }
                .font(.subheadline)
                .monospacedDigit()
            }
            HStack {
                StatCard(titulo: "Por persona", valor: trip.costoPorPersona.dinero(trip.monedaBase), icono: "person")
                StatCard(titulo: "Por día", valor: trip.costoPorDia.dinero(trip.monedaBase), icono: "sun.max")
            }
            if trip.estado == .enCurso {
                let diasRest = max(1, (Calendar.current.dateComponents([.day], from: Date().inicioDelDia, to: trip.fechaFin.inicioDelDia).day ?? 0) + 1)
                Text("Puedes gastar \((max(0, trip.restante) / Double(diasRest)).dinero(trip.monedaBase)) por día el resto del viaje.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct EditBudgetLineView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var linea: BudgetLine
    var moneda: String

    var body: some View {
        NavigationStack {
            Form {
                TextField("Concepto", text: $linea.concepto)
                Picker("Categoría", selection: $linea.categoria) {
                    ForEach(ExpenseCategory.allCases) { Label($0.nombre, systemImage: $0.icono).tag($0) }
                }
                CampoMonto(titulo: "Monto", monto: $linea.monto, moneda: moneda)
                TextField("Detalle", text: $linea.detalle, axis: .vertical)
            }
            .navigationTitle("Partida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

struct NewBudgetLineView: View {
    @Environment(\.dismiss) private var dismiss
    var trip: Trip
    @State private var concepto = ""
    @State private var categoria: ExpenseCategory = .otros
    @State private var monto: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Concepto", text: $concepto)
                Picker("Categoría", selection: $categoria) {
                    ForEach(ExpenseCategory.allCases) { Label($0.nombre, systemImage: $0.icono).tag($0) }
                }
                CampoMonto(titulo: "Monto", monto: $monto, moneda: trip.monedaBase)
            }
            .navigationTitle("Nueva partida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agregar") {
                        trip.lineasPresupuesto.append(BudgetLine(categoria: categoria, concepto: concepto, monto: monto))
                        dismiss()
                    }
                    .disabled(concepto.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
