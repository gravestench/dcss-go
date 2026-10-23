-- Source: crawl-ref/source/acquire.cc:_acquirement_weapon_skill and
-- _acquirement_weapon_subtype. Selection is separate from ordinary loot.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local ammunition = require("ids.ammunition")
local equipment = require("policy.inventory.equipment")
local gods = require("constants.gods")
local ids = require("ids.items")
local mutations = require("ids.mutations")
local mutation_levels = require("policy.mutations.levels")
local selection = require("policy.scrolls.acquirement.selection")
local skills = require("ids.skills")

local weapons = {}

local weapon_skills = {
    skills.SK_SHORT_BLADES,
    skills.SK_LONG_BLADES,
    skills.SK_AXES,
    skills.SK_MACES_FLAILS,
    skills.SK_POLEARMS,
    skills.SK_STAVES,
    skills.SK_RANGED_WEAPONS,
}

-- Trog's gift pool stops before Ranged Weapons. Divine skill weights are
-- linear; scrolls exaggerate a trained family's chance quadratically.
local function permitted_skills(god_id)
    local count = #weapon_skills

    if god_id == gods.TROG then
        count = count - 1
    end

    return count
end

local function chosen_skill(ctx, god_id)
    local rows = {}

    for index = 1, permitted_skills(god_id) do
        local skill_id = weapon_skills[index]
        local level = selection.skill(ctx, skill_id)
        local weight = level + 1

        if not god_id then
            weight = (weight + 1) * (weight + 2)
        end

        rows[#rows + 1] = {
            id = skill_id,
            weight = weight,
        }
    end

    return selection.weighted(ctx, rows)
end

-- Include Unarmed Combat in the benchmark so weak weapon training does not overvalue a weapon.
local function best_skill(ctx, god_id)
    local best = selection.skill(ctx, skills.SK_UNARMED_COMBAT)

    for index = 1, permitted_skills(god_id) do
        best = math.max(best, selection.skill(ctx,
            weapon_skills[index]))
    end

    return best
end

-- Scale source weight by skill, shield use, and species fit before a subtype reaches the draw.
local function weight(ctx, player, species, kind, best, shields, divine)
    local weapon = kind.weapon
    local base = (weapon.acquire_weight or kind.generation.weight or 0) * 100

    if base <= 0 then
        return 0
    end

    local two_handed = equipment.needs_second_hand(ctx, player, kind, species)

    if two_handed and mutation_levels.effective(ctx, player,
        mutations.MUT_MISSING_HAND) > 0 then
        return 0
    end

    -- Scrolls favor powerful melee bases. Trog and Okawaru keep the
    -- catalog's base acquisition weights before shield and novelty bias.
    if not divine and weapon.ammo_id == ammunition.NONE then
        base = math.max(base, 500)

        if kind.id == ids.WPN_QUICK_BLADE then
            base = math.floor(base * 25 / 9)
        end

        local damage = weapon.damage

        if not two_handed then
            damage = math.floor(damage * 3 / 2)
        end

        base = math.floor(base * damage * damage * damage /
            math.max(1, weapon.speed))
    end

    local wants_shield = math.min(2 * shields, best) + 10
    local avoids_shield = math.max(best - shields, 0) + 10

    if two_handed then
        base = math.floor(base * avoids_shield / wants_shield)
    else
        base = math.floor(base * wants_shield / avoids_shield)
    end

    if not selection.seen(ctx, player, kind.id) then
        base = base * 5
    end

    return math.max(1, base)
end

-- Example: A trained Axes skill raises axe-family chance before shield use changes subtype weight.
-- Choose one weighted weapon subtype after the player build and supported kinds are known.
function weapons.pick(ctx, player, _, god_id)
    local divine = god_id ~= nil
    local skill_id = chosen_skill(ctx, god_id)
    local species = selection.species(ctx, player)
    local best = best_skill(ctx, god_id)
    local shields = selection.skill(ctx, skills.SK_SHIELDS)
    local rows = {}

    for _, kind in ipairs(catalog.all("items")) do
        if kind.class == classes.OBJ_WEAPONS and kind.weapon and
            kind.weapon.skill_id == skill_id and
            kind.generation.mode ~= "none" then
            local value = weight(ctx, player, species, kind, best,
                shields, divine)

            if value > 0 then
                rows[#rows + 1] = {
                    id = kind.id,
                    weight = value,
                }
            end
        end
    end

    return selection.weighted(ctx, rows)
end

return weapons
