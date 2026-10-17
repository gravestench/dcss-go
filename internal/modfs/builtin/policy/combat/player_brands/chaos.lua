-- Source: attack.cc:758-830,1335. Chaos rolls another melee brand first.
local brands = require("constants.weapon_brands")
local component = require("constants.component")
local holiness = require("constants.monster_holiness")
local flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local fiery = require("policy.monsters.fiery")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local holy_wrath = require("policy.combat.player_brands.holy_wrath")
local roll = require("policy.combat.roll")

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

local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function natural_or_plant(hit)
    return has(hit.definition.holiness, holiness.NATURAL) or
        has(hit.definition.holiness, holiness.PLANT)
end

local function living(_, hit)
    return not has(hit.definition.holiness, holiness.UNDEAD) and
        not has(hit.definition.holiness, holiness.NONLIVING)
end

local function vampiric(ctx, hit)
    return natural_or_plant(hit) and not ctx:has(hit.defender,
        component.SUMMON)
end

local function holy(_, hit)
    return holy_wrath.susceptible(hit.definition)
end

local function not_fiery(_, hit)
    return not fiery.is(hit.definition.id)
end

local function not_icy(_, hit)
    return not icy[hit.definition.id]
end

local function drainable(_, hit)
    return natural_or_plant(hit)
end

local function antimagic(_, hit)
    return enfeeble.antimagic_susceptible(hit.definition)
end

local function confusable(_, hit)
    return not has(hit.definition.flags, flags.CLARITY)
end

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

function chaos.choose(ctx, hit)
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

function chaos.apply(ctx, hit, player_brands)
    local selected = chaos.choose(ctx, hit)

    if selected == brands.CHAOS then
        if hit.health.current <= 0 then
            return
        end

        require("policy.combat.player_brands.chaos_effects").apply(ctx, hit)
        return
    end

    player_brands.apply(ctx, selected, hit)
end

return chaos
