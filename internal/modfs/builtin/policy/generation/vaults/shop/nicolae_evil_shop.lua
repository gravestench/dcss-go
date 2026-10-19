-- Example: The evil-shop name is drawn first; non-Dungeon branches add an altar to the shop feature.
local branches = require("ids.branches")
local directives = require("constants.vault_directives")

local handler = {}

local names = {
    "type:Blasphemy suffix:Boutique",
    "type:Evil suffix:Emporium",
    "type:Profane suffix:Products",
    "type:Sacrilege suffix:Store",
    "type:Wicked suffix:Wares",
}

local stock = table.concat({
    "any weapon ego:draining w:15",
    "any weapon ego:pain",
    "any weapon ego:vampirism",
    "any weapon ego:chaos w:1",
    "demon blade w:5",
    "demon trident w:5",
    "demon whip w:5",
    "scroll of torment",
    "staff of death",
    "book of necromancy",
    "book of death",
    "book of unlife",
    "book of decay",
    "randbook disc:necromancy w:5",
    "necronomicon w:1",
    "grand grimoire w:1",
    "sceptre_of_torment w:1",
    "scythe_of_curses w:1",
    "majin-bo w:1",
    "black_knights_barding w:1",
    "obsidian_axe w:1",
    "damnation w:1",
    "sword_of_zonguldrok w:1",
}, " | ")

-- The evil-shop name is drawn first; non-Dungeon branches add an altar to the shop feature.
local function configure_evil_shop(api)
    local name = api:random_from(names)

    api:emit(directives.KFEAT,
        "s = general shop " .. name .. " ; " .. stock)

    if api:branch_id() ~= branches.BRANCH_DUNGEON then
        api:emit(directives.KFEAT,
            "a = altar_kikubaaqudgha / altar_yredelemnul / " ..
            "altar_makhleb / altar_beogh w:1 / altar_lugonu w:1")
    end
end

handler.configure_evil_shop = configure_evil_shop

return handler
