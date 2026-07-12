#include "user.hpp"
#include "../chat/chat.hpp"
#include "../chat/chat_registry.hpp"
#include <boost/json.hpp>
#include <atomic>
#include <iostream>

namespace json = boost::json;

namespace {

std::atomic<std::size_t> nextConnectionId{1};

std::string peerFromSocket(const tcp::socket& socket) {
    boost::system::error_code ec;
    const auto endpoint = socket.remote_endpoint(ec);
    if (ec) {
        return "peer-desconocido";
    }

    return endpoint.address().to_string() + ":" + std::to_string(endpoint.port());
}

std::string truncateForLog(const std::string& value, std::size_t maxSize = 160) {
    if (value.size() <= maxSize) {
        return value;
    }

    return value.substr(0, maxSize) + "...";
}

} // namespace

User::User(tcp::socket socket, ChatRegistry& registry)
    : socket_(std::move(socket)),
      registry_(registry),
      connectionId_(nextConnectionId.fetch_add(1)),
      peer_(peerFromSocket(socket_)) {}

void User::start() {
    logInfo("connect", "cliente conectado");
    readLine();
}

std::string User::logPrefix() const {
    return "[conn#" + std::to_string(connectionId_) + " " + peer_ + "]";
}

void User::logInfo(const std::string& action, const std::string& info) const {
    std::cout << logPrefix() << " " << action;
    if (!info.empty()) {
        std::cout << " - " << info;
    }
    std::cout << '\n';
}

void User::logError(const std::string& action, const std::string& info) const {
    std::cerr << logPrefix() << " " << action;
    if (!info.empty()) {
        std::cerr << " - " << info;
    }
    std::cerr << '\n';
}

void User::readLine() {
    auto self = shared_from_this();
    asio::async_read_until(
        socket_, buffer_, '\n',
        [this, self](boost::system::error_code ec, std::size_t /*bytes*/) {
            if (ec) {
                if (ec == asio::error::eof || ec == asio::error::connection_reset) {
                    logInfo("disconnect", "cliente cerro la conexion: " + ec.message());
                } else if (ec != asio::error::operation_aborted) {
                    logError("read_error", ec.message());
                }
                closeConnection();
                return;
            }

            std::istream is(&buffer_);
            std::string line;
            std::getline(is, line);
            // Tolerar CRLF si el cliente lo manda.
            if (!line.empty() && line.back() == '\r') {
                line.pop_back();
            }

            if (!line.empty()) {
                handleLine(line);
            }

            // Seguir leyendo la siguiente linea, sea cual sea el resultado
            // del mensaje anterior (un JSON invalido no debe tumbar la
            // conexion, solo se ignora).
            readLine();
        });
}

void User::handleLine(const std::string& line) {
    boost::system::error_code parseEc;
    json::value parsed = json::parse(line, parseEc);

    if (parseEc || !parsed.is_object()) {
        logError(
            "invalid_json",
            "linea ignorada: " + truncateForLog(line));
        return;
    }

    json::object& obj = parsed.as_object();
    auto typeIt = obj.if_contains("type");
    if (!typeIt || !typeIt->is_string()) {
        logError("invalid_message", "mensaje sin campo string 'type'");
        return;
    }

    const std::string type = typeIt->as_string().c_str();

    if (type == "join") {
        if (joined_) {
            logInfo("join_ignored", "la conexion ya estaba autenticada");
            return; // ya hizo join antes en esta conexion, se ignora
        }

        auto idEventoIt = obj.if_contains("id_evento");
        auto nicknameIt = obj.if_contains("nickname");

        if (!idEventoIt || !idEventoIt->is_number() ||
            !nicknameIt || !nicknameIt->is_string()) {
            logError("join_invalid", "falta id_evento o nickname");
            return;
        }

        const int idEvento = static_cast<int>(idEventoIt->to_number<int64_t>());
        const std::string nickname = nicknameIt->as_string().c_str();

        if (nickname.empty()) {
            logError("join_invalid", "nickname vacio");
            return;
        }

        logInfo(
            "join_attempt",
            "id_evento=" + std::to_string(idEvento) + " nickname=" + nickname);
        handleJoin(idEvento, nickname);
        return;
    }

    if (type == "message") {
        if (!joined_) {
            logError("message_ignored", "mensaje recibido antes de join");
            return;
        }

        auto contenidoIt = obj.if_contains("contenido");
        if (!contenidoIt || !contenidoIt->is_string()) {
            logError("message_invalid", "falta contenido");
            return;
        }

        std::string contenido = contenidoIt->as_string().c_str();
        if (contenido.empty()) {
            logInfo("message_ignored", "contenido vacio");
            return; // no se hace broadcast de mensajes vacios
        }

        handleMessage(contenido);
        return;
    }

    logError("unknown_type", type);
}

void User::handleJoin(int id_evento, const std::string& nickname) {
    chat_ = registry_.getChat(id_evento);
    if (!chat_) {
        logError(
            "join_rejected",
            "no existe chat para id_evento=" + std::to_string(id_evento));
        json::object err;
        err["type"] = "error";
        err["message"] = "No se encontro el chat";
        deliver(json::serialize(err));
        closeConnection();  // se intentó conectar a un chat inexistente
        return;
    }

    nickname_ = nickname;
    joined_ = true;

    chat_->addUser(shared_from_this());
    logInfo(
        "join_ok",
        "id_evento=" + std::to_string(id_evento) + " nickname=" + nickname_);

    // Enviar historial almacenado en memoria al usuario que recien se unio
    chat_->loadChat(shared_from_this());

    // Confirmacion al cliente de que el join fue exitoso.
    json::object ack;
    ack["type"] = "joined";
    ack["id_evento"] = id_evento;
    ack["nickname"] = nickname_;
    deliver(json::serialize(ack));
}

void User::handleMessage(const std::string& contenido) {
    if (!chat_) {
        logError("message_ignored", "no hay chat asociado a la conexion");
        return;
    }
    logInfo(
        "message",
        "nickname=" + nickname_ + " contenido=\"" + truncateForLog(contenido) + "\"");
    chat_->receiveMessage(nickname_, contenido);
}

void User::deliver(const std::string& jsonLine) {
    auto self = shared_from_this();
    const bool writeInProgress = !writeQueue_.empty();
    writeQueue_.push_back(jsonLine + "\n");

    if (!writeInProgress) {
        doWrite();
    }
}

void User::doWrite() {
    auto self = shared_from_this();
    asio::async_write(
        socket_, asio::buffer(writeQueue_.front()),
        [this, self](boost::system::error_code ec, std::size_t /*bytes*/) {
            if (ec) {
                if (ec != asio::error::operation_aborted) {
                    logError("write_error", ec.message());
                }
                closeConnection();
                return;
            }

            writeQueue_.pop_front();
            if (!writeQueue_.empty()) {
                doWrite();
            }
        });
}

void User::closeConnection() {
    if (closed_) {
        return;
    }
    closed_ = true;

    logInfo(
        "close",
        joined_ ? "cerrando conexion nickname=" + nickname_ : "cerrando conexion sin join");

    if (chat_) {
        chat_->removeUser(this);
        chat_.reset();
    }

    try {
        socket_.shutdown(tcp::socket::shutdown_both);
    } catch (...) {
    }

    try {
        socket_.close();
    } catch (...) {
    }
}
