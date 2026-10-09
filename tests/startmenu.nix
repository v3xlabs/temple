{test, ...}:
test {
  name = "startmenu";
  testScript = ''
    wait_for_shell(machine)
    for name, program in [("win7-aero", "konsole"), ("xp-luna", "kate")]:
        with subtest(f"{name}: Super opens the Start menu, and typed text finds a program that Enter starts"):
            machine.succeed(ipc + f"theme set {name}")
            time.sleep(4)
            machine.send_key("meta_l")
            time.sleep(1)
            machine.send_chars(program)
            time.sleep(1)
            machine.screenshot(f"{name}-search")
            machine.send_key("ret")
            wait_for(program, lambda: [w for w in windows(machine) if w["resourceClass"] == f"org.kde.{program}"])
  '';
}
