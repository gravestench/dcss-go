local mutations = require("ids.mutations")
local effects = require("policy.combat.player_kill_effects")
local powered = require("policy.character.powered_by_death")

-- The kill-effect registry invokes powered-by-death after a qualifying player kill.
-- Example: a qualifying kill reaches powered.on_kill through the shared player-kill effect registry.
effects.add(mutations.MUT_POWERED_BY_DEATH, powered.on_kill)

return powered
