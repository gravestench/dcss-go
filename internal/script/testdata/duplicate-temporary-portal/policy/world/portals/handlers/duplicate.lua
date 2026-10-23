-- A deliberately invalid sparse mod claims Bazaar's entrance again.
local terrain = require("constants.terrain")

local handler = {
    id = "duplicate",
    features = {
        terrain.DNGN_ENTER_BAZAAR,
    },
}

-- The catalog must fail before it can route any command here.
function handler.prepare()
    return nil
end

-- This fixture has no source marker of its own.
function handler.is_marker()
    return false
end

-- This cannot run because the catalog rejects duplicate ownership.
function handler.materialize()
    error("duplicate handler unexpectedly materialized")
end

return handler
