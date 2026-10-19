-- A revived player loses these temporary effects while lasting character state survives.

-- Source: nearby-danger.cc:revive clears temporary afflictions. Persistent
-- character records, inventory, and skill training are deliberately absent.
local component = require("constants.component")
local zap = require("policy.magic.effects.zaps.ids").component

local statuses = {
    component.AGILITY,
    component.AREA_STATUS,
    component.CHANNEL,
    component.CURL,
    component.DAMAGE_SAFETY,
    component.FROZEN_RAMPARTS,
    component.ICY_DEFENSE,
    component.LIQUEFACTION,
    component.PASSWALL_DELAY,
    component.PERMANENT_HP_LOSS,
    component.PLAYER_FORM,
    component.PLAYER_PARALYSIS,
    component.PLAYER_SLOW,
    component.PLAYER_WEAKNESS,
    component.PLAYER_STATUS,
    component.POWERED_BY_DEATH,
    component.SANGUINE_ARMOUR,
    component.STAT_LOSS,
    component.TELEPORT,
    component.ZAP_FLIGHT,
    zap.CONTAMINATION,
    zap.PLAYER_CONFUSION,
    "status.drain",
}

return statuses
