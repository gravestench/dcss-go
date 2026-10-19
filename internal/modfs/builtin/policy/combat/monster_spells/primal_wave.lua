local beam = require("policy.combat.monster_beams")
local beam_power = require("policy.combat.monster_beams.power")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local displacement = require("policy.combat.monster_beams.displacement")
local explosion = require("policy.combat.explosion")
local spells = require("ids.spells")
local temporary_terrain = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")

local primal_wave = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_PRIMAL_WAVE)

-- Preserve fractional wave duration with the monster-spell stream.
local function random_round(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)

    if ctx:random("monster_spell", denominator) <
        numerator % denominator then
        return quotient + 1
    end

    return quotient
end

-- Example: primal_wave.plan(ctx, caster, foe) with reachable foe -> saved aim for later shallow-water splash
-- Targets the radius-one splash after the ray lands.
function primal_wave.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- The wave push uses incoming direction from the actual contact.
function primal_wave.after_hit(ctx, caster, defender, _, _, incoming)
    displacement.wave(ctx, caster, defender, incoming)
end

-- beam.cc:bolt::finish_beam creates a radius-one temporary splash for a
-- monster caster. Only floor and shallow-water cells can receive it.
function primal_wave.after_endpoint(ctx, caster, _, _, endpoint)
    local power = beam_power.caster_power(ctx, caster, profile)
    local count = 3 + 2 * ctx:random("monster_spell", 5)
    local duration = random_round(ctx, power * 4, 3) + 66
    local cells = explosion.cells(ctx, endpoint.level_id,
        endpoint.x, endpoint.y, 1)
    local changed = 0

    for _, cell in ipairs(cells) do
        if changed >= count then
            break
        end

        local feature = ctx:cell(endpoint.level_id, cell.x, cell.y)

        if feature == terrain.DNGN_FLOOR or
            feature == terrain.DNGN_SHALLOW_WATER then
            local distance = math.max(math.abs(cell.x - endpoint.x),
                math.abs(cell.y - endpoint.y))
            local tile_duration = duration + ctx:random("monster_spell",
                math.floor(duration / 2) + 1) - 20 * distance

            temporary_terrain.place(ctx, caster,
                spells.SPELL_PRIMAL_WAVE,
                endpoint.level_id, cell.x, cell.y,
                terrain.DNGN_SHALLOW_WATER,
                math.max(1, tile_duration))
            changed = changed + 1
        end
    end

    ctx:emit("combat", "The wave splashes down.")
end

-- The hit hook creates a radius-one splash only on eligible floor or shallow water.
function primal_wave.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, primal_wave)
end

return primal_wave
