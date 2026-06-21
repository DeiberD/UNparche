# Requisitos No Funcionales

## Módulo: Autenticación

| ID | Prioridad | Descripción |
|---|---|---|
| RNF-01 | Must | Las contraseñas de los usuarios deben almacenarse utilizando el algoritmo **Argon2id** con una sal aleatoria única por usuario. |
| RNF-02 | Must | El inicio de sesión debe completarse en menos de **3 segundos**. |

---

## Módulo: Perfil de Usuario

| ID     | Prioridad | Descripción                                                                                                 |
| --------| -----------| -------------------------------------------------------------------------------------------------------------|
| RNF-03 | Must      | El sistema debe mostrar únicamente la información que el usuario haya definido explícitamente como pública. |
| RNF-04 | Should    | La edición del perfil debería realizarse en máximo **tres pasos**.                                          |
| RNF-05 | Could     | El sistema podría permitir personalizar la imagen de perfil.                                                |

---

## Módulo: Mapa del Campus

| ID | Prioridad | Descripción |
|---|---|---|
| RNF-06 | Must | El mapa debe cargar en menos de **3 segundos**. |
| RNF-07 | Must | El mapa debe soportar en dispositivos **Android** las funcionalidades de navegación, zoom, agrupación de eventos y visualización de marcadores sin fallos de renderizado ni interrupciones de interacción. |
| RNF-08 | Should | El sistema debe determinar y mostrar ubicaciones dentro del campus con una desviación máxima de **10 metros** respecto a la posición real reportada por el dispositivo. |

---

## Módulo: Eventos

| ID | Prioridad | Descripción |
|---|---|---|
| RNF-09 | Must | El sistema debe validar fechas y campos obligatorios antes de publicar un evento. |
| RNF-10 | Must | Los eventos deben eliminarse automáticamente **24 horas** después de finalizar. |
| RNF-11 | Should | El sistema debería soportar al menos **1 000 eventos activos** simultáneamente. |

---

## Módulo: Chat

| ID     | Prioridad | Descripción                                                                                                                                                                                               |
| --------| -----------| -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| RNF-15 | Must      | El sistema debe permitir a los usuarios acceder a la funcionalidad de chat.                                                                                                                               |
| RNF-16 | Should    | Los mensajes deberían almacenarse mientras el evento permanezca activo.                                                                                                                                   |
| RNF-17 | Could     | El sistema debe restringir el envío de mensajes con una longitud superior a **300 caracteres** y limitar a cada usuario a un máximo de **5 mensajes** enviados dentro de un intervalo de **10 segundos**. |