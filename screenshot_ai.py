#!/usr/bin/env python3
"""
AI Screenshot Naming using macOS Apple Foundation Models CLI (`fm`).
Captures screen interactively, names with YYYY-MM-DD_HHMMSS_<slug>.png,
and displays a native floating preview thumbnail on the bottom right.
"""

import datetime
import os
import re
import shutil
import subprocess
import sys
import tempfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PREVIEW_BIN = os.path.join(SCRIPT_DIR, "preview_thumbnail")

# Find 'fm' CLI in PATH or fallback to /usr/bin/fm
FM_PATH = shutil.which("fm") or "/usr/bin/fm"


def get_screenshot_directory() -> str:
    """Reads configured macOS screenshot directory or defaults to ~/Desktop."""
    try:
        res = subprocess.run(
            ["defaults", "read", "com.apple.screencapture", "location"],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode == 0 and res.stdout.strip():
            path = os.path.expanduser(res.stdout.strip())
            if os.path.isdir(path):
                return path
    except Exception:
        pass
    return os.path.expanduser("~/Desktop")


def show_floating_preview(file_path: str) -> None:
    """Displays a native macOS floating thumbnail in the bottom right corner."""
    if os.path.exists(PREVIEW_BIN):
        subprocess.Popen(
            [PREVIEW_BIN, file_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )


def sanitize_slug(raw_text: str) -> str:
    """Sanitizes text to only alphanumeric chars with _ and -."""
    text = re.sub(r"[`'\"]", "", raw_text).strip()
    slug = re.sub(r"[^a-zA-Z0-9_-]+", "-", text).strip("-_").lower()
    slug = re.sub(r"-{2,}", "-", slug)
    return slug[:45] if slug else "screenshot"


def describe_image(image_path: str) -> str:
    """Invokes Apple Foundation Model CLI ('fm respond') to describe the screenshot."""
    if not os.path.exists(FM_PATH):
        return "screenshot"

    instructions = (
        "Describe this screenshot in 2 to 4 words. "
        "Output only lowercase words separated by hyphens (kebab-case). "
        "Do not include quotes, periods, or extra text. Example: github-issue-list"
    )

    try:
        res = subprocess.run(
            [
                FM_PATH,
                "respond",
                "--image",
                image_path,
                "--instructions",
                instructions,
                "--no-stream",
                "--greedy",
            ],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if res.returncode == 0 and res.stdout.strip():
            return sanitize_slug(res.stdout.strip())
    except Exception:
        pass

    return "screenshot"


def main():
    target_dir = get_screenshot_directory()

    # Capture to a temporary PNG
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        temp_path = tmp.name

    try:
        # screencapture -i invokes native macOS crosshair area/window selector
        capture = subprocess.run(["screencapture", "-i", temp_path])

        # If user pressed Escape or cancelled, file size is 0
        if capture.returncode != 0 or not os.path.exists(temp_path) or os.path.getsize(temp_path) == 0:
            return

        # Query local Apple Foundation Model CLI
        slug = describe_image(temp_path)

        # Generate timestamp format YYYY-MM-DD_HHMMSS
        now = datetime.datetime.now()
        timestamp = now.strftime("%Y-%m-%d_%H%M%S")
        target_name = f"{timestamp}_{slug}.png"
        target_path = os.path.join(target_dir, target_name)

        # Deduplicate if file already exists
        counter = 1
        while os.path.exists(target_path):
            target_name = f"{timestamp}_{slug}_{counter}.png"
            target_path = os.path.join(target_dir, target_name)
            counter += 1

        os.rename(temp_path, target_path)

        # Show native floating thumbnail on bottom right
        show_floating_preview(target_path)

    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)


if __name__ == "__main__":
    main()
