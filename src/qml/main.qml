import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 800
    height: 1000
    title: qsTr("Microfluidics control system")

    property bool darkMode: false
    Material.theme: darkMode ? Material.Dark : Material.Light

    SwipeView {
        id: swipeView
        padding: 20
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        ManualControl{
            id: manualControlView
        }

        RoutineControl {
            id: routineControlView
        }

        LogScreen {
            id: logScreenView
        }
    }

    footer: TabBar {
        id: tabBar
        currentIndex: swipeView.currentIndex
        TabButton {
            text: qsTr("Manual control")
        }

        TabButton {
            text: qsTr("Routines")
        }

        TabButton {
            text: qsTr("Log")
        }
    }

    Component.onCompleted: {
        console.info("Application version: " + Backend.appVersion)
        console.info("Writing to log file at: " + Backend.logFilePath)
    }
}
