#include "chat_registry.hpp"
#include "chat.hpp"
#include <algorithm>

std::shared_ptr<Chat> ChatRegistry::getChat(int id_evento) {
    auto it = chats_.find(id_evento);
    if (it != chats_.end()) {
        return it->second;
    }
    return nullptr;
}

void ChatRegistry::registerEvents(const std::vector<int>& eventIds) {
    for (int id : eventIds) {
        chats_.try_emplace(id, std::make_shared<Chat>(id));
    }
}

std::vector<int> ChatRegistry::registeredEventIds() const {
    std::vector<int> ids;
    ids.reserve(chats_.size());

    for (const auto& [id, chat] : chats_) {
        ids.push_back(id);
    }

    std::sort(ids.begin(), ids.end());
    return ids;
}
