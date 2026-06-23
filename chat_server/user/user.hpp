#pragma once
#include <boost/asio.hpp>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

class Chat; // forward declaration

class User{
private:
    tcp::socket socket;
    Chat* chat = nullptr;
    std::string nickname;
    bool isAuth;
    void authenticate(std::string username, Chat* chat);

public:
    void read();
    void sendMessage();
};