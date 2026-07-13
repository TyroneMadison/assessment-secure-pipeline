import json, logging, os, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

logging.basicConfig(stream=sys.stdout, level=logging.INFO, format="%(message)s")

class Handler(BaseHTTPRequestHandler):
    def _log(self, path, status):
        logging.info(json.dumps({"path": path, "status": status}))

    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "healthy"}).encode())
        else:
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok")
        self._log(self.path, 200)

    def log_message(self, format, *args):
        pass

HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
