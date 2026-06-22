# Historias de Usuario — Chat del Evento

## HU-20 · Chat grupal en tiempo real por evento

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-34, RF-36, RNF-15, RNF-16

> Como usuario comunitario, quiero participar en un chat asociado a cada evento, para conversar en tiempo real con otros interesados o asistentes.

### Criterios de aceptación

- **Dado** que estoy autenticado y el chat está habilitado, **cuando** ingreso al evento, **entonces** puedo acceder a su chat grupal.
- **Dado** que envío un mensaje válido, **cuando** el chat está activo, **entonces** el mensaje se muestra a los demás usuarios del chat.
- **Dado** que no estoy autenticado, **cuando** intento acceder al chat, **entonces** el sistema bloquea el acceso.
- **Dado** que el evento permanece activo, **cuando** se envían mensajes, **entonces** el sistema conserva el historial mientras corresponda según el ciclo de vida definido.

---

## HU-21 · Distinción visual de mensajes del organizador

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-35

> Como usuario del chat, quiero distinguir los mensajes del administrador o del grupo organizador, para identificar información oficial dentro de la conversación.

### Criterios de aceptación

- **Dado** que el administrador del evento envía un mensaje, **cuando** aparece en el chat, **entonces** su nombre o mensaje se muestra con un estilo visual diferenciado.
- **Dado** que un miembro del grupo organizador envía un mensaje, **cuando** aparece en el chat, **entonces** se distingue de los mensajes de usuarios comunes.
- **Dado** que un usuario comunitario envía un mensaje, **cuando** aparece en el chat, **entonces** no se muestra con identificación oficial.
- **Dado** que consulto el chat, **cuando** hay mensajes destacados del organizador, **entonces** puedo reconocerlos sin abrir información adicional.

---

## HU-22 · Habilitación o deshabilitación del chat

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-37

> Como organizador, quiero activar o desactivar el chat al crear o editar un evento, para controlar si habrá conversación asociada al evento.

### Criterios de aceptación

- **Dado** que creo un evento, **cuando** marco la opción de habilitar chat, **entonces** el evento se publica con chat disponible.
- **Dado** que creo un evento, **cuando** desmarco la opción de habilitar chat, **entonces** el evento se publica sin acceso al chat.
- **Dado** que edito un evento propio, **cuando** cambio la configuración del chat, **entonces** el sistema actualiza la disponibilidad del chat.
- **Dado** que no soy organizador, **cuando** intento cambiar la configuración del chat, **entonces** el sistema no permite modificarla.