local categories = require("constants.catalog")

local definition = {
    id = "MUT_BAD_OVERLAY",
    status = "active",
    weight = 5,
    max_level = 0,
    uses = {
        "bad",
    },
    form_based = false,
    short_description = "bad overlay",
    have = {
        "Bad overlay.",
        "",
        "",
    },
    gain = {
        "Bad overlay gained.",
        "",
        "",
    },
    lose = {
        "Bad overlay lost.",
        "",
        "",
    },
}

register.definition(categories.MUTATIONS, definition)

return definition
