// Parses `busctl --system --json=short call org.bluez / \
//   org.freedesktop.DBus.ObjectManager GetManagedObjects` into an advert map,
// keyed by address so entries can be matched back to Bluetooth.devices.
//
// Quickshell.Bluetooth exposes no RSSI, ServiceData or ManufacturerData, so the
// proximity and Fast Pair signals have to be read from BlueZ directly. Used by
// FastPair.qml; fastPairAdverts.test.js checks it with `node`.

var FAST_PAIR_UUID = "0000fe2c-";
var CLASS_MAJOR_AUDIO = 0x04;

function hex2(b) {
    return ("0" + (b & 0xff).toString(16)).slice(-2);
}

// Fast Pair service data is one version/flags byte then a 3-byte model ID.
// Shorter payloads are the non-discoverable (account key filter) frame, which
// carries no model ID, so those only mean "this is a Fast Pair device".
function fastPairModelId(serviceData) {
    for (var uuid in serviceData) {
        if (uuid.indexOf(FAST_PAIR_UUID) !== 0)
            continue;
        var bytes = (serviceData[uuid] && serviceData[uuid].data) || [];
        if (bytes.length < 4)
            return "";
        return hex2(bytes[1]) + hex2(bytes[2]) + hex2(bytes[3]);
    }
    return null; // no Fast Pair advert at all
}

function parseAdverts(text) {
    var payload;
    try {
        payload = JSON.parse(text);
    } catch (e) {
        return null; // busctl failed or raced; caller keeps the previous map
    }
    var objects = payload && payload.data && payload.data[0];
    if (!objects)
        return null;

    var out = {};
    for (var path in objects) {
        var dev = objects[path]["org.bluez.Device1"];
        if (!dev)
            continue;
        var address = dev.Address && dev.Address.data;
        // No RSSI means BlueZ has the device cached but has not seen it in this
        // discovery session, i.e. it is not actually nearby right now.
        var rssi = dev.RSSI && dev.RSSI.data;
        if (!address || rssi === undefined || rssi === null)
            continue;

        var icon = (dev.Icon && dev.Icon.data) || "";
        var cod = (dev.Class && dev.Class.data) || 0;
        var model = fastPairModelId((dev.ServiceData && dev.ServiceData.data) || {});

        out[address] = {
            address: address,
            rssi: rssi,
            icon: icon,
            fastPair: model !== null,
            fastPairModel: model || "",
            // Class of Device bits 8-12 are the major device class, and 0x04 is
            // Audio/Video. BLE-only earbuds often advertise no CoD at all,
            // hence the icon and Fast Pair fallbacks.
            audio: icon.indexOf("audio-") === 0 || ((cod >> 8) & 0x1f) === CLASS_MAJOR_AUDIO || model !== null
        };
    }
    return out;
}

if (typeof module !== "undefined")
    module.exports = { parseAdverts: parseAdverts, fastPairModelId: fastPairModelId };
