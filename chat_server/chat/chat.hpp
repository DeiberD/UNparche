#pragma once
#include <memory>
#include <string>
#include <vector>
#include "message.hpp"

class User; // forward declaration

// Sala de chat asociada a un evento especifico (id_evento). Vive en
// memoria mientras haya al menos una referencia activa (ver ChatRegistry).
// No conoce SQL ni nada de persistencia
class Chat : public std::enable_shared_from_this<Chat> {
public:
    Chat();

    void addUser(const std::shared_ptr<User>& user);
    void removeUser(User* user);

    // Recibe un mensaje ya validado, lo hace broadcast a todos los
    // usuarios conectados a esta sala y dispara la persistencia async.
    void receiveMessage(const std::string& nickname, const std::string& contenido);

    size_t userCount() const { return users_.size(); }

    // Envia al 'user' todos los mensajes almacenados en memoria (historial).
    void loadChat(const std::shared_ptr<User>& user);

private:
    std::vector<std::shared_ptr<User>> users_;
    std::vector<Message> messages_;
};