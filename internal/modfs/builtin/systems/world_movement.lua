local catalog = require("policy.catalog")
local constriction = require("policy.combat.constriction")
local player_constriction = require("policy.combat.player_constriction")
local monster_stats = require("policy.combat.monster_stats")
local targets = require("policy.ai.targets")
local clutch = require("policy.magic.effects.statuses.vile_clutch")
local fastroot = require("policy.magic.effects.zaps.fastroot")
local vine_grip = require("policy.combat.monster_plants.vine_grip")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local acrobat = require("policy.jewellery.acrobat")
local trap_held = require("policy.traps.held")
local barbs = require("policy.combat.barbs")
local roll = require("policy.combat.monster_roll")
local opportunity = require("policy.combat.opportunity_attacks")
local xom_cloud_trail = require("policy.religion.xom.cloud_trail")
local xom_stairs = require("policy.religion.xom.stair_repel")
local passage = require("policy.religion.fedhas.pass_through")
local channels = require("constants.message_channels")
local categories = require("constants.catalog")
local monsters = require("ids.monsters")

-- Theory of operation: Movement first handles escape and occupied cells, then commits a legal destination.
-- A failed constriction escape spends the movement action; a successful one costs the holder energy.
local function escape_grasp(ctx, actor, intent)
    local grip = ctx:get(actor, component.CONSTRICTION)

    if not grip then
        return true
    end

    local constrictor = ctx:get(grip.by, component.ACTOR)

    if not constrictor then
        error("constrictor " .. ctx:id(grip.by) .. " has no actor")
    end

    local definition = catalog.get("monsters", constrictor.kind_id)
    grip.escape_attempts = grip.escape_attempts + 1
    ctx:set(actor, component.CONSTRICTION, grip)

    local player = actor == ctx:player()
    local escaped

    if player then
        escaped = constriction.escape(ctx, grip.escape_attempts,
            monster_stats.hit_dice(ctx, grip.by, definition))
    else
        escaped = constriction.monster_escape(ctx,
            grip.escape_attempts,
            monster_stats.hit_dice(ctx, grip.by, definition))
    end

    if not escaped then
        intent.kind = intent_ids.WAIT
        ctx:set(actor, component.INTENT, intent)

        if player then
            ctx:emit("combat", "The " .. definition.name ..
                "'s grasp on you weakens, but your attempt to escape fails.")
        end

        return false
    end

    ctx:remove(actor, component.CONSTRICTION)

    if not player then
        return true
    end

    local energy = ctx:get(grip.by, component.MONSTER_ENERGY)

    if not energy then
        error("constrictor " .. ctx:id(grip.by) .. " has no energy")
    end

    energy.points = energy.points - 5
    ctx:set(grip.by, component.MONSTER_ENERGY, energy)
    ctx:emit("combat", "You escape the " .. definition.name .. "'s grasp.")

    return true
end

local system = {}

-- Movement converts failed escape attempts into WAIT and updates position before melee targeting.
function system.update(ctx, actor, elapsed_aut)
    local intent = ctx:get(actor, component.INTENT)

    if not intent or intent.kind ~= intent_ids.MOVE then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if not position then
        error("moving actor " .. ctx:id(actor) .. " has no position")
    end

    -- Net escape is attempted before actor movement or occupied-cell melee conversion.
    if ctx:has(actor, component.TRAP_HELD) then
        trap_held.escape(ctx, actor)
        intent.kind = intent_ids.WAIT
        ctx:set(actor, component.INTENT, intent)

        return
    end

    -- Monsters resolve their own constriction, clutch, and roots before destination checks.
    if actor ~= ctx:player() then
        if not player_constriction.escape(ctx, actor) or
            not clutch.escape(ctx, actor) or
            not fastroot.escape(ctx, actor) or
            not vine_grip.escape(ctx, actor) then
            intent.kind = intent_ids.WAIT
            ctx:set(actor, component.INTENT, intent)

            return
        end
    end

    local x = position.x + intent.dx
    local y = position.y + intent.dy
    local occupied = ctx:actor_at(position.level_id, x, y)
    local passable_plant = passage.at(ctx, actor,
        position.level_id, x, y)

    -- Reclassify an occupied destination before the combat system reads this intent.
    if occupied and not passable_plant then
        if actor ~= ctx:player() and
            not targets.enemy(ctx, actor, occupied) then
            intent.kind = intent_ids.WAIT
        else
            intent.kind = intent_ids.MELEE
        end
        ctx:set(actor, component.INTENT, intent)

        return
    end

    -- A constricted monster can still strike an occupied neighbor. Source
    -- movement tries to escape only after ruling out that melee action.
    if actor ~= ctx:player() and
        not escape_grasp(ctx, actor, intent) then
        return
    end

    if actor == ctx:player() and
        (not fastroot.escape(ctx, actor) or
            not vine_grip.escape(ctx, actor) or
            not escape_grasp(ctx, actor, intent)) then
        return
    end

    -- Source opportunity strikes resolve while the player still occupies
    -- the old cell. A lethal or displacing strike cancels the pending move.
    if actor == ctx:player() and not opportunity.run(ctx, position, {
        level_id = position.level_id,
        x = x,
        y = y,
    }, elapsed_aut) then
        intent.kind = intent_ids.WAIT
        ctx:set(actor, component.INTENT, intent)

        return
    end

    -- Only a free destination and completed escape reaches the position mutation.
    -- Xom's trail clouds the vacated cell, not a failed move's origin.
    if actor == ctx:player() then
        xom_cloud_trail.leave(ctx, actor, position)
    end

    if passable_plant then
        local origin_actors = ctx:actors_at(position.level_id,
            position.x, position.y)

        if #origin_actors == 1 then
            local plant_actor = ctx:get(passable_plant, component.ACTOR)
            local definition = catalog.get(categories.MONSTERS,
                plant_actor.kind_id)
            local growth = definition.genus_id == monsters.MONS_FUNGUS and
                "fungus" or "plants"

            ctx:emit(channels.MOVEMENT,
                "You walk carefully through the " .. growth .. ".")
        end
    end

    ctx:move_actor(actor, position.level_id, x, y,
        passable_plant ~= nil)
    barbs.moved(ctx, actor, elapsed_aut)
    roll.moved(ctx, actor)

    if actor == ctx:player() then
        acrobat.moved(ctx, actor)
        xom_stairs.on_move(ctx, actor, {
            level_id = position.level_id,
            x = x,
            y = y,
        })
    end
end

register.system({
    id = "world.movement",
    scope = "active",
    query = {},
    after = { "attack.spell" },
    before = { "attack.combat" },
    update = system.update,
})

return system
