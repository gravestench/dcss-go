-- monster.cc:_mons_is_fiery. Shared by rain clouds and chaos brands.
local monsters = require("ids.monsters")

local fiery = {}

local kinds = {
    [monsters.MONS_FIRE_VORTEX] = true,
    [monsters.MONS_FIRE_ELEMENTAL] = true,
    [monsters.MONS_EFREET] = true,
    [monsters.MONS_AZRAEL] = true,
    [monsters.MONS_LAVA_SNAKE] = true,
    [monsters.MONS_SALAMANDER] = true,
    [monsters.MONS_SALAMANDER_MYSTIC] = true,
    [monsters.MONS_MOLTEN_GARGOYLE] = true,
    [monsters.MONS_ORB_OF_FIRE] = true,
}

function fiery.is(kind_id)
    return kinds[kind_id] == true
end

return fiery
