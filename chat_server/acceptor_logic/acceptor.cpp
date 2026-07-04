#include "acceptor.hpp"
#include "../chat/chat_registry.hpp"
#include "../user/user.hpp"
#include <iostream>
#include <memory>

void do_accept(asio::io_context& io_context, tcp::acceptor& acceptor, ChatRegistry& registry) {
    acceptor.async_accept(
        [&acceptor, &io_context, &registry](boost::system::error_code error, tcp::socket socket) {
            if (!error) {
                auto user = std::make_shared<User>(std::move(socket), registry);
                user->start();
            } else {
                std::cerr << "[acceptor] error al aceptar conexion: " << error.message() << "\n";
            }

            // Seguir aceptando la siguiente conexion, siempre.
            do_accept(io_context, acceptor, registry);
        });
}