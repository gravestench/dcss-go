local mutations = require("ids.mutations")
local effects = require("policy.combat.player_kill_effects")
local powered = require("policy.character.powered_by_death")

effects.add(mutations.MUT_POWERED_BY_DEATH, powered.on_kill)

return powered
