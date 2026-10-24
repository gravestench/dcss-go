-- Exercise production explicit-unrand generation inside the live Go game.
-- A fixed-scenario monster carries the item so normal save rules apply.
local artefacts = require("ids.artefacts")
local catalog = require("policy.catalog")
local component = require("constants.component")
local generation = require("policy.item_generation")
local purpose = require("constants.item_generation_purpose")
local quality = require("constants.vault_item_quality")

local policy = {}

-- Find the scenario's live monster, generate Dispater's staff by its
-- authoritative catalog identity, and equip the real carried entity.
function policy.run(ctx)
    local monster = ctx:query({ component.AI })[1]

    if not monster then
        error("signature gear fixture has no monster")
    end

    local definition = catalog.get("artefacts",
        artefacts.UNRAND_DISPATER)
    local rolled = generation.roll(ctx, {
        kind_id = definition.kind_id,
        unique_id = definition.id,
        depth = 1,
        quality = quality.ORDINARY,
        allow_uniques = false,
        purpose = purpose.VAULT,
        site = "signature gear save fixture",
    })
    local item = generation.create(ctx, rolled, {
        carrier = monster,
    })

    ctx:add(item, component.EQUIPPED, {
        slot = "weapon",
    })

    return {}
end

register.policy({
    id = "test.signature_gear",
    run = policy.run,
})

return policy
