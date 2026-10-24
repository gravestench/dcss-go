-- Terminal input uses the same stable IDs as game command policies.
-- Example: a route returns { kind = commands.move }; the bridge can then
-- dispatch the shared command ID without duplicating numeric values here.
local kind = require("constants.command_kind")

local commands = {
    move = kind.MOVE,
    upstairs = kind.UPSTAIRS,
    downstairs = kind.DOWNSTAIRS,
    pickup = kind.PICKUP,
    wait = kind.WAIT,
    inspect = kind.INSPECT,
    quaff = kind.QUAFF,
    drop = kind.DROP,
    wield = kind.WIELD,
    open_door = kind.OPEN_DOOR,
    close_door = kind.CLOSE_DOOR,
    wear = kind.WEAR,
    take_off = kind.TAKE_OFF,
    continue_equipment = kind.CONTINUE_EQUIPMENT,
    cancel_equipment = kind.CANCEL_EQUIPMENT,
    fire = kind.FIRE,
    throw = kind.THROW,
    memorise = kind.MEMORISE,
    cancel_memorise = kind.CANCEL_MEMORISE,
    cancel_vampire = kind.CANCEL_MEMORISE,
    cast = kind.CAST,
    force_cast = kind.FORCE_CAST,
    ability = kind.ABILITY,
    evoke_wand = kind.EVOKE_WAND,
    evoke_item = kind.EVOKE_ITEM,
    read = kind.READ,
    pray = kind.PRAY,
}

return commands
