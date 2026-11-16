import SwiftUI
import MapKit

struct TripMapView: View {
    let trip: Trip
    @State private var posicion: MapCameraPosition = .automatic
    @State private var seleccion: ItineraryItem?

    private var conUbicacion: [ItineraryItem] {
        trip.itinerario.filter { $0.latitud != nil && $0.longitud != nil }.sorted { $0.hora < $1.hora }
    }

    var body: some View {
        Map(position: $posicion) {
            if trip.latitud != 0 || trip.longitud != 0 {
                Marker(trip.destinoNombre, systemImage: "star.fill",
                       coordinate: CLLocationCoordinate2D(latitude: trip.latitud, longitude: trip.longitud))
                    .tint(.red)
            }
            ForEach(conUbicacion) { item in
                Annotation(item.titulo, coordinate: CLLocationCoordinate2D(latitude: item.latitud!, longitude: item.longitud!)) {
                    IconoCategoria(icono: item.categoria.icono, color: item.categoria.color, tamano: 28)
                        .onTapGesture { seleccion = item }
                }
            }
            if conUbicacion.count > 1 {
                MapPolyline(coordinates: conUbicacion.map { CLLocationCoordinate2D(latitude: $0.latitud!, longitude: $0.longitud!) })
                    .stroke(.blue.opacity(0.5), lineWidth: 3)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .bottom) {
            if let s = seleccion {
                HStack {
                    VStack(alignment: .leading) {
                        Text(s.titulo).font(.headline)
                        Text("\(s.dia.larga) · \(s.hora.hora)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: s.latitud!, longitude: s.longitud!)))
                        item.name = s.titulo
                        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit])
                    } label: {
                        Label("Cómo llegar", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding()
            } else if conUbicacion.isEmpty {
                Text("Agrega lugares a tus actividades del itinerario para verlos aquí.")
                    .font(.footnote)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding()
            }
        }
        .navigationTitle("Mapa")
        .navigationBarTitleDisplayMode(.inline)
    }
}
