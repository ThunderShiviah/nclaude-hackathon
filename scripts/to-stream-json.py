#!/usr/bin/env python3
"""
Adapter that converts line-by-line text input to Claude stream-json format.

Usage:
    echo 'Hello' | ./to-stream-json.py | claude -p --input-format=stream-json ...
"""

import sys
import json

def main():
    try:
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue

            # Wrap in stream-json format
            stream_msg = {
                "type": "user",
                "message": {
                    "role": "user",
                    "content": [{"type": "text", "text": line}]
                }
            }

            print(json.dumps(stream_msg), flush=True)
    except KeyboardInterrupt:
        pass

if __name__ == '__main__':
    main()
