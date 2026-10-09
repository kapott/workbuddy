// One notification popup, drawn the way mako's config drew it: a 2px border
// coloured by urgency, the app's image or icon on the left, summary over body.
//
// Left click runs the default action if the app offered one, then dismisses.
// Right click dismisses every popup, as mako's on-button-right did. Other
// actions are buttons under the body. The timeout stops while the pointer is
// over the card, so a long body can be read to the end.

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: card

    required property var modelData
    readonly property var notification: card.modelData

    readonly property var buttons: card.notification.actions.filter(a => a.identifier !== "default")
    readonly property string picture: card.notification.image
        || (card.notification.appIcon ? Quickshell.iconPath(card.notification.appIcon, true) : "")

    implicitHeight: body.implicitHeight + Theme.padding * 2
    radius: Theme.menuRadius - 2
    color: Theme.background
    border.width: 2
    border.color: card.notification.urgency === NotificationUrgency.Critical ? Theme.red
        : card.notification.urgency === NotificationUrgency.Low ? Theme.dim
        : Theme.yellow

    Timer {
        interval: Notifications.timeoutMs(card.notification)
        running: interval > 0 && !hover.containsMouse
        onTriggered: card.notification.expire()
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                return Notifications.dismissAll();
            card.notification.actions.find(a => a.identifier === "default")?.invoke();
            card.notification.dismiss();
        }
    }

    Row {
        id: body
        x: Theme.padding
        y: Theme.padding
        width: parent.width - Theme.padding * 2
        spacing: Theme.padding

        IconImage {
            id: image
            visible: card.picture !== ""
            source: card.picture
            implicitSize: Theme.notificationImageSize
        }

        Column {
            width: parent.width - (image.visible ? image.width + Theme.padding : 0)
            spacing: 2

            Text {
                width: parent.width
                text: card.notification.summary || card.notification.appName
                elide: Text.ElideRight
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                font.bold: true
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: card.notification.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: Theme.notificationBodyLines
                elide: Text.ElideRight
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
            }

            Row {
                visible: card.buttons.length > 0
                spacing: Theme.gap
                topPadding: Theme.gap

                Repeater {
                    model: card.buttons

                    Rectangle {
                        required property var modelData
                        width: label.implicitWidth + Theme.padding * 2
                        height: label.implicitHeight + Theme.gap * 2
                        radius: 4
                        color: buttonArea.containsMouse ? Theme.dim : Theme.raised

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                        }

                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                modelData.invoke();
                                card.notification.dismiss();
                            }
                        }
                    }
                }
            }
        }
    }
}
