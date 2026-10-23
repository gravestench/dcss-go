-- The source no_tele_into property blocks random landing until the
-- Zonguldrok door opens. The policy reads real kind and ID constants;
-- the fixture supplies only the two possible cell-record sets.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local landings = require("policy.world.teleport_landings")
local properties = require("constants.vault_properties")

local test = {}

-- One saved encounter state may release its own level's property mask,
-- while the same source property on another level stays effective.
function test.run()
    local state = {
        level_id = 3301,
        door_appeared = false,
    }
    local owner = {}
    local context = {}

    function context:query(ids)
        harness.equal(ids[1], component.WORLD_WIZLAB_ZONGULDROK,
            "landing queries the focused encounter owner")

        return { owner }
    end

    function context:get(entity, id)
        harness.equal(entity, owner, "landing reads the encounter owner")
        harness.equal(id, component.WORLD_WIZLAB_ZONGULDROK,
            "landing reads its saved state")

        return state
    end

    function context:records_at()
        return {
            {
                kind = effects.PROPERTY,
                identity = properties.NO_TELE_INTO,
                overridden = false,
            },
        }
    end

    harness.falsy(landings.allowed(context, 3301, 12, 8),
        "closed source grave zone rejects teleport")

    state.door_appeared = true

    harness.truthy(landings.allowed(context, 3301, 12, 8),
        "appearing D door releases the source mask")
    harness.falsy(landings.allowed(context, 3302, 12, 8),
        "another level's mask is not released")
end

return test
