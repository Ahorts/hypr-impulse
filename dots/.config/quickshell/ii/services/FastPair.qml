pragma Singleton
pragma ComponentBehavior: Bound

import "fastPairAdverts.js" as Adverts
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

/**
 * Offers nearby unpaired Bluetooth devices for one-tap pairing, like Android's
 * Fast Pair. Drives modules/ii/fastPair/FastPairPopup.qml.
 *
 * Off by default: it keeps the adapter discovering for as long as nothing is
 * connected, which costs radio time and battery.
 */
Singleton {
    id: root

    readonly property var options: Config.options.bluetooth.fastPair
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter

    // Device currently being offered, and whether the card is up.
    property BluetoothDevice candidate: null
    property bool popupShown: false
    // A pair/connect attempt is in flight. Deliberately independent of
    // popupShown: closing the card must not abort a connect already running.
    property bool busy: false
    property bool failed: false

    // address -> advert, straight from BlueZ. See fastPairAdverts.js.
    property var adverts: ({})
    // address -> ms timestamp before which a device must not be offered again.
    // Dismissing is a snooze, never a blacklist: closing the card means "not
    // now", and earbuds sitting in pairing mode are worth offering again later.
    // Permanent ignores go in options.ignoredDevices instead.
    property var suppressedUntil: ({})
    // Wall-clock ms before which nothing at all is offered.
    property real mutedUntil: 0

    // An unresolved name is just the MAC, which is nothing worth offering.
    readonly property var macNameRegex: /^([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}$/

    function pickCandidate() {
        if (root.popupShown || Date.now() < root.mutedUntil)
            return;
        let best = null;
        let bestRssi = -999;
        for (const device of (Bluetooth.devices?.values ?? [])) {
            if (!device || device.paired || device.connected || device.pairing)
                continue;
            if ((root.suppressedUntil[device.address] ?? 0) > Date.now())
                continue;
            if (root.options.ignoredDevices.includes(device.address))
                continue;
            if (root.macNameRegex.test(device.name ?? ""))
                continue;
            const advert = root.adverts[device.address];
            if (!advert || advert.rssi < root.options.rssiThreshold)
                continue;
            if (root.options.audioOnly && !advert.audio)
                continue;
            if (advert.rssi > bestRssi) {
                best = device;
                bestRssi = advert.rssi;
            }
        }
        if (!best)
            return;
        root.candidate = best;
        root.busy = false;
        root.failed = false;
        root.popupShown = true;
        if (root.options.popupTimeout > 0)
            autoDismiss.restart();
    }

    function connectCandidate() {
        const device = root.candidate;
        if (!device)
            return;
        autoDismiss.stop();
        // Drops shouldScan, which stops discovery: pairing during an inquiry is
        // unreliable.
        root.busy = true;
        root.failed = false;
        connectTimeout.restart();
        // Trusting up front stops BlueZ asking the agent to authorize the
        // service, which the borrowed bluetoothctl agent would only prompt for
        // on a pipe nobody reads. It is also what makes the device reconnect on
        // its own next time, which is the half of Fast Pair that matters most.
        device.trusted = true;
        if (device.paired)
            return; // connectRetry takes it from here
        pairingAgent.running = true;
    }

    // Ends the attempt. Only reached once the link has actually held.
    function finishConnect() {
        console.log("FastPair: connected", root.candidate?.name ?? "device");
        root.busy = false;
        root.releaseAgent();
        root.dismiss(0);
    }

    function releaseAgent() {
        pairingAgent.running = false;
    }

    // Hides the card. UI only: an in-flight attempt keeps running.
    function dismiss(suppressMs) {
        if (suppressMs > 0 && root.candidate) {
            let next = Object.assign({}, root.suppressedUntil);
            next[root.candidate.address] = Date.now() + suppressMs;
            root.suppressedUntil = next;
        }
        autoDismiss.stop();
        root.popupShown = false;
    }

    function muteAll(ms) {
        root.mutedUntil = Date.now() + ms;
        root.dismiss(0);
    }

    // Unlike a snooze, this survives a restart.
    function ignoreCandidate() {
        const address = root.candidate?.address;
        if (address && !root.options.ignoredDevices.includes(address))
            root.options.ignoredDevices = [...root.options.ignoredDevices, address];
        root.dismiss(0);
    }

    Connections {
        target: root.candidate
        enabled: root.candidate !== null

        // BlueZ raises the link during pairing and then tears it down a few
        // seconds later, so the first "connected" is not the real one. Wait for
        // it to hold before closing the card, otherwise connectRetry gets
        // switched off right before the drop it exists to catch.
        function onConnectedChanged() {
            if (!root.busy)
                return;
            if (!root.candidate?.connected) {
                settle.stop();
                return;
            }
            settle.restart();
        }
    }

    Timer {
        id: settle
        interval: 9000
        onTriggered: {
            if (root.candidate?.connected)
                root.finishConnect();
        }
    }

    // Pair() fails outright with "Page Timeout" when the device does not answer
    // the page, which is routine while earbuds settle into pairing mode. Keep
    // asking for as long as the attempt is alive.
    Timer {
        id: pairRetry
        running: root.busy && pairingAgent.agentReady && root.candidate && !root.candidate.paired
        repeat: true
        interval: 5000
        triggeredOnStart: true
        onTriggered: {
            console.log("FastPair: pairing", root.candidate.name);
            root.candidate.pair();
        }
    }

    // Pair() returns before BlueZ has finished SDP, and the link drops once more
    // after bonding, so a single Connect() is never enough. Quickshell exposes
    // no ServicesResolved, so keep asking until it holds or connectTimeout gives
    // up.
    Timer {
        id: connectRetry
        running: root.busy && root.candidate && root.candidate.paired && !root.candidate.connected
        repeat: true
        interval: 2000
        triggeredOnStart: true
        onTriggered: {
            console.log("FastPair: connecting", root.candidate.name);
            root.candidate.connect();
        }
    }

    Timer {
        id: connectTimeout
        interval: 60000
        onTriggered: {
            if (!root.busy)
                return;
            settle.stop();
            console.warn("FastPair: gave up on", root.candidate?.name ?? "device", "- paired =", root.candidate?.paired ?? false, "connected =", root.candidate?.connected ?? false);
            root.releaseAgent();
            root.busy = false;
            root.failed = true;
            if (root.popupShown && root.options.popupTimeout > 0)
                autoDismiss.restart();
        }
    }

    Timer {
        id: autoDismiss
        interval: 1000 * root.options.popupTimeout
        onTriggered: root.dismiss(root.options.snoozeSeconds * 1000)
    }

    // Discovery just runs whenever the adapter is idle. Short scan windows do
    // not work: a BR/EDR inquiry round takes ~10s, so a few seconds of scanning
    // turns up BLE beacons and misses the earbuds. It still stops the moment
    // anything connects, since scanning stutters A2DP.
    readonly property bool shouldScan: Config.ready && root.options.enable && (root.adapter?.enabled ?? false) && !BluetoothStatus.connected && !root.busy

    function applyScanState() {
        if (!root.adapter)
            return;
        // No ownership tracking: Quickshell shares one D-Bus connection across
        // the whole shell, so our discovery reference cannot be told apart from
        // the Bluetooth dialog's. Both cases where this stops scanning (pairing,
        // and a device connecting) are reasons to stop anyway.
        root.adapter.discovering = root.shouldScan;
    }

    onShouldScanChanged: root.applyScanState()
    onAdapterChanged: root.applyScanState()
    Component.onCompleted: root.applyScanState()

    // Quickshell's discovering setter is fire-and-forget, and BlueZ answers
    // "Resource Not Ready" while the adapter is still coming up, so one bad
    // moment at startup would otherwise kill discovery for the whole session.
    // Re-assert until it sticks; this also covers BlueZ dropping discovery on
    // its own. Costs nothing once scanning, since running goes false.
    Timer {
        running: root.shouldScan && !(root.adapter?.discovering ?? false)
        repeat: true
        interval: 3000
        onTriggered: root.applyScanState()
    }

    // Discovery can also be running because the user opened the Bluetooth dialog,
    // so this checks the option too: the singleton outlives the popup when the
    // option is switched off, and must go quiet rather than keep polling.
    Timer {
        running: root.options.enable && (root.adapter?.discovering ?? false) && !root.popupShown
        repeat: true
        interval: 2000
        triggeredOnStart: true
        onTriggered: busctlDump.running = true
    }

    // Quickshell implements no org.bluez.Agent1 (only Adapter1, Device1 and
    // Battery1) and BlueZ refuses to pair when no agent is registered anywhere
    // on the bus, so Pair() fails silently on a system with no blueman or
    // bluedevil running. bluetoothctl brings its own agent. Borrow it only for
    // the duration of the pairing, so a system that does have a proper agent
    // (one that can actually show a PIN) keeps it as the default.
    Process {
        id: pairingAgent
        property bool agentReady: false
        command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
        stdinEnabled: true
        onStarted: pairingAgent.write("default-agent\n")
        onRunningChanged: if (!pairingAgent.running) pairingAgent.agentReady = false
        stdout: SplitParser {
            onRead: line => {
                if (pairingAgent.agentReady || !line.includes("Agent registered"))
                    return;
                pairingAgent.agentReady = true;
            }
        }
    }

    Process {
        id: busctlDump
        command: ["busctl", "--system", "--json=short", "call", "org.bluez", "/", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"]
        stdout: StdioCollector {
            id: dumpCollector
            onStreamFinished: {
                const parsed = Adverts.parseAdverts(dumpCollector.text);
                if (!parsed)
                    return; // busctl raced or failed; keep the previous map
                root.adverts = parsed;
                root.pickCandidate();
            }
        }
    }
}
