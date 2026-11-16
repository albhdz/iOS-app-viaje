import SwiftUI

struct SettingsView: View {
    @Environment(CurrencyService.self) private var currency
    @AppStorage(Ajustes.claveMoneda) private var moneda = "MXN"
    @AppStorage(Ajustes.claveOrigen) private var origen = "Ciudad de México"
    @AppStorage(Ajustes.claveRecordatorios) private var recordatorios = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SelectorMoneda(titulo: "Mi moneda", moneda: $moneda)
                    Picker("Ciudad de salida", selection: $origen) {
                        ForEach(DestinationCatalog.origenes) { Text($0.nombre).tag($0.nombre) }
                    }
                } header: {
                    Text("Preferencias")
                } footer: {
                    Text("Se usan para mostrar precios y calcular el costo de los vuelos.")
                }

                Section {
                    Toggle("Recordatorios del checklist", isOn: $recordatorios)
                        .onChange(of: recordatorios) { _, activo in
                            if activo {
                                Task {
                                    let ok = await NotificationService.solicitarPermiso()
                                    if !ok { recordatorios = false }
                                }
                            }
                        }
                } footer: {
                    Text("Te avisamos cuándo comprar vuelos, contratar seguro, instalar la eSIM y más, además de la cuenta regresiva.")
                }

                Section("Tipos de cambio") {
                    Button {
                        Task { await currency.actualizar() }
                    } label: {
                        HStack {
                            Label("Actualizar ahora", systemImage: "arrow.clockwise")
                            if currency.actualizando { Spacer(); ProgressView() }
                        }
                    }
                    if let f = currency.ultimaActualizacion {
                        LabeledContent("Actualizado", value: f.formatted(date: .abbreviated, time: .shortened))
                    } else {
                        Text("Usando tasas de referencia integradas").font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("Los costos son estimaciones 2026 basadas en promedios públicos por destino (índices de costo de viaje y guías de presupuesto). Los precios reales varían por temporada, anticipación y disponibilidad. Ajusta cada partida con tus cotizaciones.")
                        .font(.footnote)
                    Text("Requisitos de visa: asumen pasaporte latinoamericano. Verifica siempre en el sitio oficial del país de destino.")
                        .font(.footnote)
                } header: {
                    Text("Acerca de los precios")
                }

                Section {
                    LabeledContent("Versión", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
