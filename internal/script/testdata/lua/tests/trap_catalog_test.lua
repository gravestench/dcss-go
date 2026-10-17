local harness = require("tests.harness")

local test = {}

local active = {
    TRAP_TELEPORT = true,
    TRAP_TELEPORT_PERMANENT = true,
    TRAP_ALARM = true,
    TRAP_NET = true,
    TRAP_ZOT = true,
    TRAP_SHAFT = true,
    TRAP_GOLUBRIA = true,
    TRAP_PLATE = true,
    TRAP_WEB = true,
    TRAP_DISPERSAL = true,
}

local removed = {
    "TRAP_DART",
    "TRAP_ARROW",
    "TRAP_SPEAR",
    "TRAP_BLADE",
    "TRAP_BOLT",
    "TRAP_NEEDLE",
    "TRAP_GAS",
    "TRAP_SHADOW",
    "TRAP_SHADOW_DORMANT",
}

local function expect_error(trap_catalog, needle, definition)
    local okay, message = pcall(trap_catalog.definition, definition)

    harness.falsy(okay, "invalid trap must be rejected")
    harness.truthy(tostring(message):find(needle, 1, true),
        "trap error must name " .. needle)
end

function test.run()
    local loaded, trap_catalog = pcall(require, "policy.traps.catalog")

    harness.truthy(loaded, "trap catalog policy loads")

    local ids = register.ids("traps")

    harness.equal(#ids, 10, "pinned source active trap count")

    for _, id in ipairs(ids) do
        local definition = register.get("traps", id)

        harness.truthy(active[id], "only active trap IDs register")
        harness.equal(definition.id, id, "trap definition ID")
        harness.truthy(type(definition.name) == "string" and
            definition.name ~= "", "trap has a name")
        harness.equal(definition.glyph, "^", "trap source glyph")
        harness.truthy(type(definition.effect) == "string" and
            definition.effect ~= "", "trap has an effect module")
    end

    for _, id in ipairs(removed) do
        local okay = pcall(register.get, "traps", id)

        harness.falsy(okay, "removed trap remains unavailable")
    end

    expect_error(trap_catalog, "name", {
        id = "TRAP_TEST",
        glyph = "^",
        regular = false,
        effect = "policy.traps.effects.test",
    })

    expect_error(trap_catalog, "effect", {
        id = "TRAP_TEST",
        name = "test trap",
        glyph = "^",
        regular = false,
        effect = "policy.traps.effects.missing",
    })

    expect_error(trap_catalog, "removed trap", {
        id = "TRAP_DART",
        name = "legacy dart trap",
        glyph = "^",
        regular = false,
        effect = "policy.traps.effects.teleport",
    })
end

return test
