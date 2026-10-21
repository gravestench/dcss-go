-- Theory of operation: the murder den rolls one unusually large hydra's
-- head count before source substitutions, then declares the keyed monster
-- after its plant declaration. This preserves both the source RNG position
-- and the order in which declarations become saved placement records.
local directives = require("constants.vault_directives")

local handler = {}

-- Two three-sided dice plus seven gives the source 9–13 head range.
local function roll_hydra_heads(api)
    local heads = api:roll_dice(2, 3) + 7

    api:remember("hydra_heads", heads)
end

-- Use the earlier draw after the static plant declaration, as source DES did.
local function declare_hydra(api)
    local heads = api:recall("hydra_heads")

    api:emit(directives.KMONS,
        "h = " .. heads .. "-headed hydra patrolling")
end

handler.roll_hydra_heads = roll_hydra_heads
handler.declare_hydra = declare_hydra

return handler
