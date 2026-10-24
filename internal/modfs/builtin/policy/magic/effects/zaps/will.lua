local units = require("constants.willpower")
local armour_egos = require("constants.armour_egos")

local will = {}

-- Guile on the caster affects a target's saving throw, not the target's
-- owned willpower. Both monster and player armour use these slots.
local function caster_has_guile(ctx, source)
    if not source then
        return false
    end

    local equipment = require("policy.combat.equipment")
    local worn = equipment.worn(ctx, source, {
        body = true,
        cloak = true,
        head = true,
        gloves = true,
        boots = true,
        shield = true,
    })

    for _, entry in pairs(worn) do
        if entry.ego == armour_egos.GUILE then
            return true
        end
    end

    return false
end

-- Example: A monster with willpower 5000 is immune before the two spell resistance dice are rolled.
-- Treat source sentinel willpower as an immunity gate before enchant power consumes resistance dice.
function will.invulnerable(definition)
    return (definition.willpower or 0) >= units.INVULNERABLE
end

-- Return the source check_willpower margin after two named-stream draws.
-- Phantom Mirror needs the margin itself, while ordinary hexes test its sign.
function will.margin(ctx, definition, enchant_power, target, stream,
    source)
    if will.invulnerable(definition) then
        return 100
    end

    local resistance

    if target then
        -- The live owner imports equipment, which can import this spell
        -- policy during startup. Load it only when an actor makes a save.
        local monster_willpower = require(
            "policy.combat.monster_willpower")

        resistance = monster_willpower.level(ctx, target, definition)
    else
        -- Targetless formula probes cannot own equipment or statuses.
        resistance = definition.willpower or 0

        if resistance < 0 then
            resistance = math.floor(definition.hd *
                -resistance * 4 / 3)
        end
    end

    if caster_has_guile(ctx, source) then
        resistance = math.max(0,
            resistance - 2 * units.PIP)
    end

    local stepped = math.floor(35 *
        math.log(1 + enchant_power / 35) / math.log(2) + 0.5)
    local threshold = 100 + resistance - stepped
    local chosen_stream = stream or "spell"
    local roll = ctx:random(chosen_stream, 100) +
        ctx:random(chosen_stream, 101)

    return threshold - roll
end

-- Source: actor.cc:check_willpower and beam.cc:ench_power_stepdown.
-- Monster casts pass their saved stream; player spells use the spell stream.
function will.resists(ctx, definition, enchant_power, target, stream,
    source)
    return will.margin(ctx, definition, enchant_power,
        target, stream, source) > 0
end

return will
