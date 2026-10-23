-- Theory of operation: this map keeps source geometry in its DES file.
-- The methods below run at authored source positions, so emitted
-- directives see earlier map substitutions and retain seeded order.
local effects = require("constants.vault_effects")
local triggers = require("constants.vault_triggers")
local loot = require("policy.generation.vaults.crypt_end.loot")

local handler = {}

-- Attach a saved one-shot event to linked glass Crypt grates.
-- Source operation:
-- lua_marker("|",
--            Triggerable.synchronized_markers(
--              function_at_spot("crypt_drop_grates", { trig = false },
--                               true, { only_at_slave = true,
--                                       listen_to_slaves = true })))
local function arm_grates(api)
    -- Each prize glyph can activate the same grate group. The m targets
    -- are recorded before the later source NSUBST changes prize glyphs.
    api:record(effects.MARKER, {
        glyph = "|",
        identity = triggers.CRYPT_GRATES_DROP,
        event = triggers.ENTER_EVENT,
        group = triggers.CRYPT_GRATES_GROUP,
    })
    api:record(effects.MARKER, {
        glyph = "m",
        identity = triggers.CRYPT_GRATE_TARGET,
        group = triggers.CRYPT_GRATES_GROUP,
        role = "wall",
    })
end

handler.arm_grates = arm_grates

-- Add Crypt ending incentives at the authored source position.
-- Source operation:
-- : crypt_loot_plus(_G)
local function bonus_loot(api)
    loot.apply(api)
end

handler.bonus_loot = bonus_loot

return handler
