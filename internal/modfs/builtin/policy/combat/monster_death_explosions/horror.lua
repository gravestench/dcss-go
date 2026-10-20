-- A Lurking Horror does not roll blast damage. Its death Torments every
-- susceptible actor in sight through the ordinary Torment owner.
local area = require("policy.combat.torment_area")
local channels = require("constants.message_channels")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local monsters = require("ids.monsters")

local horror = {}

-- The corpse cell is already vacant, but the death position anchors the
-- LOS radius. Inner Flame replaces this intrinsic source effect.
function horror.on_death(ctx, actor, definition, position)
    if definition.id ~= monsters.MONS_LURKING_HORROR then
        return false
    end

    if ctx:has(actor, component.INNER_FLAME) then
        return true
    end

    area.apply(ctx, actor, channels.COMBAT, position)

    return true
end

death_hooks.add("monster.horror_torment", horror.on_death)

return horror
