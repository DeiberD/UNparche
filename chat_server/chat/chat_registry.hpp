#pragma once
#include <memory>
#include <unordered_map>

class Chat;
class HttpNotifier;

// Punto unico de acceso a todas las salas de chat activas. El servidor es
// single-threaded (un solo io_context::run en main), asi que no hace falta
// mutex para proteger este mapa: todos los handlers async corren en el
// mismo hilo.
class ChatRegistry {
public:

    // Retorna la sala del evento si existe; si no, retorna nullptr.
    std::shared_ptr<Chat> getChat(int id_evento);

private:
    std::unordered_map<int, std::shared_ptr<Chat>> chats_;
};