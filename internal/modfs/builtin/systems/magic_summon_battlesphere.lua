local spells = require("ids.spells")
local component = require("constants.component")
local catalog = require("policy.catalog")
local sphere = require("policy.magic.effects.summons.battlesphere")

local function conjuration(spell)
    if spell.id == spells.SPELL_BATTLESPHERE or
        spell.id == spells.SPELL_SPELLFORGED_SERVITOR then
        return false
    end

    for _, school in ipairs(spell.schools or {}) do
        if school == "conjuration" then
            return true
        end
    end

    return false
end

-- The player spell system signals only successful casts. Source:
-- spl-summoning.cc:battlesphere_can_mirror and trigger_battlesphere.
local system = {}

function system.update(ctx, entity)
    if entity ~= ctx:player() or
        #ctx:signals("player_spell_success") == 0 then
        return
    end

    local intent = ctx:get(entity, component.INTENT)

    if intent and intent.kind == 15 and
        conjuration(catalog.get("spells", intent.spell_id)) then
        sphere.fire(ctx, entity)
    end
end

register.system({
    id = "magic.summon.battlesphere",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "world.movement" },
    update = system.update,
})

return system
