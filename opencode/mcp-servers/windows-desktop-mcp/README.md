# Windows Desktop MCP

An MCP server for Windows GUI automation in OpenCode using `pywinauto`.

It is intended for ad hoc AI-driven desktop testing sessions where browser tools are not enough.

## Why this setup

- Uses Windows UI Automation when possible (`uia` backend by default)
- Works well for native Windows apps and many Electron/WPF/WinForms apps
- Stays disabled by default in OpenCode so it does not add tool context unless you explicitly enable it

## Files

- `server.py`: MCP server entry point
- `requirements.txt`: Python dependencies
- `captures/`: default screenshot output directory created on demand

## Install dependencies

```bash
pip install -r C:\Users\enisn\.config\opencode\mcp-servers\windows-desktop-mcp\requirements.txt
```

## OpenCode config

The server is registered in `C:\Users\enisn\.config\opencode\opencode.jsonc` and `C:\Users\enisn\.config\opencode\opencode.json` as:

```json
"windows_desktop": {
  "type": "local",
  "command": [
    "python",
    "C:/Users/enisn/.config/opencode/mcp-servers/windows-desktop-mcp/server.py"
  ],
  "enabled": false
}
```

Set `"enabled": true` only in sessions where you want desktop automation, then restart OpenCode.

## Tool flow

Typical sequence:

1. `desktop_launch_application` or start the app another way
2. `desktop_list_windows` to get a `root_hwnd`
3. `desktop_inspect_window` or `desktop_find_controls` to discover paths
4. `desktop_click`, `desktop_set_text`, or `desktop_type_keys` to interact
5. `desktop_screenshot` to verify what happened

## Control references

- `root_hwnd`: top-level window handle from `desktop_list_windows`
- `path`: slash-separated child indexes from `desktop_inspect_window`, such as `0/2/1`
- Empty `path` means the top-level window itself

This avoids relying on child window handles, which are often missing for UI Automation elements.

## Backend guidance

- Start with `backend="uia"`
- Try `backend="win32"` for older or less accessible applications

## Notes

- `desktop_type_keys` uses pywinauto key syntax like `^a`, `%{F4}`, and `{ENTER}`
- `desktop_click` can also click relative coordinates inside a window by passing `offset_x` and `offset_y`
- Full-desktop screenshots are supported by calling `desktop_screenshot` without a `root_hwnd`
