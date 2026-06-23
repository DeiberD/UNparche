#pragma once
#include <boost/asio.hpp>
#include <vector>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

class User; // forward declaration
class Message;

class Chat{
private:
    std::string eventName;
    std::vector<User*> users;
    std::vector<Message> messages;
    
public:
    void addUser(User* user);
    void removeUser(User* user);
    void receiveMessage(User* sender, Message& message);
};