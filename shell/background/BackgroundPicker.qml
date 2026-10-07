pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../pickers"
import "../windows"

// Every highlighted wallpaper shows on all screens at once. Enter keeps it,
// Escape returns to the chosen one.
PanelWindow {
    id: root

    property bool open: false

    function toggle() {
        if (open)
            cancel();
        else
            show();
    }

    // Taken once, like the theme picker: following the focused screen would
    // move the picker each time it takes or returns the keyboard.
    function show() {
        screen = Windows.focusedScreen;
        BackgroundState.rescan();
        open = true;
        carousel.open(BackgroundState.chosen || (BackgroundState.all[0] ?? ""));
    }

    function cancel() {
        BackgroundState.cancelPreview();
        open = false;
    }

    visible: open
    WlrLayershell.namespace: "temple-backgrounds"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    Carousel {
        id: carousel

        anchors.fill: parent

        entries: BackgroundState.all.map(path => {
            const slash = path.lastIndexOf("/");
            const file = path.slice(slash + 1);
            // A file directly in the store carries its hash in front of the name.
            const name = path.slice(0, slash) === "/nix/store" ? file.slice(file.indexOf("-") + 1) : file;
            return {
                key: path,
                label: name.replace(/\.[^.]+$/, "")
            };
        })
        hint: "←/→ preview  ·  type to filter  ·  Enter keeps  ·  Esc restores"
        delegate: preview
        onHighlighted: key => BackgroundState.previewPath(key)
        onAccepted: key => {
            BackgroundState.choose(key);
            root.open = false;
        }
        onCancelled: root.cancel()
    }

    Component {
        id: preview

        Image {
            required property string key

            anchors.fill: parent
            source: key
            sourceSize.width: Math.ceil(width * root.devicePixelRatio)
            sourceSize.height: Math.ceil(height * root.devicePixelRatio)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
        }
    }
}
