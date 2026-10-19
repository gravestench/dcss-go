-- DES directive names identify parsed source instructions kept in vault records.

local directives = {
    TAGS = "TAGS",
    ORIENT = "ORIENT",
    WEIGHT = "WEIGHT",
    DEPTH = "DEPTH",
    CHANCE = "CHANCE",
    CLEAR = "CLEAR",
    SUBST = "SUBST",
    NSUBST = "NSUBST",
    SHUFFLE = "SHUFFLE",
    KFEAT = "KFEAT",
    KMONS = "KMONS",
    KITEM = "KITEM",
    KMASK = "KMASK",
    KPROP = "KPROP",
    MONS = "MONS",
    ITEM = "ITEM",
    COLOUR = "COLOUR",
    FTILE = "FTILE",
    RTILE = "RTILE",
    TILE = "TILE",
    MARKER = "MARKER",
    SUBVAULT = "SUBVAULT",
    HOOK_RUN = "HOOK_RUN",
    HOOK_VETO = "HOOK_VETO",
    HOOK_POST_PLACE = "HOOK_POST_PLACE",
}

return directives
