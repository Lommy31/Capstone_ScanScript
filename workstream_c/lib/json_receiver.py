
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import json

OUTPUT_DIR = Path(
    r"E:\Downloads\ScanScript\workstream_b\ocr_outputs"
)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


class JsonReceiver(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/upload-json":
            self.send_error(404)
            return

        try:
            length = int(self.headers.get("Content-Length", 0))
            if length <= 0 or length > 5_000_000:
                self.send_error(400, "Invalid file size")
                return

            data = json.loads(self.rfile.read(length).decode("utf-8"))

            # Validasi bahwa data benar-benar JSON
            filename = f"ocr_result_{data.get('image_id', 'unknown')}.json"
            filename = "".join(
                c for c in filename if c.isalnum() or c in "._-"
            )

            output_path = OUTPUT_DIR / filename
            output_path.write_text(
                json.dumps(data, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "ok",
                "file": str(output_path)
            }).encode("utf-8"))

            print(f"JSON tersimpan: {output_path}")

        except (ValueError, json.JSONDecodeError):
            self.send_error(400, "Invalid JSON")
        except Exception as exc:
            print(f"Error: {exc}")
            self.send_error(500, "Failed to save JSON")


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8001), JsonReceiver)
    print("Server penerima JSON berjalan di port 8001.")
    print(f"Folder output: {OUTPUT_DIR}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer dihentikan.")
    finally:
        server.server_close()

