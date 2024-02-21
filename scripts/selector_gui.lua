local SelectorAppearance = require("scripts.selector_appearance")

local SelectorGui = {}

local function find(tab, element)
    for index, value in pairs(tab) do
        if value == element then
            return index
        end
    end

    return false
end

local function write_text_boxes(entry, gui)
    local options_flow = gui.inner_frame.options_flow

    local select_index_constant = options_flow.select_index_control_flow.select_index_select_flow.select_index_constant
    local random_input_update_interval_textfield = options_flow.random_input_update_interval_flow.random_input_update_interval_textfield

    select_index_constant.text = tostring(entry.index_constant)
    random_input_update_interval_textfield.text = tostring(entry.interval)
end

local function write_radio_buttons(entry, gui)
    local options_flow = gui.inner_frame.options_flow

    local radio_buttons = {
        index = options_flow.select_index_button_flow.select_index_button,
        count_inputs = options_flow.count_inputs_button_flow.count_inputs_button,
        random_input = options_flow.random_input_button_flow.random_input_button,
        stack_size = options_flow.stack_size_button_flow.stack_size_button,
        quality_transfer = options_flow.quality_transfer_button_flow.quality_transfer_button,
    }

    for _, button in pairs(radio_buttons) do
        button.state = false
    end

    radio_buttons[entry.mode].state = true
end

local function write_switches(entry, gui)
    local options_flow = gui.inner_frame.options_flow

    local select_index_switch = options_flow.select_index_control_flow.select_index_switch_flow.select_index_switch

    if entry.index_order == "ascending" then
        select_index_switch.switch_state = "right"
    else
        select_index_switch.switch_state = "left"
    end
end

local function write_signals(entry, gui)
    local options_flow = gui.inner_frame.options_flow

    local selection_signal_guis = {
        select_index = options_flow.select_index_control_flow.select_index_select_flow.select_index_signal,
        count_inputs = options_flow.count_inputs_signal,
        quality_selection = options_flow.quality_selection_signal_flow.quality_selection_signal,
        quality_target = options_flow.quality_target_signal_flow.quality_target_signal,
    }

    selection_signal_guis.select_index.elem_value = entry.index_signal
    selection_signal_guis.count_inputs.elem_value = entry.count_signal
    selection_signal_guis.quality_selection.elem_value = entry.quality_selection_signal
    selection_signal_guis.quality_target.elem_value = entry.quality_target_signal
end

function SelectorGui.on_gui_added(player, entity)
    local screen = player.gui.screen

    if screen.selector_gui then
        screen.selector_gui.destroy()
    end

    local gui = screen.add {
        type = "frame",
        name = "selector_gui",
        direction = "vertical",

        tags = {
            selector_id = entity.unit_number,
        }
    }

    local title_bar = gui.add {
        type = "flow",
        name = "title_bar",
        direction = "horizontal",
    }

    title_bar.drag_target = gui

    title_bar.add {
        type = "label",
        name = "title",
        style = "frame_title",
        ignored_by_interaction = true,
        caption = {"selector-gui.title"},
    }

    title_bar.add {
        type = "empty-widget",
        name = "drag_handle",
        ignored_by_interaction = true,
        style = "flib_titlebar_drag_handle",
    }

    title_bar.add {
        type = "sprite-button",
        name = "close_button",
        style = "frame_action_button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
    }

    local inner_frame = gui.add {
        type = "frame",
        name = "inner_frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding",
    }

    inner_frame.style.padding = 12
    inner_frame.style.bottom_padding = 9

    local indicator = inner_frame.add {
        type = "flow",
        name = "indicator",
        direction = "horizontal",
        style = "status_flow",
    }

    indicator.style.vertical_align = "center"
    indicator.style.horizontally_stretchable = true
    indicator.style.bottom_padding = 4

    local status_image = indicator.add {
        type = "sprite",
        name = "indicator_sprite",
        sprite = "utility/status_not_working",
        style = "status_image",
    }

    status_image.style.stretch_image_to_widget_size = true

    indicator.add {
        type = "label",
        name = "indicator_label",
        caption = "Working",
    }

    local preview_frame = inner_frame.add {
        type = "frame",
        name = "preview",
        style = "deep_frame_in_shallow_frame",
    }

    local preview = preview_frame.add {
        type = "entity-preview",
        name = "preview",
        style = "wide_entity_button",
    }

    preview.entity = entity

    local options_flow = inner_frame.add {
        type = "flow",
        name = "options_flow",
        direction = "vertical",
    }

    options_flow.style.horizontal_align = "left"

    -- Select Index
    local select_index_button_flow = options_flow.add {
        type = "flow",
        name = "select_index_button_flow",
        direction = "horizontal",
    }

    select_index_button_flow.style.top_padding = 4

    local select_index_button = select_index_button_flow.add {
        type = "radiobutton",
        name = "select_index_button",
        state = false,
        caption = {"", {"selector-gui.select-input"}, " [img=info]"},
        tooltip = {"selector-gui.select-input-tooltip"},
    }

    select_index_button.style.font_color = {255, 230, 192}
    select_index_button.style.font = "heading-3"

    local select_index_control_flow = options_flow.add {
        type = "flow",
        name = "select_index_control_flow",
        direction = "vertical",
    }

    local select_index_select_flow = select_index_control_flow.add {
        type = "flow",
        name = "select_index_select_flow",
        direction = "horizontal",
    }

    select_index_select_flow.style.vertical_align = "center"
    select_index_select_flow.style.horizontal_spacing = 8

    local select_index_signal = select_index_select_flow.add {
        type = "choose-elem-button",
        name = "select_index_signal",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        signal = {type = "virtual", name = nil},
        caption = {"selector-gui.select-input-index"},
    }

    select_index_select_flow.add {
        type = "label",
        name = "or_signal",
        caption = {"selector-gui.or"},
    }

    local select_index_constant = select_index_select_flow.add {
        type = "textfield",
        name = "select_index_constant",
        style = "very_short_number_textfield",
        text = "0",
        numeric = true,
        allow_decimal = false,
        clear_and_focus_on_right_click = true,
    }

    select_index_constant.style.width = 50

    local select_index_switch_flow = select_index_control_flow.add {
        type = "flow",
        name = "select_index_switch_flow",
        direction = "horizontal",
    }

    select_index_switch_flow.style.vertical_align = "center"

    local select_index_switch = select_index_switch_flow.add {
        type = "switch",
        name = "select_index_switch",
        allow_none_state = false,
        switch_state = "left",
        left_label_caption = {"selector-gui.select-input-sort-descending"},
        right_label_caption = {"selector-gui.select-input-sort-ascending"},
    }

    local line_1 =  options_flow.add {
        type = "line",
        style = "line",
    }

    line_1.style.top_padding = 4
    line_1.style.bottom_padding = 4

    -- Count Inputs
    local count_inputs_button_flow = options_flow.add {
        type = "flow",
        name = "count_inputs_button_flow",
        direction = "horizontal",
    }

    local count_input_button = count_inputs_button_flow.add {
        type = "radiobutton",
        name = "count_inputs_button",
        state = false,
        caption = {"", {"selector-gui.count-inputs"}, " [img=info]"},
        tooltip = {"selector-gui.count-inputs-tooltip"},
    }

    count_input_button.style.font_color = {255, 230, 192}
    count_input_button.style.font = "heading-3"

    local count_inputs_signal = options_flow.add {
        type = "choose-elem-button",
        name = "count_inputs_signal",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        signal = {type = "virtual", name = nil},
    }

    local line_2 =  options_flow.add {
        type = "line",
        style = "line",
    }

    line_2.style.top_padding = 4
    line_2.style.bottom_padding = 4

    -- Random Input
    local random_input_button_flow = options_flow.add {
        type = "flow",
        name = "random_input_button_flow",
        direction = "horizontal",
    }

    random_input_button_flow.style.top_padding = 4

    local random_input_button = random_input_button_flow.add {
        type = "radiobutton",
        name = "random_input_button",
        state = false,
        caption = {"", {"selector-gui.random-input"}, " [img=info]"},
        tooltip = {"selector-gui.random-input-tooltip"},
    }

    random_input_button.style.font_color = {255, 230, 192}
    random_input_button.style.font = "heading-3"

    local random_input_update_interval_flow = options_flow.add {
        type = "flow",
        name = "random_input_update_interval_flow",
        direction = "horizontal",
    }

    random_input_update_interval_flow.style.vertical_align = "center"

    random_input_update_interval_flow.add {
        type = "label",
        name = "random_input_update_interval_label",
        caption = {"selector-gui.random-input-update-interval"},
    }

    local random_text = random_input_update_interval_flow.add {
        type = "textfield",
        name = "random_input_update_interval_textfield",
        style = "very_short_number_textfield",
        text = "1",
        numeric = true,
        allow_decimal = false,
        clear_and_focus_on_right_click = true,
    }

    random_text.style.width = 50

    local line_3 =  options_flow.add {
        type = "line",
        style = "line",
    }

    line_3.style.top_padding = 4
    line_3.style.bottom_padding = 4

    -- Stack Size
    local stack_size_button_flow = options_flow.add {
        type = "flow",
        name = "stack_size_button_flow",
        direction = "horizontal",
    }

    stack_size_button_flow.style.top_padding = 4

    local stack_size_button = stack_size_button_flow.add {
        type = "radiobutton",
        name = "stack_size_button",
        state = false,
        caption = {"", {"selector-gui.stack-size"}, " [img=info]"},
        tooltip = {"selector-gui.stack-size-tooltip"},
    }

    stack_size_button.style.font_color = {255, 230, 192}
    stack_size_button.style.font = "heading-3"

    local line_4 =  options_flow.add {
        type = "line",
        style = "line",
    }

    line_4.style.top_padding = 4
    line_4.style.bottom_padding = 4

    -- Quality Transfer
    local quality_transfer_button_flow = options_flow.add {
        type = "flow",
        name = "quality_transfer_button_flow",
        direction = "horizontal",
    }

    quality_transfer_button_flow.style.top_padding = 4

    local quality_transfer_button = quality_transfer_button_flow.add {
        type = "radiobutton",
        name = "quality_transfer_button",
        state = false,
        caption = {"", {"selector-gui.quality-transfer"}, " [img=info]"},
        tooltip = {"selector-gui.quality-transfer-tooltip"},
    }

    quality_transfer_button.style.font_color = {255, 230, 192}
    quality_transfer_button.style.font = "heading-3"

    local quality_selection_signal_flow = options_flow.add {
        type = "flow",
        name = "quality_selection_signal_flow",
        direction = "horizontal",
    }

    quality_selection_signal_flow.style.vertical_align = "center"

    local quality_selection_signal = quality_selection_signal_flow.add {
        type = "choose-elem-button",
        name = "quality_selection_signal",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        signal = {type = "virtual", name = nil},
    }

    local quality_selection_signal_label = quality_selection_signal_flow.add {
        type = "label",
        name = "quality_selection_signal_label",
        caption = {"selector-gui.quality-selection-signal"},
    }

    quality_selection_signal_label.style.left_margin = 8

    local quality_target_signal_flow = options_flow.add {
        type = "flow",
        name = "quality_target_signal_flow",
        direction = "horizontal",
    }

    quality_target_signal_flow.style.vertical_align = "center"

    local quality_target_signal = quality_target_signal_flow.add {
        type = "choose-elem-button",
        name = "quality_target_signal",
        style = "slot_button_in_shallow_frame",
        elem_type = "signal",
        signal = {type = "virtual", name = nil},
    }

    local quality_target_signal_label = quality_target_signal_flow.add {
        type = "label",
        name = "quality_target_signal_label",
        caption = {"selector-gui.quality-target-signal"},
    }

    quality_target_signal_label.style.left_margin = 8

    local entry = global.selector_combinators[entity.unit_number]

    if entry then
        write_radio_buttons(entry, gui)
        write_text_boxes(entry, gui)
        write_switches(entry, gui)
        write_signals(entry, gui)
    end

    player.opened = gui
    gui.force_auto_center()
end

function SelectorGui.on_gui_removed(player)
    local screen = player.gui.screen

    local gui = screen.selector_gui

    if gui then
        gui.destroy()
    end
end

function SelectorGui.bind_all_events()
    script.on_event(defines.events.on_gui_click, function(eventData)
        local element = eventData.element

        local player = game.get_player(eventData.player_index)

        if not player then
            return
        end

        if element.name == "close_button" then
            SelectorGui.on_gui_removed(player)
        end
    end)

    script.on_event(defines.events.on_gui_checked_state_changed, function(eventData)
        local player = game.get_player(eventData.player_index)

        if not player then
            return
        end

        local gui = player.gui.screen.selector_gui

        if not gui then
            return
        end

        local selector_id = gui.tags.selector_id

        if not selector_id then
            return
        end

        local selector_entry = global.selector_combinators[selector_id]

        if not selector_entry then
            return
        end

        local options_flow = gui.inner_frame.options_flow

        local radio_buttons = {
            select_index = options_flow.select_index_button_flow.select_index_button,
            count_inputs = options_flow.count_inputs_button_flow.count_inputs_button,
            random_input = options_flow.random_input_button_flow.random_input_button,
            stack_size = options_flow.stack_size_button_flow.stack_size_button,
            quality_transfer = options_flow.quality_transfer_button_flow.quality_transfer_button,
        }

        local element = eventData.element

        -- The player clicked on a radio button
        if find(radio_buttons, element) then
            -- Uncheck all other radio buttons
            for _, button in pairs(radio_buttons) do
                button.state = button == eventData.element
            end
        end

        if element == radio_buttons.select_index then
            selector_entry.mode = "index"
        end

        if element == radio_buttons.count_inputs then
            selector_entry.mode = "count_inputs"
        end

        if element == radio_buttons.random_input then
            selector_entry.mode = "random-input"
        end

        if element == radio_buttons.stack_size then
            selector_entry.mode = "stack_size"
        end

        if element == radio_buttons.quality_transfer then
            selector_entry.mode = "quality_transfer"
        end

        if find(radio_buttons, element) then
            SelectorAppearance.update_combinator_appearance(selector_entry.input_entity)
        end
    end)

    script.on_event(defines.events.on_gui_elem_changed, function(eventData)
        local player = game.get_player(eventData.player_index)

        if not player then
            return
        end

        local gui = player.gui.screen.selector_gui

        if not gui then
            return
        end

        local selector_id = gui.tags.selector_id

        if not selector_id then
            return
        end

        local selector_entry = global.selector_combinators[selector_id]

        if not selector_entry then
            return
        end

        local options_flow = gui.inner_frame.options_flow

        local selection_signal_guis = {
            select_index = options_flow.select_index_control_flow.select_index_select_flow.select_index_signal,
            count_inputs = options_flow.count_inputs_signal,
            quality_selection = options_flow.quality_selection_signal_flow.quality_selection_signal,
            quality_target = options_flow.quality_target_signal_flow.quality_target_signal,
        }

        local element = eventData.element

        if eventData.element == selection_signal_guis.select_index then
            selector_entry.index_signal = eventData.element.elem_value
        end

        if eventData.element == selection_signal_guis.count_inputs then
            selector_entry.count_signal = eventData.element.elem_value
        end

        if eventData.element == selection_signal_guis.quality_selection then
            selector_entry.quality_selection_signal = eventData.element.elem_value
        end

        if eventData.element == selection_signal_guis.quality_target then
            selector_entry.quality_target_signal = eventData.element.elem_value
        end
    end)

    script.on_event(defines.events.on_gui_text_changed, function(eventData)
        local player = game.get_player(eventData.player_index)

        if not player then
            return
        end

        local gui = player.gui.screen.selector_gui

        if not gui then
            return
        end

        local selector_id = gui.tags.selector_id

        if not selector_id then
            return
        end

        local selector_entry = global.selector_combinators[selector_id]

        if not selector_entry then
            return
        end

        local options_flow = gui.inner_frame.options_flow

        local select_index_constant = options_flow.select_index_control_flow.select_index_select_flow.select_index_constant
        local random_input_update_interval_textfield = options_flow.random_input_update_interval_flow.random_input_update_interval_textfield

        if eventData.element == select_index_constant then
            selector_entry.index_constant = tonumber(eventData.element.text)
        end

        if eventData.element == random_input_update_interval_textfield then
            selector_entry.interval = tonumber(eventData.element.text)
        end
    end)

    -- handle the switch going left or right
    script.on_event(defines.events.on_gui_switch_state_changed, function(eventData)
        local player = game.get_player(eventData.player_index)

        if not player then
            return
        end

        local gui = player.gui.screen.selector_gui

        if not gui then
            return
        end

        local selector_id = gui.tags.selector_id

        if not selector_id then
            return
        end

        local selector_entry = global.selector_combinators[selector_id]

        if not selector_entry then
            return
        end

        local options_flow = gui.inner_frame.options_flow

        local select_index_switch = options_flow.select_index_control_flow.select_index_switch_flow.select_index_switch

        if eventData.element == select_index_switch then
            if eventData.element.switch_state == "left" then
                selector_entry.index_order = "descending"
            else
                selector_entry.index_order = "ascending"
            end

            SelectorAppearance.update_combinator_appearance(selector_entry.input_entity)
        end
    end)
end

return SelectorGui