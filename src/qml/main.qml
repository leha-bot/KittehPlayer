import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.11
import QtQuick.Window 2.11
import player 1.0

import "codes.js" as LanguageCodes

Window {
    id: mainWindow
    title: titleLabel.text
    visible: true
    width: 720
    height: 480

    property int lastScreenVisibility

    function toggleFullscreen() {
        if (mainWindow.visibility != Window.FullScreen) {
            lastScreenVisibility = mainWindow.visibility
            mainWindow.visibility = Window.FullScreen
        } else {
            mainWindow.visibility = lastScreenVisibility
        }
    }

    function updatePlayPauseIcon() {
        var paused = player.getProperty("pause")
        if (paused) {
            playPauseButton.icon.source = "qrc:/player/icons/play.svg"
        } else {
            playPauseButton.icon.source = "qrc:/player/icons/pause.svg"
        }
    }

    function updateVolume() {
        var muted = player.getProperty("mute")
        var volume = player.getProperty("volume")

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
        var playlist_pos = player.getProperty("playlist-pos")
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
        player.command(["cycle", "pause"])
        updatePlayPauseIcon()
    }

    function setSubtitle(sub) {
        console.log(sub)
    }

    function tracksMenuUpdate() {
        var tracks = player.getProperty("track-list/count")
        var track = 0
        subModel.clear()
        audioModel.clear()
        vidModel.clear()

        var aid = player.getProperty("aid")
        var sid = player.getProperty("sid")
        var vid = player.getProperty("vid")

        console.log("Updating Track Menu, Total Tracks: " + tracks)
        for (track = 0; track <= tracks; track++) {
            var trackID = player.getProperty("track-list/" + track + "/id")
            var trackType = player.getProperty(
                        "track-list/" + track + "/type")
            var trackLang = LanguageCodes.localeCodeToEnglish(
                        String(player.getProperty(
                                   "track-list/" + track + "/lang")))
            var trackTitle = player.getProperty(
                        "track-list/" + track + "/title")
            if (trackType == "sub") {
                subModel.append({
                                    key: trackLang,
                                    value: trackID
                                })
                if (player.getProperty("track-list/" + track + "/selected")) {
                    subList.currentIndex = subList.count
                }
            } else if (trackType == "audio") {
                audioModel.append({
                                      key: (trackTitle === undefined ? "" : trackTitle + " ")
                                           + trackLang,
                                      value: trackID
                                  })
                if (player.getProperty("track-list/" + track + "/selected")) {
                    audioList.currentIndex = audioList.count
                }
            } else if (trackType == "video") {
                vidModel.append({
                                    key: "Video " + trackID,
                                    value: trackID
                                })
                if (player.getProperty("track-list/" + track + "/selected")) {
                    vidList.currentIndex = vidList.count
                }
            }
        }
    }

    MpvObject {
        id: player
        anchors.fill: parent

        FontLoader {
            id: notoFont
            source: "fonts/NotoSans.ttf"
        }

        Timer {
            id: initTimer
            interval: 2000
            running: false
	    repeat: false
            onTriggered: {
		player.startPlayer()
            }
        }
        Component.onCompleted: { initTimer.start() }

        function startPlayer() {
            var args = Qt.application.arguments
            var len = Qt.application.arguments.length
            var argNo = 0
            player.setOption("ytdl-format", "bestvideo[width<=" + Screen.width
                               + "][height<=" + Screen.height + "]+bestaudio")
            if (len > 1) {
                for (argNo = 1; argNo < len; argNo++) {
                    var argument = args[argNo]
		    if (argument.indexOf("KittehPlayer") !== -1) { continue; } 
                    if (argument.startsWith("--")) {
                        argument = argument.substr(2)
                        if (argument.length > 0) {
                            var splitArg = argument.split(/=(.+)/)
                            if (splitArg[0] == "fullscreen") {
                                toggleFullscreen()
                            } else {
                                if (splitArg[1].length == 0) {
                                    splitArg[1] = "true"
                                }
                                player.setOption(splitArg[0], splitArg[1])
                            }
                        }
                    } else { 
                        player.command(["loadfile", argument])
                    }
                }
            }
        }

        function createTimestamp(d) {
            d = Number(d)
            var h = Math.floor(d / 3600)
            var m = Math.floor(d % 3600 / 60)
            var s = Math.floor(d % 3600 % 60)

            var hour = h > 0 ? h + ":" : ""
            var minute = m + ":"
            var second = s < 10 ? "0" + s : s
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
            titleLabel.text = player.getProperty("media-title")
        }

        function hideControls() {
	        if (! subtitlesMenu.visible) {
                player.setOption("sub-margin-y", "22")
                controlsBar.visible = false
                controlsBackground.visible = false
                titleBar.visible = false
                titleBackground.visible = false
            }
        }

        function showControls() {
            updateControls()
            player.setOption("sub-margin-y",
                               String(controlsBar.height + progressBar.height))
            controlsBar.visible = true
            controlsBackground.visible = true
            titleBar.visible = true
            titleBackground.visible = true
        }

        FileDialog {
            id: fileDialog
            title: "Please choose a file"
            folder: shortcuts.home
            onAccepted: {
                player.command(["loadfile", String(fileDialog.fileUrl)])
                fileDialog.close()
            }
            onRejected: {
                fileDialog.close()
            }
        }

        Dialog {
            id: loadDialog
            title: "URL / File Path"
            standardButtons: StandardButton.Cancel | StandardButton.Open
            onAccepted: {
               player.command(["loadfile", pathText.text])
               pathText.text = ""
	    }
            TextField {
                id: pathText
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
            onClicked: {
                player.command(["cycle", "pause"])
                updateControls()
            }
            onDoubleClicked: {
                fileDialog.open()
            }
            Timer {
                id: mouseAreaPlayerTimer
                interval: 1000
                running: false
                repeat: false
                onTriggered: {
                    player.hideControls()
                }
            }
            onPositionChanged: {
                player.showControls()
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
            height: Screen.height / 24
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
            height: Screen.height / 24
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
                        player.command(["set", "aid", String(
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
                        player.command(["set", "sid", String(
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
                        player.command(["set", "vid", String(
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
                anchors.topMargin: progressBackground.height + handleRect.height

                bottomPadding: 0

                onMoved: {
                    player.command(["seek", progressBar.value, "absolute"])
                }

                background: Rectangle {
                    id: progressBackground
                    x: progressBar.leftPadding
                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                    implicitHeight: (Screen.height / 256) < 2 ? 2 : Screen.height / 256
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
                    id: handleRect
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
                //icon.name: "prev"
                icon.source: "icons/prev.svg"
                icon.color: "white"
                display: AbstractButton.IconOnly
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                visible: false
                width: 0
                onClicked: {
                    player.command(["playlist-prev"])
                    updatePrev()
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            Button {
                id: playPauseButton
                //icon.name: "pause"
                icon.source: "icons/pause.svg"
                icon.color: "white"
                display: AbstractButton.IconOnly
                anchors.top: parent.top
                anchors.bottom: parent.bottom
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
                //icon.name: "next"
                icon.source: "icons/next.svg"
                icon.color: "white"
                display: AbstractButton.IconOnly
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: playPauseButton.right
                onClicked: {
                    player.command(["playlist-next", "force"])
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            Button {
                id: volumeButton
                //icon.name: "volume-up"
                icon.source: "icons/volume-up.svg"
                icon.color: "white"
                display: AbstractButton.IconOnly
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: playlistNextButton.right
                onClicked: {
                    player.command(["cycle", "mute"])
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
                    player.command(["set", "volume", Math.round(
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
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                padding: 5
                font.family: notoFont.name
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
            }

            Button {
                id: subtitlesButton
                //icon.name: "subtitles"
                icon.source: "icons/subtitles.svg"
                icon.color: "white"
                anchors.right: settingsButton.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
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
                //icon.name: "settings"
                icon.source: "icons/settings.svg"
                icon.color: "white"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                anchors.right: fullscreenButton.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
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
                //icon.name: "fullscreen"
                icon.source: "icons/fullscreen.svg"
                icon.color: "white"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                display: AbstractButton.IconOnly
                onClicked: {
                    toggleFullscreen()
                }

                background: Rectangle {
                    color: "transparent"
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: {
                if (event.key == Qt.Key_K || event.key == Qt.Key_Space) {
                    player.command(["cycle", "pause"])
                } else if (event.key == Qt.Key_J) {
                    player.command(["seek", "-10"])
                } else if (event.key == Qt.Key_L) {
                    player.command(["seek", "10"])
                }
                updateControls()
            }
        }
    }
}
