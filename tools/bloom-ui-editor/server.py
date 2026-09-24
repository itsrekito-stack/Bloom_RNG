from __future__ import annotations

import json
import mimetypes
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
import subprocess
from collections import OrderedDict
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Optional

HOST = "127.0.0.1"
DEFAULT_PORT = 8765
ROOT = Path(os.environ.get("BLOOM_UI_ROOT", os.getcwd())).resolve()
CACHE_LIMIT = 256
BRIDGE_VERSION = 3

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


def run_git(*args: str, timeout: float = 20.0) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=str(ROOT),
        text=True,
        capture_output=True,
        timeout=timeout,
        check=False,
    )


def git_status_payload() -> dict:
    inside = run_git("rev-parse", "--is-inside-work-tree")
    if inside.returncode != 0 or inside.stdout.strip() != "true":
        return {"ok": False, "error": "Project root is not a Git working tree"}

    head = run_git("rev-parse", "HEAD")
    subject = run_git("log", "-1", "--pretty=%s")
    branch = run_git("branch", "--show-current")
    status = run_git("status", "--porcelain")
    return {
        "ok": True,
        "head": head.stdout.strip() if head.returncode == 0 else "",
        "subject": subject.stdout.strip() if subject.returncode == 0 else "",
        "branch": branch.stdout.strip() if branch.returncode == 0 else "",
        "dirty": bool(status.stdout.strip()),
        "changes": status.stdout.splitlines()[:30],
    }


def git_stash_entries() -> list[tuple[str, str]]:
    result = run_git("stash", "list", "--format=%gd%x09%gs")
    if result.returncode != 0:
        return []
    out: list[tuple[str, str]] = []
    for line in result.stdout.splitlines():
        if "\t" in line:
            ref, subject = line.split("\t", 1)
            out.append((ref.strip(), subject.strip()))
    return out


def safe_sync_git() -> tuple[int, dict]:
    status_before = git_status_payload()
    if not status_before.get("ok"):
        return 503, status_before

    old_head = status_before.get("head", "")
    dirty = bool(status_before.get("dirty"))
    stash_ref = ""
    stash_label = ""
    stashed = False
    restored = False

    if dirty:
        stash_label = f"Bloom UI Studio AI SYNC {int(time.time())}"
        try:
            stash = run_git("stash", "push", "-u", "-m", stash_label, timeout=30.0)
        except (subprocess.TimeoutExpired, OSError) as exc:
            return 500, {"ok": False, "stage": "stash", "error": str(exc)}
        if stash.returncode != 0:
            output = "\n".join(x for x in [stash.stdout.strip(), stash.stderr.strip()] if x)
            return 500, {"ok": False, "stage": "stash", "error": output or "git stash failed"}

        for ref, subject in git_stash_entries():
            if stash_label in subject:
                stash_ref = ref
                break
        if not stash_ref:
            return 500, {
                "ok": False,
                "stage": "stash",
                "error": "Локальные изменения были сохранены, но stash не удалось идентифицировать. Ничего не удалено.",
            }
        stashed = True

    try:
        pull = run_git("pull", "--ff-only", timeout=45.0)
    except (subprocess.TimeoutExpired, OSError) as exc:
        pull = None
        pull_error = str(exc)
    else:
        pull_error = ""

    if pull is None or pull.returncode != 0:
        output = pull_error
        if pull is not None:
            output = "\n".join(x for x in [pull.stdout.strip(), pull.stderr.strip()] if x) or "git pull --ff-only failed"

        restore_note = ""
        if stashed and stash_ref:
            try:
                restore = run_git("stash", "apply", stash_ref, timeout=30.0)
            except (subprocess.TimeoutExpired, OSError) as exc:
                restore = None
                restore_note = str(exc)
            if restore is not None and restore.returncode == 0:
                restored = True
                run_git("stash", "drop", stash_ref)
            elif restore is not None:
                restore_note = "\n".join(x for x in [restore.stdout.strip(), restore.stderr.strip()] if x)

        return 500, {
            "ok": False,
            "stage": "pull",
            "error": output,
            "stashed": stashed,
            "restored": restored,
            "stash_ref": stash_ref if stashed and not restored else "",
            "restore_error": restore_note,
        }

    status_after_pull = git_status_payload()
    new_head = status_after_pull.get("head", "")

    if stashed and stash_ref:
        try:
            restore = run_git("stash", "apply", stash_ref, timeout=30.0)
        except (subprocess.TimeoutExpired, OSError) as exc:
            return 500, {
                "ok": False,
                "stage": "restore",
                "error": str(exc),
                "changed": bool(old_head and new_head and old_head != new_head),
                "stashed": True,
                "restored": False,
                "stash_ref": stash_ref,
            }

        if restore.returncode != 0:
            status_conflict = git_status_payload()
            conflict_scan = run_git("diff", "--name-only", "--diff-filter=U")
            conflicts = [x for x in conflict_scan.stdout.splitlines() if x.strip()] if conflict_scan.returncode == 0 else []
            output = "\n".join(x for x in [restore.stdout.strip(), restore.stderr.strip()] if x)
            return 409, {
                "ok": False,
                "stage": "restore",
                "error": "Мои изменения подтянуты, но при возврате твоих локальных правок возник конфликт. Stash сохранён.",
                "details": output[-6000:],
                "conflicts": conflicts,
                "changed": bool(old_head and new_head and old_head != new_head),
                "stashed": True,
                "restored": False,
                "stash_ref": stash_ref,
                "dirty": status_conflict.get("dirty", True),
            }

        restored = True
        drop = run_git("stash", "drop", stash_ref)
        if drop.returncode != 0:
            return 500, {
                "ok": False,
                "stage": "drop",
                "error": "Локальные изменения возвращены, но временный stash не удалось удалить. Данные не потеряны.",
                "stash_ref": stash_ref,
                "changed": bool(old_head and new_head and old_head != new_head),
                "stashed": True,
                "restored": True,
            }

    status_final = git_status_payload()
    pull_output = "\n".join(x for x in [pull.stdout.strip(), pull.stderr.strip()] if x)
    return 200, {
        "ok": True,
        "changed": bool(old_head and new_head and old_head != new_head),
        "head": status_final.get("head", new_head),
        "subject": status_final.get("subject", ""),
        "dirty": status_final.get("dirty", False),
        "stashed": stashed,
        "restored": restored,
        "output": pull_output[-6000:],
    }


class BloomHandler(SimpleHTTPRequestHandler):
    server_version = "BloomUIStudio/1.0"

    def log_message(self, fmt: str, *args) -> None:
        print("[Bloom UI]", fmt % args)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self.end_headers()

    def do_GET(self) -> None:
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path == "/api/health":
            body = json.dumps({"ok": True, "server": "Bloom UI Studio", "bridge": BRIDGE_VERSION}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if parsed.path == "/api/git/status":
            payload = git_status_payload()
            body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(200 if payload.get("ok") else 503)
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


    def do_POST(self) -> None:
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path != "/api/git/pull":
            self.send_error(404, "Unknown endpoint")
            return

        status_code, payload = safe_sync_git()
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main() -> None:
    global ROOT
    import argparse

    parser = argparse.ArgumentParser(description="Bloom UI Studio local server")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--root", default=str(ROOT))
    args = parser.parse_args()

    root = Path(args.root).resolve()
    ROOT = root
    os.chdir(root)

    server = ThreadingHTTPServer((HOST, args.port), BloomHandler)
    print()
    print("Bloom UI Studio server")
    print(f"Root: {root}")
    print(f"URL : http://{HOST}:{args.port}/tools/bloom-ui-editor/index.html")
    print("Roblox thumbnail proxy: enabled")
    print(f"Assistant Bridge API: v{BRIDGE_VERSION}")
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
