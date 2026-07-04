#include "user.hpp"
#include "../chat/chat.hpp"
#include "../chat/chat_registry.hpp"
#include <boost/json.hpp>
#include <iostream>

namespace json = boost::json;

User::User(tcp::socket socket, ChatRegistry& registry)
    : socket_(std::move(socket)), registry_(registry) {}

void User::start() {
    readLine();
}

void User::readLine() {
    auto self = shared_from_this();
    asio::async_read_until(
        socket_, buffer_, '\n',
        [this, self](boost::system::error_code ec, std::size_t /*bytes*/) {
            if (ec) {
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
        std::cerr << "[User] linea invalida (no es JSON de objeto), se ignora\n";
        return;
    }

    json::object& obj = parsed.as_object();
    auto typeIt = obj.if_contains("type");
    if (!typeIt || !typeIt->is_string()) {
        std::cerr << "[User] mensaje sin campo 'type', se ignora\n";
        return;
    }

    const std::string type = typeIt->as_string().c_str();

    if (type == "join") {
        if (joined_) {
            return; // ya hizo join antes en esta conexion, se ignora
        }

        auto idEventoIt = obj.if_contains("id_evento");
        auto nicknameIt = obj.if_contains("nickname");

        if (!idEventoIt || !idEventoIt->is_number() ||
            !nicknameIt || !nicknameIt->is_string()) {
            std::cerr << "[User] join invalido: falta id_evento o nickname\n";
            return;
        }

        const int idEvento = static_cast<int>(idEventoIt->to_number<int64_t>());
        const std::string nickname = nicknameIt->as_string().c_str();

        if (nickname.empty()) {
            std::cerr << "[User] join invalido: nickname vacio\n";
            return;
        }

        handleJoin(idEvento, nickname);
        return;
    }

    if (type == "message") {
        if (!joined_) {
            std::cerr << "[User] mensaje recibido antes de join, se ignora\n";
            return;
        }

        auto contenidoIt = obj.if_contains("contenido");
        if (!contenidoIt || !contenidoIt->is_string()) {
            std::cerr << "[User] message invalido: falta contenido\n";
            return;
        }

        std::string contenido = contenidoIt->as_string().c_str();
        if (contenido.empty()) {
            return; // no se hace broadcast de mensajes vacios
        }

        handleMessage(contenido);
        return;
    }

    std::cerr << "[User] type desconocido: " << type << "\n";
}

void User::handleJoin(int id_evento, const std::string& nickname) {
    id_evento_ = id_evento;
    nickname_ = nickname;
    joined_ = true;

    chat_ = registry_.getOrCreate(id_evento_);
    chat_->addUser(shared_from_this());

    // Confirmacion al cliente de que el join fue exitoso.
    json::object ack;
    ack["type"] = "joined";
    ack["id_evento"] = id_evento_;
    ack["nickname"] = nickname_;
    deliver(json::serialize(ack));
}

void User::handleMessage(const std::string& contenido) {
    if (!chat_) {
        return;
    }
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
    if (chat_) {
        chat_->removeUser(this);
        chat_.reset();
    }

    boost::system::error_code ignored;
    socket_.shutdown(tcp::socket::shutdown_both, ignored);
    socket_.close(ignored);
}
