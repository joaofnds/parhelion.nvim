"""usage: python3 -I serve.py OUT. Serves the review page review.sh wrote to OUT on a free local port, prints its
address, and saves each pick the page makes to OUT/picks.json."""
import functools
import http.server
import json
import os
import sys

out = sys.argv[1]
picks = os.path.join(out, "picks.json")


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_PUT(self):
        length = int(self.headers.get("Content-Length", 0))
        if self.path != "/picks.json" or not 0 < length < 1_000_000:
            self.send_error(400)
            return
        body = self.rfile.read(length)
        try:
            json.loads(body)
        except ValueError:
            self.send_error(400)
            return
        with open(picks + ".tmp", "wb") as f:
            f.write(body)
        os.replace(picks + ".tmp", picks)
        self.send_response(204)
        self.end_headers()

    def log_message(self, format, *args):
        pass


server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Handler, directory=out))
print(f"http://127.0.0.1:{server.server_address[1]}/review.html", flush=True)
server.serve_forever()
