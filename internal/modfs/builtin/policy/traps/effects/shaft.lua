-- Source: traps.cc and generic_shaft_dest.
local catalog = require("policy.catalog")
local component = require("constants.component")
local habitat = require("policy.combat.monster_habitat")
local intelligence = require("constants.monster_intelligence")
local relocation = require("policy.world.monster_relocation")
local streams = require("constants.rng_streams")

local effect = {}

-- A falling monster needs an unoccupied habitat cell below before the shaft collapses.
local function landing(ctx, actor, level_id)
    local width, height = ctx:level_size(level_id)

    if not width then
        return nil, nil
    end

    for _ = 1, 1000 do
        local x = ctx:random(streams.TRAPS, width)
        local y = ctx:random(streams.TRAPS, height)

        if not ctx:actor_at(level_id, x, y) and
            habitat.at(ctx, actor, level_id, x, y) then
            return x, y
        end
    end

    return nil, nil
end

-- Known player shafts are safe here; eligible monsters get the separate fall roll.
-- Example: effect.trigger(ctx, nil, player, site) leaves a known shaft intact for the player.
function effect.trigger(ctx, _, actor, site)
    -- A known shaft is safe for the player. The separate malevolence rule
    -- handles surprise shaft effects on the player.
    if actor == ctx:player() then
        return false
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get("monsters", state.kind_id)

    if intelligence.rank[definition.intelligence_id] >=
        intelligence.rank[intelligence.HUMAN] then
        return false
    end

    if ctx:random(streams.TRAPS, 4) == 0 then
        return false
    end

    local x, y = landing(ctx, actor, site.level_id + 1)

    if not x then
        return false
    end

    relocation.move(ctx, actor, site.level_id + 1, x, y)
    ctx:emit("trap", "A shaft crumbles and collapses.")

    return true
end

return effect
