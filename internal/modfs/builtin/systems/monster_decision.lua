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
local pacified_departure = require("policy.ai.pacified_departure")
local statuses = require("policy.magic.effects.statuses.player")
local allies = require("policy.character.allies")
local fedhas = require("policy.religion.gods.fedhas")
local jiyva = require("policy.religion.gods.jiyva")
local beogh = require("policy.religion.gods.beogh")
local jelly_feeding = require("policy.religion.jiyva.feeding")
local jelly_targets = require("policy.religion.jiyva.targets")
local awareness = require("policy.ai.awareness")
local invisibility = require("policy.potions.invisibility")
local component = require("constants.component")
local ugly_thing = require("policy.monsters.ugly_thing")
local elven_twins = require("policy.monsters.elven_twins")
local slime_lifecycle = require("policy.monsters.slime_lifecycle")
local breath = require("policy.combat.monster_breath")
local behaviors = require("constants.ai_behaviors")
local intents = require("constants.intent")

-- Allied casters offer spells against a visible enemy before routing toward
-- it. Frenzied and haunting hostiles retain the normal player awareness gate.
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

    state.behavior = behaviors.SEEK
    state.target_x = destination.x
    state.target_y = destination.y
    state.memory_until_aut = ctx:aut() + 250

    if attack_goal and targets.allied(ctx, entity) and
        not statuses.frenzied(ctx, entity) and
        ctx:visible(position.level_id,
        position.x, position.y, 7, destination.x, destination.y) then
        local intent = spell.choose(ctx, entity, target, false)

        if intent then
            return state, intent
        end
    end

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

    -- A pacified neutral actor pursues an exit before ordinary neutral
    -- wandering can replace its saved destination.
    local pacified = ctx:get(entity, component.ELYVILON_PACIFIED)

    if pacified and pacified.pacified then
        local next_state, intent = pacified_departure.intent(ctx,
            entity, state, position)

        if intent then
            return next_state, intent
        end
    end

    -- Neutral actors have no player foe. Let them wander without offering
    -- a hostile spell, missile, or melee intent against that actor.
    if not targets.enemy(ctx, entity, player_entity) then
        if state.behavior == behaviors.SLEEP then
            return state, { kind = intents.WAIT }
        end

        state.behavior = behaviors.WANDER
        state.target_x = 0
        state.target_y = 0
        local item = jelly_targets.item(ctx, entity, position)

        if item then
            state.target_x = item.x
            state.target_y = item.y

            return state, route.follow(ctx, entity, state, position,
                item, nil, false, true)
        end

        wander.update(ctx, entity, state, position)

        if state.target_x == 0 and state.target_y == 0 then
            return state, { kind = 6 }
        end

        return state, route.follow(ctx, entity, state, position, player,
            player_entity, false)
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

    -- Source vault sleepers wait until sight, sound, or injury alerts them.
    -- Convert a successful sight contest to ordinary pursuit before memory
    -- and spell selection inspect the role.
    if state.behavior == behaviors.SLEEP then
        if not player_detected then
            return state, { kind = 6 }
        end

        state.behavior = behaviors.WANDER
    end

    if retreating then
        state.bat_retreat_actions = state.bat_retreat_actions - 1
        state.behavior = behaviors.WANDER
        state.target_x = 0
        state.target_y = 0
    else
        memory.update(ctx, state, position, player, player_detected)
    end

    -- A detected player offers spells first, launcher attacks second, and thrown attacks last.
    if player_detected and not retreating then
        local intent = spell.choose(ctx, entity, player_entity, false)

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
    if state.behavior == behaviors.WANDER then
        wander.update(ctx, entity, state, position)

        if state.target_x == 0 and state.target_y == 0 then
            return state, {
                kind = 6,
            }
        end
    end

    local intent = route.follow(ctx, entity, state, position, player,
        player_entity, state.behavior ~= behaviors.WANDER)

    if retreating and state.bat_retreat_actions == 0 then
        state.behavior = behaviors.SEEK
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

    -- The source waits until the survivor sees the player to activate a
    -- pending twin grief response. Do this before choosing its action.
    elven_twins.maybe_energize(ctx, entity)

    breath.advance(ctx, entity)

    allies.on_monster_turn(ctx, entity)

    -- Source attitude-change policy runs before the monster chooses an
    -- action, so a newly neutral plant cannot attack on this same turn.
    fedhas.neutralise(ctx, ctx:player(), entity)
    jiyva.neutralise(ctx, ctx:player(), entity)
    beogh.convert_on_turn(ctx, ctx:player(), entity)

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

    -- Source slimes eat on their current cell before choosing a spell,
    -- attack, or move. A meal spends exactly this monster action.
    if jelly_feeding.act(ctx, entity) then
        ctx:add(entity, component.INTENT, {
            kind = intents.WAIT,
        })

        return
    end

    -- A source ugly-thing mutation is a natural special ability, so it
    -- spends this monster action rather than running before a second move
    -- or attack. Malmutate uses the same policy outside this turn phase.
    if ctx:has(entity, component.UGLY_THING) and
        ugly_thing.tick(ctx, entity) then
        ctx:add(entity, component.INTENT, {
            kind = 6,
        })

        return
    end

    -- Slime creatures choose division or combination before their usual
    -- route, spending the same scheduled action as another natural ability.
    if slime_lifecycle.tick(ctx, entity) then
        if ctx:has(entity, component.ACTOR) then
            ctx:add(entity, component.INTENT, {
                kind = intents.WAIT,
            })
        end

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
        local threat = targets.nearest(ctx, entity, position, 7)
        local threat_position = threat and
            ctx:get(threat, component.POSITION) or player_position
        local intent = threat and
            spell.choose(ctx, entity, threat, true)

        if not intent then
            intent = fear.flee(ctx, entity, position, threat_position)
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
