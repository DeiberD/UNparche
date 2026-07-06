#pragma once

#include <string>
#include <vector>

// Cliente para las rutas HTTP de unparche-api que necesita el servidor de chat.
// No mantiene estado: cada llamada abre y cierra su propia conexion.
class apiBackend {
public:
    // Consulta GET /eventos/ids-actuales y retorna las IDs recibidas.
    //
    // useTls debe ser false para el backend local de Wrangler (puerto 8787)
    // y true para el Worker desplegado por HTTPS (puerto 443).
    // Lanza std::runtime_error si falla la conexion, la API responde con error
    // o el cuerpo no es un arreglo JSON de numeros enteros.
    static std::vector<int> getCurrentEventIds(
        const std::string& host,
        const std::string& port,
        bool useTls,
        const std::string& target = "/eventos/ids-actuales");
};
