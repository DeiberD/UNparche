SRCDIRS = . acceptor_logic api_backend chat user
BUILDDIR = build
OUTDIR = bin

# Busca los .cpp en la raiz y en cada subcarpeta de modulos
SOURCES = $(wildcard *.cpp) \
          $(wildcard acceptor_logic/*.cpp) \
          $(wildcard api_backend/*.cpp) \
          $(wildcard chat/*.cpp) \
		  $(wildcard user/*.cpp)

# Cada .cpp genera su .o dentro de build/, conservando el nombre
# (aplana la ruta: acceptor_logic/acceptor.cpp -> build/acceptor.o)
OBJECTS = $(patsubst %.cpp,$(BUILDDIR)/%.o,$(notdir $(SOURCES)))

# Nombre del ejecutable generado
EXECUTABLE = chat_server

# Poner la ruta completa de donde tengan ubicado Boost/OpenSSL
BOOST_INCLUDE = C:\\msys64\\ucrt64\\include
BOOST_LIB = C:\\msys64\\ucrt64\\lib

INC = -I"$(BOOST_INCLUDE)" -I.
CFLAGS = -std=c++20 -fcoroutines

# Antes de cada modulo o dependencia poner '-l' seguido del nombre
# boost_system NO se linkea: en tu instalacion no existe libboost_system
# (Boost moderno la volvio header-only, asi que no hace falta).
LIB = -L"$(BOOST_LIB)" \
	-lboost_json-mt \
	-lssl \
	-lcrypto \
	-lws2_32 \
	-lmswsock

# Variables de entorno para correr el server (make run)
CHAT_SERVER_PORT ?= 5000
UNPARCHE_API_HOST ?= 127.0.0.1
UNPARCHE_API_PORT ?= 8787
UNPARCHE_API_USE_TLS ?= false
UNPARCHE_API_EVENT_IDS_TARGET ?= /eventos/ids-actuales

# Regla de busqueda: le dice a make donde encontrar los .cpp de cada modulo
vpath %.cpp $(SRCDIRS)

$(OUTDIR)/$(EXECUTABLE): $(OBJECTS)
	@mkdir -p $(OUTDIR)
	@echo "Linkeando: "
	@echo "g++ $^ -o $(OUTDIR)/$(EXECUTABLE) $(LIB)"; \
	g++ $^ -o $(OUTDIR)/$(EXECUTABLE) $(LIB)

$(BUILDDIR)/%.o: %.cpp
	@mkdir -p $(BUILDDIR)
	g++ $(CFLAGS) $(INC) -c $< -o $@

run: $(OUTDIR)/$(EXECUTABLE)
	CHAT_SERVER_PORT=$(CHAT_SERVER_PORT) \
	UNPARCHE_API_HOST=$(UNPARCHE_API_HOST) \
	UNPARCHE_API_PORT=$(UNPARCHE_API_PORT) \
	UNPARCHE_API_USE_TLS=$(UNPARCHE_API_USE_TLS) \
	UNPARCHE_API_EVENT_IDS_TARGET=$(UNPARCHE_API_EVENT_IDS_TARGET) \
	./$(OUTDIR)/$(EXECUTABLE)

clean:
	rm -f $(BUILDDIR)/*.o
	rm -f $(OUTDIR)/$(EXECUTABLE)
