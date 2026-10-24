-- Source-generated shield egos use the same live worn-item entry as other
-- armour. Each test equips one real ECS buckler and reads production rules.
local component = require("constants.component")
local egos = require("constants.armour_egos")
local forms = require("constants.form_ids")
local items = require("ids.items")
local resistances = require("constants.resistance_ids")
local damage = require("policy.magic.damage")
local player_resistance = require("policy.combat.player_resistance")
local reflection = require("policy.combat.reflection")
local fixture = require("tests.fixtures.jewellery")
local harness = require("tests.harness")

local test = {}

-- Give a player one worn, source-generated shield ego without repeating
-- an item schema; equipment policy reads the same catalog as gameplay.
local function shield(ctx, ego)
    local game, player = fixture.player(ctx)
    local entity = fixture.carry(ctx, player, items.ARM_BUCKLER)
    local item = ctx:get(entity, component.ITEM)

    item.ego = ego
    ctx:set(entity, component.ITEM, item)
    ctx:add(entity, component.EQUIPPED, { slot = "shield" })

    return game, player, entity
end

-- Fire, cold, poison, and negative-energy checks must include the shield
-- slot, while the plain and Reflection egos add no resistance of their own.
local function resistance_egos(ctx)
    local ordinary, ordinary_player = shield(ctx, egos.NORMAL)

    harness.equal(damage.player_resistance(ordinary,
        ordinary_player, resistances.FIRE), 0,
        "ordinary shield adds no elemental resistance")

    local cases = {
        {
            ego = egos.FIRE_RESISTANCE,
            resistance = resistances.FIRE,
        },
        {
            ego = egos.COLD_RESISTANCE,
            resistance = resistances.COLD,
        },
        {
            ego = egos.RESISTANCE,
            resistance = resistances.FIRE,
        },
        {
            ego = egos.RESISTANCE,
            resistance = resistances.COLD,
        },
        {
            ego = egos.POSITIVE_ENERGY,
            resistance = resistances.NEGATIVE_ENERGY,
        },
    }

    for _, entry in ipairs(cases) do
        local game, player, entity = shield(ctx, entry.ego)

        harness.equal(damage.player_resistance(game, player,
            entry.resistance), 1,
            entry.ego .. " shield grants its source resistance")

        ctx:remove(entity, component.EQUIPPED)

        harness.equal(damage.player_resistance(game, player,
            entry.resistance), 0,
            "unequipped " .. entry.ego .. " shield grants nothing")
    end

    local combined, combined_player = shield(ctx, egos.RESISTANCE)

    harness.equal(player_resistance.poison(combined, combined_player), 0,
        "Resistance ego does not also grant poison resistance")

    local poisoned, poisoned_player, poisoned_entity = shield(ctx,
        egos.POISON_RESISTANCE)

    harness.equal(player_resistance.poison(poisoned, poisoned_player), 1,
        "poison-resistance shield grants one poison pip")

    ctx:remove(poisoned_entity, component.EQUIPPED)

    harness.equal(player_resistance.poison(poisoned, poisoned_player), 0,
        "unequipped poison-resistance shield grants nothing")

    local melded, melded_player = shield(ctx, egos.FIRE_RESISTANCE)

    ctx:add(melded_player, component.PLAYER_FORM, {
        form_id = forms.FUNGUS,
        remaining_aut = 100,
    })

    harness.equal(damage.player_resistance(melded, melded_player,
        resistances.FIRE), 0,
        "melded fire-resistance shield grants no resistance")

    ctx:remove(melded_player, component.PLAYER_FORM)

    harness.equal(damage.player_resistance(melded, melded_player,
        resistances.FIRE), 1,
        "unmelded fire-resistance shield grants resistance again")
end

-- The same reflection predicate serves missile, launcher, and beam block
-- paths. A physical-form meld suppresses it without discarding the item.
local function reflection_ego(ctx)
    local game, player, entity = shield(ctx, egos.REFLECTION)

    harness.truthy(reflection.active(game, player),
        "worn Reflection shield reflects a successful block")

    ctx:add(player, component.PLAYER_FORM, {
        form_id = forms.FUNGUS,
        remaining_aut = 100,
    })

    harness.falsy(reflection.active(game, player),
        "melded Reflection shield grants no reflection")

    ctx:remove(player, component.PLAYER_FORM)
    ctx:remove(entity, component.EQUIPPED)

    harness.falsy(reflection.active(game, player),
        "removed Reflection shield grants no reflection")
end

-- Exercise all generated resistance and reflection identities through the
-- live item route; Protection AC is checked by the Go game view test.
function test.run(ctx)
    resistance_egos(ctx)
    reflection_ego(ctx)
end

return test
