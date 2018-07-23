#include "bluetoothcommunicator.h"


BluetoothCommunicator::BluetoothCommunicator()
    : Communicator()
    , mSocket(NULL)
    , mServiceDiscoveryAgent(NULL)
    , mDeviceDiscoveryAgent(NULL)
{
}

BluetoothCommunicator::~BluetoothCommunicator()
{
    qDebug() << "deleting bluetoothCommunicator";

    // TODO: close and kill socket, if necessary
}


void BluetoothCommunicator::refreshAll()
{
    char toSend[2] = {(uint8_t)STATUS, (uint8_t)ALL_COMPONENTS};
    mSocket->write(toSend, 2);
}

/**
 * @brief Connect to the ESP32, if it's available
 *
 * This function searches for the ESP32 and connects to it, if possible.
 */
void BluetoothCommunicator::connect()
{
    setConnectionStatus(Connecting);
    qDebug() << "Searching for ESP32...";

    // There are two methods of discovering bluetooth devices. One discovers devices, and the other
    // discovers services. Both are useful to find the correct device; one then connects to it using
    // one of the three QBluetoothSocket::connectToService methods.

    // Service discovery requires the device to support SDP (advertising its available services). This
    // wasn't supported by the ESP32 at first, so device discovery was used instead. It now seems to have
    // been implemented, so service discovery can be used.

    // Service discovery is the preferred method, as it works on Linux as well as Android.

    initServiceDiscoveryAgent();

    qDebug() << "Starting service discovery...";
    mServiceDiscoveryAgent->setUuidFilter(QBluetoothUuid::SerialPort);
    mServiceDiscoveryAgent->start();

    /*
    initDeviceDiscoveryAgent();
    mDeviceDiscoveryAgent->start();
    */
}

/**
 * @brief Connect to the microcontroller, given the service information
 * @param serviceInfo ServiceInfo describing the Serial Port Profile to connect to.
 */
void BluetoothCommunicator::connect(const QBluetoothServiceInfo &serviceInfo)
{
    setConnectionStatus(Connecting);
    qDebug() << "Connecting to service...";

    initSocket();

    mSocket->connectToService(serviceInfo);
    qDebug() << "Connect to service done";
}

/**
 * @brief Connect to the microcontroller, given an address and port
 *
 * Note that this method does not work on Android. The serviceInfo method should be used instead.
 */
void BluetoothCommunicator::connect(const QBluetoothAddress &address, quint16 port)
{
    setConnectionStatus(Connecting);
    qDebug() << "Connecting to address" << address << ", port" << port;
    initSocket();

    mSocket->connectToService(address, port);
}

/**
 * @brief This slot should be called when data is ready on the serial port
 *
 * Data is communicated between the microcontroller and the PC in two-byte packets;
 * this function reads the received bytes and emits signals depending on what was received.
 * Since the microcontroller only communicates the status of the various hardware components,
 * the signals emitted can be `valveStateChanged`, `pumpStateChanged`, or `pressureChanged`.
 */
void BluetoothCommunicator::onSocketReady()
{
    //qDebug() << "Received" << mSocket->bytesAvailable() << "bytes on serial port";

    QByteArray buffer = mSocket->readAll();
    parseBuffer(buffer);
}

void BluetoothCommunicator::onSocketError(QBluetoothSocket::SocketError error)
{
    if (!mSocket)
        return;

    if (error != QBluetoothSocket::NoSocketError) {
        qWarning() << "Bluetooth socket error: " << mSocket->errorString();
    }
}

void BluetoothCommunicator::onSocketConnected()
{
    setConnectionStatus(Connected);
    qDebug() << "Socket connected";
}

void BluetoothCommunicator::onSocketDisconnected()
{
    setConnectionStatus(Disconnected);
    qDebug() << "Socket disconnected";
}

void BluetoothCommunicator::onServiceDiscovered(QBluetoothServiceInfo serviceInfo)
{
    /*
    qDebug() << "==============================================";
    qDebug() << "Discovered service on"
             << serviceInfo.device().name() << serviceInfo.device().address().toString();
    qDebug() << "\tService name:" << serviceInfo.serviceName();
    qDebug() << "\tDescription:"
             << serviceInfo.attribute(QBluetoothServiceInfo::ServiceDescription).toString();
    qDebug() << "\tProvider:"
             << serviceInfo.attribute(QBluetoothServiceInfo::ServiceProvider).toString();
    qDebug() << "\tL2CAP protocol service multiplexer:"
             << serviceInfo.protocolServiceMultiplexer();
    qDebug() << "\tRFCOMM server channel:" << serviceInfo.serverChannel();
    qDebug() << "==============================================";
    */

    if (serviceInfo.device().name() == "Microfluidics control system") {
        qDebug () << "Found microcontroller.";
        mService = serviceInfo;
    }
}

void BluetoothCommunicator::onServiceDiscoveryError(QBluetoothServiceDiscoveryAgent::Error error)
{
    Q_UNUSED(error)
    qWarning() << "Bluetooth connection error:" << mServiceDiscoveryAgent->errorString();
}

void BluetoothCommunicator::onServiceDiscoveryFinished()
{
    qDebug() << "Bluetooth service discovery finished. Connecting...";
    connect(mService);
}

void BluetoothCommunicator::onDeviceDiscovered(QBluetoothDeviceInfo deviceInfo)
{
    /*
    qDebug() << "-------------------------------------------------------------------------------";
    qDebug() << "Bluetooth device discovered:" << deviceInfo.name() << "(" << deviceInfo.address() << ")";
    qDebug() << "Device UUID:" << deviceInfo.deviceUuid();
    qDebug() << "Major device class:" << deviceInfo.majorDeviceClass();
    qDebug() << "Minor device class:" << deviceInfo.minorDeviceClass();
    qDebug() << "RSSI:" << deviceInfo.rssi();
    qDebug() << "Service classes:" << deviceInfo.serviceClasses();

    qDebug() << "Service UUIDs:";
    QList<QBluetoothUuid> uuids = deviceInfo.serviceUuids();
    foreach(QBluetoothUuid id, uuids) {
        qDebug() << id;
    }
    */

    if (deviceInfo.name() == "Microfluidics control system") {
        qDebug() << "Found control system; stopping discovery";
        mDeviceInfo = deviceInfo;
        mDeviceDiscoveryAgent->stop();
    }

}

void BluetoothCommunicator::onDeviceDiscoveryError(QBluetoothDeviceDiscoveryAgent::Error error)
{
    Q_UNUSED(error)
    qDebug() << "Device discovery error:" << mDeviceDiscoveryAgent->errorString();
}

void BluetoothCommunicator::onDeviceDiscoveryFinished()
{
    qDebug() << "Device discovery finished";
    if (mDeviceInfo.isValid())
        connect(mDeviceInfo.address(), 2); // TODO: detect which channel the SPP is actually on (can't currently check for that)
    else
        setConnectionStatus(Disconnected);

}

void BluetoothCommunicator::setComponentState(Component c, int val)
{
    if (mConnectionStatus == Disconnected) {
        qWarning() << "Can't set requested component state: device is disconnected";
        return; // TODO: (?) throw exception
    }
    //qDebug() << "setComponentState: setting component" << c << "to" << val;

    char toSend[2] = {(uint8_t)c, (uint8_t)val};
    mSocket->write(toSend, 2);
}

/**
 * @brief Initialize the bluetooth socket and connect signals & slots
 *
 * The socket handles all communication between the two devices, once they are connected.
 * Data is sent to the microcontroller using QBluetoothSocket::write; when data is received
 * from the microcontroller, the BluetoothCommunicator::onSocketReady slot is called.
 */
void BluetoothCommunicator::initSocket()
{
    if (!mSocket) {
        mSocket = new QBluetoothSocket(QBluetoothServiceInfo::RfcommProtocol);
        qDebug() << "Socket created";

        QObject::connect(mSocket, SIGNAL(connected()),
                         this, SLOT(onSocketConnected()));
        QObject::connect(mSocket, SIGNAL(disconnected()),
                         this, SLOT(onSocketDisconnected()));
        QObject::connect(mSocket, SIGNAL(readyRead()),
                         this, SLOT(onSocketReady()));
        QObject::connect(mSocket, SIGNAL(error(QBluetoothSocket::SocketError)),
                         this, SLOT(onSocketError(QBluetoothSocket::SocketError)));

    }
}

/**
 * @brief Initialize the bluetooth service discovery agent and connect signals & slots
 *
 * The service discovery agent searches for all available services. It is a more in-depth
 * search than the one carried out by the device discovery agent.
 *
 * Currently, it does not work as the ESP32 does not advertise is serial port profile service,
 * so the device discovery method should be used. This function may be removed soon.
 */
void BluetoothCommunicator::initServiceDiscoveryAgent()
{
    if (!mServiceDiscoveryAgent) {
        mServiceDiscoveryAgent = new QBluetoothServiceDiscoveryAgent();
        qDebug() << "Discovery agent created";

        QObject::connect(mServiceDiscoveryAgent, SIGNAL(serviceDiscovered(QBluetoothServiceInfo)),
                         this, SLOT(onServiceDiscovered(QBluetoothServiceInfo)));
        QObject::connect(mServiceDiscoveryAgent, SIGNAL(finished()), this, SLOT(onServiceDiscoveryFinished()));
        QObject::connect(mServiceDiscoveryAgent, SIGNAL(canceled()), this, SLOT(onServiceDiscoveryFinished()));
        QObject::connect(mServiceDiscoveryAgent, SIGNAL(error(QBluetoothServiceDiscoveryAgent::Error)),
                         this, SLOT(onServiceDiscoveryError(QBluetoothServiceDiscoveryAgent::Error)));

    }
}

/**
 * @brief Initialize the bluetooth device discovery agent and connect signals & slots
 *
 * The device discovery agent searches for devices, which can then be queried to obtain the
 * list of services that they offer. Every time a device is found, the deviceDiscovered signal is
 * emitted.
 */
void BluetoothCommunicator::initDeviceDiscoveryAgent()
{
    if (!mDeviceDiscoveryAgent) {
        mDeviceDiscoveryAgent = new QBluetoothDeviceDiscoveryAgent();
        qDebug() << "Device discovery agent created";

        QObject::connect(mDeviceDiscoveryAgent, SIGNAL(deviceDiscovered(QBluetoothDeviceInfo)),
                         this, SLOT(onDeviceDiscovered(QBluetoothDeviceInfo)));
        QObject::connect(mDeviceDiscoveryAgent, SIGNAL(error(QBluetoothDeviceDiscoveryAgent::Error)),
                         this, SLOT(onDeviceDiscoveryError(QBluetoothDeviceDiscoveryAgent::Error)));
        QObject::connect(mDeviceDiscoveryAgent, SIGNAL(finished()),
                         this, SLOT(onDeviceDiscoveryFinished()));
        QObject::connect(mDeviceDiscoveryAgent, SIGNAL(canceled()),
                         this, SLOT(onDeviceDiscoveryFinished()));

    }
}
