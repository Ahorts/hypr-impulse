// node services/fastPairAdverts.test.js
// Real `busctl GetManagedObjects` dump from a live scan (trimmed to the
// properties the parser reads), plus one synthetic Fast Pair advert since no
// Fast Pair device was in range when it was captured.
const assert = require("assert");
const { parseAdverts, fastPairModelId } = require("./fastPairAdverts.js");

const DUMP = {
        "type": "a{oa{sa{sv}}}",
        "data": [
            {
                "/org/bluez/hci0/dev_5E_93_DA_26_66_05": {
                    "org.bluez.Device1": {
                        "Address": {
                            "type": "s",
                            "data": "5E:93:DA:26:66:05"
                        },
                        "RSSI": {
                            "type": "n",
                            "data": -95
                        }
                    }
                },
                "/org/bluez/hci0/dev_53_6F_83_76_14_CF": {
                    "org.bluez.Device1": {
                        "Address": {
                            "type": "s",
                            "data": "53:6F:83:76:14:CF"
                        },
                        "RSSI": {
                            "type": "n",
                            "data": -89
                        },
                        "Icon": {
                            "type": "s",
                            "data": "audio-headset"
                        },
                        "Class": {
                            "type": "u",
                            "data": 2360324
                        },
                        "Name": {
                            "type": "s",
                            "data": "BT Speaker"
                        }
                    }
                },
                "/org/bluez/hci0/dev_74_19_0A_2F_1E_9B": {
                    "org.bluez.Device1": {
                        "Address": {
                            "type": "s",
                            "data": "74:19:0A:2F:1E:9B"
                        },
                        "RSSI": {
                            "type": "n",
                            "data": -57
                        },
                        "Name": {
                            "type": "s",
                            "data": "Galaxy Fit3 (1E9B)"
                        },
                        "ServiceData": {
                            "type": "a{sv}",
                            "data": {
                                "0000fd69-0000-1000-8000-00805f9b34fb": {
                                    "type": "ay",
                                    "data": [
                                        0,
                                        222,
                                        231,
                                        70,
                                        53,
                                        92,
                                        144,
                                        20,
                                        39,
                                        205,
                                        153,
                                        29,
                                        39,
                                        88,
                                        0
                                    ]
                                }
                            }
                        }
                    }
                },
                "/org/bluez/hci0/dev_34_FC_99_FF_6A_78": {
                    "org.bluez.Device1": {
                        "Address": {
                            "type": "s",
                            "data": "34:FC:99:FF:6A:78"
                        },
                        "RSSI": {
                            "type": "n",
                            "data": -97
                        },
                        "Name": {
                            "type": "s",
                            "data": "Washer"
                        }
                    }
                },
                "/org/bluez/hci0/dev_A8_E2_91_48_B5_83": {
                    "org.bluez.Device1": {
                        "Address": {
                            "type": "s",
                            "data": "A8:E2:91:48:B5:83"
                        },
                        "RSSI": {
                            "type": "n",
                            "data": -97
                        },
                        "Icon": {
                            "type": "s",
                            "data": "computer"
                        },
                        "Class": {
                            "type": "u",
                            "data": 3031300
                        },
                        "Name": {
                            "type": "s",
                            "data": "APPAN"
                        }
                    }
                },
                "/org/bluez/hci0/dev_2C_DE_DF_0C_16_C3": {
                    "org.bluez.Device1": {
                        "Address": {
                            "type": "s",
                            "data": "2C:DE:DF:0C:16:C3"
                        },
                        "Icon": {
                            "type": "s",
                            "data": "audio-headset"
                        },
                        "Class": {
                            "type": "u",
                            "data": 2393092
                        },
                        "Name": {
                            "type": "s",
                            "data": "Nirvana Ion"
                        }
                    }
                },
                "/org/bluez/hci0/dev_11_22_33_44_55_66": {
                    "org.bluez.Device1": {
                        "Address": {
                            "type": "s",
                            "data": "11:22:33:44:55:66"
                        },
                        "RSSI": {
                            "type": "n",
                            "data": -52
                        },
                        "Name": {
                            "type": "s",
                            "data": "11-22-33-44-55-66"
                        },
                        "ServiceData": {
                            "type": "a{sv}",
                            "data": {
                                "0000fe2c-0000-1000-8000-00805f9b34fb": {
                                    "type": "ay",
                                    "data": [
                                        0,
                                        14,
                                        48,
                                        196
                                    ]
                                }
                            }
                        }
                    }
                }
            }
        ]
    };

const a = parseAdverts(JSON.stringify(DUMP));

// Paired headset was in BlueZ's cache but carried no RSSI -> not nearby now.
assert.ok(!("2C:DE:DF:0C:16:C3" in a), "device without RSSI must be dropped");

// BR/EDR speaker: CoD 0x240404 -> major class 0x04, icon audio-headset.
assert.strictEqual(a["53:6F:83:76:14:CF"].rssi, -89);
assert.strictEqual(a["53:6F:83:76:14:CF"].audio, true);
assert.strictEqual(a["53:6F:83:76:14:CF"].fastPair, false);

// Samsung watch advertises service data 0xFD69, not 0xFE2C, and has no CoD.
assert.strictEqual(a["74:19:0A:2F:1E:9B"].audio, false, "watch must not look like earbuds");
assert.strictEqual(a["74:19:0A:2F:1E:9B"].fastPair, false);

// A laptop (icon "computer") must not qualify either.
assert.strictEqual(a["A8:E2:91:48:B5:83"].audio, false);

// Fast Pair advert: audio by virtue of FE2C, model ID from bytes 1..3.
assert.strictEqual(a["11:22:33:44:55:66"].fastPair, true);
assert.strictEqual(a["11:22:33:44:55:66"].audio, true);
assert.strictEqual(a["11:22:33:44:55:66"].fastPairModel, "0e30c4");

// Non-discoverable Fast Pair frame: flagged, but no model ID.
assert.strictEqual(fastPairModelId({ "0000fe2c-0000-1000-8000-00805f9b34fb": { data: [0, 1] } }), "");
assert.strictEqual(fastPairModelId({ "0000fd69-0000-1000-8000-00805f9b34fb": { data: [0, 1, 2, 3] } }), null);

// Garbage in, previous state preserved (null), not a crash.
assert.strictEqual(parseAdverts("busctl: command not found"), null);
assert.strictEqual(parseAdverts('{"type":"x"}'), null);

console.log("ok - " + Object.keys(a).length + " adverts parsed, all assertions passed");
