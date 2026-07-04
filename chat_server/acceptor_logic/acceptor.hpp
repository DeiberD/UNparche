#pragma once
#include <boost/asio.hpp>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

class ChatRegistry;

// Acepta conexiones entrantes indefinidamente. Cada conexion nueva crea un
// User (shared_ptr) que arranca su propio ciclo de lectura async.
void do_accept(asio::io_context& io_context, tcp::acceptor& acceptor, ChatRegistry& registry);