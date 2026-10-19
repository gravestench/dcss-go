local catalog = require("policy.catalog")
local constriction = require("policy.combat.constriction")
local player_constriction = require("policy.combat.player_constriction")
local targets = require("policy.ai.targets")
local clutch = require("policy.magic.effects.statuses.vile_clutch")
local fastroot = require("policy.magic.effects.zaps.fastroot")
local vine_grip = require("policy.combat.monster_plants.vine_grip")
local component = require("constants.component")
local intent_ids = require("constants.intent")
local acrobat = require("policy.jewellery.acrobat")
local trap_held = require("policy.traps.held")
local barbs = require("policy.combat.barbs")

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

    if not constriction.escape(ctx, grip.escape_attempts, definition.hd) then
        intent.kind = intent_ids.WAIT
        ctx:set(actor, component.INTENT, intent)
        ctx:emit("combat", "The " .. definition.name ..
            "'s grasp on you weakens, but your attempt to escape fails.")

        return false
    end

    ctx:remove(actor, component.CONSTRICTION)

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

    -- Reclassify an occupied destination before the combat system reads this intent.
    if occupied then
        if actor ~= ctx:player() and
            not targets.enemy(ctx, actor, occupied) then
            intent.kind = intent_ids.WAIT
        else
            intent.kind = intent_ids.MELEE
        end
        ctx:set(actor, component.INTENT, intent)

        return
    end

    if actor == ctx:player() and
        (not fastroot.escape(ctx, actor) or
            not vine_grip.escape(ctx, actor) or
            not escape_grasp(ctx, actor, intent)) then
        return
    end

    -- Only a free destination and completed escape reaches the position mutation.
    ctx:move_actor(actor, position.level_id, x, y)
    barbs.moved(ctx, actor, elapsed_aut)

    if actor == ctx:player() then
        acrobat.moved(ctx, actor)
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
