-- The source card calls torment_player on living characters, so nearby
-- monsters must not enter the area Torment owner. Undead and demonic players
-- instead receive Holy Word self-damage.
local area = require("policy.combat.torment_area")
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local harness = require("tests.harness")
local health = require("policy.combat.player_health")
local species = require("ids.species")

local test = {}

-- Replace downstream effect owners just long enough to observe routing.
-- Their damage and LOS behavior is covered by their separate rule tests.
function test.run(ctx)
    local player = ctx:create()
    local area_calls = 0
    local self_damage = 0

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })

    local old_area = area.apply
    local old_damage = health.damage

    area.apply = function(_, source)
        harness.equal(source, player)
        area_calls = area_calls + 1
    end

    health.damage = function(_, source, amount)
        harness.equal(source, player)
        self_damage = self_damage + amount
    end

    local success, message = pcall(function()
        effects.apply(ctx, player, cards.TORMENT, {})
        harness.equal(area_calls, 0)
        harness.equal(self_damage, 49)

        for _, kind_id in ipairs({
            species.SP_MUMMY,
            species.SP_DEMONSPAWN,
        }) do
            ctx:set(player, component.PLAYER, {
                species_id = kind_id,
            })

            effects.apply(ctx, player, cards.TORMENT, {})
        end

        harness.equal(area_calls, 0)
        harness.equal(self_damage, 147)
    end)

    area.apply = old_area
    health.damage = old_damage

    if not success then
        error(message)
    end
end

return test
