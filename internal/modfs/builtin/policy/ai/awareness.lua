local catalog = require("policy.catalog")
local component = require("constants.component")
local intelligence = require("constants.monster_intelligence")
local stealth = require("policy.character.stealth")
local monster_stats = require("policy.combat.monster_stats")
local behaviors = require("constants.ai_behaviors")

local awareness = {}

-- Sight only starts detection; a wandering sleeper still needs a stealth contest before waking.
-- Example: awareness.detects(ctx, monster, state, true) checks whether sight alerts a sleeping monster.
function awareness.detects(ctx, monster, state, player_visible)
    if not player_visible then
        return false
    end

    if state.behavior ~= behaviors.WANDER and
        state.behavior ~= behaviors.SLEEP then
        return true
    end

    local score = stealth.score(ctx, ctx:player())

    if score == 0 then
        return true
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local rank = intelligence.rank[definition.intelligence_id]

    if rank == nil then
        error("unknown monster intelligence " ..
            tostring(definition.intelligence_id))
    end

    -- shout.cc:check_awaken tests (10 + intelligence*4 + HD + 1)
    -- against the player's stealth score each time a wandering monster
    -- sees the player.
    local perception = math.max(4, 10 + rank * 4 +
        monster_stats.hit_dice(ctx, monster, definition))

    return ctx:random("ai", score) < perception + 1
end

-- Direct harm interrupts natural sleep. A known attacker gives the actor a
-- pursuit target; otherwise it wakes without inventing a remembered foe.
function awareness.wake_from_damage(ctx, monster, attacker)
    local state = ctx:get(monster, component.AI)

    if not state or state.behavior ~= behaviors.SLEEP then
        return
    end

    local source = attacker and ctx:get(attacker, component.POSITION)
    local position = ctx:get(monster, component.POSITION)

    state.behavior = behaviors.WANDER

    if source and position and source.level_id == position.level_id then
        state.behavior = behaviors.SEEK
        state.target_x = source.x
        state.target_y = source.y
        state.memory_until_aut = ctx:aut() + 250
    end

    ctx:set(monster, component.AI, state)
end

return awareness
