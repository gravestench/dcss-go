-- Kikubaaqudgha's pain brand shares the permanent capstone flag with
-- Forbidden Knowledge. Its extra Torment is cast by the player and receives
-- the source's guaranteed partial Kiku protection.
local abilities = require("ids.abilities")
local blessing = require("policy.abilities.weapon_blessing")
local brands = require("constants.weapon_brands")
local channels = require("constants.message_channels")
local gods = require("constants.gods")
local identification = require("policy.items.identification")
local torment = require("policy.combat.torment_area")
local torment_sources = require("constants.torment_sources")

local kiku = {}

-- Confirmation remains free, including a cancelled prompt.
function kiku.confirmation(ctx, player, item)
    return "Do you wish to have " ..
        identification.name(ctx, player, item) ..
        " bloodied with pain?"
end

-- Source gift_timeout suppresses Kiku's shield during pain branding.
-- Blood placement follows this deliberately unprotected Torment.
function kiku.after(ctx, player)
    torment.apply(ctx, player, channels.RELIGION, nil,
        torment_sources.KIKU_BLESSING)
    require("policy.combat.divine_blood").spread(ctx, player, 2)
end

return blessing.define({
    ability_id = abilities.KIKU_BLESS_WEAPON,
    god_id = gods.KIKUBAAQUDGHA,
    brand = brands.PAIN,
    name = "Brand Weapon With Pain",
    allow_ranged = true,
    no_weapon_message = "You have no weapon to blood with pain.",
    invalid_weapon_message = "Kikubaaqudgha cannot brand that weapon.",
    success_message = "Your weapon shines brightly! Kikubaaqudgha booms: Use this gift wisely!",
    confirmation = kiku.confirmation,
    after = kiku.after,
})
