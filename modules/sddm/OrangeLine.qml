import QtQuick

// The orange line above the footer: brightest a quarter in, blue at both ends.
Rectangle {
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop {
            position: 0
            color: "#003399"
        }
        GradientStop {
            position: 0.125
            color: "#8d6b61"
        }
        GradientStop {
            position: 0.25
            color: "#f99737"
        }
        GradientStop {
            position: 0.375
            color: "#ea913c"
        }
        GradientStop {
            position: 0.5
            color: "#c2814c"
        }
        GradientStop {
            position: 0.625
            color: "#8d6b61"
        }
        GradientStop {
            position: 0.75
            color: "#535478"
        }
        GradientStop {
            position: 0.875
            color: "#21408c"
        }
        GradientStop {
            position: 1
            color: "#003399"
        }
    }
}
