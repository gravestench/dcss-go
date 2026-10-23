-- Source: player.cc:get_teleportitis_level, player-reacts.cc:player_reacts,
-- and spl-transloc.cc:_teleport_player. A failed landing or quiet landing
-- consumes the trigger without relocating the player.
local capabilities = require("constants.mutation_capabilities")
local catalog = require("policy.catalog")
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local flight = require("policy.combat.flight")
local ids = require("policy.magic.effects.zaps.ids")
local monster_flags = require("constants.monster_flags")
local mutations = require("ids.mutations")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local traits = require("policy.character.traits")
local vision = require("policy.character.vision")
local water = require("policy.character.water")
local landings = require("policy.world.teleport_landings")

local teleportitis = {}

-- Inspect the monster's declared flags rather than its name; stationary or
-- neutral monsters should not count as a hostile destination incentive.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Convert mutation level to the per-turn teleportitis rate consumed by the
-- timer, leaving the scheduling decision in one tick handler.
function teleportitis.rate(level)
    return level * 6
end

-- Reject occupied or blocked cells before terrain hazards; flight and swim
-- capabilities can make a cell safe that is dangerous for another player.
local function can_land(ctx, player, level_id, x, y)
    if not ctx:walkable(level_id, x, y) or
        ctx:actor_at(level_id, x, y) or
        not landings.allowed(ctx, level_id, x, y) then
        return false
    end

    local feature = ctx:cell(level_id, x, y)

    if flight.active(ctx, player) then
        return true
    end

    return feature ~= terrain.DNGN_LAVA and
        (feature ~= terrain.DNGN_DEEP_WATER or
            water.can_swim(ctx, player))
end

-- Look for a live nearby enemy at a candidate destination; teleportitis is
-- meant to place the player in danger, not on arbitrary safe floor.
local function hostile_near(ctx, player, level_id, x, y)
    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local actor = ctx:get(monster, component.ACTOR)
        local position = ctx:get(monster, component.POSITION)
        local health = ctx:get(monster, component.HEALTH)

        if health.current > 0 and position.level_id == level_id and
            targets.enemy(ctx, player, monster) and
            ctx:visible(level_id, x, y, 7, position.x, position.y) then
            local definition = catalog.get("monsters", actor.kind_id)

            if not has_flag(definition, monster_flags.NO_THREAT) then
                return true
            end
        end
    end

    return false
end

-- Test at most 500 cells; the first safe landing succeeds only if a hostile is visible nearby.
-- Example: random teleport searches for a walkable landing cell near a hostile monster.
function teleportitis.destination(ctx, player, position)
    local width, height = ctx:level_size(position.level_id)

    -- The source samples at most 500 whole-floor candidates. It does not
    -- retry when its first valid candidate lacks a nearby hostile monster.
    for _ = 1, 500 do
        local x = ctx:random("teleport", width)
        local y = ctx:random("teleport", height)

        if can_land(ctx, player, position.level_id, x, y) then
            if hostile_near(ctx, player, position.level_id, x, y) then
                return x, y
            end

            return nil, nil
        end
    end

    return nil, nil
end

-- Advance the saved chance on elapsed aut and draw only when the mutation is
-- active. A failed destination search still respects the source draw budget.
function teleportitis.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    local level = effects.sum(ctx, player,
        capabilities.TELEPORTITIS_RATE)

    if level <= 0 then
        return
    end

    local choice = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", choice.species_id)

    local forms = require("policy.magic.effects.forms.player")

    if traits.stasis(species) or forms.stasis(ctx, player) or
        ctx:random("mutation", 100) >= math.min(100, aut) or
        ctx:random("mutation", math.floor(100 / level)) ~= 0 then
        return
    end

    local origin = ctx:get(player, component.POSITION)
    local x, y = teleportitis.destination(ctx, player, origin)

    if not x then
        return
    end

    ctx:emit("mutation", "You feel strangely unstable.")
    ctx:emit("mutation", "You are yanked towards a nearby monster!")

    local message = "Your surroundings suddenly seem different."

    if x == origin.x and y == origin.y then
        message = "Your surroundings flicker for a moment."
    elseif ctx:visible(origin.level_id, origin.x, origin.y,
        vision.radius(ctx, player), x, y) then
        message = "Your surroundings seem slightly different."
    end

    cloud.place(ctx, cloud_ids.CLOUD_TLOC_ENERGY, player, origin.level_id,
        origin.x, origin.y,
        (1 + ctx:random("teleport", 3)) * 10)

    if x ~= origin.x or y ~= origin.y then
        ctx:move_actor(player, origin.level_id, x, y)
    end

    ctx:emit("mutation", message)
end

effects.add(mutations.MUT_TELEPORT, {
    [capabilities.TELEPORTITIS_RATE] = teleportitis.rate,
})

return teleportitis
