import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.11
import QtQuick.Window 2.11

MenuItem {
    FontLoader {
        id: notoFont
        source: "fonts/NotoSans.ttf"
    }
    id: menuItem
    implicitWidth: 100
    implicitHeight: 20

    contentItem: Text {
        rightPadding: menuItem.indicator.width
        text: menuItem.text
        font.family: notoFont.name
        opacity: 1
        color: menuItem.highlighted ? "#5a50da" : "white"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 20
        opacity: 1
        color: menuItem.highlighted ? "#c0c0f0" : "transparent"
    }
}
