-- wizlab_iskenderun keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")

local map = {}

-- The tower's random summons draw from its two source schools of
-- defenders. The named books and draconian groups remain DES content.
function map.site_1(api)
    shared.random_monsters(api,
        "purple draconian / tengu conjurer")
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Iskenderun's Mystic Tower")
end

return map
