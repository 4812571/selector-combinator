local data_util = require("__flib__.data-util")

local recipe = data_util.copy_prototype(data.raw["recipe"]["arithmetic-combinator"], "selector-combinator")
data:extend{recipe}
