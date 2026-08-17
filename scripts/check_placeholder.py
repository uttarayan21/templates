#!/usr/bin/env python3
"""Guard for ``om init`` placeholder substitution.

``om init`` replaces placeholders by plain substring search over every file in
the template. That is only safe if the placeholder is a string that cannot
occur by accident, and only complete if every file hardcoding the name uses
that exact string.

For each template declaring a ``package-name`` param this asserts:

1. the crate in ``Cargo.toml`` is named exactly the placeholder,
2. scaffolding with a sentinel leaves no trace of the placeholder, and
3. the sentinel actually landed somewhere.

(1) is the one with teeth: if someone edits a template's ``Cargo.toml`` to
``name = "foo"``, ``om init`` silently keeps producing crates named ``foo`` no
matter what the user types, because the placeholder no longer matches. (3)
fails if a template declares the param but has nothing to substitute. Nothing
here builds a derivation, so it stays fast.

Usage::

    python3 scripts/check_placeholder.py

Requires ``nix`` and ``om`` on PATH.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SENTINEL = "zqxjkvbrwp"
REPO = Path(__file__).resolve().parent.parent
NAME_RE = re.compile(r'^name = "(.*)"$', re.MULTILINE)


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    """Run a command without a shell, capturing output as text."""
    return subprocess.run(
        cmd, cwd=REPO, capture_output=True, text=True, encoding="utf-8", errors="replace"
    )


def require(tool: str) -> None:
    if shutil.which(tool) is None:
        sys.exit(f"error: '{tool}' not found on PATH")


def load_om() -> dict:
    print("==> evaluating .#om")
    proc = run(["nix", "eval", "--json", ".#om"])
    if proc.returncode != 0:
        sys.exit(f"error: nix eval failed:\n{proc.stderr}")
    return json.loads(proc.stdout)


def targets(om: dict) -> list[tuple[str, str, Path]]:
    """Yield (template, placeholder, source dir) for templates with a name param.

    The template path is a /nix/store checkout of this repo, so whatever
    follows "-source/" is the directory in the working tree.
    """
    found = []
    for name, tpl in sorted(om["templates"].items()):
        for param in tpl.get("params", []):
            if param.get("name") == "package-name":
                path = tpl["template"]["path"]
                _, sep, srcdir = path.partition("-source/")
                found.append((name, param["placeholder"], REPO / srcdir if sep else Path(path)))
    return found


def files_containing(root: Path, needle: str) -> list[Path]:
    """Paths under root whose name or decoded content contains needle."""
    hits = []
    for path in sorted(root.rglob("*")):
        if needle in path.name:
            hits.append(path)
        elif path.is_file():
            try:
                text = path.read_bytes().decode("utf-8", errors="ignore")
            except OSError:
                continue
            if needle in text:
                hits.append(path)
    return hits


def check(template: str, placeholder: str, srcdir: Path, workdir: Path) -> str | None:
    """Return an error message, or None if the template checks out."""
    # 1. A crate named anything else would never be substituted.
    manifest = srcdir / "Cargo.toml"
    if manifest.is_file():
        match = NAME_RE.search(manifest.read_text(encoding="utf-8"))
        declared = match.group(1) if match else None
        if declared != placeholder:
            return (
                f"{manifest.relative_to(REPO)} declares name = {declared!r},\n"
                f"      but {template}'s package-name placeholder is {placeholder!r}.\n"
                f"      om init would leave the crate named {declared!r}."
            )

    out = workdir / f"out-{template}"
    proc = run(
        [
            "om", "init",
            "-o", str(out),
            f".#{template}",
            "--params", json.dumps({"package-name": SENTINEL}),
            "--non-interactive",
        ]
    )
    if proc.returncode != 0:
        return f"om init failed for {template}:\n{proc.stderr.strip()}"

    # 2. The placeholder must be fully gone.
    leftover = files_containing(out, placeholder)
    if leftover:
        listing = "\n".join(f"        {p.relative_to(out)}" for p in leftover)
        return (
            f"{template} still contains the placeholder {placeholder!r} "
            f"after substitution:\n{listing}"
        )

    # 3. The value must have landed somewhere.
    hits = files_containing(out, SENTINEL)
    if not hits:
        return f"{template} declares package-name but nothing was substituted"

    print(f"  ok  {template} (placeholder {placeholder!r} -> {len(hits)} file(s))")
    return None


def main() -> int:
    for tool in ("nix", "om"):
        require(tool)

    found = targets(load_om())
    if not found:
        print("FAIL: no template declares a package-name param", file=sys.stderr)
        return 1

    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        workdir = Path(tmp)
        for template, placeholder, srcdir in found:
            error = check(template, placeholder, srcdir, workdir)
            if error is not None:
                print(f"FAIL: {error}", file=sys.stderr)
                failures += 1

    if failures:
        print(f"\n{failures} template(s) failed", file=sys.stderr)
        return 1

    print("==> all templates substitute cleanly")
    return 0


if __name__ == "__main__":
    sys.exit(main())
