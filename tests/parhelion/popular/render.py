"""usage: render.py <shots-dir> <html-dir> [per-sheet]. Draws each view in dark and light, side by side, on sheets."""
import glob
import html
import json
import os
import sys


def grid(shot, label):
    parts = [
        f'<div class="pane" style="background:{shot["defaults"]["bg"]}">'
        f'<div class="label" style="color:{shot["defaults"]["fg"]};background:{shot["defaults"]["bg"]}">{html.escape(label)}</div>'
        '<div class="g">'
    ]
    for row in shot["rows"]:
        parts.append('<span class="r">')
        for cell in row:
            fg, bg = cell["fg"], cell["bg"]
            flags = set((cell.get("flags") or "").split(","))
            if "reverse" in flags:
                fg, bg = bg, fg
            style = [f"color:{fg}", f"background:{bg}"]
            if "bold" in flags:
                style.append("font-weight:700")
            if "italic" in flags:
                style.append("font-style:italic")
            decoration = []
            if flags & {"underline", "undercurl", "underdouble", "underdotted", "underdashed"}:
                decoration.append("underline")
            if "strikethrough" in flags:
                decoration.append("line-through")
            if decoration:
                style.append("text-decoration:" + " ".join(decoration))
                if "undercurl" in flags:
                    style.append("text-decoration-style:wavy")
                if cell.get("sp"):
                    style.append(f"text-decoration-color:{cell['sp']}")
            parts.append(f'<span class="c" style="{";".join(style)}">{html.escape(cell["text"] or "")}</span>')
        parts.append("</span>")
    parts.append("</div></div>")
    return "".join(parts)


shots, out = sys.argv[1], sys.argv[2]
per_sheet = int(sys.argv[3]) if len(sys.argv) > 3 else 2
os.makedirs(out, exist_ok=True)
names = sorted({os.path.basename(p).rsplit("-", 1)[0] for p in glob.glob(shots + "/*.json")})
style = (
    '<!doctype html><meta charset="utf-8"><style>'
    "html,body{margin:0;padding:0;background:#222}"
    ".wrap{display:inline-flex;gap:4px;margin-bottom:4px}"
    ".pane{display:inline-block}"
    ".label{font:600 13px/22px Menlo,monospace;padding:0 10px}"
    '.g{display:inline-block;font:16px/20px PragmataPro,"PragmataPro Mono",Menlo,monospace;white-space:pre}'
    ".r{display:block;height:20px}"
    ".c{display:inline-block;width:8px;height:20px;overflow:visible;vertical-align:top}"
    "</style>"
)
for index in range(0, len(names), per_sheet):
    page = [style]
    for name in names[index : index + per_sheet]:
        page.append('<div class="wrap">')
        for mode in ("dark", "light"):
            path = f"{shots}/{name}-{mode}.json"
            if os.path.exists(path):
                page.append(grid(json.load(open(path)), f"{name} {mode}"))
        page.append("</div>")
    open(f"{out}/sheet-{index // per_sheet:02}.html", "w").write("".join(page))
    print(f"sheet-{index // per_sheet:02}", " ".join(names[index : index + per_sheet]))
