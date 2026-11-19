import json
import os
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.request import Request, build_opener, ProxyHandler

IMDS = "http://169.254.169.254/latest"
opener = build_opener(ProxyHandler({}))
load_lock = threading.Lock()
workers = []
next_run = 0


def instance_info():
    request = Request(f"{IMDS}/api/token", method="PUT", headers={
        "X-aws-ec2-metadata-token-ttl-seconds": "60",
    })
    with opener.open(request, timeout=2) as response:
        token = response.read().decode()
    metadata = {"version": "1.0"}
    for key, path in [("instance_id", "instance-id"), ("az", "placement/availability-zone")]:
        request = Request(f"{IMDS}/meta-data/{path}", headers={"X-aws-ec2-metadata-token": token})
        with opener.open(request, timeout=2) as response:
            metadata[key] = response.read().decode()
    return metadata


class PortalHandler(BaseHTTPRequestHandler):
    def respond(self, status, body):
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path == "/health":
            self.respond(200, {"status": "OK"})
            return
        if self.path != "/api/info":
            self.respond(404, {"error": "Ruta desconocida"})
            return
        try:
            info = instance_info()
        except OSError:
            self.respond(503, {"error": "Metadatos no disponibles"})
            return
        self.respond(200, info)

    def do_POST(self):
        global next_run
        if self.path != "/api/stress":
            self.respond(404, {"error": "Ruta desconocida"})
            return
        if self.headers.get("X-RompeCode-Test") != "1":
            self.respond(403, {"error": "Falta la cabecera de la prueba"})
            return
        with load_lock:
            if time.monotonic() < next_run or any(p.poll() is None for p in workers):
                self.respond(409, {"error": "Prueba en curso o en periodo de espera"})
                return
            workers.clear()
            next_run = time.monotonic() + 360
            for _ in range(os.cpu_count() or 1):
                workers.append(subprocess.Popen([
                    "/usr/bin/timeout", "300s", "/usr/bin/yes",
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
        self.respond(202, {"duration_seconds": 300})


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8080), PortalHandler).serve_forever()
