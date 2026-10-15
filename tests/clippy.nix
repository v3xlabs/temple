{
  pkgs,
  test,
}: let
  # Stands in for Voxtype's bridge: one second of voice, then silence.
  bridge = pkgs.writeShellScriptBin "voxtype-audio-bridge" ''
    echo '{"status":"connected"}'
    for _ in $(seq 100); do echo '{"peak":0.5,"rms":0.3,"vad":1,"ts_ms":0}'; sleep 0.01; done
    while true; do echo '{"peak":0.01,"rms":0.01,"vad":0,"ts_ms":0}'; sleep 0.01; done
  '';
in
  test {
    name = "clippy";
    nodes.machine = {
      temple.theme = "xp-luna";
      environment.systemPackages = [pkgs.libnotify bridge];
    };
    testScript = ''
      voxtype = "/run/user/1000/voxtype/state"


      # Clippy's surface sits 16 px from the right edge of the 1600 px screen.
      def clippy(listing):
          return [w for w in listing if w["resourceClass"] == "quickshell" and w["x"] + w["width"] == 1600 - 16]


      def set_voxtype(value):
          machine.succeed(user + f"sh -c 'echo {value} > {voxtype}'")


      wait_for_shell(machine)
      # The shell creates the directory, and Clippy watches the state file only once it exists.
      machine.wait_until_succeeds("test -d /run/user/1000/voxtype")
      watch_windows(machine)
      assert not clippy(windows(machine))

      with subtest("Clippy comes on screen while Voxtype records"):
          base = len(window_events(machine))
          set_voxtype("recording")
          shown = wait_for("Clippy", lambda: clippy([w for kind, w in window_events(machine)[base:] if kind == "ADDED"]))
          assert len(shown) == 1, shown
          time.sleep(1)
          machine.screenshot("recording")

      with subtest("Clippy stays while Voxtype transcribes"):
          set_voxtype("transcribing")
          time.sleep(3)
          machine.screenshot("transcribing")
          assert len(clippy(windows(machine))) == 1

      with subtest("Voxtype's notification opens Clippy's balloon"):
          height = clippy(windows(machine))[0]["height"]
          machine.succeed(user + f"sh -c 'echo idle > {voxtype}; notify-send --app-name=Voxtype Transcribed \"It looks like you are writing a letter.\"'")
          wait_for("the balloon", lambda: [w for w in clippy(windows(machine)) if w["height"] > height])
          machine.screenshot("balloon")

      with subtest("Clippy leaves once Voxtype is idle and the balloon times out"):
          wait_for("Clippy to leave", lambda: not clippy(windows(machine)), seconds=30)
          machine.screenshot("gone")
    '';
  }
