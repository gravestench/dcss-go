-- Rangers summons source-tier ranged allies under the common summon owner.
local cards = require("ids.cards")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- Tier two with an extra-monster coinflip gives two naga sharpshooters
-- and one deep elf master archer, all with source degree-three expiry.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local card_draws = 0

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            card_draws = card_draws + 1

            if card_draws == 1 then
                harness.equal(bound, 2)
            else
                harness.equal(bound, 8)
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    effects.apply(owner, player, cards.RANGERS, {
        tier = 2,
        power = 800,
    })

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned, 3)
    harness.equal(ctx:get(summoned[1], component.ACTOR).kind_id,
        monsters.MONS_NAGA_SHARPSHOOTER)
    harness.equal(ctx:get(summoned[2], component.ACTOR).kind_id,
        monsters.MONS_NAGA_SHARPSHOOTER)
    harness.equal(ctx:get(summoned[3], component.ACTOR).kind_id,
        monsters.MONS_DEEP_ELF_MASTER_ARCHER)
    harness.equal(card_draws, 4)
end

return test
