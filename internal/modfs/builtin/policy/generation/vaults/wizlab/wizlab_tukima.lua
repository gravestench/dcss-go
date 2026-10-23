-- wizlab_tukima keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")

local map = {}

-- The source random roster serves effects that request a nearby monster.
-- The authored keyed MONS slots remain separate from that roster.
function map.site_1(api)
    shared.random_monsters(api, "dancing weapon / rakshasa")
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Tukima's Studio")
end

return map
