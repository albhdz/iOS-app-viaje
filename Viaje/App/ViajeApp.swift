import SwiftUI
import SwiftData

@main
struct ViajeApp: App {
    @State private var currency = CurrencyService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(currency)
                .task { await currency.actualizarSiEsNecesario() }
        }
        .modelContainer(for: [
            Trip.self, BudgetLine.self, ItineraryItem.self, Expense.self,
            Booking.self, PackingItem.self, ChecklistItem.self, Traveler.self,
        ])
    }
}

struct RootView: View {
    @AppStorage(Ajustes.claveTab) private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TripsListView()
                .tabItem { Label("Mis viajes", systemImage: "suitcase.rolling.fill") }
                .tag(0)
            ExploreView()
                .tabItem { Label("Explorar", systemImage: "globe.americas.fill") }
                .tag(1)
            ToolsView()
                .tabItem { Label("Herramientas", systemImage: "wrench.and.screwdriver.fill") }
                .tag(2)
            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
                .tag(3)
        }
    }
}

/// Claves de preferencias del usuario.
enum Ajustes {
    static let claveTab = "tabSeleccionada"
    static let claveMoneda = "monedaBase"
    static let claveOrigen = "ciudadOrigen"
    static let claveRecordatorios = "recordatoriosActivos"

    static var monedaBase: String { UserDefaults.standard.string(forKey: claveMoneda) ?? "MXN" }
    static var origen: OriginCity? {
        let nombre = UserDefaults.standard.string(forKey: claveOrigen) ?? "Ciudad de México"
        return DestinationCatalog.origenes.first { $0.nombre == nombre }
    }
}
