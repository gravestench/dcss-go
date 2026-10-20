-- BRANCH_ARENA ambient monster rows from the version-34 DCSS source table.
-- The source may repeat a monster at another depth or curve; keep
-- those rows separate so their weights accumulate as designed.
-- This committed data is loaded at runtime without the C++ checkout.
local branches = require("ids.branches")
local categories = require("constants.catalog")

local definition = {
    id = branches.BRANCH_ARENA,
    branch_id = branches.BRANCH_ARENA,
    rows = {
        -- The source has no ordinary ambient monster rows here.
        -- Authored maps or a separate portal policy may still place actors.
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
