-- A charm changes a monster's allegiance, so its old vault patrol order
-- cannot continue competing with the ally's player-following behavior.
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- Cast the real Charm effect through its catalog entry and the shared world
-- fixture; a high resistance roll makes the target fail its willpower check.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 3, 3)
    local rat = fixture.actor(ctx, monsters.MONS_RAT, 4, 3)
    local game = fixture.context(ctx, player)
    local spell = catalog.get("spells", spells.SPELL_CHARMING)
    local intent = {
        dx = 1,
        dy = 0,
    }

    ctx:add(rat, component.MONSTER_PATROL, {
        level_id = 1,
        x = 4,
        y = 3,
    })

    -- Maximum legal draws make this ordinary rat fail Charm's will roll.
    function game:random(_, bound)
        return bound - 1
    end

    allegiance.cast_charm(game, player, intent, spell, 200)

    harness.truthy(allegiance.charmed(game, rat),
        "the spell applied charm")
    harness.falsy(ctx:has(rat, component.MONSTER_PATROL),
        "a charmed ally forgot its old vault patrol")
end

return test
