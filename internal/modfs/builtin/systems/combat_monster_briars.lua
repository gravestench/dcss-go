-- Theory of operation: a briar patch is a physical obstacle, not a roaming
-- combatant. Ordinary summon expiry owns its lifetime; this system only
-- prevents generic monster AI from assigning a movement or attack intent.
local component = require("constants.component")
local intent = require("constants.intent")
local spells = require("ids.spells")

local system = {}

-- A waiting intent lets the existing monster action pipeline account for
-- the actor without teaching its generic decision owner about briars.
function system.update(ctx, briar)
    local summon = ctx:get(briar, component.SUMMON)

    if not summon or summon.source_id ~= spells.SPELL_WALL_OF_BRAMBLES or
        ctx:has(briar, component.INTENT) then
        return
    end

    ctx:add(briar, component.INTENT, {
        kind = intent.MONSTER_WAIT,
    })
end

register.system({
    id = "combat.monster_briars",
    scope = "active",
    query = { component.SUMMON },
    before = { "monster.decision" },
    update = system.update,
})

return system
