-- Lugonu's one-time Abyssal capstone brands a carried melee weapon with
-- distortion. This definition owns its speech; the shared source action
-- owns selection, exact item identity, enchantment, and saved history.
local abilities = require("ids.abilities")
local blessing = require("policy.abilities.weapon_blessing")
local brands = require("constants.weapon_brands")
local gods = require("constants.gods")
local identification = require("policy.items.identification")

local lugonu = {}

-- The prompt names the live selected item, never a remembered menu label.
function lugonu.confirmation(ctx, player, item)
    return "Do you wish to have " ..
        identification.name(ctx, player, item) ..
        " corrupted with distortion?"
end

return blessing.define({
    ability_id = abilities.LUGONU_BLESS_WEAPON,
    god_id = gods.LUGONU,
    brand = brands.DISTORTION,
    name = "Bless Weapon",
    allow_ranged = false,
    no_weapon_message = "You have no weapon Lugonu can corrupt.",
    invalid_weapon_message = "Lugonu cannot corrupt that weapon.",
    success_message = "Your weapon shines brightly! Lugonu booms: Use this gift wisely!",
    confirmation = lugonu.confirmation,
})
