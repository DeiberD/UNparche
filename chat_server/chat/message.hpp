#pragma once
#include <string>
#include <chrono>

// Representa un mensaje ya validado y listo para difundir/persistir.
struct Message {
    int id_evento;
    std::string correo;
    std::string nickname;
    std::string contenido;
    long long timestamp_ms; // epoch millis, calculado por el server (fuente de verdad unica)

    static long long now_ms() {
        using namespace std::chrono;
        return duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
    }

    // Serializa el mensaje a JSON de una sola linea (sin '\n' incluido).
    // Escapado minimo (comillas, backslash, saltos de linea) suficiente para chat de texto.
    std::string toJsonLine() const;
};
