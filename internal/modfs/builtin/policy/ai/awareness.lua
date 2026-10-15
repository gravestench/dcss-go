local catalog = require("policy.catalog")
local component = require("constants.component")
local intelligence = require("constants.monster_intelligence")
local stealth = require("policy.character.stealth")

local awareness = {}

function awareness.detects(ctx, monster, state, player_visible)
    if not player_visible then
        return false
    end

    if state.behavior ~= "wander" then
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
    local perception = math.max(4, 10 + rank * 4 + definition.hd)

    return ctx:random("ai", score) < perception + 1
end

return awareness
