CXX := g++
TARGET := chat_server

SOURCES := $(wildcard *.cpp) \
	$(wildcard acceptor_logic/*.cpp) \
	$(wildcard api_backend/*.cpp) \
	$(wildcard chat/*.cpp) \
	$(wildcard user/*.cpp)

CXXFLAGS := -std=c++20 -Wall -Wextra -O2 -I.
LDLIBS := -lboost_json -lssl -lcrypto -pthread

.PHONY: all run clean

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CXX) $(CXXFLAGS) $(SOURCES) -o $(TARGET) $(LDLIBS)

run: $(TARGET)
	./$(TARGET)

clean:
	$(RM) $(TARGET)
