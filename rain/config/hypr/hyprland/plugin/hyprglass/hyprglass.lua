local plugin_path = HOME .. "/.config/hypr/hyprland/plugin/hyprglass/hyprglass.so"
if not hl.plugin.hyprglass then
    os.execute("hyprctl plugin load " .. plugin_path)
end

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        default_theme = "light",
        default_preset = "glass",
        tint_color = 0x02142aa9,
        glass_opacity = 1,
        brightness = 1,
        dark = { brightness = 1 },
        light = { adaptive_boost = 1 },
        layers = { enabled = 1 },
        blur_strength = 1,
        blur_iterations = 1,
        refraction_strength = 1,
        chromatic_aberration = 1,
        lens_distortion = 1,
        edge_thickness = 0.018,
        fresnel_strength = 0,
        specular_strength = 0,
        contrast = 2,
        saturation = 1,
        vibrancy = 0,
        adaptive_dim = 0,
        adaptive_boost = 0,
    })

    -- Layer surfaces: each call whitelists the namespace and configures it
    hg.layer("quickshell:*", { preset = "clear", mask_threshold = 0.1 })
    hl.window_rule({ match = { class = "discord" },       tag = "+hyprglass_disabled" })
end
