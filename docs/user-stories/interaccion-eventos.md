# Historias de Usuario - Interacción con Eventos

## HU-15 · Consulta de información completa de un evento

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-24, RF-25

> Como usuario comunitario, quiero ver la información completa de un evento, para decidir si me interesa asistir.

### Criterios de aceptación

- **Dado** que pulso un evento desde el mapa o la lista, **cuando** se abre la ficha del evento, **entonces** veo título, organizador, descripción, fecha, hora, duración, ubicación y tipo.
- **Dado** que el evento pertenece a un grupo, **cuando** consulto su organizador, **entonces** puedo acceder a la información completa del grupo.
- **Dado** que el evento fue creado por un usuario individual, **cuando** consulto el organizador, **entonces** se muestra la información pública disponible de ese usuario.
- **Dado** que falta información obligatoria del evento, **cuando** se intenta mostrar la ficha, **entonces** el sistema no debe presentar datos inconsistentes.

---

## HU-16 · Confirmación y cancelación de asistencia

**Prioridad:** Must Have  
**RF/RNF relacionados:** RF-28

> Como usuario comunitario, quiero confirmar o cancelar mi asistencia a un evento, para gestionar mi participación en actividades del campus.

### Criterios de aceptación

- **Dado** que consulto un evento visible, **cuando** confirmo mi asistencia, **entonces** el sistema registra que planeo asistir.
- **Dado** que ya confirmé asistencia, **cuando** selecciono cancelar asistencia, **entonces** el sistema elimina mi confirmación del evento.
- **Dado** que confirmo asistencia a un evento, **cuando** consulto mi pestaña de eventos, **entonces** el evento aparece dentro de mis eventos confirmados.
- **Dado** que cancelo mi asistencia, **cuando** consulto nuevamente el evento, **entonces** el estado se muestra actualizado.

---

## HU-17 · Activación de notificaciones de un evento

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-29, RF-30

> Como usuario comunitario, quiero activar notificaciones de un evento, para recibir recordatorios y enterarme de cambios importantes.

### Criterios de aceptación

- **Dado** que consulto un evento, **cuando** activo sus notificaciones, **entonces** el sistema guarda mi preferencia.
- **Dado** que tengo notificaciones activas para un evento, **cuando** faltan 15 minutos para su inicio, **entonces** recibo un aviso.
- **Dado** que el organizador cambia la ubicación, hora, estado o información crítica del evento, **cuando** tengo notificaciones activas, **entonces** recibo una notificación del cambio.
- **Dado** que desactivo las notificaciones de un evento, **cuando** ocurren cambios posteriores, **entonces** no debo recibir avisos de ese evento.

---

## HU-18 · Consulta de asistentes confirmados

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-31

> Como usuario comunitario, quiero consultar la lista de personas que confirmaron asistencia, para saber quiénes planean participar en el evento.

### Criterios de aceptación

- **Dado** que consulto un evento, **cuando** abro la lista de asistentes, **entonces** se muestran los usuarios que han confirmado asistencia.
- **Dado** que ningún usuario ha confirmado asistencia, **cuando** abro la lista, **entonces** el sistema muestra un mensaje indicando que no hay asistentes confirmados.
- **Dado** que un usuario cancela su asistencia, **cuando** la lista se actualiza, **entonces** deja de aparecer como asistente.
- **Dado** que se muestra la lista de asistentes, **cuando** selecciono un usuario, **entonces** puedo consultar su perfil público en modo lectura.

---

## HU-19 · Publicación y consulta de anuncios del evento

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-32, RF-33, RF-30

> Como organizador, quiero publicar anuncios dentro de un evento, para comunicar cambios o novedades a las personas interesadas.

### Criterios de aceptación

- **Dado** que soy organizador del evento, **cuando** publico un anuncio, **entonces** el sistema lo agrega a la sección de anuncios del evento.
- **Dado** que soy asistente o consulto el evento, **cuando** existen anuncios publicados, **entonces** puedo verlos en la ficha del evento.
- **Dado** que el anuncio informa un cambio, **cuando** los usuarios tienen notificaciones activas, **entonces** reciben una notificación del cambio.
- **Dado** que no soy organizador, **cuando** intento publicar un anuncio, **entonces** el sistema no permite realizar la acción.