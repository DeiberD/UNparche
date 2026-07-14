#include "api_backend.hpp"

#include <boost/asio.hpp>
#include <boost/asio/ssl.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/ssl.hpp>
#include <boost/json.hpp>
#include <chrono>
#include <limits>
#include <stdexcept>

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace http = beast::http;
namespace json = boost::json;
namespace ssl = asio::ssl;
using tcp = asio::ip::tcp;

namespace {

std::vector<int> parseEventIds(const std::string& body) {
    boost::system::error_code ec;
    const json::value parsed = json::parse(body, ec);

    if (ec || !parsed.is_array()) {
        throw std::runtime_error(
            "La respuesta de /eventos/ids-actuales no es un arreglo JSON");
    }

    std::vector<int> eventIds;
    eventIds.reserve(parsed.as_array().size());

    for (const json::value& value : parsed.as_array()) {
        if (!value.is_int64()) {
            throw std::runtime_error(
                "La respuesta de /eventos/ids-actuales contiene una ID invalida");
        }

        const std::int64_t id = value.as_int64();
        if (id <= 0 || id > std::numeric_limits<int>::max()) {
            throw std::runtime_error(
                "La respuesta de /eventos/ids-actuales contiene una ID fuera de rango");
        }

        eventIds.push_back(static_cast<int>(id));
    }

    return eventIds;
}

http::request<http::empty_body> makeRequest(
    const std::string& host,
    const std::string& target) {
    http::request<http::empty_body> request{http::verb::get, target, 11};
    request.set(http::field::host, host);
    request.set(http::field::user_agent, "unparche-chat-server/1.0");
    request.set(http::field::accept, "application/json");
    return request;
}

template <typename Stream>
std::vector<int> sendRequest(
    Stream& stream,
    const std::string& host,
    const std::string& target) {
    auto request = makeRequest(host, target);
    http::write(stream, request);

    beast::flat_buffer buffer;
    http::response<http::string_body> response;
    http::read(stream, buffer, response);

    if (response.result() != http::status::ok) {
        throw std::runtime_error(
            "La API respondio HTTP " + std::to_string(response.result_int()));
    }

    return parseEventIds(response.body());
}

} // namespace

std::vector<int> apiBackend::getCurrentEventIds(
    const std::string& host,
    const std::string& port,
    bool useTls,
    const std::string& target) {
    asio::io_context ioContext;
    tcp::resolver resolver(ioContext);
    const auto endpoints = resolver.resolve(host, port);

    if (!useTls) {
        beast::tcp_stream stream(ioContext);
        stream.expires_after(std::chrono::seconds(5));
        stream.connect(endpoints);

        auto eventIds = sendRequest(stream, host, target);

        beast::error_code ec;
        stream.socket().shutdown(tcp::socket::shutdown_both, ec);
        return eventIds;
    }

    ssl::context sslContext(ssl::context::tls_client);
    sslContext.set_default_verify_paths();

    beast::ssl_stream<beast::tcp_stream> stream(ioContext, sslContext);
    stream.set_verify_mode(ssl::verify_peer);
    stream.set_verify_callback(ssl::host_name_verification(host));

    if (!SSL_set_tlsext_host_name(stream.native_handle(), host.c_str())) {
        throw std::runtime_error("No fue posible configurar SNI para " + host);
    }

    beast::get_lowest_layer(stream).expires_after(std::chrono::seconds(5));
    beast::get_lowest_layer(stream).connect(endpoints);
    stream.handshake(ssl::stream_base::client);

    auto eventIds = sendRequest(stream, host, target);

    beast::error_code ec;
    stream.shutdown(ec);
    return eventIds;
}
