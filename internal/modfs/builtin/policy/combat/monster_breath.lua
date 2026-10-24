-- Monster breath slots share one recovery clock on the caster. The
-- source's ENCH_BREATH_WEAPON duration is one to five monster actions.
local component = require("constants.component")
local spell_flags = require("constants.monster_spell_flags")
local streams = require("constants.rng_streams")

local breath = {}

-- All breath slots on an actor share the same saved action count. A fast
-- Bat beast may act twice per player turn, so elapsed world aut is wrong.
function breath.ready(ctx, caster)
    local cooldown = ctx:get(caster,
        component.MONSTER_BREATH_COOLDOWN)

    return not cooldown or cooldown.remaining_actions == 0
end

-- Advance once when this monster receives another action, including an
-- action that becomes WAIT. Source decays breath after each monster move;
-- consuming one count before the next decision gives the same readiness.
function breath.advance(ctx, caster)
    local cooldown = ctx:get(caster,
        component.MONSTER_BREATH_COOLDOWN)

    if not cooldown or cooldown.remaining_actions == 0 then
        return
    end

    cooldown.remaining_actions = cooldown.remaining_actions - 1
    ctx:set(caster, component.MONSTER_BREATH_COOLDOWN,
        cooldown)
end

-- This is a slot property, not a spell-ID list. Modded breath spells get
-- the same timing automatically when they register a BREATH slot.
function breath.slot(slot)
    for _, flag in ipairs(slot.flags or {}) do
        if flag == spell_flags.BREATH then
            return true
        end
    end

    return false
end

-- Set recovery before resolving the selected effect, as mon-cast does.
-- One d5 draw on the monster spell stream yields ten to fifty auts.
function breath.begin(ctx, caster)
    if not breath.ready(ctx, caster) then
        error("monster breath weapon is still recovering")
    end

    local state = {
        remaining_actions = 1 +
            ctx:random(streams.MONSTER_SPELL, 5),
    }

    if ctx:has(caster, component.MONSTER_BREATH_COOLDOWN) then
        ctx:set(caster, component.MONSTER_BREATH_COOLDOWN, state)
    else
        ctx:add(caster, component.MONSTER_BREATH_COOLDOWN, state)
    end
end

return breath
