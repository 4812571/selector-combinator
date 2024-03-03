local CountInputsMode = {}

function CountInputsMode:on_tick()
    local settings = self.settings
    local mode = settings.mode

    local input_signals = self.input_entity.get_merged_signals(defines.circuit_connector_id.combinator_input)
    local cache = self.cache

    if input_signals == nil then
        if not cache.previous_input_was_nil then
            cache.input_count = 0

            self.control_behavior.parameters = nil
            cache.previous_input_was_nil = true
        end
        return
    end

    cache.previous_input_was_nil = false
    
    -- if our number of inputs has changed, and we have a configured signal, update the count in our cache, then output
    if #input_signals ~= cache.input_count and settings.count_signal then
        cache.input_count = #input_signals
        cache.output[1].count = cache.input_count
        self.control_behavior.parameters = cache.output
    end
end

return CountInputsMode
