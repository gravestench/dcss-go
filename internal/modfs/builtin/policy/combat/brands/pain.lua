local catalog = require("policy.catalog")
local roll = require("policy.combat.roll")
local player_health = require("policy.combat.player_health")
local monster_stats = require("policy.combat.monster_stats")

-- A human-intelligence caster with a necromancy slot uses full HD as skill;
-- an empty or unrelated book falls back to fractional HD.
local function necromancy_book(book_id)
    if book_id == "MST_NO_SPELLS" then
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

-- Only human-intelligence casters derive Pain skill from HD and their spellbook.
local function skill(ctx, attacker)
    local actor = ctx:get(attacker, "core.actor")
    local definition = catalog.get("monsters", actor.kind_id)

    -- monster.cc: only human-intelligence monsters can use
    -- necromancy skill, at HD or half HD depending on known spells.
    if definition.intelligence_id ~= "I_HUMAN" then
        return 0
    end

    if necromancy_book(definition.spellbook_id) then
        return monster_stats.hit_dice(ctx, attacker, definition)
    end

    -- actor::skill_rdiv asks for 256-scaled skill before rounding.
    -- HD 1 therefore has a 50% chance to count as skill 1.
    local hd = monster_stats.hit_dice(ctx, attacker, definition)

    return roll.random_divide(ctx, hd * 128, 256)
end

local brand = {}

-- Example: brand.apply(ctx, hit) rolls Pain activation and bonus damage
-- independently, preserving both source skill draws.
function brand.apply(ctx, hit)
    local level = skill(ctx, hit.attacker)

    -- attack.cc: one_chance_in(skill + 1) prevents pain.
    if roll.melee(ctx, level + 1) == 0 then
        return
    end

    -- Source rolls the skill again for damage, independently of the
    -- skill roll that decided whether pain activates.
    local bonus = roll.melee(ctx, skill(ctx, hit.attacker) + 1)
    hit.health = player_health.damage(ctx, hit.defender, bonus,
        false, hit.attacker)

    if bonus > 0 then
        ctx:emit("combat", "You writhe in agony!")
    end
end

return brand
