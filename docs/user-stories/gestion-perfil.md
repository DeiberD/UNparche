# Historias de Usuario — Gestión de Perfil

## HU-01 · Registro con correo institucional

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-01, RNF-01, RNF-02

> Como usuario comunitario, quiero crear una cuenta usando mi correo institucional @unal.edu.co, para acceder de forma restringida a la aplicación.

### Criterios de aceptación

- **Dado** que ingreso un correo con dominio `@unal.edu.co`, **cuando** completo nombre, apellido, contraseña y confirmación de contraseña, **entonces** el sistema permite crear la cuenta.
- **Dado** que ingreso un correo con un dominio diferente, **cuando** intento registrarme, **entonces** el sistema rechaza el registro e informa que solo se aceptan correos institucionales.
- **Dado** que la cuenta se crea correctamente, **cuando** se almacena la contraseña, **entonces** debe guardarse cifrada y no en texto plano.
- **Dado** que el registro fue exitoso, **cuando** inicio sesión, **entonces** el acceso debe completarse en menos de 3 segundos en condiciones normales.

---

## HU-02 · Edición básica del perfil

**Prioridad:** Could Have  
**RF/RNF relacionados:** RF-02, RF-03, RF-04, RNF-03, RNF-04

> Como usuario comunitario, quiero editar mi foto, carrera e información personal, para presentar una identidad básica dentro de la plataforma.

### Criterios de aceptación

- **Dado** que estoy autenticado, **cuando** ingreso a mi perfil, **entonces** puedo modificar mi foto, carrera e información personal.
- **Dado** que la carrera y la información personal son opcionales, **cuando** dejo esos campos vacíos, **entonces** el sistema permite guardar el perfil sin errores.
- **Dado** que guardo cambios válidos, **cuando** vuelvo a abrir mi perfil, **entonces** la información actualizada se muestra correctamente.
- **Dado** que otro usuario consulta mi perfil, **cuando** se carga la información, **entonces** solo debe mostrarse la información pública autorizada.

---

## HU-03 · Consulta del perfil de otro usuario

**Prioridad:** Should Have  
**RF/RNF relacionados:** RF-06, RF-07, RNF-03

> Como usuario comunitario, quiero consultar el perfil de otro usuario en modo lectura, para conocer información pública sobre esa persona y sus eventos visibles.

### Criterios de aceptación

- **Dado** que consulto el perfil de otro usuario, **cuando** se abre la vista de perfil, **entonces** no puedo editar su información.
- **Dado** que el usuario visitado permite mostrar sus eventos, **cuando** consulto su perfil, **entonces** veo los eventos a los que planea asistir.
- **Dado** que el usuario visitado restringió la visibilidad de sus eventos, **cuando** consulto su perfil, **entonces** esos eventos no se muestran.
- **Dado** que se muestra información del perfil, **cuando** otro usuario la visualiza, **entonces** el sistema debe respetar la privacidad configurada.