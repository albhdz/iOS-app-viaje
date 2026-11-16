import SwiftUI

/// Anillo de progreso circular.
struct ProgressRing: View {
    var progreso: Double
    var color: Color = .accentColor
    var grosor: CGFloat = 8

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: grosor)
            Circle()
                .trim(from: 0, to: min(max(progreso, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: grosor, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progreso)
        }
    }
}

/// Tarjeta pequeña de estadística.
struct StatCard: View {
    var titulo: String
    var valor: String
    var icono: String
    var color: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(titulo, systemImage: icono)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(valor)
                .font(.headline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Barra horizontal de avance (gastado vs estimado).
struct BarraPresupuesto: View {
    var gastado: Double
    var total: Double
    var color: Color = .accentColor

    private var fraccion: Double { total > 0 ? gastado / total : 0 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(fraccion > 1 ? Color.red : color)
                    .frame(width: geo.size.width * min(fraccion, 1))
            }
        }
        .frame(height: 6)
    }
}

/// Icono redondeado de categoría.
struct IconoCategoria: View {
    var icono: String
    var color: Color
    var tamano: CGFloat = 32

    var body: some View {
        Image(systemName: icono)
            .font(.system(size: tamano * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: tamano, height: tamano)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: tamano * 0.28))
    }
}

/// Campo para capturar montos.
struct CampoMonto: View {
    var titulo: String
    @Binding var monto: Double
    var moneda: String

    var body: some View {
        HStack {
            Text(titulo)
            Spacer()
            TextField("0", value: $monto, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
            Text(moneda).foregroundStyle(.secondary)
        }
    }
}

/// Selector de moneda.
struct SelectorMoneda: View {
    var titulo: String = "Moneda"
    @Binding var moneda: String

    var body: some View {
        Picker(titulo, selection: $moneda) {
            ForEach(CurrencyService.monedas, id: \.self) { m in
                Text("\(m) · \(CurrencyService.nombres[m] ?? m)").tag(m)
            }
        }
    }
}

extension Date {
    var corta: String { formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "es_MX"))) }
    var larga: String { formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "es_MX"))).capitalized }
    var hora: String { formatted(.dateTime.hour().minute().locale(Locale(identifier: "es_MX"))) }
}
