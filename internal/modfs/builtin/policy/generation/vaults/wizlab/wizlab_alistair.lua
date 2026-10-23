-- wizlab_alistair keeps the original Wizard Lab MAP in its DES file.
-- Each site method below owns one source Lua declaration group.
local shared = require("policy.generation.vaults.wizlab.shared")
local directives = require("constants.vault_directives")
local loot = require("constants.vault_loot")

local map = {}

-- Source dgn pools are alternatives for one reward draw. Keep this
-- extra consumable slot ahead of the fixed acquirement scroll.
function map.site_1(api)
    api:emit(directives.ITEM,
        loot.SCROLLS .. " / " .. loot.POTIONS)
end

-- Partygoer summons share the source mixed caster roster after the
-- authored degeneration fog and ordinary keyed guests are recorded.
function map.site_2(api)
    shared.random_monsters(api,
        "wizard w:40 / necromancer / boggart / " ..
        "glowing orange brain / worldbinder / sphinx / " ..
        "demonspawn corrupter w:1")
    shared.setup(api)
end

-- The source epilogue names this room on first entry.
function map.epilogue(api)
    shared.epilogue(api, "Alistair's Party Mansion")
end

return map
