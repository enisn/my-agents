#!/usr/bin/env python3
# pyright: reportMissingImports=false

import json
import os
import re
import sys
import time
from collections import deque
from pathlib import Path
from typing import Any

try:
    from mcp.server.fastmcp import FastMCP
except ImportError:
    print("Error: mcp not installed. Install with: pip install mcp", file=sys.stderr)
    sys.exit(1)

try:
    from PIL import ImageGrab
except ImportError:
    print(
        "Error: Pillow not installed. Install with: pip install pillow", file=sys.stderr
    )
    sys.exit(1)

try:
    from pywinauto import Application, Desktop
    from pywinauto.keyboard import send_keys
except ImportError:
    print(
        "Error: pywinauto not installed. Install with: pip install pywinauto",
        file=sys.stderr,
    )
    sys.exit(1)


mcp = FastMCP("windows-desktop-mcp")

BASE_DIR = Path(__file__).resolve().parent
CAPTURE_DIR = Path(
    os.getenv("WINDOWS_DESKTOP_MCP_CAPTURE_DIR", str(BASE_DIR / "captures"))
)
SUPPORTED_BACKENDS = {"uia", "win32"}
SUPPORTED_BUTTONS = {"left", "right", "middle"}


def ok(**data: Any) -> str:
    return json.dumps({"success": True, **data}, indent=2)


def fail(message: str, **data: Any) -> str:
    return json.dumps({"success": False, "error": message, **data}, indent=2)


def validate_backend(backend: str) -> str:
    value = (backend or "uia").lower()
    if value not in SUPPORTED_BACKENDS:
        raise ValueError(
            f"Unsupported backend '{backend}'. Use one of: {', '.join(sorted(SUPPORTED_BACKENDS))}"
        )
    return value


def parse_path(path: str) -> list[int]:
    if not path:
        return []

    indices: list[int] = []
    for segment in path.split("/"):
        if segment == "":
            continue
        if not segment.isdigit():
            raise ValueError(
                f"Invalid path '{path}'. Use slash-separated child indexes like '0/2/1'."
            )
        indices.append(int(segment))
    return indices


def join_path(path: str, index: int) -> str:
    return f"{path}/{index}" if path else str(index)


def maybe_call(func: Any, default: Any = None) -> Any:
    try:
        return func()
    except Exception:
        return default


def maybe_attr(obj: Any, name: str, default: Any = None) -> Any:
    try:
        return getattr(obj, name)
    except Exception:
        return default


def rect_to_dict(rect: Any) -> dict[str, int] | None:
    if rect is None:
        return None
    return {
        "left": int(rect.left),
        "top": int(rect.top),
        "right": int(rect.right),
        "bottom": int(rect.bottom),
        "width": int(rect.right - rect.left),
        "height": int(rect.bottom - rect.top),
    }


def window_text(wrapper: Any) -> str:
    return maybe_call(wrapper.window_text, "") or ""


def wrapper_handle(wrapper: Any) -> int:
    handle = maybe_attr(wrapper, "handle")
    if handle is None:
        handle = maybe_attr(maybe_attr(wrapper, "element_info"), "handle", 0)
    return int(handle or 0)


def wrapper_process_id(wrapper: Any) -> int | None:
    value = maybe_call(wrapper.process_id, None)
    if value is None:
        value = maybe_attr(maybe_attr(wrapper, "element_info"), "process_id", None)
    return int(value) if value is not None else None


def wrapper_class_name(wrapper: Any) -> str:
    info = maybe_attr(wrapper, "element_info")
    value = maybe_attr(info, "class_name", None)
    if not value:
        value = maybe_call(wrapper.class_name, "")
    return value or ""


def wrapper_control_type(wrapper: Any) -> str:
    info = maybe_attr(wrapper, "element_info")
    value = maybe_attr(info, "control_type", None)
    if not value:
        value = maybe_call(wrapper.friendly_class_name, "")
    return value or ""


def wrapper_automation_id(wrapper: Any) -> str:
    info = maybe_attr(wrapper, "element_info")
    return maybe_attr(info, "automation_id", "") or ""


def wrapper_summary(wrapper: Any, root_hwnd: int, path: str) -> dict[str, Any]:
    return {
        "root_hwnd": int(root_hwnd),
        "path": path,
        "handle": wrapper_handle(wrapper),
        "title": window_text(wrapper),
        "class_name": wrapper_class_name(wrapper),
        "control_type": wrapper_control_type(wrapper),
        "automation_id": wrapper_automation_id(wrapper),
        "process_id": wrapper_process_id(wrapper),
        "visible": maybe_call(wrapper.is_visible, None),
        "enabled": maybe_call(wrapper.is_enabled, None),
        "rectangle": rect_to_dict(maybe_call(wrapper.rectangle, None)),
    }


def top_level_windows(
    backend: str,
    title_regex: str = "",
    visible_only: bool = True,
    pid: int | None = None,
    max_results: int = 50,
) -> list[dict[str, Any]]:
    desktop = Desktop(backend=backend)
    pattern = re.compile(title_regex, re.IGNORECASE) if title_regex else None
    windows = desktop.windows(top_level_only=True, visible_only=visible_only)
    results: list[dict[str, Any]] = []

    for wrapper in windows:
        summary = wrapper_summary(wrapper, wrapper_handle(wrapper), "")
        if pid is not None and summary["process_id"] != pid:
            continue
        if pattern and not pattern.search(summary["title"]):
            continue
        results.append(summary)
        if len(results) >= max_results:
            break

    return results


def resolve_target(root_hwnd: int, path: str, backend: str) -> tuple[Any, Any]:
    desktop = Desktop(backend=backend)
    root = desktop.window(handle=int(root_hwnd)).wrapper_object()
    current = root

    for index in parse_path(path):
        children = current.children()
        if index >= len(children):
            raise ValueError(
                f"Path '{path}' is out of range at index {index}. '{current.window_text()}' has {len(children)} children."
            )
        current = children[index]

    return root, current


def serialize_tree(
    wrapper: Any,
    root_hwnd: int,
    path: str,
    depth: int,
    max_children: int,
) -> dict[str, Any]:
    data = wrapper_summary(wrapper, root_hwnd, path)
    if depth <= 0:
        return data

    children = maybe_call(wrapper.children, []) or []
    data["child_count"] = len(children)
    data["children"] = [
        serialize_tree(
            child, root_hwnd, join_path(path, index), depth - 1, max_children
        )
        for index, child in enumerate(children[:max_children])
    ]
    if len(children) > max_children:
        data["children_truncated"] = len(children) - max_children
    return data


def make_output_path(save_path: str | None, prefix: str) -> Path:
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    if save_path:
        path = Path(save_path).expanduser()
        if not path.is_absolute():
            path = Path.cwd() / path
    else:
        path = CAPTURE_DIR / f"{prefix}-{timestamp}.png"

    path.parent.mkdir(parents=True, exist_ok=True)
    return path.resolve()


def matches_filters(
    info: dict[str, Any],
    title_regex: str,
    control_type: str,
    automation_id: str,
    class_name: str,
) -> bool:
    if title_regex and not re.search(
        title_regex, info.get("title", "") or "", re.IGNORECASE
    ):
        return False
    if (
        control_type
        and (info.get("control_type", "") or "").lower() != control_type.lower()
    ):
        return False
    if automation_id and (info.get("automation_id", "") or "") != automation_id:
        return False
    if class_name and (info.get("class_name", "") or "").lower() != class_name.lower():
        return False
    return True


@mcp.tool()
def desktop_list_windows(
    backend: str = "uia",
    title_regex: str = "",
    visible_only: bool = True,
    pid: int | None = None,
    max_results: int = 50,
) -> str:
    """List top-level desktop windows and return their `root_hwnd` handles."""
    try:
        backend = validate_backend(backend)
        windows = top_level_windows(
            backend, title_regex, visible_only, pid, max_results
        )
        return ok(backend=backend, count=len(windows), windows=windows)
    except Exception as exc:
        return fail(str(exc))


@mcp.tool()
def desktop_wait_for_window(
    title_regex: str = "",
    backend: str = "uia",
    visible_only: bool = True,
    pid: int | None = None,
    timeout_sec: float = 10.0,
    poll_interval_sec: float = 0.5,
) -> str:
    """Wait for a top-level window to appear by title regex and/or pid."""
    try:
        backend = validate_backend(backend)
        if not title_regex and pid is None:
            return fail("Provide at least one filter: title_regex or pid.")

        deadline = time.time() + max(timeout_sec, 0.1)
        while time.time() <= deadline:
            matches = top_level_windows(backend, title_regex, visible_only, pid, 20)
            if matches:
                return ok(
                    backend=backend,
                    matched=True,
                    window=matches[0],
                    count=len(matches),
                    windows=matches,
                )
            time.sleep(max(poll_interval_sec, 0.1))

        return fail(
            "Timed out waiting for a matching window.",
            backend=backend,
            title_regex=title_regex,
            pid=pid,
            timeout_sec=timeout_sec,
        )
    except Exception as exc:
        return fail(str(exc))


@mcp.tool()
def desktop_inspect_window(
    root_hwnd: int,
    path: str = "",
    backend: str = "uia",
    depth: int = 2,
    max_children: int = 40,
) -> str:
    """Inspect a window or control tree. Use `path` from earlier inspection results."""
    try:
        backend = validate_backend(backend)
        _, target = resolve_target(root_hwnd, path, backend)
        tree = serialize_tree(
            target, int(root_hwnd), path, max(depth, 0), max(max_children, 1)
        )
        return ok(backend=backend, root_hwnd=int(root_hwnd), path=path, tree=tree)
    except Exception as exc:
        return fail(str(exc), root_hwnd=root_hwnd, path=path)


@mcp.tool()
def desktop_find_controls(
    root_hwnd: int,
    path: str = "",
    backend: str = "uia",
    title_regex: str = "",
    control_type: str = "",
    automation_id: str = "",
    class_name: str = "",
    depth: int = 5,
    max_results: int = 20,
    max_nodes: int = 400,
) -> str:
    """Search descendants by title, control type, automation id, or class name."""
    try:
        backend = validate_backend(backend)
        if not any([title_regex, control_type, automation_id, class_name]):
            return fail(
                "Provide at least one filter: title_regex, control_type, automation_id, or class_name."
            )

        _, start = resolve_target(root_hwnd, path, backend)
        queue = deque([(start, path, 0)])
        matches: list[dict[str, Any]] = []
        scanned_nodes = 0

        while queue and len(matches) < max_results and scanned_nodes < max_nodes:
            wrapper, current_path, level = queue.popleft()
            scanned_nodes += 1
            info = wrapper_summary(wrapper, int(root_hwnd), current_path)

            if matches_filters(
                info, title_regex, control_type, automation_id, class_name
            ):
                matches.append(info)

            if level >= max(depth, 0):
                continue

            children = maybe_call(wrapper.children, []) or []
            for index, child in enumerate(children):
                queue.append((child, join_path(current_path, index), level + 1))

        return ok(
            backend=backend,
            root_hwnd=int(root_hwnd),
            start_path=path,
            count=len(matches),
            scanned_nodes=scanned_nodes,
            truncated=bool(queue),
            matches=matches,
        )
    except Exception as exc:
        return fail(str(exc), root_hwnd=root_hwnd, path=path)


@mcp.tool()
def desktop_click(
    root_hwnd: int,
    path: str = "",
    backend: str = "uia",
    button: str = "left",
    double: bool = False,
    offset_x: int | None = None,
    offset_y: int | None = None,
) -> str:
    """Click a control, or click relative to a window using `offset_x` and `offset_y`."""
    try:
        backend = validate_backend(backend)
        button = (button or "left").lower()
        if button not in SUPPORTED_BUTTONS:
            return fail(
                f"Unsupported button '{button}'. Use one of: {', '.join(sorted(SUPPORTED_BUTTONS))}."
            )
        if (offset_x is None) != (offset_y is None):
            return fail("Provide both offset_x and offset_y together.")

        _, target = resolve_target(root_hwnd, path, backend)
        rect = maybe_call(target.rectangle, None)
        if rect is None:
            return fail(
                "Target element does not expose a rectangle.",
                root_hwnd=root_hwnd,
                path=path,
            )

        rel_x = offset_x
        rel_y = offset_y
        if rel_x is None:
            rel_x = int((rect.right - rect.left) / 2)
            rel_y = int((rect.bottom - rect.top) / 2)
        if rel_y is None:
            rel_y = int((rect.bottom - rect.top) / 2)

        target.set_focus()
        time.sleep(0.1)
        target.click_input(button=button, double=double, coords=(rel_x, rel_y))

        return ok(
            backend=backend,
            clicked=wrapper_summary(target, int(root_hwnd), path),
            button=button,
            double=double,
            absolute_point={
                "x": int(rect.left + rel_x),
                "y": int(rect.top + rel_y),
            },
            relative_point={"x": int(rel_x), "y": int(rel_y)},
        )
    except Exception as exc:
        return fail(str(exc), root_hwnd=root_hwnd, path=path)


@mcp.tool()
def desktop_set_text(
    root_hwnd: int,
    text: str,
    path: str = "",
    backend: str = "uia",
    clear: bool = True,
    press_enter: bool = False,
    pause: float = 0.03,
) -> str:
    """Set plain text in an input control. Falls back to typing if needed."""
    try:
        backend = validate_backend(backend)
        _, target = resolve_target(root_hwnd, path, backend)
        target.set_focus()
        method = "send_keys"

        if clear:
            try:
                target.set_edit_text(text)
                method = "set_edit_text"
            except Exception:
                send_keys("^a{BACKSPACE}", pause=max(pause, 0.0))
                time.sleep(0.05)
                send_keys(text, with_spaces=True, pause=max(pause, 0.0))
        else:
            try:
                target.type_keys(
                    text,
                    with_spaces=True,
                    pause=max(pause, 0.0),
                    set_foreground=True,
                )
                method = "type_keys"
            except Exception:
                send_keys(text, with_spaces=True, pause=max(pause, 0.0))

        if press_enter:
            send_keys("{ENTER}", pause=max(pause, 0.0))

        return ok(
            backend=backend,
            target=wrapper_summary(target, int(root_hwnd), path),
            method=method,
            clear=clear,
            press_enter=press_enter,
        )
    except Exception as exc:
        return fail(str(exc), root_hwnd=root_hwnd, path=path)


@mcp.tool()
def desktop_type_keys(
    keys: str,
    root_hwnd: int | None = None,
    path: str = "",
    backend: str = "uia",
    pause: float = 0.03,
) -> str:
    """Type keys using pywinauto syntax like `^a`, `%{F4}`, or `{ENTER}`."""
    try:
        target_info = None
        if root_hwnd is not None:
            backend = validate_backend(backend)
            _, target = resolve_target(root_hwnd, path, backend)
            target.set_focus()
            target.type_keys(
                keys,
                with_spaces=True,
                pause=max(pause, 0.0),
                set_foreground=True,
            )
            target_info = wrapper_summary(target, int(root_hwnd), path)
        else:
            backend = "global"
            send_keys(keys, with_spaces=True, pause=max(pause, 0.0))

        return ok(backend=backend, keys=keys, target=target_info)
    except Exception as exc:
        return fail(str(exc), root_hwnd=root_hwnd, path=path)


@mcp.tool()
def desktop_screenshot(
    root_hwnd: int | None = None,
    path: str = "",
    backend: str = "uia",
    save_path: str = "",
) -> str:
    """Capture a screenshot of the full desktop, a window, or a control."""
    try:
        target_info = None
        if root_hwnd is None:
            image = ImageGrab.grab(all_screens=True)
        else:
            backend = validate_backend(backend)
            _, target = resolve_target(root_hwnd, path, backend)
            image = target.capture_as_image()
            target_info = wrapper_summary(target, int(root_hwnd), path)

        output_path = make_output_path(save_path, "desktop-capture")
        image.save(output_path)

        return ok(
            backend=backend if root_hwnd is not None else "global",
            save_path=str(output_path),
            width=int(image.width),
            height=int(image.height),
            target=target_info,
        )
    except Exception as exc:
        return fail(str(exc), root_hwnd=root_hwnd, path=path)


@mcp.tool()
def desktop_launch_application(
    command: str,
    workdir: str = "",
    backend: str = "uia",
    startup_wait_sec: float = 2.0,
) -> str:
    """Launch a Windows desktop application and return its pid and windows."""
    try:
        backend = validate_backend(backend)
        if not command.strip():
            return fail("Command cannot be empty.")

        resolved_workdir = None
        if workdir:
            resolved_workdir = Path(workdir).expanduser().resolve()
            if not resolved_workdir.exists():
                return fail(f"Workdir does not exist: {resolved_workdir}")

        app = Application(backend=backend).start(
            command,
            work_dir=str(resolved_workdir) if resolved_workdir else None,
            wait_for_idle=False,
        )
        time.sleep(max(startup_wait_sec, 0.1))

        pid = int(app.process)
        windows = top_level_windows(backend, pid=pid, max_results=20)

        return ok(
            backend=backend,
            command=command,
            workdir=str(resolved_workdir) if resolved_workdir else "",
            pid=pid,
            count=len(windows),
            windows=windows,
        )
    except Exception as exc:
        return fail(str(exc), command=command, workdir=workdir)


if __name__ == "__main__":
    mcp.run()
