-- Force the bundled Lady map as the first floor so gameplay and save tests
-- exercise its real DES records without waiting for a rare Swamp draw.
local vaults = require("ids.vaults")

local selection = {}

-- Return the source definition; the fixture changes selection only.
function selection.choose_catalog()
    return {
        id = vaults.grunt_lady_of_the_lake,
    }
end

-- Extra maps could consume the Lady's approach cells before the test move.
function selection.choose_tag()
    return nil
end

return selection
