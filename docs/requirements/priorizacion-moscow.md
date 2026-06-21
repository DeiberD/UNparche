# Priorización MoSCoW

La priorización MoSCoW se definió teniendo en cuenta que UNparche es un proyecto universitario con un tiempo de desarrollo limitado a sprints cortos. El criterio principal para los **Must Have** fue funcionalidad sin la cual el sistema no tiene razón de existir: si no se puede ver el mapa con eventos ni publicar uno, la aplicación no cumple ningún propósito. Funcionalidades como la autenticación completa, los grupos o el sistema de amigos, aunque deseables, no bloquean la propuesta de valor central y por eso se ubican en categorías inferiores. La moderación se excluye del alcance del proyecto dado que su implementación requiere flujos administrativos que superan el tiempo disponible.

---

## Must Have

Funcionalidad sin la cual el sistema no tiene razón de existir.

`RF-14` `RF-15` `RF-16` `RF-18` `RF-19` `RF-21` `RF-24` `RF-28` `RF-34` `RF-36` `RF-43` `RF-44`

| RF    | Descripción resumida                                         |
| -------| --------------------------------------------------------------|
| RF-14 | Mostrar eventos en el mapa con íconos SVG por tipo           |
| RF-15 | Filtrar eventos por grupo, categoría, tipo, fecha y amigos   |
| RF-16 | Mostrar por defecto eventos del día actual y próximos        |
| RF-18 | Navegar y hacer zoom dentro del campus (sin salir del área)  |
| RF-19 | Agrupar eventos cercanos según nivel de zoom                 |
| RF-21 | Vista de lista de eventos como alternativa al mapa           |
| RF-24 | Ver información completa de un evento al pulsarlo            |
| RF-28 | Confirmar o cancelar asistencia a un evento                  |
| RF-34 | Chat grupal en tiempo real por evento                        |
| RF-36 | Chat activo desde la creación hasta el fin del evento        |
| RF-43 | Formulario de creación de evento con todos los campos        |
| RF-44 | Configurar visibilidad del evento (pública / grupo / amigos) |

---

## Should Have

Importantes pero no bloqueantes para el lanzamiento mínimo.

`RF-06` `RF-07` `RF-17` `RF-22` `RF-23` `RF-25` `RF-29` `RF-30` `RF-32` `RF-33` `RF-35` `RF-37` `RF-38` `RF-40` `RF-45` `RF-46` `RF-47`

| RF | Descripción resumida |
|---|---|
| RF-06 | Ver perfil de otro usuario en modo lectura |
| RF-07 | Mostrar eventos a los que el usuario planea asistir |
| RF-17 | Filtrar el mapa por otras fechas |
| RF-22 | Mismos filtros del mapa disponibles en la lista |
| RF-23 | Mostrar automáticamente nuevos eventos públicos en lista |
| RF-25 | Mostrar grupo organizador y acceder a su información |
| RF-29 | Activar notificaciones push de un evento |
| RF-30 | Notificación push ante cualquier cambio del evento |
| RF-32 | Organizador publica anuncios dentro del evento |
| RF-33 | Asistentes ven los anuncios del organizador |
| RF-35 | Distinción visual de mensajes del organizador en el chat |
| RF-37 | Habilitar / deshabilitar el chat del evento |
| RF-38 | Calendario con eventos de asistencia confirmada |
| RF-40 | Lista de eventos creados por el usuario (pasados / en curso / programados) |
| RF-45 | Asociar evento a un grupo del usuario (opcional) |
| RF-46 | Programar evento como recurrente |
| RF-47 | Cancelar el evento |

---

## Could Have

Deseables si el tiempo lo permite.

`RF-01` `RF-02` `RF-03` `RF-04` `RF-05` `RF-08` `RF-09` `RF-10` `RF-11` `RF-12` `RF-13` `RF-20` `RF-26` `RF-27` `RF-31` `RF-39` `RF-41` `RF-42` `RF-48` `RF-49` `RF-50` `RF-51` `RF-52` `RF-53`

| RF | Descripción resumida |
|---|---|
| RF-01 | Crear perfil con correo institucional |
| RF-02 | Editar foto de perfil |
| RF-03 | Editar carrera (opcional) |
| RF-04 | Editar información personal en texto (opcional) |
| RF-05 | Ver y editar grupos desde el perfil |
| RF-08 | Crear grupo no oficial |
| RF-09 | Distinguir grupos oficiales con sello de verificación |
| RF-10 | Solicitar verificación oficial de un grupo |
| RF-11 | Unirse a grupos solo por invitación |
| RF-12 | Pestaña de exploración de grupos |
| RF-13 | Filtrar grupos por categoría, estado oficial y nombre |
| RF-20 | Contorno diferenciador cuando un amigo confirma asistencia |
| RF-26 | Suscribirse a notificaciones de futuros eventos de un grupo |
| RF-27 | Consultar calendario de eventos programados de un grupo |
| RF-31 | Consultar lista de asistentes confirmados |
| RF-39 | Historial de eventos pasados asistidos |
| RF-41 | Editar, cancelar, eliminar o configurar repetición de evento propio |
| RF-42 | Duplicar o reagendar eventos pasados propios |
| RF-48 | Pestaña con lista de amigos |
| RF-49 | Gestionar solicitudes de amistad pendientes |
| RF-50 | Agregar amigos por correo institucional |
| RF-51 | Ver perfil de un amigo al pulsarlo |
| RF-52 | Eliminar amigos de la lista |
| RF-53 | Invitar a un amigo a un evento |

---

## Won't Have

Fuera del alcance del proyecto actual.

`RF-54` `RF-55` `RF-56` `RF-57` `RF-58` `RF-59`

Estos requisitos corresponden al **Módulo de Moderación**. Su implementación requiere flujos administrativos que superan el tiempo disponible. Ver [Actores del sistema](../overview/actores.md) para más detalle sobre el rol de Moderador.