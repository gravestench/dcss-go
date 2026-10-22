
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local slow = require("policy.combat.monster_hexes.slow")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local species = require("ids.species")

local test = {}

-- Slow applies the source minimum ten turns to a player.
function test.run()
    local caster = 101
    local player = 202
    local ctx = {
        values = {
            [caster] = {
                [component.ACTOR] = {
                    kind_id = monsters.MONS_ORC_WIZARD,
                },
            },

            [player] = {
                [component.PLAYER] = {
                    species_id = species.SP_HUMAN,
                },
            },
        },
    }

    -- Read the player Slow component after the monster hex lands.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    -- Create the first Slow timer so minimum duration can be checked.
    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    -- Force low duration dice to expose the ten-turn floor.
    function ctx:random()
        return 0
    end

    local profile = catalog.get("monster_beams", spells.SPELL_SLOW)

    slow.apply(ctx, caster, player, profile)

    local status = ctx:get(player, component.PLAYER_SLOW)

    harness.equal(status.remaining_aut, 150,
        "source minimum ten turns saves fifteen slowed turns")
end

return test
