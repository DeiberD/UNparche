#pragma once
#include <boost/asio/io_context.hpp>
#include <boost/system/detail/error_code.hpp>
#include "../chat/chat.hpp"
#include "../user/user.hpp"

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

// Acceptor logic
void do_accept(asio::io_context& io_context, tcp::acceptor& acceptor){

    // async acceptor function that receives as a parameter a lambda function with a reference to the main loop and the
    // acceptor object, the lambda is executed with every new connection
    acceptor.async_accept([&acceptor, &io_context](boost::system::error_code error, tcp::socket socket){

    });
}