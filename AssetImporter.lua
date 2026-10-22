--[[
    ASSET IMPORTER  |  Premium Edition (Obsidian Gold)
    - Scan file .rbxm / .rbxmx / .rbxl / .rbxlx dari folder workspace executor
    - Import ke Folder baru di Workspace + isi script terbaca (editor Studio Lite)
    - .rbxl/.rbxlx: kalau GetObjects kosong, struktur + script dibangun ulang dari isi file
    - Tombol bulat kecil untuk buka / tutup panel (bisa digeser)
    Taruh file asset di: workspace/ImporterAssets (dibuat otomatis)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local ASSET_FOLDER = "ImporterAssets"
local SCAN_FOLDERS = { ASSET_FOLDER, "" } -- "" = root workspace executor

local ICON = {
    PACKAGE = "rbxassetid://128864012857079",
    FOLDER = "rbxassetid://88761476236687",
    SETTINGS = "rbxassetid://11956055886",
    DASHBOARD = "rbxassetid://90838150633173",
    FILE = "rbxassetid://17109896197",
    GAMEPAD = "rbxassetid://115836418226834",
    REFRESH = "rbxassetid://13492317101",
    CHECK = "rbxassetid://18349889388",
    ALERT = "rbxassetid://7634887649",
}

-- Obsidian + Gold
local C = {
    bg = Color3.fromRGB(8, 8, 10),
    panel = Color3.fromRGB(14, 13, 16),
    card = Color3.fromRGB(19, 18, 22),
    card2 = Color3.fromRGB(30, 28, 33),
    border = Color3.fromRGB(78, 64, 36),
    accent = Color3.fromRGB(205, 165, 82),
    accent2 = Color3.fromRGB(248, 222, 150),
    accentDark = Color3.fromRGB(150, 110, 45),
    text = Color3.fromRGB(248, 244, 234),
    muted = Color3.fromRGB(152, 146, 132),
    ink = Color3.fromRGB(26, 19, 8),
    ok = Color3.fromRGB(96, 214, 144),
    err = Color3.fromRGB(240, 84, 100),
}
local WHITE = Color3.new(1, 1, 1)

-- ============ Helper UI ============
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(p, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p) end
local function stroke(p, col, tr, th)
    return new("UIStroke", {
        Color = col or C.border, Transparency = tr or 0.5, Thickness = th or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, p)
end
local function gradient(p, c0, c1, rot)
    return new("UIGradient", {Color = ColorSequence.new(c0, c1), Rotation = rot or 0}, p)
end
local function label(p, text, size, pos, sz, col, font)
    return new("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextSize = size or 12,
        Font = font or Enum.Font.GothamBold, TextColor3 = col or C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = pos or UDim2.new(), Size = sz or UDim2.new(1, 0, 0, 20),
    }, p)
end
local function tween(o, t, props)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- Tombol emas premium. Teks dipisah (label) supaya tidak ikut ter-gradient.
-- return: button, textLabel
local function primaryButton(parent, text, pos, size)
    local b = new("TextButton", {
        Position = pos, Size = size, BackgroundColor3 = WHITE, Text = "",
        AutoButtonColor = false, ClipsDescendants = true,
    }, parent)
    corner(b, 10)
    gradient(b, C.accent2, C.accentDark, 90)
    local st = stroke(b, C.accent2, 0.35, 1)
    -- kilau tipis di atas tombol
    local shine = new("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = WHITE, BackgroundTransparency = 0.85,
        BorderSizePixel = 0, ZIndex = 2,
    }, b)
    corner(shine, 10)
    local lb = new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text,
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.ink, ZIndex = 3,
    }, b)
    b.MouseEnter:Connect(function() tween(st, 0.15, {Transparency = 0}) tween(shine, 0.15, {BackgroundTransparency = 0.7}) end)
    b.MouseLeave:Connect(function() tween(st, 0.15, {Transparency = 0.35}) tween(shine, 0.15, {BackgroundTransparency = 0.85}) end)
    return b, lb
end

local function makeDraggable(handle, target, clickCb)
    local dragging, moved, startPos, startUI
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            startPos, startUI = i.Position, target.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startPos
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.new(startUI.X.Scale, startUI.X.Offset + d.X, startUI.Y.Scale, startUI.Y.Offset + d.Y)
            end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved and clickCb then clickCb() end
        end
    end)
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
    Name = "AssetImporterUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, getParent())

-- ============ Notifikasi ============
local function notify(title, msg, isErr)
    local col = isErr and C.err or C.ok
    local f = new("Frame", {
        Size = UDim2.fromOffset(290, 62), AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, 330, 1, -20), BackgroundColor3 = C.card, BorderSizePixel = 0, ZIndex = 50,
    }, gui)
    corner(f, 12); stroke(f, col, 0.35, 1.2)
    gradient(f, C.card2, C.card, 135)
    local bar = new("Frame", {Size = UDim2.new(0, 3, 1, -20), Position = UDim2.fromOffset(8, 10), BackgroundColor3 = col, BorderSizePixel = 0}, f)
    corner(bar, 2)
    new("ImageLabel", {
        Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(20, 22), BackgroundTransparency = 1,
        Image = isErr and ICON.ALERT or ICON.CHECK, ImageColor3 = col,
    }, f)
    label(f, title, 12, UDim2.fromOffset(48, 9), UDim2.new(1, -58, 0, 18))
    local m = label(f, msg, 10, UDim2.fromOffset(48, 28), UDim2.new(1, -58, 0, 28), C.muted, Enum.Font.Gotham)
    m.TextWrapped = true; m.TextYAlignment = Enum.TextYAlignment.Top
    tween(f, 0.4, {Position = UDim2.new(1, -16, 1, -20)})
    task.delay(3.6, function()
        tween(f, 0.3, {Position = UDim2.new(1, 330, 1, -20)})
        task.wait(0.35)
        f:Destroy()
    end)
end

-- ============ Window ============
local main = new("Frame", {
    Size = UDim2.fromOffset(560, 380), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = WHITE,
    BorderSizePixel = 0, ClipsDescendants = true,
}, gui)
corner(main, 16)
gradient(main, Color3.fromRGB(20, 18, 24), Color3.fromRGB(7, 7, 9), 135)
local mainStroke = stroke(main, WHITE, 0.15, 1.5)
gradient(mainStroke, C.accent2, Color3.fromRGB(90, 66, 26), 90)
local scale = new("UIScale", {}, main)

local baseScale = 1
local function fit()
    local cam = workspace.CurrentCamera
    if cam then
        local v = cam.ViewportSize
        baseScale = math.min(v.X / 600, v.Y / 420, 1)
        if main.Visible then scale.Scale = baseScale end
    end
end
fit()
scale.Scale = baseScale
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end

local isOpen = true
local function openMain()
    isOpen = true
    main.Visible = true
    scale.Scale = baseScale * 0.9
    tween(scale, 0.25, {Scale = baseScale})
end
local function closeMain()
    isOpen = false
    tween(scale, 0.18, {Scale = baseScale * 0.9})
    task.delay(0.19, function() if not isOpen then main.Visible = false end end)
end

-- ---- Sidebar ----
local side = new("Frame", {Size = UDim2.new(0, 160, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, main)
gradient(side, Color3.fromRGB(24, 21, 28), Color3.fromRGB(10, 9, 12), 90)
new("Frame", {
    Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = C.border, BackgroundTransparency = 0.3, BorderSizePixel = 0,
}, side)

local logo = new("Frame", {Size = UDim2.fromOffset(38, 38), Position = UDim2.fromOffset(14, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0}, side)
corner(logo, 11)
gradient(logo, C.accent2, C.accentDark, 45)
stroke(logo, C.accent2, 0.5, 1)
new("ImageLabel", {
    Size = UDim2.fromOffset(22, 22), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Image = ICON.PACKAGE, ImageColor3 = C.ink,
}, logo)
label(side, "ASSET IMPORTER", 12, UDim2.fromOffset(62, 17), UDim2.new(1, -66, 0, 16))
label(side, "PREMIUM EDITION", 8, UDim2.fromOffset(62, 35), UDim2.new(1, -66, 0, 12), C.accent2)

-- ---- Header ----
local header = new("Frame", {Size = UDim2.new(1, -160, 0, 56), Position = UDim2.fromOffset(160, 0), BackgroundTransparency = 1}, main)
local titleLbl = label(header, "", 17, UDim2.fromOffset(20, 10), UDim2.new(1, -70, 0, 22))
local subLbl = label(header, "", 10, UDim2.fromOffset(20, 33), UDim2.new(1, -70, 0, 14), C.muted, Enum.Font.Gotham)
local hline = new("Frame", {
    Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 1, -1),
    BackgroundColor3 = WHITE, BackgroundTransparency = 0.3, BorderSizePixel = 0,
}, header)
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent), ColorSequenceKeypoint.new(1, C.bg),
    }),
}, hline)

local closeBtn = new("TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -42, 0, 14), BackgroundColor3 = C.card2,
    Text = "X", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text, AutoButtonColor = false, ZIndex = 5,
}, header)
corner(closeBtn, 14); stroke(closeBtn, C.border, 0.3)
closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.15, {BackgroundColor3 = C.err}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.15, {BackgroundColor3 = C.card2}) end)
closeBtn.MouseButton1Click:Connect(closeMain)

makeDraggable(header, main)
makeDraggable(side, main)

local content = new("Frame", {
    Size = UDim2.new(1, -160, 1, -56), Position = UDim2.fromOffset(160, 56),
    BackgroundTransparency = 1, ClipsDescendants = true,
}, main)

-- ============ Views & Nav ============
local views, navs = {}, {}
local viewInfo = {
    Overview = {"Overview", "Ringkasan akun dan statistik asset"},
    Assets = {"Assets", "Pilih file lalu tekan IMPORT"},
    Scripts = {"Script Viewer", "Isi script dari file yang di-import"},
    Settings = {"Settings", "Tentang dan pengaturan"},
}

local function makeView(name)
    local v = new("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false}, content)
    new("UIPadding", {PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14)}, v)
    views[name] = v
    return v
end

local function showView(name)
    for n, v in pairs(views) do v.Visible = (n == name) end
    for n, nv in pairs(navs) do
        local on = (n == name)
        tween(nv.btn, 0.2, {BackgroundTransparency = on and 0.05 or 1})
        tween(nv.bar, 0.2, {Size = UDim2.fromOffset(3, on and 18 or 0)})
        tween(nv.icon, 0.2, {ImageColor3 = on and C.accent2 or C.muted})
        tween(nv.label, 0.2, {TextColor3 = on and C.text or C.muted})
    end
    titleLbl.Text = viewInfo[name][1]
    subLbl.Text = viewInfo[name][2]
end

local function navButton(name, icon, order)
    local b = new("TextButton", {
        Size = UDim2.new(1, -24, 0, 38), Position = UDim2.fromOffset(12, 74 + (order - 1) * 44),
        BackgroundColor3 = C.card2, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
    }, side)
    corner(b, 10)
    local bar = new("Frame", {
        Size = UDim2.fromOffset(3, 0), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = C.accent2, BorderSizePixel = 0,
    }, b)
    corner(bar, 2)
    local ic = new("ImageLabel", {
        Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 14, 0.5, -8),
        BackgroundTransparency = 1, Image = icon, ImageColor3 = C.muted,
    }, b)
    local lb = label(b, name, 12, UDim2.fromOffset(40, 0), UDim2.new(1, -44, 1, 0), C.muted, Enum.Font.GothamMedium)
    navs[name] = {btn = b, bar = bar, icon = ic, label = lb}
    b.MouseButton1Click:Connect(function() showView(name) end)
end
navButton("Overview", ICON.DASHBOARD, 1)
navButton("Assets", ICON.FOLDER, 2)
navButton("Scripts", ICON.FILE, 3)
navButton("Settings", ICON.SETTINGS, 4)

-- footer sidebar
local execName = "Executor"
pcall(function()
    if identifyexecutor then execName = tostring((identifyexecutor())) end
end)
local foot = new("Frame", {Size = UDim2.new(1, -24, 0, 36), Position = UDim2.new(0, 12, 1, -48), BackgroundColor3 = C.card, BorderSizePixel = 0}, side)
corner(foot, 10); stroke(foot, C.border, 0.4)
local dot = new("Frame", {Size = UDim2.fromOffset(8, 8), Position = UDim2.new(0, 12, 0.5, -4), BackgroundColor3 = C.ok, BorderSizePixel = 0}, foot)
corner(dot, 4)
local fl = label(foot, "Ready  |  " .. execName, 10, UDim2.fromOffset(28, 0), UDim2.new(1, -34, 1, 0), C.muted, Enum.Font.GothamMedium)
fl.TextTruncate = Enum.TextTruncate.AtEnd

-- ---- Overview ----
local ov = makeView("Overview")
local prof = new("Frame", {Size = UDim2.new(1, 0, 0, 88), BackgroundColor3 = WHITE, BorderSizePixel = 0}, ov)
corner(prof, 14)
gradient(prof, Color3.fromRGB(44, 36, 22), Color3.fromRGB(18, 16, 20), 45)
stroke(prof, C.accent, 0.4, 1.2)
local avatarWrap = new("Frame", {Size = UDim2.fromOffset(58, 58), Position = UDim2.fromOffset(16, 15), BackgroundColor3 = C.card, BorderSizePixel = 0}, prof)
corner(avatarWrap, 29); stroke(avatarWrap, C.accent2, 0.1, 2)
local avatar = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"}, avatarWrap)
corner(avatar, 29)
task.spawn(function()
    local ok, img = pcall(function()
        return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)
    if ok and img then avatar.Image = img end
end)
local nm = label(prof, lp.DisplayName, 15, UDim2.fromOffset(86, 16), UDim2.new(1, -100, 0, 20))
nm.TextTruncate = Enum.TextTruncate.AtEnd
local un = label(prof, "@" .. lp.Name .. "   |   ID " .. lp.UserId, 10, UDim2.fromOffset(86, 38), UDim2.new(1, -100, 0, 14), C.muted, Enum.Font.Gotham)
un.TextTruncate = Enum.TextTruncate.AtEnd
local pill = new("Frame", {Size = UDim2.fromOffset(74, 16), Position = UDim2.fromOffset(86, 58), BackgroundColor3 = WHITE, BorderSizePixel = 0}, prof)
corner(pill, 8)
gradient(pill, C.accent2, C.accentDark, 0)
new("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "PREMIUM", Font = Enum.Font.GothamBold,
    TextSize = 9, TextColor3 = C.ink,
}, pill)

local function statCard(idx, title)
    local f = new("Frame", {
        Size = UDim2.new(1 / 3, -8, 0, 66), Position = UDim2.new((idx - 1) / 3, (idx - 1) * 4, 0, 100),
        BackgroundColor3 = WHITE, BorderSizePixel = 0,
    }, ov)
    corner(f, 12); stroke(f, C.border, 0.35)
    gradient(f, C.card2, C.card, 135)
    label(f, title, 9, UDim2.fromOffset(12, 10), UDim2.new(1, -24, 0, 12), C.muted)
    return label(f, "0", 22, UDim2.fromOffset(12, 28), UDim2.new(1, -24, 0, 28), C.accent2)
end
local statAssets = statCard(1, "TOTAL ASSETS")
local statImported = statCard(2, "DI-IMPORT")
local statScripts = statCard(3, "SCRIPT TERBACA")

local tip = new("Frame", {Size = UDim2.new(1, 0, 0, 58), Position = UDim2.fromOffset(0, 178), BackgroundColor3 = C.card, BorderSizePixel = 0}, ov)
corner(tip, 12); stroke(tip, C.border, 0.4)
new("ImageLabel", {Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(14, 20), BackgroundTransparency = 1, Image = ICON.FOLDER, ImageColor3 = C.accent2}, tip)
local tl = label(tip, "Letakkan file .rbxm / .rbxl di folder workspace/" .. ASSET_FOLDER .. " lalu buka tab Assets.", 10, UDim2.fromOffset(44, 8), UDim2.new(1, -56, 0, 42), C.muted, Enum.Font.Gotham)
tl.TextWrapped = true

local importedTotal, scriptTotal = 0, 0

-- ---- Assets ----
local av = makeView("Assets")
local rows, filterKind, searchText = {}, "ALL", ""
local function applyFilter()
    for _, r in ipairs(rows) do
        local okKind = (filterKind == "ALL") or (r.kind == filterKind)
        local okSearch = (searchText == "") or (r.name:lower():find(searchText, 1, true) ~= nil)
        r.frame.Visible = okKind and okSearch
    end
end

local seg = new("Frame", {Size = UDim2.fromOffset(190, 30), BackgroundColor3 = C.card, BorderSizePixel = 0}, av)
corner(seg, 15); stroke(seg, C.border, 0.4)
local segBtns = {}
for i, nmk in ipairs({"ALL", "MODEL", "PLACE"}) do
    local b = new("TextButton", {
        Size = UDim2.fromOffset(60, 26), Position = UDim2.fromOffset(2 + (i - 1) * 62, 2),
        BackgroundColor3 = C.accent, BackgroundTransparency = (i == 1) and 0 or 1,
        Text = nmk, Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = (i == 1) and C.ink or C.text, AutoButtonColor = false,
    }, seg)
    corner(b, 13)
    segBtns[nmk] = b
    b.MouseButton1Click:Connect(function()
        filterKind = nmk
        for n2, fb in pairs(segBtns) do
            local on = (n2 == nmk)
            tween(fb, 0.2, {BackgroundTransparency = on and 0 or 1, TextColor3 = on and C.ink or C.text})
        end
        applyFilter()
    end)
end

local rescan, rescanLbl = primaryButton(av, "RESCAN", UDim2.new(1, -96, 0, 0), UDim2.fromOffset(96, 30))
local searchBox = new("TextBox", {
    Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 38), BackgroundColor3 = C.card,
    Text = "", PlaceholderText = "Cari asset...", PlaceholderColor3 = C.muted, TextColor3 = C.text,
    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
}, av)
corner(searchBox, 10); stroke(searchBox, C.border, 0.4)
new("UIPadding", {PaddingLeft = UDim.new(0, 12)}, searchBox)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchText = searchBox.Text:lower()
    applyFilter()
end)

local listFrame = new("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -76), Position = UDim2.fromOffset(0, 76), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, av)
new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)

-- ---- Scripts ----
local scv = makeView("Scripts")
local scList = new("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 92), BackgroundColor3 = C.card, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, scv)
corner(scList, 10); stroke(scList, C.border, 0.4)
new("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, scList)
new("UIListLayout", {Padding = UDim.new(0, 4)}, scList)

local codeBox = new("TextBox", {
    Size = UDim2.new(1, 0, 1, -138), Position = UDim2.fromOffset(0, 100), BackgroundColor3 = Color3.fromRGB(11, 10, 13),
    Text = "Import file dulu, lalu pilih script di atas.", TextColor3 = C.text, Font = Enum.Font.Code, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false, TextEditable = false, MultiLine = true, TextWrapped = false, ClipsDescendants = true,
}, scv)
corner(codeBox, 10); stroke(codeBox, C.border, 0.4)
new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6)}, codeBox)
local copyBtn = primaryButton(scv, "COPY", UDim2.new(0, 0, 1, -30), UDim2.fromOffset(100, 30))

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
    scriptTotal += 1
    statScripts.Text = tostring(scriptTotal)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.card2, Text = "  [" .. class .. "]  " .. path,
        Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false,
    }, scList)
    corner(b, 8)
    b.MouseEnter:Connect(function() tween(b, 0.12, {BackgroundColor3 = C.border}) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, {BackgroundColor3 = C.card2}) end)
    b.MouseButton1Click:Connect(function() showSource(src) end)
end

-- ---- Settings ----
local sv = makeView("Settings")
local about = new("Frame", {Size = UDim2.new(1, 0, 0, 96), BackgroundColor3 = WHITE, BorderSizePixel = 0}, sv)
corner(about, 14)
gradient(about, Color3.fromRGB(40, 33, 21), Color3.fromRGB(17, 15, 19), 45)
stroke(about, C.accent, 0.45, 1.2)
label(about, "Asset Importer  -  Premium Edition", 14, UDim2.fromOffset(16, 14), UDim2.new(1, -32, 0, 20))
local ab = label(about, "Scan dan import file .rbxm / .rbxl dari folder workspace executor ke Workspace game (lokal / client).", 10, UDim2.fromOffset(16, 38), UDim2.new(1, -32, 0, 44), C.muted, Enum.Font.Gotham)
ab.TextWrapped = true; ab.TextYAlignment = Enum.TextYAlignment.Top
local unload = primaryButton(sv, "UNLOAD GUI", UDim2.fromOffset(0, 108), UDim2.fromOffset(120, 32))
unload.MouseButton1Click:Connect(function() gui:Destroy() end)

-- ============ Tombol kecil buka / tutup panel ============
local toggle = new("ImageButton", {
    Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 14, 0, 120), BackgroundColor3 = WHITE,
    AutoButtonColor = false, Image = "", ZIndex = 20,
}, gui)
corner(toggle, 23)
gradient(toggle, C.accent2, C.accentDark, 45)
stroke(toggle, C.accent2, 0.3, 1.5)
new("ImageLabel", {
    Size = UDim2.fromOffset(24, 24), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Image = ICON.PACKAGE, ImageColor3 = C.ink, ZIndex = 21,
}, toggle)
makeDraggable(toggle, toggle, function()
    if isOpen then closeMain() else openMain() end
end)
UIS.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightShift then
        if isOpen then closeMain() else openMain() end
    end
end)

-- ============ Logic ============
-- ---------- Parser file rbxm/rbxmx/rbxl (baca struktur + isi script) ----------
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
    local names, cur, guard = {}, inst, 0
    while cur and guard < 200 do
        table.insert(names, 1, cur.name)
        cur = insts[cur.parent]
        guard += 1
    end
    return table.concat(names, "/")
end

-- return: list script, tree {insts, order}
local function parseBinary(data)
    if data:sub(1, 8) ~= "<roblox!" then return nil end
    local pos = 33
    local classes, insts, order = {}, {}, {}
    local chunks = 0
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
        chunks += 1
        if chunks % 25 == 0 then task.wait() end
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
    return list, {insts = insts, order = order}
end

local function unesc(str)
    return (str:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&amp;", "&"))
end

-- return: list script, tree {insts, order}  (dibangun dari XML)
local function parseXml(data)
    local list, stack, pos = {}, {}, 1
    local insts, order = {}, {}
    local idc = 0
    local pats = {
        open = '<Item class="([^"]+)"',
        close = "</Item>",
        name = '<string name="Name">(.-)</string>',
        src = '<ProtectedString name="Source">(.-)</ProtectedString>',
    }
    local cache = {}
    local steps = 0
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
        steps += 1
        if steps % 400 == 0 then task.wait() end
        if best == "open" then
            idc += 1
            local parent = stack[#stack]
            local node = {id = idc, class = cap, name = cap, parent = parent and parent.id or -1}
            insts[idc] = node
            order[#order + 1] = idc
            table.insert(stack, node)
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
    return list, {insts = insts, order = order}
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

local function pushSource(inst, folderName, path, class, source)
    local env = (getgenv and getgenv()) or _G
    env.ImportedSources = env.ImportedSources or {}
    pcall(function()
        if setscriptable then setscriptable(inst, "Source", true) end
        inst.Source = source
    end)
    -- isi script dimasukkan ke editor Studio Lite (sistem script awal)
    local text = #source > 150000 and source:sub(1, 150000) or source
    applySource(inst, text)
    env.ImportedSources[folderName .. "/" .. path] = source
    registerScript(path, class, source)
end

local function attachSources(objs, folder, parsed)
    local queues = {}
    for _, sc in ipairs(parsed) do
        sc.source = cleanSource(sc.source)
        local key = sc.path .. "|" .. sc.class
        queues[key] = queues[key] or {}
        table.insert(queues[key], sc)
    end
    local n = 0
    local function handle(inst)
        if SCRIPT_CLASSES[inst.ClassName] then
            local q = queues[pathOf(inst, folder) .. "|" .. inst.ClassName]
            local sc = q and table.remove(q, 1)
            if sc then
                n += 1
                pushSource(inst, folder.Name, sc.path, sc.class, sc.source)
            end
        end
    end
    local visited = 0
    for _, obj in ipairs(objs) do
        handle(obj)
        for _, d in ipairs(obj:GetDescendants()) do
            handle(d)
            visited += 1
            if visited % 150 == 0 then task.wait() end
        end
    end
    return n
end

-- Fallback: bangun ulang hierarki dari isi file (dipakai bila GetObjects kosong, mis. .rbxl)
-- Script dibuat sebagai script asli, objek lain jadi Folder bernama sama.
local MAX_NODES = 25000
local function buildFromTree(folder, tree)
    local insts, order = tree.insts, tree.order
    local made, objCount, scriptCount = {}, 0, 0
    local limit = math.min(#order, MAX_NODES)
    for idx = 1, limit do
        local r = order[idx]
        local it = insts[r]
        local inst
        if SCRIPT_CLASSES[it.class] then
            local ok, o = pcall(Instance.new, it.class)
            if ok then
                inst = o
                pcall(function() inst.Disabled = true end)
            end
        end
        if not inst then inst = Instance.new("Folder") end
        pcall(function() inst.Name = it.name end)
        made[r] = inst
        if idx % 300 == 0 then task.wait() end
    end
    for idx = 1, limit do
        local r = order[idx]
        local it = insts[r]
        local inst = made[r]
        local par = made[it.parent]
        inst.Parent = par or folder
        objCount += 1
        if idx % 300 == 0 then task.wait() end
    end
    for idx = 1, limit do
        local r = order[idx]
        local it = insts[r]
        local inst = made[r]
        if SCRIPT_CLASSES[it.class] and it.source and #it.source > 0 and inst.ClassName == it.class then
            scriptCount += 1
            pushSource(inst, folder.Name, chainPath(insts, it), it.class, cleanSource(it.source))
            if scriptCount % 20 == 0 then task.wait() end
        end
    end
    return objCount, scriptCount, #order > limit
end

local function importFile(info)
    if not (readfile and getcustomasset) then
        return false, "Executor tidak support readfile/getcustomasset"
    end

    -- baca & parse isi file dulu (dipakai untuk isi script + fallback)
    local parsed, tree, scriptErr
    local okR, data = pcall(readfile, info.path)
    if okR and type(data) == "string" then
        local okP, a, b = pcall(function()
            if data:sub(1, 8) == "<roblox!" then return parseBinary(data) end
            if data:find("<roblox", 1, true) then return parseXml(data) end
        end)
        if okP then parsed, tree = a, b else scriptErr = tostring(a) end
    end

    local base = info.name:gsub("%.[^%.]+$", "")
    local name, n = base, 1
    while workspace:FindFirstChild(name) do n += 1; name = base .. "_" .. n end
    local folder = new("Folder", {Name = name}, workspace)

    -- cara 1: GetObjects
    local count = 0
    local ok, objs = pcall(function()
        return game:GetObjects(getcustomasset(info.path))
    end)
    local gotObjects = ok and type(objs) == "table" and #objs > 0
    if gotObjects then
        local function adopt(obj)
            local okp = pcall(function() obj.Parent = folder end)
            if okp and obj.Parent == folder then count += 1 return end
            -- service / DataModel (hasil .rbxl): pindahkan isinya ke subfolder
            local sub = Instance.new("Folder")
            sub.Name = obj.Name
            local moved = 0
            for _, ch in ipairs(obj:GetChildren()) do
                if pcall(function() ch.Parent = sub end) and ch.Parent == sub then moved += 1 end
            end
            if moved > 0 then sub.Parent = folder; count += moved else sub:Destroy() end
        end
        for _, obj in ipairs(objs) do
            if obj:IsA("DataModel") then
                for _, svc in ipairs(obj:GetChildren()) do adopt(svc) end
            else
                adopt(obj)
            end
        end
    end

    local scriptCount = 0
    local via = "GetObjects"
    if count > 0 then
        if parsed then
            local okA, res = pcall(attachSources, {folder}, folder, parsed)
            if okA then scriptCount = res else scriptErr = tostring(res) end
        end
    elseif tree and #tree.order > 0 then
        -- cara 2: bangun ulang dari isi file
        via = "Rebuild"
        local okB, oc, sc, trunc = pcall(buildFromTree, folder, tree)
        if okB then
            count, scriptCount = oc, sc
            if trunc then via = "Rebuild (dipotong " .. MAX_NODES .. " node)" end
        else
            scriptErr = tostring(oc)
        end
    end

    if count == 0 then
        folder:Destroy()
        return false, "File kosong / format tidak didukung executor"
    end

    local msg = count .. " object, " .. scriptCount .. " script [" .. via .. "] -> Workspace." .. name
    if scriptErr then msg = msg .. " (error: " .. scriptErr:sub(1, 60) .. ")" end
    return true, msg
end

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

local function addRow(info)
    local isPlace = info.kind == "PLACE"
    local col = isPlace and C.accent2 or C.ok
    local f = new("Frame", {Size = UDim2.new(1, -4, 0, 62), BackgroundColor3 = WHITE, BorderSizePixel = 0}, listFrame)
    corner(f, 12); stroke(f, C.border, 0.4)
    gradient(f, C.card2, C.card, 135)
    local tile = new("Frame", {Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(12, 11), BackgroundColor3 = col, BackgroundTransparency = 0.82, BorderSizePixel = 0}, f)
    corner(tile, 11)
    new("ImageLabel", {
        Size = UDim2.fromOffset(20, 20), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, Image = isPlace and ICON.GAMEPAD or ICON.FILE, ImageColor3 = col,
    }, tile)
    local n = label(f, info.name, 12, UDim2.fromOffset(62, 9), UDim2.new(1, -156, 0, 18))
    n.TextTruncate = Enum.TextTruncate.AtEnd
    local p = label(f, info.path, 9, UDim2.fromOffset(62, 27), UDim2.new(1, -156, 0, 14), C.muted, Enum.Font.Gotham)
    p.TextTruncate = Enum.TextTruncate.AtEnd
    local tag = new("TextLabel", {
        Size = UDim2.fromOffset(46, 13), Position = UDim2.fromOffset(62, 44), BackgroundColor3 = col,
        Text = info.kind, Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = Color3.fromRGB(20, 15, 10),
    }, f)
    corner(tag, 6)
    local btn, btnLbl = primaryButton(f, "IMPORT", UDim2.new(1, -88, 0.5, -15), UDim2.fromOffset(76, 30))
    btn.MouseButton1Click:Connect(function()
        if btnLbl.Text ~= "IMPORT" then return end
        btnLbl.Text = "LOADING"
        task.spawn(function()
            local ok, msg = importFile(info)
            btnLbl.Text = ok and "DONE" or "FAIL"
            if ok then
                importedTotal += 1
                statImported.Text = tostring(importedTotal)
            end
            notify(ok and "Success" or "Failed", msg, not ok)
            task.wait(2)
            if btn.Parent then btnLbl.Text = "IMPORT" end
        end)
    end)
    table.insert(rows, {frame = f, kind = info.kind, name = info.name})
end

local scanning = false
local function refresh()
    if scanning then return end
    scanning = true
    rescanLbl.Text = "SCANNING..."
    for _, r in ipairs(rows) do r.frame:Destroy() end
    table.clear(rows)
    if makefolder and isfolder and not isfolder(ASSET_FOLDER) then pcall(makefolder, ASSET_FOLDER) end
    local files = scanFiles()
    for _, info in ipairs(files) do addRow(info) end
    statAssets.Text = tostring(#files)
    applyFilter()
    rescanLbl.Text = "RESCAN"
    if #files > 0 then
        notify("Scan Complete", "Ditemukan " .. #files .. " file asset.", false)
    else
        notify("Empty", "Tidak ada file asset di workspace/" .. ASSET_FOLDER, true)
    end
    scanning = false
end
rescan.MouseButton1Click:Connect(refresh)

showView("Overview")
openMain()
task.defer(refresh)
