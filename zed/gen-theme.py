"""Generate zed/themes/umber.json (brown-gray, low glare).

Usage: python3 zed/gen-theme.py zed/themes/umber.json
Prints WCAG contrast of each color against the editor background.
Zed only watches ~/.config/zed/themes, so after regenerating run
`touch -h ~/.config/zed/themes/umber.json` to reload the symlinked theme.
"""
import json
import sys


def a(hex6, alpha):
    return f"{hex6}{alpha}"


def lum(h):
    h = h.lstrip("#")[:6]
    rgb = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def contrast(x, y):
    l1, l2 = sorted([lum(x), lum(y)], reverse=True)
    return (l1 + 0.05) / (l2 + 0.05)


DARK = dict(
    appearance="dark",
    name="Umber",
    # Surfaces: warm brown-gray, nothing near pure black.
    chrome="#262220",      # title/status/tab bar
    panel="#2a2623",       # side panels, agent panel
    bg="#2e2a26",          # editor
    elevated="#36312c",    # popovers, modals
    active_line="#34302b",
    # Multibuffer (references, search) file header band.
    subheader="#3b352f",
    hover="#3a352f",
    selected="#453e37",
    active="#4d453d",
    border="#3e3832",
    border_variant="#34302b",
    border_focused="#7d6d5c",
    # Text: parchment, not white.
    text="#cdc3b5",
    text_muted="#a3998c",
    text_placeholder="#7d746a",
    text_disabled="#655d55",
    line_number="#635b53",
    line_number_active="#a89c8c",
    comment="#968b7e",
    punct="#9a8f83",
    # Accents: desaturated earth tones.
    red="#c4917f",
    orange="#cba07a",
    yellow="#c9b17f",
    green="#a5ae87",
    teal="#8fab9f",
    blue="#93a3b0",
    purple="#b29bab",
    cursor="#d4a87c",
    # Diffs: pastel teal (added) vs pink (removed), hues as far from the
    # brown background as possible so the two never blend together.
    diff_added="#7fd3cf",
    diff_deleted="#f0a3cc",
    diff_line_alpha="38",
    diff_word_alpha="0c",  # line + word tint keeps text >= 4.5:1
    selection_alpha="38",
    usage_alpha="38",
    bg_tint_alpha="26",
    term_black="#2a2623",
    term_white="#cdc3b5",
    term_bright_black="#6e655c",
    term_bright_white="#ddd4c7",
)

LIGHT = dict(
    appearance="light",
    name="Umber Light",
    # Surfaces: soft parchment, never paper-white.
    chrome="#cfc5b6",
    panel="#d5ccbe",
    bg="#dbd2c4",
    elevated="#e0d8cb",
    active_line="#d3c9ba",
    subheader="#cbc0b0",
    hover="#cdc2b2",
    selected="#c3b7a5",
    active="#b9ac99",
    border="#c2b6a4",
    border_variant="#cbc0b0",
    border_focused="#8c7457",
    # Text: dark umber, never black.
    text="#463c33",
    text_muted="#5f5347",
    text_placeholder="#8a7e70",
    text_disabled="#a09484",
    line_number="#a39787",
    line_number_active="#5e5247",
    comment="#6e6255",
    punct="#6c6054",
    red="#874434",
    orange="#80511f",
    yellow="#685720",
    green="#4c5a2e",
    teal="#33594e",
    blue="#3f5366",
    purple="#69475e",
    cursor="#80511f",
    diff_added="#2f7a74",
    diff_deleted="#a8457a",
    diff_line_alpha="26",
    diff_word_alpha="40",
    selection_alpha="40",
    usage_alpha="26",
    bg_tint_alpha="2e",
    term_black="#463c33",
    term_white="#cfc5b6",
    term_bright_black="#7d7163",
    term_bright_white="#e0d8cb",
)


def style(p):
    sel = p["selection_alpha"]
    tint = p["bg_tint_alpha"]

    def status(name, color):
        return {
            name: color,
            f"{name}.background": a(color, tint),
            f"{name}.border": a(color, "66"),
        }

    s = {
        "accents": [p["orange"], p["teal"], p["purple"], p["green"], p["blue"], p["red"], p["yellow"]],
        "border": p["border"],
        "border.variant": p["border_variant"],
        "border.focused": p["border_focused"],
        "border.selected": p["border_focused"],
        "border.transparent": "#00000000",
        "border.disabled": p["border_variant"],
        "elevated_surface.background": p["elevated"],
        "surface.background": p["panel"],
        "background": p["chrome"],
        "element.background": p["panel"],
        "element.hover": p["hover"],
        "element.active": p["active"],
        "element.selected": p["selected"],
        "element.disabled": p["panel"],
        "drop_target.background": a(p["orange"], "33"),
        "ghost_element.background": "#00000000",
        "ghost_element.hover": p["hover"],
        "ghost_element.active": p["active"],
        "ghost_element.selected": p["selected"],
        "ghost_element.disabled": "#00000000",
        "text": p["text"],
        "text.muted": p["text_muted"],
        "text.placeholder": p["text_placeholder"],
        "text.disabled": p["text_disabled"],
        "text.accent": p["orange"],
        "icon": p["text_muted"],
        "icon.muted": p["text_placeholder"],
        "icon.disabled": p["text_disabled"],
        "icon.placeholder": p["text_placeholder"],
        "icon.accent": p["orange"],
        "status_bar.background": p["chrome"],
        "title_bar.background": p["chrome"],
        "title_bar.inactive_background": p["chrome"],
        "toolbar.background": p["bg"],
        "tab_bar.background": p["chrome"],
        "tab.inactive_background": p["chrome"],
        "tab.active_background": p["bg"],
        "search.match_background": a(p["yellow"], "40"),
        "search.active_match_background": a(p["orange"], "66"),
        "panel.background": p["panel"],
        "panel.focused_border": None,
        "pane.focused_border": None,
        "pane_group.border": p["border"],
        "scrollbar.thumb.background": a(p["text_muted"], "33"),
        "scrollbar.thumb.hover_background": a(p["text_muted"], "55"),
        "scrollbar.thumb.active_background": a(p["text_muted"], "77"),
        "scrollbar.thumb.border": "#00000000",
        "scrollbar.track.background": "#00000000",
        "scrollbar.track.border": "#00000000",
        "editor.foreground": p["text"],
        "editor.background": p["bg"],
        "editor.gutter.background": p["bg"],
        "editor.subheader.background": p["subheader"],
        "editor.active_line.background": p["active_line"],
        # Marks each usage in References / Find All References.
        "editor.highlighted_line.background": a(p["blue"], p["usage_alpha"]),
        "editor.line_number": p["line_number"],
        "editor.active_line_number": p["line_number_active"],
        "editor.hover_line_number": p["text_muted"],
        "editor.invisible": p["text_disabled"],
        "editor.wrap_guide": a(p["text_muted"], "14"),
        "editor.active_wrap_guide": a(p["text_muted"], "26"),
        "editor.indent_guide": a(p["text_muted"], "1a"),
        "editor.indent_guide_active": a(p["text_muted"], "40"),
        "editor.document_highlight.read_background": a(p["blue"], "26"),
        "editor.document_highlight.write_background": a(p["orange"], "26"),
        "editor.document_highlight.bracket_background": a(p["orange"], "26"),
        "terminal.background": p["bg"],
        "terminal.foreground": p["text"],
        "terminal.bright_foreground": p["term_bright_white"],
        "terminal.dim_foreground": p["text_muted"],
        "terminal.ansi.black": p["term_black"],
        "terminal.ansi.bright_black": p["term_bright_black"],
        "terminal.ansi.dim_black": p["term_black"],
        "terminal.ansi.white": p["term_white"],
        "terminal.ansi.bright_white": p["term_bright_white"],
        "terminal.ansi.dim_white": p["text_muted"],
        "link_text.hover": p["orange"],
        "version_control.added": p["diff_added"],
        "version_control.modified": p["yellow"],
        "version_control.deleted": p["diff_deleted"],
        "version_control.renamed": p["blue"],
        "version_control.conflict": p["orange"],
        "version_control.ignored": p["text_disabled"],
        # Changed words inside a diff hunk, layered on the line tint.
        "version_control.word_added": a(p["diff_added"], p["diff_word_alpha"]),
        "version_control.word_deleted": a(p["diff_deleted"], p["diff_word_alpha"]),
        "editor.diff_hunk.added.background": a(p["diff_added"], p["diff_line_alpha"]),
        "editor.diff_hunk.added.hollow_background": a(p["diff_added"], "14"),
        "editor.diff_hunk.added.hollow_border": a(p["diff_added"], "66"),
        "editor.diff_hunk.deleted.background": a(p["diff_deleted"], p["diff_line_alpha"]),
        "editor.diff_hunk.deleted.hollow_background": a(p["diff_deleted"], "14"),
        "editor.diff_hunk.deleted.hollow_border": a(p["diff_deleted"], "66"),
    }
    for ansi, key in [("red", "red"), ("green", "green"), ("yellow", "yellow"),
                      ("blue", "blue"), ("magenta", "purple"), ("cyan", "teal")]:
        s[f"terminal.ansi.{ansi}"] = p[key]
        s[f"terminal.ansi.bright_{ansi}"] = p[key]
        s[f"terminal.ansi.dim_{ansi}"] = a(p[key], "aa")
    for name, color in [
        ("conflict", p["orange"]), ("created", p["green"]), ("deleted", p["red"]),
        ("error", p["red"]), ("hidden", p["text_disabled"]), ("hint", p["text_placeholder"]),
        ("ignored", p["text_disabled"]), ("info", p["blue"]), ("modified", p["yellow"]),
        ("predictive", p["text_placeholder"]), ("renamed", p["blue"]), ("success", p["green"]),
        ("unreachable", p["text_disabled"]), ("warning", p["orange"]),
    ]:
        s.update(status(name, color))

    s["players"] = [
        {"cursor": c, "background": c, "selection": a(c if i else p["orange"], sel)}
        for i, c in enumerate([p["cursor"], p["teal"], p["purple"], p["green"],
                               p["blue"], p["red"], p["yellow"]])
    ]

    def syn(color, italic=False, weight=None):
        d = {"color": color, "font_style": "italic" if italic else None, "font_weight": weight}
        return d

    s["syntax"] = {
        "attribute": syn(p["purple"]),
        "boolean": syn(p["orange"]),
        "comment": syn(p["comment"], italic=True),
        "comment.doc": syn(p["comment"], italic=True),
        "constant": syn(p["orange"]),
        "constructor": syn(p["yellow"]),
        "embedded": syn(p["text"]),
        "emphasis": syn(p["orange"], italic=True),
        "emphasis.strong": syn(p["orange"], weight=700),
        "enum": syn(p["teal"]),
        "function": syn(p["yellow"]),
        "function.builtin": syn(p["yellow"]),
        "hint": syn(p["text_placeholder"]),
        "keyword": syn(p["red"]),
        "label": syn(p["blue"]),
        "link_text": syn(p["blue"]),
        "link_uri": syn(p["teal"]),
        "namespace": syn(p["text_muted"]),
        "number": syn(p["orange"]),
        "operator": syn(p["punct"]),
        "predictive": syn(p["text_placeholder"], italic=True),
        "preproc": syn(p["purple"]),
        "primary": syn(p["text"]),
        "property": syn(p["blue"]),
        "punctuation": syn(p["punct"]),
        "punctuation.bracket": syn(p["punct"]),
        "punctuation.delimiter": syn(p["punct"]),
        "punctuation.list_marker": syn(p["orange"]),
        "punctuation.markup": syn(p["orange"]),
        "punctuation.special": syn(p["red"]),
        "selector": syn(p["yellow"]),
        "selector.pseudo": syn(p["purple"]),
        "string": syn(p["green"]),
        "string.escape": syn(p["teal"]),
        "string.regex": syn(p["teal"]),
        "string.special": syn(p["teal"]),
        "string.special.symbol": syn(p["teal"]),
        "tag": syn(p["red"]),
        "text.literal": syn(p["green"]),
        "title": syn(p["orange"], weight=700),
        "type": syn(p["teal"]),
        "variable": syn(p["text"]),
        "variable.parameter": syn(p["text"]),
        "variable.special": syn(p["purple"]),
        "variant": syn(p["teal"]),
        "diff.plus": syn(p["diff_added"]),
        "diff.minus": syn(p["diff_deleted"]),
    }
    return s


def report(p):
    bg = p["bg"]
    for k in ["text", "text_muted", "comment", "line_number", "red", "orange",
              "yellow", "green", "teal", "blue", "purple"]:
        print(f"  {p['name']:12} {k:14} {contrast(p[k], bg):5.2f}:1", file=sys.stderr)


theme = {
    "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
    "name": "Umber",
    "author": "Pasha Oakes",
    "themes": [{"name": p["name"], "appearance": p["appearance"], "style": style(p)}
               for p in (DARK, LIGHT)],
}

for p in (DARK, LIGHT):
    report(p)
json.dump(theme, open(sys.argv[1], "w"), indent=2)
open(sys.argv[1], "a").write("\n")
