# Entidades del Sistema

Modelo de datos de UNparche. Cada entidad usa `UUID` como identificador primario.

---

## Usuario

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador único del usuario |
| `correoInstitucional` | String | Correo `@unal.edu.co`, único en el sistema |
| `contrasenaHash` | String | Contraseña almacenada cifrada (Argon2id) |
| `fotoPerfil` | URL / null | Imagen de perfil opcional |
| `carrera` | String / null | Programa académico opcional |
| `informacionPersonal` | Text / null | Texto libre de presentación opcional |
| `rol` | Enum | `COMUNITARIO`, `MODERADOR` |
| `fechaCreacion` | DateTime | Fecha de registro en el sistema |
| `activo` | Boolean | Indica si la cuenta está habilitada |

---

## Evento

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador único del evento |
| `titulo` | String | Nombre del evento (obligatorio) |
| `descripcion` | Text | Descripción detallada (obligatorio) |
| `fechaInicio` | DateTime | Fecha y hora de inicio (obligatorio) |
| `duracion` | Integer | Duración en minutos (obligatorio) |
| `fechaFin` | DateTime | Calculada: `fechaInicio + duracion` |
| `ubicacion` | GeoPoint | Coordenadas geográficas dentro del campus |
| `tipoEvento` | Enum | `Académico`, `Social`, `Cultural`, `Deportivo`, `Otro` |
| `chatHabilitado` | Boolean | Indica si el evento tiene chat activo |
| `organizadorId` | UUID | FK al Usuario creador |
| `estado` | Enum | `Programado`, `En_curso`, `Finalizado`, `Cancelado` |
| `fechaEliminacion` | DateTime | `fechaFin + 24 horas` (automática) |
| `fechaPublicacion` | DateTime | Fecha en que se publicó el evento |

---

## Asistencia

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador único |
| `usuarioId` | UUID | FK al Usuario |
| `eventoId` | UUID | FK al Evento |
| `estado` | Enum | `Confirmada`, `Cancelada` |
| `notificacionesActivas` | Boolean | Si el usuario activó notificaciones del evento |
| `fechaConfirmacion` | DateTime | Fecha en que se registró la asistencia |

---

## Amistad

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador único |
| `solicitanteId` | UUID | FK al Usuario que envió la solicitud |
| `receptorId` | UUID | FK al Usuario que recibe la solicitud |
| `estado` | Enum | `Pendiente`, `Aceptada`, `Rechazada`, `Eliminada` |
| `fechaSolicitud` | DateTime | Fecha de envío |
| `fechaRespuesta` | DateTime / null | Fecha de aceptación o rechazo |

---

## Anuncio

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador único |
| `eventoId` | UUID | FK al Evento |
| `autorId` | UUID | FK al Organizador |
| `contenido` | Text | Texto del anuncio |
| `fechaPublicacion` | DateTime | Timestamp del anuncio |

---

## Grupo

| Propiedad | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador único del grupo |
| `nombre` | String | Nombre del grupo (obligatorio) |
| `descripcion` | Text | Descripción del grupo |
| `categoria` | Enum | `Académico`, `Cultural`, `Social`, `Deportivo`, `Otro` |
| `esOficial` | Boolean | Indica si el grupo tiene verificación institucional |
| `estadoVerificacion` | Enum | `No_Solicitado`, `Pendiente`, `Rechazado`, `Cancelado` |
| `administradorId` | UUID | FK al Usuario administrador |
| `fechaCreacion` | DateTime | Fecha de creación del grupo |

---

## Invitación a Grupo

| Propiedad     | Tipo     | Descripción                          |
| ---------------| ----------| --------------------------------------|
| `id`          | UUID     | Identificador único                  |
| `grupoId`     | UUID     | FK al Grupo                          |
| `invitadoId`  | UUID     | FK al Usuario invitado               |
| `invitadorId` | UUID     | FK al Usuario que invita             |
| `estado`      | Enum     | `Pendiente`, `Aceptada`, `Rechazada` |
| `fechaEnvio`  | DateTime | Fecha de emisión de la invitación    |