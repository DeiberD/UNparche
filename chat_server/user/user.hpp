#pragma once
#include <boost/asio.hpp>
#include <boost/asio/streambuf.hpp>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

class Chat; // forward declaration

class User{
private:
    tcp::socket socket;
    Chat* chat = nullptr;
    asio::streambuf buffer;
    std::string nickname;
    bool isAuth;

public:
    User(tcp::socket socket);
    void read();
    void sendMessage();
};