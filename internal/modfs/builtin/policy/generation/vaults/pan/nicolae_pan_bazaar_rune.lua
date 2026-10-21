-- Theory of operation: this source vault is a Pan bazaar whose shops all
-- use one generated lord name. The central shop sells the demonic rune
-- until pickup, then ordinary rarities. Shop stock remains DES data, while
-- generic shop generation creates the actual inventory on the shop stream.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local loot = require("constants.vault_loot")
local messages = require("constants.pan_messages")
local runes = require("constants.runes")
local stock = require("constants.pan_shop")

local handler = {}

-- Build one keyed shop feature with the owner shared by all the bazaar's
-- signs. A nil stock clause leaves the generic shop's ordinary inventory.
local function emit_shop(api, glyph, kind, owner, label, items)
    local expression = glyph .. " = " .. kind .. " shop name:" .. owner

    if label then
        expression = expression .. " " .. label
    end

    if items then
        expression = expression .. " ; " .. items
    end

    api:emit(directives.KFEAT, expression)
end

-- Source dgn.good_scrolls and dgn.loot_potions use '/' as weighted item
-- alternatives; shop stock grammar uses '|', so keep their weights intact.
local function shop_items(expression)
    return expression:gsub("/", "|")
end

-- One source name draw and one suffix draw precede every KMONS/KFEAT
-- declaration. Reusing those values makes this a single coherent bazaar.
local function configure(api)
    local owner = api:random_name():gsub(" ", "_")
    local suffix = api:random_from(stock.SUFFIXES)

    api:emit(directives.KMONS,
        "Z = pandemonium lord name:" .. owner)

    if api:has_rune(runes.DEMONIC) or api:validating() then
        emit_shop(api, "Z", "general", owner,
            "type:Rarities suffix:" .. suffix, stock.RARITIES)
    else
        emit_shop(api, "Z", "general", owner,
            "type:Demonic_Rune suffix:" .. suffix .. " count:1",
            "demonic rune of Zot")
    end

    emit_shop(api, "H", "general", owner,
        "type:Assorted suffix:Sundries", stock.SUNDRIES)
    emit_shop(api, "J", "scroll", owner,
        "type:Exquisite suffix:Manuscripts", shop_items(loot.GOOD_SCROLLS))
    emit_shop(api, "K", "distillery", owner,
        "type:Quality suffix:Elixirs", shop_items(loot.POTIONS))
    emit_shop(api, "L", "general", owner,
        "type:Fine suffix:Accessories", stock.ACCESSORIES)
    emit_shop(api, "M", "jewellery", owner)
    emit_shop(api, "N", "book", owner)
    emit_shop(api, "O", "general", owner,
        "type:Superb suffix:Hardware", stock.HARDWARE)
    emit_shop(api, "S", "general", owner,
        "type:Infernal suffix:Boutique", stock.INFERNAL)
end

-- The entry warning explains the unusual way to acquire this rune. It is
-- stored with the level so entering after a save need not rerun generation.
local function epilogue(api)
    if not api:has_rune(runes.DEMONIC) then
        api:record(effects.ENTRY_MESSAGE, {
            text = messages.BAZAAR_RUNE_WARNING,
        })
    end
end

handler.configure = configure
handler.epilogue = epilogue

return handler
