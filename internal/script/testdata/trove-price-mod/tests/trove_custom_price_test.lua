-- Use the production toll and payment owners with one sparse price file.
-- No test copy of the source Trove schema or payment implementation exists.
local component = require("constants.component")
local harness = require("tests.harness")
local payment = require("policy.world.trove.payment")
local price_policies = require("policy.world.trove.prices.catalog")
local toll = require("policy.world.trove.toll")

local test = {}

-- The test context records the same wallet component production debits.
local function context()
    local state = {
        gold = 300,
        purchases = 0,
    }
    local ctx = {}

    -- The wallet owner reads this player component during match and commit.
    function ctx:get(_, id)
        harness.equal(id, component.WALLET, "wallet lookup")
        return state
    end

    -- The wallet owner writes its normal debit back to the same component.
    function ctx:set(_, id, updated)
        harness.equal(id, component.WALLET, "wallet update")
        state = updated
    end

    -- Offer binds confirmation to the live gate entity ID.
    function ctx:id()
        return 7
    end

    -- Show the final wallet without reaching into production Lua state.
    function ctx:balance()
        return state.gold
    end

    return ctx
end

-- A new kind validates, displays, matches, debits, and records its receipt.
function test.run()
    local gate = {
        price_kind = "gold",
        item_id = "",
        quantity = 120,
        minimum_plus = 0,
        ego_id = "",
        artefact_name = "",
        source_rune_index = 0,
    }
    local price = {
        kind = gate.price_kind,
        item_id = gate.item_id,
        quantity = gate.quantity,
        minimum_plus = gate.minimum_plus,
        ego_id = gate.ego_id,
        artefact_name = gate.artefact_name,
        source_rune_index = gate.source_rune_index,
    }
    local ctx = context()

    harness.truthy(toll.valid(price), "mod price accepted")
    harness.falsy(toll.valid({ kind = "missing" }),
        "unregistered price rejected")
    harness.truthy(toll.encode(price) ~= "", "mod price has witness")
    harness.equal(payment.price_name(gate), "120 gold", "mod price display")
    harness.truthy(payment.describe(gate):find("120 gold", 1, true),
        "inspection uses mod price")
    harness.truthy(payment.offer(ctx, 7, gate).prompt:find("120 gold", 1, true),
        "confirmation uses mod price")

    local accepted = payment.match(ctx, 1, gate)
    local receipt = payment.commit(ctx, 1, gate, accepted)

    harness.equal(ctx:balance(), 180, "mod price debited")
    harness.equal(receipt.kind, "gold", "mod receipt kind")
    harness.equal(receipt.quantity, 120, "mod receipt amount")

    gate.receipt_item_id = receipt.item_id
    gate.receipt_quantity = receipt.quantity
    harness.truthy(price_policies.get("gold").valid_receipt(gate),
        "mod receipt validates saved amount")

    gate.receipt_quantity = 121
    harness.falsy(price_policies.get("gold").valid_receipt(gate),
        "changed receipt rejected")
end

return test
