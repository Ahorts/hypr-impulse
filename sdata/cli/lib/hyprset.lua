#!/usr/bin/env lua
-- hyprset.lua - Hyprland override manager (Lua)
-- Manages ~/.config/hypr/hyprland/shellOverrides/main.lua
--
-- Usage:
--   hyprset.lua set <key> <value>         Set a hyprland config option
--   hyprset.lua set-animation <n> <s>     Set animation style (preserves other fields)
--   hyprset.lua reset <key>               Remove an override
--   hyprset.lua merge <repo.lua>          Merge repo defaults into user overrides
--
-- Key format:
--   "decoration:rounding"      → hl.config({decoration={rounding=18}})
--   "animation:workspaces"     → hl.animation({leaf="workspaces", ...})
--   "layerrule:namespace:..."  → hl.layer_rule({match={namespace="..."}, ...})

local HOME = os.getenv("HOME")
local OVERRIDES_DIR = HOME .. "/.config/hypr/hyprland/shellOverrides"
local OVERRIDES_PATH = OVERRIDES_DIR .. "/main.lua"

local function read_lines(path)
    local f = io.open(path, "r")
    if not f then return {} end
    local lines = {}
    for line in f:lines() do table.insert(lines, line) end
    f:close()
    return lines
end

local function write_lines(path, lines)
    os.execute("mkdir -p " .. OVERRIDES_DIR)
    local tmp = path .. ".tmp"
    local f = io.open(tmp, "w")
    for _, line in ipairs(lines) do
        f:write(line, "\n")
    end
    f:close()
    os.rename(tmp, path)
end

local function esc(s)
    return s:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
end

-- Extract identifying key from different hl.* call types
local function extract_key(line)
    local func, content = line:match("^hl%.([%w_]+)%({(.-)}%)$")
    if not func then return nil end

    if func == "config" then
        local parts = {}
        local pos = 1
        while pos <= #content do
            local s, e, key = content:find("^([%w_]+)=", pos)
            if not s then break end
            table.insert(parts, key)
            pos = e + 1
            if content:sub(pos, pos) == "{" then
                pos = pos + 1
            else
                break
            end
        end
        if #parts == 0 then return nil end
        return table.concat(parts, ":")

    elseif func == "animation" then
        local leaf = content:match('leaf%s*=%s*"([^"]+)"')
        if leaf then return "animation:" .. leaf end

    elseif func == "layer_rule" then
        local mf, mv = content:match('match%s*=%s*{(%w+)%s*=%s*"([^"]+)"')
        if mf and mv then return "layerrule:" .. mf .. ":" .. mv end
    end
    return nil
end

-- Build a pattern to match a line by key
local function make_key_pattern(key_parts)
    if key_parts[1] == "animation" and key_parts[2] then
        local leaf = table.concat(key_parts, ":", 2)
        return '^hl%.animation%({.-leaf%s*=%s*"' .. esc(leaf) .. '"'
    elseif key_parts[1] == "layerrule" and key_parts[2] then
        local match_field = key_parts[2]
        local match_val = table.concat(key_parts, ":", 3)
        return '^hl%.layer_rule%({.-match%s*=%s*{' .. esc(match_field) .. '%s*=%s*"' .. esc(match_val) .. '"'
    else
        local p = "^hl%.config%({"
        for i, part in ipairs(key_parts) do
            p = p .. esc(part) .. "="
            if i < #key_parts then p = p .. "{" end
        end
        return p
    end
end

-- Build hl.config({...}) line for regular config keys
local function format_value(val)
    if val == "true" or val == "false" then return val end
    local n = tonumber(val)
    if n then return tostring(n) end
    return '"' .. val .. '"'
end

local function build_config_line(key_parts, value)
    local fmt = format_value(value)
    if #key_parts == 1 then
        return "hl.config({" .. key_parts[1] .. "=" .. fmt .. "})"
    end
    local inner = key_parts[#key_parts] .. "=" .. fmt
    for i = #key_parts - 1, 1, -1 do
        inner = key_parts[i] .. "={" .. inner .. "}"
    end
    return "hl.config({" .. inner .. "})"
end

-- Set a regular hl.config option
local function action_set(key, value)
    local parts = {}
    for part in key:gmatch("[^:]+") do table.insert(parts, part) end
    if #parts == 0 then return end

    local new_line = build_config_line(parts, value)
    local pattern = make_key_pattern(parts)
    local lines = read_lines(OVERRIDES_PATH)
    local found = false
    for i, line in ipairs(lines) do
        if line ~= "" and not line:match("^%s*%-%-") and line:match(pattern) then
            lines[i] = new_line
            found = true
            break
        end
    end
    if not found then
        table.insert(lines, new_line)
    end
    write_lines(OVERRIDES_PATH, lines)
    print("Set " .. key .. " = " .. value)
end

-- Set animation style (partial update via hl.animation)
local function action_set_animation(anim_name, style)
    local lines = read_lines(OVERRIDES_PATH)
    local search = 'hl.animation({leaf="' .. anim_name .. '"'
    local found = false
    for i, line in ipairs(lines) do
        if line:sub(1, #search) == search then
            local new_line = line:gsub('style%s*=%s*"[^"]*"', 'style = "' .. style .. '"')
            lines[i] = new_line
            found = true
            break
        end
    end
    if not found then
        table.insert(lines, 'hl.animation({leaf="' .. anim_name .. '", enabled=true, speed=7, bezier="menu_decel", style="' .. style .. '"})')
    end
    write_lines(OVERRIDES_PATH, lines)
    print("Set animation " .. anim_name .. " = " .. style)
end

-- Remove a line by key
local function action_reset(key)
    local parts = {}
    for part in key:gmatch("[^:]+") do table.insert(parts, part) end
    if #parts == 0 then return end

    local pattern = make_key_pattern(parts)
    local lines = read_lines(OVERRIDES_PATH)
    local new_lines = {}
    for _, line in ipairs(lines) do
        if line:match("^%s*%-%-") or not line:match(pattern) then
            table.insert(new_lines, line)
        end
    end
    write_lines(OVERRIDES_PATH, new_lines)
    print("Reset " .. key)
end

-- Fetch current Hyprland value for a config key via hyprctl
local function get_hyprctl_value(key)
    local cmd = 'hyprctl getoption -j "' .. key .. '" 2>/dev/null'
    local f = io.popen(cmd)
    if not f then return nil end
    local output = f:read("*a")
    f:close()
    if not output or output == "" or output:match("no such option") then return nil end
    -- Parse simple hyprctl JSON: extract int, str, or float value
    local b = output:match('"bool"%s*:%s*(%a+)')
    if b and (b == "true" or b == "false") then return b end
    local i = output:match('"int"%s*:%s*(%-?%d+)')
    if i then return i end
    local s = output:match('"str"%s*:%s*"([^"]+)"')
    if s then return s end
    local fl = output:match('"float"%s*:%s*(%-?%d+%.?%d*)')
    if fl then return fl end
    return nil
end

-- Strip marker comment and trailing space; return (clean_line, marker)
local function parse_marker(line)
    local before, mark = line:match("^(.-)%-%-%s*@(%a+)%s*$")
    if before and (mark == "live" or mark == "static") then
        -- Strip trailing whitespace from the captured content
        before = before:match("^(.-)%s*$")
        return before, mark
    end
    return line, "static"
end

-- Merge repo defaults into user overrides
local function action_merge(repo_path)
    local local_lines = read_lines(OVERRIDES_PATH)
    local repo_lines = read_lines(repo_path)
    local merged = {}
    local existing = {}
    for _, line in ipairs(local_lines) do
        if line:match("^%s*%-%-") or line == "" then
            table.insert(merged, line)
        else
            table.insert(merged, line)
            local k = extract_key(line)
            if k then existing[k] = true end
        end
    end
    for _, line in ipairs(repo_lines) do
        if not line:match("^%s*%-%-") and line ~= "" then
            local raw_line, marker = parse_marker(line)
            local k = extract_key(raw_line)
            if k and not existing[k] then
                if marker == "live" then
                    local val = get_hyprctl_value(k)
                    if val then
                        local parts = {}
                        for part in k:gmatch("[^:]+") do table.insert(parts, part) end
                        local new_line = build_config_line(parts, val)
                        table.insert(merged, new_line)
                        print("Added " .. k .. " = " .. val .. " (live)")
                    else
                        table.insert(merged, raw_line)
                        print("Added " .. k .. " (live unavailable, using static)")
                    end
                else
                    table.insert(merged, raw_line)
                    print("Added " .. k .. " (static)")
                end
            elseif k then
                print("Skipped " .. k .. " (user override exists)")
            end
        end
    end
    write_lines(OVERRIDES_PATH, merged)
    print("Merge complete")
end

-- Main
local action = arg[1]
if action == "set" then
    if not arg[2] or not arg[3] then
        print("Usage: hyprset.lua set <key> <value>"); os.exit(1)
    end
    action_set(arg[2], arg[3])
elseif action == "set-animation" then
    if not arg[2] or not arg[3] then
        print("Usage: hyprset.lua set-animation <name> <style>"); os.exit(1)
    end
    action_set_animation(arg[2], arg[3])
elseif action == "reset" then
    if not arg[2] then
        print("Usage: hyprset.lua reset <key>"); os.exit(1)
    end
    action_reset(arg[2])
elseif action == "merge" then
    if not arg[2] then
        print("Usage: hyprset.lua merge <repo_file>"); os.exit(1)
    end
    action_merge(arg[2])
else
    print("Usage: hyprset.lua <set|set-animation|reset|merge> [...]")
    os.exit(1)
end
