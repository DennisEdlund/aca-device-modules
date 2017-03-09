module TvOne; end

class TvOne::WindowStacker
    include ::Orchestrator::Constants
    include ::Orchestrator::Transcoder

    descriptive_name 'Videowall Window Stacker Logic'
    generic_name :WindowStacker
    implements :logic

description <<-DESC
The CORIOmaster videowall processors does not provide the ability to hide
windows on signal loss. This logic module may be used to bind windows used
in a layout to displays defined within a system. When a display has no source
routed it's Z-index will be dropped to 0, revealing background content.

Use settings to define mapping between system outputs and window ID's:
```
{
    "windows": {
        "Display_1": [1, 2, 3],
        "Display_2": 7,
        "Display_3": [9, 4]
    }
}
```
DESC


    def on_load
        @subscriptions = []
        on_update
    end

    def on_unload; end

    def on_update
        @subscriptions.each do |reference|
            unsubscribe(reference)
        end

        bindings = setting(:windows) || {}
        @videowall = setting(:videowall) || 1
        @show = setting(:show) || 15  # visible z layer
        @hide = setting(:hide) || 0   # hidden z layer

       # Subscribe to source updates and relayer on change
        @subscriptions = bindings.map do |display, window|
               system.subscribe(:System, 1, display) do |notice|
                       logger.debug { "Restacking #{display} linked windows due to source change" }
                       source = notice.value[:source]
                       restack window, source
               end
        end
    end


    protected


    def relayer(window, source); end
    
    def restack(window, source)
        z_index = source == :none ? @hide : @show
        [*window].each do |id|
            system.get(:VideoWall, @videowall).window id, "Zorder", z_index
        end
    end

end
