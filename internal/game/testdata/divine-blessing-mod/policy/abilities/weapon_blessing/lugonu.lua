-- A same-path mod replaces only Lugonu's definition. The bundled shared
-- transaction still owns saved choices, item conversion, and commitment.
local abilities = require("ids.abilities")
local blessing = require("policy.abilities.weapon_blessing")
local brands = require("constants.weapon_brands")
local gods = require("constants.gods")
local identification = require("policy.items.identification")

local lugonu = {}

-- The fixture's changed words make the effective Lua definition observable
-- through the ordinary game command and its ruleset hash.
function lugonu.confirmation(ctx, player, item)
    return "Bless " .. identification.name(ctx, player, item) .. "?"
end

return blessing.define({
    ability_id = abilities.LUGONU_BLESS_WEAPON,
    god_id = gods.LUGONU,
    brand = brands.DISTORTION,
    name = "Bless Weapon",
    allow_ranged = false,
    no_weapon_message = "No weapon is available.",
    invalid_weapon_message = "That weapon is unavailable.",
    success_message = "Modded distortion blessing complete.",
    confirmation = lugonu.confirmation,
})
