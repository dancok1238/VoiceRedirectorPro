-- MyToolbox: kode orisinal. Fitur: cari asset, insert via ID/URL, load more, log, toggle UI.
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
if not pcall(function() return parentGui.Name end) then
    parentGui = player:WaitForChild("PlayerGui")
end

local C = {
    bg = Color3.fromRGB(24, 24, 28), panel = Color3.fromRGB(34, 34, 40),
    accent = Color3.fromRGB(88, 101, 242), text = Color3.new(1, 1, 1),
    sub = Color3.fromRGB(170, 170, 178), red = Color3.fromRGB(255, 90, 90),
    green = Color3.fromRGB(90, 220, 160),
}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end

local gui = new("ScreenGui", {Name = "MyToolbox", ResetOnSpawn = false, DisplayOrder = 999}, parentGui)

-- tombol toggle
local toggle = new("TextButton", {
    Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0, 12, 0.5, -20),
    BackgroundColor3 = C.accent, Text = "TB", TextColor3 = C.text,
    Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false,
}, gui)
round(toggle, 20)

local main = new("Frame", {
    Size = UDim2.fromOffset(340, 440), Position = UDim2.new(0, 60, 0.5, -220),
    BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true, Draggable = true,
}, gui)
round(main, 12)
toggle.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 6),
    BackgroundTransparency = 1, Text = "MY TOOLBOX", TextColor3 = C.text,
    Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
}, main)

-- log
local logLabel = new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 10, 1, -24),
    BackgroundTransparency = 1, Text = "Siap.", TextColor3 = C.sub,
    Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, main)
local function log(msg, color)
    logLabel.Text = msg
    logLabel.TextColor3 = color or C.sub
end

local function box(placeholder, pos, size)
    local b = new("TextBox", {
        Size = size, Position = pos, BackgroundColor3 = C.panel, PlaceholderText = placeholder,
        Text = "", TextColor3 = C.text, PlaceholderColor3 = C.sub, Font = Enum.Font.Gotham,
        TextSize = 13, ClearTextOnFocus = false, BorderSizePixel = 0,
    }, main)
    round(b, 8)
    return b
end
local function button(text, pos, size)
    local b = new("TextButton", {
        Size = size, Position = pos, BackgroundColor3 = C.accent, Text = text,
        TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 12,
        AutoButtonColor = true, BorderSizePixel = 0,
    }, main)
    round(b, 8)
    return b
end

-- insert via ID / URL
local idBox = box("Asset ID atau URL", UDim2.fromOffset(10, 40), UDim2.new(1, -100, 0, 30))
local insertBtn = button("INSERT", UDim2.new(1, -80, 0, 40), UDim2.fromOffset(70, 30))

-- cari
local searchBox = box("Cari asset...", UDim2.fromOffset(10, 78), UDim2.new(1, -100, 0, 30))
local searchBtn = button("SEARCH", UDim2.new(1, -80, 0, 78), UDim2.fromOffset(70, 30))

local list = new("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -156), Position = UDim2.fromOffset(10, 116),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, ScrollBarThickness = 4,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
round(list, 8)
new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)}, list)

local function parseId(text)
    return tonumber(text:match("%d+"))
end

-- tipe asset (Audio/Decal/Texture dibuat sebagai Proxy Block, sisanya lewat server Studio Lite)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local types, typeIndex = {"Model", "Audio", "Decal", "Texture"}, 1
local typeBtn = button("Model", UDim2.new(1, -90, 0, 8), UDim2.fromOffset(80, 24))
typeBtn.MouseButton1Click:Connect(function()
    typeIndex = typeIndex % #types + 1
    typeBtn.Text = types[typeIndex]
end)

local function spawnCFrame()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then return root.CFrame * CFrame.new(0, 0, -8) end
    return workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -15)
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
    return part
end

-- minta server Studio Lite memuat model, hasilnya berupa Instance atau muncul di PlayerGui
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
        if not before[c] and c ~= gui and c ~= parentGui then return c end
    end
    return nil, "Gagal merender data dari SL"
end

local function place(obj)
    local sky = obj:IsA("Sky") and obj or obj:FindFirstChildWhichIsA("Sky", true)
    local tool = (obj:IsA("Tool") or obj:IsA("HopperBin")) and obj
        or obj:FindFirstChildWhichIsA("Tool", true) or obj:FindFirstChildWhichIsA("HopperBin", true)
    if sky then
        sky.Parent = Lighting
        if sky ~= obj then obj:Destroy() end
        return "Sky"
    elseif tool then
        local backpack = player:FindFirstChild("Backpack")
        pcall(function() tool:Clone().Parent = game:GetService("StarterPack") end)
        tool.Parent = backpack or workspace
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

local function insertAsset(id)
    if not id then return log("ID tidak valid.", C.red) end
    local kind = types[typeIndex]
    if kind ~= "Model" then
        proxyBlock(id, kind)
        return log(kind .. " dimasukkan ke Proxy Block.", C.green)
    end
    log("Connecting to SL server...")
    local obj, err = fetchFromStudioLite(id)
    if not obj then
        -- cadangan: coba InsertService jika Studio Lite tidak tersedia
        local ok, model = pcall(function() return InsertService:LoadAsset(id) end)
        if not ok or not model then return log("Gagal: " .. tostring(err), C.red) end
        obj = model
    end
    local items = obj:IsA("Folder") and obj:GetChildren() or {obj}
    local result
    for _, it in ipairs(items) do result = place(it) end
    if obj:IsA("Folder") then obj:Destroy() end
    log(("Berhasil insert %d (%s)"):format(id, result or "?"), C.green)
end

insertBtn.MouseButton1Click:Connect(function() task.spawn(insertAsset, parseId(idBox.Text)) end)
idBox.FocusLost:Connect(function(enter) if enter then task.spawn(insertAsset, parseId(idBox.Text)) end end)

-- pencarian (endpoint toolbox Roblox; bisa berubah sewaktu-waktu)
local cursor, lastKeyword = nil, nil
local loadMore = new("TextButton", {
    Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.bg, Text = "LOAD MORE",
    TextColor3 = C.sub, Font = Enum.Font.GothamBold, TextSize = 12, LayoutOrder = 1e6,
    Visible = false, BorderSizePixel = 0,
}, list)
round(loadMore, 6)

local function addResult(id, name)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.bg, BorderSizePixel = 0,
        Text = ("  %s  [%d]"):format(name, id), TextColor3 = C.text, Font = Enum.Font.Gotham,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, list)
    round(b, 6)
    b.MouseButton1Click:Connect(function() task.spawn(insertAsset, id) end)
end

local function search(keyword, append)
    if not append then
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") and c ~= loadMore then c:Destroy() end
        end
        cursor = nil
    end
    lastKeyword = keyword
    log("Mencari '" .. keyword .. "'...")
    local url = "https://apis.roblox.com/toolbox-service/v1/marketplace/10?limit=20&keyword="
        .. HttpService:UrlEncode(keyword) .. (cursor and ("&cursor=" .. HttpService:UrlEncode(cursor)) or "")
    local ok, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
    if not ok or not res.data then return log("Pencarian gagal.", C.red) end

    local ids = {}
    for _, item in ipairs(res.data) do ids[#ids + 1] = item.id end
    local names = {}
    if #ids > 0 then
        local ok2, det = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=" .. table.concat(ids, ",")))
        end)
        if ok2 and det.data then
            for _, d in ipairs(det.data) do
                if d.asset then names[d.asset.id] = d.asset.name end
            end
        end
    end
    for _, id in ipairs(ids) do addResult(id, names[id] or "Asset") end

    cursor = res.nextPageCursor
    loadMore.Visible = cursor ~= nil
    log(("%d hasil."):format(#ids), C.green)
end

searchBtn.MouseButton1Click:Connect(function()
    if searchBox.Text ~= "" then search(searchBox.Text, false) end
end)
searchBox.FocusLost:Connect(function(enter)
    if enter and searchBox.Text ~= "" then search(searchBox.Text, false) end
end)
loadMore.MouseButton1Click:Connect(function()
    if lastKeyword and cursor then search(lastKeyword, true) end
end)

log("MyToolbox siap.", C.green)
