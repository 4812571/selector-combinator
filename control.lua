local SelectorSimulation = require("scripts.selector_simulation")
local SelectorGui = require("scripts.selector_gui")

script.on_init(function()
    SelectorSimulation.init()
end)

local selector_filter = {
    filter = "name",
    name = "selector-combinator",
}

local function on_added(event)
    SelectorSimulation.add_combinator(event.created_entity)
end

local function on_entity_destroyed(event)
    SelectorSimulation.remove_combinator(event.entity.unit_number)
end

local function on_destroyed(event)
    SelectorSimulation.remove_combinator(event.unit_number)
end

local function on_gui_opened(event)
    local entity = event.entity

    if not entity then
        return
    end

    if not entity.valid then
        return
    end

    if entity.name ~= "selector-combinator" then
        return
    end

    local player = game.get_player(event.player_index)

    if not player then
        return
    end

    SelectorGui.on_gui_added(player, entity)
end

local function on_gui_closed(event)
    local element = event.element

    if not element then
        return
    end

    if element.name ~= "selector-gui" then
        return
    end

    local player = game.get_player(event.player_index)

    if not player then
        return
    end

    SelectorGui.gui_closed(player)
end

local function on_tick()
    SelectorSimulation.update()
end

SelectorGui.bind_all_events()

-- Added Events
script.on_event(defines.events.on_built_entity, on_added, {selector_filter})

-- Removed Events
script.on_event(defines.events.on_player_mined_entity, on_entity_destroyed, {selector_filter})
script.on_event(defines.events.on_robot_mined_entity, on_entity_destroyed, {selector_filter})
script.on_event(defines.events.script_raised_destroy, on_entity_destroyed, {selector_filter})

-- *Special* Removed Events
script.on_event(defines.events.on_entity_destroyed, on_destroyed)

-- GUI Events
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)

-- Update Event
script.on_event(defines.events.on_tick, on_tick)

-- Put every player that joins into editor mode
script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    player.cheat_mode = true

    if not player then
        return
    end

    for _, tech in pairs(player.force.technologies) do
        tech.researched = true
    end
end)