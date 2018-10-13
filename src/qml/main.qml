import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.11
import QtQuick.Window 2.11
import player 1.0

import "codes.js" as LanguageCodes

ApplicationWindow {
    id: mainWindow
    title: "Qt Quick Controls 2"
    visible: true
    width: 720
    height: 480

    property int lastScreenVisibility

    function updatePlayPauseIcon() {
        var paused = renderer.getProperty("pause")
        if (paused) {
            playPauseButton.icon.source = "qrc:/player/icons/play.svg"
        } else {
            playPauseButton.icon.source = "qrc:/player/icons/pause.svg"
        }
    }

    function updateVolume() {
        var muted = renderer.getProperty("mute")
        var volume = renderer.getProperty("volume")

        if (muted || volume === 0) {
            volumeButton.icon.source = "qrc:/player/icons/volume-mute.svg"
        } else {
            if (volume < 25) {
                volumeButton.icon.source = "qrc:/player/icons/volume-down.svg"
            } else {
                volumeButton.icon.source = "qrc:/player/icons/volume-up.svg"
            }
        }
    }

    function updatePrev() {
        var playlist_pos = renderer.getProperty("playlist-pos")
        if (playlist_pos > 0) {
            playlistPrevButton.visible = true
            playlistPrevButton.width = playPauseButton.width
        } else {
            playlistPrevButton.visible = false
            playlistPrevButton.width = 0
        }
    }

    function updateControls() {
        updatePrev()
        updatePlayPauseIcon()
        updateVolume()
    }

    function updatePlayPause() {
        renderer.command(["cycle", "pause"])
        updatePlayPauseIcon()
    }

    function setSubtitle(sub) {
        console.log(sub)
    }

    function tracksMenuUpdate() {
        var tracks = renderer.getProperty("track-list/count")
        var track = 0
        subModel.clear()
        audioModel.clear()
        vidModel.clear()

        var aid = renderer.getProperty("aid")
        var sid = renderer.getProperty("sid")
        var vid = renderer.getProperty("vid")

        console.log("Updating Track Menu, Total Tracks: " + tracks)
        for (track = 0; track <= tracks; track++) {
            var trackID = renderer.getProperty("track-list/" + track + "/id")
            var trackType = renderer.getProperty(
                        "track-list/" + track + "/type")
            var trackLang = LanguageCodes.localeCodeToEnglish(
                        String(renderer.getProperty(
                                   "track-list/" + track + "/lang")))
            var trackTitle = renderer.getProperty(
                        "track-list/" + track + "/title")
            if (trackType == "sub") {
                subModel.append({
                                    key: trackLang,
                                    value: trackID
                                })
                if (renderer.getProperty("track-list/" + track + "/selected")) {
                    subList.currentIndex = subList.count
                }
            } else if (trackType == "audio") {
                audioModel.append({
                                      key: (trackTitle === undefined ? "" : trackTitle + " ")
                                           + trackLang,
                                      value: trackID
                                  })
                if (renderer.getProperty("track-list/" + track + "/selected")) {
                    audioList.currentIndex = audioList.count
                }
            } else if (trackType == "video") {
                vidModel.append({
                                    key: "Video " + trackID,
                                    value: trackID
                                })
                if (renderer.getProperty("track-list/" + track + "/selected")) {
                    vidList.currentIndex = vidList.count
                }
            }
        }
    }

    MpvObject {
        id: renderer
        anchors.fill: parent
        Component.onCompleted: {
            var args = Qt.application.arguments
            var len = Qt.application.arguments.length
            var argNo = 0
            renderer.setOption("ytdl-format", "bestvideo[width<=" + Screen.width
                               + "][height<=" + Screen.height + "]+bestaudio")
            if (len > 1) {
                for (argNo = 0; argNo < len; argNo++) {
                    var argument = args[argNo]
                    if (argument.startsWith("--")) {
                        argument = argument.substr(2)
                        if (argument.length > 0) {
                            var splitArg = argument.split(/=(.+)/)
                            renderer.setOption(splitArg[0], splitArg[1])
                        }
                    } else {
                        renderer.command(["loadfile", argument, "append-play"])
                    }
                }
            }
        }

        FontLoader {
            id: notoFont
            source: "fonts/NotoSans.ttf"
        }

        function createTimestamp(d) {
            d = Number(d)
            var h = Math.floor(d / 3600)
            var m = Math.floor(d % 3600 / 60)
            var s = Math.floor(d % 3600 % 60)

            var hour = h > 0 ? h + ":" : ""
            var minute = m + ":"
            var second = s > 10 ? s : "0" + s
            return hour + minute + second
        }

        function setProgressBarEnd(val) {
            progressBar.to = val
        }

        function setProgressBarValue(val) {
            timeLabel.text = createTimestamp(val) + " / " + createTimestamp(
                        progressBar.to)
            progressBar.value = val
        }

        function setTitle() {
            titleLabel.text = renderer.getProperty("media-title")
        }

        function hideControls() {
            controlsBar.visible = false
            controlsBackground.visible = false
            titleBar.visible = false
            titleBackground.visible = false
            controlsBar.height = 0
        }

        function showControls() {
            updateControls()
            controlsBar.visible = true
            controlsBackground.visible = true
            titleBar.visible = true
            titleBackground.visible = true
            controlsBar.height = renderer.height / 16
        }

        Dialog {
            id: loadDialog
            title: "URL / File Path"
            standardButtons: StandardButton.Cancel | StandardButton.Open

            onAccepted: {
                renderer.command(["loadfile", pathText.text])
                pathText.text = ""
            }

            TextField {
                id: pathText
                text: "/home/kitteh/babyshark.mkv"
                placeholderText: qsTr("URL / File Path")
            }
        }

        MouseArea {
            id: mouseAreaBar
            x: 0
            y: parent.height
            width: parent.width
            height: controlsBar.height + progressBar.height
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            hoverEnabled: true
            onEntered: {
                mouseAreaPlayerTimer.stop()
            }
        }

        MouseArea {
            id: mouseAreaPlayer
            width: parent.width
            anchors.bottom: mouseAreaBar.top
            anchors.bottomMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.top: titleBar.bottom
            anchors.topMargin: 0
            hoverEnabled: true
            onClicked: loadDialog.open()
            Timer {
                id: mouseAreaPlayerTimer
                interval: 2000
                running: false
                repeat: false
                onTriggered: {
                    renderer.hideControls()
                }
            }
            onPositionChanged: {
                renderer.showControls()
                mouseAreaPlayerTimer.restart()
            }
        }

        Rectangle {
            id: titleBackground
            height: titleBar.height
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "black"
            opacity: 0.6
        }

        Rectangle {
            id: titleBar
            height: renderer.height / 16
            anchors.right: parent.right
            anchors.rightMargin: parent.width / 128
            anchors.left: parent.left
            anchors.leftMargin: parent.width / 128
            anchors.top: parent.top

            visible: true
            color: "transparent"

            Text {
                id: titleLabel
                text: "Title"
                color: "white"
                width: parent.width
                height: parent.height
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                anchors.topMargin: 4
                anchors.top: parent.top
                font.family: notoFont.name
                fontSizeMode: Text.Fit
                minimumPixelSize: 10
                font.pixelSize: 72
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
                opacity: 1
            }
        }

        Rectangle {
            id: controlsBackground
            height: controlsBar.height + (progressBar.topPadding * 2)
                    - (progressBackground.height * 2)
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "black"
            opacity: 0.6
        }

        Rectangle {
            id: controlsBar
            height: renderer.height / 16
            anchors.right: parent.right
            anchors.rightMargin: parent.width / 128
            anchors.left: parent.left
            anchors.leftMargin: parent.width / 128
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            visible: true
            color: "transparent"

            Rectangle {
                id: subtitlesMenuBackground
                height: controlsBar.height + (progressBar.topPadding * 2)
                        - (progressBackground.height * 2)
                anchors.fill: subtitlesMenu
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: false
                color: "black"
                opacity: 0.6
                radius: 5
            }

            Rectangle {
                id: subtitlesMenu
                color: "transparent"
                width: childrenRect.width
                height: childrenRect.height
                visible: false
                anchors.right: subtitlesButton.right
                anchors.bottom: progressBar.top
                radius: 5

                Text {
                    id: audioLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: "Audio"
                    color: "white"
                    font.family: notoFont.name
                    font.pixelSize: 14
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 1
                }
                ComboBox {
                    id: audioList
                    textRole: "key"
                    anchors.top: audioLabel.bottom
                    model: ListModel {
                        id: audioModel
                    }
                    onActivated: {
                        renderer.command(["set", "aid", String(
                                              audioModel.get(index).value)])
                    }
                    opacity: 1
                }
                Text {
                    id: subLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: "Subtitles"
                    color: "white"
                    font.family: notoFont.name
                    font.pixelSize: 14
                    anchors.top: audioList.bottom
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 1
                }
                ComboBox {
                    id: subList
                    textRole: "key"
                    anchors.top: subLabel.bottom
                    model: ListModel {
                        id: subModel
                    }
                    onActivated: {
                        renderer.command(["set", "sid", String(
                                              subModel.get(index).value)])
                    }
                    opacity: 1
                }
                Text {
                    id: vidLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: "Video"
                    color: "white"
                    font.family: notoFont.name
                    font.pixelSize: 14
                    anchors.top: subList.bottom
                    renderType: Text.NativeRendering
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 1
                }
                ComboBox {
                    id: vidList
                    textRole: "key"
                    anchors.top: vidLabel.bottom
                    model: ListModel {
                        id: vidModel
                    }
                    onActivated: {
                        renderer.command(["set", "vid", String(
                                              vidModel.get(index).value)])
                    }
                    opacity: 1
                }
            }

            Slider {
                id: progressBar
                to: 1
                value: 0.0
                palette.dark: "#f00"
                anchors.bottom: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottomMargin: 0

                bottomPadding: 0

                onMoved: {
                    renderer.command(["seek", progressBar.value, "absolute"])
                }

                background: Rectangle {
                    id: progressBackground
                    x: progressBar.leftPadding
                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                    implicitHeight: (renderer.height / 256) < 2 ? 2 : renderer.height / 256
                    width: progressBar.availableWidth
                    height: implicitHeight
                    color: Qt.rgba(255, 255, 255, 0.4)

                    Rectangle {
                        width: progressBar.visualPosition * parent.width
                        height: parent.height
                        color: "red"
                        opacity: 1
                    }
                }

                handle: Rectangle {
                    x: progressBar.leftPadding + progressBar.visualPosition
                       * (progressBar.availableWidth - width)
                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: 12
                    color: "red"
                    border.color: "red"
                }
            }

            Button {
                id: playlistPrevButton
                icon.name: "prev"
                icon.source: "icons/prev.svg"
                icon.color: "white"
                display: AbstractButton.IconOnly
                visible: false
                width: 0
                onClicked: {
                    renderer.command(["playlist-prev"])
                    updatePrev()
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            Button {
                id: playPauseButton
                icon.name: "pause"
                icon.source: "icons/pause.svg"
                icon.color: "white"
                display: AbstractButton.IconOnly
                anchors.left: playlistPrevButton.right
                onClicked: {
                    updatePlayPause()
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            Button {
                id: playlistNextButton
                icon.name: "next"
                icon.source: "icons/next.svg"
                icon.color: "white"
                display: AbstractButton.IconOnly
                anchors.left: playPauseButton.right
                onClicked: {
                    renderer.command(["playlist-next", "force"])
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            Button {
                id: volumeButton
                icon.name: "volume-up"
                icon.source: "icons/volume-up.svg"
                icon.color: "white"
                display: AbstractButton.IconOnly
                anchors.left: playlistNextButton.right
                onClicked: {
                    renderer.command(["cycle", "mute"])
                    updateVolume()
                }
                background: Rectangle {
                    color: "transparent"
                }
            }
            Slider {
                id: volumeBar
                to: 100
                value: 100
                palette.dark: "#f00"

                implicitWidth: Math.max(
                                   background ? background.implicitWidth : 0,
                                                (handle ? handle.implicitWidth : 0)
                                                + leftPadding + rightPadding)
                implicitHeight: Math.max(
                                    background ? background.implicitHeight : 0,
                                                 (handle ? handle.implicitHeight : 0)
                                                 + topPadding + bottomPadding)

                anchors.left: volumeButton.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                onMoved: {
                    renderer.command(["set", "volume", Math.round(
                                          volumeBar.value).toString()])
                    updateVolume()
                }

                handle: Rectangle {
                    x: volumeBar.leftPadding + volumeBar.visualPosition
                       * (volumeBar.availableWidth - width)
                    y: volumeBar.topPadding + volumeBar.availableHeight / 2 - height / 2
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: 12
                    color: "#f6f6f6"
                    border.color: "#f6f6f6"
                }

                background: Rectangle {
                    x: volumeBar.leftPadding
                    y: volumeBar.topPadding + volumeBar.availableHeight / 2 - height / 2
                    implicitWidth: 60
                    implicitHeight: 3
                    width: volumeBar.availableWidth
                    height: implicitHeight
                    color: "#33333311"
                    Rectangle {
                        width: volumeBar.visualPosition * parent.width
                        height: parent.height
                        color: "white"
                    }
                }
            }

            Text {
                id: timeLabel
                text: "0:00 / 0:00"
                color: "white"
                anchors.left: volumeBar.right
                anchors.bottom: parent.bottom
                anchors.top: parent.top
                padding: 5
                font.family: notoFont.name
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
            }

            Button {
                id: subtitlesButton
                icon.name: "subtitles"
                icon.source: "icons/subtitles.svg"
                icon.color: "white"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                anchors.right: settingsButton.left
                display: AbstractButton.IconOnly
                onClicked: {
                    tracksMenuUpdate()
                    subtitlesMenu.visible = !subtitlesMenu.visible
                    subtitlesMenuBackground.visible = !subtitlesMenuBackground.visible
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            Button {
                id: settingsButton
                icon.name: "settings"
                icon.source: "icons/settings.svg"
                icon.color: "white"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                anchors.right: fullscreenButton.left
                display: AbstractButton.IconOnly
                onClicked: {
                    loadDialog.open()
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            Button {
                id: fullscreenButton
                icon.name: "fullscreen"
                icon.source: "icons/fullscreen.svg"
                icon.color: "white"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                anchors.right: parent.right
                display: AbstractButton.IconOnly
                onClicked: {
                    if (mainWindow.visibility != Window.FullScreen) {
                        lastScreenVisibility = mainWindow.visibility
                        mainWindow.visibility = Window.FullScreen
                    } else {
                        mainWindow.visibility = lastScreenVisibility
                    }
                }

                background: Rectangle {
                    color: "transparent"
                }
            }

            //}
        }
    }
}
