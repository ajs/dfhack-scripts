gui = require('gui')
unit = dfhack.gui.getSelectedUnit()
if not unit then
    print("Error: Cannot get unit")
else
    dfhack.gui.revealInDwarfmodeMap(unit.pos)
    screen = dfhack.gui.getCurViewscreen(true)
    dfhack.screen.dismiss(screen)
    gui.simulateInput(screen, 'D_VIEWUNIT')
end
