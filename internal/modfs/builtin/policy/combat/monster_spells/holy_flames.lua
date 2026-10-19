-- Holy Flames surrounds the selected foe with individually saved holy cloud
-- cells. It does not replace a cloud or displace a monster to complete a ring.
-- Source: spl-clouds.cc:holy_flames, mon-cast.cc:SPELL_HOLY_FLAMES.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local clouds = require("ids.clouds")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local placement = require("policy.clouds.placement")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local stats = require("policy.combat.monster_stats")
local streams = require("constants.rng_streams")
local wind = require("policy.combat.monster_support.still_winds")

local effect = {}

-- Source AI does not spend this cast while Still Winds prevents clouds.
function effect.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)

    if not source or wind.active_level(ctx, source.level_id) then
        return nil
    end

    return direct.plan(ctx, caster, foe, spells.SPELL_HOLY_FLAMES)
end

-- Use ordinary monster HD rather than spell HD: temporary brilliance boosts
-- spell power, but holy_flames reads the caster's hit dice for cloud life.
local function duration(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local hd = stats.hit_dice(ctx, caster, definition)

    return (8 + roll.average_two(ctx,
        streams.MONSTER_SPELL, hd * 3)) * 10
end

-- A blocked neighbor is skipped, but an adjacent player may have holy fire
-- placed beneath them: the source excludes monster occupancy only. Each
-- placement is the saved world-cloud entity natural exposure later reads.
local function surround(ctx, caster, destination, lifetime)
    local placed = 0

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = destination.x + dx
                local y = destination.y + dy
                local occupant = ctx:actor_at(destination.level_id,
                    x, y)

                if ctx:walkable(destination.level_id, x, y) and
                    (not occupant or occupant == ctx:player()) and
                    not placement.at(ctx, destination.level_id, x, y) and
                    placement.place(ctx, clouds.CLOUD_HOLY, caster,
                        destination.level_id, x, y, lifetime) then
                    placed = placed + 1
                end
            end
        end
    end

    return placed
end

-- The selected foe stays the center even when it is a monster rather than
-- the player. Its saved entity identity is checked before placing anything.
function effect.resolve(ctx, caster, foe, _, plan)
    local destination = direct.require(ctx, caster, foe, plan)
    local health = ctx:get(foe, component.HEALTH)

    if not health or health.current <= 0 or
        wind.active_level(ctx, destination.level_id) then
        return
    end

    if surround(ctx, caster, destination, duration(ctx, caster)) == 0 then
        return
    end

    if foe == ctx:player() then
        ctx:emit(channels.SPELL,
            "Blessed fire suddenly surrounds you!")
    elseif senses.player_sees_actor(ctx, foe) then
        ctx:emit(channels.SPELL,
            "Blessed fire surrounds the monster!")
    end
end

return effect
