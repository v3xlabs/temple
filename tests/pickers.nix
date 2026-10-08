{test, ...}:
test {
  name = "pickers";
  nodes.machine.programs.ydotool.enable = true;
  testScript = ''
    wheel = "YDOTOOL_SOCKET=/run/ydotoold/socket ydotool mousemove --wheel -x 0 -y "
    harmony = "/etc/temple/wallpapers/Windows 7 Harmony.jpg"


    def chosen_background():
        return machine.succeed(f"cat {state}/background.path || true").strip()


    def scroll(steps):
        for _ in range(abs(steps)):
            machine.succeed(wheel + ("-1" if steps > 0 else "1"))
            time.sleep(0.6)


    wait_for_shell(machine)
    names = machine.succeed(ipc + "theme list").split()
    first = names.index(theme(machine))

    with subtest("scrolling the theme picker previews themes, and Enter keeps one"):
        machine.succeed(ipc + "shell toggleThemes")
        time.sleep(2)
        scroll(2)
        wait_for("two themes on", lambda: theme(machine) == names[(first + 2) % len(names)])
        scroll(-1)
        kept = names[(first + 1) % len(names)]
        wait_for("one theme back", lambda: theme(machine) == kept)
        machine.send_key("ret")
        time.sleep(2)
        assert theme(machine) == kept
        assert machine.succeed(f"readlink {state}/theme").strip() == f"/etc/temple/themes/{kept}"

    with subtest("typing filters the background picker, and Enter keeps the match"):
        machine.succeed(ipc + "shell toggleBackgrounds")
        time.sleep(2)
        machine.send_chars("harmony")
        time.sleep(1)
        machine.screenshot("backgrounds-harmony")
        machine.send_key("ret")
        wait_for("the Harmony wallpaper", lambda: chosen_background() == harmony)
        wait_for("the lock screen link", lambda: machine.succeed(f"readlink {state}/background").strip() == harmony)

    with subtest("Escape drops a scrolled preview"):
        machine.succeed(ipc + "shell toggleBackgrounds")
        time.sleep(2)
        scroll(2)
        machine.send_key("esc")
        time.sleep(2)
        assert chosen_background() == harmony

    with subtest("scrolling the background picker and Enter keeps another wallpaper"):
        machine.succeed(ipc + "shell toggleBackgrounds")
        time.sleep(2)
        scroll(2)
        machine.screenshot("backgrounds-scrolled")
        machine.send_key("ret")
        wait_for("another wallpaper", lambda: chosen_background() != harmony)
        machine.succeed(f"test -f '{chosen_background()}'")
  '';
}
