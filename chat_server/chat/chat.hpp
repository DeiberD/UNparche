#pragma once
#include <memory>
#include <string>
#include <vector>
#include "message.hpp"

class User; // forward declaration
class HttpNotifier;

// Sala de chat asociada a un evento especifico (id_evento). Vive en
// memoria mientras haya al menos una referencia activa (ver ChatRegistry).
// No conoce SQL ni nada de persistencia directamente: delega eso al
// HttpNotifier via fire-and-forget.
class Chat : public std::enable_shared_from_this<Chat> {
public:
    Chat(int id_evento, HttpNotifier& notifier);

    void addUser(const std::shared_ptr<User>& user);
    void removeUser(User* user);

    // Recibe un mensaje ya validado, lo hace broadcast a todos los
    // usuarios conectados a esta sala y dispara la persistencia async.
    void receiveMessage(const std::string& nickname, const std::string& contenido);

    int idEvento() const { return id_evento_; }
    size_t userCount() const { return users_.size(); }

private:
    int id_evento_;
    std::vector<std::shared_ptr<User>> users_;
    HttpNotifier& notifier_;
};