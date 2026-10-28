import QtQuick

// The bright line under the top band: lightest left of centre, fading to the
// band blue at both edges.
Rectangle {
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0
            color: "#466dcd"
        }
        GradientStop {
            position: 0.125
            color: "#91afec"
        }
        GradientStop {
            position: 0.25
            color: "#c7ddff"
        }
        GradientStop {
            position: 0.375
            color: "#c1d8fd"
        }
        GradientStop {
            position: 0.5
            color: "#afc8f6"
        }
        GradientStop {
            position: 0.75
            color: "#7c9be5"
        }
        GradientStop {
            position: 1
            color: "#456dcd"
        }
    }
}
