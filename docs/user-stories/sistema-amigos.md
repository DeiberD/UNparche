# Historias de Usuario - Sistema de Amigos

## HU-32 · Lista de amigos

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-48, RF-51

> Como usuario comunitario, quiero ver mi lista de amigos y consultar sus perfiles, para mantener una red social básica dentro de la aplicación.

### Criterios de aceptación

- **Dado** que tengo amigos agregados, **cuando** ingreso a la pestaña de amigos, **entonces** se muestra mi lista de amigos.
- **Dado** que selecciono un amigo, **cuando** pulso sobre su nombre, **entonces** se abre su perfil en modo lectura.
- **Dado** que no tengo amigos agregados, **cuando** ingreso a la pestaña, **entonces** el sistema muestra un mensaje de estado vacío.
- **Dado** que un amigo modifica su información pública, **cuando** vuelvo a consultar su perfil, **entonces** veo la información actualizada autorizada.

---

## HU-33 · Gestión de solicitudes de amistad

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-49, RF-50

> Como usuario comunitario, quiero enviar, aceptar o rechazar solicitudes de amistad mediante correo institucional, para construir mi red de contactos dentro de la universidad.

### Criterios de aceptación

- **Dado** que conozco el correo institucional de otro usuario, **cuando** envío una solicitud, **entonces** el sistema registra la solicitud como pendiente.
- **Dado** que recibo una solicitud de amistad, **cuando** la acepto, **entonces** el usuario se agrega a mi lista de amigos.
- **Dado** que recibo una solicitud de amistad, **cuando** la rechazo, **entonces** no se crea relación de amistad.
- **Dado** que intento agregar un correo no registrado o inválido, **cuando** envío la solicitud, **entonces** el sistema informa que no puede completar la acción.

---

## HU-34 · Eliminación de amigos

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-52

> Como usuario comunitario, quiero eliminar amigos de mi lista, para mantener actualizada mi red de contactos.

### Criterios de aceptación

- **Dado** que tengo un usuario en mi lista de amigos, **cuando** selecciono eliminar, **entonces** el sistema solicita confirmación.
- **Dado** que confirmo la eliminación, **cuando** el sistema procesa la acción, **entonces** el usuario deja de aparecer en mi lista de amigos.
- **Dado** que elimino a un amigo, **cuando** ese usuario consulta su propia lista, **entonces** la relación de amistad también deja de estar activa.
- **Dado** que cancelo la confirmación, **cuando** regreso a la lista, **entonces** la amistad se conserva sin cambios.

---

## HU-35 · Invitación de amigos a eventos

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-53

> Como usuario comunitario, quiero invitar a un amigo a un evento al que planeo asistir, para compartir actividades de interés dentro del campus.

### Criterios de aceptación

- **Dado** que confirmé asistencia a un evento, **cuando** selecciono invitar amigo, **entonces** puedo escoger un usuario de mi lista de amigos.
- **Dado** que envío una invitación, **cuando** el sistema la procesa, **entonces** el amigo recibe una notificación o registro de invitación al evento.
- **Dado** que no he confirmado asistencia al evento, **cuando** intento invitar a un amigo, **entonces** el sistema no permite completar la invitación.
- **Dado** que el evento no es visible para ese amigo por configuración de privacidad, **cuando** intento invitarlo, **entonces** el sistema informa que no puede enviarse la invitación.