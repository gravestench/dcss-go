-- The curing effect override returns a distinctive message when dispatched.
-- Example: applying POT_CURING returns the overlaid curing message.

local items = require("ids.items")
local potions = require("policy.potions")

local effect = {}

-- Leave eligibility unrestricted so this overlay tests effect replacement
-- alone rather than potion-use gating.
function effect.can_quaff()
    return nil
end

-- Return a unique message from the replacement handler, making normal
-- potion dispatch to this layered file observable.
function effect.apply()
    return "The overlaid curing effect ran."
end

potions.register(items.POT_CURING, effect)

return effect
