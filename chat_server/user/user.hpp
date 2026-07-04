#pragma once
#include <boost/asio.hpp>
#include <memory>
#include <string>
#include <deque>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

class Chat; // forward declaration
class ChatRegistry; // forward declaration

// Representa una conexion TCP activa de un cliente Flutter.
// La sesion del usuario en el chat = vida de este socket: no hay login,
// el usuario se identifica con un nickname libre enviado en el mensaje
// "join" inicial. Al desconectarse, el User se remueve de su Chat.
class User : public std::enable_shared_from_this<User> {
public:
    User(tcp::socket socket, ChatRegistry& registry);

    // Arranca el ciclo de lectura async. Debe llamarse justo despues de
    // construir el shared_ptr<User> (nunca desde el constructor).
    void start();

    // Envia una linea (mensaje ya serializado a JSON) a este cliente.
    // Fire-and-forget desde la perspectiva del llamador (broadcast).
    void deliver(const std::string& jsonLine);

    const std::string& nickname() const { return nickname_; }
    int idEvento() const { return id_evento_; }

private:
    void readLine();
    void handleLine(const std::string& line);
    void handleJoin(int id_evento, const std::string& nickname);
    void handleMessage(const std::string& contenido);
    void doWrite();
    void closeConnection();

    tcp::socket socket_;
    ChatRegistry& registry_;
    asio::streambuf buffer_;
    std::deque<std::string> writeQueue_;

    std::string nickname_;
    int id_evento_ = -1;
    bool joined_ = false;
    std::shared_ptr<Chat> chat_; // sala a la que pertenece una vez hace join
};