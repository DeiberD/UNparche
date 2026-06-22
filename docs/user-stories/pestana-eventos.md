# Historias de Usuario - Pestaña de Eventos

## HU-23 · Calendario de eventos confirmados

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-38

> Como usuario comunitario, quiero ver en calendario los eventos a los que confirmé asistencia, para organizar mi participación en actividades del campus.

### Criterios de aceptación

- **Dado** que confirmé asistencia a uno o más eventos, **cuando** ingreso a la pestaña de eventos, **entonces** los veo organizados en vista de calendario.
- **Dado** que selecciono un evento en el calendario, **cuando** pulso sobre él, **entonces** se abre su ficha de información.
- **Dado** que cancelo mi asistencia, **cuando** vuelvo al calendario, **entonces** el evento deja de aparecer en mis eventos confirmados.
- **Dado** que no tengo eventos confirmados, **cuando** ingreso al calendario, **entonces** el sistema muestra un mensaje de estado vacío.

---

## HU-24 · Historial de eventos asistidos

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-39

> Como usuario comunitario, quiero consultar un historial de eventos pasados a los que asistí, para recordar actividades en las que participé.

### Criterios de aceptación

- **Dado** que asistí a eventos pasados, **cuando** ingreso al historial, **entonces** se muestran con su nombre e información básica.
- **Dado** que no tengo eventos pasados registrados, **cuando** consulto el historial, **entonces** el sistema muestra un mensaje indicando que no hay registros.
- **Dado** que selecciono un evento pasado, **cuando** abro su detalle, **entonces** puedo consultar la información disponible del evento.
- **Dado** que un evento fue eliminado por ciclo de vida, **cuando** se muestra en historial, **entonces** se conserva la información mínima necesaria para identificarlo si aplica.

---

## HU-25 · Lista de eventos creados por el usuario

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-40

> Como organizador, quiero ver la lista de eventos que he creado, para gestionar mis eventos pasados, en curso y programados.

### Criterios de aceptación

- **Dado** que he creado eventos, **cuando** ingreso a la sección de mis eventos, **entonces** se muestran clasificados como pasados, en curso o programados.
- **Dado** que selecciono un evento propio programado, **cuando** se abre su ficha, **entonces** veo opciones de gestión disponibles.
- **Dado** que no he creado eventos, **cuando** ingreso a la sección, **entonces** el sistema muestra un mensaje de estado vacío.
- **Dado** que un evento cambia de estado por fecha y hora, **cuando** consulto la lista, **entonces** aparece en la categoría correspondiente.

---

## HU-26 · Gestión de eventos propios

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-41, RF-42

> Como organizador, quiero editar, cancelar, eliminar, duplicar o reagendar mis eventos, para mantener actualizada la información publicada.

### Criterios de aceptación

- **Dado** que tengo un evento futuro, **cuando** ingreso a su gestión, **entonces** puedo editarlo o cancelarlo.
- **Dado** que tengo un evento pasado, **cuando** ingreso a su gestión, **entonces** puedo eliminarlo, duplicarlo o reagendarlo según corresponda.
- **Dado** que modifico un evento propio, **cuando** guardo los cambios, **entonces** la información actualizada se refleja en el mapa, lista y ficha del evento.
- **Dado** que cancelo un evento, **cuando** los usuarios tenían notificaciones activas, **entonces** se les notifica la cancelación.