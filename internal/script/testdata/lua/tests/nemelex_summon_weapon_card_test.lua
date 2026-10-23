-- Summon Weapon's tier controls its item kind, enchantment band, brand,
-- and the dancing ghost's derived combat power. The item is carried by
-- the summon so the normal expiry owner removes both together.
local cards = require("ids.cards")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local death = require("policy.death")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local items = require("ids.items")
local streams = require("constants.rng_streams")
local weapon_brands = require("constants.weapon_brands")

local test = {}

-- Deterministic zero draws choose the first weapon, first brand, and no
-- randart. Exact stats catch a ghost profile accidentally fixed at power 100.
function test.run(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 10,
        y = 10,
    })

    local three_draws = 0

    function game:random(stream, bound)
        if stream == streams.CARDS then
            if bound == 3 then
                three_draws = three_draws + 1

                if three_draws == 2 then
                    return 1
                end
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    effects.apply(game, player, cards.SUMMON_WEAPON, {
        tier = 0,
        power = 80,
    })

    local summons = ctx:query({ component.SUMMON })

    harness.equal(#summons, 1)

    local creature = summons[1]
    local carried = ctx:query({ component.CARRIED_BY })

    harness.equal(#carried, 1)
    harness.equal(ctx:get(carried[1], component.CARRIED_BY).holder,
        creature)

    local weapon = ctx:get(carried[1], component.ITEM)

    harness.equal(weapon.kind_id, items.WPN_QUARTERSTAFF)
    harness.equal(weapon.plus, -2)
    harness.equal(weapon.ego, weapon_brands.VENOM)
    harness.truthy(ctx:get(creature, constructs.DANCING_WEAPON))
    harness.equal(ctx:get(creature, component.SUMMON).source_id,
        cards.SUMMON_WEAPON)

    local dropped = death.drop_inventory(game, creature,
        ctx:get(creature, component.POSITION))

    harness.equal(#dropped, 0)
    harness.falsy(ctx:has(carried[1], component.ITEM),
        "dancing weapon death destroys its temporary item")
end

return test
