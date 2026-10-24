-- Source: attack.cc,1335. Chaos rolls another melee brand first.
local brands = require("constants.weapon_brands")
local component = require("constants.component")
local holiness = require("constants.monster_holiness")
local flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local fiery = require("policy.monsters.fiery")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local holy_wrath = require("policy.combat.monster_target_brands.holy_wrath")
local roll = require("policy.combat.roll")
local conduct = require("policy.religion.conduct")
local identification = require("policy.items.identification")
local kinds = require("constants.religion_conduct")
local streams = require("constants.rng_streams")

local chaos = {
    after_death = true,
}

local icy = {
    [monsters.MONS_ICE_BEAST] = true,
    [monsters.MONS_SIMULACRUM] = true,
    [monsters.MONS_ICE_STATUE] = true,
    [monsters.MONS_BLOCK_OF_ICE] = true,
    [monsters.MONS_NARGUN] = true,
}

-- Holiness and flag lists can be absent in catalog entries, so missing lists match nothing.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Drain and vampirism are reserved for living tissue or plant matter.
local function natural_or_plant(hit)
    return has(hit.definition.holiness, holiness.NATURAL) or
        has(hit.definition.holiness, holiness.PLANT)
end

-- Venom has no biological effect on undead or nonliving defenders.
local function living(_, hit)
    return not has(hit.definition.holiness, holiness.UNDEAD) and
        not has(hit.definition.holiness, holiness.NONLIVING)
end

-- Summoned life cannot restore HP even when its species would otherwise qualify.
local function vampiric(ctx, hit)
    return natural_or_plant(hit) and not ctx:has(hit.defender,
        component.SUMMON)
end

-- Share Holy Wrath's holiness check so Chaos does not redefine sacred susceptibility.
local function holy(_, hit)
    return holy_wrath.susceptible(hit.definition)
end

-- A fire-native monster should not draw a redundant flaming outcome.
local function not_fiery(_, hit)
    return not fiery.is(hit.definition.id)
end

-- These ice-bodied monsters should not draw a redundant freezing outcome.
local function not_icy(_, hit)
    return not icy[hit.definition.id]
end

-- Negative-energy drain requires a natural or plant target in this Chaos table.
local function drainable(_, hit)
    return natural_or_plant(hit)
end

-- Use Enfeeble's susceptibility rule so anti-magic is not offered to immune monsters.
local function antimagic(ctx, hit)
    return enfeeble.antimagic_susceptible(ctx, hit.defender)
end

-- Innate clarity removes the confusion outcome before weights are summed.
local function confusable(_, hit)
    return not has(hit.definition.flags, flags.CLARITY)
end

-- Treat a missing predicate as universally eligible while keeping exclusions explicit.
local function valid(ctx, hit, choice)
    return not choice.valid or choice.valid(ctx, hit)
end

local choices = {
    {
        id = brands.FLAMING,
        weight = 10,
        valid = not_fiery,
    },

    {
        id = brands.FREEZING,
        weight = 10,
        valid = not_icy,
    },

    {
        id = brands.ELECTROCUTION,
        weight = 10,
    },

    {
        id = brands.VENOM,
        weight = 10,
        valid = living,
    },

    {
        id = brands.CHAOS,
        weight = 10,
    },

    {
        id = brands.DRAINING,
        weight = 5,
        valid = drainable,
    },

    {
        id = brands.VAMPIRISM,
        weight = 5,
        valid = vampiric,
    },

    {
        id = brands.HOLY_WRATH,
        weight = 5,
        valid = holy,
    },

    {
        id = brands.ANTIMAGIC,
        weight = 5,
        valid = antimagic,
    },

    {
        id = brands.CONFUSE,
        weight = 2,
        valid = confusable,
    },

    {
        id = brands.DISTORTION,
        weight = 2,
    },
}

-- Example: chaos.choose(ctx, hit) with defender with eligible effects -> returns one weighted brand ID
-- Build the valid weighted effect pool from this defender before consuming the chaos draw.
function chaos.choose(ctx, hit)
    -- Recompute the eligible total for this defender before the weighted
    -- draw; immunity and holiness can remove individual brand choices.
    local total = 0

    for _, choice in ipairs(choices) do
        if valid(ctx, hit, choice) then
            total = total + choice.weight
        end
    end

    local draw = roll.melee(ctx, total)

    for _, choice in ipairs(choices) do
        if valid(ctx, hit, choice) then
            draw = draw - choice.weight

            if draw < 0 then
                return choice.id
            end
        end
    end

    error("chaos has no eligible melee effect")
end

-- A self-selected Chaos result uses monster effects; other results reuse ordinary brand code.
function chaos.apply(ctx, hit, target_brands)
    -- Source attack.cc judges the chosen chaos weapon brand, even when its
    -- random effect is harmless. Identification before the proc decides
    -- whether a good god forgives this particular swing.
    if hit.attacker == ctx:player() then
        local known = hit.weapon_entity and
            identification.known(ctx, hit.attacker,
                hit.weapon_entity).properties or false

        conduct.record(ctx, {
            id = kinds.CHAOS,
            level = 2 + ctx:random(streams.RELIGION, 3),
            known = known,
        })
    end

    local selected = chaos.choose(ctx, hit)

    if selected == brands.CHAOS then
        -- The self-selection enters the chaos effect table only while the
        -- defender is still alive; other choices reuse their brand module.
        if hit.health.current <= 0 then
            return
        end

        require("policy.combat.monster_target_brands.chaos_effects").apply(ctx, hit)
        return
    end

    target_brands.apply(ctx, selected, hit)
end

return chaos
