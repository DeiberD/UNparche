#include "chat.hpp"
#include "../user/user.hpp"
#include "../http_client/http_notifier.hpp"
#include <algorithm>

Chat::Chat(int id_evento, HttpNotifier& notifier)
    : id_evento_(id_evento), notifier_(notifier) {}

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
    Message message{id_evento_, nickname, contenido, Message::now_ms()};
    const std::string jsonLine = message.toJsonLine();

    // Broadcast a todos los usuarios conectados a esta sala (incluido el
    // remitente, para que el cliente confirme entrega/orden con la copia
    // "oficial" del server, que incluye timestamp_ms del server).
    for (const auto& u : users_) {
        u->deliver(jsonLine);
    }

    // Persistencia fire-and-forget: no bloquea el broadcast de arriba.
    notifier_.notifyMessageAsync(message);
}
