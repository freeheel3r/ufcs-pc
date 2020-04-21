import QtQuick 2.12
import QtQuick.Controls 2.12

import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12

import org.example.ufcs 1.0 // for the Style singleton

Item {
    Layout.preferredHeight: button1.height

    property int h: 60
    property int w: h*1.2
    RowLayout {
        id: multiplexerButtons
        anchors.fill: parent

        Button {
            id: button1
            text: "1"
            autoExclusive: true
            checkable: true
            enabled: Backend.connectionStatus == "Connected"
            onClicked: Backend.setMultiplexer(1)

            Layout.preferredHeight: h
            Layout.preferredWidth: w
        }

        Button {
            text: "2"
            autoExclusive: true
            checkable: true
            enabled: Backend.connectionStatus == "Connected"
            onClicked: Backend.setMultiplexer(2)

            Layout.preferredHeight: h
            Layout.preferredWidth: w
        }
        Button {
            text: "3"
            autoExclusive: true
            checkable: true
            enabled: Backend.connectionStatus == "Connected"
            onClicked: Backend.setMultiplexer(3)

            Layout.preferredHeight: h
            Layout.preferredWidth: w
        }
        Button {
            text: "4"
            autoExclusive: true
            checkable: true
            enabled: Backend.connectionStatus == "Connected"
            onClicked: Backend.setMultiplexer(4)

            Layout.preferredHeight: h
            Layout.preferredWidth: w
        }
        Button {
            text: "5"
            autoExclusive: true
            checkable: true
            enabled: Backend.connectionStatus == "Connected"
            onClicked: Backend.setMultiplexer(5)

            Layout.preferredHeight: h
            Layout.preferredWidth: w
        }
        Button {
            text: "6"
            autoExclusive: true
            checkable: true
            enabled: Backend.connectionStatus == "Connected"
            onClicked: Backend.setMultiplexer(6)

            Layout.preferredHeight: h
            Layout.preferredWidth: w
        }
        Button {
            text: "7"
            autoExclusive: true
            checkable: true
            enabled: Backend.connectionStatus == "Connected"
            onClicked: Backend.setMultiplexer(7)

            Layout.preferredHeight: h
            Layout.preferredWidth: w
        }
        Button {
            text: "8"
            autoExclusive: true
            checkable: true
            enabled: Backend.connectionStatus == "Connected"
            onClicked: Backend.setMultiplexer(8)

            Layout.preferredHeight: h
            Layout.preferredWidth: w
        }
    }
}
