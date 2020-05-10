import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Material.impl 2.12

import org.example.ufcs 1.0

Item {
    id: control
    property int valveNumber

    property color normalColor: "#e60000"
    property color highlightedColor: "#d10000"

    // True if user can edit the label
    property bool editable: false

    implicitHeight: dense ? 55 : 70
    implicitWidth: dense ? 80 : 100
    Layout.fillWidth: true

    property bool dense : Backend.denseThemeEnabled

    Button {
        id: button
        text: valveNumber
        focusPolicy: Qt.ClickFocus
        autoRepeat: false
        display: AbstractButton.IconOnly // don't display the "text" property on the button
        anchors.fill: parent

        checkable: true
        checked: false

        enabled: !control.editable && Backend.connectionStatus == "Connected"

        onClicked: Backend.setValve(valveNumber, checked);
    }

    Text {
        id: element
        text: valveNumber

        anchors.top: control.top
        anchors.topMargin: dense ? 10 : 12
        anchors.horizontalCenter: control.horizontalCenter

        horizontalAlignment: Text.AlignHCenter
        font.pointSize: dense ? 6 : 8
        color: button.enabled ? Material.primaryTextColor : Material.hintTextColor
    }

    Rectangle {
        id: textInputBackground
        anchors.fill: textInput
        color: Material.backgroundColor
        visible: control.editable
    }

    TextInput {
        id: textInput
        width: control.width - 6
        height: 20

        anchors.horizontalCenter: control.horizontalCenter
        anchors.bottom: control.bottom
        anchors.bottomMargin: 12
        text: qsTr("Input label")

        selectByMouse: control.editable
        enabled: control.editable

        font.pointSize: dense ? 6 : 8
        autoScroll: false
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        color: button.enabled ? Material.primaryTextColor : Material.hintTextColor

        // To do: a better implementation of this where the max. width is set
        maximumLength: Math.max(12, width / fontMetrics.averageCharacterWidth)

        FontMetrics {
            id: fontMetrics
            font: textInput.font
        }

        onEditingFinished: {
            // Surrender focus to hide the editing cursor
            control.focus = true
        }

        onTextEdited: {
            Backend.setValveLabel(valveNumber, text);
        }

    }

    ValveSwitchHelper {
        id: helper
        onStateChanged: button.checked = state
    }

    Component.onCompleted: {
        helper.valveNumber = valveNumber
        textInput.text = Backend.valveLabel(valveNumber);
    }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:4}D{i:2;flowX:"-563";flowY:"-64"}D{i:3;flowX:"-93.75";flowY:3.25}
D{i:4;flowX:"-93.75";flowY:3.25}
}
##^##*/
