if global and global.selector_combinators then
    for _, selector in pairs(global.selector_combinators) do
        -- move copyable settings from selector to selector.settings
        if not selector.settings then
            selector.settings = {}

            settings.mode = selector.mode
            settings.index_order = selector.index_order
            settings.index_constant = selector.index_constant
            settings.index_signal = selector.index_signal
            settings.count_signal = selector.count_signal
            settings.quality_selection_signal = selector.quality_selection_signal
            settings.quality_target_signal = selector.quality_target_signal

            selector.mode = nil
            selector.index_order = nil
            selector.index_constant = nil
            selector.index_signal = nil
            selector.count_signal = nil
            selector.quality_selection_signal = nil
            selector.quality_target_signal = nil
        end
        
        -- Ensure that the index constant is not nil
        if not selector.settings.index_constant then
            selector.settings.index_constant = 0
        end
    end
end
