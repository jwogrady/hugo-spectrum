#!/usr/bin/env bash
# Spectrum build checks. Exercises the tag-frequency partials against the
# edge cases that break naive tag clouds. No dependencies beyond hugo + python3.
set -uo pipefail
THEME="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok(){ printf '  \033[32mPASS\033[0m %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  \033[31mFAIL\033[0m %s\n' "$1"; fail=$((fail+1)); }

fixture () { # $1 name ; stdin = list of "slug:tag,tag"
  local d="$TMP/$1"; mkdir -p "$d/content/posts" "$d/themes"
  ln -s "$THEME" "$d/themes/spectrum"
  cat > "$d/hugo.toml" <<EOF
baseURL = 'https://example.org/'
title = 'fixture'
theme = 'spectrum'
capitalizeListTitles = false
[taxonomies]
  tag = 'tags'
EOF
  local i=0
  while IFS=: read -r slug tags; do
    [ -z "$slug" ] && continue
    i=$((i+1))
    mkdir -p "$d/content/posts/$slug"
    { echo '+++'; echo "title = \"$slug\""; echo "date = 2026-01-$(printf %02d $((i%28+1)))";
      if [ -n "$tags" ]; then
        printf 'tags = ['; printf '"%s",' ${tags//,/ } | sed 's/,$//'; printf ']\n'
      fi
      echo '+++'; } > "$d/content/posts/$slug/index.md"
  done
  (cd "$d" && hugo --quiet --destination out --panicOnWarning 2>&1)
  echo "$d"
}

echo "── edge cases ──"

# 1. no tags at all
d=$(fixture notags <<< "alpha:")
[ -f "$d/out/index.html" ] && ! grep -q 'tag-signal' "$d/out/index.html" \
  && ok "no tags: builds, renders no signal field" || no "no tags"

# 2. a single tag
d=$(fixture onetag <<< "alpha:solo")
grep -q 'tag-signal:1.0000' "$d/out/index.html" \
  && ok "one tag: intensity pinned to 1.0" || no "one tag"

# 3. every count equal -> flat field, distance 0 everywhere
d=$(fixture equal <<< "a:x
b:y
c:z")
# The subject index renders each subject twice — once in the field, once in
# the ranked climb — so the assertion is the invariant rather than a count:
# with every count equal, every signal on the page sits at full intensity.
tot=$(grep -o 'class="tag-signal__name"' "$d/out/tags/index.html" | wc -l)
n=$(grep -o 'class="tag-signal__name" style="--tag-signal:1.0000' "$d/out/tags/index.html" | wc -l)
[ "$tot" -gt 0 ] && [ "$n" -eq "$tot" ] && ok "equal counts: every tag at full intensity, field reads flat" || no "equal counts ($n of $tot at full intensity)"

# 4. one extreme outlier must not crush the rest
d=$(fixture outlier <<< "a:big
b:big
c:big
e:big
f:big
g:big
h:big
i:big
j:big
k:big
l:big
m:big
n:big
o:big
p:big
q:big
r:big
s:big
t:big
u:big
v:rare
w:other")
# The real invariant under banding: an extreme outlier costs one band and
# leaves every other subject at full chroma. Under the old intensity curve a
# 20-vs-1 spread would have crushed the rest toward the floor.
read -r bands nonapex_full <<<"$(python3 - "$d/out/tags/index.html" <<'PYEOF'
import re, sys
s = open(sys.argv[1]).read()
rows = re.findall(r'--tag-signal:([0-9.]+);--tag-hue:([0-9.]+);--tag-chroma:([0-9.]+);', s)
bands = len({r[0] for r in rows})
nonapex = [c for _, _, c in rows if float(c) > 0]
print(bands, int(all(abs(float(c) - 1.0) < 1e-6 for c in nonapex) and len(nonapex) > 0))
PYEOF
)"
if [ "${bands:-0}" -ge 2 ] && [ "${nonapex_full:-0}" -eq 1 ]
then ok "extreme outlier (20 vs 1): $bands bands, non-apex subjects keep full chroma"
else no "outlier flattened the field (bands=$bands full-chroma=$nonapex_full)"; fi

# 5. hundreds of tags
{ for i in $(seq 1 220); do echo "p$i:t$((i%140))"; done; } > "$TMP/many.txt"
d=$(fixture many < "$TMP/many.txt")
c=$(grep -o 'class="tag-signal"' "$d/out/tags/index.html" | wc -l)
[ "$c" -ge 130 ] && ok "hundreds of tags: $c signals rendered" || no "many tags ($c)"

# 6. determinism — same input, byte-identical output
d1=$(fixture det1 <<< "a:x,y
b:y,z
c:z")
d2=$(fixture det2 <<< "a:x,y
b:y,z
c:z")
if diff -q <(grep -o '\-\-tag-signal:[0-9.]*' "$d1/out/tags/index.html") \
           <(grep -o '\-\-tag-signal:[0-9.]*' "$d2/out/tags/index.html") >/dev/null
then ok "deterministic across builds"; else no "non-deterministic output"; fi

# 7. the lightness ramp spans its whole range, at any band count
#
# The apex is pinned at 1.0 on its own, so the bands under it divide the
# ceiling between them: rarest on the floor, last-below-apex on the ceiling,
# the rest spread evenly. Dividing by (bands - 1) counted an interval the
# apex had already left, so the ceiling was never reached and the shortfall
# grew as bands fell — eight bands stopped at 0.583 of a ramp documented as
# 0.68, and three stopped at 0.34. That is most of why a small corpus looked
# broken rather than merely quiet, so three bands is the case asserted: it is
# the one a new site is actually in, and it fails loudest.
d=$(fixture ramp <<< "a:rare
b:mid
c:mid
d:top
e:top
f:top")
ramp=$(grep -o '\-\-tag-signal:[0-9.]\{6\}' "$d/out/tags/index.html" \
       | sed 's/.*://' | sort -u | tr '\n' ' ')
[ "$ramp" = "0.0000 0.6800 1.0000 " ] \
  && ok "three bands span floor, ceiling and apex (${ramp% })" \
  || no "the ramp does not reach its ceiling (bands at: ${ramp% })"

# 8. a lone band IS the apex, and the legend has to be able to say so
#
# distance divided by (bands - 1) behind a guard that forced the divisor to 1
# when there was one band, so the only field that is flat reported the
# maximum distance from an apex every one of its subjects was sitting on. The
# note written for exactly that case was unreachable for as long as it has
# existed. Both directions, because a note that always fires is no better.
d=$(fixture flatfield <<< "a:x
b:y
c:z")
flat_on=0;  grep -q 'so the field is flat' "$d/out/tags/index.html" && flat_on=1
d=$(fixture bandedfield <<< "a:x
b:x
c:y")
flat_off=0; grep -q 'so the field is flat' "$d/out/tags/index.html" && flat_off=1
[ "$flat_on" -eq 1 ] && [ "$flat_off" -eq 0 ] \
  && ok "a flat field says it is flat, and a banded one does not" \
  || no "flat note (equal counts=$flat_on, unequal=$flat_off)"

# 9. a thin field says it is thin
#
# Resolution is the count of distinct counts, so it is bought with content
# and cannot be configured. Under four bands there is nothing to separate and
# the field looks broken to anyone meeting the theme on a fresh site, which
# is every evaluator. Three bands must say so; four must not, or the note
# becomes furniture.
d=$(fixture thinfield <<< "a:r
b:m
c:m
d:t
e:t
f:t")
thin_on=0;  grep -q 'bands, and it separates' "$d/out/tags/index.html" && thin_on=1
d=$(fixture widefield <<< "a:r
b:m
c:m
d:t
e:t
f:t
g:q
h:q
i:q
j:q")
thin_off=0; grep -q 'bands, and it separates' "$d/out/tags/index.html" && thin_off=1
[ "$thin_on" -eq 1 ] && [ "$thin_off" -eq 0 ] \
  && ok "a three-band field declares its own resolution, a four-band one does not" \
  || no "resolution note (3 bands=$thin_on, 4 bands=$thin_off)"

echo "── main site ──"

# Reference codes are the publication conceit; a malformed one is invisible
# in the markup and obvious on the page. GroupByDate returns a slice, and
# ranging it with two variables silently yields the index instead of the year.
#
# The fixture is the theme's own exampleSite, built into TMP. This used to be
# the consuming Pulse site two directories up, which meant the theme's checks
# only ran inside someone else's checkout: in a clone of this repository alone
# eleven of them failed outright and the unused-template one passed vacuously,
# because a build that never happened reports no unused templates.
#
# The theme is symlinked under the name exampleSite asks for, so the fixture
# does not depend on what the checkout directory happens to be called.
SITE="$THEME/exampleSite"
PUB="$TMP/refs"
THEME_NAME="$(sed -n "s/^theme[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" "$SITE/hugo.toml" | head -1)"
mkdir -p "$TMP/themes" && ln -s "$THEME" "$TMP/themes/${THEME_NAME:-theme}"
if (hugo --source "$SITE" --themesDir "$TMP/themes" --destination "$PUB" \
         -D --quiet --panicOnWarning) 2>/dev/null; then
  # Checked in front matter and at the URL, not in the rendered page. It
  # scanned the journal index until the reference left that table, then the
  # entry page until the eyebrow was dropped — twice it went to 0/0 and
  # reported no findings as success. A reference is a citation handle: it
  # lives in front matter and it has to resolve. Neither of those moves
  # when the page stops printing it.
  read -r total good aliased <<<"$(python3 - "$SITE" "$TMP/refs" <<'PYEOF'
import re, sys, pathlib
root, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
total = good = aliased = 0
posts = sorted(list((root / "content" / "posts").glob("*.md"))
             + list((root / "content" / "posts").glob("*/index.md")))
for f in posts:
    m = re.search(r'^resolves\s*=\s*"([^"]+)"', f.read_text(), re.M)
    if not m: continue
    total += 1
    ref = m.group(1)
    if re.fullmatch(r"JRN \d\d-\d{3}", ref):
        good += 1
        code = ref.split(" ", 1)[1]
        if (out / "r" / code / "index.html").exists(): aliased += 1
print(f"{total} {good} {aliased}")
PYEOF
)"
  if [ "${total:-0}" -gt 0 ] && [ "$total" -eq "${good:-0}" ] && [ "$total" -eq "${aliased:-0}" ]
  then ok "every reference is well-formed and resolves ($good/$total)"
  else no "references broken ($good well-formed, $aliased resolve, of $total)"; fi

  # A CSS minifier may strip the space after a closing paren. That is safe for
  # calc() but not for var(), whose substitution happens after parsing:
  # `var(--rule-hair)solid` becomes `1pxsolid` and the declaration is dropped.
  # It silently broke every border, the focus ring and the animation once.
  broken=$(grep -rhoE 'var\(--[a-z0-9-]+(,[^)]*)?\)[a-zA-Z]+' "$TMP/refs"/css/*.css 2>/dev/null | wc -l)
  if [ "$broken" -eq 0 ]
  then ok "no var() glued to the next token in published css"
  else no "$broken var() declarations broken by minification"; fi

  # A page states its title twice: the headline a reader sees, and the <title>
  # a tab, a bookmark and a search result see. Hugo names a term page after its
  # own key, so the two diverge silently on exactly the pages nobody screenshots
  # — /archives/2026-09/ headed "September 2026" and tabbed "2026-09 — Spectrum"
  # for as long as there was no demo site rendering both at once.
  #
  # Asserted as the invariant rather than against a list of known-bad keys: the
  # tab must begin with the headline, on every page that has one.
  read -r seen bad first <<<"$(python3 - "$TMP/refs" <<'PYEOF'
import re, sys, pathlib, html
root = pathlib.Path(sys.argv[1])
strip = lambda t: html.unescape(re.sub(r"<[^>]*>", "", t)).strip()
seen = bad = 0; first = "-"
for f in sorted(root.rglob("index.html")):
    # Home is the exception by design: it is titled with the publication's
    # name alone, so its headline ("Journal") never prefixes its tab. Its
    # pager pages are home too — .IsHome is true for /page/2/ — and carry
    # the same title, so they take the same exemption.
    rel = f.relative_to(root).parent
    if rel == pathlib.Path(".") or re.fullmatch(r"page/\d+", rel.as_posix()): continue
    t = f.read_text(errors="replace")
    mt = re.search(r"<title>(.*?)</title>", t, re.S)
    mh = re.search(r"<h1[^>]*>(.*?)</h1>", t, re.S)
    if not mt or not mh: continue
    title, h1 = strip(mt.group(1)), strip(mh.group(1))
    if not h1: continue
    seen += 1
    if not title.startswith(h1):
        bad += 1
        if first == "-": first = f"{f.relative_to(root).parent}: {h1!r} vs {title!r}"
print(f"{seen} {bad} {first}")
PYEOF
)"
  # Fails when it matches nothing: a check anchored to rendered output that
  # stops finding pages reports "no findings" as success.
  if [ "${seen:-0}" -gt 0 ] && [ "${bad:-1}" -eq 0 ]
  then ok "every browser tab title matches its own headline ($seen pages)"
  else no "tab title diverges from the headline ($bad of ${seen:-0}) $first"; fi
fi

if (hugo --source "$SITE" --themesDir "$TMP/themes" --destination "$TMP/strict" \
         --gc -D --panicOnWarning --printPathWarnings --quiet) 2>/dev/null
then ok "strict build clean (warnings fatal)"; else no "strict build"; fi


# Typography arithmetic. Paragraphs separated by less than the space between
# their own lines do not read as separate blocks — an easy regression to make
# by changing one token.
read -r gap lead ok <<<"$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
css = "\n".join(p.read_text() for p in pathlib.Path(sys.argv[1]).glob("*.css"))
def v(n, depth=0):
    # Tokens alias other tokens now (--space-para: var(--s11)), so resolve the
    # chain rather than reading the first literal and silently getting zero.
    m = re.search(rf"{re.escape(n)}:\s*([^;]+);", css)
    if not m or depth > 8: return 0.0
    val = m.group(1).strip()
    a = re.fullmatch(r"var\(\s*(--[\w-]+)\s*\)", val)
    if a: return v(a.group(1), depth + 1)
    lit = re.match(r"([\d.]+)rem", val)
    return float(lit.group(1)) * 16 if lit else 0.0
def num(n):
    m = re.search(rf"{re.escape(n)}:\s*([\d.]+)\s*;", css)
    return float(m.group(1)) if m else 0.0
gap = v("--space-para"); lead = v("--size-prose") * num("--lh-prose")
print(f"{gap:.0f} {lead:.0f} {1 if lead and gap/lead >= 0.7 else 0}")
PYEOF
)"
if [ "${ok:-0}" -eq 1 ]
then ok "paragraph gap ${gap}px exceeds 0.7 of ${lead}px leading"
else no "paragraph gap ${gap}px too tight against ${lead}px leading"; fi


# The masthead's height is set by the identity, not by the sections beside
# it. If a nav link had the taller line box the header would grow when the
# menu was restyled, and the identity would stop being what sizes the
# masthead. The same invariant has followed this row through three
# layouts — a count beside a head, a clock beside a nameplate, now a nav
# beside an identity — so it is retargeted rather than retired each time.
read -r tbox mbox <<<"$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
# print.css redefines these in points; the invariant is about screen layout
css = "\n".join(p.read_text() for p in sorted(pathlib.Path(sys.argv[1]).glob("*.css"))
                if p.name != "print.css")
SIZES = {"2xs": 10.51, "xs": 12.33, "sm": 14.48, "base": 17.0,
         "lg": 19.96, "xl": 23.43, "2xl": 27.51, "3xl": 32.29, "4xl": 37.91}
LHS   = {"label": 1.25, "title": 1.3, "tight": 1.18, "snug": 1.35, "body": 1.65}
def box(sel):
    # Anchor at the start of a rule. Unanchored, ".nameplate" matched
    # ".identity:hover .nameplate", a rule with neither a size nor a
    # line-height, so the check measured the 16x1.65 fallback and passed.
    m = re.search(rf"(?:^|[}}\n])\s*{re.escape(sel)}\s*\{{([^}}]*)\}}", css, re.M)
    if not m:
        return None                      # missing selector is a failure, not a pass
    b = m.group(1)
    fs = re.search(r"font-size:\s*var\(--size-([a-z0-9]+)\)", b)
    lh = re.search(r"line-height:\s*var\(--lh-([a-z]+)\)", b)
    size = SIZES.get(fs.group(1), 16.0) if fs else 16.0
    ratio = LHS.get(lh.group(1), 1.65) if lh else 1.65   # no line-height -> inherits body
    return size * ratio
t, m = box(".masthead__name"), box(".masthead__sections a")
print(f"{t:.1f} {m:.1f}" if t and m else "0 0")
PYEOF
)"
if [ "${tbox:-0}" != "0" ] && awk -v a="$tbox" -v b="$mbox" 'BEGIN{exit !(a+0 >= b+0)}'
then ok "masthead height set by the identity (${tbox}px) not the nav (${mbox}px)"
else no "the nav drives the masthead height (name=${tbox:-?} nav=${mbox:-?})"; fi


# Any rule that sets a font size but no line-height silently inherits body
# leading, which makes row heights depend on which sibling happens to be
# tallest. That is how a header starts shifting between pages.
orphans=$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
css = "\n".join(p.read_text() for p in sorted(pathlib.Path(sys.argv[1]).glob("*.css"))
                if p.name != "print.css")
# Comments blanked first. A comment containing a brace shifts every rule
# boundary after it, and this check quietly stopped seeing `table` and
# `label` — both of which were sized with no leading.
css = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), css, flags=re.S)
bad = [" ".join(m.group(1).split())[:44]
       for m in re.finditer(r"([^{}]+)\{([^}]*)\}", css)
       if "font-size: var(--size-" in m.group(2)
       and "line-height" not in m.group(2)
       and ":root" not in m.group(1)
       and not m.group(1).strip().startswith("/*")]
print("|".join(bad))
PYEOF
)
if [ -z "$orphans" ]
then ok "every sized rule declares a line-height"
else no "rules sized without a line-height: $(printf "%s" "$orphans" | tr "|" ",")"; fi


# Both containers must fill the frame and total the same width, or the page
# edges move on navigation. The two-column spread is main + gap + aside; the
# one-column page is the frame itself. Asserted as arithmetic, not as the
# presence of a string, because the numbers are what the eye sees.
#
# Note the derivation does most of the work: --col-main is calc(page - aside
# - gap), so widening the aside narrows main and the sum still holds. This
# check catches the case that actually goes wrong — someone hardcoding
# --col-main back to a literal, which is how it drifted before.
read -r sum pg pad cap <<<"$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
d = pathlib.Path(sys.argv[1])
tok = (d / "tokens.css").read_text()
css = "\n".join(f.read_text() for f in sorted(d.glob("*.css")) if f.name != "print.css")
def v(n, depth=0):
    m = re.search(rf"{re.escape(n)}:\s*([^;]+);", tok)
    if not m or depth > 8: return None
    val = m.group(1).strip()
    a = re.fullmatch(r"var\(\s*(--[\w-]+)\s*\)", val)
    if a: return v(a.group(1), depth + 1)
    c = re.fullmatch(r"calc\((.*)\)", val)   # nested var() parens
    if c:
        t = re.findall(r"var\((--[\w-]+)\)", c.group(1))
        vals = [v(x, depth + 1) for x in t]
        if any(x is None for x in vals): return None
        return vals[0] - sum(vals[1:])
    lit = re.match(r"([\d.]+)rem", val)
    return float(lit.group(1)) if lit else None
main, aside, gap, page = v("--col-main"), v("--col-aside"), v("--col-gap"), v("--page")
total = None if None in (main, aside, gap) else main + aside + gap
grid = "minmax(0, var(--col-main)) var(--col-aside)" in css and "gap: var(--col-gap)" in css
pad  = bool(re.search(r"main\.page \{[^}]*padding-block", css))
# Nothing may pin a one-column page narrower than the frame.
cap  = not re.search(r"main\.page > :not\(\.spread\) \{ max-width: var\(--col-", css)
print(f"{'1' if total and abs(total - page) < 0.01 and grid else '0'} {page} "
      f"{'1' if pad else '0'} {'1' if cap else '0'}")
PYEOF
)"
if [ "${sum:-0}" -eq 1 ] && [ "${pad:-0}" -eq 1 ] && [ "${cap:-0}" -eq 1 ]
then ok "both containers fill the ${pg}rem frame (main + gap + aside = page)"
else no "containers disagree (sum=$sum pad=$pad uncapped=$cap)"; fi

echo
echo "── the ratio ──"

# Every length in the stylesheet must be a step on the space ladder, a step
# on the type scale, a declared frame width or one of the five breakpoints.
# Authority on a page is consistency, and consistency is not something you
# can keep by eye across 1,400 lines of CSS — it has to be arithmetic.
off="$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
d = pathlib.Path(sys.argv[1])
tok = (d / "tokens.css").read_text()
ladder = {round(float(m), 4) for m in re.findall(r"--s\d+:\s*([\d.]+)rem", tok)}
ladder |= {round(float(m), 4) for m in re.findall(r"--size-[\w-]+:\s*([\d.]+)rem", tok)}
allowed = ladder | {1.0, 0.0, 34.0, 43.25, 17.0, 72.0, 40.0, 44.0, 60.0, 64.0}
bad = []
# Roles and frame widths declared in tokens.css are checked too — a role
# aliasing a bare 6.5rem was invisible while the file was skipped whole.
for name, val in re.findall(r"(--[\w-]+):\s*([\d.]+)rem", tok):
    if re.fullmatch(r"--s\d+", name) or name.startswith("--size-"): continue
    if not any(abs(float(val) - c) < 0.003 for c in allowed):
        bad.append(f"tokens.css {name}: {val}rem")
for f in sorted(d.glob("*.css")):
    if f.name in ("tokens.css", "print.css"): continue
    # Blank comment bodies but keep their newlines, or the reported line
    # number points at the wrong line and the report sends you hunting.
    src = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"),
                 f.read_text(), flags=re.S)
    for ln, line in enumerate(src.split("\n"), 1):
        for m in re.finditer(r"(-?\d*\.?\d+)rem", line):
            v = abs(float(m.group(1)))
            if not any(abs(v - c) < 0.003 for c in allowed):
                bad.append(f"{f.name}:{ln} {m.group(0)}")
print(" ".join(bad[:6]) if bad else "")
PYEOF
)"
# A crashed check must fail, not pass on an empty string. This class of
# bug — a check whose failure mode is passing — has now bitten four times.
st=$?; if [ $st -ne 0 ]; then no "ladder check crashed"; elif [ -z "$off" ]
then ok "every length in the stylesheet is a step on the ladder"
else no "off-ladder lengths: $off"; fi

# The ladder check only ever read rem, so a bare line-height sat off every
# scale in plain sight: .index__claim carried 1.5 while the leading tokens
# run 1.18 / 1.25 / 1.3 / 1.35 / 1.65 / 1.72. Leading is typography too.
# print.css is excluded, as it is from the ladder check above: paper is a
# different medium with its own scale, set in points.
lh="$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
d = pathlib.Path(sys.argv[1])
bad = []
for f in sorted(d.glob("*.css")):
    if f.name in ("tokens.css", "print.css"): continue
    src = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"),
                 f.read_text(), flags=re.S)
    for ln, line in enumerate(src.split("\n"), 1):
        for m in re.finditer(r"line-height:\s*([^;}]+)", line):
            v = m.group(1).strip()
            if not v.startswith("var(--lh-"):
                bad.append(f"{f.name}:{ln} {v}")
print(" ".join(bad[:6]) if bad else "")
PYEOF
)"
st=$?; if [ $st -ne 0 ]; then no "leading check crashed"; elif [ -z "$lh" ]
then ok "every line-height is a leading token"
else no "off-scale leading: $lh"; fi

# The ladder itself must actually be geometric. A step edited by hand to
# "look right" would otherwise sit in the file claiming to be phi.
read -r sr tr <<<"$(python3 - "$THEME/assets/css/tokens.css" <<'PYEOF'
import re, sys, pathlib
tok = pathlib.Path(sys.argv[1]).read_text()
def ratios(vals):
    return [b / a for a, b in zip(vals, vals[1:])]
sp = [float(v) for _, v in sorted(
    ((int(n), v) for n, v in re.findall(r"--s(\d+):\s*([\d.]+)rem", tok)))]
ty = [float(v) for v in re.findall(r"--size-\w+:\s*([\d.]+)rem", tok)]
ty = sorted(set(ty))
ok_s = all(abs(r - 1.272020) < 0.004 for r in ratios(sp))
ok_t = all(abs(r - 1.173985) < 0.004 for r in ratios(ty))
print(f"{1 if ok_s else 0} {1 if ok_t else 0}")
PYEOF
)"
if [ "${sr:-0}" -eq 1 ] && [ "${tr:-0}" -eq 1 ]
then ok "space ladder is phi^1/2 and type scale is phi^1/3 throughout"
else no "scale is not geometric (space=$sr type=$tr)"; fi

# One head, one record grammar. A layout that writes its own band or its own
# row markup is how the spacing drifted apart in the first place.
read -r bands rows <<<"$(python3 - "$THEME/layouts" <<'PYEOF'
import sys, pathlib
d = pathlib.Path(sys.argv[1])
bands = rows = 0
for f in list(d.glob("*.html")) + [q for q in d.rglob("_partials/**/*.html")
                                   if q.name not in ("heading.html", "index-table.html")]:
    src = f.read_text()
    bands += src.count('class="hd')
    rows  += src.count('<tr>')
print(f"{bands} {rows}")
PYEOF
)"
if [ "${bands:-1}" -eq 0 ] && [ "${rows:-1}" -eq 0 ]
then ok "no layout or partial hand-rolls a head or a record row"
else no "markup written outside the components (bands=$bands rows=$rows)"; fi

# A two-column page with nothing in its second column is a 17rem hole. That
# is what `and` short-circuiting to false, compared unequal to nil, produced
# on every post. Negative-tested against exactly that.
#
# It does not catch the other bug from the same sitting — .CurrentSection of
# a top-level page being home, which gave Plates a branch nav of the whole
# site. That version is wrong but self-consistent, so the column and the
# aside still agree and this check is silent. Knowing which defects a check
# cannot see is part of the check.
empty="$(python3 - "$PUB" <<'PYEOF'
import re, sys, pathlib
bad = []
for f in pathlib.Path(sys.argv[1]).rglob("index.html"):
    h = f.read_text()
    m = re.search(r'class="page page--(\w+)"', h)
    if not m: continue
    # Exact count, not presence: three columns means two asides, and a
    # three-column page that rendered one would have a 17rem hole the
    # presence test could not see.
    want = {"one": 0, "two": 1, "three": 2}.get(m.group(1))
    got = h.count('class="spread__aside')
    if want is None:
        bad.append(f"{f.parent.name or '/'}:unknown column mode {m.group(1)}")
    elif want != got:
        bad.append(f"{f.parent.name or '/'}:{m.group(1)} wants {want} aside(s), has {got}")
print(" ".join(sorted(set(bad))[:6]))
PYEOF
)"
if [ -z "$empty" ]
then ok "every page has exactly the asides its column count implies"
else no "column/aside mismatch: $empty"; fi

# A menu that says Catalog pointing at /services/ is a section with two
# names, and the reader sees both. Every nav label must slugify to the last
# segment of its own URL.
slug="$(python3 - "$PUB" <<'PYEOF'
import re, sys, pathlib
h = (pathlib.Path(sys.argv[1]) / "index.html").read_text()
nav = re.search(r'<nav aria-label="Sections">.*?</nav>', h, re.S)
bad = []
if nav:
    for href, txt in re.findall(r'href="([^"]+)"[^>]*>([^<]+)', nav.group(0)):
        seg = href.strip("/").split("/")[-1]
        if not seg: continue          # the journal lives at the root
        want = re.sub(r"[^a-z0-9]+", "-", txt.strip().lower()).strip("-")
        if seg != want:
            bad.append(f"{txt.strip()} -> /{seg}/")
print(" ".join(bad))
PYEOF
)"
if [ -z "$slug" ]
then ok "every nav label matches its own slug"
else no "label and slug disagree: $slug"; fi

# The clock is progressive enhancement, which is only true while the served
# markup is already correct. The failure mode is rendering an empty element
# for the script to fill — the page then looks fine to whoever wrote it and
# is broken for everyone with scripting off. Assert the served stamp is a
# real timestamp, that it is the same shape as the live one so the upgrade
# reflows nothing, and that this is still the only script in the theme.
read -r stamp shape n <<<"$(python3 - "$PUB" "$THEME/layouts" <<'PYEOF'
import re, sys, pathlib
h = (pathlib.Path(sys.argv[1]) / "index.html").read_text()
# Anchored on data-clock, the attribute the script targets, so a change
# of wrapper element cannot quietly stop this from measuring anything.
m = re.search(r'<time[^>]*\bdata-clock\b[^>]*>(.*?)</time>', h, re.S)
txt = " ".join(re.sub(r"<[^>]+>", " ", m.group(1)).split()) if m else ""
# Any real zone abbreviation, not just UTC: the publication's zone is
# configurable and CST reads CDT for half the year.
real  = bool(re.fullmatch(r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [A-Z]{2,5}", txt))
shape = len(txt) == len("2026-09-19 14:32:07 UTC")
# Executable scripts only. A JSON-LD block is a <script> element that runs
# nothing — counting it made the theme look like it had grown a second
# script when what it had grown was structured data. The claim being
# defended is "the clock is the only code that runs", so that is what is
# counted, and a real second script still trips it.
n = sum(len(re.findall(r'<script(?![^>]*application/ld\+json)', f.read_text()))
        for f in pathlib.Path(sys.argv[2]).rglob("*.html"))
print(f"{1 if real else 0} {1 if shape else 0} {n}")
PYEOF
)"
if [ "${stamp:-0}" -eq 1 ] && [ "${shape:-0}" -eq 1 ] && [ "${n:-9}" -eq 1 ]
then ok "clock degrades to a real served timestamp (1 executable script in the theme)"
else no "clock fallback broken (real=$stamp same-shape=$shape scripts=$n)"; fi

# Dated records are grouped by day, each group headed by a sticky date that
# holds until the next one pushes it up. The invariants: one head per
# distinct date, no date heading twice, heads in the same order as the rows,
# and every group actually containing rows.
#
# The previous version of this check read <td class="index__date"> cells.
# Those stopped existing when the date column became a group head, so it
# found nothing to measure and passed on every build. A check that matches
# no elements must fail, not succeed.
log="$(python3 - "$PUB" <<'PYEOF'
import re, sys, pathlib
bad, seen_any = [], False
for f in pathlib.Path(sys.argv[1]).rglob("index.html"):
    h = f.read_text()
    tbl = re.search(r'<table class="index">.*?</table>', h, re.S)
    if not tbl: continue
    t = tbl.group(0)
    groups = re.findall(r'<tbody class="index__group">(.*?)</tbody>', t, re.S)
    if not groups: continue
    name = f.parent.name or "/"
    heads = []
    for g in groups:
        hd = re.search(r'<tr class="index__day">.*?datetime="([^"]+)"', g, re.S)
        rows = len(re.findall(r"<tr(?! class=)", g))
        if hd:
            seen_any = True
            heads.append(hd.group(1))
            if rows == 0: bad.append(f"{name}: {hd.group(1)} heads nothing")
    if len(heads) != len(set(heads)):
        bad.append(f"{name}: a date heads more than one group")
    if heads != sorted(heads, reverse=True) and heads != sorted(heads):
        bad.append(f"{name}: date heads out of order")
if not seen_any:
    bad.append("no dated group heads found anywhere - check matched nothing")
print(" ".join(sorted(set(bad))[:5]))
PYEOF
)"
if [ -z "$log" ]
then ok "each day heads one group, once, in order"
else no "log grouping wrong: $log"; fi

# Column heads are hidden, not deleted. Hiding them is a visual decision;
# removing them would strip a data table of the labels a screen reader
# announces with every cell. Both failure directions are caught: a thead
# that stops being hidden, and one that stops existing.
hd="$(python3 - "$PUB" <<'PYEOF'
import re, sys, pathlib
bad, seen = [], False
for f in pathlib.Path(sys.argv[1]).rglob("index.html"):
    h = f.read_text()
    if '<table class="index">' not in h: continue
    seen = True
    name = f.parent.name or "/"
    th = re.search(r"<thead([^>]*)>(.*?)</thead>", h, re.S)
    if not th: bad.append(f"{name}: no column heads"); continue
    if "u-sr" not in th.group(1): bad.append(f"{name}: column heads not hidden")
    if not re.search(r'<th scope="col"', th.group(2)): bad.append(f"{name}: heads not scoped")
if not seen: bad.append("no index tables found - check matched nothing")
print(" ".join(sorted(set(bad))[:5]))
PYEOF
)"
if [ -z "$hd" ]
then ok "column heads hidden from the page, kept for screen readers"
else no "column heads wrong: $hd"; fi

# The zone selector. It is inert without scripting, so it ships hidden and
# the script reveals it — offering a control that cannot work is worse than
# not offering it.
#
# The publication's own zone has to be somewhere in the list, or a reader who
# switches away can never get back to the zone the archive pages are built in
# — the one the dates beneath the clock are filed under.
#
# It used to have to be *first*, because first was the reader's default. It is
# not either of those things now: the served paint comes from
# params.spectrum.timezone, and the script lands a reader on whichever listed
# zone keeps their machine's own wall clock, falling to UTC when none does. So
# the order is free, and this asserts membership rather than position.
# The publication's zone as Hugo actually resolved it, not as hugo.toml
# spells it. Both checks below need it and both used to re-read the file;
# see the note on the mirror check for what that missed. Resolved once here
# so there is one answer and no second place for it to go stale.
EFF_TZ="$(hugo config --source "$SITE" --themesDir "$TMP/themes" --format json 2>/dev/null | python3 -c "
import json, sys
try:
    print(json.load(sys.stdin).get('timezone') or '-')
except Exception:
    print('-')
")"

read -r n hid zlist cfg <<<"$(python3 - "$SITE" "$PUB" "$EFF_TZ" <<'PYEOF'
import re, sys, pathlib, json, subprocess
root, pub = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
h = (pub / "index.html").read_text()
# Match the class token, not the whole attribute: these elements carry
# more than one class, and an exact-attribute match silently stops finding
# them the moment a second is added.
pick = re.search(r'<div\b([^>]*\bclass="[^"]*\bclock__zones\b[^"]*"[^>]*)>(.*?)</div>', h, re.S)
tzs = re.findall(r'data-tz="([^"]+)"', pick.group(2)) if pick else []
n = len(tzs)
hid = 1 if pick and "hidden" in pick.group(1) else 0
# Handed in, not read from hugo.toml: a zone the file declares and Hugo
# discarded would still be compared against the rendered buttons here.
cfg = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != "-" else ""
print(f"{n} {hid} {','.join(tzs) or '-'} {cfg or '-'}")
PYEOF
)"
offered=0
case ",$zlist," in *",$cfg,"*) offered=1 ;; esac
if [ "${n:-0}" -ge 2 ] && [ "${hid:-0}" -eq 1 ] && [ -n "$cfg" ] && [ "$offered" -eq 1 ]
then ok "zone selector ships hidden and offers the publication's zone ($cfg)"
else no "zone selector wrong (buttons=$n hidden=$hid zones=$zlist timeZone=$cfg)"; fi

# An unset timeZone means Hugo uses the build machine's zone, so the same
# commit renders different times on a laptop and in CI. The mirror the
# script reads must agree with it.
#
# Asked of `hugo config`, not of hugo.toml. A key's presence in the file is
# not the same fact as Hugo having read it: a root setting written below a
# table header is scoped INTO that table, so `timeZone` placed one line
# under [frontmatter] becomes an unknown front-matter key and is discarded
# in silence. The file still matches, the check still passes, and every date
# on the site quietly falls back to the build machine's zone — the precise
# failure this check exists to prevent, surviving the check that prevents
# it. Found in the sibling Pulse repo, where exactly that had happened to
# enableGitInfo and timeZone in one commit.
#
# Discarded and applied look identical from the outside, so the assertion
# has to be made against the effective configuration.
read -r tzc tzp <<<"$(hugo config --source "$SITE" --themesDir "$TMP/themes" --format json 2>/dev/null | python3 -c "
import json, sys
try:
    c = json.load(sys.stdin)
except Exception:
    print('- -'); raise SystemExit
root = c.get('timezone') or '-'
param = (c.get('params') or {}).get('spectrum', {}).get('timezone') or '-'
print(f'{root} {param}')
")"
if [ "$tzc" != "-" ] && [ "$tzc" = "$tzp" ]
then ok "timeZone is read by Hugo and mirrored for the clock ($tzc)"
else no "timezone config wrong (effective timeZone=$tzc param=$tzp)"; fi

# A class in the markup with no rule behind it is invisible: the element
# renders, unstyled, looking like a spacing mistake rather than a missing
# declaration. .index__dayline shipped that way — the flex row that puts
# the weekday at the far edge was written into the template and never into
# the stylesheet, so the date and the weekday rendered flush together.
orphan="$(python3 - "$THEME" <<'PYEOF'
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
css = "\n".join(f.read_text() for f in (root / "assets/css").glob("*.css"))
styled = set(re.findall(r"\.([a-zA-Z][\w-]*)", css))
used = set()
for f in (root / "layouts").rglob("*.html"):
    for attr in re.findall(r'class="([^"{}]*)"', f.read_text()):
        used |= {c for c in attr.split() if c}
# Classes the script adds at runtime are styled but never in the templates;
# the reverse is what matters here.
missing = sorted(c for c in used - styled if not c.startswith("u-"))
print(" ".join(missing[:8]))
PYEOF
)"
if [ -z "$orphan" ]
then ok "every class in the markup has a rule behind it"
else no "classes with no rule: $orphan"; fi

# The masthead is one row: the nav is a sibling of the identity, directly
# inside the inner. Nested a level deeper it stops being floated against
# the identity, which is what a lost </div> did once already.
#
# The previous version of this check looked for a .masthead__top wrapper.
# That element no longer exists, so it found nothing to measure and passed
# on every build — the same way the date check did when its cells moved.
read -r sib bal <<<"$(python3 - "$PUB/index.html" <<'PYEOF'
import re, sys, pathlib
h = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r'<header class="masthead">.*?</header>', h, re.S)
if not m: print("0 0"); raise SystemExit
head, depth, inner_at, sib, seen_nav = m.group(0), 0, None, 0, False
for tag in re.finditer(r'<(/?)(\w+)([^>]*)>', head):
    close, name, attrs = tag.group(1), tag.group(2), tag.group(3)
    if name in ("img", "br", "input", "path", "meta"): continue
    if not close:
        if "masthead__inner" in attrs: inner_at = depth + 1
        elif name == "nav":
            seen_nav = True
            if inner_at is not None and depth == inner_at: sib = 1
        depth += 1
    else:
        depth -= 1
print(f"{sib if seen_nav else 0} {1 if depth == 0 else 0}")
PYEOF
)"
if [ "${sib:-0}" -eq 1 ] && [ "${bal:-0}" -eq 1 ]
then ok "masthead is one row, nav beside the identity, tags balanced"
else no "masthead structure broken (nav-beside-identity=$sib balanced=$bal)"; fi

# Every rendered date goes through time.In on the publication's zone, so the
# whole site reads in that zone wherever it is built. Two ways to get this
# wrong, and both shipped:
#
#   .Date.Format   formats the stored value. One entry filed at 00:17 UTC came
#                  out September 20 on its own page and 19 SEP in the journal.
#   .Date.Local    formats in the *build machine's* zone, which is only the
#                  publication's by luck. Correct on a laptop in Chicago, a day
#                  out in a UTC runner: the journal grew a day whose archive
#                  page no entry belongs to, and the day link 404ed.
#
# Machine values keep their offset and are exempt: that is the instant, not a
# rendering of it.
stray="$(python3 - "$THEME/layouts" <<'PYEOF'
import re, sys, pathlib
bad = []
for f in sorted(pathlib.Path(sys.argv[1]).rglob("*.html")):
    for n, line in enumerate(f.read_text().split("\n"), 1):
        for m in re.finditer(r'\.(?:Date|Lastmod)\.Format\s+"([^"]+)"', line):
            if m.group(1) == "2006-01-02T15:04:05Z07:00": continue   # the instant
            bad.append(f"{f.name}:{n}")
        if re.search(r'\.(?:Date|Lastmod)\.Local\b', line):
            bad.append(f"{f.name}:{n}")
print(" ".join(sorted(set(bad))[:6]))
PYEOF
)"
if [ -z "$stray" ]
then ok "every rendered date goes through the publication zone"
else no "dates formatted outside the zone: $stray"; fi

# The panels stick as one block; the reserved slot above them scrolls away.
# position:sticky travels the height of its containing block, so the block
# is a child of the aside rather than the aside itself — sticking the aside
# would pin the zones with everything else. And the aside has to stretch to
# the column's height rather than its content's, or the panels unstick as
# soon as the last one scrolls by.
read -r stick child stretch slots <<<"$(python3 - "$THEME/assets/css" "$PUB/index.html" <<'PYEOF'
import re, sys, pathlib
css = "\n".join(f.read_text() for f in sorted(pathlib.Path(sys.argv[1]).glob("*.css"))
                if f.name != "print.css")
def rule(sel):
    m = re.search(rf"(?:^|[}}\n])\s*{re.escape(sel)}\s*\{{([^}}]*)\}}", css, re.M)
    return m.group(1) if m else ""

stick = 1 if "position: sticky" in rule(".aside__panels") else 0

# Depth-walked, not indentation-matched: whitespace is not structure.
h = pathlib.Path(sys.argv[2]).read_text()
a = re.search(r'<aside class="spread__aside".*?</aside>', h, re.S)
kids, depth = [], 0
for tag in re.finditer(r'<(/?)(\w+)([^>]*)>', a.group(0) if a else ""):
    close, name, attrs = tag.group(1), tag.group(2), tag.group(3)
    if name in ("img", "br", "input", "path", "meta", "time", "a", "span", "button"): continue
    if not close:
        if depth == 1:
            c = re.search(r'class="([^"]+)"', attrs)
            if c: kids.append(set(c.group(1).split()))
        depth += 1
    else:
        depth -= 1
# The slot is a sibling of the sticky block, not inside it: sticky travels
# the height of its containing block, and the slot has to scroll away.
child = 1 if (len(kids) >= 2 and "aside__top" in kids[0]
              and "aside__panels" in kids[1]) else 0

# align-items:start would leave the aside content-height, and the panels
# would unstick as soon as the last one scrolled by.
stretch = 0 if re.search(r"\.spread\s*\{[^}]*align-items:\s*start", css) else 1

# A reserved slot with no height reserves nothing. Both slots exist so the
# column beside them starts at one height on every page, and both are
# invisible when empty — so losing the height is silent.
slots = 1
for sel in (".aside__top", ".page-head__crumb"):
    if "min-height" not in rule(sel): slots = 0
print(f"{stick} {child} {stretch} {slots}")
PYEOF
)"
if [ "${stick:-0}" -eq 1 ] && [ "${child:-0}" -eq 1 ] && [ "${stretch:-0}" -eq 1 ] && [ "${slots:-0}" -eq 1 ]
then ok "the panels stick, and both reserved slots hold their height"
else no "sticky aside broken (sticky=$stick order=$child stretched=$stretch slots=$slots)"; fi

# Braces balance in every stylesheet. A stray closing brace is ignored by
# every parser, so a block deleted carelessly leaves one behind and nothing
# ever says so — there was one sitting at the end of components.css from a
# rule removed long before. Depth is also never allowed to go negative,
# which catches the brace being in the wrong place rather than merely
# surplus.
braces="$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
bad = []
for f in sorted(pathlib.Path(sys.argv[1]).glob("*.css")):
    src = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"),
                 f.read_text(), flags=re.S)
    depth = 0
    for n, line in enumerate(src.split("\n"), 1):
        for ch in line:
            if ch == "{": depth += 1
            elif ch == "}":
                depth -= 1
                if depth < 0: bad.append(f"{f.name}:{n} unmatched }}"); depth = 0
    if depth: bad.append(f"{f.name}: {depth} block(s) left open")
print(" ".join(bad[:5]))
PYEOF
)"
if [ -z "$braces" ]
then ok "braces balance in every stylesheet"
else no "unbalanced css: $braces"; fi

# A tag's hover underline has to be drawn on the element that carries the
# frequency colour. The anchor is color:inherit — it has to be, or the
# :visited pass reaches the colour and flattens every tag to one hue — so
# an underline declared there takes the surrounding ink instead of the
# tag's. And hover must not bring up a border: a grey rectangle around a
# word whose whole job is to be a colour.
tag="$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
css = "\n".join(f.read_text() for f in sorted(pathlib.Path(sys.argv[1]).glob("*.css"))
                if f.name != "print.css")
def rule(sel):
    m = re.search(rf"(?:^|[}}\n])\s*{re.escape(sel)}\s*\{{([^}}]*)\}}", css, re.M)
    return m.group(1) if m else None
bad = []
anchor = rule(".tag-signal:hover")
span   = rule(".tag-signal:hover .tag-signal__name")
if span is None or "text-decoration" not in span:
    bad.append("underline not on the coloured span")
if anchor and "text-decoration" in anchor:
    bad.append("underline still on the anchor")
if anchor and re.search(r"border(-\w+)?-?color\s*:", anchor):
    bad.append("hover draws a border")
print(" ".join(bad))
PYEOF
)"
if [ -z "$tag" ]
then ok "tag hover underlines in the tag's own color, with no box"
else no "tag hover wrong: $tag"; fi

# The masthead sticks, so everything else that sticks pins below it, and
# the only strip content can scroll through is the gap between the two.
# A pinned band has to cover exactly that gap: a shorter cover leaves a
# slit, and a taller one reaches past the masthead and eats the row above.
#
# --sticky-top must be derived from the masthead's own height, not typed,
# or restyling the identity silently moves the masthead out from under
# everything pinned to it.
cover="$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
css = "\n".join(f.read_text() for f in sorted(pathlib.Path(sys.argv[1]).glob("*.css"))
                if f.name != "print.css")
def rule(sel):
    m = re.search(rf"(?:^|[}}\n])\s*{re.escape(sel)}\s*\{{([^}}]*)\}}", css, re.M)
    return m.group(1) if m else None
bad = []
mast = rule(".masthead") or ""
if "position: sticky" not in mast: bad.append("masthead does not stick")
tok = (pathlib.Path(sys.argv[1]) / "tokens.css").read_text()
if not re.search(r"--sticky-top:\s*calc\(\s*var\(--masthead-h\)", tok):
    bad.append("--sticky-top not derived from the masthead height")
head = rule(".index__day th") or ""
if "top: var(--sticky-top)" in head:
    c = rule(".index__day th::before")
    if c is None: bad.append("day head pinned with no cover")
    else:
        if "height: var(--sticky-gap)" not in c: bad.append("cover is not the gap's height")
        if "bottom: 100%" not in c: bad.append("cover is not directly above the band")
        if "background:" not in c: bad.append("cover is transparent")
print(" ".join(bad))
PYEOF
)"
if [ -z "$cover" ]
then ok "the masthead sticks and pinned bands cover their own gap"
else no "sticky gap uncovered: $cover"; fi

# Every date in the journal links to a day that was actually built, and
# every day page carries the navigation. Day terms come from the taxonomy,
# so a link can only point at a day with entries on it — but only as long
# as the term stamped in front matter is the one the journal prints, and
# those are computed in two different places.
days="$(python3 - "$PUB" <<'PYEOF'
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
bad, seen = [], 0
for f in list(root.glob("index.html")) + list(root.glob("page/*/index.html")):
    h = f.read_text()
    for href in re.findall(r'<a class="index__daylink" href="([^"]+)"', h):
        seen += 1
        if not (root / href.strip("/") / "index.html").exists():
            bad.append(f"{href} not built")
for f in root.glob("archives/*/index.html"):
    term = f.parent.name
    if len(term) != 10: continue
    if 'class="daynav"' not in f.read_text():
        bad.append(f"{term} has no day nav")
if not seen: bad.append("no day links found - check matched nothing")
print(" ".join(sorted(set(bad))[:5]))
PYEOF
)"
if [ -z "$days" ]
then ok "every journal date links to a day that exists, and every day navigates"
else no "day links broken: $days"; fi

# The headline sits at the same height whether or not the page has a
# breadcrumb. The slot is reserved on every page, so a title does not drop
# by the trail's height the moment a page is nested.
slot="$(python3 - "$PUB" <<'PYEOF'
import re, sys, pathlib
bad, seen = [], 0
for f in pathlib.Path(sys.argv[1]).rglob("index.html"):
    h = f.read_text()
    if 'class="hd hd--page"' not in h: continue
    seen += 1
    if 'class="page-head__crumb"' not in h:
        bad.append(f"{f.parent.name or '/'}: headline with no reserved slot")
if not seen: bad.append("no page heads found - check matched nothing")
print(" ".join(sorted(set(bad))[:5]))
PYEOF
)"
if [ -z "$slot" ]
then ok "the headline sits at one height, breadcrumb or not"
else no "breadcrumb slot missing: $slot"; fi

# Every palette block that sets a surface must also set the tag tuning for
# it. Custom properties do not inherit between sibling selectors, so a
# block that omits them falls back to :root — the paper palette, whose apex
# lightness is 0.22. The two explicitly-forced dark blocks were doing
# exactly that, which painted the most-used subject near-black on black for
# any site that set theme = 'dark' rather than leaving it to the OS.
pal="$(python3 - "$THEME/assets/css/tokens.css" <<'PYEOF'
import re, sys, pathlib
t = pathlib.Path(sys.argv[1]).read_text()
NEED = {"--tag-apex-hue", "--tag-l-rare", "--tag-l-apex", "--tag-c-peak", "--tag-glow-max"}
def is_uv(sel):
    return bool(re.search(r'(?<!:not\()\[data-palette="ultraviolet"\]', sel))
bad, seen = [], 0
for m in re.finditer(r'(?m)^([^{}\n][^{}]*?)\{([^{}]*)\}', t):
    sel, body = " ".join(m.group(1).split()), m.group(2)
    if "--surface:" not in body: continue
    seen += 1
    have = dict(re.findall(r"(--tag-[\w-]+)\s*:\s*([^;]+);", body))
    missing = NEED - set(have)
    if missing:
        bad.append(f"{sel[:28]}: no {','.join(sorted(missing))}")
        continue
    # A dark surface needs a light apex, and the hue must match the palette.
    surf = re.search(r"--surface:\s*#(\w{6})", body).group(1)
    dark = sum(int(surf[i:i+2], 16) for i in (0, 2, 4)) < 3 * 128
    apex = float(have["--tag-l-apex"])
    if dark and apex < 0.6: bad.append(f"{sel[:28]}: apex {apex} on a dark surface")
    if not dark and apex > 0.6: bad.append(f"{sel[:28]}: apex {apex} on a light surface")
    hue = have["--tag-apex-hue"].strip()
    if is_uv(sel) and hue == "82": bad.append(f"{sel[:28]}: default hue in the uv palette")
if not seen: bad.append("no palette blocks found - check matched nothing")
print(" ".join(bad[:4]))
PYEOF
)"
if [ -z "$pal" ]
then ok "every palette tunes its own tags for its own surface"
else no "palette tuning wrong: $pal"; fi

# The filled control, in every palette, in every link state.
#
# Two failures live here and only one is a colour. The pairing a palette
# declares was never wrong — 5.39:1 at worst. What was wrong is that a
# button made from an <a> could not keep it: `a:visited` is 0,1,1 and `.btn`
# is 0,1,0, so a visited target dropped the label to --link-visited on the
# signal fill at 1.07:1, in all six palettes at once. So this asserts the
# arithmetic AND the specificity, because the arithmetic passed throughout.
read -r pairs worst unpinned <<<"$(python3 - "$THEME/assets/css" <<'PYEOF'
import re, sys, pathlib
d = pathlib.Path(sys.argv[1])
tok = (d / "tokens.css").read_text()
base = (d / "base.css").read_text()

def lum(h):
    h = h.lstrip("#")
    if len(h) == 3: h = "".join(c * 2 for c in h)
    r, g, b = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)
def ratio(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)

# Every block that declares either half of the pair, carrying forward the
# root defaults for whichever half it does not restate.
starts = [(m.start(), m.group(0)) for m in re.finditer(r"(?m)^(?::root|@media)[^{]*\{", tok)]
ends = [p for p, _ in starts][1:] + [len(tok)]
root_sig = root_ink = None
pairs = []; worst = 99.0
for (pos, _), end in zip(starts, ends):
    blk = tok[pos:end]
    g = lambda n: (re.search(rf"{n}:\s*(#[0-9A-Fa-f]{{3,8}})", blk) or [None, None])[1]
    sig, ink = g("--signal"), g("--ink-on-signal")
    if root_sig is None and sig: root_sig = sig
    if root_ink is None and ink: root_ink = ink
    sig, ink = sig or root_sig, ink or root_ink
    if not (sig and ink): continue
    pairs.append(1); worst = min(worst, ratio(ink, sig))

# The label must be pinned on every link state, or a link rule outranks it.
want = {":link", ":visited", ":active"}
have = {st for st in want
        if re.search(rf"\.btn{st}[^{{]*\{{[^}}]*color:\s*var\(--ink-on-signal\)", base)}
print(len(pairs), round(worst, 2), " ".join(sorted(want - have)) or "-")
PYEOF
)"
if [ "${pairs:-0}" -gt 0 ] && [ "$unpinned" = "-" ] \
   && python3 -c "import sys; sys.exit(0 if float('$worst') >= 4.5 else 1)"
then ok "the filled control meets AA in every palette (worst ${worst}:1, pinned on every link state)"
else no "button contrast: worst ${worst}:1 over ${pairs:-0} palettes, unpinned states: $unpinned"; fi

# Every template the theme ships is reached by the demo content. A partial
# nothing exercises is a feature documented but never rendered — figure.html
# sat unused while the README promised entries take a featured image.
#
# Built against exampleSite, not the consuming site. This read $SITE until the
# theme grew layouts that site had no page for, and reported three templates
# unused when the fault was the fixture: a consuming site is free to use only
# part of a theme, and the theme's own demo is the thing that must use all of
# it. It is also why the check now works in a clone with no Pulse beside it.
# Through the same symlinked themes dir as the fixture: `--themesDir ../..`
# only resolved when the checkout directory happened to be named after the
# theme, and when it did not, the build failed, printed no "is unused" lines,
# and this check passed on a build that never happened.
unused="$( (hugo --source "$SITE" --themesDir "$TMP/themes" \
              --printUnusedTemplates --destination "$TMP/ut" 2>&1) \
           | grep -o 'Template [^ ]* is unused' | sed 's/Template //;s/ is unused//' | head -5 )"
if [ -z "$unused" ]
then ok "every template the theme ships is exercised by the content"
else no "templates never reached: $(printf '%s' "$unused" | tr '\n' ' ')"; fi

# Structured data. Validity is not the assertion — the interesting failure
# parses. Go's html/template treats a <script> body as JavaScript, so jsonify
# without safeJS ships a JSON *string* whose value is the document: it loads,
# it round-trips, and every consumer reads a string where a graph should be.
# So the check is on shape: an object, with a @graph of objects.
#
# $TMP/ut is the exampleSite build the unused-template check just made.
read -r blocks bad kinds <<<"$(python3 - "$TMP/ut" <<'PYEOF'
import json, re, sys, pathlib, html
root = pathlib.Path(sys.argv[1]); blocks = 0; bad = []; kinds = set()
for f in sorted(root.rglob("*.html")):
    for m in re.finditer(r'<script type="application/ld\+json">(.*?)</script>',
                         f.read_text(errors="replace"), re.S):
        blocks += 1
        where = f.relative_to(root).parent
        try:
            d = json.loads(html.unescape(m.group(1)))
        except Exception:
            bad.append(f"{where}:unparseable"); continue
        if not isinstance(d, dict):
            bad.append(f"{where}:double-encoded"); continue
        g = d.get("@graph")
        if not isinstance(g, list) or not g:
            bad.append(f"{where}:no-graph"); continue
        for node in g:
            if not isinstance(node, dict):
                bad.append(f"{where}:graph-node-{type(node).__name__}"); break
            kinds.add(node.get("@type"))
        # Every page states the publication it belongs to.
        if not {"Organization", "WebSite"} <= {n.get("@type") for n in g if isinstance(n, dict)}:
            bad.append(f"{where}:no-publisher")
print(blocks, len(bad), len(kinds))
if bad: print(" ".join(sorted(set(bad))[:4]), file=sys.stderr)
PYEOF
)"
# Fails when it matches nothing: a build that stopped emitting schema entirely
# would otherwise report zero failures and pass.
if [ "${blocks:-0}" -gt 0 ] && [ "${bad:-1}" -eq 0 ] && [ "${kinds:-0}" -ge 6 ]
then ok "every page carries a well-formed schema graph ($blocks blocks, $kinds types)"
else no "schema broken ($bad bad of ${blocks:-0}, ${kinds:-0} types)"; fi

# Heading order. A heading may go back up any number of levels — an h2 after
# an h3 closes the h3's section — but going down it may only ever descend by
# one. h1 followed by h3 is a level nobody wrote, and a reader navigating by
# heading falls through the hole.
#
# The conversion pages ran h1 -> h3 -> h3 -> h3 -> h2 for as long as they
# existed: features.html set its items at h3 with nothing between them and
# the page title, and faq.html then closed with an h2. Every check here was
# green throughout, because none of them had ever looked at the outline.
read -r pages skips first <<<"$(python3 - "$TMP/ut" <<'PYEOF'
import re, sys, pathlib
root = pathlib.Path(sys.argv[1]); pages = skips = 0; first = "-"
for f in sorted(root.rglob("*.html")):
    body = f.read_text(errors="replace")
    # The outline is the page's, so the sr-only column heads count too; only
    # headings inside the document body are in scope.
    levels = [int(m.group(1)) for m in re.finditer(r"<h([1-6])\b", body)]
    if not levels: continue
    pages += 1
    for prev, cur in zip(levels, levels[1:]):
        if cur > prev + 1:
            skips += 1
            if first == "-":
                first = f"{f.relative_to(root).parent or '/'}:h{prev}->h{cur}"
            break
print(pages, skips, first)
PYEOF
)"
# Fails when it matches nothing, like the rest: a build that stopped emitting
# headings would otherwise pass with zero skips.
if [ "${pages:-0}" -gt 0 ] && [ "${skips:-1}" -eq 0 ]
then ok "no page skips a heading level ($pages pages)"
else no "heading levels skipped on ${skips:-?} of ${pages:-0} pages, first $first"; fi

# A preview is not the publication. The robots template is the only thing that
# reads the build environment, so it is the only thing that can tell a deploy
# preview apart from the real site — and a preview that serves the production
# robots.txt asks to be indexed under a hostname that duplicates it.
#
# Asserted in both directions. A template that disallowed everything would
# pass a preview-only check while quietly delisting the real site.
prev="$TMP/preview"
if (hugo --source "$SITE" --themesDir "$TMP/themes" --destination "$prev" \
         --environment preview -D --quiet --panicOnWarning) 2>/dev/null; then
  prod_ok=0; prev_ok=0
  grep -q '^Allow: /$' "$PUB/robots.txt" 2>/dev/null && prod_ok=1
  grep -q '^Disallow: /$' "$prev/robots.txt" 2>/dev/null \
    && ! grep -q '^Allow: /$' "$prev/robots.txt" && prev_ok=1
  if [ "$prod_ok" -eq 1 ] && [ "$prev_ok" -eq 1 ]
  then ok "production invites indexing, a preview build refuses it"
  else no "robots wrong (production allows=$prod_ok preview disallows=$prev_ok)"; fi
else
  no "preview build failed"
fi

# entryAside, asserted in both directions against the same content.
#
# The feature is two templates agreeing: columns.html has to grant the second
# column and page.html has to fill it. Either one alone is silent — a column
# with no panels is a 17rem hole, and panels with no column are never
# rendered — so a one-directional check would pass on half an implementation.
#
# The off case is the one that protects existing publications. exampleSite
# opts in, so $PUB above is the on case and the off case is built here with
# the parameter overridden back to false.
# Overridden by environment rather than by a second fixture directory, so
# the two builds are provably the same content and differ only in the one
# parameter under test.
off="$TMP/entryaside-off"
if (HUGO_PARAMS_SPECTRUM_ENTRYASIDE=false hugo --source "$SITE" \
         --themesDir "$TMP/themes" --destination "$off" \
         -D --quiet --panicOnWarning) 2>/dev/null; then

  entry_on="$PUB/posts/morning-pass/index.html"
  entry_off="$off/posts/morning-pass/index.html"
  branch_on="$PUB/docs/procedure/index.html"

  on_clock=0;  grep -q 'class="clock"' "$entry_on"  2>/dev/null && on_clock=1
  off_clock=0; grep -q 'class="clock"' "$entry_off" 2>/dev/null && off_clock=1
  on_col=0;    grep -q 'page--two'     "$entry_on"  2>/dev/null && on_col=1
  off_col=0;   grep -q 'page--one'     "$entry_off" 2>/dev/null && off_col=1

  if [ "$on_clock" -eq 1 ] && [ "$on_col" -eq 1 ] \
     && [ "$off_clock" -eq 0 ] && [ "$off_col" -eq 1 ]
  then ok "entryAside: an entry gains the panels when set, and neither when not"
  else no "entryAside (on: clock=$on_clock two-col=$on_col / off: clock=$off_clock one-col=$off_col)"; fi

  # A branch page has its own navigation and must not be handed the journal's
  # panels instead, whichever way the parameter is set.
  b_nav=0;   grep -q 'class="branch"' "$branch_on" 2>/dev/null && b_nav=1
  b_clock=0; grep -q 'class="clock"'  "$branch_on" 2>/dev/null && b_clock=1
  if [ "$b_nav" -eq 1 ] && [ "$b_clock" -eq 0 ]
  then ok "entryAside: a branch page keeps its own navigation"
  else no "entryAside branch page (nav=$b_nav clock=$b_clock)"; fi
else
  no "entryAside: the off-case build failed"
fi

# The record's second line, and where the fallback chain has to stop.
#
# A table where some rows carry a subtitle and some do not reads as missing
# data rather than as variation, so the chain runs claim -> excerpt ->
# description: three fields that are all one authored line about the entry.
# It stops there. .Summary would fill every remaining row, which is the
# tempting and wrong fix — it is the first seventy words of the body, so the
# column fills with paragraphs that break mid-sentence.
#
# Both directions on the same build: the landing page has a description and
# no claim, so its row must gain the description; the journal's entries have
# neither, so their rows must stay bare. If .Summary ever leaks in, the
# second assertion is the one that catches it.
if [ -f "$PUB/patterns/index.html" ] && [ -f "$PUB/index.html" ]; then
  fb=0; grep -q 'index__claim">Calibration, bench time and reference standards' \
          "$PUB/patterns/index.html" && fb=1
  rows=$(grep -o 'class="index__title"' "$PUB/index.html" | wc -l)
  subs=$(grep -o 'class="index__claim"' "$PUB/index.html" | wc -l)
  if [ "$fb" -eq 1 ] && [ "$rows" -gt 0 ] && [ "$subs" -lt "$rows" ]
  then ok "the index falls back to a description, and stops short of the body ($subs of $rows journal rows subtitled)"
  else no "index second line (description fallback=$fb, $subs of $rows journal rows subtitled)"; fi
else
  no "index second line: the example site build is missing"
fi

# The second line, all four rungs, on a fixture rather than on the demo.
#
# This was asserted on exampleSite alone, which made it hostage to content
# anyone is free to improve. The consuming site reported the trap: writing
# the claims the ragged-row finding called for removed the only bare rows it
# had, so the corpus that proved the fallback was needed stopped being able
# to test it. A consumer who acts on a finding stops being able to test it,
# and the demo is about to be rewritten with claims on every entry.
#
# Fixtures do not have that problem, because nobody is tempted to finish
# them. The fourth rung is the one that matters and was never asserted
# anywhere: a page with nothing authored must render no second line at all.
# .Summary would fill it with the first seventy words of the body, which is
# the tempting fix and the wrong one.
fb="$TMP/fallback"; mkdir -p "$fb/content/posts" "$fb/themes"
ln -s "$THEME" "$fb/themes/spectrum"
cat > "$fb/hugo.toml" <<'TOML'
baseURL = 'https://example.org/'
title = 'fallback fixture'
theme = 'spectrum'
TOML
cat > "$fb/content/posts/a.md" <<'MD'
+++
title = "A"
date = 2026-01-04
claim = "CLAIMWINS"
excerpt = "EXCERPTLOSES"
description = "DESCLOSES"
+++
Body prose that must never reach the index.
MD
cat > "$fb/content/posts/b.md" <<'MD'
+++
title = "B"
date = 2026-01-03
excerpt = "EXCERPTWINS"
description = "DESCLOSES"
+++
Body prose that must never reach the index.
MD
cat > "$fb/content/posts/c.md" <<'MD'
+++
title = "C"
date = 2026-01-02
description = "DESCWINS"
+++
Body prose that must never reach the index.
MD
cat > "$fb/content/posts/d.md" <<'MD'
+++
title = "D"
date = 2026-01-01
+++
Body prose that must never reach the index and is long enough to be a summary.
MD
(cd "$fb" && hugo --quiet --destination out --panicOnWarning) >/dev/null 2>&1
fbh="$fb/out/index.html"
rung1=0; grep -q 'index__claim">CLAIMWINS<'   "$fbh" 2>/dev/null && rung1=1
rung2=0; grep -q 'index__claim">EXCERPTWINS<' "$fbh" 2>/dev/null && rung2=1
rung3=0; grep -q 'index__claim">DESCWINS<'    "$fbh" 2>/dev/null && rung3=1
lost=$(grep -o 'LOSES' "$fbh" 2>/dev/null | wc -l)
subs=$(grep -o 'class="index__claim"' "$fbh" 2>/dev/null | wc -l)
body=$(grep -o 'Body prose that must never reach the index' "$fbh" 2>/dev/null | wc -l)
if [ "$rung1" -eq 1 ] && [ "$rung2" -eq 1 ] && [ "$rung3" -eq 1 ] \
   && [ "${lost:-1}" -eq 0 ] && [ "${subs:-0}" -eq 3 ] && [ "${body:-1}" -eq 0 ]
then ok "the second line falls claim > excerpt > description and stops: 3 of 4 rows subtitled, no body prose"
else no "fallback chain (claim=$rung1 excerpt=$rung2 desc=$rung3 shadowed=$lost subtitled=$subs body=$body)"; fi

# AggregateRating: capability here, never in the demo.
#
# rating is the only offer field that renders nowhere on the page — it exists
# solely to emit an AggregateRating — so a demo carrying one ships a
# machine-readable claim about what customers thought, invisible to anyone
# copying exampleSite into a real site. A search engine acts on it. That is
# fabricated proof with a neutral filename, and it is the half that ships by
# accident precisely because no one can see it.
#
# The capability still has to work, so it is tested on a fixture that is
# built and thrown away. Adversarial and structural coverage belongs in
# fixtures; fabricated proof belongs nowhere near a corpus built to be copied.
rd="$TMP/rating"; mkdir -p "$rd/content/patterns" "$rd/themes"
ln -s "$THEME" "$rd/themes/spectrum"
cat > "$rd/hugo.toml" <<'TOML'
baseURL = 'https://example.org/'
title = 'rating fixture'
theme = 'spectrum'
TOML
cat > "$rd/content/patterns/thing.md" <<'MD'
+++
title  = "Thing"
layout = "conversion"
sku    = "SKU-1"
price  = "10.00"
rating = { value = "4.2", count = "9" }
+++
Body.
MD
(cd "$rd" && hugo --quiet --destination out --panicOnWarning) >/dev/null 2>&1
agg=$(grep -o '"AggregateRating"' "$rd/out/patterns/thing/index.html" 2>/dev/null | wc -l)
demo=$(grep -ro '"AggregateRating"' "$PUB" 2>/dev/null | wc -l)
if [ "${agg:-0}" -ge 1 ] && [ "${demo:-1}" -eq 0 ]
then ok "AggregateRating is supported, and the demo fabricates none"
else no "AggregateRating (fixture=$agg demo=$demo)"; fi

# The revision record, asserted in both directions.
#
# docs/citation.md has said since the theme existed that corrections are
# recorded at the foot of the entry, and for four releases nothing rendered
# one — a convention the publication states and its own theme cannot keep.
#
# The direction that matters is the second. A document is a thing whose
# version a reader needs, and a record is what is published now; a post
# edited after its date has simply been edited, so putting a revision
# history on one would claim an accountability the journal does not have.
# Asserted on the built site rather than on the partial, because the partial
# rendering correctly while no layout calls it is exactly the failure that
# hid here before.
if [ -d "$PUB" ]; then
  doc=0;  grep -q 'class="revisions"' "$PUB/docs/procedure/index.html" 2>/dev/null && doc=1
  conv=0; grep -q 'class="revisions"' "$PUB/patterns/service/index.html" 2>/dev/null && conv=1
  rows=$(grep -o 'class="revisions__entry"' "$PUB/docs/procedure/index.html" 2>/dev/null | wc -l)
  recs=$(grep -l 'class="revisions"' "$PUB"/posts/*/index.html 2>/dev/null | wc -l)
  if [ "$doc" -eq 1 ] && [ "$conv" -eq 1 ] && [ "$rows" -gt 0 ] && [ "$recs" -eq 0 ]
  then ok "documents carry a revision record ($rows entries), records carry none"
  else no "revision record (page=$doc conversion=$conv rows=$rows posts-with-one=$recs)"; fi
else
  no "revision record: the example site build is missing"
fi

# The demo has to stay out of the case it is meant to argue against. A
# distribution that collapses to three bands would put the theme's own
# example site under the resolution note, which is the opposite of a demo.
if [ -f "$PUB/tags/index.html" ]; then
  eb=$(grep -o '\-\-tag-signal:[0-9.]\{6\}' "$PUB/tags/index.html" | sort -u | wc -l)
  [ "$eb" -ge 4 ] \
    && ok "the example site's field has enough bands to read as a field ($eb)" \
    || no "the example site collapsed to $eb bands"
else
  no "example site band count: build missing"
fi

# The render hooks, asserted by position rather than by presence.
#
# head-append.html and body-open.html ship empty so a site can add to <head>
# and to the top of <body> without forking a forty-line head.html. A fork is a
# copy, and a copy goes stale in silence the moment the original moves — the
# site serves an old <head> against a new theme and nothing says so.
#
# Presence is not the contract, position is. A tag manager's <noscript> iframe
# is specified to be the first child of <body> and is checked for it, and
# anything appended to <head> must not be able to push <meta charset> out of
# the first 1024 bytes where the parser stops guessing the encoding. So the
# fixture overrides both hooks and asserts where the markup landed.
#
# The markers are real elements, not HTML comments. This build strips comments
# from its output and leaves everything else alone, so a comment marker reads
# as "the override did not apply" when the override applied perfectly. That
# cost an hour once.
hk="$TMP/hooks"; mkdir -p "$hk/content" "$hk/themes" "$hk/layouts/_partials"
ln -s "$THEME" "$hk/themes/spectrum"
cat > "$hk/hugo.toml" <<EOF
baseURL = 'https://example.org/'
title = 'hooks'
theme = 'spectrum'
EOF
printf '<meta name="headmark" content="1">\n' > "$hk/layouts/_partials/head-append.html"
printf '<i data-bodymark></i>\n'              > "$hk/layouts/_partials/body-open.html"
(cd "$hk" && hugo --quiet --destination out --panicOnWarning >/dev/null 2>&1)
H="$hk/out/index.html"
if [ -f "$H" ]; then
  # Byte offsets, so these are assertions about order in the document rather
  # than about the markers merely existing somewhere in it.
  off () { python3 -c "import sys;print(open(sys.argv[1],'rb').read().find(sys.argv[2].encode()))" "$H" "$1"; }
  charset=$(off '<meta charset');        headmark=$(off 'name="headmark"')
  headend=$(off '</head>');              bodyopen=$(off '<body>')
  bodymark=$(off 'data-bodymark');       skip=$(off 'class="skip"')
  if [ "$charset" -gt -1 ] && [ "$charset" -lt 1024 ] \
     && [ "$headmark" -gt "$charset" ] && [ "$headmark" -lt "$headend" ] \
     && [ "$bodymark" -gt "$bodyopen" ] && [ "$bodymark" -lt "$skip" ]
  then ok "render hooks land in position (head-append inside <head>, body-open first in <body>)"
  else no "render hooks (charset=$charset headmark=$headmark headend=$headend body=$bodyopen bodymark=$bodymark skip=$skip)"; fi
else
  no "render hooks: the fixture did not build"
fi

# The other direction, which protects every site that does not want them:
# unoverridden, the hooks must contribute nothing. An empty partial that
# emitted so much as a newline would change every page the theme renders, and
# the skip link must stay the first thing inside <body>.
if [ -d "$PUB" ]; then
  stray=$(grep -rl 'headmark\|bodymark' "$PUB" --include='*.html' 2>/dev/null | wc -l)
  first=$(python3 - "$PUB/index.html" <<'PY'
import sys
d = open(sys.argv[1]).read()
i = d.find('<body>') + len('<body>')
print(1 if d[i:i+40].lstrip().startswith('<a class="skip"') else 0)
PY
)
  if [ "$stray" -eq 0 ] && [ "$first" -eq 1 ]
  then ok "the hooks are inert unless a site overrides them"
  else no "hooks inert (markers=$stray skip-link-first=$first)"; fi
else
  no "hooks inert: the example site build is missing"
fi

echo
printf "  %d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
