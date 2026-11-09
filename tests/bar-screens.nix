{test, ...}:
test {
  name = "bar-screens";
  nodes.machine = {
    temple.bar.monitors.bottom = ["DP-1"];
    specialisation.named.configuration.temple.bar.monitors.bottom = ["Virtual-2"];
    specialisation.right.configuration.temple.bar.monitors.bottom = ["right"];
  };
  display = [
    "-device virtio-vga,xres=1280,yres=720"
    "-device secondary-vga,xres=1280,yres=720"
  ];
  testScript = ''
    def bar_outputs():
        return sorted(w["output"] for w in windows(machine) if w["resourceClass"] == "quickshell" and w["layer"] != 0 and w["height"] < 100)


    def rightmost_output():
        backgrounds = [w for w in windows(machine) if w["resourceClass"] == "quickshell" and w["layer"] == 0]
        return max(backgrounds, key=lambda w: w["x"] + w["width"])["output"]


    wait_for_shell(machine)

    with subtest("a configured output that is not connected leaves a bar on every output"):
        wait_for("a bar on both outputs", lambda: bar_outputs() == ["Virtual-1", "Virtual-2"])

    with subtest("a connected output by name gets the only bar"):
        machine.succeed("/run/current-system/specialisation/named/bin/switch-to-configuration test")
        wait_for("one bar on Virtual-2", lambda: bar_outputs() == ["Virtual-2"])

    with subtest("a position picks the output at that place in the layout"):
        machine.succeed("/run/current-system/specialisation/right/bin/switch-to-configuration test")
        wait_for("one bar on the rightmost output", lambda: bar_outputs() == [rightmost_output()])
  '';
}
