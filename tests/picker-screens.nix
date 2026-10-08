{test, ...}:
test {
  name = "picker-screens";
  display = [
    "-device virtio-vga,xres=1280,yres=720"
    "-device secondary-vga,xres=1280,yres=720"
    "-device secondary-vga,xres=1280,yres=720"
  ];
  testScript = ''
    def konsole():
        return [w for w in windows(machine) if w["resourceClass"] == "org.kde.konsole"]


    # Full-screen shell surfaces above the background layer: the theme picker and the launcher.
    def opened_since(base):
        events = window_events(machine)[base:]
        removed = {w["id"] for kind, w in events if kind == "REMOVED"}
        return [
            w
            for kind, w in events
            if kind == "ADDED" and w["resourceClass"] == "quickshell" and w["layer"] != 0 and (w["width"], w["height"]) == (1280, 720) and w["id"] not in removed
        ]


    wait_for_shell(machine)
    names = machine.succeed(ipc + "theme list").split()
    first = theme(machine)

    machine.succeed(user + "systemd-run --user --collect konsole")
    start_screen = wait_for("konsole", konsole)[0]["output"]
    machine.succeed(user + "busctl --user call org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component invokeShortcut s 'Window to Next Screen'")
    active = wait_for("konsole on the next screen", lambda: [w for w in konsole() if w["output"] != start_screen])[0]["output"]
    watch_windows(machine)

    with subtest("Super+T opens one picker, on the active screen, and arrows preview"):
        base = len(window_events(machine))
        machine.succeed(ipc + "shell toggleThemes")
        wait_for("the theme picker", lambda: opened_since(base))
        machine.send_key("right")
        wait_for("the next theme", lambda: theme(machine) == names[(names.index(first) + 1) % len(names)])
        time.sleep(2)
        machine.screenshot("picker")
        surfaces = opened_since(base)
        assert len(surfaces) == 1 and surfaces[0]["output"] == active, surfaces

    with subtest("Escape closes the picker and restores the theme"):
        machine.send_key("esc")
        wait_for("the first theme", lambda: theme(machine) == first)
        wait_for("the picker to close", lambda: not opened_since(base))

    with subtest("the launcher opens the same picker on the active screen"):
        base = len(window_events(machine))
        machine.succeed(ipc + "shell togglePalette")
        wait_for("the launcher", lambda: opened_since(base))
        machine.send_chars("theme")
        machine.send_key("ret")
        time.sleep(3)
        machine.screenshot("picker-from-launcher")
        surfaces = opened_since(base)
        assert len(surfaces) == 1 and surfaces[0]["output"] == active, surfaces
        machine.send_key("right")
        wait_for("the next theme", lambda: theme(machine) == names[(names.index(first) + 1) % len(names)])
  '';
}
