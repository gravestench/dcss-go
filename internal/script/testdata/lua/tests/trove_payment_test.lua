-- Trove payment tests use the production item, knowledge, rune, and worship
-- schemas. A small context stores actual component-shaped records while
-- preserving the production policy as the only matching implementation.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local ids = require("ids.items")
local payment = require("policy.world.trove.payment")
local trove = require("constants.trove")
local brands = require("constants.weapon_brands")

local test = {}

-- Keep carried item order explicit, because an exact enchantment beats a
-- higher one even when the higher item appears first in inventory.
local function context()
    local states = {
        [1] = {
            [component.ITEM_KNOWLEDGE] = {
                known_types = {},
                seen_types = {},
            },
            [component.PLAYER_RUNES] = {
                collected = {},
            },
            [component.RELIGION_WORSHIP] = {
                god_id = gods.ZIN,
                piety = 60,
            },
        },
    }
    local destroyed = {}
    local ctx = {}

    -- Keep inventory enumeration in the same order the source matcher sees.
    function ctx:query()
        return {2, 3, 4}
    end

    -- Resolve only the actual production component keys requested by policy.
    function ctx:get(entity, id)
        local row = states[entity]

        return row and row[id]
    end

    -- Retain payment writes so tests can inspect the remaining stack/piety.
    function ctx:set(entity, id, value)
        states[entity][id] = value
    end

    -- Record full-stack consumption separately from partial quantity writes.
    function ctx:destroy(entity)
        destroyed[entity] = true
    end

    -- Confirmation targets use the same stable entity ID representation.
    function ctx:id(entity)
        return tostring(entity)
    end

    -- The rune and inventory helpers ask for component presence.
    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    -- The first candidate is unidentified; the second has a higher plus;
    -- the third has the exact plus and enough quantity for a partial debit.
    for entity = 2, 4 do
        states[entity] = {
            [component.ITEM] = {
                kind_id = ids.WPN_DEMON_WHIP,
                quantity = 3,
                plus = entity == 4 and 5 or 6,
                ego = "",
            },
            [component.CARRIED_BY] = { holder = 1 },
            [component.ITEM_IDENTIFICATION] = {
                known_type = entity ~= 2,
                known_pluses = entity ~= 2,
                known_properties = entity ~= 2,
            },
        }
    end

    return ctx, states, destroyed
end

-- Unknown items are not surrendered. A known exact enchantment is chosen
-- before a higher qualifying one and a partial stack retains its entity.
local function check_item_payment()
    local ctx, states, destroyed = context()
    local gate = {
        price_kind = trove.PRICE_ITEM,
        item_id = ids.WPN_DEMON_WHIP,
        quantity = 2,
        minimum_plus = 5,
        ego_id = "",
        artefact_name = "",
    }
    local match, reason = payment.match(ctx, 1, gate)

    harness.equal(reason, nil, "identified item can pay")
    harness.equal(match.entity, 4, "exact plus beats higher plus")

    local receipt = payment.commit(ctx, 1, gate, match)

    harness.equal(states[4][component.ITEM].quantity, 1,
        "partial stack remains")
    harness.falsy(destroyed[4], "partial debit keeps entity")
    harness.equal(receipt.item_id, ids.WPN_DEMON_WHIP,
        "receipt names actual item")

    states[4][component.EQUIPPED] = { slot = "weapon" }
    states[3][component.EQUIPPED] = { slot = "weapon" }
    harness.equal(payment.match(ctx, 1, gate), nil,
        "equipped item cannot pay")

    harness.truthy(payment.price_name(gate):find("+5", 1, true),
        "saved enchantment appears in the entrance prompt")

    gate.ego_id = brands.FLAMING
    harness.truthy(payment.price_name(gate):find("flaming", 1, true),
        "source brand requirement appears in the prompt")

    gate.artefact_name = "the Sword of Testing"
    harness.equal(payment.price_name(gate), "the Sword of Testing",
        "named artefact requirement replaces generic subtype")
end

-- Source miscellaneous tolls, including the horn, match the kind and
-- quantity without requiring type/properties/pluses identification.
local function check_horn_payment()
    local ctx, states = context()

    states[2][component.ITEM].kind_id = ids.MISC_HORN_OF_GERYON
    states[2][component.ITEM].quantity = 1
    states[2][component.ITEM].plus = 0

    local gate = {
        price_kind = trove.PRICE_ITEM,
        item_id = ids.MISC_HORN_OF_GERYON,
        quantity = 1,
        minimum_plus = 0,
        ego_id = "",
        artefact_name = "",
    }
    local accepted = payment.match(ctx, 1, gate)

    harness.equal(accepted.entity, 2,
        "unidentified source horn still qualifies")
    harness.equal(payment.price_name(gate), "the horn of Geryon",
        "source horn name has its definite article")
end

-- Named runes are retained; the no-piety route reads the current god and
-- lowers its saved piety only after successful travel commits.
local function check_rune_and_piety()
    local ctx, states, destroyed = context()
    local rune = {
        price_kind = trove.PRICE_RUNE,
        item_id = ids.RUNE_ABYSSAL,
        quantity = 1,
        source_rune_index = trove.RUNE_ABYSSAL_SOURCE_INDEX,
    }

    states[1][component.PLAYER_RUNES].collected[ids.RUNE_ABYSSAL] = true
    local proof = payment.match(ctx, 1, rune)

    harness.equal(proof.item_id, ids.RUNE_ABYSSAL,
        "named rune proof")
    payment.commit(ctx, 1, rune, proof)
    harness.falsy(destroyed[ids.RUNE_ABYSSAL],
        "rune is never consumed")

    local piety = { price_kind = trove.PRICE_NO_PIETY }
    local accepted = payment.match(ctx, 1, piety)

    payment.commit(ctx, 1, piety, accepted)
    harness.equal(states[1][component.RELIGION_WORSHIP].piety,
        15, "source no-piety threshold")

    states[1][component.RELIGION_WORSHIP].god_id = gods.ASHENZARI
    harness.equal(payment.match(ctx, 1, piety), nil,
        "Ashenzari refuses after conversion")
end

-- Item, proof rune, and worship paths use the same gate price vocabulary.
function test.run()
    check_item_payment()
    check_rune_and_piety()
    check_horn_payment()
end

return test
