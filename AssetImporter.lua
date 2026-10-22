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
navButton("Settings", 3)

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
    return true, count .. " object diimport ke Workspace." .. name
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
