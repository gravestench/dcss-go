-- Elyvilon's ability menu uses the production registry, including source
-- ranks and Purification's unusual permission to work while confused.
local abilities = require("ids.abilities")
local commands = require("policy.commands.abilities")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local zap = require("policy.magic.effects.zaps.ids").component

local test = {}

-- Use an ECS player so menu checks read the same worship and status
-- components as a live game, without duplicating either schema.
local function worshipper(ctx)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.ELYVILON,
        piety = piety.breakpoint(1),
        penance = {},
    })
    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 30,
    })

    return player
end

-- Each rank grants exactly its source ability; a patron change or
-- penance removes all four without deleting saved piety.
local function ranks(ctx, player)
    local ids = {
        abilities.ELYVILON_PURIFICATION,
        abilities.ELYVILON_HEAL_OTHER,
        abilities.ELYVILON_HEAL_SELF,
        abilities.ELYVILON_DIVINE_VIGOUR,
    }
    local thresholds = { 1, 2, 3, 5 }
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(#ids, 4)

    for index, id in ipairs(ids) do
        local definition = registry.get(id)

        harness.truthy(definition, tostring(id))
        worship.piety = piety.breakpoint(thresholds[index])
        ctx:set(player, component.RELIGION_WORSHIP, worship)
        harness.truthy(registry.usable_now(ctx, player, definition))

        if index < #ids then
            harness.falsy(registry.usable_now(ctx, player,
                registry.get(ids[index + 1])))
        end
    end

    worship.penance[gods.ELYVILON] = 1
    ctx:set(player, component.RELIGION_WORSHIP, worship)

    for _, id in ipairs(ids) do
        harness.falsy(registry.usable_now(ctx, player,
            registry.get(id)))
    end
end

-- Purification is flagged conf_ok in source. The shared command policy
-- must consult that flag rather than reject every confused invocation.
local function confusion(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.penance[gods.ELYVILON] = 0
    worship.piety = 200
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    ctx:add(player, zap.PLAYER_CONFUSION, { remaining_aut = 10 })

    local cleanse = commands.prepare(ctx, player, {
        ability_id = abilities.ELYVILON_PURIFICATION,
    })
    local healing = commands.prepare(ctx, player, {
        ability_id = abilities.ELYVILON_HEAL_SELF,
    })

    harness.truthy(cleanse.intent)
    harness.equal(healing.message, "You are too confused!")
end

-- One fixture covers rank changes and command routing on the same actor.
function test.run(ctx)
    local player = worshipper(ctx)

    ranks(ctx, player)
    confusion(ctx, player)
end

return test
