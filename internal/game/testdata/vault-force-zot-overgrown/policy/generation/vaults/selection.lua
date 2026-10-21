-- Put the bundled source overgrown map on D:1 for a focused live save test.
-- Only selection changes; the DES hook, markers, ECS schema, and system are
-- the production files.
local vaults = require("ids.vaults")

local selection = {}

-- Return the real source definition directly instead of waiting for a rare
-- ordinary Zot draw in a many-floor integration test.
function selection.choose_catalog()
    return {
        id = vaults.grunt_zot_stairs_overgrown,
    }
end

-- Keep optional child maps from hiding the source LOS marker.
function selection.choose_tag()
    return nil
end

return selection
