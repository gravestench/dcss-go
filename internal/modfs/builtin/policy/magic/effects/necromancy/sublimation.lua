local catalog = require("policy.catalog")
local forms = require("policy.magic.effects.forms.player")
local registry = require("policy.magic.effects.registry")
local statuses = require("policy.magic.effects.statuses.player")
local vampire = require("policy.character.vampire")

local sublimation = {}

-- Species and transformed bodies without usable blood cannot trade HP for MP.
local function can_bleed(ctx, player)
    local origin = ctx:get(player, "core.player")
    local species = catalog.get("species", origin.species_id)
    local form = ctx:get(player, "magic.player_form")
    local active_form = form and form.remaining_aut > 0 and form.form_id or ""

    return not vampire.bloodless(ctx, player) and
        species.undead_type ~= "US_UNDEAD" and
        species.id ~= "SP_GARGOYLE" and
        species.id ~= "SP_DJINNI" and
        active_form ~= "lich" and active_form ~= "statue" and
        active_form ~= "storm" and forms.can_bleed(ctx, player)
end

-- Avoid a zero-bound RNG call when the chance is certain at low spell power.
local function chance(ctx, numerator, denominator)
    return denominator <= numerator or
        ctx:random("spell", denominator) < numerator
end

-- Stochastically round the HP floor so each cast keeps the intended average safety margin.
local function random_divide(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Source: spl-util.cc:casting_uselessness_reason and spl-other.cc:
-- cast_sublimation_of_blood. Abort conditions are checked before spending MP.
-- Example: A player at full MP cannot sublime blood into more MP.
-- Reject full MP, bloodless bodies, Death's Door, and critical HP before paying spell cost.
function sublimation.prepare(ctx, player)
    local magic = ctx:get(player, "core.magic")
    local health = ctx:get(player, "core.health")

    if magic.current >= magic.max then
        return "Your reserves of magic are already full."
    end

    if not can_bleed(ctx, player) then
        return "You have no blood to sublime."
    end

    if statuses.death_door_active(ctx, player) then
        return "You can't draw power from your own body while in death's door."
    end

    if health.current <= 2 then
        return "Your attempt to draw power from your own body fails."
    end

    return nil
end

-- Convert HP to MP one point at a time, with power limiting both extra HP loss and early stopping.
function sublimation.resolve(ctx, player, _, _, power)
    local health = ctx:get(player, "core.health")
    local magic = ctx:get(player, "core.magic")
    local min_hp = math.max(1, random_divide(ctx, health.current, 10))
    local gained = 0

    while magic.current < magic.max and health.current > min_hp do
        magic.current = magic.current + 1
        health.current = math.max(1, health.current - 1)
        gained = gained + 1

        local extra_rolls = health.current > min_hp and 3 or 0

        for _ = 1, extra_rolls do
            if chance(ctx, 6, power) then
                health.current = math.max(1, health.current - 1)
            end
        end

        if chance(ctx, 6, power) then
            break
        end
    end

    ctx:set(player, "core.health", health)
    ctx:set(player, "core.magic", magic)

    if gained > 0 then
        ctx:emit("spell", "You draw magical energy from your own body!")
    else
        ctx:emit("spell", "Your attempt to draw power from your own body fails.")
    end
end

registry.add("SPELL_SUBLIMATION_OF_BLOOD", sublimation)

return sublimation
