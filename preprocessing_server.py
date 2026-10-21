
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent
IMAGE_DIR = ROOT_DIR / "experiments" / "preprocessed"


class PreprocessingHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        prefix = "/preprocessed-image/"

        if not self.path.startswith(prefix):
            self.send_error(404, "Endpoint not found")
            return

        image_number = self.path[len(prefix):]

        if not image_number.isdigit():
            self.send_error(400, "Image number must be a number")
            return

        number = int(image_number)

        if not 1 <= number <= 10:
            self.send_error(404, "Image number must be between 1 and 10")
            return

        image_path = IMAGE_DIR / f"preprocessed_{number:02d}.png"

        if not image_path.is_file():
            self.send_error(404, "Preprocessed image not found")
            return

        image_data = image_path.read_bytes()

        self.send_response(200)
        self.send_header("Content-Type", "image/png")
        self.send_header("Content-Length", str(len(image_data)))
        self.end_headers()
        self.wfile.write(image_data)

    def log_message(self, format, *args):
        print(f"[HTTP] {args[0]}")


if __name__ == "__main__":
    server = ThreadingHTTPServer(
        ("0.0.0.0", 8000),
        PreprocessingHandler
    )

    print("Preprocessing server berjalan di port 8000.")
    print("Contoh: http://<IP-LAPTOP>:8000/preprocessed-image/1")
    print("Tekan Ctrl+C untuk menghentikan server.")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer dihentikan.")
    finally:
        server.server_close()
