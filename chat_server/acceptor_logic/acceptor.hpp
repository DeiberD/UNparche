#include <boost/asio.hpp>

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

void do_accept(asio::io_context& io_context, tcp::acceptor& acceptor);