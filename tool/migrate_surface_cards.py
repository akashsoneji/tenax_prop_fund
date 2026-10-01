#!/usr/bin/env python3
"""Codemod: `Container(decoration: AppTheme.surfaceCard(scheme, ...), ...)` -> `AppCard(...)`.

Only rewrites a Container whose arguments are a subset of
{decoration, padding, margin, width, child} and whose decoration is exactly
`AppTheme.surfaceCard(<ColorScheme expr>[, radius: X])` — AppCard renders the
same Container with the same decoration, so the output is pixel-identical.
`radius:` is passed through verbatim (call sites mix `18` and `18.r`); the
surfaceCard default radius (16) is AppCard's default too. Anything else
(alignment, clipBehavior, Ink, extra surfaceCard args) is left untouched.

Usage: tool/migrate_surface_cards.py <feature> [<feature> ...] [--dry-run]
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FEATURES = ROOT / "lib" / "features"
FROZEN = ("chart", "chart_landscape")
ALLOWED = {"decoration", "padding", "margin", "width", "child"}
CALL = re.compile(r"(?<![\w.])Container\(")


def _close(src, start):
    depth, i, quote = 1, start, None
    while i < len(src):
        ch = src[i]
        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
        elif ch == "/" and src.startswith("//", i):
            i = src.find("\n", i)
            if i == -1:
                break
            continue
        elif ch in "'\"":
            quote = ch
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError("unbalanced")


def _args(body):
    """[(name, raw_text)] for each top-level argument."""
    out, depth, quote, cur = [], 0, None, ""
    for ch in body:
        if quote:
            cur += ch
            if ch == quote:
                quote = None
            continue
        if ch in "'\"":
            quote = ch
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            out.append(cur)
            cur = ""
            continue
        cur += ch
    if cur.strip():
        out.append(cur)
    named = []
    for raw in out:
        m = re.match(r"\s*(\w+)\s*:(?!:)", raw)
        named.append((m.group(1) if m else None, raw))
    return named


SURFACE = re.compile(
    r"^\s*decoration:\s*AppTheme\.surfaceCard\(\s*([\w.]+)\s*(?:,\s*radius:\s*([^,()]+?))?\s*,?\s*\)\s*$",
    re.S,
)


def migrate(path, dry):
    src = path.read_text()
    out, pos, n = [], 0, 0
    for m in CALL.finditer(src):
        if m.start() < pos:
            continue
        end = _close(src, m.end())
        args = _args(src[m.end():end - 1])
        names = {a for a, _ in args}
        if None in names or not names <= ALLOWED or "decoration" not in names:
            continue
        deco = next(raw for a, raw in args if a == "decoration")
        dm = SURFACE.match(deco)
        if not dm:
            continue
        new_args = []
        if dm.group(2):
            new_args.append(f"radius: {dm.group(2).strip()}")
        for a, raw in args:
            if a != "decoration":
                new_args.append(raw.strip())
        indent = re.search(r"([ \t]*)\S[^\n]*$", src[:m.start()] + "x").group(1)
        inner = indent + "  "
        body = "".join(f"\n{inner}{arg}," for arg in new_args)
        out.append(src[pos:m.start()])
        out.append(f"AppCard({body}\n{indent})")
        pos = end
        n += 1
    if not n:
        return 0
    out.append(src[pos:])
    new = "".join(out)
    if "shared/widgets/app_card.dart'" not in new:
        depth = len(path.relative_to(ROOT / "lib").parts) - 1
        imp = "import '" + "../" * depth + "shared/widgets/app_card.dart';\n"
        last = list(re.finditer(r"^import [^\n]+;\n", new, re.M))[-1]
        new = new[:last.end()] + imp + new[last.end():]
    if not dry:
        path.write_text(new)
    return n


def main():
    feats = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not feats:
        feats = sorted(p.name for p in FEATURES.iterdir() if p.is_dir())
    dry = "--dry-run" in sys.argv
    total = 0
    for f in feats:
        if f in FROZEN:
            continue
        for p in sorted((FEATURES / f).rglob("*.dart")):
            n = migrate(p, dry)
            if n:
                print(f"  {n:3d}  {p.relative_to(ROOT)}")
            total += n
    print(f"rewritten: {total}{' (dry run)' if dry else ''}")


if __name__ == "__main__":
    main()
