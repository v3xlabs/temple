{
  pkgs,
  self,
}: let
  # One JSON line per window. Layer surfaces count as windows too; `layer` 0 is
  # KWin's desktop layer, where the background surfaces sit.
  describe = ''
    function describe(w) {
      const f = w.frameGeometry;
      return JSON.stringify({
        id: String(w.internalId),
        resourceClass: w.resourceClass,
        output: w.output ? w.output.name : "",
        layer: w.layer,
        x: Math.round(f.x),
        y: Math.round(f.y),
        width: Math.round(f.width),
        height: Math.round(f.height),
        clientHeight: Math.round(w.clientGeometry.height),
        noBorder: w.noBorder,
      });
    }
  '';
  dump = pkgs.writeText "temple-dump.js" ''
    ${describe}
    for (const w of workspace.stackingOrder)
      print("TEMPLE-WIN " + describe(w));
    print("TEMPLE-DUMP-END");
  '';
  watch = pkgs.writeText "temple-watch.js" ''
    ${describe}
    workspace.windowAdded.connect(w => print("TEMPLE-ADDED " + describe(w)));
    workspace.windowRemoved.connect(w => print("TEMPLE-REMOVED " + describe(w)));
  '';

  prelude = ''
    import json
    import time
    from datetime import timedelta

    user = "sudo -u temple env HOME=/home/temple XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus WAYLAND_DISPLAY=wayland-0 "
    ipc = user + "qs -p /etc/temple/shell ipc call "
    state = "/home/temple/.local/state/temple"


    def wait_for(what, check, seconds=30):
        deadline = time.monotonic() + seconds
        while True:
            result = check()
            if result:
                return result
            if time.monotonic() > deadline:
                raise Exception(f"timed out waiting for {what}")
            time.sleep(0.5)


    def wait_for_shell(machine):
        machine.wait_until_succeeds(user + "qs -p /etc/temple/shell ipc show", timeout=timedelta(seconds=240))


    def theme(machine):
        return machine.succeed(ipc + "theme get").strip()


    def kwin_log(machine):
        return machine.succeed(user + "journalctl --user -u plasma-kwin_wayland --no-pager -o cat")


    def kwin_support_information(machine):
        reply = machine.succeed(user + "busctl --user --json=short call org.kde.KWin /KWin org.kde.KWin supportInformation")
        return json.loads(reply)["data"][0]


    def run_kwin_script(machine, path, name):
        sid = machine.succeed(user + f"busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting loadScript ss {path} {name}").split()[1]
        machine.succeed(user + f"busctl --user call org.kde.KWin /Scripting/Script{sid} org.kde.kwin.Script run")


    def records(text, marker):
        return [json.loads(line.split(marker, 1)[1]) for line in text.splitlines() if marker in line]


    def windows(machine):
        done = kwin_log(machine).count("TEMPLE-DUMP-END")
        run_kwin_script(machine, "${dump}", "temple-dump")

        def listed():
            chunks = kwin_log(machine).split("TEMPLE-DUMP-END")
            return chunks[done] if len(chunks) > done + 1 else None

        listing = wait_for("KWin window list", listed)
        machine.succeed(user + "busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting unloadScript s temple-dump")
        return records(listing, "TEMPLE-WIN ")


    def watch_windows(machine):
        run_kwin_script(machine, "${watch}", "temple-watch")


    def window_events(machine):
        events = []
        for line in kwin_log(machine).splitlines():
            for kind in ("ADDED", "REMOVED"):
                marker = f"TEMPLE-{kind} "
                if marker in line:
                    events.append((kind, json.loads(line.split(marker, 1)[1])))
        return events
  '';
in {
  # One NixOS test of the VM host. `display` is the list of QEMU display devices.
  test = {
    name,
    nodes ? {machine = {};},
    display ? ["-device virtio-vga,xres=1600,yres=900"],
    testScript,
  }:
    pkgs.testers.runNixOSTest {
      name = "temple-${name}";
      defaults = {
        imports = [self.nixosModules.temple ../hosts/vm.nix];
        virtualisation = {
          memorySize = 4096;
          cores = 4;
          qemu.options = ["-vga none"] ++ display;
        };
      };
      inherit nodes;
      testScript = prelude + testScript;
    };
}
