-- A committed source map supplies all fog fields; this fixture fixes only
-- selection so the game test need not hunt for a seed.
local vaults = require("ids.vaults")

local selection = {}

-- Choose the arrival whose marker has a variable countdown and entry burst.
function selection.choose_catalog()
    return {
        id = vaults.dpeg_arrival_fog,
    }
end

-- Keep supplemental maps out of this single-machine lifecycle test.
function selection.choose_tag()
    return nil
end

return selection
