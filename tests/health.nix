{
  pkgs,
  test,
}:
test {
  name = "health";
  testScript = ''
    def warned(summary, text=""):
        saved = json.loads(machine.succeed(f"cat {state}/notifications.json || echo '{{}}'"))
        return [entry for entry in saved.get("history", []) if entry["appName"] == "System Health" and entry["summary"] == summary and text in entry["body"]]


    # A small ext4 disk the test can fill: `size` MiB, mounted at `target`.
    def scratch(target, size):
        machine.succeed(f"truncate -s {size}M /tmp/{size}.img && ${pkgs.e2fsprogs}/bin/mkfs.ext4 -q /tmp/{size}.img && mkdir -p {target} && mount -o loop /tmp/{size}.img {target}")


    def load(on):
        if on:
            machine.succeed("for i in $(seq $(nproc)); do sh -c 'while :; do :; done' >/dev/null 2>&1 & echo $! >> /tmp/load.pids; done")
        else:
            machine.succeed("kill $(cat /tmp/load.pids) && rm /tmp/load.pids")


    wait_for_shell(machine)

    with subtest("a processor busy at 100% for ten seconds raises one warning"):
        load(True)
        wait_for("the CPU warning", lambda: warned("High CPU usage"), 60)
        time.sleep(10)
        assert len(warned("High CPU usage")) == 1, "the CPU warning repeated while the load lasted"
        machine.screenshot("cpu")
        load(False)

    with subtest("a disk with under a tenth of its space free raises a low space warning"):
        scratch("/mnt/low", 64)
        machine.succeed("fallocate -l 50M /mnt/low/fill")
        wait_for("the low space warning", lambda: warned("Low Disk Space", "/mnt/low"), 40)
        machine.screenshot("low")
        time.sleep(70)
        history = json.loads(machine.succeed(f"cat {state}/notifications.json"))["history"]
        others = [entry for entry in history if entry["appName"] != "System Health" and "disk space" in entry["body"]]
        assert others == [], f"Plasma's free space notifier warned too: {others}"

    with subtest("a disk that will be full within ten minutes at its rate raises a filling warning"):
        scratch("/mnt/filling", 512)
        machine.succeed("sh -c 'for i in $(seq 200); do head -c 2M /dev/zero >> /mnt/filling/grow; sync; sleep 1; done' >/dev/null 2>&1 &")
        wait_for("the filling warning", lambda: warned("Disk filling up", "/mnt/filling"), 90)
        machine.screenshot("filling")

    with subtest("the CPU warning comes back after the load drops and returns"):
        time.sleep(15)
        load(True)
        wait_for("a second CPU warning", lambda: len(warned("High CPU usage")) == 2, 60)
        load(False)
  '';
}
