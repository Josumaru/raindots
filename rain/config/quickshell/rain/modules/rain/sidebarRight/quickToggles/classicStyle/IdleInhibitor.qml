import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    id: root
    toggled: Idle.inhibit
    buttonIcon: "power"
    onClicked: {
        Idle.toggleInhibit()
    }
    StyledToolTip {
        text: Translation.tr("Keep system awake")
    }

}
