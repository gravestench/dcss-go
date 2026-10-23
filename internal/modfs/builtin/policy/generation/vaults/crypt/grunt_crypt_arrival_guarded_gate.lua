-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local effects = require("constants.vault_effects")
local triggers = require("constants.vault_triggers")
local appearance = require("policy.generation.vaults.crypt.appearance")

local handler = {}

-- Attach a saved one-shot LOS event to the source sarcophagi.
-- Source operation:
--   local trap_marker = TriggerableFunction:new {
--       func = "callback.grunt_crypt_arrival_guards_awaken",
--       repeated = false}
--   trap_marker:add_triggerer(DgnTriggerer:new {
--       type="player_los"})
--   lua_marker('J', trap_marker)
--   lua_marker('G', props_marker {trap_sarcophagus=1,
--                                 veto_destroy="veto"})
--   set_feature_name("granite_statue", "sarcophagus")
local function arm_sarcophagi(api)
    -- J watches the approaching player; G records the final transformed
    -- statue cells, which the callback changes only once.
    api:record(effects.MARKER, {
        glyph = "J",
        identity = triggers.CRYPT_GUARDS_AWAKEN,
        event = triggers.PLAYER_LOS_EVENT,
        group = triggers.CRYPT_SARCOPHAGI_GROUP,
    })
    api:record(effects.MARKER, {
        glyph = "G",
        identity = triggers.CRYPT_SARCOPHAGUS_TARGET,
        group = triggers.CRYPT_SARCOPHAGI_GROUP,
        role = "wall",
    })
    appearance.sarcophagus(api)
end

handler.arm_sarcophagi = arm_sarcophagi

return handler
