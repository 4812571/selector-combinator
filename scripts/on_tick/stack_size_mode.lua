local StackSizeMode = {}

function StackSizeMode:on_tick()
    local settings = self.settings
    local mode = settings.mode

    local input_signals = self.input_entity.get_merged_signals(defines.circuit_connector_id.combinator_input)
    local cache = self.cache

    if input_signals == nil then
        if not cache.previous_input_was_nil then
            cache.old_inputs = {}

            self.control_behavior.parameters = nil
            cache.previous_input_was_nil = true
        end
        return
    end

    cache.previous_input_was_nil = false

    local inputs_match = true

    if #input_signals < #cache.old_inputs then
        cache.old_inputs = {}
        inputs_match = false
    end

    local old_inputs = cache.old_inputs
    for i=1, #input_signals do
        local name = input_signals[i].signal.name
        if name ~= old_inputs[i] then
            -- correct mismatch, flag mismatch, and continue comparing
            old_inputs[i] = name
            inputs_match = false
        end
    end

    if inputs_match then return end

    local parameters = {}
    local i = 1
    for _, signal in pairs(input_signals) do
        local item_prototype = game.item_prototypes[signal.signal.name]
        if item_prototype then
            parameters[i] = {
                signal = signal.signal,
                count = item_prototype.stack_size,
                index = i
            }
            i = i + 1
        end
    end

    self.control_behavior.parameters = parameters
end

return StackSizeMode
