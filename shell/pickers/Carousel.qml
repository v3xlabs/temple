pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../theme"

// Overlay content shared by the pickers: scrim, a carousel of skewed slices,
// the selected label and a hint line. The picker owns the window and decides
// what highlighting, keeping and cancelling do.
Item {
    id: root

    // [{ key, label }]; typing filters on label.
    required property var entries
    // One slice's content, laid out at expandedWidth x expandedHeight and
    // cropped by the slice. Its root declares `required property string key`.
    required property Component delegate
    property string hint: ""

    property string currentKey: ""
    property string filter: ""
    readonly property int currentIndex: entries.findIndex(entry => entry.key === currentKey)
    readonly property var matching: {
        const needle = filter.toLowerCase();
        const indices = [];
        for (let i = 0; i < entries.length; i++)
            if (entries[i].label.toLowerCase().includes(needle))
                indices.push(i);
        return indices;
    }
    readonly property int position: matching.indexOf(currentIndex)

    // The highlighted entry takes 60% of the screen at 16:10; everything else scales with it.
    readonly property real zoom: Math.max(1, Math.min(width * 0.6, height * 0.6 * 1.6) / 640)
    readonly property int expandedWidth: Math.round(640 * zoom)
    readonly property int expandedHeight: Math.round(400 * zoom)
    readonly property int sliceWidth: Math.round(96 * zoom)
    readonly property int sliceHeight: Math.round(360 * zoom)
    readonly property int sliceSpacing: -skew
    readonly property int skew: Math.round(24 * zoom)
    readonly property int step: sliceWidth + sliceSpacing
    readonly property int radius: Math.max(1, Math.min(16, Math.ceil((width - expandedWidth) / 2 / step)))

    // A pointer resting where the overlay opens must not count as hovering.
    property bool pointerMoved: false
    property bool pointerSeen: false
    property point pointerOrigin

    signal highlighted(string key)
    signal accepted(string key)
    signal cancelled

    function open(key: string) {
        filter = "";
        currentKey = key;
        pointerMoved = false;
        pointerSeen = false;
        keyHandler.forceActiveFocus();
    }

    function select(index: int) {
        const key = entries[index].key;
        if (key === currentKey)
            return;
        currentKey = key;
        highlighted(key);
    }

    function move(delta: int) {
        const count = matching.length;
        if (count === 0)
            return;
        select(matching[position < 0 ? 0 : (position + delta + count) % count]);
    }

    function setFilter(text: string) {
        filter = text;
        if (position < 0 && matching.length > 0)
            select(matching[0]);
    }

    function accept() {
        if (position >= 0)
            accepted(currentKey);
    }

    function notePointer(at: point) {
        if (pointerMoved)
            return;
        if (!pointerSeen) {
            pointerSeen = true;
            pointerOrigin = at;
        } else if (Math.abs(at.x - pointerOrigin.x) + Math.abs(at.y - pointerOrigin.y) > 3) {
            pointerMoved = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        // Below Hyprland's ignore_alpha 0.3 for temple-*, so the live preview behind stays sharp.
        color: "#47000000"
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: mouse => root.notePointer(Qt.point(mouse.x, mouse.y))
        onClicked: root.cancelled()
    }

    Item {
        id: keyHandler

        focus: true
        Keys.onPressed: event => {
            const shift = event.modifiers & Qt.ShiftModifier;
            const plain = (event.modifiers & ~Qt.ShiftModifier) === Qt.NoModifier;
            const code = event.text.length === 1 ? event.text.charCodeAt(0) : 0;
            if (event.key === Qt.Key_Escape) {
                if (root.filter)
                    root.setFilter("");
                else
                    root.cancelled();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.accept();
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && shift)) {
                root.move(-1);
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.move(1);
            } else if (event.key === Qt.Key_Backspace && root.filter) {
                root.setFilter(root.filter.slice(0, -1));
            } else if (plain && code >= 32 && code !== 127) {
                root.setFilter(root.filter + event.text);
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    Item {
        id: carousel

        readonly property real centreX: (width - root.expandedWidth) / 2

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: Math.round(-40 * root.zoom)
        width: parent.width
        height: root.expandedHeight

        MouseArea {
            x: carousel.centreX
            width: root.expandedWidth
            height: parent.height
        }

        Repeater {
            model: root.matching

            Item {
                id: slice

                required property int modelData
                required property int index
                readonly property string key: root.entries[modelData].key
                readonly property int offset: {
                    const count = root.matching.length;
                    let distance = (index - Math.max(root.position, 0) + count) % count;
                    if (distance > count / 2)
                        distance -= count;
                    return distance;
                }
                readonly property bool selected: offset === 0
                readonly property bool hovered: area.containsMouse && root.pointerMoved
                readonly property bool live: Math.abs(offset) <= root.radius + 1
                property Item content: null

                function syncContent() {
                    if (live && !content)
                        content = root.delegate.createObject(holder, {
                            key: slice.key
                        });
                    else if (!live && content) {
                        content.destroy();
                        content = null;
                    }
                }

                onLiveChanged: syncContent()
                Component.onCompleted: syncContent()

                visible: Math.abs(offset) <= root.radius
                x: selected ? carousel.centreX : offset < 0 ? carousel.centreX + offset * root.step : carousel.centreX + root.expandedWidth + root.sliceSpacing + (offset - 1) * root.step
                y: (root.expandedHeight - height) / 2
                z: selected ? 100 : 50 - Math.abs(offset)
                width: selected ? root.expandedWidth : root.sliceWidth
                height: selected ? root.expandedHeight : root.sliceHeight

                Behavior on x {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: mask

                    anchors.fill: parent
                    visible: false
                    layer.enabled: true

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: "white"
                            strokeColor: "transparent"
                            startX: root.skew
                            startY: 0

                            PathLine {
                                x: slice.width
                                y: 0
                            }
                            PathLine {
                                x: slice.width - root.skew
                                y: slice.height
                            }
                            PathLine {
                                x: 0
                                y: slice.height
                            }
                            PathLine {
                                x: root.skew
                                y: 0
                            }
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: mask
                        maskThresholdMin: 0.3
                        maskSpreadAtMin: 0.3
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#16161c"
                    }

                    Item {
                        id: holder

                        x: (slice.width - root.expandedWidth) / 2
                        y: (slice.height - root.expandedHeight) / 2
                        width: root.expandedWidth
                        height: root.expandedHeight
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: slice.selected ? 0 : slice.hovered ? 0.2 : 0.45

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: slice.selected ? Theme.accent : "#59ffffff"
                        strokeWidth: slice.selected ? 3 : 1
                        startX: root.skew
                        startY: 0

                        PathLine {
                            x: slice.width
                            y: 0
                        }
                        PathLine {
                            x: slice.width - root.skew
                            y: slice.height
                        }
                        PathLine {
                            x: 0
                            y: slice.height
                        }
                        PathLine {
                            x: root.skew
                            y: 0
                        }
                    }
                }

                MouseArea {
                    id: area

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: mouse => root.notePointer(area.mapToItem(root, mouse.x, mouse.y))
                    onClicked: {
                        if (slice.key === root.currentKey)
                            root.accept();
                        else
                            root.select(slice.modelData);
                    }
                }
            }
        }
    }

    Text {
        id: label

        anchors.top: carousel.bottom
        anchors.topMargin: Math.round(24 * root.zoom)
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.expandedWidth
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        textFormat: Text.PlainText
        text: root.position >= 0 ? root.entries[root.currentIndex].label : root.filter ? "No matches" : ""
        color: "white"
        style: Text.Outline
        styleColor: "#b3000000"
        font.family: Theme.fontSans
        font.pixelSize: Math.round(30 * root.zoom)
        font.weight: Font.DemiBold
    }

    Text {
        id: filterLine

        anchors.top: label.bottom
        anchors.topMargin: Math.round(6 * root.zoom)
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.expandedWidth
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        textFormat: Text.PlainText
        text: root.filter ? "Filter: " + root.filter : " "
        color: "#e6ffffff"
        style: Text.Outline
        styleColor: "#b3000000"
        font.family: Theme.fontSans
        font.pixelSize: Math.round(17 * root.zoom)
    }

    Text {
        anchors.top: filterLine.bottom
        anchors.topMargin: Math.round(14 * root.zoom)
        anchors.horizontalCenter: parent.horizontalCenter
        textFormat: Text.PlainText
        text: root.hint
        color: "#ccffffff"
        style: Text.Outline
        styleColor: "#b3000000"
        font.family: Theme.fontSans
        font.pixelSize: Math.round(14 * root.zoom)
    }
}
