-- An active mutation without an effect module should fail behavior coverage.

local categories = require("constants.catalog")

local definition = {
    id = "MUT_MISSING_EFFECT",
    status = "active",
    weight = 1,
    max_level = 1,
    uses = {},
    form_based = false,
    short_description = "missing effect",
    have = {
        "You have an unimplemented mutation.",
        "",
        "",
    },
    gain = {
        "You gain an unimplemented mutation.",
        "",
        "",
    },
    lose = {
        "You lose an unimplemented mutation.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
