# Historias de Usuario - Creación y Edición de Eventos

## HU-27 · Creación de evento

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-43, RF-44, RNF-09

> Como usuario comunitario, quiero crear un evento con información básica y ubicación en el mapa, para difundir actividades dentro del campus.

### Criterios de aceptación

- **Dado** que estoy autenticado, **cuando** completo título, descripción, fecha y hora de inicio, duración, ubicación, tipo de evento, visibilidad y configuración de chat, **entonces** puedo publicar el evento.
- **Dado** que falta un campo obligatorio, **cuando** intento publicar el evento, **entonces** el sistema solicita completar la información requerida.
- **Dado** que ingreso una fecha inválida, **cuando** envío el formulario, **entonces** el sistema rechaza la publicación y muestra el error correspondiente.
- **Dado** que el evento se publica correctamente, **cuando** se consulta el mapa o la lista, **entonces** aparece según su visibilidad y fecha programada.

---

## HU-28 · Configuración de visibilidad del evento

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-44

> Como organizador, quiero configurar la visibilidad de un evento, para controlar si lo ven todos, solo miembros de un grupo o solo mis amigos.

### Criterios de aceptación

- **Dado** que creo o edito un evento, **cuando** selecciono visibilidad pública, **entonces** cualquier usuario autenticado puede verlo.
- **Dado** que selecciono visibilidad solo miembros del grupo, **cuando** se publica el evento, **entonces** solo los integrantes del grupo asociado pueden verlo.
- **Dado** que selecciono visibilidad solo amigos, **cuando** se publica el evento, **entonces** solo mis amigos pueden verlo.
- **Dado** que un usuario no cumple la condición de visibilidad, **cuando** consulta mapa o lista, **entonces** el evento no debe aparecerle.

---

## HU-29 · Asociación de evento a un grupo

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-45, RF-25

> Como organizador, quiero asociar un evento a un grupo al que pertenezco, para publicar actividades en nombre de ese colectivo.

### Criterios de aceptación

- **Dado** que pertenezco a uno o más grupos, **cuando** creo un evento, **entonces** puedo seleccionar uno como organizador.
- **Dado** que no pertenezco a ningún grupo, **cuando** creo un evento, **entonces** el campo de grupo no se muestra o queda sin opciones disponibles.
- **Dado** que asocio un evento a un grupo, **cuando** se consulta su ficha, **entonces** el grupo aparece como organizador.
- **Dado** que intento asociar un evento a un grupo al que no pertenezco, **cuando** envío el formulario, **entonces** el sistema no permite la acción.

---

## HU-30 · Programación de evento recurrente

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-46

> Como organizador, quiero programar un evento como recurrente, para publicar actividades que se repiten sin crear cada fecha manualmente.

### Criterios de aceptación

- **Dado** que creo o edito un evento, **cuando** activo la recurrencia, **entonces** puedo definir la frecuencia correspondiente.
- **Dado** que guardo un evento recurrente, **cuando** consulto el mapa, lista o calendario, **entonces** aparecen las ocurrencias programadas según la recurrencia.
- **Dado** que modifico la recurrencia, **cuando** guardo los cambios, **entonces** el sistema actualiza las ocurrencias futuras correspondientes.
- **Dado** que ingreso una recurrencia con una fecha de finalización anterior o igual a la fecha inicial del evento, **cuando** intento guardar, **entonces** el sistema muestra un mensaje de validación.

---

## HU-31 · Cancelación de evento

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-47, RF-30

> Como organizador, quiero cancelar un evento, para informar que una actividad ya no se realizará.

### Criterios de aceptación

- **Dado** que soy organizador de un evento futuro, **cuando** selecciono cancelar evento, **entonces** el sistema solicita confirmación.
- **Dado** que confirmo la cancelación, **cuando** el sistema procesa la acción, **entonces** el evento queda marcado como cancelado o deja de mostrarse como activo según la lógica definida.
- **Dado** que usuarios tenían notificaciones activas o asistencia confirmada, **cuando** se cancela el evento, **entonces** reciben una notificación de cancelación.
- **Dado** que no soy organizador, **cuando** intento cancelar el evento, **entonces** el sistema no permite realizar la acción.