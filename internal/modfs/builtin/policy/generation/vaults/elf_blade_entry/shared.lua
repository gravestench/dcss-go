-- Source blade-entry helpers all have the same patrol and visual style.
-- Their individual DES maps supply the actual geometry and other actors.
local directives = require("constants.vault_directives")

local shared = {}

-- The source helper adds its selector tag before placement; that tag is
-- static in each split DES file. Emit only the ordered runtime directives.
local function elven_blade_entry(api)
    api:emit(directives.MONS,
        "patrolling dancing weapon ; dagger good_item | " ..
        "mundane falchion w:6")
    api:emit(directives.FTILE, "- = floor_vault")
    api:emit(directives.COLOUR, "- = lightgrey")
end

shared.elven_blade_entry = elven_blade_entry

return shared
