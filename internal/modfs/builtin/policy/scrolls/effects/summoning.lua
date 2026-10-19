-- Source: item-use.cc:SCR_SUMMONING calls summon_shadow_creatures.
local allies = require("policy.character.allies")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local item_ids = require("ids.items")
local pool = require("policy.population.pool")
local scrolls = require("policy.scrolls")
local summons = require("policy.magic.effects.summons.common")

local effect = {}

-- Filter the local monster catalog to legal shadow-creature candidates before draws.
local function population(ctx, player)
    local position = ctx:get(player, "core.position")
    local allowed = {}

    for _, definition in ipairs(catalog.all(categories.MONSTERS)) do
        if definition.status ~= "removed" and
            definition.status ~= "enum_only" then
            allowed[definition.id] = true
        end
    end

    return pool.at_depth(position.level_id, allowed, "")
end

-- Known ally restrictions stop a pointless read before any summon RNG is consumed.
function effect.prepare(ctx, player, request)
    if request.known and allies.forbidden(ctx, player) then
        return {
            message = "You cannot coerce anything to answer your summons.",
        }
    end

    return nil
end

-- Example: Summoning rolls two to four attempts from the eligible local monster pool.
-- Recheck No Love on execution, then choose summon attempts from the local pool.
function effect.apply(ctx, player)
    if allies.forbidden(ctx, player) then
        ctx:emit("read", "Nothing happens.")

        return
    end

    local choices, total = population(ctx, player)

    if total == 0 then
        ctx:emit("read", "Nothing happens.")

        return
    end

    ctx:emit("read", "Wisps of shadow whirl around you...")

    local count = 2 + ctx:random("spell", 2) +
        ctx:random("spell", 2)

    for _ = 1, count do
        local kind_id = pool.pick(ctx, choices, total)
        local definition = catalog.get(categories.MONSTERS, kind_id)
        local degree = math.min(4,
            1 + math.floor(17 / math.max(definition.hd - 3, 1)))

        summons.spawn(ctx, player, item_ids.SCR_SUMMONING,
            kind_id, degree, 20, {
                source_category = categories.ITEMS,
            })
    end
end

scrolls.register(item_ids.SCR_SUMMONING, effect)

return effect
