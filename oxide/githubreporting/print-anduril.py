#!/usr/bin/env python3
import sys
import json

def load_multi_json(fp):
    """Yield JSON objects from a file containing one or more objects, even if not NDJSON."""
    decoder = json.JSONDecoder()
    buffer = ""
    while True:
        chunk = fp.read(4096)
        if not chunk:
            break
        buffer += chunk
        while buffer:
            buffer = buffer.lstrip()
            if not buffer:
                break
            try:
                obj, idx = decoder.raw_decode(buffer)
                yield obj
                buffer = buffer[idx:]
            except json.JSONDecodeError:
                # Not enough data to decode, read more
                break

def clean(val):
    if isinstance(val, list):
        return ", ".join(str(x) for x in val)
    if val is None:
        return ""
    return str(val)

def main():
    # Accept both JSON array or multiple JSON objects in one file
    content = sys.stdin.read()
    content_stripped = content.lstrip()
    if content_stripped.startswith("["):
        data = json.loads(content)
    else:
        # Use our multi-object loader
        from io import StringIO
        data = list(load_multi_json(StringIO(content)))

    if not data:
        print("No data found.")
        return

    columns = [
        "item_type",
        "custom_type",
        "status",
        "anduril_priority",
        "on_roadmap",
        "title",
        "id",
        "labels",
    ]
    print("| " + " | ".join(columns) + " |")
    print("|" + "|".join(["---"] * len(columns)) + "|")
    for item in data:
        row = [clean(item.get(col, "")) for col in columns]
        print("| " + " | ".join(row) + " |")

if __name__ == "__main__":
    main()
