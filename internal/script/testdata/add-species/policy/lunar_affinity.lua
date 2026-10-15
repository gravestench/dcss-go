register.policy({
    id = "test.lunar_affinity",
    run = function()
        local species = register.get("species", "SP_MOON_HUMAN")

        return { value = species.lunar_affinity }
    end,
})
