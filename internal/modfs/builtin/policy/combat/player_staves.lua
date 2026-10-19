local staves = require("policy.inventory.staves")
local fighter = require("policy.combat.fighter")
local damage = require("policy.magic.damage")
local roll = require("policy.combat.roll")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local skills = require("ids.skills")
local monster_poison = require("policy.combat.monster_poison")

local player_staves = {}

-- Earth staff damage tests AC three times, so each save needs its own melee draw.
local function armour(ctx, raw, ac, rolls)
    local saved = 0

    -- Source: actor.cc rolls AC independently three times for earth.
    for _ = 1, rolls do
        saved = saved + roll.armour(ctx, ac)
    end

    return math.max(0, raw - saved)
end

-- Example: player_staves.apply(ctx, hit, brands, definition, defender_ac) with dead target -> no elemental staff proc
-- Add a magical staff's elemental proc after a landed melee hit, using its own power and AC rolls.
function player_staves.apply(ctx, hit, brands, definition, defender_ac)
    if not definition or not definition.staff or
        hit.health.current <= 0 then
        return
    end

    if mutation_levels.effective(ctx, hit.attacker,
        mutations.MUT_NO_ARTIFICE) > 0 then
        return
    end

    local staff = definition.staff
    local raw = staves.roll_damage(ctx,
        fighter.skill(ctx, staff.skill_id, 100),
        fighter.skill(ctx, skills.SK_EVOCATIONS, 200),
        fighter.skill(ctx, skills.SK_EVOCATIONS, 50))

    if raw <= 0 then
        return
    end

    raw = math.floor(raw * (staff.damage_numerator or 1) /
        (staff.damage_denominator or 1))

    local bonus = raw

    if staff.resistance_id then
        if staff.negative_energy then
            bonus = brands.negative(ctx, hit, raw)
        else
            bonus = damage.monster_elemental(ctx, hit.defender,
                raw, staff.resistance_id)
        end
    else
        bonus = armour(ctx, raw, defender_ac, staff.ac_rolls or 0)
    end

    if bonus <= 0 then
        return
    end

    ctx:emit("combat", string.format(staff.message, hit.definition.name))
    brands.damage(ctx, hit, bonus)

    if staff.poison_level and hit.health.current > 0 then
        -- Source: melee-attack.cc poisons surviving defenders
        -- after the staff's resistible damage.
        monster_poison.apply(ctx, hit.defender, hit.definition,
            staff.poison_level, hit.attacker, false)
    end
end

return player_staves
