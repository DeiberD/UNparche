# Historias de Usuario - Vista de Lista de Eventos

## HU-13 · Consulta de eventos en vista de lista

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-21, RF-23

> Como usuario comunitario, quiero consultar los eventos en una vista de lista, para revisar actividades disponibles sin depender únicamente del mapa.

### Criterios de aceptación

- **Dado** que ingreso a la vista de lista, **cuando** existen eventos públicos disponibles, **entonces** se muestran ordenados por fecha de inicio ascendente.
- **Dado** que se publica un nuevo evento público, **cuando** consulto la lista, **entonces** el evento aparece automáticamente en la vista correspondiente.
- **Dado** que no existen eventos disponibles, **cuando** ingreso a la lista, **entonces** el sistema muestra un mensaje de estado vacío.
- **Dado** que selecciono un evento desde la lista, **cuando** pulso sobre él, **entonces** se abre su información detallada.
- **Dado** que visualizo la información detallada de un evento, **cuando** pulso en su ubicación, **entonces** se abre la ubicación en la vista de mapa.

---

## HU-14 · Filtrado de eventos en lista

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-22

> Como usuario comunitario, quiero usar en la lista los mismos filtros disponibles en el mapa, para buscar eventos de forma consistente en ambas vistas.

### Criterios de aceptación

- **Dado** que estoy en la vista de lista, **cuando** filtro por fecha, **entonces** se muestran solo los eventos correspondientes a esa fecha.
- **Dado** que filtro por categoría o tipo, **cuando** aplico el filtro, **entonces** la lista se actualiza con los eventos que cumplen el criterio.
- **Dado** que filtro por grupo organizador, **cuando** selecciono un grupo, **entonces** se muestran únicamente sus eventos visibles.
- **Dado** que cambio entre mapa y lista, **cuando** hay filtros activos, **entonces** la lógica de filtrado se mantiene de forma coherente.