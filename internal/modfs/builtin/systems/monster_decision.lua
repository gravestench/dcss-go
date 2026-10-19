-- Theory of operation: AI commits one intent from current health and ally state; later systems execute it.
-- Active monster decisions from ai.go. Movement and combat resolve the intent.
local memory = require("policy.ai.memory")
local wander = require("policy.ai.wander")
local route = require("policy.ai.route")
local spell = require("policy.ai.spell")
local ranged = require("policy.ai.ranged")
local net = require("policy.combat.net")
local enchant = require("policy.combat.monster_enchant")
local confusion = require("policy.magic.effects.statuses.confusing_touch")
local habitat = require("policy.combat.monster_habitat")
local fear = require("policy.ai.fear")
local targets = require("policy.ai.targets")
local statuses = require("policy.magic.effects.statuses.player")
local allies = require("policy.character.allies")
local awareness = require("policy.ai.awareness")
local invisibility = require("policy.potions.invisibility")
local component = require("constants.component")

-- Allies follow the player when no enemy exists; they wait instead of striking their adjacent leader.
local function choose_actor_target(ctx, entity, state, position)
    local target = targets.nearest(ctx, entity, position, 7)
    local attack_goal = target ~= nil

    if not target then
        if not targets.allied(ctx, entity) then
            return nil
        end

        target = ctx:player()
    end

    local destination = ctx:get(target, "core.position")

    if not destination or destination.level_id ~= position.level_id then
        return state, { kind = 6 }
    end

    state.behavior = "seek"
    state.target_x = destination.x
    state.target_y = destination.y
    state.memory_until_aut = ctx:aut() + 250

    if not attack_goal and
        math.max(math.abs(position.x - destination.x),
            math.abs(position.y - destination.y)) <= 1 then
        return state, { kind = 6 }
    end

    return state, route.follow(ctx, entity, state, position,
        destination, target, attack_goal)
end

-- Select intent from current ally and target state; execution remains with movement and attack systems.
local function choose_intent(ctx, entity, state)
    local position = ctx:get(entity, "core.position")

    if not position then
        error("monster " .. ctx:id(entity) .. " has no position")
    end

    local player_entity = ctx:player()
    local player = ctx:get(player_entity, "core.position")

    if not player then
        error("player " .. ctx:id(player_entity) .. " has no position")
    end

    if position.level_id ~= player.level_id then
        error("monster " .. ctx:id(entity) .. " is not on the active floor")
    end

    if not ctx:cell(position.level_id, position.x, position.y) then
        error("monster level " .. position.level_id .. " is missing")
    end

    -- Blinding and invisibility checks precede geometric sight before memory updates.
    local player_visible = not enchant.blinded(ctx, entity) and
        not statuses.enfeeble_blinded(ctx, entity) and
        invisibility.visible_to(ctx, player_entity, entity) and ctx:visible(
        position.level_id,
        position.x,
        position.y,
        7,
        player.x,
        player.y
    )
    local player_detected = awareness.detects(ctx, entity, state,
        player_visible)
    local retreating = state.bat_retreat_actions > 0

    if retreating then
        state.bat_retreat_actions = state.bat_retreat_actions - 1
        state.behavior = "wander"
        state.target_x = 0
        state.target_y = 0
    else
        memory.update(ctx, state, position, player, player_detected)
    end

    -- A detected player offers spells first, launcher attacks second, and thrown attacks last.
    if player_detected and not retreating then
        local intent = spell.choose(ctx, entity, position, player, false)

        if not intent then
            local launcher_intent, has_launcher = ranged.choose_launcher(ctx, entity, position, player)

            if has_launcher then
                intent = launcher_intent
            else
                intent = ranged.choose_throw(ctx, entity, position, player)
            end
        end

        if intent then
            return state, intent
        end
    end

    -- Wandering may create a new target; no target produces WAIT rather than a blind route step.
    if state.behavior == "wander" then
        wander.update(ctx, entity, state, position)

        if state.target_x == 0 and state.target_y == 0 then
            return state, {
                kind = 6,
            }
        end
    end

    local intent = route.follow(ctx, entity, state, position, player,
        player_entity, state.behavior ~= "wander")

    if retreating and state.bat_retreat_actions == 0 then
        state.behavior = "seek"
        state.target_x = player.x
        state.target_y = player.y
    end

    if retreating and intent.kind == 2 then
        return state, {
            kind = 6,
        }
    end

    return state, intent
end

local system = {}

-- Monster AI writes an intent only after regeneration and status effects have updated its state.
function system.update(ctx, entity)
    if not ctx:has(entity, "core.ai") then
        return
    end

    local health = ctx:get(entity, "core.health")

    if not health or health.current <= 0 then
        return
    end

    allies.on_monster_turn(ctx, entity)

    local combat = ctx:get(entity, "core.combat")

    if combat then
        combat.shield_blocks = 0
        ctx:set(entity, "core.combat", combat)
    end

    -- A surviving summon may carry an intent from its controller; other stale intents are invalid.
    if ctx:has(entity, "core.intent") then
        if ctx:has(entity, "magic.summon") then
            return
        end

        error("monster " .. ctx:id(entity) .. " already has an intent")
    end

    local state = ctx:get(entity, "core.ai")

    if not state then
        error("monster " .. ctx:id(entity) .. " has no AI")
    end

    if ctx:has(entity, "zap.paralysis") then
        ctx:add(entity, "core.intent", {
            kind = 6,
        })

        return
    end

    if statuses.hibernating(ctx, entity) or
        statuses.petrified(ctx, entity) then
        ctx:add(entity, "core.intent", {
            kind = 6,
        })

        return
    end

    if statuses.enfeeble_dazed(ctx, entity) then
        ctx:add(entity, "core.intent", {
            kind = 6,
        })

        return
    end

    local held = ctx:get(entity, "projectile.held")

    if held then
        net.struggle(ctx, entity, held)
        ctx:add(entity, "core.intent", {
            kind = 6,
        })

        return
    end

    -- Confusion draws both displacement axes even if the final cell forces WAIT.
    if confusion.active(ctx, entity) then
        local position = ctx:get(entity, "core.position")
        local player_position = ctx:get(ctx:player(), "core.position")
        local dx = ctx:random("ai", 3) - 1
        local dy = ctx:random("ai", 3) - 1
        local x = position.x + dx
        local y = position.y + dy
        local intent = { kind = 6 }

        if x == player_position.x and y == player_position.y then
            intent = { kind = 2, dx = dx, dy = dy }
        elseif (dx ~= 0 or dy ~= 0) and
            habitat.at(ctx, entity, position.level_id, x, y) and
            not ctx:actor_at(position.level_id, x, y) then
            intent = { kind = 1, dx = dx, dy = dy }
        end

        ctx:add(entity, "core.intent", intent)

        return
    end

    -- A frightened monster still tries a fear-compatible spell before fleeing.
    if statuses.fear_active(ctx, entity) then
        local position = ctx:get(entity, "core.position")
        local player_position = ctx:get(ctx:player(), "core.position")
        local intent = spell.choose(ctx, entity, position, player_position,
            true)

        if not intent then
            intent = fear.flee(ctx, entity, position, player_position)
        end

        ctx:add(entity, "core.intent", intent)

        return
    end

    -- Haunt binds a hostile wraith to its victim even when that victim is
    -- another monster or has left sight. The shared route owner still
    -- decides whether it can move or strike the destination.
    if targets.allied(ctx, entity) or statuses.frenzied(ctx, entity) or
        ctx:has(entity, component.SUMMON_HAUNTING) then
        local next_state, intent = choose_actor_target(ctx, entity,
            state, ctx:get(entity, "core.position"))

        if next_state then
            ctx:set(entity, "core.ai", next_state)
            ctx:add(entity, "core.intent", intent)

            return
        end
    end

    local next_state, intent = choose_intent(ctx, entity, state)
    ctx:set(entity, "core.ai", next_state)
    ctx:add(entity, "core.intent", intent)
end

register.system({
    id = "monster.decision",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "world.stairs" },
    update = system.update,
})

return system
