-- Bloated Husk's death is an eight-die physical explosion whose die size
-- is the dying body's effective hit dice. It has no elemental resistance.
local blast = require("policy.magic.effects.summons.blast")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local husk = {}

-- Death cleanup has freed the monster's grid cell, but its saved actor
-- still supplies HD and kill attribution while the blast reaches neighbors.
function husk.on_death(ctx, actor, definition, position)
    if definition.id ~= monsters.MONS_BLOATED_HUSK then
        return false
    end

    if ctx:has(actor, component.INNER_FLAME) then
        return true
    end

    local hd = monster_stats.hit_dice(ctx, actor, definition)

    blast.area(ctx, actor, 2, 8, hd,
        nil, nil, streams.MONSTER_SPELL, position)
    ctx:emit("combat", "The bloated husk explodes!")

    return true
end

death_hooks.add("monster.husk_explosion", husk.on_death)

return husk
