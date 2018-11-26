#include "applicationcontroller.h"
#include "guihelper.h"

void ApplicationController::messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{

    QString date = QDateTime::currentDateTime().toString("yyyy-MM-dd");
    QString time = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");

    QString messageType;
    QString message;

    switch (type) {
    case QtDebugMsg:
        messageType  = "Debug";
        message = msg;
        break;
    case QtInfoMsg:
        messageType  = "Info";
        message = msg;
        break;
    case QtWarningMsg:
        messageType  = "Warning";
        message = msg;
        break;
    case QtCriticalMsg:
        messageType  = "Critical error";
        message = QString("%1 (%2:%3, %4)").arg(msg).arg(context.file).arg(context.line).arg(context.function);
        break;
    case QtFatalMsg:
        messageType  = "Fatal error";
        message = QString("%1 (%2:%3, %4)").arg(msg).arg(context.file).arg(context.line).arg(context.function);
        break;
    }

    QString text = date + " " + time + " " + messageType + ": " + message + "\n";

    QByteArray b = text.toLocal8Bit();
    fprintf(stderr, b.constData());
    fflush(stderr); // Force output to be printed right away

    QFile logFile(appController()->logFilePath());
    if (logFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
        QTextStream ts(&logFile);
        ts << text;
    }

    // Logs are stored in a fragmented way to make rich markup easier in QML.
    // Date is omitted since not particularly useful within the app
    QStringList toAdd;
    toAdd << time << messageType << message;
    appController()->addToLog(toAdd);
}

ApplicationController* singleton = nullptr;

ApplicationController* ApplicationController::appController()
{
    if (singleton == nullptr) {
        singleton = new ApplicationController();
    }
    return singleton;
}

ApplicationController::ApplicationController(QObject *parent) : QObject(parent)
{
    // Initialize mCommunicator. Can be either USB ("Serial") or Bluetooth. Windows
    // doesn't support Bluetooth, and Android doesn't support serial over USB (at least,
    // not without rooting your phone), so we can set defaults for those platforms.
    // For other platforms, use whichever one you prefer.
    // This has to be specified at compile time for now; run-time switching may be supported later.

#if defined(Q_OS_WIN)
    mCommunicator = new SerialCommunicator();
#elif defined(Q_OS_ANDROID)
    mCommunicator = new BluetoothCommunicator();
#else
    mCommunicator = new SerialCommunicator();
#endif

    QObject::connect(mCommunicator, &Communicator::valveStateChanged, this, &ApplicationController::onValveStateChanged);
    QObject::connect(mCommunicator, &Communicator::pressureChanged, this, &ApplicationController::onPressureChanged);
    //QObject::connect(mCommunicator, &Communicator::pumpStateChanged, this, &ApplicationController::onPumpStateChanged);
    QObject::connect(mCommunicator, &Communicator::connectionStatusChanged, this, &ApplicationController::onCommunicatorStatusChanged);

    mRoutineController = new RoutineController(mCommunicator); // TODO: check if this is really the best way to do this (a singleton may be better)

    mLogFilePath = "log_" + QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm-ss") + ".txt";

    // This is used by mSettings
    QCoreApplication::setApplicationName("ufcs-pc");
    QCoreApplication::setOrganizationName("Watsaig");
    QCoreApplication::setOrganizationDomain("watsaig.com");
    mSettings = new QSettings();
}

ApplicationController::~ApplicationController()
{
    delete mRoutineController;
    delete mCommunicator;
}

QString ApplicationController::connectionStatus()
{
    return mCommunicator->getConnectionStatusString();
}

void ApplicationController::connect()
{
    mCommunicator->connect();
}

void ApplicationController::registerPCHelper(int controllerNumber, PCHelper* instance)
{
    mQmlPressureControllers[controllerNumber] = instance;
}

void ApplicationController::registerValveSwitchHelper(int valveNumber, ValveSwitchHelper* instance)
{
    mQmlValveSwitches[valveNumber] = instance;
}

/**
 * @brief Add a message to the (internal) log, for access within the application.
 * @param entry A QStringList (or compatible type) with 3 elements: time, message type and message text.
 *
 * This log is only for access within the application. It is separate from the messages logged to file.
 * See ApplicationController::messageHandler for the rest of the logging code.
 */
void ApplicationController::addToLog(QVariant entry)
{
    mLog.append(entry);
    emit newLogMessage(entry);
}

void ApplicationController::onValveStateChanged(int valveNumber, bool open)
{
    qInfo() << "Valve" << valveNumber << (open ? "opened" : "closed");

    if (mQmlValveSwitches.contains(valveNumber))
        mQmlValveSwitches[valveNumber]->setState(open);
}

void ApplicationController::onPumpStateChanged(int pumpNumber, bool on)
{
    Q_UNUSED(pumpNumber)
    Q_UNUSED(on)

    // Not used for now, probably not necessary
}

void ApplicationController::onPressureChanged(int controllerNumber, double pressure)
{
    //qInfo() << "Measured pressure (normalized) on controller" << controllerNumber << ":" << pressure;
    if (mQmlPressureControllers.contains(controllerNumber))
        mQmlPressureControllers[controllerNumber]->setMeasuredValue(pressure);
}

void ApplicationController::onCommunicatorStatusChanged(Communicator::ConnectionStatus newStatus)
{
    qDebug() << "App controller: communicator status changed to" << mCommunicator->getConnectionStatusString();

    if (newStatus == Communicator::Connected)
        mCommunicator->refreshAll();

    emit connectionStatusChanged(mCommunicator->getConnectionStatusString());
}
