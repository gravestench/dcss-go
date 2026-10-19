-- Every player Haste source extends the same saved duration. The source
-- halves nominal turns for faster actions through haste_div's 2/3 rounding.
-- Example: haste.apply(ctx, player, 40, "potion") grants potion Haste.
local catalog = require("policy.catalog")
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local traits = require("policy.character.species_traits")

local haste = {}

-- Round the source two-thirds factor on the caller's saved RNG stream.
local function rounded_two_thirds(ctx, value, stream)
    local numerator = value * 2
    local whole = math.floor(numerator / 3)
    local remainder = numerator % 3

    if remainder > 0 and ctx:random(stream, 3) < remainder then
        return whole + 1
    end

    return whole
end

-- Stasis belongs to the player's species or current form, independent of
-- which potion or spell tried to add speed.
function haste.restriction(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", identity.species_id)

    if traits.stasis(species) or forms.stasis(ctx, player) then
        return "Your stasis prevents you from being hasted."
    end

    return nil
end

-- Power controls the random nominal spread; the shared timer caps at 40
-- turns after haste_div, so repeat sources extend but never replace it.
function haste.apply(ctx, player, power, stream)
    local restriction = haste.restriction(ctx, player)

    if restriction then
        return restriction
    end

    local durations = ctx:get(player, component.DURATIONS)

    if not durations then
        error("Haste requires player durations")
    end

    local previous = durations.haste_aut
    local turns = rounded_two_thirds(ctx,
        40 + ctx:random(stream, power), stream)

    durations.haste_aut = math.min(400, previous + turns * 10)
    ctx:set(player, component.DURATIONS, durations)

    if previous > 0 then
        return "You feel as though your hastened speed will last longer."
    end

    return "You feel yourself speed up."
end

return haste
