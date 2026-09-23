#!/usr/bin/env python3
"""Rebuild the code tree of this repository from the lab's working folders.

The lab's analysis code lives in Dropbox (Projects/Sensorimotor and the shared
"Analysis Suite") and is still being edited. This script copies the files listed
in tools/manifest.csv into the repository and applies two kinds of edits to the
copies only -- source files are never written:

  1. Hard-coded lab paths are rewritten. Any string literal that starts with the
     Sensorimotor project folder (under any of the drive/Dropbox spellings used on
     lab machines) becomes  [smroot() '<rest>'] , and addpath() calls that point at
     lab folders are commented out (startup_sm.m puts all repository code on the path).
  2. Hand-written patches from tools/patches.py (cwd-relative loads, output folders).
     Every patch must match; a patch that no longer matches means the source changed
     and stops the build.

It also writes tools/SOURCE_LOCK.csv with the md5 of every source file so later
changes in the lab folders can be detected:

    python tools/build_repo.py            # rebuild code/ and python/
    python tools/build_repo.py --check    # report sources changed since the last build
"""
import argparse, csv, hashlib, os, re, sys, time

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOLS = os.path.join(REPO, 'tools')
sys.path.insert(0, TOOLS)
from patches import PATCHES  # noqa: E402

TEAM_ROOTS = [
    r"Z:\Dropbox\Chen Lab Dropbox\Chen Lab Team Folder",
    "/net/claustrum/mnt/data/Dropbox/Chen Lab Dropbox/Chen Lab Team Folder",
]
# every spelling of the team folder seen in the lab code
TEAM_RE = (r"(?:[A-Z]:(?:\\{1,2}|/)Dropbox(?:\\{1,2}|/)(?:Chen Lab Dropbox|Dropbox)(?:\\{1,2}|/)"
           r"|/net/claustrum/mnt/data/Dropbox/Chen Lab Dropbox/)Chen Lab Team Folder(?:\\{1,2}|/)")
SEP = r"(?:\\{1,2}|/)"
# 'single' or "double" quoted literal starting at the Sensorimotor project folder
SM_LITERAL = re.compile(r"(['\"])" + TEAM_RE + r"Projects" + SEP + r"Sensorimotor(?:" + SEP + r"([^'\"]*))?\1")
TEAM_LITERAL = re.compile(r"['\"]" + TEAM_RE)
ABS_ADDPATH = re.compile(r"""^(addpath|add_chen_path|rmpath)\s*\(\s*(genpath\s*\(\s*)?['"]([A-Za-z]:\\|/net/)""")
# figure exports aimed at the manuscript/figure folders go to results/figures instead
FIG_OUT = re.compile(r"^(?:Manuscript/(?:[^/]+/)*Figures|Figures)/(.*)$")
MARK = '% [release] '
# credentials and personal details that must never be published; redacted in every copied file
SECRETS = [(re.compile(r"https://hooks\.slack\.com/services/[A-Za-z0-9/_+-]+"), "REDACTED_SLACK_WEBHOOK"),
           (re.compile(r"xox[baprs]-[A-Za-z0-9-]+"), "REDACTED_SLACK_TOKEN"),
           # personal home directories on the BU cluster, e.g. /usr2/postdoc/<username>/
           (re.compile(r"/usr\d+/(?:postdoc|ugrad|grad|faculty|staff)/[A-Za-z0-9_.-]+"), "/usr/<user>")]


def md5(path):
    h = hashlib.md5()
    with open(path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def find_source(rel):
    for root in TEAM_ROOTS:
        p = os.path.join(root, *re.split(r'[\\/]', rel))
        if os.path.exists(p):
            return p
    return None


def read_text(path):
    raw = open(path, 'rb').read()
    for enc in ('utf-8', 'cp1252', 'latin-1'):
        try:
            return raw.decode(enc), enc
        except UnicodeDecodeError:
            pass


def rewrite_paths(text, repo_path, warnings):
    out = []
    for n, line in enumerate(text.split('\n'), 1):
        code = line.lstrip()
        if code.startswith('%'):
            out.append(line)
            continue
        if ABS_ADDPATH.match(code):
            indent = line[:len(line) - len(code)]
            out.append(f"{indent}{MARK}path handled by startup_sm.m: {code}")
            continue
        if not TEAM_LITERAL.search(line):
            out.append(line)
            continue

        def repl(m):
            q, tail = m.group(1), re.sub(r'\\{1,2}', '/', m.group(2) or '')
            fig = FIG_OUT.match(tail)
            if fig:  # output figure: results/figures/<subdir>/<file>
                sub, _, name = fig.group(1).rpartition('/')
                base, tail = f"smout('figures{('/' + sub) if sub else ''}')", name
            else:
                base = "smroot()"
            if not tail:
                return base
            # char literal -> [char char]; string literal -> string + string ([char "str"] would be a 1x2 string array)
            return f"[{base} '{tail}']" if q == "'" else f'(string({base}) + "{tail}")'
        new = SM_LITERAL.sub(repl, line)
        if TEAM_LITERAL.search(new):
            warnings.append(f"{repo_path}:{n}: unresolved lab path: {line.strip()[:140]}")
        out.append(new)
    return '\n'.join(out)


def redact_secrets(text, repo_path, warnings):
    for pattern, placeholder in SECRETS:
        text, n = pattern.subn(placeholder, text)
        if n:
            warnings.append(f"{repo_path}: redacted {n} secret(s) -> {placeholder}")
    return text


def apply_patches(text, repo_path, errors):
    for p in PATCHES.get(repo_path, []):
        find, repl, count = p['find'], p['replace'], p.get('count', 1)
        found = text.count(find)
        if found != count:
            errors.append(f"{repo_path}: patch expected {count} match(es), found {found}: {find[:90]!r}")
            continue
        text = text.replace(find, repl)
    return text


def load_manifest():
    with open(os.path.join(TOOLS, 'manifest.csv'), newline='') as fh:
        return [(r['source_rel_to_team_folder'], r['repo_path']) for r in csv.DictReader(fh)]


def build():
    rows, lock, warnings, errors = load_manifest(), [], [], []
    # startup_sm.m puts every code folder on the path, so function names must be unique
    names = [os.path.basename(d) for _, d in rows if d.endswith('.m')]
    errors += [f"duplicate function name in repo: {n}" for n in sorted({n for n in names if names.count(n) > 1})]
    for rel, dst in rows:
        src = find_source(rel)
        if not src:
            errors.append(f"missing source: {rel}")
            continue
        out = os.path.normpath(os.path.join(REPO, dst))
        assert out.startswith(REPO + os.sep), f"destination escapes repo: {dst}"
        os.makedirs(os.path.dirname(out), exist_ok=True)
        if dst.endswith('.m'):
            text, enc = read_text(src)
            text = text.replace('\r\n', '\n')
            text = rewrite_paths(text, dst, warnings)
            text = redact_secrets(text, dst, warnings)
            text = apply_patches(text, dst, errors)
            with open(out, 'w', encoding='utf-8', newline='\n') as fh:
                fh.write(text)
        else:
            with open(src, 'rb') as a, open(out, 'wb') as b:
                b.write(a.read())
        st = os.stat(src)
        lock.append([dst, rel, md5(src), time.strftime('%Y-%m-%d %H:%M', time.localtime(st.st_mtime)), md5(out)])

    unused = set(PATCHES) - {d for _, d in rows}
    errors += [f"patch target not in manifest: {u}" for u in sorted(unused)]

    with open(os.path.join(TOOLS, 'SOURCE_LOCK.csv'), 'w', newline='') as fh:
        w = csv.writer(fh)
        w.writerow(['repo_path', 'source_rel_to_team_folder', 'source_md5', 'source_modified', 'repo_md5'])
        w.writerows(sorted(lock))
    print(f"built {len(lock)} files into {REPO}")
    for w_ in warnings:
        print("WARN ", w_)
    for e in errors:
        print("ERROR", e)
    return 1 if errors else 0


def check():
    path = os.path.join(TOOLS, 'SOURCE_LOCK.csv')
    if not os.path.exists(path):
        sys.exit("no SOURCE_LOCK.csv yet; run a build first")
    changed = 0
    with open(path, newline='') as fh:
        for r in csv.DictReader(fh):
            src = find_source(r['source_rel_to_team_folder'])
            if not src:
                print(f"MISSING  {r['source_rel_to_team_folder']}")
                changed += 1
            elif md5(src) != r['source_md5']:
                print(f"CHANGED  {r['source_rel_to_team_folder']}  ->  {r['repo_path']}")
                changed += 1
    print(f"{changed} source file(s) changed since last build")
    return 1 if changed else 0


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--check', action='store_true', help='only report sources changed since the last build')
    sys.exit(check() if ap.parse_args().check else build())
