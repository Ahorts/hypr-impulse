import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import "./cards"

StyledPopup {
    id: root
    popupRadius: Appearance.rounding.large

    function formatTime(seconds) {
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        if (h > 0)
            return `${h}h, ${m}m`;
        else
            return `${m}m`;
    }

    animate: false
    contentItem: HeroCard {
        id: mediaHero
        compactMode: true
        adaptiveWidth: true
        anchors.centerIn: parent
        icon: "battery_android_full"

        title: {
            if (Battery.chargeState == 4) {
                return Translation.tr("Fully charged");
            } else if (Battery.chargeState == 1) {
                return Translation.tr("Charging:") + ` ${Battery.energyRate.toFixed(2)}W`;
            } else {
                return Translation.tr("Discharging:") + ` ${Battery.energyRate.toFixed(2)}W`;
            }
        }
        subtitle: { 
            Battery.isCharging ? Translation.tr("Time to full:") + ` ${formatTime(Battery.timeToFull)}` : Translation.tr("Time to empty:") + ` ${formatTime(Battery.timeToEmpty)}`;
        }

        pillText: `${(Battery.health).toFixed(1)}%`
        pillIcon: "battery_android_full"
    }
}