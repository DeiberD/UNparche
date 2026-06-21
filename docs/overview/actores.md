# Actores del Sistema

## Actor 1 — Usuario Comunitario

| Atributo | Descripción |
|---|---|
| **Descripción** | Miembro activo de la comunidad UNAL Bogotá: estudiante de pregrado o posgrado, docente o personal administrativo con correo `@unal.edu.co`. Es el actor principal del sistema, consume y crea contenido. |
| **Rango de edad** | 16 – 80 años. La mayoría entre 18 y 35 (estudiantes de pregrado y posgrado). |
| **Género** | Mixto, sin restricción de género. |
| **Gustos / intereses** | Actividades culturales, deportes universitarios, conferencias académicas, conciertos, ferias, grupos estudiantiles, hackathons, vida social del campus. |
| **Discapacidad** | Se contempla el uso por personas con discapacidad visual parcial (contraste y tamaño de texto) y motriz leve (navegación táctil en mapa). No se modelan flujos específicos de accesibilidad en esta versión, pero el sistema no debe excluirlos activamente. |
| **Permisos** | Crear eventos, confirmar asistencia, chatear, agregar amigos, crear grupos, suscribirse a notificaciones. |

---

## Actor 2 — Organizador

| Atributo | Descripción |
|---|---|
| **Descripción** | Usuario comunitario que ha creado al menos un evento. **No es un rol separado**; cualquier Usuario Comunitario autenticado puede convertirse en organizador al publicar un evento. |
| **Rango de edad** | 16 – 80 años. |
| **Género** | Mixto, sin restricción de género. |
| **Gustos / intereses** | Liderazgo estudiantil, gestión de comunidades, difusión de actividades académicas o culturales, coordinación de grupos universitarios. |
| **Discapacidad** | Se contempla el uso por personas con discapacidad visual parcial (contraste y tamaño de texto) y motriz leve (navegación táctil en mapa). No se modelan flujos específicos de accesibilidad en esta versión, pero el sistema no debe excluirlos activamente. |
| **Permisos adicionales** | Editar, cancelar y eliminar sus propios eventos. |

---

## Actor 3 — Moderador de Plataforma

| Atributo | Descripción |
|---|---|
| **Descripción** | Usuario con permisos elevados asignados por la plataforma. Supervisa el contenido publicado y garantiza el cumplimiento de las políticas universitarias. Actualmente catalogado como **Won't Have** en el alcance del proyecto. |
| **Rango de edad** | 25 – 55 años. Personal administrativo o técnico designado por la aplicación. |
| **Género** | Mixto, sin restricción de género. |
| **Gustos / intereses** | Administración de plataformas, cumplimiento normativo, comunidad digital universitaria. |
| **Discapacidad** | Sin restricciones modeladas. |
| **Permisos adicionales** | Eliminar eventos y perfiles, emitir anuncios globales, verificar grupos oficiales. |

> El módulo de Moderación está clasificado como **Won't Have** en el alcance actual del proyecto.