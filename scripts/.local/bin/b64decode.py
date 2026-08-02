#!/usr/bin/env python3

import argparse
import base64
import sys


def decode_base64(value: str) -> str:
    try:
        decoded = base64.b64decode(value, validate=True)
        return decoded.decode("utf-8")
    except Exception as e:
        raise ValueError(f"Invalid base64 input: {e}") from e


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Decode a base64-encoded string"
    )
    parser.add_argument(
        "value",
        help="Base64-encoded string to decode"
    )

    args = parser.parse_args()

    try:
        result = decode_base64(args.value)
        print(result)
    except ValueError as e:
        print(e, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
