# Cloudflare D1 - UNparche

Esta carpeta contiene la estructura de base de datos para la migración de UNparche desde MySQL hacia Cloudflare D1.

## Estructura

- `migrations/`: migraciones SQL ejecutables sobre Cloudflare D1.
- `seeds/`: datos iniciales o datos de prueba.
- `snapshots/`: copias consolidadas del esquema actual para consulta.
- `docs/`: notas técnicas sobre diferencias entre MySQL y D1.

## Fuente de verdad

El esquema original en MySQL se conserva en:

'database/mysql/'

A partir de la migración, el esquema ejecutable para Cloudflare D1 debe vivir en:

'database/d1/migrations/'

No se debe modificar la base directamente sin crear una migración.
