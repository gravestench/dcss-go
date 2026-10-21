-- Pain brand skill belongs to the attacker and is independent of the
-- defender type. Both monster-target and player-target Pain use this rule.
local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_spellbook = require("policy.combat.monster_spellbook")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
local schools = require("constants.spell_schools")

local necromancy = {}

-- Source checks the actor's active slots, including MST_GHOST's rolled
-- Pan lord spells, rather than looking up only a static catalog book.
local function has_necromancy(ctx, attacker)
    local book = monster_spellbook.for_actor(ctx, attacker)

    if not book then
        return false
    end

    for _, slot in ipairs(book.slots) do
        local spell = catalog.get("spells", slot.spell_id)

        for _, school in ipairs(spell.schools or {}) do
            if school == schools.NECROMANCY then
                return true
            end
        end
    end

    return false
end

-- The player illusion owns a frozen skill from its source character. Other
-- monsters derive skill from their intelligence and live hit dice as in
-- monster.cc::monster::skill_rdiv.
function necromancy.monster_skill(ctx, attacker)
    local ghost = ctx:get(attacker, component.PLAYER_ILLUSION)

    if ghost then
        return ghost.necromancy_skill
    end

    local actor = ctx:get(attacker, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if definition.intelligence_id ~= "I_HUMAN" then
        return 0
    end

    local hd = monster_stats.hit_dice(ctx, attacker, definition)

    if has_necromancy(ctx, attacker) then
        return hd
    end

    return roll.random_divide(ctx, hd * 128, 256)
end

return necromancy
