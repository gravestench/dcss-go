-- Theory of operation: Wucad's monks and Borgnjor's lost souls are
-- ordinary short-lived summons, so their expiry and actor placement use
-- the established summon owner. This wrapper supplies only their lab
-- source identity and event provenance, not a second lifetime system.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local component = require("constants.component")
local streams = require("constants.rng_streams")
local common = require("policy.magic.effects.summons.common")

local summons = {}

-- Source callbacks choose an exact nearby cell and a fixed lifetime.
-- An occupied or unsuitable cell fails without a partial actor.
function summons.place(ctx, state, source_index, kind_id, x, y,
    duration_aut, event_kind)
    local actor = common.spawn(ctx, ctx:player(),
        state.vault_id, kind_id, 1, nil, {
            anchor = ctx:get(ctx:player(), component.POSITION),
            exact = {
                x = x,
                y = y,
            },
            stream = streams.WIZLAB_EVENTS,
            source_category = categories.VAULTS,
            expires_aut = ctx:aut() + duration_aut,
            attitude = attitudes.HOSTILE,
            silent_failure = true,
            silent_hostility = true,
        })

    if actor then
        ctx:add(actor, component.WORLD_WIZLAB_EVENT_ACTOR, {
            level_id = state.level_id,
            vault_id = state.vault_id,
            source_index = source_index,
            kind = event_kind,
        })
    end

    return actor
end

return summons
