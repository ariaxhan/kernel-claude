#!/usr/bin/env python3
"""Project complexity gate: AST-aware JS/TS, budgets, skips, and baseline diffs."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import fnmatch
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass


JS_EXTS = {".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx", ".mts", ".cts"}
LIZARD_EXTS = JS_EXTS | {
    ".c", ".cc", ".cpp", ".cs", ".go", ".h", ".hpp", ".java", ".kt", ".kts",
    ".m", ".mm", ".php", ".py", ".rb", ".rs", ".scala", ".sh", ".swift",
}
EXCLUDED_PARTS = {
    ".git", ".next", ".svelte-kit", ".venv", ".wrangler", "build", "coverage",
    "dist", "graphify-out", "node_modules", "test-results", "vendor", "venv",
}
CONFIG_KEYS = {"version", "default", "budgets", "skip", "engine"}


class GateError(Exception):
    pass


class AnalyzerUnavailable(GateError):
    pass


@dataclass(frozen=True)
class Record:
    file: str
    line: int
    function: str
    ccn: int
    nloc: int

    @property
    def key(self) -> str:
        return f"{self.file}:{self.function}"


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, check=False)


def git_lines(repo: Path, args: list[str]) -> list[str]:
    proc = run(["git", *args], repo)
    if proc.returncode != 0:
        raise GateError(proc.stderr.strip() or f"git {' '.join(args)} failed")
    return [line for line in proc.stdout.splitlines() if line]


def is_source(rel: str) -> bool:
    path = Path(rel)
    return path.suffix.lower() in LIZARD_EXTS and not any(part in EXCLUDED_PARTS for part in path.parts)


def targets(repo: Path, base: str | None) -> list[str]:
    in_git = run(["git", "rev-parse", "--git-dir"], repo).returncode == 0
    if in_git:
        if base:
            bases = git_lines(repo, ["merge-base", base, "HEAD"])
            if not bases:
                raise GateError(f"no merge base with {base}")
            names = git_lines(repo, ["diff", "--name-only", "--diff-filter=d", bases[0]])
            names += git_lines(repo, ["ls-files", "--others", "--exclude-standard"])
        else:
            names = git_lines(repo, ["ls-files", "--cached", "--others", "--exclude-standard"])
        return sorted({name for name in names if is_source(name) and (repo / name).is_file()})

    found: list[str] = []
    for root, dirs, files in os.walk(repo):
        dirs[:] = [name for name in dirs if name not in EXCLUDED_PARTS]
        for name in files:
            path = Path(root, name)
            rel = path.relative_to(repo).as_posix()
            if is_source(rel):
                found.append(rel)
    return sorted(found)


def validate_budgets(path: Path, budgets: object) -> dict[str, int]:
    if not isinstance(budgets, dict):
        raise GateError(f"invalid config {path}: budgets must be an object")
    for selector, limit in budgets.items():
        valid_limit = isinstance(limit, int) and not isinstance(limit, bool) and limit >= 1
        if not isinstance(selector, str) or not selector or not valid_limit:
            raise GateError(f"invalid config {path}: every budget needs a selector and positive integer")
    return budgets


def validate_skips(path: Path, skips: object) -> dict[str, str]:
    if not isinstance(skips, dict):
        raise GateError(f"invalid config {path}: skip must be an object")
    for selector, reason in skips.items():
        valid_reason = isinstance(reason, str) and bool(reason.strip())
        if not isinstance(selector, str) or not selector or not valid_reason:
            raise GateError(f"invalid config {path}: every skip needs a selector and reason")
    return skips


def load_config(path: Path) -> dict:
    if not path.exists():
        return {"version": 1, "default": 15, "budgets": {}, "skip": {}, "engine": "auto"}
    try:
        value = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise GateError(f"invalid config {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise GateError(f"invalid config {path}: root must be an object")
    unknown = sorted(set(value) - CONFIG_KEYS)
    if unknown:
        raise GateError(f"invalid config {path}: unknown keys: {', '.join(unknown)}")
    if value.get("version", 1) != 1:
        raise GateError(f"invalid config {path}: version must be 1")
    default = value.get("default", 15)
    if not isinstance(default, int) or isinstance(default, bool) or default < 1:
        raise GateError(f"invalid config {path}: default must be a positive integer")
    budgets = validate_budgets(path, value.get("budgets", {}))
    skips = validate_skips(path, value.get("skip", {}))
    engine = value.get("engine", "auto")
    if engine not in {"auto", "eslint", "lizard"}:
        raise GateError(f"invalid config {path}: engine must be auto, eslint, or lizard")
    return {"version": 1, "default": default, "budgets": budgets, "skip": skips, "engine": engine}


def eslint_binary(repo: Path) -> str | None:
    local = repo / "node_modules" / ".bin" / "eslint"
    if local.is_file() and os.access(local, os.X_OK):
        return str(local)
    return shutil.which("eslint")


def has_eslint_config(repo: Path) -> bool:
    names = ("eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts",
             ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", ".eslintrc.yaml")
    return any((repo / name).exists() for name in names)


def arrow_name(repo: Path, rel: str, line: int) -> str:
    try:
        source = (repo / rel).read_text().splitlines()[line - 1]
    except (OSError, IndexError, UnicodeDecodeError):
        return f"(anonymous@{line})"
    match = re.search(r"(?:export\s+)?(?:const|let|var)\s+([A-Za-z_$][\w$]*)\b.*=>", source)
    if match:
        return match.group(1)
    match = re.search(r"\b([A-Za-z_$][\w$]*)\s*:\s*(?:async\s*)?(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>", source)
    return match.group(1) if match else f"(anonymous@{line})"


def eslint_name(repo: Path, rel: str, line: int, message: str) -> str:
    match = re.search(r"(?:function|method) '([^']+)' has a complexity", message, re.IGNORECASE)
    if match:
        return match.group(1)
    return arrow_name(repo, rel, line)


def analyze_eslint(repo: Path, files: list[str], binary: str) -> list[Record]:
    records: list[Record] = []
    for start in range(0, len(files), 100):
        batch = files[start:start + 100]
        proc = run([binary, *batch, "--rule", "complexity: [error, 0]", "--format", "json"], repo)
        if proc.returncode not in {0, 1}:
            raise GateError(f"eslint analysis failed: {proc.stderr.strip() or proc.stdout.strip()}")
        try:
            reports = json.loads(proc.stdout or "[]")
        except json.JSONDecodeError as exc:
            raise GateError(f"eslint returned invalid JSON: {exc}") from exc
        for report in reports:
            try:
                rel = Path(report["filePath"]).resolve().relative_to(repo).as_posix()
            except (KeyError, ValueError) as exc:
                raise GateError("eslint returned a file outside the repository") from exc
            for message in report.get("messages", []):
                if message.get("fatal"):
                    detail = message.get("message", "fatal parser error")
                    raise GateError(f"eslint could not parse {rel}:{message.get('line', 0)}: {detail}")
                if message.get("ruleId") != "complexity":
                    continue
                found = re.search(r"complexity of (\d+)", message.get("message", ""))
                if not found:
                    raise GateError(f"eslint complexity output changed: {message.get('message', '')}")
                line = int(message.get("line", 0))
                name = eslint_name(repo, rel, line, message["message"])
                records.append(Record(rel, line, name, int(found.group(1)), 0))
    return records


LIZARD_LINE = re.compile(r"^(.*?):(\d+): warning: (.+) has (\d+) NLOC, (\d+) CCN.*$")


def lizard_command() -> list[str] | None:
    if shutil.which("lizard"):
        return ["lizard"]
    if shutil.which("uvx"):
        return ["uvx", "--quiet", "lizard"]
    return None


def analyze_lizard(repo: Path, files: list[str], command: list[str]) -> list[Record]:
    if not files:
        return []
    proc = run([*command, "-w", "-C", "0", *files], repo)
    if proc.returncode not in {0, 1}:
        raise GateError(f"lizard analysis failed: {proc.stderr.strip() or proc.stdout.strip()}")
    records: list[Record] = []
    for line in proc.stdout.splitlines():
        match = LIZARD_LINE.match(line.removeprefix("./"))
        if not match:
            continue
        rel, lineno, name, nloc, ccn = match.groups()
        records.append(Record(rel, int(lineno), name, int(ccn), int(nloc)))
    return records


def matches(selector: str, record: Record) -> bool:
    return fnmatch.fnmatchcase(record.key, selector)


def selected_limit(record: Record, config: dict) -> int:
    if record.key in config["budgets"]:
        return config["budgets"][record.key]
    for selector, limit in config["budgets"].items():
        if matches(selector, record):
            return limit
    return config["default"]


def skipped(record: Record, config: dict) -> tuple[str, str] | None:
    for selector, reason in config["skip"].items():
        if matches(selector, record):
            return selector, reason
    return None


def emit_record(record: Record) -> None:
    print(f"{record.file}\t{record.line}\t{record.function}\t{record.ccn}\t{record.nloc}")


def read_baseline(path: Path) -> list[Record]:
    records: list[Record] = []
    try:
        lines = path.read_text().splitlines()
    except OSError as exc:
        raise GateError(f"cannot read baseline {path}: {exc}") from exc
    for number, line in enumerate(lines, 1):
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) != 5:
            raise GateError(f"invalid baseline {path}:{number}: expected 5 TSV fields")
        try:
            records.append(Record(fields[0], int(fields[1]), fields[2], int(fields[3]), int(fields[4])))
        except ValueError as exc:
            raise GateError(f"invalid baseline {path}:{number}: numeric field required") from exc
    return records


def records_by_key(records: list[Record]) -> dict[str, list[Record]]:
    grouped: dict[str, list[Record]] = defaultdict(list)
    for record in records:
        grouped[record.key].append(record)
    for values in grouped.values():
        values.sort(key=lambda record: record.line)
    return grouped


def emit_existing_diffs(
    before: list[Record], after_by_key: dict[str, list[Record]], config: dict, counts: dict
) -> None:
    occurrence: Counter[str] = Counter()
    for old in sorted(before, key=lambda record: (record.file, record.line, record.function)):
        candidates = after_by_key.get(old.key, [])
        index = occurrence[old.key]
        occurrence[old.key] += 1
        new = candidates[index] if index < len(candidates) else None
        if new is None:
            counts["removed"] += 1
            print(f"{old.file}\t{old.line}\t{old.function}\t{old.ccn}\t-\t-\tremoved")
            continue
        status = "reduced" if new.ccn < old.ccn else "regressed" if new.ccn > old.ccn else "unchanged"
        counts[status] += 1
        print(
            f"{new.file}\t{new.line}\t{new.function}\t{old.ccn}\t{new.ccn}\t"
            f"{selected_limit(new, config)}\t{status}"
        )


def emit_added_violations(current: list[Record], before_counts: Counter[str], config: dict, counts: dict) -> None:
    occurrence: Counter[str] = Counter()
    for record in sorted(current, key=lambda value: (value.file, value.line, value.function)):
        index = occurrence[record.key]
        occurrence[record.key] += 1
        if index >= before_counts[record.key] and record.ccn > selected_limit(record, config):
            counts["added"] += 1
            print(
                f"{record.file}\t{record.line}\t{record.function}\t-\t{record.ccn}\t"
                f"{selected_limit(record, config)}\tadded"
            )


def emit_diff(before: list[Record], current: list[Record], config: dict, baseline_gate: bool = False) -> int:
    counts = {"reduced": 0, "unchanged": 0, "regressed": 0, "removed": 0, "added": 0}
    print("file\tline\tfunction\tbefore\tafter\tbudget\tstatus")
    emit_existing_diffs(before, records_by_key(current), config, counts)
    if baseline_gate:
        emit_added_violations(current, Counter(record.key for record in before), config, counts)
    diff_fields = ("reduced", "unchanged", "regressed", "removed")
    fields = (*diff_fields, "added") if baseline_gate else diff_fields
    print("SUMMARY\t" + "\t".join(f"{key}={counts[key]}" for key in fields))
    if baseline_gate:
        return 1 if any(counts[key] for key in ("reduced", "regressed", "removed", "added")) else 0
    over_budget = any(record.ccn > selected_limit(record, config) for record in current)
    return 1 if counts["regressed"] or over_budget else 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="complexity.sh",
        description="Cyclomatic complexity gate. TSV: file, line, function, CCN, NLOC.",
    )
    parser.add_argument("--all", action="store_true", help="emit every measured function for a baseline")
    parser.add_argument("--config", help="config path; default <repo>/.ccnrc")
    parser.add_argument("--diff", metavar="BASELINE_TSV", help="emit before/current regression diff")
    parser.add_argument(
        "--check-baseline",
        metavar="BASELINE_TSV",
        help="CI ratchet: fail changed or new over-budget functions",
    )
    parser.add_argument("--engine", choices=("auto", "eslint", "lizard"))
    parser.add_argument("--skip", action="append", default=[], metavar="SELECTOR=REASON")
    parser.add_argument("repo")
    parser.add_argument("base_ref", nargs="?")
    return parser.parse_args()


def apply_limit_override(config: dict) -> None:
    if "CCN_MAX" in os.environ:
        try:
            env_limit = int(os.environ["CCN_MAX"])
        except ValueError as exc:
            raise GateError("CCN_MAX must be a positive integer") from exc
        if env_limit < 1:
            raise GateError("CCN_MAX must be a positive integer")
        config["default"] = env_limit


def apply_cli_overrides(config: dict, args: argparse.Namespace) -> None:
    if args.engine:
        config["engine"] = args.engine
    for item in args.skip:
        if "=" not in item:
            raise GateError("--skip requires SELECTOR=REASON")
        selector, reason = item.split("=", 1)
        if not selector or not reason.strip():
            raise GateError("--skip requires a non-empty selector and reason")
        config["skip"][selector] = reason.strip()


def collect_records(repo: Path, files: list[str], engine: str) -> list[Record]:
    js_files = [name for name in files if Path(name).suffix.lower() in JS_EXTS]
    other_files = [name for name in files if name not in js_files]
    eslint = eslint_binary(repo)
    use_eslint = engine != "lizard" and bool(js_files) and bool(eslint) and has_eslint_config(repo)
    if engine == "eslint" and not use_eslint:
        raise GateError("eslint engine requested, but an executable and project config were not found")

    records: list[Record] = []
    if use_eslint:
        print("complexity engine: eslint AST for JS/TS", file=sys.stderr)
        records.extend(analyze_eslint(repo, js_files, eslint or "eslint"))
    else:
        other_files += js_files
        if js_files:
            print(
                "complexity engine: lizard fallback for JS/TS; object-literal methods are not visible",
                file=sys.stderr,
            )

    lizard = lizard_command()
    if other_files:
        if not lizard:
            raise AnalyzerUnavailable("no analyzer: install lizard/uvx, or project ESLint for JS/TS")
        records.extend(analyze_lizard(repo, other_files, lizard))
    return records


def apply_skips(records: list[Record], config: dict) -> list[Record]:
    kept: list[Record] = []
    announced: set[tuple[str, str]] = set()
    for record in records:
        skip = skipped(record, config)
        if not skip:
            kept.append(record)
        elif skip not in announced:
            print(f"complexity skip: {skip[0]} ({skip[1]})", file=sys.stderr)
            announced.add(skip)
    return kept


def main() -> int:
    args = parse_args()
    if args.diff and args.check_baseline:
        raise GateError("choose --diff or --check-baseline, not both")
    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        raise GateError(f"repo is not a directory: {repo}")
    config_path = Path(args.config).resolve() if args.config else repo / ".ccnrc"
    config = load_config(config_path)
    apply_limit_override(config)
    apply_cli_overrides(config, args)

    files = targets(repo, args.base_ref)
    if not files:
        return 0
    kept = apply_skips(collect_records(repo, files, config["engine"]), config)

    if args.diff:
        return emit_diff(read_baseline(Path(args.diff)), kept, config)
    if args.check_baseline:
        return emit_diff(read_baseline(Path(args.check_baseline)), kept, config, baseline_gate=True)
    if args.all:
        for record in sorted(kept, key=lambda value: (value.file, value.line, value.function)):
            emit_record(record)
        return 0

    hotspots = [record for record in kept if record.ccn > selected_limit(record, config)]
    for record in sorted(hotspots, key=lambda value: (-value.ccn, value.file, value.line)):
        emit_record(record)
    return 1 if hotspots else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AnalyzerUnavailable as exc:
        print(f"complexity SKIPPED: {exc}", file=sys.stderr)
        raise SystemExit(3)
    except GateError as exc:
        print(f"complexity ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2)
