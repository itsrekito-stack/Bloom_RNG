from __future__ import annotations

import json
import mimetypes
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import OrderedDict
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Optional

HOST = "127.0.0.1"
DEFAULT_PORT = 8765
ROOT = Path(os.environ.get("BLOOM_UI_ROOT", os.getcwd())).resolve()
CACHE_LIMIT = 256

_thumbnail_cache: "OrderedDict[str, tuple[bytes, str]]" = OrderedDict()


def fetch_url(url: str, timeout: float = 8.0) -> tuple[bytes, str]:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "BloomUIStudio/1.0",
            "Accept": "application/json,image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        body = resp.read()
        ctype = resp.headers.get_content_type() or "application/octet-stream"
        return body, ctype


def roblox_thumbnail(asset_id: str) -> Optional[tuple[bytes, str]]:
    cached = _thumbnail_cache.get(asset_id)
    if cached is not None:
        _thumbnail_cache.move_to_end(asset_id)
        return cached

    query = urllib.parse.urlencode(
        {
            "assetIds": asset_id,
            "returnPolicy": "PlaceHolder",
            "size": "420x420",
            "format": "Png",
            "isCircular": "false",
        }
    )
    api_url = "https://thumbnails.roblox.com/v1/assets?" + query

    image_url = None
    for attempt in range(4):
        try:
            raw, _ = fetch_url(api_url)
            payload = json.loads(raw.decode("utf-8"))
            rows = payload.get("data") or []
            if rows:
                row = rows[0]
                image_url = row.get("imageUrl")
                state = str(row.get("state") or "").lower()
                if image_url:
                    break
                if state not in {"pending", "inreview"}:
                    break
        except Exception:
            if attempt == 3:
                return None
        time.sleep(0.2 + attempt * 0.15)

    if not image_url:
        return None

    try:
        image_bytes, content_type = fetch_url(image_url)
    except Exception:
        return None

    if not content_type.startswith("image/"):
        content_type = "image/png"

    result = (image_bytes, content_type)
    _thumbnail_cache[asset_id] = result
    _thumbnail_cache.move_to_end(asset_id)
    while len(_thumbnail_cache) > CACHE_LIMIT:
        _thumbnail_cache.popitem(last=False)
    return result


class BloomHandler(SimpleHTTPRequestHandler):
    server_version = "BloomUIStudio/1.0"

    def log_message(self, fmt: str, *args) -> None:
        print("[Bloom UI]", fmt % args)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self) -> None:
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path == "/api/health":
            body = b'{"ok":true,"server":"Bloom UI Studio"}'
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path == "/api/thumbnail":
            qs = urllib.parse.parse_qs(parsed.query)
            asset_id = (qs.get("id") or [""])[0]
            if not re.fullmatch(r"\d{1,20}", asset_id):
                self.send_error(400, "Invalid asset id")
                return

            result = roblox_thumbnail(asset_id)
            if result is None:
                self.send_error(404, "Roblox thumbnail unavailable")
                return

            body, content_type = result
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "public, max-age=3600")
            self.end_headers()
            self.wfile.write(body)
            return

        super().do_GET()


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Bloom UI Studio local server")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--root", default=str(ROOT))
    args = parser.parse_args()

    root = Path(args.root).resolve()
    os.chdir(root)

    server = ThreadingHTTPServer((HOST, args.port), BloomHandler)
    print()
    print("Bloom UI Studio server")
    print(f"Root: {root}")
    print(f"URL : http://{HOST}:{args.port}/tools/bloom-ui-editor/index.html")
    print("Roblox thumbnail proxy: enabled")
    print("Close this window to stop the server.")
    print()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
