pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property var backgrounds: BackgroundState.backgrounds
    readonly property string wanted: BackgroundState.effective || (backgrounds.length > 0 ? backgrounds[Quickshell.screens.indexOf(screen) % backgrounds.length] : "")
    property bool firstInFront: true
    readonly property Wallpaper front: firstInFront ? first : second
    readonly property Wallpaper back: firstInFront ? second : first

    function show() {
        if (front.path === wanted)
            return;
        back.path = wanted;
        if (back.status === Image.Ready)
            swap(back);
    }

    function swap(wallpaper: Wallpaper) {
        if (wallpaper !== back || wallpaper.path !== wanted)
            return;
        firstInFront = !firstInFront;
        release.restart();
    }

    onWantedChanged: show()
    Component.onCompleted: show()

    WlrLayershell.namespace: "background"
    WlrLayershell.layer: WlrLayer.Background
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    component Wallpaper: Image {
        property string path: ""

        anchors.fill: parent
        source: path
        sourceSize.width: Math.ceil(width * root.devicePixelRatio)
        sourceSize.height: Math.ceil(height * root.devicePixelRatio)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }
    }

    Wallpaper {
        id: first

        opacity: root.firstInFront ? 1 : 0
        onStatusChanged: if (status === Image.Ready)
            root.swap(first)
    }

    Wallpaper {
        id: second

        opacity: root.firstInFront ? 0 : 1
        onStatusChanged: if (status === Image.Ready)
            root.swap(second)
    }

    // Drops the faded-out decode so a screen holds one full-size image.
    Timer {
        id: release

        interval: 320
        onTriggered: if (root.back.path !== root.wanted)
            root.back.path = ""
    }
}
