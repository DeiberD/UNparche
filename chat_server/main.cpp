// main.cpp
#include <boost/asio.hpp>
#include <iostream>
#include <cstdlib>
#include "acceptor_logic/acceptor.hpp"
#include "api_backend/api_backend.hpp"
#include "chat/chat_registry.hpp"

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

bool envFlag(const char* name, bool defaultValue) {
    const std::string value = envOr(name, defaultValue ? "true" : "false");
    return value == "1" || value == "true" || value == "TRUE";
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

        const std::string apiHost = envOr("UNPARCHE_API_HOST", "127.0.0.1");
        const std::string apiPort = envOr("UNPARCHE_API_PORT", "8787");
        const bool apiUseTls = envFlag("UNPARCHE_API_USE_TLS", false);
        const std::string eventIdsTarget =
            envOr("UNPARCHE_API_EVENT_IDS_TARGET", "/eventos/ids-actuales");

        ChatRegistry registry;
        std::vector<int> eventIds = apiBackend::getCurrentEventIds(
            apiHost,
            apiPort,
            apiUseTls,
            eventIdsTarget);
        registry.registerEvents(eventIds);

        tcp::endpoint endpoint(tcp::v4(), port);
        tcp::acceptor acceptor(io_context, endpoint);

        std::cout << "Chat server escuchando en puerto " << port << std::endl;
        std::cout << "Chats registrados: " << eventIds.size() << std::endl;

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
