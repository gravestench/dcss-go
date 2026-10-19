-- Example: A Wanderer rolls a weighted gift after its starting skills are chosen.
-- Source: ng-wanderer.cc at e60ba356. Wanderer is generated during a start;
-- its role skills and grants cannot live in the static job catalog.
local wanderer = {}
local gifts = require("policy.character.wanderer_gifts")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

-- Sort generated grants by ID to make starting skill order deterministic.
local function grant_before(left, right)
    return left.id < right.id
end

local offense = {
    "SK_AXES", "SK_MACES_FLAILS", "SK_RANGED_WEAPONS", "SK_POLEARMS",
    "SK_SHORT_BLADES", "SK_LONG_BLADES", "SK_STAVES", "SK_UNARMED_COMBAT",
    "SK_SUMMONINGS", "SK_NECROMANCY", "SK_TRANSLOCATIONS",
    "SK_TRANSMUTATIONS", "SK_POISON_MAGIC", "SK_CONJURATIONS",
    "SK_HEXES", "SK_FIRE_MAGIC", "SK_ICE_MAGIC", "SK_SPELLCASTING",
    "SK_AIR_MAGIC", "SK_EARTH_MAGIC", "SK_FIGHTING",
}

local defense = {
    "SK_FIGHTING", "SK_DODGING", "SK_ARMOUR", "SK_SHIELDS",
    "SK_EVOCATIONS", "SK_STEALTH", "SK_THROWING",
}

local physical = {
    "SK_AXES", "SK_MACES_FLAILS", "SK_RANGED_WEAPONS", "SK_POLEARMS",
    "SK_SHORT_BLADES", "SK_LONG_BLADES", "SK_STAVES", "SK_UNARMED_COMBAT",
    "SK_FIGHTING",
}

local mundane = {
    SK_ARMOUR = true,
    SK_DODGING = true,
    SK_SHIELDS = true,
    SK_EVOCATIONS = true,
    SK_STEALTH = true,
    SK_THROWING = true,
}

for _, id in ipairs(physical) do
    mundane[id] = true
end

local strength_skills = {
    SK_AXES = true,
    SK_MACES_FLAILS = true,
    SK_ARMOUR = true,
}

local dexterity_skills = {
    SK_SHORT_BLADES = true,
    SK_LONG_BLADES = true,
    SK_RANGED_WEAPONS = true,
    SK_STAVES = true,
    SK_DODGING = true,
    SK_SHIELDS = true,
    SK_STEALTH = true,
}

local flexible_skills = {
    SK_POLEARMS = true,
    SK_UNARMED_COMBAT = true,
    SK_FIGHTING = true,
    SK_EVOCATIONS = true,
    SK_THROWING = true,
}

-- Use effective mutation level when restricting a Wanderer role choice.
local function mutation(ctx, id)
    return mutation_levels.effective(ctx, ctx:player(), id) > 0
end

-- Role and stat draws share the character stream and consume one roll over aptitude weights.
local function weighted(ctx, choices)
    local total = 0

    for _, choice in ipairs(choices) do
        total = total + choice.weight
    end

    local roll = ctx:random("character", total)

    for _, choice in ipairs(choices) do
        if roll < choice.weight then
            return choice.id
        end

        roll = roll - choice.weight
    end

    error("wanderer weighted choice exhausted")
end

-- Exclude skills unusable by this species before computing weighted role candidates.
local function role(ctx, species, pool)
    local choices = {}

    for _, id in ipairs(pool) do
        local aptitude = species.aptitudes[id]

        if aptitude and aptitude.allowed then
            choices[#choices + 1] = {
                id = id,
                weight = math.max(1, math.floor(100 * 2 ^ (aptitude.value / 4))),
            }
        end
    end

    return weighted(ctx, choices)
end

-- Innate casters may be assigned Spellcasting before the ordinary offensive pool draw.
local function offense_role(ctx, species)
    if mutation(ctx, mutations.MUT_INNATE_CASTER) and
        ctx:random("character", 2) == 0 then
        return "SK_SPELLCASTING"
    end

    if mutation(ctx, mutations.MUT_NO_GRASPING) and
        ctx:random("character", 3) == 0 then
        return role(ctx, species, physical)
    end

    return role(ctx, species, offense)
end

-- The three chosen roles bias stat gains; ties still consume the source random draw.
local function stat_bonus(ctx, species, roles)
    local bonus = {
        strength = 0,
        intelligence = 0,
        dexterity = 0,
    }

    local influence = {
        strength = 0,
        intelligence = 0,
        dexterity = 0,
    }

    for _, id in ipairs(roles) do
        if strength_skills[id] then
            influence.strength = influence.strength + 1
        elseif dexterity_skills[id] then
            influence.dexterity = influence.dexterity + 1
        elseif flexible_skills[id] then
            local field = ctx:random("character", 2) == 0 and "strength" or "dexterity"
            influence[field] = influence[field] + 1
        else
            influence.intelligence = influence.intelligence + 1
        end
    end

    for _ = 1, 12 do
        local choices = {}

        for _, field in ipairs({ "strength", "intelligence", "dexterity" }) do
            local base = species[field] + bonus[field]
            choices[#choices + 1] = {
                id = field,
                weight = base > 17 and 1 or 2 + 2 * influence[field],
            }
        end

        local field = weighted(ctx, choices)
        bonus[field] = bonus[field] + 1
    end

    return bonus
end

-- Allocate the remaining starting levels after the guaranteed role grants.
local function skills(ctx, species, roles, has_spells)
    local levels = {}
    local distinct = {}
    local martial = 0
    local magical = 0

    levels[roles[1]] = 1

    for _, id in ipairs(roles) do
        if not distinct[id] then
            distinct[id] = true
            local target = id

            if mutation(ctx, mutations.MUT_INNATE_CASTER) and
                id:match("_MAGIC$") then
                target = "SK_SPELLCASTING"
            end

            levels[target] = (levels[target] or 0) + 1

            if mundane[id] then
                martial = martial + 1
            elseif id == "SK_SPELLCASTING" or id:match("_MAGIC$") or
                id == "SK_CONJURATIONS" or id == "SK_HEXES" or
                id == "SK_SUMMONINGS" or id == "SK_NECROMANCY" or
                id == "SK_TRANSLOCATIONS" or id == "SK_TRANSMUTATIONS" then
                magical = magical + 1
            end
        end
    end

    local remaining = (has_spells and 9 or 10) - 1

    if has_spells then
        levels.SK_SPELLCASTING = (levels.SK_SPELLCASTING or 0) + 1
    end

    for _ in pairs(distinct) do
        remaining = remaining - 1
    end

    while remaining > 0 do
        local options = {
            {
                id = roles[1],
                weight = 8,
            },
            {
                id = roles[2],
                weight = 5,
            },
            {
                id = roles[3],
                weight = 5,
            },
            {
                id = "SK_FIGHTING",
                weight = 1 + 2 * martial,
            },
            {
                id = "SK_ARMOUR",
                weight = 1 + martial,
            },
            {
                id = "SK_DODGING",
                weight = 2 + math.floor(magical / 2),
            },
            {
                id = "SK_THROWING",
                weight = 1,
            },
            {
                id = "SK_STEALTH",
                weight = 2,
            },
            {
                id = "SK_SPELLCASTING",
                weight = 1 + magical,
            },
            {
                id = "SK_EVOCATIONS",
                weight = 2,
            },
            {
                id = "SK_INVOCATIONS",
                weight = 1,
            },
        }

        local id = weighted(ctx, options)
        local aptitude = species.aptitudes[id]

        if aptitude and aptitude.allowed and (levels[id] or 0) < 5 then
            levels[id] = (levels[id] or 0) + 1
            remaining = remaining - 1
        end
    end

    local grants = {}

    for id, level in pairs(levels) do
        if species.aptitudes[id] and species.aptitudes[id].allowed then
            grants[#grants + 1] = {
                id = id,
                level = level,
            }
        end
    end

    table.sort(grants, grant_before)

    return grants
end

-- Resolve role skills first; their aptitude-weighted choices drive stat bonuses and starting gifts.
-- Generate role skills before gifts so equipment and spell choices follow the rolled build.
function wanderer.generate(ctx, species)
    local first

    if ctx:random("character", 3) == 0 then
        first = role(ctx, species, defense)
    else
        first = offense_role(ctx, species)
    end

    local second = offense_role(ctx, species)
    local third = role(ctx, species, defense)
    local roles = { first, second, third }
    local bonus = stat_bonus(ctx, species, roles)
    local grants = {}
    local learned = {}
    local received = {}
    local weapon_roles = {}

    for _, id in ipairs(physical) do
        if id ~= "SK_FIGHTING" and species.aptitudes[id] and
            species.aptitudes[id].allowed then
            weapon_roles[#weapon_roles + 1] = {
                id = id,
                weight = math.max(1,
                    math.floor(100 * 2 ^ (species.aptitudes[id].value / 4))),
            }
        end
    end

    for index, skill in ipairs(roles) do
        local actual
        local spells

        if index == 1 then
            actual, spells = gifts.good(ctx, species, skill, grants, weapon_roles)
        else
            actual, spells = gifts.decent(ctx, species, skill, grants, received)
        end

        roles[index] = actual
        received[actual] = true

        for _, spell in ipairs(spells) do
            learned[#learned + 1] = spell
        end
    end

    gifts.extra(ctx, species, grants)

    return {
        attributes = bonus,
        equipment = grants,
        skills = skills(ctx, species, roles, #learned > 0),
        spells = learned,
    }
end

return wanderer
