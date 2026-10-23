-- wizlab_maxwell keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")

local map = {}

-- Maxwell's animated workshop uses this late-depth roster for source
-- random-monster requests, while its keyed forge guards stay in DES.
function map.site_1(api)
    shared.random_monsters(api,
        "gargoyle / earth elemental / molten gargoyle / " ..
        "peacekeeper / war gargoyle / crystal guardian w:2 / " ..
        "ironbound thunderhulk / electric golem w:1")
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Maxwell's Workshop")
end

return map
