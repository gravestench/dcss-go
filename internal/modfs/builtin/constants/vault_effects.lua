-- Vault effect kinds preserve deferred placement instructions across save and restore.

local effects = {
    DELAYED_DECAY = "delayed_decay",
    FEATURE_NAME = "feature_name",
    BORDER_FILL = "border_fill",
    OCTA_ROOM = "octa_room",
    SMEAR_MAP = "smear_map",
    DES_DIRECTIVE = "des_directive",
    SOURCE_FEATURE = "source_feature",
    FEATURE = "feature",
    MONSTER = "monster",
    ITEM = "item",
    MARKER = "marker",
    COLOUR = "colour",
    TILE = "tile",
    MASK = "mask",
    PROPERTY = "property",
    GENERATION_RULE = "generation_rule",
    VETO = "veto",
}

return effects
