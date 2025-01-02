from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading


class AuthCodeHandler(BaseHTTPRequestHandler):
    code = None

    def do_HEAD(self):
        self.send_response(200)

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        try:
            query_components = parse_qs(urlparse(self.path).query)
            AuthCodeHandler.code = query_components["code"][0]
            print("CODE: " + AuthCodeHandler.code)
        except IndexError:
            AuthCodeHandler.code = None


def run_server_get_auth_code(redirect_port):
    server_address = ('', redirect_port)
    with HTTPServer(server_address, AuthCodeHandler) as httpd:
        threading.Thread(target=httpd.serve_forever).start()
        while True:
            sleep(0.5)
            if AuthCodeHandler.code is None:
                continue
            httpd.shutdown()
            return AuthCodeHandler.code

