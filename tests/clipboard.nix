{
  pkgs,
  test,
}:
test {
  name = "clipboard";
  nodes.machine = {environment.systemPackages = [pkgs.wl-clipboard];};
  testScript = ''
    def copy(text):
        machine.succeed(user + f"wl-copy {text} >/dev/null 2>&1")
        time.sleep(0.5)


    def clipboard():
        return machine.succeed(user + "wl-paste --no-newline")


    def open_history():
        before = {w["id"] for w in windows(machine)}
        machine.send_key("meta_l-v")
        wait_for("the clipboard history", lambda: [w for w in windows(machine) if w["id"] not in before])
        time.sleep(0.5)


    wait_for_shell(machine)
    for text in ["first", "second", "third"]:
        copy(text)

    for name in ["xp-luna", "win7-aero", "macos-tahoe", "templeos"]:
        with subtest(f"{name}: Super+V shows the history, and Escape leaves the clipboard as it was"):
            machine.succeed(ipc + f"theme set {name}")
            time.sleep(4)
            open_history()
            machine.send_key("down")
            time.sleep(0.5)
            machine.screenshot(f"{name}-history")
            machine.send_key("esc")
            time.sleep(0.5)
            assert clipboard() == "third", clipboard()

    with subtest("Enter on an older entry puts it back on the clipboard"):
        open_history()
        machine.send_key("down")
        machine.send_key("ret")
        wait_for("the second copy", lambda: clipboard() == "second")

    with subtest("Typed text filters the history"):
        open_history()
        machine.send_chars("fir")
        time.sleep(0.5)
        machine.screenshot("filtered")
        machine.send_key("ret")
        wait_for("the first copy", lambda: clipboard() == "first")

    with subtest("An image copy shows a thumbnail, and Enter puts the image back on the clipboard"):
        machine.succeed(user + "wl-copy --type image/png < /etc/temple/shell/bg.png >/dev/null 2>&1")
        time.sleep(1)
        copy("fourth")
        open_history()
        machine.send_key("down")
        time.sleep(0.5)
        machine.screenshot("image")
        machine.send_key("ret")
        wait_for("the image copy", lambda: "image/png" in machine.succeed(user + "wl-paste --list-types"))
  '';
}
