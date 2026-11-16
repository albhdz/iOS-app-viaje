import Foundation
import UserNotifications

/// Recordatorios locales: tareas del checklist y cuenta regresiva del viaje.
enum NotificationService {

    static func solicitarPermiso() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func programar(para trip: Trip) {
        guard UserDefaults.standard.bool(forKey: Ajustes.claveRecordatorios) else { return }
        cancelar(para: trip)
        let center = UNUserNotificationCenter.current()
        let cal = Calendar.current

        func agendar(id: String, titulo: String, cuerpo: String, fecha: Date) {
            guard fecha > Date() else { return }
            let content = UNMutableNotificationContent()
            content.title = titulo
            content.body = cuerpo
            content.sound = .default
            var comps = cal.dateComponents([.year, .month, .day], from: fecha)
            comps.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }

        let prefijo = trip.id.uuidString
        // Agrupar tareas por día para no saturar.
        let pendientes = Dictionary(grouping: trip.checklist.filter { !$0.hecho }) { $0.diasAntes }
        for (dias, items) in pendientes {
            guard let fecha = cal.date(byAdding: .day, value: -dias, to: trip.fechaInicio) else { continue }
            let lista = items.prefix(3).map(\.titulo).joined(separator: ", ")
            agendar(id: "\(prefijo)-check-\(dias)",
                    titulo: "\(trip.emoji) \(trip.nombre): \(items.count) pendiente(s)",
                    cuerpo: lista, fecha: fecha)
        }
        for d in [30, 7, 1] {
            if let fecha = cal.date(byAdding: .day, value: -d, to: trip.fechaInicio) {
                agendar(id: "\(prefijo)-cuenta-\(d)",
                        titulo: "\(trip.emoji) ¡Faltan \(d) día(s)!",
                        cuerpo: "Tu viaje a \(trip.destinoNombre) se acerca. Revisa equipaje y documentos.",
                        fecha: fecha)
            }
        }
    }

    static func cancelar(para trip: Trip) {
        let prefijo = trip.id.uuidString
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            let ids = reqs.map(\.identifier).filter { $0.hasPrefix(prefijo) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
