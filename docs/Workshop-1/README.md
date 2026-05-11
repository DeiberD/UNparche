# UNparche

> Aplicación móvil para descubrir y difundir eventos dentro del campus de la **Universidad Nacional de Colombia — sede Bogotá**.

---

## Tabla de contenidos

1. [Descripción del proyecto](#1-descripción-del-proyecto)
2. [Características principales](#2-características-principales)
3. [Requisitos funcionales](#3-requisitos-funcionales)
   - [Gestión de Perfil](#-gestión-de-perfil)
   - [Grupos](#-grupos)
   - [Mapa del Campus](#-mapa-del-campus)
   - [Vista de Lista de Eventos](#-vista-de-lista-de-eventos)
   - [Interacción con Eventos](#-interacción-con-eventos)
   - [Chat del Evento](#-chat-del-evento)
   - [Pestaña de Eventos](#-pestaña-de-eventos)
   - [Creación y Edición de Eventos](#-creación-y-edición-de-eventos)
   - [Sistema de Amigos](#-sistema-de-amigos)
   - [Moderación](#-moderación)
4. [Requisitos no funcionales](#4-requisitos-no-funcionales)
5. [Priorización MoSCoW](#5-priorización-moscow)
6. [Historias de usuario](#6-historias-de-usuario)
7. [User Story Map](#7-user-story-map)

---

## 1. Descripción del proyecto

**UNparche** es una aplicación móvil diseñada **exclusivamente** para la comunidad universitaria de la Universidad Nacional de Colombia (sede Bogotá). Su propósito es centralizar la difusión y el descubrimiento de eventos académicos, culturales, deportivos y sociales que ocurren dentro del campus, integrando:

- Un **mapa interactivo** con geolocalización precisa de cada evento.
- Un **canal de comunicación en tiempo real** (chat) asociado a cada pin del mapa.

| Característica | Descripción |
|---|---|
| **Autenticación** | Exclusiva con correo institucional `@unal.edu.co` |
| **Alcance geográfico** | Campus UNAL Bogotá — sede única |
| **Roles de usuario** | Usuario Comunitario · Administrador |
| **Ventana de publicación** | Hasta 7 días antes del inicio del evento |
| **Ciclo de vida del evento** | Se elimina automáticamente 24 h después de su hora de fin |
| **Chat por evento** | Sala de chat en tiempo real asociada al pin del mapa |

---

## 2. Características principales

- **Mapa del campus** con íconos SVG por tipo de evento y clustering automático por zoom.
- **Filtros avanzados** por grupo, categoría, tipo, fecha y amigos que asistirán.
- **Chat grupal en tiempo real** por evento, con distinción visual del organizador.
- **Notificaciones push** ante cambios de evento (hora, ubicación, cancelación).
- **Sistema de grupos** con sello de verificación para organizaciones oficiales UNAL.
- **Red de amigos** con visibilidad de su asistencia en el mapa.
- **Calendario personal** de eventos confirmados e historial de asistencia.
- **Eliminación automática** de eventos 24 h después de finalizar.

---

## 3. Requisitos funcionales

### Gestión de Perfil

| ID | Descripción |
|---|---|
| RF-01 | Crear perfil usando el correo institucional |
| RF-02 | Editar foto de perfil |
| RF-03 | Editar carrera (campo opcional) |
| RF-04 | Editar información personal en texto (campo opcional) |
| RF-05 | Ver y editar los grupos a los que pertenece el usuario |
| RF-06 | Ver perfil de otro usuario en modo lectura |
| RF-07 | Ver los eventos a los que planea asistir un usuario visitado |

### Grupos

| ID | Descripción |
|---|---|
| RF-08 | Cualquier miembro puede crear un grupo no oficial |
| RF-09 | Distinción visual de grupos oficiales con sello de verificado |
| RF-10 | El administrador puede enviar solicitud de verificación oficial |
| RF-11 | Unirse a un grupo requiere invitación de un miembro |
| RF-12 | Pestaña de exploración de grupos oficiales y no oficiales |
| RF-13 | Filtrar grupos por tipo, categoría u otros criterios |

### Mapa del Campus

| ID | Descripción |
|---|---|
| RF-14 | Mostrar eventos con íconos SVG o imágenes personalizadas |
| RF-15 | Buscar y filtrar por grupo, categoría, tipo, fecha y amigos |
| RF-16 | Mostrar por defecto los eventos del día actual y próximos |
| RF-17 | Filtrar el mapa por otras fechas para ver eventos futuros |
| RF-18 | Desplazarse y hacer zoom con límites mínimos y máximos |
| RF-19 | Agrupar eventos cercanos al alejar; desagrupar al acercar |
| RF-20 | Contorno diferenciador en el ícono cuando un amigo asistirá |

### Vista de Lista de Eventos

| ID | Descripción |
|---|---|
| RF-21 | Vista de lista de eventos como alternativa al mapa |
| RF-22 | Mismas opciones de filtrado que el mapa |
| RF-23 | Cada nuevo evento público aparece automáticamente en la lista |

### Interacción con Eventos

| ID | Descripción |
|---|---|
| RF-24 | Mostrar información completa del evento (título, organizador, descripción, fecha/hora, duración, ubicación, tipo) |
| RF-25 | Mostrar el grupo organizador y acceder a su información |
| RF-26 | Suscribirse a notificaciones push de futuros eventos de un grupo |
| RF-27 | Consultar el calendario de eventos programados de un grupo |
| RF-28 | Confirmar o cancelar asistencia a un evento |
| RF-29 | Activar notificaciones push del evento |
| RF-30 | Notificación push ante cualquier cambio del evento |
| RF-31 | Consultar la lista de personas con asistencia confirmada |
| RF-32 | El organizador puede publicar anuncios dentro del evento |
| RF-33 | Los asistentes pueden ver los anuncios del organizador |

### Chat del Evento

| ID | Descripción |
|---|---|
| RF-34 | Chat grupal en tiempo real para cada evento |
| RF-35 | Distinción visual de mensajes del administrador / grupo organizador |
| RF-36 | Chat activo desde la creación hasta la finalización del evento |
| RF-37 | El administrador puede habilitar o deshabilitar el chat |

### Pestaña de Eventos

| ID | Descripción |
|---|---|
| RF-38 | Vista de calendario con eventos de asistencia confirmada |
| RF-39 | Historial de eventos pasados a los que el usuario asistió |
| RF-40 | Lista de eventos creados: pasados, en curso y programados |
| RF-41 | Editar, configurar recurrencia, cancelar o eliminar eventos propios |
| RF-42 | Duplicar o re-agendar eventos pasados propios |

### Creación y Edición de Eventos

| ID | Descripción |
|---|---|
| RF-43 | Formulario con título, descripción, fecha/hora, duración, ubicación, tipo, visibilidad y chat |
| RF-44 | Visibilidad pública, solo miembros del grupo, o solo amigos |
| RF-45 | Asociar el evento a un grupo al que pertenezca el usuario |
| RF-46 | Programar el evento como recurrente |
| RF-47 | Cancelar el evento |

### Sistema de Amigos

| ID | Descripción |
|---|---|
| RF-48 | Pestaña con la lista de amigos del usuario |
| RF-49 | Gestionar solicitudes de amistad pendientes (enviadas y recibidas) |
| RF-50 | Agregar nuevos amigos mediante correo institucional |
| RF-51 | Ver el perfil de un amigo al pulsarlo |
| RF-52 | Eliminar amigos de la lista |
| RF-53 | Invitar a un amigo a un evento al que el usuario planea asistir |

### Moderación

| ID | Descripción |
|---|---|
| RF-54 | Asignar el rol de moderador a un usuario |
| RF-55 | El moderador puede eliminar eventos que incumplan normas |
| RF-56 | Notificar al organizador el motivo de eliminación de su evento |
| RF-57 | El moderador puede eliminar perfiles que incumplan políticas |
| RF-58 | El moderador puede emitir anuncios globales para toda la comunidad |
| RF-59 | El moderador puede filtrar eventos recién publicados y verificarlos |

---

## 4. Requisitos no funcionales

### Autenticación

| ID | Prioridad | Descripción |
|---|---|---|
| RNF-01 | Must | Contraseñas almacenadas de forma cifrada |
| RNF-02 | Must | Inicio de sesión en menos de 3 segundos |

### Perfil de Usuario

| ID | Prioridad | Descripción |
|---|---|---|
| RNF-03 | Must | Solo se muestra información pública autorizada del usuario |
| RNF-04 | Should | Edición del perfil en máximo tres pasos |
| RNF-05 | Could | Personalización de imagen de perfil |

### Mapa del Campus

| ID | Prioridad | Descripción |
|---|---|---|
| RNF-06 | Must | El mapa carga en menos de 3 segundos |
| RNF-07 | Must | El mapa funciona correctamente en Android |
| RNF-08 | Should | Geolocalización con precisión dentro del campus |

### Eventos

| ID | Prioridad | Descripción |
|---|---|---|
| RNF-09 | Must | Validación de fechas y campos obligatorios antes de publicar |
| RNF-10 | Must | Los eventos se eliminan automáticamente 24 h después de finalizar |
| RNF-11 | Should | Soporte para al menos 1 000 eventos activos simultáneamente |

### Chat

| ID | Prioridad | Descripción |
|---|---|---|
| RNF-15 | Must | Solo usuarios autenticados acceden a chats |
| RNF-16 | Should | Mensajes almacenados mientras el evento permanezca activo |
| RNF-17 | Could | Restricción de mensajes excesivamente largos o spam |

---

## 5. Priorización MoSCoW

La priorización se definió considerando que UNparche es un proyecto universitario con **sprints cortos**. El criterio principal para los *Must Have* fue: funcionalidad sin la cual el sistema no tiene razón de existir.

> La moderación se excluye del alcance del proyecto dado que su implementación requiere flujos administrativos que superan el tiempo disponible.

### Must Have
`RF-14` `RF-15` `RF-16` `RF-18` `RF-19` `RF-21` `RF-24` `RF-28` `RF-34` `RF-36` `RF-43` `RF-44`

### Should Have
`RF-06` `RF-07` `RF-17` `RF-22` `RF-23` `RF-25` `RF-29` `RF-30` `RF-32` `RF-33` `RF-35` `RF-37` `RF-38` `RF-40` `RF-45` `RF-46` `RF-47`

### Could Have
`RF-01` `RF-02` `RF-03` `RF-04` `RF-05` `RF-08` `RF-09` `RF-10` `RF-11` `RF-12` `RF-13` `RF-20` `RF-26` `RF-27` `RF-31` `RF-39` `RF-41` `RF-42` `RF-48` `RF-49` `RF-50` `RF-51` `RF-52` `RF-53`

### Won't Have
`RF-54` `RF-55` `RF-56` `RF-57` `RF-58` `RF-59`

---

## 6. Historias de usuario

A continuación se listan las historias de usuario agrupadas por módulo. Cada historia incluye su prioridad MoSCoW, los RF/RNF relacionados y sus criterios de aceptación en formato Given / When / Then.

###  Módulo: Gestión de Perfil

<details>
<summary><strong>HU-01</strong> · Registro con correo institucional &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-01, RNF-01, RNF-02

**Historia:** Como miembro de la comunidad universitaria, quiero crear una cuenta usando mi correo institucional `@unal.edu.co`, para acceder de forma restringida a la aplicación.

**Criterios de aceptación:**
- **Dado** que ingreso un correo `@unal.edu.co`, **cuando** completo los datos requeridos, **entonces** el sistema permite crear la cuenta.
- **Dado** que ingreso un correo con dominio diferente, **cuando** intento registrarme, **entonces** el sistema rechaza el registro e informa que solo se aceptan correos institucionales.
- **Dado** que la cuenta se crea correctamente, **cuando** se almacena la contraseña, **entonces** debe guardarse cifrada y no en texto plano.
- **Dado** que el registro fue exitoso, **cuando** inicio sesión, **entonces** el acceso se completa en menos de 3 segundos en condiciones normales.

</details>

<details>
<summary><strong>HU-02</strong> · Edición básica del perfil &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-02, RF-03, RF-04, RNF-03, RNF-04

**Historia:** Como usuario comunitario, quiero editar mi foto, carrera e información personal, para presentar una identidad básica dentro de la plataforma.

**Criterios de aceptación:**
- **Dado** que estoy autenticado, **cuando** ingreso a mi perfil, **entonces** puedo modificar mi foto, carrera e información personal.
- **Dado** que carrera e información personal son opcionales, **cuando** dejo esos campos vacíos, **entonces** el sistema permite guardar sin errores.
- **Dado** que guardo cambios válidos, **cuando** vuelvo a abrir mi perfil, **entonces** la información actualizada se muestra correctamente.
- **Dado** que otro usuario consulta mi perfil, **cuando** se carga la información, **entonces** solo se muestra la información pública autorizada.

</details>

<details>
<summary><strong>HU-03</strong> · Consulta del perfil de otro usuario &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-06, RF-07, RNF-03

**Historia:** Como usuario comunitario, quiero consultar el perfil de otro usuario en modo lectura, para conocer información pública sobre esa persona y sus eventos visibles.

**Criterios de aceptación:**
- **Dado** que consulto el perfil de otro usuario, **cuando** se abre la vista, **entonces** no puedo editar su información.
- **Dado** que el usuario visitado permite mostrar sus eventos, **cuando** consulto su perfil, **entonces** veo los eventos a los que planea asistir.
- **Dado** que el usuario restringió la visibilidad de sus eventos, **cuando** consulto su perfil, **entonces** esos eventos no se muestran.
- **Dado** que se muestra información del perfil, **cuando** otro usuario la visualiza, **entonces** el sistema respeta la privacidad configurada.

</details>

---

### Módulo: Grupos

<details>
<summary><strong>HU-04</strong> · Creación de grupo no oficial &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-08

**Historia:** Como miembro de la comunidad universitaria, quiero crear un grupo no oficial, para organizar eventos en nombre de un colectivo dentro del campus.

**Criterios de aceptación:**
- **Dado** que estoy autenticado, **cuando** completo nombre, descripción y categoría, **entonces** el sistema permite crear un grupo no oficial.
- **Dado** que creo un grupo, **cuando** se guarda correctamente, **entonces** quedo registrado como administrador.
- **Dado** que intento crear un grupo sin nombre, **cuando** envío el formulario, **entonces** el sistema solicita completar el campo obligatorio.
- **Dado** que el grupo fue creado, **cuando** se consulta en la plataforma, **entonces** aparece como no oficial y sin sello de verificación.

</details>

<details>
<summary><strong>HU-05</strong> · Solicitud de verificación de grupo &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-09, RF-10

**Historia:** Como administrador de un grupo, quiero solicitar la verificación oficial, para que el grupo sea reconocido como organización universitaria legítima.

**Criterios de aceptación:**
- **Dado** que administro un grupo no oficial, **cuando** ingreso a su configuración, **entonces** puedo enviar una solicitud de verificación.
- **Dado** que envío la solicitud, **cuando** adjunto la evidencia requerida, **entonces** el sistema deja la solicitud pendiente de revisión.
- **Dado** que un grupo es aprobado, **cuando** aparece en la aplicación, **entonces** se muestra con sello de verificado.
- **Dado** que un grupo no ha sido verificado, **cuando** se muestra en la app, **entonces** no aparece con sello oficial.

</details>

<details>
<summary><strong>HU-06</strong> · Invitación y pertenencia a grupos &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-05, RF-11

**Historia:** Como miembro de la comunidad universitaria, quiero unirme a grupos únicamente mediante invitación, para evitar suplantaciones o publicaciones indebidas en nombre de organizaciones.

**Criterios de aceptación:**
- **Dado** que un miembro me envía una invitación, **cuando** la acepto, **entonces** el sistema me agrega como integrante.
- **Dado** que no he recibido invitación, **cuando** intento unirme directamente, **entonces** el sistema no permite completar la unión.
- **Dado** que pertenezco a un grupo, **cuando** edito mi perfil, **entonces** puedo ver ese grupo en mi información de pertenencia.
- **Dado** que acepto o rechazo una invitación, **cuando** se procesa la respuesta, **entonces** el estado se actualiza correctamente.

</details>

<details>
<summary><strong>HU-07</strong> · Exploración y filtrado de grupos &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-12, RF-13

**Historia:** Como usuario comunitario, quiero explorar y filtrar grupos oficiales y no oficiales, para encontrar colectivos relacionados con mis intereses.

**Criterios de aceptación:**
- **Dado** que ingreso a la pestaña de grupos, **cuando** se carga la vista, **entonces** se listan grupos oficiales y no oficiales.
- **Dado** que aplico filtro por tipo, **cuando** selecciono oficial o no oficial, **entonces** se muestran solo los grupos correspondientes.
- **Dado** que aplico filtro por categoría, **cuando** confirmo el filtro, **entonces** la lista se actualiza según la categoría.
- **Dado** que un grupo es oficial, **cuando** aparece en la lista, **entonces** se muestra con su sello de verificación.

</details>

---

### Módulo: Mapa del Campus

<details>
<summary><strong>HU-08</strong> · Visualización de eventos en el mapa &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-14, RF-16, RNF-06, RNF-07

**Historia:** Como usuario comunitario, quiero ver los eventos disponibles ubicados en el mapa del campus, para identificar rápidamente qué actividades ocurren cerca de mí.

**Criterios de aceptación:**
- **Dado** que ingreso a la aplicación, **cuando** se carga el mapa, **entonces** se muestran por defecto los eventos del día actual y los próximos.
- **Dado** que existe un evento publicado, **cuando** se visualiza en el mapa, **entonces** aparece con un ícono asociado a su tipo.
- **Dado** que el evento tiene imagen personalizada válida, **cuando** se muestra en el mapa, **entonces** el sistema puede usarla como representación visual.
- **Dado** que abro el mapa en Android, **cuando** la conexión y el dispositivo funcionan normalmente, **entonces** el mapa carga en menos de 3 segundos.

</details>

<details>
<summary><strong>HU-09</strong> · Filtros de eventos en el mapa &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-15, RF-16, RF-17

**Historia:** Como usuario comunitario, quiero filtrar eventos por grupo, categoría, tipo, fecha y amigos que asistirán, para encontrar actividades relevantes.

**Criterios de aceptación:**
- **Dado** que estoy en el mapa, **cuando** selecciono un filtro por tipo, **entonces** solo se muestran los eventos de ese tipo.
- **Dado** que selecciono una fecha futura, **cuando** aplico el filtro, **entonces** se muestran los eventos programados para esa fecha.
- **Dado** que quito los filtros, **cuando** regreso a la vista por defecto, **entonces** el mapa vuelve a mostrar eventos actuales y próximos.
- **Dado** que no existen eventos para el filtro, **cuando** se actualiza el mapa, **entonces** el sistema muestra un mensaje de sin resultados.

</details>

<details>
<summary><strong>HU-10</strong> · Navegación táctil del mapa &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-18

**Historia:** Como usuario comunitario, quiero desplazarme y hacer zoom en el mapa, para explorar diferentes zonas del campus sin perder la referencia espacial.

**Criterios de aceptación:**
- **Dado** que estoy en el mapa, **cuando** arrastro la pantalla, **entonces** puedo desplazarme por las zonas permitidas del campus.
- **Dado** que hago gesto de zoom, **cuando** aumento o reduzco la escala, **entonces** el mapa responde dentro de los límites definidos.
- **Dado** que intento alejar por debajo del límite mínimo, **cuando** realizo el gesto, **entonces** el sistema impide superar ese límite.
- **Dado** que intento acercar por encima del límite máximo, **cuando** realizo el gesto, **entonces** el sistema impide superar ese límite.

</details>

<details>
<summary><strong>HU-11</strong> · Agrupación de eventos cercanos &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-19

**Historia:** Como usuario comunitario, quiero que los eventos cercanos se agrupen cuando el mapa está alejado, para evitar saturación visual y entender mejor la distribución de actividades.

**Criterios de aceptación:**
- **Dado** que existen varios eventos cercanos, **cuando** el nivel de zoom es bajo, **entonces** el sistema los agrupa en un solo marcador.
- **Dado** que se muestra un grupo de eventos, **cuando** observo el marcador agrupado, **entonces** veo el número de eventos que contiene.
- **Dado** que aumento el zoom, **cuando** los eventos dejan de estar superpuestos, **entonces** el sistema los desagrupa automáticamente.
- **Dado** que selecciono una agrupación, **cuando** el sistema despliega la información, **entonces** puedo identificar los eventos incluidos.

</details>

<details>
<summary><strong>HU-12</strong> · Identificación de eventos con asistencia de amigos &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-20

**Historia:** Como usuario comunitario, quiero reconocer en el mapa los eventos a los que asistirán mis amigos, para decidir si también quiero participar.

**Criterios de aceptación:**
- **Dado** que un amigo confirmó asistencia, **cuando** visualizo ese evento en el mapa, **entonces** su marcador muestra un contorno diferenciador.
- **Dado** que ningún amigo confirmó asistencia, **cuando** visualizo el evento, **entonces** el marcador se muestra sin contorno especial.
- **Dado** que aplico el filtro de amigos, **cuando** se actualiza el mapa, **entonces** se muestran los eventos relacionados con mi red.
- **Dado** que un amigo cancela asistencia, **cuando** el mapa se actualiza, **entonces** el contorno se elimina si ya no hay amigos confirmados.

</details>

---

### Módulo: Vista de Lista de Eventos

<details>
<summary><strong>HU-13</strong> · Consulta de eventos en vista de lista &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-21, RF-23

**Historia:** Como usuario comunitario, quiero consultar los eventos en una vista de lista, para revisar actividades disponibles sin depender del mapa.

**Criterios de aceptación:**
- **Dado** que ingreso a la vista de lista, **cuando** existen eventos públicos, **entonces** se muestran como ítems ordenados.
- **Dado** que se publica un nuevo evento público, **cuando** consulto la lista, **entonces** el evento aparece automáticamente.
- **Dado** que no existen eventos, **cuando** ingreso a la lista, **entonces** el sistema muestra un mensaje de estado vacío.
- **Dado** que selecciono un evento desde la lista, **cuando** pulso sobre él, **entonces** se abre su información detallada.

</details>

<details>
<summary><strong>HU-14</strong> · Filtrado de eventos en lista &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-22

**Historia:** Como usuario comunitario, quiero usar en la lista los mismos filtros disponibles en el mapa, para buscar eventos de forma consistente en ambas vistas.

**Criterios de aceptación:**
- **Dado** que estoy en la vista de lista, **cuando** filtro por fecha, **entonces** se muestran solo los eventos de esa fecha.
- **Dado** que filtro por categoría o tipo, **cuando** aplico el filtro, **entonces** la lista se actualiza con los eventos que cumplen el criterio.
- **Dado** que filtro por grupo organizador, **cuando** selecciono un grupo, **entonces** se muestran únicamente sus eventos visibles.
- **Dado** que cambio entre mapa y lista, **cuando** hay filtros activos, **entonces** la lógica de filtrado se mantiene coherente.

</details>

---

### Módulo: Interacción con Eventos

<details>
<summary><strong>HU-15</strong> · Consulta de información completa de un evento &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-24, RF-25

**Historia:** Como usuario comunitario, quiero ver la información completa de un evento, para decidir si me interesa asistir.

**Criterios de aceptación:**
- **Dado** que pulso un evento, **cuando** se abre la ficha, **entonces** veo título, organizador, descripción, fecha, hora, duración, ubicación y tipo.
- **Dado** que el evento pertenece a un grupo, **cuando** consulto el organizador, **entonces** puedo acceder a la información completa del grupo.
- **Dado** que fue creado por un individuo, **cuando** consulto el organizador, **entonces** se muestra la información pública de ese usuario.
- **Dado** que falta información obligatoria, **cuando** se intenta mostrar la ficha, **entonces** el sistema no presenta datos inconsistentes.

</details>

<details>
<summary><strong>HU-16</strong> · Confirmación y cancelación de asistencia &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-28

**Historia:** Como usuario comunitario, quiero confirmar o cancelar mi asistencia a un evento, para gestionar mi participación en actividades del campus.

**Criterios de aceptación:**
- **Dado** que consulto un evento visible, **cuando** confirmo asistencia, **entonces** el sistema registra que planeo asistir.
- **Dado** que ya confirmé asistencia, **cuando** selecciono cancelar, **entonces** el sistema elimina mi confirmación.
- **Dado** que confirmo asistencia, **cuando** consulto mi pestaña de eventos, **entonces** el evento aparece en mis eventos confirmados.
- **Dado** que cancelo asistencia, **cuando** consulto el evento nuevamente, **entonces** el estado se muestra actualizado.

</details>

<details>
<summary><strong>HU-17</strong> · Activación de notificaciones de un evento &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-29, RF-30

**Historia:** Como usuario comunitario, quiero activar notificaciones de un evento, para recibir recordatorios y enterarme de cambios importantes.

**Criterios de aceptación:**
- **Dado** que consulto un evento, **cuando** activo sus notificaciones, **entonces** el sistema guarda mi preferencia.
- **Dado** que tengo notificaciones activas, **cuando** faltan 15 minutos para el inicio, **entonces** recibo un aviso.
- **Dado** que el organizador cambia información crítica, **cuando** tengo notificaciones activas, **entonces** recibo una notificación del cambio.
- **Dado** que desactivo las notificaciones, **cuando** ocurren cambios posteriores, **entonces** no recibo avisos de ese evento.

</details>

<details>
<summary><strong>HU-18</strong> · Consulta de asistentes confirmados &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-31

**Historia:** Como usuario comunitario, quiero consultar la lista de personas que confirmaron asistencia, para saber quiénes planean participar.

**Criterios de aceptación:**
- **Dado** que consulto un evento, **cuando** abro la lista de asistentes, **entonces** veo los usuarios con asistencia confirmada.
- **Dado** que nadie ha confirmado, **cuando** abro la lista, **entonces** el sistema muestra un mensaje de sin asistentes.
- **Dado** que un usuario cancela asistencia, **cuando** la lista se actualiza, **entonces** deja de aparecer en ella.
- **Dado** que se muestra la lista, **cuando** selecciono un usuario, **entonces** puedo consultar su perfil público en modo lectura.

</details>

<details>
<summary><strong>HU-19</strong> · Publicación y consulta de anuncios del evento &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-32, RF-33, RF-30

**Historia:** Como organizador, quiero publicar anuncios dentro de un evento, para comunicar cambios o novedades relevantes a las personas interesadas.

**Criterios de aceptación:**
- **Dado** que soy organizador, **cuando** publico un anuncio, **entonces** el sistema lo agrega a la sección de anuncios del evento.
- **Dado** que soy asistente, **cuando** existen anuncios publicados, **entonces** puedo verlos en la ficha del evento.
- **Dado** que el anuncio informa un cambio relevante, **cuando** los usuarios tienen notificaciones activas, **entonces** reciben una notificación.
- **Dado** que no soy organizador, **cuando** intento publicar un anuncio, **entonces** el sistema no permite la acción.

</details>

---

### Módulo: Chat del Evento

<details>
<summary><strong>HU-20</strong> · Chat grupal en tiempo real por evento &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-34, RF-36, RNF-15, RNF-16

**Historia:** Como usuario autenticado, quiero participar en un chat asociado a cada evento, para conversar en tiempo real con otros interesados.

**Criterios de aceptación:**
- **Dado** que estoy autenticado y el chat está habilitado, **cuando** ingreso al evento, **entonces** puedo acceder a su chat grupal.
- **Dado** que envío un mensaje válido, **cuando** el chat está activo, **entonces** el mensaje se muestra a los demás usuarios.
- **Dado** que no estoy autenticado, **cuando** intento acceder al chat, **entonces** el sistema bloquea el acceso.
- **Dado** que el evento permanece activo, **cuando** se envían mensajes, **entonces** el sistema conserva el historial según el ciclo de vida definido.

</details>

<details>
<summary><strong>HU-21</strong> · Distinción visual de mensajes del organizador &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-35

**Historia:** Como usuario del chat, quiero distinguir los mensajes del administrador o del grupo organizador, para identificar información oficial dentro de la conversación.

**Criterios de aceptación:**
- **Dado** que el administrador envía un mensaje, **cuando** aparece en el chat, **entonces** se muestra con estilo visual diferenciado.
- **Dado** que un miembro del grupo organizador envía un mensaje, **cuando** aparece en el chat, **entonces** se distingue de los mensajes de usuarios comunes.
- **Dado** que un usuario común envía un mensaje, **cuando** aparece en el chat, **entonces** no se muestra con identificación oficial.
- **Dado** que consulto el chat, **cuando** hay mensajes del organizador, **entonces** puedo reconocerlos sin abrir información adicional.

</details>

<details>
<summary><strong>HU-22</strong> · Habilitación o deshabilitación del chat &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-37

**Historia:** Como organizador, quiero activar o desactivar el chat al crear o editar un evento, para controlar si habrá conversación asociada.

**Criterios de aceptación:**
- **Dado** que creo un evento, **cuando** marco habilitar chat, **entonces** el evento se publica con chat disponible.
- **Dado** que creo un evento, **cuando** desmarco habilitar chat, **entonces** el evento se publica sin acceso al chat.
- **Dado** que edito un evento propio, **cuando** cambio la configuración del chat, **entonces** el sistema actualiza la disponibilidad.
- **Dado** que no soy organizador, **cuando** intento cambiar la configuración, **entonces** el sistema no permite modificarla.

</details>

---

### Módulo: Pestaña de Eventos

<details>
<summary><strong>HU-23</strong> · Calendario de eventos confirmados &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-38

**Historia:** Como usuario comunitario, quiero ver en calendario los eventos a los que confirmé asistencia, para organizar mi participación.

**Criterios de aceptación:**
- **Dado** que confirmé asistencia a eventos, **cuando** ingreso a la pestaña, **entonces** los veo en vista de calendario.
- **Dado** que selecciono un evento en el calendario, **cuando** pulso sobre él, **entonces** se abre su ficha de información.
- **Dado** que cancelo asistencia, **cuando** vuelvo al calendario, **entonces** el evento deja de aparecer en mis confirmados.
- **Dado** que no tengo eventos confirmados, **cuando** ingreso al calendario, **entonces** el sistema muestra un estado vacío.

</details>

<details>
<summary><strong>HU-24</strong> · Historial de eventos asistidos &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-39

**Historia:** Como usuario comunitario, quiero consultar un historial de eventos pasados a los que asistí, para recordar actividades en las que participé.

**Criterios de aceptación:**
- **Dado** que asistí a eventos pasados, **cuando** ingreso al historial, **entonces** se muestran con nombre e información básica.
- **Dado** que no tengo eventos pasados, **cuando** consulto el historial, **entonces** el sistema muestra un mensaje de sin registros.
- **Dado** que selecciono un evento pasado, **cuando** abro su detalle, **entonces** puedo consultar la información disponible.
- **Dado** que un evento fue eliminado por ciclo de vida, **cuando** se muestra en historial, **entonces** se conserva la información mínima de identificación.

</details>

<details>
<summary><strong>HU-25</strong> · Lista de eventos creados por el usuario &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-40

**Historia:** Como organizador, quiero ver la lista de eventos que he creado, para gestionar mis eventos pasados, en curso y programados.

**Criterios de aceptación:**
- **Dado** que he creado eventos, **cuando** ingreso a la sección, **entonces** se muestran clasificados como pasados, en curso o programados.
- **Dado** que selecciono un evento programado, **cuando** se abre su ficha, **entonces** veo opciones de gestión disponibles.
- **Dado** que no he creado eventos, **cuando** ingreso a la sección, **entonces** el sistema muestra un estado vacío.
- **Dado** que un evento cambia de estado por fecha, **cuando** consulto la lista, **entonces** aparece en la categoría correspondiente.

</details>

<details>
<summary><strong>HU-26</strong> · Gestión de eventos propios &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-41, RF-42

**Historia:** Como organizador, quiero editar, cancelar, eliminar, duplicar o reagendar mis eventos, para mantener actualizada la información publicada.

**Criterios de aceptación:**
- **Dado** que tengo un evento futuro, **cuando** ingreso a su gestión, **entonces** puedo editarlo o cancelarlo.
- **Dado** que tengo un evento pasado, **cuando** ingreso a su gestión, **entonces** puedo eliminarlo, duplicarlo o reagendarlo.
- **Dado** que modifico un evento, **cuando** guardo los cambios, **entonces** la información actualizada se refleja en mapa, lista y ficha.
- **Dado** que cancelo un evento, **cuando** los usuarios tenían notificaciones activas, **entonces** se les notifica la cancelación.

</details>

---

### Módulo: Creación y Edición de Eventos

<details>
<summary><strong>HU-27</strong> · Creación de evento &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-43, RF-44, RNF-09

**Historia:** Como miembro de la comunidad universitaria, quiero crear un evento con información básica y ubicación en el mapa, para difundir actividades dentro del campus.

**Criterios de aceptación:**
- **Dado** que estoy autenticado, **cuando** completo todos los campos requeridos, **entonces** puedo publicar el evento.
- **Dado** que falta un campo obligatorio, **cuando** intento publicar, **entonces** el sistema solicita completar la información.
- **Dado** que ingreso una fecha inválida, **cuando** envío el formulario, **entonces** el sistema rechaza la publicación y muestra el error.
- **Dado** que el evento se publica correctamente, **cuando** se consulta mapa o lista, **entonces** aparece según su visibilidad y fecha.

</details>

<details>
<summary><strong>HU-28</strong> · Configuración de visibilidad del evento &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RF-44

**Historia:** Como organizador, quiero configurar la visibilidad de un evento, para controlar quién puede verlo.

**Criterios de aceptación:**
- **Dado** que selecciono visibilidad pública, **cuando** se publica el evento, **entonces** cualquier usuario autenticado puede verlo.
- **Dado** que selecciono solo miembros del grupo, **cuando** se publica, **entonces** solo los integrantes del grupo pueden verlo.
- **Dado** que selecciono solo amigos, **cuando** se publica, **entonces** solo mis amigos pueden verlo.
- **Dado** que un usuario no cumple la condición, **cuando** consulta mapa o lista, **entonces** el evento no le aparece.

</details>

<details>
<summary><strong>HU-29</strong> · Asociación de evento a un grupo &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-45, RF-25

**Historia:** Como organizador, quiero asociar un evento a un grupo al que pertenezco, para publicar actividades en nombre de ese colectivo.

**Criterios de aceptación:**
- **Dado** que pertenezco a grupos, **cuando** creo un evento, **entonces** puedo seleccionar uno como organizador.
- **Dado** que no pertenezco a ningún grupo, **cuando** creo un evento, **entonces** el campo de grupo no muestra opciones.
- **Dado** que asocio un evento a un grupo, **cuando** se consulta su ficha, **entonces** el grupo aparece como organizador.
- **Dado** que intento asociar un evento a un grupo al que no pertenezco, **cuando** envío el formulario, **entonces** el sistema no permite la acción.

</details>

<details>
<summary><strong>HU-30</strong> · Programación de evento recurrente &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-46

**Historia:** Como organizador, quiero programar un evento como recurrente, para publicar actividades que se repiten sin crear cada fecha manualmente.

**Criterios de aceptación:**
- **Dado** que activo la recurrencia, **cuando** defino la frecuencia, **entonces** el sistema acepta la configuración.
- **Dado** que guardo un evento recurrente válido, **cuando** consulto mapa, lista o calendario, **entonces** aparecen las ocurrencias programadas.
- **Dado** que modifico la recurrencia, **cuando** guardo los cambios, **entonces** el sistema actualiza las ocurrencias futuras.
- **Dado** que ingreso una recurrencia inválida, **cuando** intento guardar, **entonces** el sistema muestra un mensaje de validación.

</details>

<details>
<summary><strong>HU-31</strong> · Cancelación de evento &nbsp;<code>Should Have</code></summary>

**RF/RNF:** RF-47, RF-30

**Historia:** Como organizador, quiero cancelar un evento, para informar que una actividad ya no se realizará.

**Criterios de aceptación:**
- **Dado** que soy organizador de un evento futuro, **cuando** selecciono cancelar, **entonces** el sistema solicita confirmación.
- **Dado** que confirmo la cancelación, **cuando** el sistema procesa la acción, **entonces** el evento queda marcado como cancelado.
- **Dado** que usuarios tenían notificaciones activas, **cuando** se cancela el evento, **entonces** reciben notificación de cancelación.
- **Dado** que no soy organizador, **cuando** intento cancelar, **entonces** el sistema no permite la acción.

</details>

---

### Módulo: Sistema de Amigos

<details>
<summary><strong>HU-32</strong> · Lista de amigos &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-48, RF-51

**Historia:** Como usuario comunitario, quiero ver mi lista de amigos y consultar sus perfiles, para mantener una red social básica dentro de la aplicación.

**Criterios de aceptación:**
- **Dado** que tengo amigos agregados, **cuando** ingreso a la pestaña de amigos, **entonces** veo mi lista de amigos.
- **Dado** que selecciono un amigo, **cuando** pulso sobre su nombre, **entonces** se abre su perfil en modo lectura.
- **Dado** que no tengo amigos, **cuando** ingreso a la pestaña, **entonces** el sistema muestra un estado vacío.
- **Dado** que un amigo modifica su información pública, **cuando** consulto su perfil, **entonces** veo la información actualizada autorizada.

</details>

<details>
<summary><strong>HU-33</strong> · Gestión de solicitudes de amistad &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-49, RF-50

**Historia:** Como usuario comunitario, quiero enviar, aceptar o rechazar solicitudes de amistad mediante correo institucional, para construir mi red de contactos.

**Criterios de aceptación:**
- **Dado** que conozco el correo de otro usuario, **cuando** envío una solicitud, **entonces** el sistema la registra como pendiente.
- **Dado** que recibo una solicitud, **cuando** la acepto, **entonces** el usuario se agrega a mi lista de amigos.
- **Dado** que recibo una solicitud, **cuando** la rechazo, **entonces** no se crea relación de amistad.
- **Dado** que el correo no está registrado o es inválido, **cuando** envío la solicitud, **entonces** el sistema informa que no puede completar la acción.

</details>

<details>
<summary><strong>HU-34</strong> · Eliminación de amigos &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-52

**Historia:** Como usuario comunitario, quiero eliminar amigos de mi lista, para mantener actualizada mi red de contactos.

**Criterios de aceptación:**
- **Dado** que tengo un usuario en mi lista, **cuando** selecciono eliminar, **entonces** el sistema solicita confirmación.
- **Dado** que confirmo la eliminación, **cuando** el sistema procesa la acción, **entonces** el usuario deja de aparecer en mi lista.
- **Dado** que elimino a un amigo, **cuando** ese usuario consulta su lista, **entonces** la relación también deja de estar activa para él.
- **Dado** que cancelo la confirmación, **cuando** regreso a la lista, **entonces** la amistad se conserva sin cambios.

</details>

<details>
<summary><strong>HU-35</strong> · Invitación de amigos a eventos &nbsp;<code>Could Have</code></summary>

**RF/RNF:** RF-53

**Historia:** Como usuario comunitario, quiero invitar a un amigo a un evento al que planeo asistir, para compartir actividades de interés.

**Criterios de aceptación:**
- **Dado** que confirmé asistencia a un evento, **cuando** selecciono invitar amigo, **entonces** puedo escoger un usuario de mi lista.
- **Dado** que envío una invitación, **cuando** el sistema la procesa, **entonces** el amigo recibe una notificación o registro de invitación.
- **Dado** que no he confirmado asistencia, **cuando** intento invitar a un amigo, **entonces** el sistema no permite completar la invitación.
- **Dado** que el evento no es visible para ese amigo, **cuando** intento invitarlo, **entonces** el sistema informa que no puede enviarse la invitación.

</details>

---

### Módulo: Ciclo de Vida y Notificaciones

<details>
<summary><strong>HU-36</strong> · Eliminación automática de eventos finalizados &nbsp;<code>Must Have</code></summary>

**RF/RNF:** RNF-10

**Historia:** Como usuario comunitario, quiero que los eventos finalizados se eliminen automáticamente, para mantener actualizada la información visible en la aplicación.

**Criterios de aceptación:**
- **Dado** que un evento finalizó, **cuando** transcurren 24 horas desde su hora de fin, **entonces** el sistema lo elimina automáticamente de las vistas activas.
- **Dado** que aún no han pasado 24 horas, **cuando** consulto las vistas, **entonces** el sistema puede conservarlo según la lógica definida.
- **Dado** que un evento fue eliminado por ciclo de vida, **cuando** consulto el mapa o la lista activa, **entonces** ya no aparece como disponible.
- **Dado** que el evento tenía chat asociado, **cuando** se elimina del ciclo activo, **entonces** el chat deja de estar disponible para nuevas interacciones.

</details>

---

## 7. User Story Map

El mapa de historias de usuario organiza visualmente las 35 HU en 3 sprints, agrupadas por módulo (épica) y columna de actividad/tarea.

```
unparche_usm.html   ← Abrir en navegador
unparche_usm.css    ← Estilos (debe estar en la misma carpeta)
```

| Sprint | Prioridad | Historias incluidas |
|---|---|---|
| **Sprint 1** | Must Have | HU-08, HU-09, HU-10, HU-11, HU-13, HU-15, HU-16, HU-20, HU-27, HU-28, HU-36 |
| **Sprint 2** | Should Have | HU-03, HU-14, HU-17, HU-19, HU-21, HU-22, HU-23, HU-25, HU-29, HU-30, HU-31 |
| **Sprint 3** | Could Have | HU-01, HU-02, HU-04, HU-05, HU-06, HU-07, HU-12, HU-18, HU-24, HU-26, HU-32, HU-33, HU-34, HU-35 |

---

*Proyecto académico — Universidad Nacional de Colombia, sede Bogotá.*