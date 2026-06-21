# Descripción del Proyecto

## ¿Qué es UNparche?

UNparche es una aplicación móvil diseñada exclusivamente para la comunidad universitaria de la **Universidad Nacional de Colombia (sede Bogotá)**. Su propósito es centralizar la difusión y el descubrimiento de eventos académicos, culturales, deportivos y sociales que ocurren dentro del campus, integrando:

- Un **mapa interactivo** con geolocalización precisa de cada evento (representado con un pin).
- Un **canal de comunicación en tiempo real (chat)** asociado a cada evento.

## Características principales

| Característica | Descripción |
|---|---|
| **Autenticación** | Exclusiva con correo institucional `@unal.edu.co` |
| **Alcance geográfico** | Campus UNAL Bogotá |
| **Roles de usuario** | Usuario Comunitario · Administrador |
| **Ventana de publicación** | Hasta 7 días antes del inicio del evento |
| **Ciclo de vida del evento** | Se elimina automáticamente 24 horas después de su hora de fin |
| **Chat por evento** | Sala de chat en tiempo real habilitada por el organizador |

### Chat por evento

Cada evento puede tener una sala de chat en tiempo real si el organizador la habilita. Es accesible desde el pin del mapa asociado y su propósito es permitir la comunicación entre los usuarios en torno al evento.

- Los participantes pueden enviar y leer mensajes; se muestran en orden cronológico con el nombre del autor y la hora de envío.
- Al abrir el chat, el usuario ve el historial de mensajes previos de esa sala.
- Los mensajes nuevos aparecen en tiempo real sin necesidad de recargar.

---

## Contexto del sistema

| Atributo | Descripción |
|---|---|
| **Naturaleza** | Aplicación móvil de tipo red social universitaria con componente de geolocalización |
| **Sector** | Educación superior pública |
| **Ecosistema** | Exclusivo de la Universidad Nacional de Colombia sede Bogotá |
| **Acceso** | Restringido mediante autenticación con correo institucional (`@unal.edu.co`) |

**Propósito central:** Centralizar el descubrimiento y difusión de eventos universitarios (académicos, culturales, deportivos, sociales) integrando mapa interactivo y chat en tiempo real.