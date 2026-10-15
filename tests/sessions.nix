{test, ...}: let
  node = session: {lib, ...}: {
    services.displayManager.defaultSession = lib.mkForce session;
    # Settings a user made in plain Plasma. The Temple session must win over
    # them and must not write to this file.
    systemd.tmpfiles.rules = [
      "d /home/temple/.config 0755 temple users -"
      "f+ /home/temple/.config/kwinrc 0644 temple users - [org.kde.kdecoration2]\\nlibrary=org.kde.breeze\\ntheme=Breeze\\n\\n[TabBox]\\nLayoutName=compact\\n"
    ];
  };
in
  test {
    name = "sessions";
    nodes = {
      temple = node "temple";
      plasma = node "plasma";
    };
    testScript = ''
      components = user + "busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel allComponents"
      session_kwinrc = user + "sh -c 'export $(systemctl --user show-environment | grep ^XDG_CONFIG_DIRS=); kreadconfig6 --file kwinrc --group {} --key {}'"


      def assert_kwinrc_untouched(machine):
          kwinrc = machine.succeed("cat /home/temple/.config/kwinrc")
          assert "temple-" not in kwinrc and "[$i]" not in kwinrc, kwinrc
          assert "library=org.kde.breeze" in kwinrc and "LayoutName=compact" in kwinrc, kwinrc


      start_all()

      with subtest("plain Plasma runs plasmashell and no Temple parts"):
          plasma.wait_until_succeeds(user + "systemctl --user is-active plasma-plasmashell.service", timeout=timedelta(seconds=240))
          plasma.fail(user + "systemctl --user is-active temple-shell.service")
          plasma.fail("pgrep -u temple -f '[q]s -p /etc/temple/shell'")
          plasma.fail(components + " | grep -i temple")
          info = kwin_support_information(plasma)
          assert "Plugin: org.kde.breeze\n" in info, info

      with subtest("Temple runs its shell in place of plasmashell and the splash"):
          temple.wait_until_succeeds(user + "systemctl --user is-active temple-shell.service", timeout=timedelta(seconds=240))
          wait_for_shell(temple)
          temple.fail("pgrep -x plasmashell")
          temple.fail("pgrep -x ksplashqml")
          temple.succeed(components + " | grep -i temple")

      with subtest("Temple's KWin uses the theme's decoration over the user's kwinrc"):
          first = theme(temple)
          info = kwin_support_information(temple)
          assert "Plugin: org.kde.kwin.aurorae\n" in info and f"Theme: temple-{first}\n" in info, info

      with subtest("a theme switch moves the decoration and switcher, and windows stay decorated"):
          temple.succeed(user + "systemd-run --user --collect konsole")
          wait_for("konsole", lambda: [w for w in windows(temple) if w["resourceClass"] == "org.kde.konsole"])
          temple.succeed(ipc + "theme set xp-luna")
          wait_for("the XP decoration", lambda: "Theme: temple-xp-luna\n" in kwin_support_information(temple))
          assert temple.succeed(session_kwinrc.format("TabBox", "LayoutName")).strip() == "temple-xp-luna"
          time.sleep(2)
          wait_for(
              "a decorated konsole",
              lambda: [w for w in windows(temple) if w["resourceClass"] == "org.kde.konsole" and not w["noBorder"] and w["height"] > w["clientHeight"]],
          )
          log = kwin_log(temple)
          assert "Failed to initialize decoration theme" not in log and "Could not locate decoration plugin" not in log
          temple.screenshot("temple-xp-luna")

      with subtest("neither session writes Temple settings into ~/.config/kwinrc"):
          assert_kwinrc_untouched(temple)
          assert_kwinrc_untouched(plasma)
    '';
  }
