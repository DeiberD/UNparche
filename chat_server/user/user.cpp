#include "user.hpp"

#include <nlohmann/json.hpp>
using json = nlohmann::json;

User::User(tcp::socket socket_) : socket(std::move(socket_)){

};

void User::read(){
    
};