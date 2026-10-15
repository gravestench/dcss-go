local catalog = require("policy.catalog")
local constriction = require("policy.combat.constriction")
local player_constriction = require("policy.combat.player_constriction")
local targets = require("policy.ai.targets")
local clutch = require("policy.magic.effects.statuses.vile_clutch")
local fastroot = require("policy.magic.effects.zaps.fastroot")
local component = require("constants.component")
local intent_ids = require("constants.intent")

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

function system.update(ctx, actor)
    local intent = ctx:get(actor, component.INTENT)

    if not intent or intent.kind ~= intent_ids.MOVE then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if not position then
        error("moving actor " .. ctx:id(actor) .. " has no position")
    end

    if actor ~= ctx:player() then
        if not player_constriction.escape(ctx, actor) or
            not clutch.escape(ctx, actor) or
            not fastroot.escape(ctx, actor) then
            intent.kind = intent_ids.WAIT
            ctx:set(actor, component.INTENT, intent)

            return
        end
    end

    local x = position.x + intent.dx
    local y = position.y + intent.dy
    local occupied = ctx:actor_at(position.level_id, x, y)

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

    if actor == ctx:player() and not escape_grasp(ctx, actor, intent) then
        return
    end

    ctx:move_actor(actor, position.level_id, x, y)
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
