# Historias de Usuario - Grupos

## HU-04 · Creación de grupo no oficial

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-08

> Como usuario comunitario, quiero crear un grupo no oficial, para organizar eventos en nombre de un colectivo dentro del campus.

### Criterios de aceptación

- **Dado** que estoy autenticado, **cuando** completo el nombre, descripción y categoría del grupo, **entonces** el sistema permite crear un grupo no oficial.
- **Dado** que creo un grupo, **cuando** se guarda correctamente, **entonces** quedo registrado como administrador del grupo.
- **Dado** que intento crear un grupo sin nombre, **cuando** envío el formulario, **entonces** el sistema solicita completar el campo obligatorio.
- **Dado** que el grupo fue creado, **cuando** se consulta en la plataforma, **entonces** aparece como no oficial y sin sello de verificación.

---

## HU-05 · Solicitud de verificación de grupo

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-09, RF-10

> Como administrador de un grupo, quiero solicitar la verificación oficial, para que el grupo sea reconocido visualmente como organización universitaria legítima.

### Criterios de aceptación

- **Dado** que administro un grupo no oficial, **cuando** ingreso a su configuración, **entonces** puedo enviar una solicitud de verificación.
- **Dado** que envío la solicitud, **cuando** adjunto o registro la evidencia requerida, **entonces** el sistema deja la solicitud pendiente de revisión.
- **Dado** que un grupo es aprobado como oficial, **cuando** aparece en la aplicación, **entonces** se muestra con un sello de verificado junto a su nombre.
- **Dado** que un grupo no ha sido verificado, **cuando** se muestra en la aplicación, **entonces** no debe aparecer con sello oficial.

---

## HU-06 · Invitación y pertenencia a grupos

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-05, RF-11

> Como usuario comunitario, quiero unirme a grupos únicamente mediante invitación, para evitar suplantaciones o publicaciones indebidas en nombre de organizaciones.

### Criterios de aceptación

- **Dado** que un miembro del grupo me envía una invitación, **cuando** la acepto, **entonces** el sistema me agrega como integrante del grupo.
- **Dado** que no he recibido invitación, **cuando** intento unirme directamente a un grupo, **entonces** el sistema no permite completar la unión.
- **Dado** que pertenezco a un grupo, **cuando** edito mi perfil, **entonces** puedo ver ese grupo dentro de mi información de pertenencia.
- **Dado** que acepto o rechazo una invitación, **cuando** se procesa la respuesta, **entonces** el estado de la invitación se actualiza correctamente.

---

## HU-07 · Exploración y filtrado de grupos

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-12, RF-13

> Como usuario comunitario, quiero explorar y filtrar grupos oficiales y no oficiales, para encontrar colectivos relacionados con mis intereses.

### Criterios de aceptación

- **Dado** que ingreso a la pestaña de grupos, **cuando** se carga la vista, **entonces** se listan grupos oficiales y no oficiales.
- **Dado** que aplico un filtro por tipo de grupo, **cuando** selecciono oficial o no oficial, **entonces** se muestran solo los grupos correspondientes.
- **Dado** que aplico un filtro por categoría, **cuando** confirmo el filtro, **entonces** la lista se actualiza según la categoría seleccionada.
- **Dado** que un grupo es oficial, **cuando** aparece en la lista, **entonces** se muestra con su sello de verificación.