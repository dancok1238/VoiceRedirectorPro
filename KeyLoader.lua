local KEY_URL =
    "https://raw.githubusercontent.com/dancok1238/VoiceRedirectorPro/refs/heads/utama/keys.txt"

local TERRAIN_URL =
    "https://raw.githubusercontent.com/dancok1238/VoiceRedirectorPro/refs/heads/utama/Terrain"

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "TerrainKeySystem"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(310, 190)
frame.Position = UDim2.fromScale(.5, .5)
frame.AnchorPoint = Vector2.new(.5, .5)
frame.BackgroundColor3 = Color3.fromRGB(20,20,25)
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-30,0,35)
title.Position = UDim2.fromOffset(15,10)
title.BackgroundTransparency = 1
title.Text = "TERRAIN LOADER"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1,-30,0,40)
box.Position = UDim2.fromOffset(15,55)
box.PlaceholderText = "Masukkan Key..."
box.Text = ""
box.TextSize = 15
box.BackgroundColor3 = Color3.fromRGB(35,35,42)
box.TextColor3 = Color3.new(1,1,1)
box.Parent = frame

Instance.new("UICorner", box).CornerRadius = UDim.new(0,8)

local button = Instance.new("TextButton")
button.Size = UDim2.new(1,-30,0,40)
button.Position = UDim2.fromOffset(15,105)
button.Text = "VERIFY"
button.TextSize = 16
button.Font = Enum.Font.GothamBold
button.BackgroundColor3 = Color3.fromRGB(110,70,220)
button.TextColor3 = Color3.new(1,1,1)
button.Parent = frame

Instance.new("UICorner", button).CornerRadius = UDim.new(0,8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-30,0,25)
status.Position = UDim2.fromOffset(15,150)
status.BackgroundTransparency = 1
status.Text = ""
status.TextSize = 13
status.TextColor3 = Color3.fromRGB(255,100,100)
status.Parent = frame

local function getKeys()
    local ok, data = pcall(function()
        return game:HttpGet(KEY_URL)
    end)

    if not ok then
        return nil
    end

    local keys = {}

    for line in data:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")

        if line ~= "" then
            keys[line] = true
        end
    end

    return keys
end

button.MouseButton1Click:Connect(function()
    local key = box.Text:gsub("^%s+", ""):gsub("%s+$", "")

    if key == "" then
        status.Text = "Masukkan Key."
        return
    end

    button.Text = "CHECKING..."
    button.Active = false

    local keys = getKeys()

    if not keys then
        status.Text = "Gagal mengambil daftar Key."
        button.Text = "VERIFY"
        button.Active = true
        return
    end

    if not keys[key] then
        status.Text = "Key tidak valid."
        button.Text = "VERIFY"
        button.Active = true
        return
    end

    status.Text = "Key valid! Loading..."
    status.TextColor3 = Color3.fromRGB(100,255,140)

    local ok, source = pcall(function()
        return game:HttpGet(TERRAIN_URL)
    end)

    if not ok then
        status.Text = "Gagal mengambil Terrain."
        button.Text = "VERIFY"
        button.Active = true
        return
    end

    local loaded, err = pcall(function()
        loadstring(source)()
    end)

    if loaded then
        gui:Destroy()
    else
        status.Text = "Terrain gagal dijalankan."
        warn(err)
        button.Text = "VERIFY"
        button.Active = true
    end
end)
