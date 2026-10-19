-- One component exercises every supported list and string-keyed map element
-- type through ECS copy, validation, and round-trip tests.
local schema = {
    id = "test.collections",
    version = 1,
    fields = {
        bools = { type = "list<bool>" },
        ints = { type = "list<int64>" },
        uints = { type = "list<uint64>" },
        floats = { type = "list<float64>" },
        strings = { type = "list<string>" },
        entities = { type = "list<entity>" },
        bool_map = { type = "map<string,bool>" },
        int_map = { type = "map<string,int64>" },
        uint_map = { type = "map<string,uint64>" },
        float_map = { type = "map<string,float64>" },
        string_map = { type = "map<string,string>" },
        entity_map = { type = "map<string,entity>" },
    },
}

register.component(schema)

return schema
