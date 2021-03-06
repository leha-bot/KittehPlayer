import QtQuick 2.11
import QtQuick.Controls 2.4

ComboBox {
    id: control
    width: parent.width

    FontLoader {
        id: notoFont
        source: "fonts/NotoSans.ttf"
    }

    indicator: Canvas {
        id: canvas
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12
        height: 8
        contextType: "2d"

        Connections {
            target: control
            onPressedChanged: canvas.requestPaint()
        }

        onPaint: {
            context.reset()
            context.moveTo(0, 0)
            context.lineTo(width, 0)
            context.lineTo(width / 2, height)
            context.closePath()
            context.fillStyle = control.pressed ? "#17a81a" : "#21be2b"
            context.fill()
        }
    }

    contentItem: Text {
        leftPadding: 2
        rightPadding: control.indicator.width + control.spacing
        text: control.displayText
        font.family: notoFont.name
        color: "white"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 40
        color: "transparent"
        border.color: "black"
        border.width: 2
    }

    popup: Popup {
        y: control.height - 1
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            highlight: Rectangle {
                color: "white"
                opacity: 1
            }

            ScrollIndicator.vertical: ScrollIndicator {
            }
        }

        background: Rectangle {
            opacity: 0.6
            color: "white"
            border.color: "black"
            border.width: 2
        }
    }
}
