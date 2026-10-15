-- One saved entity owns the three mutation classes for one player/ID pair.
local schema = {
    id = "character.mutation",
    version = 1,
    fields = {
        owner = {
            type = "entity",
        },

        mutation_id = {
            type = "string",
            default = "",
        },

        innate = {
            type = "int64",
            default = 0,
        },

        acquired = {
            type = "int64",
            default = 0,
        },

        temporary = {
            type = "int64",
            default = 0,
        },

    },
}

register.component(schema)

return schema
