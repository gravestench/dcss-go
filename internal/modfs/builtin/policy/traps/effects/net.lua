-- Source: traps.cc:589-650. The trap launches a floor throwing net at the
-- player; a monster has a small chance to trigger it for the player.
local catalog = require("policy.catalog")
local component = require("constants.component")
local fighter = require("policy.combat.fighter")
local held = require("policy.traps.held")
local items = require("ids.items")
local intelligence = require("constants.monster_intelligence")
local streams = require("constants.rng_streams")

local effect = {}

local function triggered(ctx, actor)
    if actor == ctx:player() then
        return true
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get("monsters", state.kind_id)

    return intelligence.rank[definition.intelligence_id] >=
        intelligence.rank[intelligence.HUMAN] and
        ctx:random(streams.TRAPS, 3) == 0
end

local function evades(ctx, player, depth)
    local evasion = fighter.defense(ctx).ev
    local first = ctx:random(streams.TRAPS, math.max(1, 2 * evasion))
    local second = ctx:random(streams.TRAPS, math.max(1, 2 * evasion))

    return math.floor((first + second) / 2) > 18 + depth / 2
end

function effect.trigger(ctx, _, actor, site)
    local player = ctx:player()

    if ctx:has(player, component.TRAP_HELD) or not triggered(ctx, actor) then
        return
    end

    if evades(ctx, player, site.level_id) then
        ctx:emit("trap", "You avoid being caught in a net.")

        return
    end

    local position = ctx:get(player, component.POSITION)
    local net_item = ctx:create()

    ctx:add(net_item, component.ITEM, {
        kind_id = items.MI_THROWING_NET,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(net_item, component.POSITION, position)
    ctx:add(net_item, component.PROJECTILE_NET, {
        durability = 0,
    })
    held.catch_net(ctx, player, net_item)
    ctx:emit("trap", "You are caught in a net!")
end

return effect
