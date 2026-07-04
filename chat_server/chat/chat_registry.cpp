#include "chat_registry.hpp"
#include "chat.hpp"

std::shared_ptr<Chat> ChatRegistry::getChat(int id_evento) {
    auto it = chats_.find(id_evento);
    if (it != chats_.end()) {
        return it->second;
    }
    return nullptr;
}