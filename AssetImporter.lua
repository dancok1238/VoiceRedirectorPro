--[[
    ASSET IMPORTER (versi baru)
    - Scan file .rbxm / .rbxmx / .rbxl / .rbxlx dari folder workspace executor
    - Filter ALL / MODEL / PLACE
    - Tombol IMPORT per file -> masuk ke Folder baru di Workspace
    Taruh file asset di folder: workspace/ImporterAssets (dibuat otomatis)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local ASSET_FOLDER = "ImporterAssets"
local SCAN_FOLDERS = { ASSET_FOLDER, "" } -- "" = root workspace executor

local C = {
    bg = Color3.fromRGB(15, 12, 20),
    side = Color3.fromRGB(18, 14, 25),
    card = Color3.fromRGB(22, 16, 32),
    accent = Color3.fromRGB(157, 78, 221),
    accent2 = Color3.fromRGB(199, 125, 255),
    text = Color3.fromRGB(245, 240, 255),
    muted = Color3.fromRGB(150, 140, 175),
    ok = Color3.fromRGB(80, 200, 120),
    err = Color3.fromRGB(230, 70, 90),
}

-- ============ Helper UI ============
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(p, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p) end
local function stroke(p, col, tr) return new("UIStroke", {Color = col or C.accent, Transparency = tr or 0.5, Thickness = 1.2}, p) end
local function label(p, text, size, pos, sz, col, font)
    return new("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextSize = size or 12,
        Font = font or Enum.Font.GothamBold, TextColor3 = col or C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = pos or UDim2.new(), Size = sz or UDim2.new(1, 0, 0, 20),
    }, p)
end

local function getParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    if ok and ui then return ui end
    ok, ui = pcall(function() return game:GetService("CoreGui") end)
    if ok and ui then return ui end
    return lp:WaitForChild("PlayerGui")
end

local old = getParent():FindFirstChild("AssetImporterUI")
if old then old:Destroy() end

local gui = new("ScreenGui", {
    Name = "AssetImporterUI", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 100,
}, getParent())

-- ============ Notifikasi ============
local function notify(title, msg, isErr)
    local col = isErr and C.err or C.accent
    local f = new("Frame", {
        Size = UDim2.fromOffset(260, 56), AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 300, 1, -20), BackgroundColor3 = C.card,
    }, gui)
    corner(f, 12); stroke(f, col, 0.4)
    label(f, title, 12, UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 18))
    local m = label(f, msg, 10, UDim2.fromOffset(14, 28), UDim2.new(1, -28, 0, 22), C.muted, Enum.Font.Gotham)
    m.TextWrapped = true; m.TextYAlignment = Enum.TextYAlignment.Top
    TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(1, -16, 1, -20)}):Play()
    task.delay(3, function()
        local t = TweenService:Create(f, TweenInfo.new(0.3), {Position = UDim2.new(1, 300, 1, -20)})
        t:Play(); t.Completed:Wait(); f:Destroy()
    end)
end

-- ============ Window ============
local main = new("Frame", {
    Size = UDim2.fromOffset(560, 380), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.bg, ClipsDescendants = true,
}, gui)
corner(main, 10); stroke(main, C.accent, 0.3)
local scale = new("UIScale", {}, main)
local function fit()
    local cam = workspace.CurrentCamera
    if cam then
        local v = cam.ViewportSize
        scale.Scale = math.min(v.X / 600, v.Y / 420, 1)
    end
end
fit()

-- drag
do
    local dragging, startPos, startUI
    main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startPos, startUI = true, i.Position, main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startPos
            main.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + d.X, startUI.Y.Scale, startUI.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- sidebar
local side = new("Frame", {Size = UDim2.new(0, 170, 1, 0), BackgroundColor3 = C.side}, main)
corner(side, 10)
label(side, "ASSET IMPORTER", 13, UDim2.fromOffset(14, 14), UDim2.new(1, -28, 0, 18))
label(side, "v1.0", 10, UDim2.fromOffset(14, 33), UDim2.new(1, -28, 0, 14), C.muted, Enum.Font.GothamMedium)

local content = new("Frame", {
    Size = UDim2.new(1, -170, 1, 0), Position = UDim2.fromOffset(170, 0),
    BackgroundTransparency = 1, ClipsDescendants = true,
}, main)

local closeBtn = new("TextButton", {
    Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -38, 0, 12),
    BackgroundColor3 = Color3.fromRGB(32, 24, 46), Text = "X", Font = Enum.Font.GothamBold,
    TextSize = 13, TextColor3 = C.text, ZIndex = 5,
}, main)
corner(closeBtn, 8)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- ============ Views ============
local views, navButtons = {}, {}

local function makeView(name)
    local v = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false}, content)
    views[name] = v
    return v
end

local function showView(name)
    for n, v in pairs(views) do v.Visible = (n == name) end
    for n, b in pairs(navButtons) do
        b.BackgroundTransparency = (n == name) and 0 or 1
        b.TextColor3 = (n == name) and C.text or C.muted
    end
end

local function navButton(name, order)
    local b = new("TextButton", {
        Size = UDim2.new(1, -28, 0, 34), Position = UDim2.fromOffset(14, 70 + (order - 1) * 40),
        BackgroundColor3 = Color3.fromRGB(38, 28, 55), BackgroundTransparency = 1,
        Text = name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.muted,
    }, side)
    corner(b, 8)
    b.MouseButton1Click:Connect(function() showView(name) end)
    navButtons[name] = b
end

navButton("Overview", 1)
navButton("Assets", 2)
navButton("Scripts", 3)
navButton("Settings", 4)

-- ---- Overview ----
local ov = makeView("Overview")
label(ov, "System Profile", 17, UDim2.fromOffset(20, 20), UDim2.new(1, -40, 0, 24))
local prof = new("Frame", {Size = UDim2.new(1, -40, 0, 80), Position = UDim2.fromOffset(20, 54), BackgroundColor3 = C.card}, ov)
corner(prof, 12); stroke(prof)
label(prof, lp.DisplayName, 15, UDim2.fromOffset(16, 16), UDim2.new(1, -32, 0, 20))
label(prof, "@" .. lp.Name .. "  |  ID: " .. lp.UserId, 11, UDim2.fromOffset(16, 40), UDim2.new(1, -32, 0, 16), C.muted, Enum.Font.Gotham)

local statTotal = new("Frame", {Size = UDim2.new(0.5, -26, 0, 60), Position = UDim2.fromOffset(20, 148), BackgroundColor3 = C.card}, ov)
corner(statTotal, 10); stroke(statTotal)
label(statTotal, "TOTAL ASSETS", 10, UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 14), C.muted)
local lblTotal = label(statTotal, "0", 20, UDim2.fromOffset(12, 26), UDim2.new(1, -24, 0, 26))

-- ---- Assets ----
local av = makeView("Assets")
label(av, "Dashboard", 17, UDim2.fromOffset(20, 20), UDim2.new(1, -60, 0, 22))
label(av, "Taruh file di workspace/" .. ASSET_FOLDER, 11, UDim2.fromOffset(20, 44), UDim2.new(1, -40, 0, 14), C.muted, Enum.Font.Gotham)

local filter = "ALL"
local rows = {}

local function applyFilter()
    for _, r in ipairs(rows) do
        r.frame.Visible = (filter == "ALL") or (r.kind == filter)
    end
end

local filterBtns = {}
for i, name in ipairs({"ALL", "MODEL", "PLACE"}) do
    local b = new("TextButton", {
        Size = UDim2.fromOffset(70, 26), Position = UDim2.fromOffset(20 + (i - 1) * 76, 68),
        BackgroundColor3 = (i == 1) and C.accent or C.card, Text = name,
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.text,
    }, av)
    corner(b, 13)
    filterBtns[name] = b
    b.MouseButton1Click:Connect(function()
        filter = name
        for n, fb in pairs(filterBtns) do fb.BackgroundColor3 = (n == name) and C.accent or C.card end
        applyFilter()
    end)
end

local rescan = new("TextButton", {
    Size = UDim2.fromOffset(100, 26), Position = UDim2.new(1, -120, 0, 68),
    BackgroundColor3 = C.card, Text = "Rescan", Font = Enum.Font.GothamBold,
    TextSize = 11, TextColor3 = C.text,
}, av)
corner(rescan, 13); stroke(rescan)

local scroll = new("ScrollingFrame", {
    Size = UDim2.new(1, -40, 1, -110), Position = UDim2.fromOffset(20, 104),
    BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = C.accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, av)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

-- ---- Settings ----
local sv = makeView("Settings")
label(sv, "About", 17, UDim2.fromOffset(20, 20), UDim2.new(1, -40, 0, 24))
local about = label(sv, "Asset Importer: scan dan import file .rbxm/.rbxl dari folder workspace executor ke Workspace game (lokal/client).", 11, UDim2.fromOffset(20, 54), UDim2.new(1, -40, 0, 60), C.muted, Enum.Font.Gotham)
about.TextWrapped = true; about.TextYAlignment = Enum.TextYAlignment.Top

-- ---- Scripts (viewer) ----
local scv = makeView("Scripts")
label(scv, "Script Viewer", 17, UDim2.fromOffset(20, 20), UDim2.new(1, -60, 0, 22))
local scList = new("ScrollingFrame", {
    Size = UDim2.new(1, -40, 0, 110), Position = UDim2.fromOffset(20, 50),
    BackgroundColor3 = C.card, ScrollBarThickness = 2, ScrollBarImageColor3 = C.accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, scv)
corner(scList, 8)
new("UIListLayout", {Padding = UDim.new(0, 4)}, scList)
local codeBox = new("TextBox", {
    Size = UDim2.new(1, -40, 1, -210), Position = UDim2.fromOffset(20, 168),
    BackgroundColor3 = C.card, Text = "Import file dulu, lalu pilih script di atas.",
    TextColor3 = C.text, Font = Enum.Font.Code, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false, TextEditable = false, MultiLine = true,
    TextWrapped = false, ClipsDescendants = true,
}, scv)
corner(codeBox, 8)
local copyBtn = new("TextButton", {
    Size = UDim2.fromOffset(100, 26), Position = UDim2.new(0, 20, 1, -34),
    BackgroundColor3 = C.accent, Text = "COPY", Font = Enum.Font.GothamBold,
    TextSize = 11, TextColor3 = Color3.new(1, 1, 1),
}, scv)
corner(copyBtn, 8)

local currentSrc = ""
local function showSource(src)
    currentSrc = src
    if #src > 20000 then
        codeBox.Text = src:sub(1, 20000) .. "\n-- [dipotong, pakai COPY untuk isi penuh]"
    else
        codeBox.Text = src
    end
end
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard and currentSrc ~= "" then
        pcall(setclipboard, currentSrc)
        notify("Copied", "Isi script disalin ke clipboard.", false)
    else
        notify("Failed", "Pilih script dulu / executor tanpa setclipboard.", true)
    end
end)

local function registerScript(path, class, src)
    local b = new("TextButton", {
        Size = UDim2.new(1, -8, 0, 22), BackgroundColor3 = Color3.fromRGB(32, 24, 46),
        Text = " [" .. class .. "] " .. path, Font = Enum.Font.GothamMedium, TextSize = 10,
        TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, scList)
    corner(b, 6)
    b.MouseButton1Click:Connect(function() showSource(src) end)
end

-- ============ Logic ============
local function kindOf(name)
    local l = name:lower()
    if l:match("%.rbxmx?$") then return "MODEL" end
    if l:match("%.rbxlx?$") then return "PLACE" end
end

local function fileName(path) return path:match("([^/\\]+)$") or path end

local function scanFiles()
    local found, seen = {}, {}
    if not listfiles then return found end
    for _, folder in ipairs(SCAN_FOLDERS) do
        local ok, list = pcall(listfiles, folder)
        if ok and type(list) == "table" then
            for _, path in ipairs(list) do
                local kind = kindOf(path)
                if kind and not seen[path] then
                    seen[path] = true
                    table.insert(found, {name = fileName(path), path = path, kind = kind})
                end
            end
        end
    end
    return found
end

-- ---------- Parser file rbxm/rbxmx (untuk baca isi script) ----------
local SCRIPT_CLASSES = {Script = true, LocalScript = true, ModuleScript = true}

local function lz4block(src)
    local out, o, i, n = {}, 0, 1, #src
    local byte = string.byte
    while i <= n do
        local token = byte(src, i); i += 1
        local lit = bit32.rshift(token, 4)
        if lit == 15 then
            local b
            repeat b = byte(src, i); i += 1; lit += b until b ~= 255
        end
        for k = 0, lit - 1 do out[o + k + 1] = byte(src, i + k) end
        o += lit; i += lit
        if i > n then break end
        local off = byte(src, i) + byte(src, i + 1) * 256; i += 2
        local ml = bit32.band(token, 15)
        if ml == 15 then
            local b
            repeat b = byte(src, i); i += 1; ml += b until b ~= 255
        end
        ml += 4
        local start = o - off
        for k = 1, ml do out[o + k] = out[start + k] end
        o += ml
    end
    local parts = {}
    for st = 1, o, 4096 do
        parts[#parts + 1] = string.char(table.unpack(out, st, math.min(st + 4095, o)))
    end
    return table.concat(parts)
end

local function decompressChunk(comp, raw)
    if comp == 0 then return raw end
    if raw:sub(1, 4) == "\40\181\47\253" then
        assert(zstddecompress, "executor tidak support zstddecompress")
        return zstddecompress(raw)
    end
    return lz4block(raw)
end

local function readInts(data, pos, n)
    local res, byte = {}, string.byte
    for i = 0, n - 1 do
        local x = byte(data, pos + i) * 16777216 + byte(data, pos + n + i) * 65536
            + byte(data, pos + 2 * n + i) * 256 + byte(data, pos + 3 * n + i)
        res[i + 1] = (x % 2 == 0) and (x / 2) or (-(x + 1) / 2)
    end
    return res, pos + n * 4
end

local function readRefs(data, pos, n)
    local ints, np = readInts(data, pos, n)
    local acc = 0
    for i = 1, n do acc += ints[i]; ints[i] = acc end
    return ints, np
end

local function chainPath(insts, inst)
    local names, cur = {}, inst
    while cur do
        table.insert(names, 1, cur.name)
        cur = insts[cur.parent]
    end
    return table.concat(names, "/")
end

local function parseBinary(data)
    if data:sub(1, 8) ~= "<roblox!" then return nil end
    local pos = 33
    local classes, insts, order = {}, {}, {}
    while pos <= #data do
        local name = data:sub(pos, pos + 3)
        local comp, unc = string.unpack("<I4I4", data, pos + 4)
        pos += 16
        local raw
        if comp == 0 then
            raw = data:sub(pos, pos + unc - 1); pos += unc
        else
            raw = data:sub(pos, pos + comp - 1); pos += comp
        end
        if name == "END\0" then break end
        if name == "INST" or name == "PROP" or name == "PRNT" then
            local chunk = decompressChunk(comp, raw)
            if name == "INST" then
                local cid, p = string.unpack("<I4", chunk, 1)
                local cname; cname, p = string.unpack("<s4", chunk, p)
                p += 1
                local count; count, p = string.unpack("<I4", chunk, p)
                local refs = readRefs(chunk, p, count)
                classes[cid] = {name = cname, refs = refs}
                for _, r in ipairs(refs) do
                    insts[r] = {class = cname, name = cname, parent = -1}
                    order[#order + 1] = r
                end
            elseif name == "PROP" then
                local cid, p = string.unpack("<I4", chunk, 1)
                local pname; pname, p = string.unpack("<s4", chunk, p)
                local ptype = string.byte(chunk, p); p += 1
                if ptype == 1 and (pname == "Name" or pname == "Source") then
                    local cls = classes[cid]
                    if cls then
                        for _, r in ipairs(cls.refs) do
                            local str; str, p = string.unpack("<s4", chunk, p)
                            insts[r][pname == "Name" and "name" or "source"] = str
                        end
                    end
                end
            else -- PRNT
                local p = 2
                local count; count, p = string.unpack("<I4", chunk, p)
                local kids; kids, p = readRefs(chunk, p, count)
                local pars = readRefs(chunk, p, count)
                for i = 1, count do
                    local k = insts[kids[i]]
                    if k then k.parent = pars[i] end
                end
            end
        end
    end
    local list = {}
    for _, r in ipairs(order) do
        local it = insts[r]
        if SCRIPT_CLASSES[it.class] and it.source and #it.source > 0 then
            list[#list + 1] = {path = chainPath(insts, it), class = it.class, source = it.source}
        end
    end
    return list
end

local function unesc(str)
    return (str:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&amp;", "&"))
end

local function parseXml(data)
    local list, stack, pos = {}, {}, 1
    local pats = {
        open = '<Item class="([^"]+)"',
        close = "</Item>",
        name = '<string name="Name">(.-)</string>',
        src = '<ProtectedString name="Source">(.-)</ProtectedString>',
    }
    local cache = {}
    while true do
        local best, bs, be, cap
        for k, pat in pairs(pats) do
            local c = cache[k]
            if c == nil or (c ~= false and c.s < pos) then
                local s, e, c1 = data:find(pat, pos)
                c = s and {s = s, e = e, cap = c1} or false
                cache[k] = c
            end
            if c and (not best or c.s < bs) then best, bs, be, cap = k, c.s, c.e, c.cap end
        end
        if not best then break end
        pos = be + 1
        if best == "open" then
            table.insert(stack, {class = cap, name = cap})
        elseif best == "close" then
            local it = table.remove(stack)
            if it and SCRIPT_CLASSES[it.class] and it.source and #it.source > 0 then
                local names = {}
                for _, a in ipairs(stack) do names[#names + 1] = a.name end
                names[#names + 1] = it.name
                list[#list + 1] = {path = table.concat(names, "/"), class = it.class, source = it.source}
            end
        elseif best == "name" then
            local top = stack[#stack]
            if top then top.name = unesc(cap) end
        elseif best == "src" then
            local top = stack[#stack]
            if top then top.source = cap:match("^<!%[CDATA%[(.*)%]%]>$") or unesc(cap) end
        end
    end
    return list
end

local function pathOf(inst, stopAt)
    local names, cur = {}, inst
    while cur and cur ~= stopAt do
        table.insert(names, 1, cur.Name)
        cur = cur.Parent
    end
    return table.concat(names, "/")
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TEMPLATE_KEY = {
    Script = "InsertScriptScript",
    LocalScript = "InsertLocalScriptLocalScript",
    ModuleScript = "InsertModuleScriptModuleScript",
}
local templateCache = {}

local function getServerFunctions()
    local f = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
    return f and f:FindFirstChild("ServerFunctions")
end

-- ambil template isi script (SL_CodeTextBox dkk) dari server Studio Lite
local function getTemplate(className)
    if templateCache[className] then return templateCache[className] end
    local sf, key = getServerFunctions(), TEMPLATE_KEY[className]
    if not (sf and key) then return nil end
    pcall(function() sf:InvokeServer("LoadAssetToPlayerGui", key) end)
    local holder = lp:WaitForChild("PlayerGui"):WaitForChild(key, 3)
    if not holder then return nil end
    local list = {}
    for _, c in ipairs(holder:GetChildren()) do table.insert(list, c:Clone()) end
    pcall(function() sf:InvokeServer("ClearAssetFromPlayerGui", key) end)
    templateCache[className] = list
    return list
end

local function applySource(inst, text)
    if not inst:FindFirstChild("SL_CodeTextBox") then
        local tpl = getTemplate(inst.ClassName)
        if tpl then
            for _, c in ipairs(tpl) do c:Clone().Parent = inst end
        end
    end
    local box = inst:FindFirstChild("SL_CodeTextBox")
    if not box then -- fallback kalau server Studio Lite tidak ditemukan
        box = Instance.new("TextBox")
        box.Name = "SL_CodeTextBox"
        box.MultiLine = true
        box.ClearTextOnFocus = false
        box.Visible = false
        box.Parent = inst
    end
    box.Text = text
    if inst.ClassName == "ModuleScript" then
        local ro = inst:FindFirstChild("SL_1ReadOnly")
        if ro then
            pcall(function() ro.ContentText = text end)
            pcall(function() ro.Text = text end)
        end
    end
end

-- bersihkan markup RichText (<font color=...>, <b>, &lt; dst) jadi kode Lua polos
local function cleanSource(src)
    if src:find("<font color=", 1, true) or src:find("<b><font", 1, true) then
        src = src:gsub("</?font[^>]*>", ""):gsub("</?[biu]>", "")
        src = src:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&amp;", "&")
    end
    return src
end

local function attachSources(objs, folder, parsed)
    local queues = {}
    for _, sc in ipairs(parsed) do
        sc.source = cleanSource(sc.source)
        local key = sc.path .. "|" .. sc.class
        queues[key] = queues[key] or {}
        table.insert(queues[key], sc)
    end
    local env = (getgenv and getgenv()) or _G
    env.ImportedSources = env.ImportedSources or {}
    local n = 0
    local function handle(inst)
        if SCRIPT_CLASSES[inst.ClassName] then
            local q = queues[pathOf(inst, folder) .. "|" .. inst.ClassName]
            local sc = q and table.remove(q, 1)
            if sc then
                n += 1
                pcall(function()
                    if setscriptable then setscriptable(inst, "Source", true) end
                    inst.Source = sc.source
                end)
                -- isi script dimasukkan ke editor Studio Lite (sistem script awal)
                local text = #sc.source > 150000 and sc.source:sub(1, 150000) or sc.source
                applySource(inst, text)
                env.ImportedSources[folder.Name .. "/" .. sc.path] = sc.source
                registerScript(sc.path, sc.class, sc.source)
            end
        end
    end
    for _, obj in ipairs(objs) do
        handle(obj)
        for _, d in ipairs(obj:GetDescendants()) do handle(d) end
    end
    return n
end

local function importFile(info)
    if not (readfile and getcustomasset) then
        return false, "Executor tidak support readfile/getcustomasset"
    end
    local ok, objs = pcall(function()
        return game:GetObjects(getcustomasset(info.path))
    end)
    if not ok or type(objs) ~= "table" or #objs == 0 then
        return false, "Gagal load file (format/executor tidak didukung)"
    end
    local base = info.name:gsub("%.[^%.]+$", "")
    local name, n = base, 1
    while workspace:FindFirstChild(name) do n += 1; name = base .. "_" .. n end
    local folder = new("Folder", {Name = name}, workspace)
    local count = 0
    for _, obj in ipairs(objs) do
        local okp = pcall(function() obj.Parent = folder end)
        if okp then count += 1 end
    end

    -- baca isi script langsung dari file
    local scriptCount, scriptErr = 0, nil
    local okR, data = pcall(readfile, info.path)
    if okR and type(data) == "string" then
        local okP, parsed = pcall(function()
            if data:sub(1, 8) == "<roblox!" then return parseBinary(data) end
            if data:find("<roblox", 1, true) then return parseXml(data) end
        end)
        if okP and type(parsed) == "table" then
            scriptCount = attachSources(objs, folder, parsed)
        elseif not okP then
            scriptErr = tostring(parsed)
        end
    end
    local msg = count .. " object, " .. scriptCount .. " script terbaca -> Workspace." .. name
    if scriptErr then msg = msg .. " (parse error: " .. scriptErr:sub(1, 60) .. ")" end
    return true, msg
end

local function addRow(info)
    local col = (info.kind == "PLACE") and C.accent2 or C.ok
    local f = new("Frame", {Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.card}, scroll)
    corner(f, 10); stroke(f, Color3.fromRGB(50, 40, 70))
    local n = label(f, info.name, 12, UDim2.fromOffset(14, 8), UDim2.new(1, -110, 0, 18))
    n.TextTruncate = Enum.TextTruncate.AtEnd
    local p = label(f, info.path, 10, UDim2.fromOffset(14, 26), UDim2.new(1, -110, 0, 14), C.muted, Enum.Font.Gotham)
    p.TextTruncate = Enum.TextTruncate.AtEnd
    local tag = new("TextLabel", {
        Size = UDim2.fromOffset(45, 14), Position = UDim2.fromOffset(14, 40),
        BackgroundColor3 = col, Text = info.kind, Font = Enum.Font.GothamBold,
        TextSize = 9, TextColor3 = Color3.fromRGB(20, 15, 30),
    }, f)
    corner(tag, 4)
    local btn = new("TextButton", {
        Size = UDim2.fromOffset(70, 28), Position = UDim2.new(1, -82, 0.5, -14),
        BackgroundColor3 = C.accent, Text = "IMPORT", Font = Enum.Font.GothamBold,
        TextSize = 11, TextColor3 = Color3.new(1, 1, 1),
    }, f)
    corner(btn, 8)
    btn.MouseButton1Click:Connect(function()
        if btn.Text ~= "IMPORT" then return end
        btn.Text = "LOADING"
        task.spawn(function()
            local ok, msg = importFile(info)
            btn.Text = ok and "DONE" or "FAIL"
            btn.BackgroundColor3 = ok and C.ok or C.err
            notify(ok and "Success" or "Failed", msg, not ok)
            task.wait(2)
            btn.Text = "IMPORT"
            btn.BackgroundColor3 = C.accent
        end)
    end)
    table.insert(rows, {frame = f, kind = info.kind})
end

local scanning = false
local function refresh()
    if scanning then return end
    scanning = true
    rescan.Text = "Scanning..."
    for _, r in ipairs(rows) do r.frame:Destroy() end
    table.clear(rows)
    if makefolder and isfolder and not isfolder(ASSET_FOLDER) then pcall(makefolder, ASSET_FOLDER) end
    local files = scanFiles()
    for _, info in ipairs(files) do addRow(info) end
    lblTotal.Text = tostring(#files)
    applyFilter()
    rescan.Text = "Rescan"
    if #files > 0 then
        notify("Scan Complete", "Ditemukan " .. #files .. " file asset.", false)
    else
        notify("Empty", "Tidak ada file asset di workspace/" .. ASSET_FOLDER, true)
    end
    scanning = false
end

rescan.MouseButton1Click:Connect(refresh)

showView("Overview")
task.defer(refresh)
