# RestartDock

A tiny macOS menu bar app. Left-click the Dock icon in the menu bar to run
`killall Dock` (the Dock restarts itself immediately). Right-click for a menu
with **Restart Dock**, **Start at Login** toggle, and **Quit**.

## Build & install

```sh
./build.sh              # compiles, ad-hoc signs, installs to /Applications, launches
./build.sh --no-install # just build into ./build/RestartDock.app
```

Requires Xcode Command Line Tools (uses `swiftc`, no Xcode project).

## Notes

- Registers itself as a login item on first launch (via `SMAppService`).
  Toggle it off from the right-click menu or in System Settings > General > Login Items.
- `LSUIElement` is set, so the app has no Dock icon or window.
- Icon is the SF Symbol `repeat`; change it in `Sources/main.swift`.

## Uninstall

```sh
./uninstall.sh   # quits the app, unregisters the login item, removes /Applications/RestartDock.app
```

## License

[MIT](LICENSE)
