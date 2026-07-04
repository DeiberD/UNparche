#include "message.hpp"
#include <boost/json.hpp>

namespace json = boost::json;

std::string Message::toJsonLine() const {
    json::object obj;
    obj["type"] = "message";
    obj["id_evento"] = id_evento;
    obj["nickname"] = nickname;
    obj["contenido"] = contenido;
    obj["timestamp_ms"] = timestamp_ms;
    return json::serialize(obj);
}