#include "http_notifier.hpp"

#include <boost/asio/co_spawn.hpp>
#include <boost/asio/detached.hpp>
#include <boost/asio/awaitable.hpp>
#include <boost/asio/use_awaitable.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/ssl.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/ssl.hpp>
#include <boost/json.hpp>
#include <iostream>

namespace beast = boost::beast;
namespace http = beast::http;
namespace json = boost::json;
namespace ssl = asio::ssl;
using tcp = asio::ip::tcp;

HttpNotifier::HttpNotifier(asio::io_context& io_context,
                            std::string host,
                            std::string port,
                            std::string target,
                            std::string internal_token)
    : io_context_(io_context),
      host_(std::move(host)),
      port_(std::move(port)),
      target_(std::move(target)),
      internal_token_(std::move(internal_token)) {}

namespace {

// Corrutina que hace todo el trabajo: resolver, conectar TLS, enviar POST,
// leer respuesta (solo para drenar el socket) y cerrar. Cualquier error se
// loguea y se descarta: nunca debe tumbar el server ni afectar el chat.
asio::awaitable<void> doPost(asio::io_context& io_context,
                              std::string host,
                              std::string port,
                              std::string target,
                              std::string token,
                              std::string body) {
    try {
        auto executor = co_await asio::this_coro::executor;

        tcp::resolver resolver(executor);
        auto const results = co_await resolver.async_resolve(host, port, asio::use_awaitable);

        // La API TS (Cloudflare Workers) sirve solo HTTPS.
        ssl::context ctx(ssl::context::tlsv12_client);
        ctx.set_default_verify_paths();

        beast::ssl_stream<beast::tcp_stream> stream(io_context, ctx);

        if (!SSL_set_tlsext_host_name(stream.native_handle(), host.c_str())) {
            std::cerr << "[HttpNotifier] fallo SNI para " << host << "\n";
            co_return;
        }

        beast::get_lowest_layer(stream).expires_after(std::chrono::seconds(5));
        co_await beast::get_lowest_layer(stream).async_connect(results, asio::use_awaitable);

        beast::get_lowest_layer(stream).expires_after(std::chrono::seconds(5));
        co_await stream.async_handshake(ssl::stream_base::client, asio::use_awaitable);

        http::request<http::string_body> req{http::verb::post, target, 11};
        req.set(http::field::host, host);
        req.set(http::field::user_agent, "unparche-chat-server/1.0");
        req.set(http::field::content_type, "application/json");
        if (!token.empty()) {
            req.set("X-Internal-Token", token);
        }
        req.body() = std::move(body);
        req.prepare_payload();

        beast::get_lowest_layer(stream).expires_after(std::chrono::seconds(5));
        co_await http::async_write(stream, req, asio::use_awaitable);

        beast::flat_buffer buffer;
        http::response<http::string_body> res;
        co_await http::async_read(stream, buffer, res, asio::use_awaitable);

        if (res.result_int() >= 400) {
            std::cerr << "[HttpNotifier] respuesta " << res.result_int()
                      << " al persistir mensaje\n";
        }

        // Cierre best-effort; ignoramos errores de shutdown (comun en TLS,
        // el peer suele cerrar abruptamente tras responder).
        beast::error_code ec;
        co_await stream.async_shutdown(asio::redirect_error(asio::use_awaitable, ec));
    } catch (const std::exception& e) {
        // Fire-and-forget: un fallo de red/persistencia no debe afectar el chat.
        std::cerr << "[HttpNotifier] error al notificar mensaje: " << e.what() << "\n";
    }
    co_return;
}

} // namespace

void HttpNotifier::notifyMessageAsync(const Message& message) const {
    json::object body;
    body["id_evento"] = message.id_evento;
    body["nickname"] = message.nickname;
    body["contenido"] = message.contenido;
    body["timestamp_ms"] = message.timestamp_ms;

    asio::co_spawn(
        io_context_,
        doPost(io_context_, host_, port_, target_, internal_token_, json::serialize(body)),
        asio::detached);
}