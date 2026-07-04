#pragma once
#include <map>
#include <memory>
#include "chat.hpp"

class HttpNotifier;

// Punto unico de acceso a todas las salas de chat activas. El servidor es
// single-threaded (un solo io_context::run en main), asi que no hace falta
// mutex para proteger este mapa: todos los handlers async corren en el
// mismo hilo.
class ChatRegistry {
public:
    explicit ChatRegistry(HttpNotifier& notifier) : notifier_(notifier) {}

    // Retorna la sala del evento, creandola en memoria si aun no existe.
    std::shared_ptr<Chat> getOrCreate(int id_evento) {
        auto it = chats_.find(id_evento);
        if (it != chats_.end()) {
            return it->second;
        }
        auto chat = std::make_shared<Chat>(id_evento, notifier_);
        chats_.emplace(id_evento, chat);
        return chat;
    }

private:
    std::map<int, std::shared_ptr<Chat>> chats_;
    HttpNotifier& notifier_;
};