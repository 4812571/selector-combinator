local dataUtil = require('__flib__.data-util')

local selector = dataUtil.copy_prototype(data.raw["item"]["arithmetic-combinator"], "selector-combinator")
selector.icon = "__selector-combinator__/graphics/selector-combinator-icon.png"

data:extend {
    selector,
}