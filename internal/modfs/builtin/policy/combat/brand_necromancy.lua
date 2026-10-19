-- Pain brand skill belongs to the attacker and is independent of the
-- defender type. Both monster-target and player-target Pain use this rule.
local catalog = require("policy.catalog")
local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")

local necromancy = {}

-- Human-intelligence casters with a Necromancy spell use full HD as skill;
-- other spellbooks receive a random half-HD effective skill.
local function has_necromancy(book_id)
    if not book_id or book_id == "" or
        book_id == "MST_NO_SPELLS" then
        return false
    end

    local book = catalog.get("monster_spellbooks", book_id)

    for _, slot in ipairs(book.slots) do
        local spell = catalog.get("spells", slot.spell_id)

        for _, school in ipairs(spell.schools or {}) do
            if school == "necromancy" then
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

    if has_necromancy(definition.spellbook_id) then
        return hd
    end

    return roll.random_divide(ctx, hd * 128, 256)
end

return necromancy
