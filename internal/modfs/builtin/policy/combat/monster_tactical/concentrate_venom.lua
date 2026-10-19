local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local duration = require("policy.combat.monster_support.duration")
local spellbook = require("policy.combat.monster_spellbook")
local spells = require("ids.spells")
local tactical = require("constants.monster_tactical")

local venom = {
    component_id = tactical.CONCENTRATE_VENOM,
}

local poison_flavours = {
    AF_POISON = true,
    AF_POISON_STRONG = true,
    AF_REACH_STING = true,
}

-- Source BEAM_CONCENTRATE_VENOM is useful only to a monster that can spit
-- poison or deliver a poison-flavoured melee attack and lacks this enchant.
function venom.benefits(ctx, recipient)
    if venom.active(ctx, recipient) then
        return false
    end

    local actor = ctx:get(recipient, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    for _, attack in ipairs(definition.attacks or {}) do
        if poison_flavours[attack.flavour_id] then
            return true
        end
    end

    local book = spellbook.for_actor(ctx, recipient)

    for _, slot in ipairs(book and book.slots or {}) do
        if slot.spell_id == spells.SPELL_SPIT_POISON then
            return true
        end
    end

    return false
end

-- Consumers check the saved timer, never component presence alone.
function venom.active(ctx, recipient)
    local state = ctx:get(recipient, venom.component_id)

    return state ~= nil and state.remaining_aut > 0
end

-- ENCH_CONCENTRATE_VENOM uses the source's shorter 300-centiturn enchant
-- class, adjusted for the recipient's speed before its melee/spit changes.
function venom.grant(ctx, recipient)
    if venom.active(ctx, recipient) then
        return false
    end

    local state = {
        remaining_aut = duration.protection(ctx, recipient),
    }

    if ctx:has(recipient, venom.component_id) then
        ctx:set(recipient, venom.component_id, state)
    else
        ctx:add(recipient, venom.component_id, state)
    end

    return true
end

-- Age the enchant on its owner before the next monster decision.
function venom.tick(ctx, recipient, elapsed_aut)
    local state = ctx:get(recipient, venom.component_id)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(recipient, venom.component_id)
    else
        ctx:set(recipient, venom.component_id, state)
    end
end

return venom
