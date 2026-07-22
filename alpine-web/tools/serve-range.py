#!/usr/bin/env python3
"""Small static server with single-range responses for v86 local testing."""

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import os
from urllib.parse import urlsplit


class RangeHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        return super().translate_path(urlsplit(path).path)

    def send_head(self):
        path = self.translate_path(self.path)
        if not self.headers.get("Range") or os.path.isdir(path):
            return super().send_head()
        try:
            file = open(path, "rb")
        except OSError:
            self.send_error(404)
            return None

        size = self.headers.get("Range")
        if not size.startswith("bytes="):
            file.close()
            self.send_error(416)
            return None

        start, end = size.removeprefix("bytes=").split("-", 1)
        total = os.fstat(file.fileno()).st_size
        first = int(start or 0)
        last = min(int(end) if end else total - 1, total - 1)
        if first > last or first >= total:
            file.close()
            self.send_error(416)
            return None
        file.seek(first)
        self.send_response(206)
        self.send_header("Content-Range", f"bytes {first}-{last}/{total}")
        self.send_header("Content-Length", str(last - first + 1))
        self.send_header("Accept-Ranges", "bytes")
        self.end_headers()
        self.range_end = last
        return file

    def copyfile(self, source, outputfile):
        remaining = getattr(self, "range_end", None)
        if remaining is None:
            return super().copyfile(source, outputfile)
        remaining = remaining - source.tell() + 1
        while remaining:
            chunk = source.read(min(1024 * 1024, remaining))
            if not chunk:
                break
            outputfile.write(chunk)
            remaining -= len(chunk)


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8001), RangeHandler).serve_forever()
