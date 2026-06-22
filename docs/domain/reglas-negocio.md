# Reglas de Negocio

## Autenticación y Acceso

| ID | Regla |
|---|---|
| RN-01 | Solo se permiten registros con correos de dominio `@unal.edu.co`. Cualquier otro dominio es rechazado. |
| RN-02 | Las contraseñas deben almacenarse hasheadas, nunca en texto plano. |
| RN-03 | El chat de un evento debe estar restringido a usuarios con una sesión activa en la plataforma. |

---

## Publicación de Eventos

| ID | Regla |
|---|---|
| RN-04 | Un evento solo puede publicarse con un máximo de **7 días** de anticipación respecto a su fecha de inicio. |
| RN-05 | Los campos `título`, `descripción`, `fecha/hora de inicio`, `duración`, `ubicación`, `tipo de evento` y `visibilidad` son obligatorios para publicar un evento. |
| RN-06 | La ubicación del evento debe estar dentro del campus UNAL Bogotá. |

---

## Ciclo de Vida de Eventos

| ID | Regla |
|---|---|
| RN-07 | Un evento pasa automáticamente a estado `FINALIZADO` al cumplirse su hora de fin (`fechaInicio + duración`). |
| RN-08 | Un evento `FINALIZADO` se elimina automáticamente de las vistas activas **24 horas** después de su hora de fin. |
| RN-09 | Al eliminarse un evento por ciclo de vida, su chat asociado deja de estar disponible. |

---

## Visibilidad de Eventos

| ID | Regla |
|---|---|
| RN-10 | Un evento con visibilidad `Pública` es visible para todos los usuarios autenticados. |
| RN-11 | Un evento con visibilidad `Solo_grupo` únicamente es visible para miembros del grupo asociado al evento. |
| RN-12 | Un evento con visibilidad `Solo_amigos` únicamente es visible para usuarios en la lista de amigos del organizador. |

---

## Grupos

| ID | Regla |
|---|---|
| RN-13 | Un usuario solo puede unirse a un grupo mediante invitación de un miembro existente. No existe unión directa. |
| RN-14 | Un grupo solo puede obtener el sello de verificación oficial si su solicitud fue aprobada por un Moderador de la plataforma. |
| RN-15 | El administrador de un grupo es automáticamente el usuario que lo creó. |

---

## Amistades

| ID | Regla |
|---|---|
| RN-16 | La relación de amistad es bidireccional: si A elimina a B, la relación deja de existir para ambos. |
| RN-17 | Las solicitudes de amistad solo pueden enviarse a correos institucionales registrados en el sistema. |

---

## Chat

| ID | Regla |
|---|---|
| RN-18 | El chat de un evento solo está disponible si el organizador lo habilitó al crear o editar el evento. |
| RN-19 | El chat está activo desde la creación del evento hasta su finalización. |
| RN-20 | Los mensajes del organizador o miembros del grupo organizador deben distinguirse visualmente de los mensajes de usuarios comunes. |

---

## Notificaciones

| ID | Regla |
|---|---|
| RN-21 | Un usuario recibe notificaciones push de cambios en un evento solo si las activó explícitamente para ese evento. |
| RN-22 | La cancelación de un evento genera automáticamente una notificación a todos los usuarios con asistencia confirmada o notificaciones activas. |