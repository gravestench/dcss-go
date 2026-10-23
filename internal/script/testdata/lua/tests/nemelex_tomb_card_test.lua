-- Tomb uses the production temporary-terrain schema so its walls and
-- restoration data remain saveable after a card action.
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local system = require("systems.religion_card_tomb")
local terrain = require("constants.terrain")

local test = {}

-- Source skips an occupied adjacent cell but seals the other seven for the
-- card's computed duration. The marker retains the original floor feature.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    fixture.actor(ctx, monsters.MONS_RAT, 8, 7)

    -- This sparse level records writes while keeping production ECS markers.
    function owner:set_cell(_, x, y, feature)
        self.cells[x .. ":" .. y] = feature
    end

    -- Zero variance and no skipped walls make the power formula observable.
    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)

        if bound == 6 then
            return 1
        end

        return 0
    end

    effects.apply(owner, player, cards.TOMB, {
        power = 200,
    })

    local markers = ctx:query({ component.TEMPORARY_TERRAIN })

    harness.equal(#markers, 7)
    harness.equal(owner:cell(1, 8, 7), terrain.DNGN_FLOOR)
    local groups = ctx:query({ component.RELIGION_CARD_TOMB })

    harness.equal(#groups, 1)
    harness.equal(#ctx:get(groups[1],
        component.RELIGION_CARD_TOMB).wall_markers, 7)

    for _, marker in ipairs(markers) do
        local state = ctx:get(marker, component.TEMPORARY_TERRAIN)

        harness.equal(state.source_kind_id, cards.TOMB)
        harness.equal(state.original_feature, terrain.DNGN_FLOOR)
        harness.equal(state.changed_feature, terrain.DNGN_ROCK_WALL)
        harness.equal(state.expires_aut, 200)
        harness.equal(owner:cell(1, state.x, state.y),
            terrain.DNGN_ROCK_WALL)
    end

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 9,
        y = 9,
    })

    system.update(owner)

    harness.equal(#ctx:query({ component.RELIGION_CARD_TOMB }), 0)
    harness.equal(#ctx:query({ component.TEMPORARY_TERRAIN }), 0)
    harness.equal(owner:cell(1, 7, 6), terrain.DNGN_FLOOR)
end

return test
