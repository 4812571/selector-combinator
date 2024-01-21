local dataUtil = require('__flib__.data-util')

local COMBINATOR_SPRITE = "__selector-combinator__/graphics/selector-combinator.png"
local COMBINATOR_HR_SPRITE = "__selector-combinator__/graphics/hr-selector-combinator.png"

local COMBINATOR_SHADOW = "__base__/graphics/entity/combinator/arithmetic-combinator-shadow.png"
local COMBINATOR_HR_SHADOW = "__base__/graphics/entity/combinator/hr-arithmetic-combinator-shadow.png"

local selector_entity = dataUtil.copy_prototype(data.raw["arithmetic-combinator"]["arithmetic-combinator"], "selector-combinator")
selector_entity.icon = "__selector-combinator__/graphics/selector-combinator-icon.png"

local function combinator_sprite(x, hr_x)
    return  {
        filename = COMBINATOR_SPRITE,
        priority="high",

        x = x,
        y = 0,

        width = 74,
        height = 64,

        frame_count = 1,
        shift = { 0.03125, 0.25 },
        scale = 1,

        hr_version={
            filename = COMBINATOR_HR_SPRITE,
            priority = "high",

            x = hr_x,
            y = 0,

            width = 144,
            height = 124,

            frame_count = 1,
            shift = { 0.015625, 0.234375 },
            scale = 0.5,
        },
    }
end

local function combinator_shadow(x, hr_x)
    return {
        filename = COMBINATOR_SHADOW,
        priority = "high",

        x = x,
        y = 0,

        width = 76,
        height = 78,

        frame_count = 1,
        shift = { 0.4375, 0.75 },
        draw_as_shadow = true,
        scale = 1,

        hr_version = {
            filename = COMBINATOR_HR_SHADOW,
            priority = "high",

            x = hr_x,
            y = 0,

            width = 148,
            height = 156,

            frame_count = 1,
            shift = { 0.421875, 0.765625 },
            draw_as_shadow = true,
            scale = 0.5,
        },
    }
end

local function combinator_sprite_layers(sprite_x, sprite_hr_x, shadow_x, shadow_hr_x)
    return {
        combinator_sprite(sprite_x, sprite_hr_x),
        combinator_shadow(shadow_x, shadow_hr_x),
    }
end

selector_entity.sprites = {
    north = {
        layers = combinator_sprite_layers(0, 0, 0, 0),
    },

    east = {
        layers = combinator_sprite_layers(74, 144, 76, 148),
    },

    south = {
        layers = combinator_sprite_layers(148, 288, 152, 296),
    },

    west = {
        layers = combinator_sprite_layers(222, 432, 228, 444),
    },
}

local function combinator_display_direction(x, y, shift)
	return {
        filename = "__selector-combinator__/graphics/selector-displays.png",

        x = x,
        y = y,
        shift = shift,

        width = 15,
        height = 11,

        draw_as_glow = true,

        hr_version = {
            scale = 0.5,
            filename = "__selector-combinator__/graphics/hr-selector-displays.png",

            x = x * 2,
            y = y * 2,
            shift = shift,

            width = 15 * 2,
            height = 11 * 2,

            draw_as_glow = true,
        }
	}
end

local function combinator_display(x, y, verticalShift, horizontalShift)
    return {
        north = combinator_display_direction(x, y, verticalShift),
        south = combinator_display_direction(x, y, verticalShift),

        east = combinator_display_direction(x , y, horizontalShift),
        west = combinator_display_direction(x , y , horizontalShift),
    }
end

local vertical_shift = { 0, -0.140625 }
local horizontal_shift = { 0, -0.328125 }

selector_entity.multiply_symbol_sprites = combinator_display(15, 0, vertical_shift, horizontal_shift)
selector_entity.divide_symbol_sprites = combinator_display(30, 0, vertical_shift, horizontal_shift)
selector_entity.plus_symbol_sprites = combinator_display(0, 0, vertical_shift, horizontal_shift)
selector_entity.minus_symbol_sprites = combinator_display(45, 0, vertical_shift, horizontal_shift)
selector_entity.modulo_symbol_sprites = combinator_display(60, 0, vertical_shift, horizontal_shift)

local selector_out_entity = dataUtil.copy_prototype(data.raw["constant-combinator"]["constant-combinator"], "selector-out-combinator")
selector_out_entity.icon = nil
selector_out_entity.icon_size = nil
selector_out_entity.icon_mipmaps = nil
selector_out_entity.next_upgrade = nil
selector_out_entity.minable = nil
selector_out_entity.selection_box = nil
selector_out_entity.collision_box = nil
selector_out_entity.collision_mask = {}
selector_out_entity.item_slot_count = 500
selector_out_entity.circuit_wire_max_distance = 3
selector_out_entity.flags = {"not-blueprintable", "not-deconstructable", "placeable-off-grid"}

local origin = { 0, 0 }

local origin_wire = {
    red = origin,
    green = origin,
}

local connection_point = {
    wire = origin_wire,
    shadow = origin_wire,
}

selector_out_entity.circuit_wire_connection_points = {
    connection_point,
    connection_point,
    connection_point,
    connection_point,
}

local invisible_sprite = {
    filename = "__core__/graphics/empty.png",
    width = 1,
    height = 1,
}

selector_out_entity.sprites = invisible_sprite
selector_out_entity.activity_led_sprites = invisible_sprite

selector_out_entity.activity_led_light_offsets = {
    origin,
    origin,
    origin,
    origin,
}

selector_out_entity.draw_circuit_wires = false

data:extend {
    selector_entity,
    selector_out_entity,
}