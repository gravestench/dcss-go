local categories = require("constants.catalog")

local definition = {
    id = "MUT_MOSSY_SKIN",
    status = "active",
    weight = 0,
    max_level = 1,
    uses = {},
    form_based = false,
    short_description = "mossy skin",
    have = {
        "Moss protects your skin.",
        "",
        "",
    },
    gain = {
        "Moss grows on your skin.",
        "",
        "",
    },
    lose = {
        "The moss withers away.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
