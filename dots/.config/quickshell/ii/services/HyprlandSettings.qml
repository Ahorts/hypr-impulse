pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property string hyprlandConfigPath: Directories.home.replace("file://", "") + "/.local/share/ii-vynx/hyprland.conf"
    
    Process {
        id: configWriter
        
        running: false
        property string pendingCommand: ""
        command: ["bash", "-c", pendingCommand]

        onExited: (exitCode, exitStatus) => {
            // NOTE: This will not work bc we are running it detached
            if (exitCode === 1) {
                Quickshell.execDetached(["notify-send", Translation.tr("Couldn't change the setting"), Translation.tr("Make sure you have vynx-cli installed"), "-a", "Shell"])
            }
        }
    }

    function changeKey(key, value) {
        if (configWriter.running) {
            console.warn("[HyprlandConfig] Writer busy, skipping")
            return
        }

        if (/['"\\`$|&;]/.test(String(value)) || /['"\\`$|&;]/.test(String(key))) {
            console.error("[HyprlandConfig] Unsafe characters rejected:", key, value)
            return
        }

        const tmpPath = "/tmp/hypr_config_write.tmp"
        const path = root.hyprlandConfigPath
        let sedCmd = ""

        if (key.includes(":")) {
            const parts = key.split(":")
            const section = parts[0].trim()
            const field = parts[1].trim()

            
            sedCmd = `${Directories.cliPath} hyprset key '${section}:${field}' '${value}' >/dev/null 2>&1 || true`
        } else {
            // idk.. put smthng here
        }

        //console.log("[HyprlandSettings] Running command:", sedCmd)
        configWriter.pendingCommand = sedCmd
        configWriter.startDetached()
    }

    function changeAnimation(animName, style) {
        if (configWriter.running) {
            console.warn("[HyprlandConfig] Writer busy, skipping")
            return
        }

        const safeCheck = /['"\\`$|&;]/
        if (safeCheck.test(String(animName)) || safeCheck.test(String(style))) {
            console.error("[HyprlandConfig] Unsafe characters rejected:", animName, style)
            return
        }

        const tmpPath = "/tmp/hypr_config_write.tmp"
        const path = root.hyprlandConfigPath

        const sedCmd = `${Directories.cliPath} hyprset anim '${animName}' '${style}' >/dev/null 2>&1 || true`

        configWriter.pendingCommand = sedCmd
        configWriter.startDetached()
    }

    function setLayout(layout) {
        if (layout !== "default" && layout !== "scrolling" && layout !== "dwindle" && layout !== "monocle" && layout !== "master") return
        // console.log("[HyprlandSettings] Setting layout to", layout)
        changeKey("general:layout", layout)
        Persistent.states.hyprland.layout = layout
    }

    function setRounding(rounding) {
        changeKey("decoration:rounding", rounding)
    }
}