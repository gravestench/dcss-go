-- Lunar affinity is exposed through a policy registered by the species overlay.
-- Example: test.lunar_affinity reads SP_MOON_HUMAN's registered affinity value.

register.policy({
    id = "test.lunar_affinity",
    -- Read the effective overlay species at call time, so the fixture catches
    -- a registry that exposed only its original embedded definition.
    run = function()
        local species = register.get("species", "SP_MOON_HUMAN")

        return { value = species.lunar_affinity }
    end,
})
