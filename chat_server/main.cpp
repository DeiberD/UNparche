// main.cpp
#include <boost/asio.hpp>
#include <iostream>
#include <cstdlib>
#include "acceptor_logic/acceptor.hpp"
#include "chat/chat_registry.hpp"
#include "http_client/http_notifier.hpp"

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

namespace {

// Lee una variable de entorno o retorna un default si no existe/esta vacia.
std::string envOr(const char* name, std::string defaultValue) {
    const char* value = std::getenv(name);
    if (value == nullptr || std::string(value).empty()) {
        return defaultValue;
    }
    return std::string(value);
}

} // namespace

int main()
{
    try
    {
        asio::io_context io_context;

        // Puerto donde el server de chat escucha conexiones TCP de los
        // clientes Flutter.
        const unsigned short port =
            static_cast<unsigned short>(std::stoi(envOr("CHAT_SERVER_PORT", "5000")));

        // Configuracion de la API TS (unparche-api) para el POST
        // fire-and-forget de persistencia de mensajes.
        const std::string apiHost = envOr("UNPARCHE_API_HOST", "unparche-api.example.workers.dev");
        const std::string apiPort = envOr("UNPARCHE_API_PORT", "443");
        const std::string apiTarget = envOr("UNPARCHE_API_MENSAJES_TARGET", "/internal/mensajes");
        const std::string internalToken = envOr("UNPARCHE_INTERNAL_TOKEN", "");

        HttpNotifier notifier(io_context, apiHost, apiPort, apiTarget, internalToken);
        ChatRegistry registry;

        tcp::endpoint endpoint(tcp::v4(), port);
        tcp::acceptor acceptor(io_context, endpoint);

        std::cout << "Chat server escuchando en puerto " << port << std::endl;
        std::cout << "Persistencia -> https://" << apiHost << apiTarget << std::endl;

        do_accept(io_context, acceptor, registry);

        io_context.run();
    }
    catch (const std::exception& e)
    {
        std::cerr << "Server error: " << e.what() << '\n';
        return 1;
    }

    return 0;
}