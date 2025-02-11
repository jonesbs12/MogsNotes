local defaults = {
    target_box = {
        pos = {
            x = windower.get_windower_settings().ui_x_res / 4,
            y = windower.get_windower_settings().ui_y_res / 2
        },
        bg = {
            alpha = 150,
            red = 100,
            green = 100,
            blue = 100
        },
        text = {
            size = 8,
            font = 'Consolas',
            stroke = {
                width = 1,
                alpha = 200
            }
        },
        padding = 10,
        flags = {
            bold = true
        },
        show = true,
    }
}
return defaults