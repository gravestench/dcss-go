-- The Shining One grants holy wrath once per character. The shared action
-- owns the item transaction; this god owns the holy word and blood cleansing
-- that follow a committed blessing in the original game.
local abilities = require("ids.abilities")
local blessing = require("policy.abilities.weapon_blessing")
local brands = require("constants.weapon_brands")
local gods = require("constants.gods")
local holy_word = require("policy.combat.holy_word")
local identification = require("policy.items.identification")

local shining_one = {}

-- The prompt reads the live item so a renamed or identified weapon is
-- described accurately at the free confirmation step.
function shining_one.confirmation(ctx, player, item)
    return "Do you wish to have " ..
        identification.name(ctx, player, item) ..
        " blessed with holy wrath?"
end

-- Holy word affects live actors and terrain only after the item is changed.
function shining_one.after(ctx, player)
    holy_word.apply(ctx, player, 100)
end

return blessing.define({
    ability_id = abilities.TSO_BLESS_WEAPON,
    god_id = gods.SHINING_ONE,
    brand = brands.HOLY_WRATH,
    name = "Brand Weapon With Holy Wrath",
    allow_ranged = true,
    no_weapon_message = "You have no weapon to bless.",
    invalid_weapon_message = "The Shining One cannot bless that weapon.",
    success_message = "Your weapon shines brightly! The Shining One booms: Use this gift wisely!",
    confirmation = shining_one.confirmation,
    after = shining_one.after,
})
