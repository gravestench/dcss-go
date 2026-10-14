-- Active monster decisions from ai.go. Movement and combat resolve the intent.
local memory = require("policy.ai.memory")
local wander = require("policy.ai.wander")
local route = require("policy.ai.route")
local spell = require("policy.ai.spell")
local ranged = require("policy.ai.ranged")
local net = require("policy.combat.net")

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

    local player_visible = ctx:visible(
        position.level_id,
        position.x,
        position.y,
        7,
        player.x,
        player.y
    )
    local retreating = state.bat_retreat_actions > 0

    if retreating then
        state.bat_retreat_actions = state.bat_retreat_actions - 1
        state.behavior = "wander"
        state.target_x = 0
        state.target_y = 0
    else
        memory.update(ctx, state, position, player, player_visible)
    end

    if player_visible and not retreating then
        local intent = spell.choose(ctx, entity, position, player)

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

    if state.behavior == "wander" then
        wander.update(ctx, entity, state, position)

        if state.target_x == 0 and state.target_y == 0 then
            return state, {
                kind = 6,
            }
        end
    end

    local intent = route.follow(ctx, entity, state, position, player, player_entity)

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

register.system({
    id = "monster.decision",
    scope = "active",
    query = {},
    after = { "monster.regeneration" },
    before = { "world.stairs" },
    update = function(ctx, entity)
        if not ctx:has(entity, "core.ai") then
            return
        end

        local health = ctx:get(entity, "core.health")

        if not health or health.current <= 0 then
            return
        end

        local combat = ctx:get(entity, "core.combat")

        if combat then
            combat.shield_blocks = 0
            ctx:set(entity, "core.combat", combat)
        end

        if ctx:has(entity, "core.intent") then
            error("monster " .. ctx:id(entity) .. " already has an intent")
        end

        local state = ctx:get(entity, "core.ai")

        if not state then
            error("monster " .. ctx:id(entity) .. " has no AI")
        end

        local held = ctx:get(entity, "projectile.held")

        if held then
            net.struggle(ctx, entity, held)
            ctx:add(entity, "core.intent", {
                kind = 6,
            })

            return
        end

        local next_state, intent = choose_intent(ctx, entity, state)
        ctx:set(entity, "core.ai", next_state)
        ctx:add(entity, "core.intent", intent)
    end,
})
