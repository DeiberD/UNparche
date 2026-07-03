// main.cpp

#include <boost/asio.hpp>
#include <iostream>
#include <unordered_map>
#include "acceptor_logic/acceptor.cpp"
#include "user/user.hpp"
#include "chat/chat.hpp"

namespace asio = boost::asio;
using tcp = asio::ip::tcp;


int main()
{
    try
    {
        asio::io_context io_context;

        const unsigned short port = 5000;
        std::unordered_map<int, Chat*> chats;

        tcp::endpoint endpoint(tcp::v4(), port);
        tcp::acceptor acceptor(io_context, endpoint);

        do_accept(io_context, acceptor, chats);
        io_context.run();
    }
    catch (const std::exception& e)
    {
        std::cerr << "Server error: " << e.what() << '\n';
        return 1;
    }

    return 0;
}