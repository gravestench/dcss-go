local component = require("constants.component")

register.component({
    id = component.WALLET,
    version = 2,
    -- Gold balance and purchase history remain on the character after shops or levels unload.
    fields = {
        gold = { type = "int64", default = 0 },
        purchases = { type = "int64", default = 0 },

        -- DCSS prices Gozag's entry from gold generated on explored floors,
        -- regardless of what the player has actually collected or spent.
        -- Gozag's entry fee remains spent after renunciation and save/restore.
        gozag_gold_used = {
            type = "int64",
            default = 0,
        },

        generated_gold = {
            type = "int64",
            default = 0,
        },

        -- Donations remain paid after leaving Zin. Nine already-taxed gold
        -- pieces are exempt from the entry tithe on a later conversion.
        donations = {
            type = "int64",
            default = 0,
        },

        -- Carry the unpaid fraction across small piles; ten single pieces
        -- owe the same whole tithe as one ten-piece stack.
        tithe_base = {
            type = "int64",
            default = 0,
        },
    },
})
