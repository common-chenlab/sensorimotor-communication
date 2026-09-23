#!/usr/bin/env python3
"""Release gate: check what a repository would publish before it goes public.

    python tools/check_public.py              # the code repository (GitHub)
    python tools/check_public.py data         # the analysis-data repository (GIN)
    python tools/check_public.py data/Animals # the sessions repository (GIN)

Lists the files that would be committed (everything not excluded by that folder's
.gitignore) and reports, per file:

  BLOCK  internal documents present, credentials or personal paths, files over GitHub's
         100 MB limit (code repository only), links to internal documents, and unresolved
         TODO / (check) / (decide) / (confirm) markers in documentation or metadata
  WARN   files over 50 MB in the code repository, email addresses (author credits in code
         headers are normal, but each should be a deliberate choice)

Exits 1 if anything blocks. Read-only.
"""
import fnmatch, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, 'tools'))
from build_repo import SECRETS  # noqa: E402  same patterns the build redacts

INTERNAL_DOCS = {'CLAUDE.md', 'OPEN_ISSUES.md', 'SESSION_HANDOFF.md', 'REVISION_PLAN.md'}
INTERNAL_REF = re.compile(r"OPEN_ISSUES\.md|CLAUDE\.md|SESSION_HANDOFF|REVISION_PLAN")
MARKERS = re.compile(r"\bTODO\b|\((?:check|decide|confirm)\)|\*\*(?:check|decide|confirm)\*\*|to confirm",
                     re.IGNORECASE)
EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
TEXT = ('.m', '.py', '.sh', '.md', '.cff', '.yml', '.yaml', '.csv', '.txt', '.json')
DOC = ('.md', '.cff', '.yml', '.yaml')


def ignore_rules(root):
    path = os.path.join(root, '.gitignore')
    if not os.path.exists(path):
        return []
    rules = []
    for line in open(path, encoding='utf-8'):
        line = line.strip()
        if line and not line.startswith('#'):
            rules.append(line)
    return rules


def ignored(rel, rules):
    rel = rel.replace('\\', '/')
    name = rel.rsplit('/', 1)[-1]
    for r in rules:
        if r.endswith('/'):
            d = r.rstrip('/')
            if rel == d or rel.startswith(d + '/') or f'/{d}/' in f'/{rel}':
                return True
        elif '/' in r:
            if fnmatch.fnmatch(rel, r.lstrip('/')):
                return True
        elif fnmatch.fnmatch(name, r):
            return True
    return False


def published_files(root):
    rules = ignore_rules(root)
    out = []
    for dp, dns, fns in os.walk(root):
        dns[:] = [d for d in dns if d != '.git']
        for f in fns:
            rel = os.path.relpath(os.path.join(dp, f), root).replace('\\', '/')
            if not ignored(rel, rules):
                out.append(rel)
    return sorted(out)


def main(target):
    root = os.path.normpath(os.path.join(REPO, target)) if target else REPO
    is_code = os.path.normcase(root) == os.path.normcase(REPO)
    files = published_files(root)
    block, warn = [], []
    for rel in files:
        path = os.path.join(root, rel)
        name = rel.rsplit('/', 1)[-1]
        size = os.path.getsize(path)
        if name in INTERNAL_DOCS:
            block.append((rel, 'internal document would be published'))
        if is_code and size > 100e6:
            block.append((rel, f'{size/1e6:.0f} MB, over GitHub\'s 100 MB limit'))
        elif is_code and size > 50e6:
            warn.append((rel, f'{size/1e6:.0f} MB, over GitHub\'s 50 MB warning size'))
        if not rel.lower().endswith(TEXT) or size > 5e6:
            continue
        text = open(path, encoding='utf-8', errors='replace').read()
        for pattern, label in SECRETS:
            for m in pattern.finditer(text):
                block.append((rel, f'credential or personal path: {m.group(0)[:60]}'))
        if rel != 'tools/check_public.py':
            for n, line in enumerate(text.splitlines(), 1):
                if INTERNAL_REF.search(line):
                    block.append((f'{rel}:{n}', 'links to an internal document'))
                if rel.lower().endswith(DOC) and MARKERS.search(line):
                    block.append((f'{rel}:{n}', 'unresolved marker: ' + line.strip()[:70]))
        for e in sorted(set(EMAIL.findall(text))):
            warn.append((rel, f'email address: {e}'))

    print(f"{root}\n{len(files)} files would be published "
          f"({sum(os.path.getsize(os.path.join(root, f)) for f in files)/1e6:.1f} MB)\n")
    for tag, rows in (('BLOCK', block), ('WARN ', warn)):
        for where, why in rows:
            print(f"{tag}  {where}  {why}")
    print(f"\n{len(block)} blocking, {len(warn)} warnings")
    return 1 if block else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else ''))
