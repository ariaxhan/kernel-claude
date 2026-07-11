#!/usr/bin/env python3
"""Crash-safe, repo-contained file transactions for governance adapters."""

import base64
from contextlib import contextmanager
import json
import os
from pathlib import Path
import tempfile
import time
import uuid

LOCK_NAME = ".kernel-governance.lock"
JOURNAL_NAME = ".kernel-governance.transaction.json"


class TransactionError(RuntimeError):
    pass


def _fsync_dir(path):
    try:
        fd = os.open(path, os.O_RDONLY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)
    except OSError:
        pass


def _contained(root, path):
    try:
        path.relative_to(root)
    except ValueError as exc:
        raise TransactionError(f"transaction target escapes repository: {path}") from exc


def _validate_ancestors(root, path):
    _contained(root, path)
    cursor = root
    if cursor.is_symlink() or not cursor.is_dir():
        raise TransactionError(f"repository root must be a real directory: {root}")
    for part in path.relative_to(root).parts[:-1]:
        cursor = cursor / part
        if cursor.exists() or cursor.is_symlink():
            if cursor.is_symlink() or not cursor.is_dir():
                raise TransactionError(f"write ancestor must be a real directory: {cursor}")


def _validate_existing_file(path, label):
    if path.is_symlink() or (path.exists() and not path.is_file()):
        raise TransactionError(f"{label} must be a regular non-symlink file: {path}")
    if path.is_file() and path.stat(follow_symlinks=False).st_nlink != 1:
        raise TransactionError(f"{label} must not be hardlinked: {path}")


def _pid_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def _read_lock(lock):
    _validate_existing_file(lock, "governance lock")
    try:
        data = json.loads(lock.read_text())
        return int(data["pid"]), str(data["identity"])
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        if time.time() - lock.stat().st_mtime < 30:
            raise TransactionError(f"active or malformed governance lock: {lock}") from exc
        return -1, "malformed-stale"


def _acquire(root, timeout=3.0):
    lock = root / LOCK_NAME
    _validate_ancestors(root, lock)
    identity = uuid.uuid4().hex
    deadline = time.monotonic() + timeout
    payload = (json.dumps({"pid": os.getpid(), "identity": identity}) + "\n").encode()
    while True:
        try:
            flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
            if hasattr(os, "O_NOFOLLOW"):
                flags |= os.O_NOFOLLOW
            fd = os.open(lock, flags, 0o644)
            try:
                os.write(fd, payload)
                os.fsync(fd)
            finally:
                os.close(fd)
            _fsync_dir(root)
            return lock, identity
        except FileExistsError:
            pid, old_identity = _read_lock(lock)
            if not _pid_alive(pid):
                # Re-read identity before unlinking so a replaced live lock is untouched.
                current_pid, current_identity = _read_lock(lock)
                if (current_pid, current_identity) == (pid, old_identity):
                    lock.unlink()
                    _fsync_dir(root)
                    continue
            if time.monotonic() >= deadline:
                raise TransactionError("governance lock busy; bounded wait expired")
            time.sleep(0.05)


def _release(lock, identity):
    if not lock.exists():
        return
    _validate_existing_file(lock, "governance lock")
    try:
        data = json.loads(lock.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise TransactionError(f"cannot safely release governance lock: {exc}") from exc
    if data.get("identity") != identity or data.get("pid") != os.getpid():
        raise TransactionError("governance lock ownership changed")
    lock.unlink()
    _fsync_dir(lock.parent)


def _mode_for(path, original_mode):
    if original_mode is not None:
        return original_mode
    return 0o755 if path.suffix == ".sh" else 0o644


def _stage(path, content, mode, prefix):
    handle = tempfile.NamedTemporaryFile("wb", dir=path.parent, prefix=prefix, delete=False)
    try:
        handle.write(content)
        handle.flush()
        os.fchmod(handle.fileno(), mode)
        os.fsync(handle.fileno())
    finally:
        handle.close()
    return Path(handle.name)


def _write_journal(root, journal):
    path = root / JOURNAL_NAME
    _validate_existing_file(path, "transaction journal")
    if path.exists():
        raise TransactionError("unrecovered transaction journal already exists")
    payload = (json.dumps(journal, sort_keys=True) + "\n").encode()
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    fd = os.open(path, flags, 0o644)
    try:
        os.write(fd, payload)
        os.fsync(fd)
    finally:
        os.close(fd)
    _fsync_dir(root)


def recover(root):
    journal_path = root / JOURNAL_NAME
    _validate_existing_file(journal_path, "transaction journal")
    if not journal_path.exists():
        return False
    try:
        journal = json.loads(journal_path.read_text())
        if journal.get("schema") != "kernel.governance-transaction/v1":
            raise ValueError("bad journal schema")
        entries = journal["entries"]
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        raise TransactionError(f"invalid recovery journal: {exc}") from exc
    for entry in reversed(entries):
        target = root / entry["target"]
        stage = root / entry["stage"]
        _validate_ancestors(root, target)
        _validate_ancestors(root, stage)
        _validate_existing_file(target, "recovery target")
        if entry["existed"]:
            content = base64.b64decode(entry["original_b64"], validate=True)
            rollback = _stage(target, content, int(entry["mode"]), f".{target.name}.recover.")
            os.replace(rollback, target)
            _fsync_dir(target.parent)
        else:
            target.unlink(missing_ok=True)
            _fsync_dir(target.parent)
        stage.unlink(missing_ok=True)
    journal_path.unlink()
    _fsync_dir(root)
    return True


@contextmanager
def locked_root(root):
    root = Path(root).absolute()
    if root.is_symlink() or not root.is_dir():
        raise TransactionError(f"repository root must be a real directory: {root}")
    root = root.resolve()
    lock, identity = _acquire(root)
    try:
        recover(root)
        hold = os.environ.get("KERNEL_TEST_HOLD_LOCK_MS", "0")
        try:
            hold_ms = int(hold)
        except ValueError as exc:
            raise TransactionError("invalid KERNEL_TEST_HOLD_LOCK_MS") from exc
        if hold_ms < 0 or hold_ms > 5000:
            raise TransactionError("KERNEL_TEST_HOLD_LOCK_MS out of range")
        if hold_ms:
            time.sleep(hold_ms / 1000)
        yield root
    finally:
        _release(lock, identity)


def transactional_write(root, writes):
    """Apply repo-contained writes. Caller must hold locked_root(root)."""
    root = Path(root).resolve()
    if len(writes) != len(set(writes)):
        raise TransactionError("transaction contains duplicate targets")
    fail_raw = os.environ.get("KERNEL_TEST_FAIL_AFTER_REPLACE", "0")
    hard_raw = os.environ.get("KERNEL_TEST_HARD_KILL_AFTER_REPLACE", "0")
    try:
        fail_after, hard_after = int(fail_raw), int(hard_raw)
    except ValueError as exc:
        raise TransactionError("invalid transaction failure injection value") from exc
    if fail_after < 0 or hard_after < 0:
        raise TransactionError("transaction failure injection must be non-negative")
    created_dirs = []
    staged = {}
    entries = []
    identity = uuid.uuid4().hex
    try:
        for path in writes:
            path = Path(path).absolute()
            _validate_ancestors(root, path)
            _validate_existing_file(path, "transaction target")
        for path in writes:
            missing = []
            cursor = path.parent
            while not cursor.exists():
                missing.append(cursor)
                cursor = cursor.parent
            for directory in reversed(missing):
                directory.mkdir(mode=0o755)
                created_dirs.append(directory)
                _fsync_dir(directory.parent)
        for path, content in writes.items():
            existed = path.is_file()
            original = path.read_bytes() if existed else b""
            original_mode = path.stat().st_mode & 0o777 if existed else None
            mode = _mode_for(path, original_mode)
            stage = _stage(path, content, mode, f".{path.name}.stage.{identity}.")
            staged[path] = stage
            entries.append({
                "target": path.relative_to(root).as_posix(),
                "stage": stage.relative_to(root).as_posix(),
                "existed": existed,
                "mode": mode,
                "original_b64": base64.b64encode(original).decode(),
            })
        journal = {"schema": "kernel.governance-transaction/v1", "identity": identity,
                   "pid": os.getpid(), "entries": entries}
        _write_journal(root, journal)
        replaced = 0
        for path, stage in staged.items():
            os.replace(stage, path)
            replaced += 1
            _fsync_dir(path.parent)
            if hard_after and replaced == hard_after:
                os._exit(97)
            if fail_after and replaced == fail_after:
                raise OSError(f"injected failure after replace {fail_after}")
        (root / JOURNAL_NAME).unlink()
        _fsync_dir(root)
    except BaseException:
        if (root / JOURNAL_NAME).exists():
            recover(root)
        else:
            for stage in staged.values():
                stage.unlink(missing_ok=True)
            for directory in reversed(created_dirs):
                try:
                    directory.rmdir()
                except OSError:
                    pass
        raise
