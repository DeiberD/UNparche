# Historias de Usuario - Ciclo de Vida y Notificaciones

## HU-36 · Eliminación automática de eventos finalizados

**Prioridad:** Must Have  
**RF/RNF relacionados:** RNF-10

> Como usuario comunitario, quiero que los eventos finalizados se eliminen automáticamente después del tiempo definido, para mantener actualizada la información visible en la aplicación.

### Criterios de aceptación

- **Dado** que un evento finalizó, **cuando** transcurren 24 horas desde su hora de fin, **entonces** el sistema lo elimina automáticamente de las vistas activas.
- **Dado** que un evento aún no ha cumplido 24 horas desde su finalización, **cuando** consulto las vistas correspondientes, **entonces** el sistema puede conservarlo según la lógica definida.
- **Dado** que un evento fue eliminado por ciclo de vida, **cuando** consulto el mapa o la lista de eventos activos, **entonces** ya no aparece como evento disponible.
- **Dado** que el evento tenía chat asociado, **cuando** se elimina del ciclo activo, **entonces** el chat deja de estar disponible para nuevas interacciones.

---

> Este módulo cubre el comportamiento automático del sistema asociado a la transición de estados del evento: `Programado → En_curso → Finalizado → Eliminado`. Para más detalle sobre las reglas que gobiernan estas transiciones, ver [Reglas de Negocio](../domain/reglas-negocio.md) (RN-07, RN-08, RN-09) y [Conceptos del Sistema](../domain/conceptos.md) (Ciclo de Vida del Evento).