-- BALEREOT COMMUNITY Toolbox (kode orisinal)
-- Fitur: tab Model/Texture/Decal/Audio/Favorites, thumbnail asset, preview, insert ke Studio Lite, log.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local C = {
    bg = Color3.fromRGB(8, 14, 26), panel = Color3.fromRGB(15, 26, 44),
    header = Color3.fromRGB(10, 20, 38), input = Color3.fromRGB(18, 32, 54),
    stroke = Color3.fromRGB(30, 80, 130), accent = Color3.fromRGB(0, 170, 255),
    accent2 = Color3.fromRGB(255, 196, 60), cyan = Color3.fromRGB(90, 225, 215),
    text = Color3.fromRGB(230, 238, 248), sub = Color3.fromRGB(140, 165, 195),
    dim = Color3.fromRGB(80, 105, 135), green = Color3.fromRGB(80, 230, 140),
    red = Color3.fromRGB(255, 90, 90), yellow = Color3.fromRGB(255, 196, 60),
    white = Color3.new(1, 1, 1),
}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function stroke(o, color, thick, transp)
    return new("UIStroke", {Color = color, Thickness = thick or 1, Transparency = transp or 0}, o)
end
local function gradient(o, keys, rot)
    local pts = {}
    for _, k in ipairs(keys) do pts[#pts + 1] = ColorSequenceKeypoint.new(k[1], k[2]) end
    return new("UIGradient", {Color = ColorSequence.new(pts), Rotation = rot or 0}, o)
end
local function spin(grad, seconds)
    TweenService:Create(grad, TweenInfo.new(seconds, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360}):Play()
end
local function thumb(id, size)
    return ("rbxthumb://type=Asset&id=%d&w=%d&h=%d"):format(id, size, size)
end

-- ScreenGui
local gui = new("ScreenGui", {
    Name = "BalereotCommunity", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, nil)
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okParent or not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

-- Jendela utama
local main = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true, Draggable = true,
    ClipsDescendants = true,
}, gui)
round(main, 14)
new("UISizeConstraint", {MaxSize = Vector2.new(420, 9999), MinSize = Vector2.new(280, 366)}, main)
gradient(main, {{0, Color3.fromRGB(10, 28, 52)}, {0.5, Color3.fromRGB(8, 16, 30)}, {1, Color3.fromRGB(4, 8, 16)}}, 90)
local mainStroke = stroke(main, C.stroke, 3)
spin(gradient(mainStroke, {{0, C.accent}, {0.25, C.cyan}, {0.5, Color3.fromRGB(255, 255, 255)}, {0.75, C.accent2}, {1, C.accent}}), 4)

-- Tombol toggle (kiri atas)
local toggleBox = new("Frame", {
    Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(8, 8),
    BackgroundColor3 = C.header, BorderSizePixel = 0, ZIndex = 100,
}, gui)
round(toggleBox, 8)
spin(gradient(stroke(toggleBox, C.accent, 1.5), {{0, C.accent}, {0.33, C.cyan}, {0.66, C.accent2}, {1, C.accent}}), 2.5)
local toggleBtn = new("TextButton", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "BC",
    TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = C.white, ZIndex = 101,
}, toggleBox)
toggleBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

-- Header
local header = new("Frame", {Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C.header, BorderSizePixel = 0, ZIndex = 3}, main)
round(header, 14)
gradient(header, {{0, Color3.fromRGB(12, 34, 62)}, {1, Color3.fromRGB(6, 14, 26)}}, 90)
local line = new("Frame", {Size = UDim2.new(1, 0, 0, 1.5), Position = UDim2.new(0, 0, 1, -1.5), BorderSizePixel = 0, BackgroundColor3 = C.white, ZIndex = 5}, header)
gradient(line, {{0, C.accent}, {0.5, C.cyan}, {1, C.accent2}})
local title = new("TextLabel", {
    Position = UDim2.new(0, 12, 0.5, -9), Size = UDim2.new(0, 170, 0, 18), BackgroundTransparency = 1,
    Text = "BALEREOT COMMUNITY", TextSize = 12, Font = Enum.Font.Arcade, TextColor3 = C.white,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
}, header)
gradient(title, {{0, Color3.fromRGB(0, 220, 255)}, {0.5, Color3.fromRGB(255, 255, 255)}, {1, Color3.fromRGB(255, 196, 60)}}, 15)

local right = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(100, 24), BackgroundTransparency = 1, ZIndex = 4}, header)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, right)
local online = new("Frame", {LayoutOrder = 1, Size = UDim2.fromOffset(58, 20), BackgroundColor3 = Color3.fromRGB(12, 44, 34), BorderSizePixel = 0, ZIndex = 4}, right)
round(online, 10)
new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "Online", Font = Enum.Font.GothamBold, TextSize = 8, TextColor3 = Color3.fromRGB(170, 255, 210)}, online)
local closeBtn = new("TextButton", {LayoutOrder = 2, Size = UDim2.fromOffset(26, 24), BackgroundColor3 = C.red, Text = "X", TextColor3 = C.white, TextSize = 11, Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 4}, right)
round(closeBtn, 6)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

-- Search bar
local searchBar = new("Frame", {Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 50), BackgroundColor3 = C.input, BorderSizePixel = 0, ZIndex = 3}, main)
round(searchBar, 8)
local searchStroke = stroke(searchBar, C.stroke, 1.2, 0.5)
new("TextLabel", {Size = UDim2.new(0, 26, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = "?", TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = C.sub, ZIndex = 4}, searchBar)
local searchBox = new("TextBox", {
    Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(34, 0), BackgroundTransparency = 1,
    Text = "", PlaceholderText = "Search Assets / paste ID...", TextColor3 = C.text, PlaceholderColor3 = C.dim,
    TextSize = 10, Font = Enum.Font.Code, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4,
}, searchBar)
searchBox.Focused:Connect(function() searchStroke.Color = C.accent; searchStroke.Transparency = 0 end)
searchBox.FocusLost:Connect(function() searchStroke.Color = C.stroke; searchStroke.Transparency = 0.5 end)
local searchBtn = new("TextButton", {
    Size = UDim2.fromOffset(58, 30), Position = UDim2.new(1, -5, 0.5, -15), AnchorPoint = Vector2.new(1, 0),
    BackgroundColor3 = C.accent, Text = "SEARCH", TextColor3 = C.white, TextSize = 8.5,
    Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 4,
}, searchBar)
round(searchBtn, 6)

-- Tabs
local TABS = {"Model", "Texture", "Decal", "Audio", "Favorites"}
local TAB_NAMES = {Model = "Models", Texture = "Textures", Decal = "Decals", Audio = "Audio", Favorites = "* Favs"}
local currentTab = "Model"
local tabBar = new("Frame", {Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 97), BackgroundTransparency = 1, ZIndex = 3}, main)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, tabBar)
local tabButtons = {}

-- Hasil (grid 2 kolom)
local RES_TOP = 134
local results = new("ScrollingFrame", {
    Size = UDim2.new(1, -16, 0, 200), Position = UDim2.fromOffset(8, RES_TOP), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3,
}, main)
new("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 40)}, results)
new("UIGridLayout", {CellSize = UDim2.new(0.5, -4, 0, 165), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}, results)

local morePill = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(150, 34), BackgroundColor3 = C.header,
    BorderSizePixel = 0, Visible = false, ZIndex = 10,
}, main)
round(morePill, 17)
stroke(morePill, C.accent, 1.2)
local moreBtn = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "v LOAD MORE", TextColor3 = C.text, TextSize = 10, Font = Enum.Font.GothamBold, ZIndex = 11}, morePill)

-- Log
local logFrame = new("Frame", {Size = UDim2.new(1, -16, 0, 100), BackgroundColor3 = C.header, BorderSizePixel = 0, ZIndex = 3}, main)
round(logFrame, 10)
stroke(logFrame, C.stroke, 1, 0.5)
new("TextLabel", {Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 6), BackgroundTransparency = 1, Text = "> SYSTEM OUTPUT LOG", TextSize = 8.5, Font = Enum.Font.GothamBold, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4}, logFrame)
new("Frame", {Size = UDim2.new(1, -20, 0, 1), Position = UDim2.fromOffset(10, 26), BackgroundColor3 = C.stroke, BorderSizePixel = 0, ZIndex = 4}, logFrame)
local logList = new("ScrollingFrame", {
    Size = UDim2.new(1, -18, 1, -36), Position = UDim2.fromOffset(9, 30), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 4,
}, logFrame)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)}, logList)

local logCount = 0
local function log(text, color)
    logCount += 1
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = tostring(text), TextColor3 = color or C.sub,
        Font = Enum.Font.Code, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = logCount, ZIndex = 5,
    }, logList)
    if logCount > 80 then
        for _, c in ipairs(logList:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() break end
        end
    end
    task.defer(function() logList.CanvasPosition = Vector2.new(0, logList.AbsoluteCanvasSize.Y) end)
end

local function layout()
    local h = math.clamp(camera.ViewportSize.Y - 60, 366, 600)
    main.Size = UDim2.new(0.92, 0, 0, h)
    local avail = h - RES_TOP - 8
    local resH = math.floor(avail * 0.66)
    results.Size = UDim2.new(1, -16, 0, resH)
    logFrame.Position = UDim2.fromOffset(8, RES_TOP + resH + 6)
    logFrame.Size = UDim2.new(1, -16, 0, avail - resH - 6)
    morePill.Position = UDim2.new(0.5, 0, 0, RES_TOP + resH - 6)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()

-- =========================================================
-- INSERT (Studio Lite)
-- =========================================================
local function spawnCFrame()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then return root.CFrame * CFrame.new(0, 0, -8) end
    return camera.CFrame * CFrame.new(0, 0, -15)
end
local function selectObj(obj)
    pcall(function() game:GetService("Selection"):Set({obj}) end)
end

local function proxyBlock(id, kind)
    local part = new("Part", {Anchored = true, Name = kind .. "_" .. id, CFrame = spawnCFrame()})
    if kind == "Audio" then
        part.Size = Vector3.new(2, 2, 2)
        part.Material = Enum.Material.Neon
        new("Sound", {Name = "AudioData", SoundId = "rbxassetid://" .. id, Volume = 0.5, Looped = true}, part):Play()
    else
        part.Size = Vector3.new(4, 4, 0.2)
        part.Material = Enum.Material.SmoothPlastic
        new(kind, {Texture = "rbxassetid://" .. id, Face = Enum.NormalId.Front}, part)
    end
    part.Parent = workspace
    selectObj(part)
end

local function fetchFromStudioLite(id)
    local folder = ReplicatedStorage:FindFirstChild("StudioLiteFolder") or ReplicatedStorage:WaitForChild("StudioLiteFolder", 5)
    local remote = folder and folder:WaitForChild("LoadAssetModelToPlayerGuiServerFunction", 5)
    if not remote then return nil, "Studio Lite tidak ditemukan" end
    local pg = player:WaitForChild("PlayerGui")
    local before = {}
    for _, c in ipairs(pg:GetChildren()) do before[c] = true end
    local ok, res = pcall(function() return remote:InvokeServer(id) end)
    if not ok then return nil, "Server timeout" end
    if typeof(res) == "Instance" then return res end
    task.wait(0.3)
    for _, c in ipairs(pg:GetChildren()) do
        if not before[c] and c ~= gui then return c end
    end
    return nil, "Gagal merender data dari SL"
end

local function place(obj)
    local sky = obj:IsA("Sky") and obj or obj:FindFirstChildWhichIsA("Sky", true)
    local tool = ((obj:IsA("Tool") or obj:IsA("HopperBin")) and obj)
        or obj:FindFirstChildWhichIsA("Tool", true) or obj:FindFirstChildWhichIsA("HopperBin", true)
    if sky then
        sky.Parent = Lighting
        if sky ~= obj then obj:Destroy() end
        return "Sky"
    elseif tool then
        pcall(function() tool:Clone().Parent = game:GetService("StarterPack") end)
        tool.Parent = player:FindFirstChild("Backpack") or workspace
        if tool ~= obj then obj:Destroy() end
        return "Tool"
    end
    obj.Parent = workspace
    task.wait(0.05)
    if obj:IsA("Model") then obj:PivotTo(spawnCFrame())
    elseif obj:IsA("BasePart") then obj.CFrame = spawnCFrame() end
    selectObj(obj)
    return "Model"
end

local function insertAsset(item)
    local id, kind = item.id, item.kind
    if kind == "Audio" or kind == "Decal" or kind == "Texture" then
        log("Inserting " .. kind .. " " .. id .. "...", C.text)
        proxyBlock(id, kind)
        return log(kind .. " Inserted to Proxy Block", C.green)
    end
    log("Inserting " .. tostring(item.name) .. "...", C.text)
    log("Connecting to SL server...", C.sub)
    local obj, err = fetchFromStudioLite(id)
    if not obj then
        local ok, model = pcall(function() return InsertService:LoadAsset(id) end)
        if not ok or not model then return log("X " .. tostring(err), C.red) end
        obj = model
    end
    local items = obj:IsA("Folder") and obj:GetChildren() or {obj}
    local result
    for _, it in ipairs(items) do result = place(it) end
    if obj:IsA("Folder") then obj:Destroy() end
    log(("OK Inserted %s (%s)"):format(tostring(item.name), result or "?"), C.green)
end

-- =========================================================
-- FAVORITES
-- =========================================================
local favorites = {}
local function favIndex(id)
    for i, f in ipairs(favorites) do if f.id == id then return i end end
end
local function toggleFav(item)
    local i = favIndex(item.id)
    if i then table.remove(favorites, i) else favorites[#favorites + 1] = item end
    return not i
end

-- =========================================================
-- PREVIEW POPUP
-- =========================================================
local overlay = new("TextButton", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4,
    Text = "", AutoButtonColor = false, Visible = false, ZIndex = 200,
}, main)
local pcard = new("Frame", {
    Size = UDim2.fromOffset(240, 340), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, Active = true,
}, overlay)
round(pcard, 16)
stroke(pcard, C.accent, 1.5, 0.2)
local pimgFrame = new("Frame", {Size = UDim2.new(1, -24, 0, 236), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = C.input, BorderSizePixel = 0, ClipsDescendants = true}, pcard)
round(pimgFrame, 12)
stroke(pimgFrame, C.stroke, 1, 0.5)
local pimg = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 0}, pimgFrame)
local pph = new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "...", TextSize = 28, Font = Enum.Font.GothamBold, TextColor3 = C.dim}, pimgFrame)
local pname = new("TextLabel", {Size = UDim2.new(1, -24, 0, 20), Position = UDim2.fromOffset(12, 258), BackgroundTransparency = 1, Text = "", TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd}, pcard)
local pby = new("TextLabel", {Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(12, 278), BackgroundTransparency = 1, Text = "", TextColor3 = C.sub, Font = Enum.Font.GothamMedium, TextSize = 10}, pcard)
local pinsert = new("TextButton", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -24, 0, 36),
    BackgroundColor3 = C.accent, Text = "INSERT ASSET", TextColor3 = C.white, TextSize = 11,
    Font = Enum.Font.GothamBold, BorderSizePixel = 0, AutoButtonColor = true,
}, pcard)
round(pinsert, 8)
local pclose = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 20), Size = UDim2.fromOffset(26, 26),
    BackgroundColor3 = Color3.fromRGB(10, 10, 10), BackgroundTransparency = 0.4, Text = "X", TextColor3 = C.white,
    TextSize = 12, Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 5,
}, pcard)
round(pclose, 13)

local previewItem
local function closePreview() overlay.Visible = false; previewItem = nil end
pclose.MouseButton1Click:Connect(closePreview)
overlay.MouseButton1Click:Connect(closePreview)
pinsert.MouseButton1Click:Connect(function()
    local item = previewItem
    if not item then return end
    closePreview()
    task.spawn(insertAsset, item)
end)

local function loadThumb(img, placeholder, id, size)
    img.Image = thumb(id, size)
    task.spawn(function()
        local t = 0
        while img.Parent and not img.IsLoaded and t < 8 do task.wait(0.2); t += 0.2 end
        if placeholder.Parent then
            if img.IsLoaded then placeholder.Visible = false else placeholder.Text = "?" end
        end
    end)
end

local function showPreview(item)
    previewItem = item
    pname.Text = tostring(item.name)
    pby.Text = "by " .. tostring(item.creator) .. "  |  ID " .. item.id
    pimg.Image = ""
    pph.Visible = true
    if item.kind == "Audio" then
        pph.Text = "AUDIO"
    else
        pph.Text = "..."
        loadThumb(pimg, pph, item.id, 420)
    end
    overlay.Visible = true
end

-- =========================================================
-- KARTU ASSET (thumbnail + nama + tombol)
-- =========================================================
local function clearResults()
    for _, c in ipairs(results:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    results.CanvasPosition = Vector2.new(0, 0)
    morePill.Visible = false
end

local order = 0
local function addCard(item)
    order += 1
    local card = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = C.panel, BorderSizePixel = 0, LayoutOrder = order}, results)
    round(card, 10)
    stroke(card, C.stroke, 1, 0.5)
    local tf = new("Frame", {Size = UDim2.new(1, -12, 0, 100), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.input, BorderSizePixel = 0, ClipsDescendants = true}, card)
    round(tf, 8)
    local img = new("ImageLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit}, tf)
    local ph = new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "...", TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = C.dim}, tf)
    if item.kind == "Audio" then ph.Text = "AUDIO" else loadThumb(img, ph, item.id, 150) end

    new("TextLabel", {Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(6, 110), BackgroundTransparency = 1, Text = tostring(item.name), TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, card)
    new("TextLabel", {Size = UDim2.new(1, -12, 0, 12), Position = UDim2.fromOffset(6, 126), BackgroundTransparency = 1, Text = "by " .. tostring(item.creator), TextColor3 = C.sub, Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, card)

    local ins = new("TextButton", {Size = UDim2.new(1, -42, 0, 18), Position = UDim2.fromOffset(6, 142), BackgroundColor3 = C.accent, Text = "INSERT", TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 9, BorderSizePixel = 0}, card)
    round(ins, 5)
    local fav = new("TextButton", {Size = UDim2.fromOffset(28, 18), Position = UDim2.new(1, -34, 0, 142), BackgroundColor3 = C.input, Text = favIndex(item.id) and "*" or "+", TextColor3 = C.accent2, Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0}, card)
    round(fav, 5)

    card.MouseButton1Click:Connect(function() showPreview(item) end)
    ins.MouseButton1Click:Connect(function() task.spawn(insertAsset, item) end)
    fav.MouseButton1Click:Connect(function()
        local added = toggleFav(item)
        fav.Text = added and "*" or "+"
        log(added and "Ditambahkan ke Favorites" or "Dihapus dari Favorites", C.yellow)
        if currentTab == "Favorites" and not added then card:Destroy() end
    end)
end

-- =========================================================
-- PENCARIAN
-- =========================================================
local function toArray(res)
    if res == nil then return {} end
    if type(res) == "table" then
        if res.Results then return res.Results end
        if type(res[1]) == "table" and res[1].Results then return res[1].Results end
        return res
    end
    local ok, page = pcall(function() return res:GetCurrentPage() end)
    if ok and type(page) == "table" then return page end
    return {}
end

local function mapItem(it, kind)
    if type(it) ~= "table" then return nil end
    local id = tonumber(it.AssetId or it.Id or it.AssetID)
    if not id then return nil end
    local name = tostring(it.Name or it.Title or "Unknown")
    local low = name:lower()
    if low:match("content deleted") or low:match("%[deleted%]") or low:match("%(deleted%)") or low == "deleted" then return nil end
    local creator = "Roblox"
    if type(it.Creator) == "table" and it.Creator.Name then creator = it.Creator.Name
    elseif it.CreatorName then creator = it.CreatorName
    elseif it.Artist then creator = it.Artist end
    return {id = id, name = name, creator = tostring(creator), kind = kind}
end

local audioPages, httpCursor
local function httpSearch(kind, kw, page)
    local typeId = kind == "Model" and 10 or 13
    local url = ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?limit=20&keyword=%s"):format(typeId, HttpService:UrlEncode(kw))
    if page > 0 and httpCursor then url ..= "&cursor=" .. HttpService:UrlEncode(httpCursor) end
    local ok, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
    if not ok or type(res) ~= "table" or not res.data then return {} end
    httpCursor = res.nextPageCursor
    local ids = {}
    for _, d in ipairs(res.data) do ids[#ids + 1] = d.id end
    local names, creators = {}, {}
    if #ids > 0 then
        local ok2, det = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=" .. table.concat(ids, ",")))
        end)
        if ok2 and type(det) == "table" and det.data then
            for _, d in ipairs(det.data) do
                if d.asset then names[d.asset.id] = d.asset.name; creators[d.asset.id] = d.creator and d.creator.name end
            end
        end
    end
    local arr = {}
    for _, id in ipairs(ids) do arr[#arr + 1] = {AssetId = id, Name = names[id] or "Asset", CreatorName = creators[id]} end
    return arr
end

-- return: daftar item mentah, hasMore, pesan error
local function fetchPage(kind, kw, page)
    if kind == "Audio" then
        if page == 0 or not audioPages then
            local params = Instance.new("AudioSearchParams")
            params.SearchKeyword = kw
            local ok, res = pcall(function() return AssetService:SearchAudioAsync(params) end)
            if not ok or not res then return nil, false, "Audio API: " .. tostring(res) end
            audioPages = res
        else
            if not pcall(function() audioPages:AdvanceToNextPageAsync() end) then return {}, false end
        end
        return toArray(audioPages), not audioPages.IsFinished
    end
    local method = (kind == "Model") and "GetFreeModelsAsync" or "GetFreeDecalsAsync"
    local ok, res = pcall(function() return InsertService[method](InsertService, kw, page, 20) end)
    local raw = ok and toArray(res) or {}
    local err = (not ok) and tostring(res) or nil
    if #raw == 0 then
        raw = httpSearch(kind, kw, page)
        if #raw > 0 then return raw, httpCursor ~= nil end
        return nil, false, err or "Tidak ada hasil"
    end
    return raw, #raw >= 10
end

local searchToken, page, searching = 0, 0, false

local function renderFavorites()
    clearResults()
    for _, f in ipairs(favorites) do addCard(f) end
    log(#favorites .. " favorites", C.green)
end

local function runSearch(append)
    if currentTab == "Favorites" then return renderFavorites() end
    local kw = searchBox.Text:match("^%s*(.-)%s*$")
    if kw == "" then return log("Isi keyword dulu.", C.yellow) end
    if searching then return end
    searching = true
    searchToken += 1
    local token = searchToken
    searchBtn.Text = "..."
    if append then page += 1 else page = 0; clearResults(); order = 0 end

    local list, hasMore, err = {}, false, nil
    local idStr = kw:match("^(%d+)$") or (kw:find("roblox.com", 1, true) and kw:match("(%d%d%d+)"))
    if idStr and not append then
        list = {{id = tonumber(idStr), name = "Asset " .. idStr, creator = "direct ID", kind = currentTab}}
    else
        local raw
        raw, hasMore, err = fetchPage(currentTab, kw, page)
        for _, it in ipairs(raw or {}) do
            local m = mapItem(it, currentTab)
            if m then list[#list + 1] = m end
        end
    end

    searching = false
    searchBtn.Text = "SEARCH"
    if token ~= searchToken then return end
    if #list == 0 then
        morePill.Visible = false
        if page == 0 then
            log("X NO RESULTS FOUND", C.red)
            if err then log(err, C.dim) end
        else
            log("! SERVER LIMIT REACHED", C.yellow)
        end
        return
    end
    for _, m in ipairs(list) do addCard(m) end
    log(page == 0 and ("FOUND " .. #list .. " results") or ("LOADED " .. #list .. " more"), C.green)
    morePill.Visible = hasMore
    moreBtn.Text = "v LOAD MORE  [Hal." .. (page + 1) .. "]"
end

searchBtn.MouseButton1Click:Connect(function() task.spawn(runSearch, false) end)
searchBox.FocusLost:Connect(function(enter) if enter then task.spawn(runSearch, false) end end)
moreBtn.MouseButton1Click:Connect(function() task.spawn(runSearch, true) end)

-- Tabs
local function setTab(name)
    currentTab = name
    for n, b in pairs(tabButtons) do
        b.BackgroundColor3 = (n == name) and C.accent or C.input
        b.TextColor3 = (n == name) and C.white or C.sub
    end
    audioPages, httpCursor = nil, nil
    if name == "Favorites" then
        renderFavorites()
    else
        clearResults()
        order = 0
        if searchBox.Text ~= "" then task.spawn(runSearch, false) end
    end
end
for i, name in ipairs(TABS) do
    local b = new("TextButton", {
        LayoutOrder = i, Size = UDim2.new(0.2, -4, 1, 0), BackgroundColor3 = C.input, Text = TAB_NAMES[name],
        TextColor3 = C.sub, TextSize = 8.5, Font = Enum.Font.GothamBold, BorderSizePixel = 0, ZIndex = 4,
    }, tabBar)
    round(b, 6)
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function() setTab(name) end)
end
setTab("Model")

-- Tampilkan
gui.Parent = gui.Parent
log("BALEREOT COMMUNITY TOOLBOX READY", C.green)
log("Klik BC untuk show/hide", C.sub)
