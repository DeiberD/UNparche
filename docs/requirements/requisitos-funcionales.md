# Requisitos Funcionales

## Módulo: Gestión de Perfil

| ID | Descripción |
|---|---|
| RF-01 | El sistema debe permitir crear un perfil usando el correo institucional. |
| RF-02 | El sistema debe permitir al usuario editar su foto de perfil. |
| RF-03 | El sistema debe permitir al usuario editar su carrera (campo opcional). |
| RF-04 | El sistema debe permitir al usuario editar información personal en texto (campo opcional). |
| RF-05 | El sistema debe permitir al usuario ver y editar los grupos a los que pertenece desde su perfil. |
| RF-06 | El sistema debe mostrar el perfil de otro usuario en modo lectura (sin posibilidad de editar la información) al ser consultado. |
| RF-07 | El sistema debe mostrar los eventos a los que planea asistir el usuario. |

---

## Módulo: Grupos

| ID | Descripción |
|---|---|
| RF-08 | El sistema debe permitir a cualquier miembro crear un grupo no oficial. |
| RF-09 | El sistema debe distinguir visualmente los grupos oficiales con un sello de verificado. |
| RF-10 | El sistema debe permitir al administrador de un grupo enviar una solicitud de verificación oficial a la plataforma (Moderadores de UNparche). |
| RF-11 | El sistema debe requerir invitación de un miembro del grupo para que un usuario pueda unirse a él. |
| RF-12 | El sistema debe ofrecer una pestaña de exploración de grupos oficiales y no oficiales. |
| RF-13 | El sistema debe permitir filtrar la lista de grupos usando uno o más de los siguientes criterios, de forma combinada o individual: `categoria` (Académico, Cultural, Social, Deportivo u Otros), `esOficial` (true/false), `nombre o descripción` (búsqueda parcial por texto). Cuando se apliquen múltiples filtros simultáneamente, el sistema debe retornar solo los grupos que cumplan **todos** los criterios seleccionados. |

---

## Módulo: Mapa del Campus

| ID | Descripción |
|---|---|
| RF-14 | El sistema debe mostrar los eventos en el mapa mediante íconos SVG predeterminados según el tipo de evento. |
| RF-15 | El sistema debe permitir buscar y filtrar eventos por grupo, categoría, tipo, fecha y amigos que asistirán. |
| RF-16 | El sistema debe mostrar por defecto únicamente los eventos del día actual y los próximos en el mapa. |
| RF-17 | El sistema debe permitir al usuario filtrar el mapa por otras fechas para ver eventos futuros. |
| RF-18 | El sistema debe permitir al usuario desplazarse y hacer zoom dentro del área correspondiente al campus universitario, sin permitir la visualización de zonas externas al campus sede Bogotá. |
| RF-19 | El sistema debe agrupar (visualmente) eventos cercanos cuando el nivel de zoom del mapa sea inferior al umbral configurado por el sistema. Cada agrupación debe indicar la cantidad de eventos contenidos. Cuando el zoom supere dicho umbral, los eventos deben desagruparse automáticamente. |
| RF-20 | El sistema debe mostrar un contorno diferenciador en el ícono de un evento cuando un amigo haya confirmado asistencia. |

---

## Módulo: Vista de Lista de Eventos

| ID | Descripción |
|---|---|
| RF-21 | El sistema debe ofrecer una vista de lista de eventos como alternativa al mapa. |
| RF-22 | El sistema debe mantener en la vista de lista las mismas opciones de filtrado que el mapa. |
| RF-23 | El sistema debe mostrar automáticamente cada nuevo evento público en la vista de lista. |

---

## Módulo: Interacción con Eventos

| ID | Descripción |
|---|---|
| RF-24 | Al pulsar sobre un evento, el sistema debe mostrar su información completa: título, organizador, descripción, fecha/hora, duración, ubicación y tipo de evento. |
| RF-25 | El sistema debe mostrar el nombre del grupo organizador y permitir acceder a su información completa cuando el evento pertenece a un grupo. |
| RF-26 | El sistema debe permitir al usuario suscribirse a notificaciones push de futuros eventos de un grupo organizador. |
| RF-27 | El sistema debe permitir al usuario consultar el calendario de eventos programados de un grupo. |
| RF-28 | El sistema debe permitir al usuario confirmar o cancelar su asistencia a un evento. |
| RF-29 | El sistema debe permitir al usuario activar notificaciones push del evento. |
| RF-30 | El sistema debe enviar una notificación push al usuario ante cualquier cambio del evento (ubicación, hora, cancelación, retrasos). |
| RF-31 | El sistema debe permitir al usuario consultar la lista de personas que han confirmado asistencia al evento. |
| RF-32 | El sistema debe permitir al organizador publicar anuncios dentro del evento. |
| RF-33 | El sistema debe mostrar a los asistentes los anuncios publicados por el organizador. |

---

## Módulo: Chat del Evento

| ID | Descripción |
|---|---|
| RF-34 | El sistema debe ofrecer un chat grupal en tiempo real para cada evento. |
| RF-35 | El sistema debe distinguir visualmente los mensajes del administrador o miembros del grupo organizador. |
| RF-36 | El chat de cada evento debe estar activo desde el momento de su creación hasta la finalización del mismo. |
| RF-37 | El sistema debe permitir al administrador habilitar o deshabilitar el chat al crear o editar el evento. |

---

## Módulo: Pestaña de Eventos

| ID | Descripción |
|---|---|
| RF-38 | El sistema debe mostrar en vista de calendario los eventos con asistencia confirmada por el usuario. |
| RF-39 | El sistema debe incluir un historial de eventos pasados a los que el usuario asistió. |
| RF-40 | El sistema debe mostrar la lista de eventos creados por el usuario: pasados, en curso y programados. |
| RF-41 | El sistema debe permitir al usuario editar, configurar la repetición del evento, cancelar o eliminar sus eventos propios según corresponda. |
| RF-42 | El sistema debe permitir duplicar o re-agendar eventos pasados propios. |

---

## Módulo: Creación y Edición de Eventos

| ID | Descripción |
|---|---|
| RF-43 | El sistema debe ofrecer un formulario con los campos: título, descripción, fecha/hora de inicio, duración, ubicación en mapa, tipo de evento, visibilidad y habilitación del chat. |
| RF-44 | El sistema debe permitir configurar la visibilidad del evento como pública, solo miembros del grupo, o solo amigos. |
| RF-45 | El sistema debe permitir asociar el evento a un grupo al que pertenezca el usuario (campo opcional). |
| RF-46 | El sistema debe permitir al organizador programar el evento como recurrente (repetición del evento en determinada fecha y hora). |
| RF-47 | El sistema debe permitir al organizador cancelar el evento. |

---

## Módulo: Sistema de Amigos

| ID    | Descripción                                                                                           |
| -------| -------------------------------------------------------------------------------------------------------|
| RF-48 | El sistema debe ofrecer una pestaña con la lista de amigos del usuario.                               |
| RF-49 | El sistema debe permitir al usuario gestionar solicitudes de amistad pendientes enviadas y recibidas. |
| RF-50 | El sistema debe permitir al usuario agregar nuevos amigos mediante su correo institucional.           |
| RF-51 | El sistema debe mostrar el perfil de un amigo al pulsarlo.                                            |
| RF-52 | El sistema debe permitir al usuario eliminar amigos de su lista.                                      |
| RF-53 | El sistema debe permitir al usuario invitar a un amigo a un evento al que él mismo planea asistir.    |

---

## Módulo: Moderación

> Este módulo está clasificado como **Won't Have** en el alcance actual.

| ID    | Descripción                                                                                                                                    |
| -------| ------------------------------------------------------------------------------------------------------------------------------------------------|
| RF-54 | El sistema debe permitir asignar el rol de moderador a un usuario.                                                                             |
| RF-55 | El sistema debe permitir al moderador eliminar eventos que incumplan las normas de la universidad.                                             |
| RF-56 | El sistema debe permitir al moderador notificar al organizador el motivo de la eliminación de su evento.                                       |
| RF-57 | El sistema debe permitir al moderador eliminar perfiles de usuarios que incumplan las políticas de la plataforma.                              |
| RF-58 | El sistema debe permitir al moderador emitir anuncios globales visibles para toda la comunidad.                                                |
| RF-59 | El sistema debe permitir al moderador filtrar la vista de lista por eventos recién publicados, verificarlos y eliminarlos si incumplen normas. |