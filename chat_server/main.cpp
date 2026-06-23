// main.cpp

#include <boost/asio.hpp>
#include <iostream>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;



int main()
{
    try
    {
        asio::io_context io_context;

        const unsigned short port = 5000;

        tcp::endpoint endpoint(tcp::v4(), port);
        tcp::acceptor acceptor(io_context, endpoint);

        io_context.run();
    }
    catch (const std::exception& e)
    {
        std::cerr << "Server error: " << e.what() << '\n';
        return 1;
    }

    return 0;
}