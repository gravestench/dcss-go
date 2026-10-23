-- wizlab_borgnjor keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local wizlab = require("constants.wizlab")

local map = {}

-- Choose the source's one-in-four wall opening pattern once. The
-- alternatives were inside source Lua, so both cannot be static DES
-- substitutions without opening too many grave passages.
function map.site_1(api)
    if api:one_in(4) then
        api:emit(directives.SUBST, "F = c..., E = cccc., D = c")
    else
        api:emit(directives.SUBST, "D = c., E = c.., F = c")
    end
end

-- The death callback belongs to the live lab event owner. This typed
-- marker anchors it to the authored A cells through save and restore.
function map.site_4(api)
    api:emit(directives.MARKER,
        "A = " .. wizlab.BORGNJOR_SOUL_MARKER)
end

-- Necromancy summons use the source late-undead roster, separate from
-- the keyed grave actors and the lost-soul callback marker.
function map.site_5(api)
    shared.random_monsters(api,
        "skeletal warrior / flayed ghost / phantasmal warrior / " ..
        "necromancer / vampire mage / shadow wraith / " ..
        "revenant w:2 / ancient champion w:2")
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Borgnjor's Mausoleum")
end

return map
