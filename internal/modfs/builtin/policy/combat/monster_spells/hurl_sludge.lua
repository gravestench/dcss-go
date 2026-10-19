local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local poison = require("policy.combat.monster_beams.poison")
local spells = require("ids.spells")
local temporary_terrain = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")

local hurl_sludge = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_HURL_SLUDGE)

hurl_sludge.before_damage = poison.before_damage

-- Example: hurl_sludge.plan(ctx, caster, foe) with reachable aim -> saved aim for later toxic-bog placement
-- Chooses the endpoint for a temporary toxic bog.
function hurl_sludge.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile)
end

-- beam.cc:bolt::finish_beam leaves toxic bog at the projectile's final
-- cell for 20–30 aut, except on lava and deep water.
function hurl_sludge.after_endpoint(ctx, caster, _, _, endpoint)
    local feature = ctx:cell(endpoint.level_id, endpoint.x, endpoint.y)

    if feature == terrain.DNGN_DEEP_WATER or
        feature == terrain.DNGN_LAVA then
        return
    end

    local duration = 20 + ctx:random("monster_spell", 11)

    temporary_terrain.place(ctx, caster, spells.SPELL_HURL_SLUDGE,
        endpoint.level_id, endpoint.x, endpoint.y,
        terrain.DNGN_TOXIC_BOG, duration)
end

-- The endpoint hook leaves temporary bog only where terrain permits it.
function hurl_sludge.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, hurl_sludge)
end

return hurl_sludge
