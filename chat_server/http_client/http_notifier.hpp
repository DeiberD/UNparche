#pragma once
#include <boost/asio.hpp>
#include <string>
#include "../chat/message.hpp"

namespace asio = boost::asio;

// Dispara un POST HTTP asincrono y "fire-and-forget" hacia la API TS
// (unparche-api) cada vez que llega un mensaje nuevo, para que quede
// persistido en la tabla mensaje_chat. No bloquea el broadcast del chat:
// se lanza la corrutina y se sigue de inmediato: el resultado (exito/fallo)
// solo se loguea, nunca se espera.
//
// host/port/target/usa_tls se configuran una vez al arrancar el server
// (ver main.cpp) a partir de variables de entorno.
class HttpNotifier {
public:
    HttpNotifier(asio::io_context& io_context,
                 std::string host,
                 std::string port,
                 std::string target,
                 std::string internal_token);

    // Encola el POST del mensaje. Retorna inmediatamente (no bloquea).
    void notifyMessageAsync(const Message& message) const;

private:
    asio::io_context& io_context_;
    std::string host_;
    std::string port_;
    std::string target_;
    std::string internal_token_;
};