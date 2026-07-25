local msg = require("mp.msg")

local function shell_quote(value)
    return "'" .. string.gsub(value, "'", "'\\''") .. "'"
end

local function sync_material_palette()
    local path = mp.get_property("path")
    if not path or path == "" then
        return
    end

    local lower = string.lower(path)
    if not (lower:match("%.mp4$") or lower:match("%.webm$") or
            lower:match("%.mkv$") or lower:match("%.mov$") or
            lower:match("%.gif$")) then
        return
    end

    local hook = (os.getenv("HOME") or "") .. "/.config/noctalia/wallpaper-hook.sh"
    if hook == "/.config/noctalia/wallpaper-hook.sh" then
        msg.error("HOME is unavailable; cannot synchronize wallpaper colors")
        return
    end

    mp.commandv("run", "sh", "-c",
        "NOCTALIA_WALLPAPER_PATH=" .. shell_quote(path) .. " " .. shell_quote(hook))
end

mp.register_event("file-loaded", sync_material_palette)
