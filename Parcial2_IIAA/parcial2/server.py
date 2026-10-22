from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from http.cookies import SimpleCookie
import secrets
import crud_usuarios_usss016325

import json

port = 3000
crudUsuarios = crud_usuarios_usss016325.crud_usuarios_usss016325()

# sesiones abiertas: token -> datos del usuario
sesiones = {}


class miServidor(SimpleHTTPRequestHandler):
    # ---------- utilidades ----------
    def token_sesion(self):
        cookie = SimpleCookie(self.headers.get('Cookie', ''))
        return cookie['sesion'].value if 'sesion' in cookie else None

    def hay_sesion(self):
        return self.token_sesion() in sesiones

    def responder_json(self, datos, extra_headers=None):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        for k, v in (extra_headers or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(json.dumps(datos).encode("utf-8"))

    def redirigir(self, destino):
        self.send_response(302)
        self.send_header("Location", destino)
        self.end_headers()

    # ---------- POST ----------
    def do_POST(self):
        longitud = int(self.headers['Content-Length'])
        datos = json.loads(self.rfile.read(longitud).decode("utf-8"))
        modulo = datos.get("modulo")

        # El login es lo unico que se puede usar sin sesion
        if modulo == "login":
            usuario = crudUsuarios.login(datos)
            if usuario:
                token = secrets.token_hex(16)
                sesiones[token] = usuario
                return self.responder_json(
                    {'msg': 'ok', 'nombre': usuario['nombre']},
                    {'Set-Cookie': f'sesion={token}; Path=/; HttpOnly'})
            return self.responder_json({'msg': 'Usuario o clave incorrectos. Acceso denegado'})

        if modulo == "logout":
            sesiones.pop(self.token_sesion(), None)
            return self.responder_json(
                {'msg': 'ok'},
                {'Set-Cookie': 'sesion=; Path=/; Max-Age=0'})

        if not self.hay_sesion():
            return self.responder_json({'msg': 'Acceso denegado, inicie sesion'})

        if modulo == "usuario":
            respuesta = {'msg': crudUsuarios.crud_usuarios_usss016325(datos)}
        else:
            respuesta = {'msg': 'Modulo desconocido'}
        self.responder_json(respuesta)

    # ---------- GET ----------
    def do_GET(self):
        urlParse = urlparse(self.path)
        qs = parse_qs(urlParse.query)

        # La pagina de login es publica y es lo primero que se muestra
        if urlParse.path in ("/", "/login", "/login.html"):
            if self.hay_sesion():
                return self.redirigir("/sistema")
            self.path = "/login.html"
            return SimpleHTTPRequestHandler.do_GET(self)

        # Todo lo demas exige haber iniciado sesion
        if not self.hay_sesion():
            if urlParse.path.endswith((".js", ".css")) or urlParse.path == "/favicon.ico":
                return SimpleHTTPRequestHandler.do_GET(self)
            return self.redirigir("/")

        if urlParse.path in ("/sistema", "/index.html"):
            self.path = "/index.html"
            return SimpleHTTPRequestHandler.do_GET(self)

        elif urlParse.path == "/usuarios":
            buscar = qs.get('buscar', [''])[0]
            self.responder_json(crudUsuarios.consultar(buscar))

        elif urlParse.path == "/vistas":
            self.path = f"/modulos/{qs.get('form', [''])[0]}.html"
            return SimpleHTTPRequestHandler.do_GET(self)

        else:
            return SimpleHTTPRequestHandler.do_GET(self)


print(f"Servidor corriendo en el puerto {port}")
server = HTTPServer(("localhost", port), miServidor)
server.serve_forever()
