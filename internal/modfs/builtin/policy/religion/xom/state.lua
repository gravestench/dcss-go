-- Xom's safety boundary depends on saved interest and old penance, even
-- after a worshipper changes gods. Both selection and effects read this.
local gods = require("constants.gods")

local state = {}

-- Boredom only applies to a current Xom worshipper. A former worshipper
-- with Xom penance can still receive a nasty retribution action.
function state.feels_nasty(worship)
    if not worship then
        return false
    end

    if ((worship.penance or {})[gods.XOM] or 0) > 0 then
        return true
    end

    return worship.god_id == gods.XOM and worship.gift_timeout < 1
end

return state
