#include "chat.hpp"
#include "../user/user.hpp"
#include <algorithm>

void Chat::addUser(const std::shared_ptr<User>& user) {
    users_.push_back(user);
}

void Chat::removeUser(User* user) {
    users_.erase(
        std::remove_if(
            users_.begin(), users_.end(),
            [user](const std::shared_ptr<User>& u) { return u.get() == user; }),
        users_.end());
}

void Chat::receiveMessage(const std::string& nickname, const std::string& contenido) {
    Message message{ nickname, contenido, Message::now_ms() };
    const std::string jsonLine = message.toJsonLine();

    // Guardar en el historial en memoria
    messages_.push_back(message);

    // Broadcast a todos los usuarios conectados a esta sala (incluido el
    // remitente, para que el cliente confirme entrega/orden con la copia
    // "oficial" del server, que incluye timestamp_ms del server).
    for (const auto& u : users_) {
        u->deliver(jsonLine);
    }
}

void Chat::loadChat(const std::shared_ptr<User>& user) {
    for (const auto& msg : messages_) {
        user->deliver(msg.toJsonLine());
    }
}
