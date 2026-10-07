--[[
    VoiceRedirectorPro
    Fixed GUI / Load Save / Universe API / Animation

    CATATAN:
    Bagian VoiceChatInternal, getsenv, replicatesignal,
    forced join/disconnect VC dihapus karena bukan API Roblox resmi.
]]

-- =========================================================
-- CLEAN OLD GUI
-- =========================================================

local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local oldGui = CoreGui:FindFirstChild("VoiceRedirectorPro")

if oldGui then
    oldGui:Destroy()
end

-- =========================================================
-- CONFIG
-- =========================================================

local CONFIG_FILE = "Delta_VoicePro_Config.txt"

local function readConfig()
    local ok, data = pcall(function()
        return readfile(CONFIG_FILE)
    end)

    if ok and data then
        return data
    end

    return nil
end

local function writeConfig(data)
    pcall(function()
        writefile(CONFIG_FILE, data)
    end)
end

-- =========================================================
-- GUI
-- =========================================================

local gui = Instance.new("ScreenGui")
gui.Name = "VoiceRedirectorPro"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 290, 0, 310)
main.Position = UDim2.new(0.5, -145, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
main.BorderSizePixel = 1
main.BorderColor3 = Color3.fromRGB(60, 60, 60)
main.Active = true
main.Draggable = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local FONT = Enum.Font.GothamBold

-- =========================================================
-- HEADER
-- =========================================================

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
header.BorderSizePixel = 0
header.Parent = main

Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🎙️ VC Redirector"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = FONT
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = FONT
closeBtn.TextSize = 12
closeBtn.Parent = main

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 12)

-- =========================================================
-- GAME CARD
-- =========================================================

local card = Instance.new("Frame")
card.Name = "GameCard"
card.Size = UDim2.new(1, -12, 0, 36)
card.Position = UDim2.new(0, 6, 0, 38)
card.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
card.BorderSizePixel = 0
card.Parent = main

Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

local cardGameName = Instance.new("TextLabel")
cardGameName.Name = "GameName"
cardGameName.Size = UDim2.new(1, -16, 1, 0)
cardGameName.Position = UDim2.new(0, 8, 0, 0)
cardGameName.BackgroundTransparency = 1
cardGameName.Text = "Belum ada target"
cardGameName.TextColor3 = Color3.fromRGB(255, 255, 255)
cardGameName.Font = FONT
cardGameName.TextSize = 13
cardGameName.TextXAlignment = Enum.TextXAlignment.Left
cardGameName.TextTruncate = Enum.TextTruncate.AtEnd
cardGameName.Parent = card

-- =========================================================
-- STATUS
-- =========================================================

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -12, 0, 24)
statusLabel.Position = UDim2.new(0, 6, 0, 192)
statusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
statusLabel.BorderSizePixel = 1
statusLabel.BorderColor3 = Color3.fromRGB(80, 80, 80)
statusLabel.Text = "Isi semua field!"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
statusLabel.Font = FONT
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

-- =========================================================
-- STATUS FUNCTION
-- =========================================================

local function setStatus(text, state)

    if not statusLabel then
        return
    end

    statusLabel.Text = tostring(text)

    local color = Color3.fromRGB(220, 220, 100)

    if state == "process" then
        color = Color3.fromRGB(255, 255, 0)

    elseif state == "success" then
        color = Color3.fromRGB(0, 255, 100)

    elseif state == "error" then
        color = Color3.fromRGB(255, 50, 50)

    elseif state == "info" then
        color = Color3.fromRGB(220, 220, 100)
    end

    statusLabel.TextColor3 = color
end

-- =========================================================
-- INPUT
-- =========================================================

local function makeInput(y, labelText, placeholder, isApi)

    local lbl = Instance.new("TextLabel")

    lbl.Size = UDim2.new(0, 85, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = FONT
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = main

    local box = Instance.new("TextBox")

    box.Size = UDim2.new(1, -100, 0, 28)
    box.Position = UDim2.new(0, 92, 0, y - 2)
    box.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
    box.BorderSizePixel = 1
    box.BorderColor3 = Color3.fromRGB(90, 90, 90)
    box.PlaceholderText = placeholder or ""
    box.Font = FONT
    box.TextSize = 12
    box.TextTruncate = Enum.TextTruncate.AtEnd
    box.Text = ""
    box.ClearTextOnFocus = false

    if isApi then
        box.PlaceholderText = "Masukkan API Key"
        box.TextEditable = true
    end

    box.Parent = main

    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    return box
end

local universeBox = makeInput(
    80,
    "Universe ID",
    "cth: 123456789"
)

local placeBox = makeInput(
    118,
    "Place ID",
    "cth: 987654321"
)

local apiBox = makeInput(
    156,
    "API Key",
    "",
    true
)

-- =========================================================
-- LOADING DOTS
-- =========================================================

local dotsFrame = Instance.new("Frame")

dotsFrame.Name = "LoadingDots"
dotsFrame.Size = UDim2.new(0, 40, 0, 12)
dotsFrame.Position = UDim2.new(0.5, -20, 0, 220)
dotsFrame.BackgroundTransparency = 1
dotsFrame.Visible = false
dotsFrame.Parent = main

local dots = {}

for i = 1, 3 do

    local dot = Instance.new("TextLabel")

    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.BackgroundTransparency = 1
    dot.Text = "•"
    dot.TextColor3 = Color3.fromRGB(255, 200, 0)
    dot.Font = FONT
    dot.TextSize = 14
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(
        0,
        (i - 1) * 14 + 6,
        0,
        6
    )

    dot.Parent = dotsFrame

    dots[i] = dot
end

-- =========================================================
-- ANIMATION
-- =========================================================

local isProcessing = false

local function startAnim()

    if isProcessing then
        return
    end

    isProcessing = true
    dotsFrame.Visible = true

    for _, dot in ipairs(dots) do
        dot.TextTransparency = 1
        dot.TextSize = 8
    end

    task.spawn(function()

        while isProcessing and gui.Parent do

            for _, dot in ipairs(dots) do

                if not isProcessing then
                    break
                end

                local tweenIn = TweenService:Create(
                    dot,
                    TweenInfo.new(
                        0.25,
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.Out
                    ),
                    {
                        TextTransparency = 0.2,
                        TextSize = 16
                    }
                )

                tweenIn:Play()

                task.wait(0.15)

                if not isProcessing then
                    break
                end

                local tweenOut = TweenService:Create(
                    dot,
                    TweenInfo.new(
                        0.25,
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.In
                    ),
                    {
                        TextTransparency = 1,
                        TextSize = 8
                    }
                )

                tweenOut:Play()

                task.wait(0.15)
            end

            task.wait(0.1)
        end

        dotsFrame.Visible = false

        for _, dot in ipairs(dots) do
            dot.TextTransparency = 1
            dot.TextSize = 8
        end

    end)
end

local function stopAnim()

    isProcessing = false
    dotsFrame.Visible = false

    for _, dot in ipairs(dots) do
        dot.TextTransparency = 1
        dot.TextSize = 8
    end
end

-- =========================================================
-- UNIVERSE API
-- =========================================================

local function updateGameInfo(universeId, apiKey)

    universeId = tostring(universeId or "")
    apiKey = tostring(apiKey or "")

    local univ = tonumber(universeId)

    if not univ then
        cardGameName.Text = "Universe ID tidak valid"
        return
    end

    if apiKey == "" then
        cardGameName.Text = "Isi API Key untuk nama"
        return
    end

    cardGameName.Text = "Memuat nama game..."

    local ok, result = pcall(function()

        local url =
            "https://apis.roblox.com/cloud/v5/universes/"
            .. tostring(univ)

        local headers = {
            ["x-api-key"] = apiKey
        }

        local response = HttpService:RequestAsync({
            Url = url,
            Method = "GET",
            Headers = headers
        })

        if not response.Success then
            error(
                "HTTP "
                .. tostring(response.StatusCode)
            )
        end

        local data = HttpService:JSONDecode(
            response.Body
        )

        return data.displayName
            or data.name
            or ("Universe " .. tostring(univ))
    end)

    if ok and result then
        cardGameName.Text = tostring(result)
    else
        cardGameName.Text = "Gagal memuat nama"
    end
end

-- =========================================================
-- SMALL BUTTON
-- =========================================================

local function makeSmallButton(x, y, text, callback)

    local btn = Instance.new("TextButton")

    btn.Size = UDim2.new(0, 70, 0, 26)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = FONT
    btn.TextSize = 12
    btn.Parent = main

    Instance.new("UICorner", btn).CornerRadius =
        UDim.new(0, 6)

    btn.MouseButton1Click:Connect(callback)

    return btn
end

-- =========================================================
-- LOAD
-- =========================================================

makeSmallButton(6, 238, "Load", function()

    local raw = readConfig()

    if not raw then
        setStatus(
            "File config tidak ditemukan.",
            "info"
        )
        return
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)

    if not ok or type(data) ~= "table" then

        setStatus(
            "Format config rusak.",
            "error"
        )

        return
    end

    universeBox.Text =
        tostring(data.UniverseID or "")

    placeBox.Text =
        tostring(data.PlaceID or "")

    apiBox.Text =
        tostring(data.APIKey or "")

    updateGameInfo(
        universeBox.Text,
        apiBox.Text
    )

    setStatus(
        "Config berhasil dimuat.",
        "success"
    )
end)

-- =========================================================
-- SAVE
-- =========================================================

makeSmallButton(82, 238, "Save", function()

    local data = {
        UniverseID = universeBox.Text,
        PlaceID = placeBox.Text,
        APIKey = apiBox.Text
    }

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if not ok then
        setStatus(
            "Gagal membuat config.",
            "error"
        )
        return
    end

    writeConfig(encoded)

    setStatus(
        "Config tersimpan.",
        "success"
    )
end)

-- =========================================================
-- ENABLE BUTTON
-- =========================================================

local enableBtn = Instance.new("TextButton")

enableBtn.Size = UDim2.new(0, 125, 0, 34)
enableBtn.Position = UDim2.new(0, 6, 0, 270)
enableBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 70)
enableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
enableBtn.BorderSizePixel = 0
enableBtn.Text = "ENABLE"
enableBtn.Font = FONT
enableBtn.TextSize = 13
enableBtn.Parent = main

Instance.new("UICorner", enableBtn).CornerRadius =
    UDim.new(0, 8)

-- =========================================================
-- DISABLE BUTTON
-- =========================================================

local disableBtn = Instance.new("TextButton")

disableBtn.Size = UDim2.new(0, 125, 0, 34)
disableBtn.Position = UDim2.new(0, 140, 0, 270)
disableBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
disableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
disableBtn.BorderSizePixel = 0
disableBtn.Text = "DISABLE"
disableBtn.Font = FONT
disableBtn.TextSize = 13
disableBtn.Parent = main

Instance.new("UICorner", disableBtn).CornerRadius =
    UDim.new(0, 8)

-- =========================================================
-- FIELD CHANGE
-- =========================================================

local function onFieldChanged()

    updateGameInfo(
        universeBox.Text,
        apiBox.Text
    )
end

universeBox.FocusLost:Connect(onFieldChanged)
placeBox.FocusLost:Connect(onFieldChanged)
apiBox.FocusLost:Connect(onFieldChanged)

-- =========================================================
-- ENABLE
-- =========================================================

enableBtn.MouseButton1Click:Connect(function()

    if isProcessing then

        setStatus(
            "Proses sedang berjalan...",
            "process"
        )

        return
    end

    local universeId =
        tostring(universeBox.Text or "")

    local placeId =
        tonumber(placeBox.Text)

    local apiKey =
        tostring(apiBox.Text or "")

    if universeId == ""
        or not placeId
        or apiKey == "" then

        setStatus(
            "Isi semua field!",
            "error"
        )

        return
    end

    startAnim()

    setStatus(
        "Target siap. Gunakan pengaturan Voice Chat resmi Roblox.",
        "info"
    )

    task.wait(0.5)

    stopAnim()
end)

-- =========================================================
-- DISABLE
-- =========================================================

disableBtn.MouseButton1Click:Connect(function()

    if isProcessing then

        setStatus(
            "Proses sedang berjalan...",
            "process"
        )

        return
    end

    local universeId =
        tostring(universeBox.Text or "")

    local apiKey =
        tostring(apiBox.Text or "")

    if universeId == "" or apiKey == "" then

        setStatus(
            "Isi Universe ID & API Key!",
            "error"
        )

        return
    end

    startAnim()

    setStatus(
        "Target siap. Perubahan Voice Chat harus dilakukan melalui API Roblox resmi.",
        "info"
    )

    task.wait(0.5)

    stopAnim()
end)

-- =========================================================
-- CLOSE
-- =========================================================

closeBtn.MouseButton1Click:Connect(function()

    stopAnim()

    if gui then
        gui:Destroy()
    end
end)

-- =========================================================
-- INITIAL
-- =========================================================

updateGameInfo(
    universeBox.Text,
    apiBox.Text
)
