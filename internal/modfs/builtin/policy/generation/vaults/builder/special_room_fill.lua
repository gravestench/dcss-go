-- Source builder/rooms.des paints monster recipes into a rectangle supplied
-- by the special-room parent. Geometry and monster choice belong to this
-- placement, so they use the vault API and leave no module-global state.
local directives = require("constants.vault_directives")

local fill = {}

-- Fill the parent's O region with ordinary floor before source NSUBST
-- reduces the monster glyph count. A packed room fills more cells.
function fill.room(api, monsters, lord, packed)
    local width, height = api:map_size()

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            api:set_cell(x, y, ".")
        end
    end

    if packed then
        api:emit(directives.SUBST, ". : 1")
    else
        api:emit(directives.SUBST, ". = 1:30 .")
    end

    api:emit(directives.NSUBST, "1 = 24=1 / 3=1. / .")

    if lord then
        api:emit(directives.NSUBST, "1 = 1=2 / 1")
        api:emit(directives.KMONS, "2 = " .. lord)
    end

    api:emit(directives.KMONS, "1 = " .. monsters)
end

return fill
