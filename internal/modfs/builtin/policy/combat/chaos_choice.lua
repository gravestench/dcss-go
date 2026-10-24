-- Weapon Chaos and natural Chaotic contact draw from the same eleven source
-- bands. The chosen brand ID is only a selection token: each caller owns
-- its own weapon or natural attack effect formula after this draw.
local catalog = require("policy.catalog")
local component = require("constants.component")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local fiery = require("policy.monsters.fiery")
local flags = require("constants.monster_flags")
local forms = require("constants.form_ids")
local holy_wrath = require(
    "policy.combat.monster_target_brands.holy_wrath")
local holiness = require("constants.monster_holiness")
local monsters = require("ids.monsters")
local player_holiness = require("policy.character.holiness")
local player_resistance = require("policy.combat.player_resistance")
local roll = require("policy.combat.roll")
local brands = require("constants.weapon_brands")

local choice = {}

local icy = {
    [monsters.MONS_ICE_BEAST] = true,
    [monsters.MONS_SIMULACRUM] = true,
    [monsters.MONS_ICE_STATUE] = true,
    [monsters.MONS_BLOCK_OF_ICE] = true,
    [monsters.MONS_NARGUN] = true,
}

-- Catalog traits are lists. A missing list never implies a property.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Brand and natural-hit callers use different envelope field names. Read
-- the current actor if neither supplies a projected monster definition.
local function definition(ctx, hit)
    if hit.definition then
        return hit.definition
    end

    if hit.defender_definition then
        return hit.defender_definition
    end

    local actor = ctx:get(hit.defender, component.ACTOR)

    return actor and catalog.get("monsters", actor.kind_id)
end

-- Player and monster bodies expose the same source questions through
-- different state owners. Preserve the exact source fiery/icy exclusions.
local function fiery_body(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        return false
    end

    return fiery.is(definition(ctx, hit).id)
end

-- Only player Ice Beast Form counts as inherently icy in source Crawl.
local function icy_body(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        local form = ctx:get(hit.defender, component.PLAYER_FORM)

        return form and form.form_id == forms.ICE_BEAST or false
    end

    return icy[definition(ctx, hit).id] == true
end

-- Undead and nonliving bodies are removed from Chaos's venom pool before
-- its one weighted draw, regardless of current poison resistance.
local function living(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        return player_holiness.natural(ctx, hit.defender)
    end

    local body = definition(ctx, hit)

    return not has(body.holiness, holiness.UNDEAD) and
        not has(body.holiness, holiness.NONLIVING)
end

-- Drain and Vampiric require source natural or plant holiness. A summoned
-- victim can still be drained but cannot supply a vampiric heal.
local function natural_or_plant(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        return player_holiness.natural(ctx, hit.defender)
    end

    local body = definition(ctx, hit)

    return has(body.holiness, holiness.NATURAL) or
        has(body.holiness, holiness.PLANT)
end

-- Source holy-energy resistance is live for player forms and exceptional
-- monster species such as the profane servitor.
local function holy(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        return player_holiness.undead_or_demonic(ctx, hit.defender)
    end

    return holy_wrath.susceptible(definition(ctx, hit))
end

-- All players are antimagic-susceptible in the pinned source. Monster
-- eligibility depends on the current spellbook, including live overrides.
local function antimagic(ctx, hit)
    return ctx:has(hit.defender, component.PLAYER) or
        enfeeble.antimagic_susceptible(ctx, hit.defender)
end

-- Clarity removes Confuse from the pool before the draw. Worn player gear
-- and monster innate flags both participate in this live check.
local function confusable(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        return not player_resistance.clarity(ctx, hit.defender)
    end

    return not has(definition(ctx, hit).flags, flags.CLARITY)
end

-- Named predicates keep the source choice table declarative and readable.
local function not_fiery(ctx, hit)
    return not fiery_body(ctx, hit)
end

-- Native ice immunity removes Freezing before the weighted draw.
local function not_icy(ctx, hit)
    return not icy_body(ctx, hit)
end

-- Summoned tissue does not grant a vampiric recovery packet.
local function vampiric(ctx, hit)
    return natural_or_plant(ctx, hit) and
        not ctx:has(hit.defender, component.SUMMON)
end

local entries = {
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
        valid = natural_or_plant,
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

-- Recheck the same eligibility in both loops so a mod's live rule changes
-- neither the source order nor the RNG bound between brand and flavour use.
function choice.choose(ctx, hit)
    local total = 0

    for _, entry in ipairs(entries) do
        if not entry.valid or entry.valid(ctx, hit) then
            total = total + entry.weight
        end
    end

    local draw = roll.melee(ctx, total)

    for _, entry in ipairs(entries) do
        if not entry.valid or entry.valid(ctx, hit) then
            draw = draw - entry.weight

            if draw < 0 then
                return entry.id
            end
        end
    end

    error("chaos contact has no eligible outcome")
end

return choice
