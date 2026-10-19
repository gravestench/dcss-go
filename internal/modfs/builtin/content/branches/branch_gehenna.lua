-- branch gehenna (BRANCH_GEHENNA) has 7 levels and connects from
-- BRANCH_VESTIBULE.
-- Entry and depth are catalog facts; generated levels and stair links are saved separately.

local categories = require("constants.catalog")

local definition = {
    id = "BRANCH_GEHENNA",
    numeric_id = 17,
    parent_id = "BRANCH_VESTIBULE",
    min_depth = 1,
    max_depth = 1,
    depth = 7,
    absolute_depth = 28,
    flags = {
        "no_items",
        "dangerous_end",
    },
    entry_feature = "DNGN_ENTER_GEHENNA",
    exit_feature = "DNGN_EXIT_GEHENNA",
    escape_feature = "DNGN_EXIT_GEHENNA",
    short_name = "Gehenna",
    long_name = "Gehenna",
    abbreviation = "Geh",
    entry_message = "Your scrolls appear blurry in the acrid smoke.",
    floor_color = "BROWN",
    rock_color = "RED",
    travel_shortcut = "G",
    runes = {
        "RUNE_GEHENNA",
    },
    ambient_noise = "normal",
    mon_die_size_expr = "HELL_MON_DIE_SIZE",
}

register.definition(categories.BRANCHES, definition)

return definition
