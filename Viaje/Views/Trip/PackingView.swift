import SwiftUI
import SwiftData

struct PackingView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: Trip
    @State private var nuevoNombre = ""
    @State private var nuevoGrupo = "General"
    @State private var ocultarEmpacados = false

    private var grupos: [String] {
        Array(Set(trip.equipaje.map(\.grupo))).sorted()
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        ProgressRing(progreso: trip.progresoEquipaje, color: .brown)
                        Text("\(Int(trip.progresoEquipaje * 100)) %").font(.caption.bold())
                    }
                    .frame(width: 56, height: 56)
                    VStack(alignment: .leading) {
                        Text("\(trip.equipaje.filter(\.empacado).count) de \(trip.equipaje.count) artículos")
                            .font(.headline)
                        Toggle("Ocultar empacados", isOn: $ocultarEmpacados).font(.caption)
                    }
                }
            }
            Section("Agregar artículo") {
                TextField("Artículo", text: $nuevoNombre)
                Picker("Grupo", selection: $nuevoGrupo) {
                    ForEach(Array(Set(grupos + ["General"])).sorted(), id: \.self) { Text($0).tag($0) }
                }
                Button("Agregar") {
                    trip.equipaje.append(PackingItem(nombre: nuevoNombre, grupo: nuevoGrupo))
                    nuevoNombre = ""
                }
                .disabled(nuevoNombre.isEmpty)
            }
            ForEach(grupos, id: \.self) { grupo in
                let items = trip.equipaje
                    .filter { $0.grupo == grupo && (!ocultarEmpacados || !$0.empacado) }
                    .sorted { $0.nombre < $1.nombre }
                if !items.isEmpty {
                    Section(grupo) {
                        ForEach(items) { item in
                            Button { item.empacado.toggle() } label: {
                                HStack {
                                    Image(systemName: item.empacado ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.empacado ? Color.green : Color.secondary)
                                        .font(.title3)
                                    Text(item.nombre)
                                        .strikethrough(item.empacado)
                                        .foregroundStyle(item.empacado ? .secondary : .primary)
                                    Spacer()
                                    if item.cantidad > 1 {
                                        Text("×\(item.cantidad)").foregroundStyle(.secondary).monospacedDigit()
                                    }
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button { item.cantidad += 1 } label: { Label("+1", systemImage: "plus") }.tint(.blue)
                            }
                        }
                        .onDelete { idx in for i in idx { context.delete(items[i]) } }
                    }
                }
            }
        }
        .navigationTitle("Equipaje")
        .toolbar {
            Menu {
                Button("Marcar todo como empacado") { trip.equipaje.forEach { $0.empacado = true } }
                Button("Desmarcar todo") { trip.equipaje.forEach { $0.empacado = false } }
            } label: { Image(systemName: "ellipsis.circle") }
        }
    }
}

struct ChecklistView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trip: Trip
    @State private var nuevo = ""

    private var secciones: [String] {
        let existentes = Set(trip.checklist.map(\.seccion))
        return Templates.ordenSecciones.filter { existentes.contains($0) }
            + existentes.subtracting(Templates.ordenSecciones).sorted()
    }

    var body: some View {
        List {
            Section {
                ProgressView(value: trip.progresoChecklist) {
                    Text("\(trip.checklist.filter(\.hecho).count) de \(trip.checklist.count) tareas")
                }
                .tint(.indigo)
                HStack {
                    TextField("Nueva tarea", text: $nuevo)
                    Button("Agregar") {
                        trip.checklist.append(ChecklistItem(titulo: nuevo, seccion: "General", diasAntes: 0))
                        nuevo = ""
                    }.disabled(nuevo.isEmpty)
                }
            }
            ForEach(secciones, id: \.self) { seccion in
                let items = trip.checklist.filter { $0.seccion == seccion }.sorted { $0.diasAntes > $1.diasAntes }
                Section(seccion) {
                    ForEach(items) { item in
                        Button { item.hecho.toggle() } label: { fila(item) }
                    }
                    .onDelete { idx in for i in idx { context.delete(items[i]) } }
                }
            }
        }
        .navigationTitle("Checklist")
        .onDisappear { NotificationService.programar(para: trip) }
    }

    private func fila(_ item: ChecklistItem) -> some View {
        let limite = Calendar.current.date(byAdding: .day, value: -item.diasAntes, to: trip.fechaInicio) ?? trip.fechaInicio
        let vencida = !item.hecho && limite < Date().inicioDelDia
        return HStack(alignment: .top) {
            Image(systemName: item.hecho ? "checkmark.square.fill" : "square")
                .foregroundStyle(item.hecho ? Color.indigo : Color.secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.titulo)
                    .strikethrough(item.hecho)
                    .foregroundStyle(item.hecho ? .secondary : .primary)
                if !item.nota.isEmpty {
                    Text(item.nota).font(.caption).foregroundStyle(.secondary)
                }
                if item.seccion != "General" {
                    Text(vencida ? "Vencida · \(limite.corta)" : "Antes del \(limite.corta)")
                        .font(.caption2.bold())
                        .foregroundStyle(vencida ? .red : .secondary)
                }
            }
        }
    }
}
