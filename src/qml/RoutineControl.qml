import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Material 2.12

import QtQml.StateMachine 1.0 as DSM

import org.example.ufcs 1.0 // for the Style singleton

/*
  Graphical interface for the routine controller C++ backend.


  The interface is described by a finite state machine: different user actions (or backend actions)
  cause a state change, which results in different elements being displayed.

  Some of the graphical elements (such as the title and description text boxes) are re-used between different states,
  while some are used only by one specific state.


  TODO ? Ascii diagram of the state machine
*/

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 50
        anchors.leftMargin: Style.view.margin
        anchors.rightMargin: anchors.leftMargin

        Label {
            id: title
            visible: false
            text: qsTr("Title")
            Layout.alignment: Qt.AlignHCenter

            font.pointSize: Style.title.fontSize
            padding: Style.title.padding
        }

        Label {
            id: description
            visible: false
            text: qsTr("This description field gives more information to the user about the current state of execution.")
            Layout.alignment: Qt.AlignHCenter
        }

        Switch {
            id: runForeverSwitch
            visible: false
            text: qsTr("Run continuously")
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            id: stepCounter
            visible: false
            Layout.alignment: Qt.AlignHCenter

            text : "Step " +  (RoutineController.currentStep + 1 ) + " of " + RoutineController.numberOfSteps()
        }

        Label {
            id: runTime
            visible: false
            Layout.alignment: Qt.AlignHCenter
            text: "Estimated run time: " + RoutineController.totalRunTime + " seconds";
        }


    // add a scrolling text box, to show the current step (and previous and following 1-2 steps)

        ListView {
            id: stepsList
            visible: false
            width: parent.width
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            model: RoutineController.stepsList
            currentIndex: RoutineController.currentStep

            delegate: Rectangle {
                height: delegateText.contentHeight
                width: parent.width
                color: "transparent"

                Text {
                    id: delegateText
                    text: modelData

                    font.pointSize: 10
                    font.bold: RoutineController.currentStep == index
                    color: RoutineController.currentStep == index ? Material.foreground : "gray"
                }
            }
        }

        ListView {
            id: errorList
            visible: false
            width: parent.width
            Layout.fillHeight: true
            model: RoutineController.errorList
            delegate: Rectangle {
                height: 25
                width: 100
                Text { text: modelData }
            }

            Layout.alignment: Qt.AlignHCenter

            /*
            Connections {
                target: RoutineController
                onError: {
                    errorList.model = RoutineController.errorList
                    console.log("New error received")
                }
            }
            */
        }

        Button {
            id: browseButton
            visible: false
            text: "Browse"
            Layout.alignment: Qt.AlignHCenter
            onClicked: fileDialog.open()
        }

        Button {
            id: returnToHomeButton
            visible: false
            text: "OK"
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            id: runButton
            visible: false
            text: "Run routine"
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            id: pauseButton
            visible: false
            text: "Pause routine"
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            id: resumeButton
            visible: false
            text: "Resume"
            Layout.alignment: Qt.AlignHCenter
        }

		Button {
		    id: stopButton
			visible: false
			text: "Stop routine"
			Layout.alignment: Qt.AlignHCenter
		}

        ColumnLayout {
            id: runYesNoButtons
            visible: false

            Layout.alignment: Qt.AlignHCenter

            Label {
                text: "Would you still like to run the routine?"
            }

            RowLayout {

                Button {
                    id: yes
                    text: "Yes"
                    padding: 12
                }

                Button {
                    id: no
                    text: "No"
                    padding: 12
                }
            }
        }
}

DSM.StateMachine {
    id: stateMachine
    initialState: noFileLoaded
    running: true

    DSM.State {
        id: noFileLoaded
        onEntered: {
            console.log("Routine UI: Entered state 'noFileLoaded'")
            title.text = "Load routine"
            description.text = "Choose a file to run"
            title.visible = true
            description.visible = true
            browseButton.visible = true
        }

        onExited: {
            title.text = ""
            title.visible = false
            description.text = ""
            description.visible = false
            browseButton.visible = false
        }

        DSM.SignalTransition {
            targetState: checkingRoutine
            signal: fileDialog.fileOpened
        }

    }

    DSM.State {
        id: checkingRoutine
        property int nErrors

        signal noErrorsFound
        signal errorsFound

        onEntered: {
            console.log("Routine UI: Entered state 'checkingRoutine'")
            description.text = "Checking routine for errors..."
            description.visible = true

            if (RoutineController.verify() > 0)
                errorsFound()
            else
                noErrorsFound()
        }

        onExited: {
            description.text = ""
            description.visible = false
        }

        DSM.SignalTransition {
            targetState: routineLoadedSuccessfully
            signal: checkingRoutine.noErrorsFound
        }

        DSM.SignalTransition {
            targetState: routineLoadedWithErrors
            signal: checkingRoutine.errorsFound
        }

    }

    DSM.State {
        id: routineLoadedSuccessfully

        onEntered: {
            console.log("Routine UI: Entered state 'routineLoadedSuccessfully'")
            title.text = "Routine loaded"
            title.visible = true
            description.text = "The routine was loaded successfully. Click below to launch it."
            description.visible = true
            runTime.visible = true
            stepsList.visible = true
            runButton.visible = true
            returnToHomeButton.visible = true
            returnToHomeButton.text = "Cancel"
        }

        onExited: {
            description.visible = false
            runTime.visible = false
            runButton.visible = false
            stepsList.visible = false
            returnToHomeButton.text = "OK"
            returnToHomeButton.visible = false
        }

        DSM.SignalTransition {
            targetState: beginRoutine
            signal: runButton.clicked
        }

        DSM.SignalTransition {
            targetState: noFileLoaded
            signal: returnToHomeButton.clicked
        }
    }

    DSM.State {
        id: routineLoadedWithErrors

        onEntered: {
            console.log("Routine UI: Entered state 'routineLoadedWithErrors'")

            title.text = RoutineController.numberOfErrors() + " errors found"
            title.visible = true

            description.text = "The routine was loaded, but some errors were detected:"
            description.visible = true

            errorList.visible = true
            runYesNoButtons.visible = true
        }
        onExited: {
            title.visible = false
            description.visible = false
            errorList.visible = false
            runYesNoButtons.visible = false
        }

        DSM.SignalTransition {
            targetState: beginRoutine
            signal: yes.clicked
        }
        DSM.SignalTransition {
            targetState: noFileLoaded
            signal: no.clicked
        }
    }

    DSM.State {
        id: beginRoutine
        // This state simply starts the routine then switches to "runningRoutine"
        signal routineStarted
        onEntered: {
            console.log("Routine UI: Entered state 'beginRoutine'")

            RoutineController.begin()
            routineStarted();
        }

        DSM.SignalTransition {
            targetState: runningRoutine
            signal: beginRoutine.routineStarted
        }
    }

    DSM.State {
        id: runningRoutine


        onEntered: {
            console.log("Routine UI: Entered state 'runningRoutine'")
            // get name of routine from backend
            title.text = "Running routine: " + RoutineController.routineName()
            title.visible = true
            stepCounter.visible = true
            stepsList.visible = true
            runForeverSwitch.visible = true
            pauseButton.visible = true
            stopButton.visible = true

        }

        onExited: {
            title.visible = false
            description.visible = false
            stepCounter.visible = false
            runForeverSwitch.visible = false
            stopButton.visible = false
            pauseButton.visible = false
        }

        DSM.SignalTransition {
            targetState: finishedRunning
            signal: RoutineController.finished
        }

        DSM.SignalTransition {
            targetState: routinePaused
            signal: RoutineController.paused
        }

        Connections {
            target: stopButton
            onClicked: {
                console.log("Routine UI: stop requested")
                title.text = "Stop requested"
                description.visible = true
                description.text = "Routine will end after current step"
                runForeverSwitch.checked = false
                runForeverSwitch.visible = false
                stopButton.visible = false
                pauseButton.visible = false
                // RoutineController then emits finished signal, to transition to next state
                RoutineController.stop()
            }
        }

        Connections {
            target: pauseButton
            onClicked: {
                console.log("Routine UI: pause requested")
                title.text = "Pause requested"
                description.text = "Routine will pause after the current step"
                description.visible = true
                RoutineController.pause()
                pauseButton.visible = false
            }
        }

    }

    DSM.State {
        id: routinePaused
        onEntered: {
            console.log("Routine UI: Entered state 'routinePaused'");
            title.text = "Routine paused"
            description.text = "Routine execution paused by user"
            title.visible = true
            description.visible = true
            resumeButton.visible = true
        }

        Connections {
            target: resumeButton
            onClicked: {
                console.log("Routine UI: resume requested")
                RoutineController.resume()
                description.visible = false
                resumeButton.visible = false
            }
        }

        DSM.SignalTransition {
            targetState: runningRoutine
            signal: RoutineController.resumed
        }

    }

    DSM.State {
        id: finishedRunning
        signal restartRoutine

        onEntered: {
            if (runForeverSwitch.checked) {
                console.log("Routine restarting automatically")
                restartRoutine()
            }

            console.log("Routine UI: Entered state 'finishedRunning'")
            title.text = "Finished"
            title.visible = true
            description.text = "The execution of the routine has ended."
            description.visible = true
            returnToHomeButton.visible = true
            runButton.visible = true
            runButton.text = "Re-run"
        }

        onExited: {
            title.visible = false
            description.visible = false
            returnToHomeButton.visible = false
            runButton.visible = false
            runButton.text = "Run"
            stepsList.visible = false
        }

        DSM.SignalTransition {
            targetState: noFileLoaded
            signal: returnToHomeButton.clicked
        }

        DSM.SignalTransition {
            targetState: beginRoutine
            signal: runButton.clicked
        }

        DSM.SignalTransition {
            targetState: beginRoutine
            signal: finishedRunning.restartRoutine
        }
    }
}

    FileDialog {
        id: fileDialog
        title: "Please choose a file"
        folder: Backend.loadRoutineFolder()
        selectMultiple: false
        visible: false
        onAccepted: {
            Backend.saveRoutineFolder(folder)
            if (RoutineController.loadFile(fileUrl))
                fileOpened()
            else {
                description.text = "The selected file could not be opened. Check that you have read permissions on the file, and try again."
            }
        }

        signal fileOpened ()
    }

}
