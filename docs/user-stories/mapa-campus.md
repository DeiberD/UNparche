# Historias de Usuario - Mapa del Campus

## HU-08 · Visualización de eventos en el mapa

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-14, RF-16, RNF-06, RNF-07

> Como usuario comunitario, quiero ver los eventos disponibles ubicados en el mapa del campus, para identificar rápidamente qué actividades ocurren cerca de mí.

### Criterios de aceptación

- **Dado** que ingreso a la aplicación, **cuando** se carga el mapa, **entonces** se muestran por defecto los eventos del día actual y los siguientes disponibles en las 24 horas siguientes.
- **Dado** que existe un evento publicado, **cuando** se visualiza en el mapa, **entonces** aparece mediante un ícono o pin asociado a su tipo de evento.
- **Dado** que abro el mapa en Android, **cuando** la conexión y el dispositivo funcionan normalmente, **entonces** el mapa debe cargar en menos de 3 segundos.

---

## HU-09 · Filtros de eventos en el mapa

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-15, RF-16, RF-17

> Como usuario comunitario, quiero filtrar eventos por grupo, categoría, tipo, fecha y amigos que asistirán, para encontrar actividades relevantes según mis intereses.

### Criterios de aceptación

- **Dado** que estoy en el mapa, **cuando** selecciono un filtro por tipo de evento, **entonces** solo se muestran los eventos de ese tipo.
- **Dado** que selecciono una fecha futura, **cuando** aplico el filtro, **entonces** se muestran los eventos programados para esa fecha.
- **Dado** que quito los filtros aplicados, **cuando** regreso a la vista por defecto, **entonces** el mapa vuelve a mostrar los eventos actuales y próximos del día.
- **Dado** que no existen eventos para un filtro seleccionado, **cuando** se actualiza el mapa, **entonces** el sistema muestra un mensaje indicando que no hay resultados.

---

## HU-10 · Navegación táctil del mapa

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-18

> Como usuario comunitario, quiero desplazarme y hacer zoom en el mapa, para explorar diferentes zonas del campus sin perder la referencia espacial.

### Criterios de aceptación

- **Dado** que estoy visualizando el mapa, **cuando** arrastro la pantalla, **entonces** puedo desplazarme únicamente dentro de los límites geográficos del campus universitario.
- **Dado** que hago gesto de zoom, **cuando** aumento o reduzco la escala, **entonces** el mapa responde dentro de los límites definidos.
- **Dado** que intento alejar el mapa por debajo del límite mínimo, **cuando** realizo el gesto, **entonces** el sistema impide superar ese límite.
- **Dado** que intento acercar el mapa por encima del límite máximo, **cuando** realizo el gesto, **entonces** el sistema impide superar ese límite.

---

## HU-11 · Agrupación de eventos cercanos

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-19

> Como usuario comunitario, quiero que los eventos cercanos se agrupen cuando el mapa está alejado, para evitar saturación visual y entender mejor la distribución de actividades.

### Criterios de aceptación

- **Dado** que existen varios eventos ubicados dentro de la misma área geográfica del mapa, **cuando** el nivel de zoom es inferior al umbral configurado por el sistema, **entonces** los eventos se muestran agrupados en un único marcador.
- **Dado** que se muestra un grupo de eventos, **cuando** observo el marcador agrupado, **entonces** veo el número de eventos que contiene.
- **Dado** que aumento el nivel de zoom, **cuando** los eventos dejan de estar visualmente superpuestos, **entonces** el sistema los desagrupa automáticamente.
- **Dado** que selecciono una agrupación, **cuando** el sistema despliega la información disponible, **entonces** puedo identificar los eventos incluidos.

---

## HU-12 · Identificación de eventos con asistencia de amigos

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-20

> Como usuario comunitario, quiero reconocer en el mapa los eventos a los que asistirán mis amigos, para decidir si también quiero participar.

### Criterios de aceptación

- **Dado** que un amigo confirmó asistencia a un evento, **cuando** visualizo ese evento en el mapa, **entonces** su marcador muestra un contorno diferenciador.
- **Dado** que ningún amigo confirmó asistencia, **cuando** visualizo el evento, **entonces** el marcador se muestra sin contorno especial.
- **Dado** que aplico el filtro de amigos que asistirán, **cuando** se actualiza el mapa, **entonces** se muestran los eventos relacionados con mi red de amigos.
- **Dado** que un amigo cancela su asistencia, **cuando** el mapa se actualiza, **entonces** el contorno se elimina si ya no hay amigos confirmados.