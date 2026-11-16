# ✈️ Viaje: planeador de viajes para iOS

App nativa para iPhone y iPad (SwiftUI + SwiftData, iOS 17+) para planear un viaje completo, **con el costo de todo**.

## Qué incluye

Antes de escribir la app revisé qué ofrecen los planeadores más usados (Wanderlog, TripIt, Stippl, Splitwise, TravelSpend, PackPoint) y junté lo mejor de cada uno. El punto débil de casi todos es el **presupuesto**, así que la app gira alrededor de los costos.

| Función | Inspirada en | Qué hace |
|---|---|---|
| **Estimador de costo total** | Budget Your Trip / calculadoras | Calcula vuelo, hospedaje, comida, transporte, actividades, seguro, visa/ETA, eSIM, propinas, souvenirs, botiquín y colchón para imprevistos |
| **Catálogo de 45 destinos** | Guías de presupuesto 2026 | Costo diario por persona en 5 estilos (mochilero → lujo), mejor época, enchufe, idioma, propinas e imperdibles con precio |
| **Itinerario día por día** | Wanderlog | Actividades con hora, duración, lugar (búsqueda MapKit), costo y "imperdibles" que se agregan con un toque |
| **Mapa del viaje** | Wanderlog | Todos los lugares en el mapa, la ruta del día y "Cómo llegar" con Apple Maps |
| **Reservaciones** | TripIt | Vuelos, hoteles, autos, trenes, tours con código de confirmación, fecha límite de cancelación gratuita, estado de pago y enlace |
| **Gastos reales en cualquier moneda** | TravelSpend | Conversión automática con tasas en línea, propina rápida y gráfica de gasto por día |
| **Dividir cuentas** | Splitwise | Quién pagó, entre quiénes se divide, saldos y el mínimo de transferencias para quedar a mano (se puede compartir) |
| **Presupuesto vs. gastado** | Stippl | Gráfica de dona por categoría, barras de avance, partidas editables, tope personal y cuánto puedes gastar por día |
| **Plan de ahorro** | — | Cuánto ahorrar por mes o por semana para llegar a la meta antes de salir |
| **Equipaje inteligente** | PackPoint | Lista generada según el tipo de viaje (playa, nieve, montaña, negocios…), los días y si el viaje es internacional |
| **Checklist con fechas** | — | Tareas de 3 meses antes, 1 mes, 1 semana, el día anterior y el día de salida, con recordatorios locales |
| **Herramientas** | — | Convertidor de divisas, calculadora de propinas, **comparador de destinos por costo total**, guías de ahorro, costos ocultos y reglas de equipaje |

## Cómo se calculan los costos

- **Vuelos**: distancia real desde tu ciudad de salida (22 ciudades de origen) con un modelo por tramos de distancia, ajustado por temporada (alta +25 %) y anticipación de compra (menos de 14 días: +45 %). Suma maleta documentada, cargos extra y traslados al aeropuerto.
- **En destino**: costo diario por persona por destino (hospedaje en habitación doble, comida, transporte y actividades), escalado por estilo de viaje. Si viajas solo, el hospedaje se ajusta a habitación individual.
- **Extras que casi nadie presupuesta**: impuestos y tasas de hospedaje (≈12 %), visa o autorización electrónica (ESTA, eTA, ETIAS, ETA UK…), seguro (≈5 % del costo prepagado), eSIM, propinas según el país, vacunas en las regiones que las piden y un colchón configurable (10 % por defecto).
- **Tipos de cambio**: se actualizan desde `open.er-api.com` (gratis, sin API key), con tasas de respaldo integradas para usar la app sin conexión.

> Los precios son estimaciones 2026 a partir de promedios públicos. Todas las partidas se pueden editar con tus cotizaciones reales.

## Cómo abrirla

1. Abre `Viaje.xcodeproj` en **Xcode 16 o posterior**.
2. En *Signing & Capabilities* elige tu equipo y cambia el bundle id (`com.example.viaje`).
3. Corre en el simulador o en tu iPhone (⌘R).

Si tienes una versión anterior de Xcode, genera el proyecto con [XcodeGen](https://github.com/yonaskolb/XcodeGen): `xcodegen` (usa `project.yml`).

## Estructura

```
Viaje/
├── App/ViajeApp.swift              # Entrada, pestañas y preferencias
├── Models/                         # SwiftData: Trip, BudgetLine, ItineraryItem, Expense, Booking…
├── Data/DestinationCatalog.swift   # 45 destinos + 22 ciudades de origen con costos
├── Data/Templates.swift            # Plantillas de equipaje y checklist
├── Services/CostEstimator.swift    # Motor de estimación de costos
├── Services/CurrencyService.swift  # Tipos de cambio y formato de dinero
├── Services/TripFactory.swift      # Crea el viaje con presupuesto, listas e itinerario base
├── Services/NotificationService.swift
└── Views/                          # Mis viajes, detalle del viaje, Explorar, Herramientas, Ajustes
```
