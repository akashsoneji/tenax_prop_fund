#!/usr/bin/env python3
"""Codemod: route feature text styles through AppText.

  GoogleFonts.beVietnamPro(<args>)  ->  AppText.base(<args>)
  TextStyle(<args>)                 ->  AppText.base(<args>)

AppText.base(...) == GoogleFonts.beVietnamPro(...) for the same arguments, so
the first rewrite is pixel-identical. The second gives bare TextStyles the real
Be Vietnam Pro weight file (user-approved design change).

A call is only rewritten when every named argument is one AppText.base
accepts (fontSize, fontWeight, color, height, letterSpacing). Anything else
(decoration, fontStyle, shadows, fontFeatures, ...) is left untouched and
reported, so nothing is silently dropped. `const TextStyle(...)` is skipped
(AppText.base is not const). Frozen paths are never touched.

Usage: tool/migrate_text_styles.py <feature> [<feature> ...] [--dry-run]
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
FEATURES = ROOT / "lib" / "features"
ALLOWED = {"fontSize", "fontWeight", "color", "height", "letterSpacing"}
FROZEN = ("chart", "chart_landscape")
CALL = re.compile(r"(?<![\w.])(const\s+)?(GoogleFonts\.beVietnamPro|TextStyle)\(")


def _close(src: str, start: int) -> int:
    """Index just past the ')' matching the '(' before `start`."""
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
    raise ValueError("unbalanced call")


def _top_level_args(body: str) -> list[str]:
    """Split a call body on top-level commas."""
    args, depth, quote, cur = [], 0, None, ""
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
            args.append(cur)
            cur = ""
            continue
        cur += ch
    if cur.strip():
        args.append(cur)
    return args


def _arg_names(body: str) -> set[str]:
    """Named-argument names: `name:` at the very start of each argument.
    Positional arguments get the marker '<positional>'."""
    names = set()
    for arg in _top_level_args(body):
        m = re.match(r"\s*(\w+)\s*:(?!:)", arg)
        names.add(m.group(1) if m else "<positional>")
    return names


def _import_line(path: pathlib.Path) -> str:
    rel = pathlib.Path("../" * (len(path.relative_to(ROOT / "lib").parts) - 1))
    return f"import '{(rel / 'shared/theme/app_text.dart').as_posix()}';"


def migrate(path: pathlib.Path, dry: bool) -> tuple[int, list[str]]:
    src = path.read_text()
    out, pos, changed, skipped = [], 0, 0, []
    for m in CALL.finditer(src):
        if m.start() < pos:
            continue
        end = _close(src, m.end())
        body = src[m.end():end - 1]
        line = src.count("\n", 0, m.start()) + 1
        extra = _arg_names(body) - ALLOWED
        if m.group(1):
            skipped.append(f"{path.relative_to(ROOT)}:{line} const TextStyle")
            continue
        if extra:
            skipped.append(f"{path.relative_to(ROOT)}:{line} unsupported {sorted(extra)}")
            continue
        out.append(src[pos:m.start()])
        out.append(f"AppText.base({body})")
        pos = end
        changed += 1
    if not changed:
        return 0, skipped
    out.append(src[pos:])
    new = "".join(out)
    if "shared/theme/app_text.dart'" not in new:
        imports = list(re.finditer(r"^import [^\n]+;\n", new, re.M))
        at = imports[-1].end()
        new = new[:at] + _import_line(path) + "\n" + new[at:]
    if "GoogleFonts." not in new:
        new = re.sub(r"^import 'package:google_fonts/google_fonts.dart';\n", "", new, flags=re.M)
    if not dry:
        path.write_text(new)
    return changed, skipped


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    total, skipped_all = 0, []
    for feature in args:
        if feature in FROZEN:
            print(f"skip frozen feature {feature}")
            continue
        for path in sorted((FEATURES / feature).rglob("*.dart")):
            n, skipped = migrate(path, dry)
            total += n
            skipped_all += skipped
            if n:
                print(f"  {n:3d}  {path.relative_to(ROOT)}")
    print(f"rewritten: {total}{' (dry run)' if dry else ''}")
    for s in skipped_all:
        print(f"  left as-is: {s}")


if __name__ == "__main__":
    main()
