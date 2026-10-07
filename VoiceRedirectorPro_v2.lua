--[[
========================================================
 ROBLOX OPEN CLOUD - VOICE CHAT CONFIG PANEL
 Versi aman
========================================================
 API KEY:
 Ubah hanya bagian:
     API_KEY = "MASUKKAN_API_KEY_DI_SINI"

 Jangan membagikan script setelah API key dimasukkan.
========================================================
]]

local API_KEY = "MASUKKAN_API_KEY_DI_SINI"
local DEFAULT_UNIVERSE_ID = ""
local DEFAULT_PLACE_ID = ""

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local oldGui = CoreGui:FindFirstChild("VoiceRedirectorPro")
if oldGui then oldGui:Destroy() end

local function create(className, properties, parent)
	local object = Instance.new(className)
	for property, value in pairs(properties) do
		object[property] = value
	end
	object.Parent = parent
	return object
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local gui = create("ScreenGui", {
	Name = "VoiceRedirectorPro",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, CoreGui)

local main = create("Frame", {
	Name = "Main",
	Size = UDim2.new(0, 290, 0, 310),
	Position = UDim2.new(0.5, -145, 0.3, 0),
	BackgroundColor3 = Color3.fromRGB(28, 28, 30),
	BorderSizePixel = 1,
	BorderColor3 = Color3.fromRGB(60, 60, 60),
	Active = true,
	Draggable = true
}, gui)
corner(main, 12)

local header = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundColor3 = Color3.fromRGB(40, 40, 45),
	BorderSizePixel = 0
}, main)
corner(header, 12)

local title = create("TextLabel", {
	Name = "Title",
	Size = UDim2.new(1, -40, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	Text = "🎙️ Voice Chat Config",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left
}, header)

local closeBtn = create("TextButton", {
	Name = "Close",
	Size = UDim2.new(0, 24, 0, 24),
	Position = UDim2.new(1, -28, 0, 4),
	BackgroundColor3 = Color3.fromRGB(220, 60, 60),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Text = "✕",
	Font = Enum.Font.GothamBold,
	TextSize = 12
}, header)
corner(closeBtn, 12)

local card = create("Frame", {
	Name = "GameCard",
	Size = UDim2.new(1, -12, 0, 36),
	Position = UDim2.new(0, 6, 0, 38),
	BackgroundColor3 = Color3.fromRGB(50, 50, 55),
	BorderSizePixel = 0
}, main)
corner(card, 8)

local cardGameName = create("TextLabel", {
	Name = "GameName",
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.new(0, 8, 0, 0),
	BackgroundTransparency = 1,
	Text = "Target tidak ada",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd
}, card)

local function makeInput(y, labelText, placeholder)
	create("TextLabel", {
		Size = UDim2.new(0, 85, 0, 18),
		Position = UDim2.new(0, 8, 0, y),
		BackgroundTransparency = 1,
		Text = labelText,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	}, main)

	local box = create("TextBox", {
		Size = UDim2.new(1, -100, 0, 28),
		Position = UDim2.new(0, 92, 0, y - 2),
		BackgroundColor3 = Color3.fromRGB(58, 58, 62),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		PlaceholderColor3 = Color3.fromRGB(140, 140, 140),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(90, 90, 90),
		PlaceholderText = placeholder or "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
		ClearTextOnFocus = false
	}, main)
	corner(box, 6)
	return box
end

local universeBox = makeInput(80, "Universe ID", "contoh: 123456789")
local placeBox = makeInput(118, "Place ID", "contoh: 987654321")
local apiBox = makeInput(156, "API Key", "Open Cloud API Key")

if API_KEY ~= "" and API_KEY ~= "MASUKKAN_API_KEY_DI_SINI" then
	apiBox.Text = API_KEY
end

universeBox.Text = DEFAULT_UNIVERSE_ID
placeBox.Text = DEFAULT_PLACE_ID

local statusLabel = create("TextLabel", {
	Name = "Status",
	Size = UDim2.new(1, -12, 0, 24),
	Position = UDim2.new(0, 6, 0, 192),
	BackgroundColor3 = Color3.fromRGB(50, 50, 55),
	BorderSizePixel = 1,
	BorderColor3 = Color3.fromRGB(80, 80, 80),
	Text = "Isi semua kolom!",
	TextColor3 = Color3.fromRGB(255, 255, 100),
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left
}, main)
corner(statusLabel, 6)

local function setStatus(text, status)
	statusLabel.Text = text
	if status == "process" then
		statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	elseif status == "success" then
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	elseif status == "error" then
		statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	else
		statusLabel.TextColor3 = Color3.fromRGB(220, 220, 100)
	end
end

local dotsFrame = create("Frame", {
	Name = "Dots",
	Size = UDim2.new(0, 40, 0, 12),
	Position = UDim2.new(0.5, -20, 0, 220),
	BackgroundTransparency = 1,
	Visible = false
}, main)

local dots = {}
for i = 1, 3 do
	dots[i] = create("TextLabel", {
		Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(0, (i - 1) * 14 + 6, 0, 0),
		BackgroundTransparency = 1,
		Text = "•",
		TextColor3 = Color3.fromRGB(255, 200, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextTransparency = 1
	}, dotsFrame)
end

local isProcessing = false

local function startAnim()
	if isProcessing then return end
	isProcessing = true
	dotsFrame.Visible = true

	task.spawn(function()
		while isProcessing do
			for _, dot in ipairs(dots) do
				if not isProcessing then break end
				TweenService:Create(dot, TweenInfo.new(0.2), {
					TextTransparency = 0,
					TextSize = 18
				}):Play()
				task.wait(0.15)
				TweenService:Create(dot, TweenInfo.new(0.2), {
					TextTransparency = 1,
					TextSize = 8
				}):Play()
				task.wait(0.15)
			end
			task.wait(0.1)
		end
		dotsFrame.Visible = false
	end)
end

local function stopAnim()
	isProcessing = false
	for _, dot in ipairs(dots) do
		dot.TextTransparency = 1
		dot.TextSize = 8
	end
	dotsFrame.Visible = false
end

local function getAPIKey()
	if API_KEY ~= "" and API_KEY ~= "MASUKKAN_API_KEY_DI_SINI" then
		return API_KEY
	end
	return apiBox.Text
end

local function requestUniverse(method, universeId, body)
	local key = getAPIKey()
	if key == "" then return false, "API Key kosong" end
	if tonumber(universeId) == nil then return false, "Universe ID tidak valid" end

	local requestData = {
		Url = "https://apis.roblox.com/cloud/v2/universes/" .. tostring(universeId),
		Method = method,
		Headers = {
			["x-api-key"] = key,
			["Content-Type"] = "application/json"
		}
	}

	if body then
		requestData.Body = HttpService:JSONEncode(body)
	end

	local success, response = pcall(function()
		return HttpService:RequestAsync(requestData)
	end)

	if not success then return false, tostring(response) end
	if not response.Success then
		return false, "HTTP " .. tostring(response.StatusCode) .. ": " .. tostring(response.StatusMessage)
	end

	return true, response
end

local function updateGameInfo(universeId)
	local id = tonumber(universeId)
	if not id then
		cardGameName.Text = "Universe ID tidak valid"
		return
	end

	if getAPIKey() == "" then
		cardGameName.Text = "Masukkan API Key"
		return
	end

	cardGameName.Text = "Memuat nama game..."

	local success, response = requestUniverse("GET", id)
	if not success then
		cardGameName.Text = "Gagal memuat nama"
		return
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)

	if not ok or type(data) ~= "table" then
		cardGameName.Text = "Data tidak valid"
		return
	end

	cardGameName.Text = data.displayName or data.name or ("Universe " .. tostring(id))
end

local function makeSmallButton(x, y, textValue, callback)
	local button = create("TextButton", {
		Size = UDim2.new(0, 70, 0, 26),
		Position = UDim2.new(0, x, 0, y),
		BackgroundColor3 = Color3.fromRGB(0, 130, 200),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Text = textValue,
		Font = Enum.Font.GothamBold,
		TextSize = 12
	}, main)
	corner(button, 6)
	button.MouseButton1Click:Connect(callback)
	return button
end

local CONFIG_FILE = "Delta_VoicePro_Config.txt"

local function readConfig()
	if not readfile then return nil end
	local ok, data = pcall(function()
		return readfile(CONFIG_FILE)
	end)
	return ok and data or nil
end

local function writeConfig(data)
	if not writefile then return false end
	return pcall(function()
		writefile(CONFIG_FILE, data)
	end)
end

makeSmallButton(6, 238, "Muat", function()
	local raw = readConfig()
	if not raw then
		setStatus("File konfigurasi tidak ada.", "info")
		return
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)

	if not ok or type(data) ~= "table" then
		setStatus("Format konfigurasi rusak.", "error")
		return
	end

	universeBox.Text = data.UniverseID or ""
	placeBox.Text = data.PlaceID or ""
	updateGameInfo(universeBox.Text)
	setStatus("Konfigurasi dimuat.", "success")
end)

makeSmallButton(82, 238, "Simpan", function()
	local data = {
		UniverseID = universeBox.Text,
		PlaceID = placeBox.Text
	}

	if writeConfig(HttpService:JSONEncode(data)) then
		setStatus("Konfigurasi tersimpan.", "success")
	else
		setStatus("Gagal menyimpan konfigurasi.", "error")
	end
end)

local enableBtn = create("TextButton", {
	Name = "Enable",
	Size = UDim2.new(0, 125, 0, 34),
	Position = UDim2.new(0, 6, 0, 270),
	BackgroundColor3 = Color3.fromRGB(0, 160, 70),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Text = "AKTIFKAN",
	Font = Enum.Font.GothamBold,
	TextSize = 13
}, main)
corner(enableBtn, 8)

local disableBtn = create("TextButton", {
	Name = "Disable",
	Size = UDim2.new(0, 125, 0, 34),
	Position = UDim2.new(0, 140, 0, 270),
	BackgroundColor3 = Color3.fromRGB(200, 50, 50),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	BorderSizePixel = 0,
	Text = "NONAKTIFKAN",
	Font = Enum.Font.GothamBold,
	TextSize = 13
}, main)
corner(disableBtn, 8)

enableBtn.MouseButton1Click:Connect(function()
	if isProcessing then
		setStatus("Proses sedang berjalan...", "process")
		return
	end

	local universeId = universeBox.Text
	if universeId == "" then
		setStatus("Universe ID belum diisi.", "error")
		return
	end

	if getAPIKey() == "" then
		setStatus("API Key belum diisi.", "error")
		return
	end

	startAnim()
	setStatus("Mengirim permintaan...", "process")

	local success, response = requestUniverse("PATCH", universeId, {
		voice_chat_enabled = true
	})

	stopAnim()

	if success then
		setStatus("Permintaan berhasil dikirim.", "success")
	else
		setStatus("Gagal: " .. tostring(response), "error")
	end
end)

disableBtn.MouseButton1Click:Connect(function()
	if isProcessing then
		setStatus("Proses sedang berjalan...", "process")
		return
	end

	local universeId = universeBox.Text
	if universeId == "" then
		setStatus("Universe ID belum diisi.", "error")
		return
	end

	if getAPIKey() == "" then
		setStatus("API Key belum diisi.", "error")
		return
	end

	startAnim()
	setStatus("Mengirim permintaan...", "process")

	local success, response = requestUniverse("PATCH", universeId, {
		voice_chat_enabled = false
	})

	stopAnim()

	if success then
		setStatus("Permintaan berhasil dikirim.", "success")
	else
		setStatus("Gagal: " .. tostring(response), "error")
	end
end)

universeBox.FocusLost:Connect(function()
	updateGameInfo(universeBox.Text)
end)

apiBox.FocusLost:Connect(function()
	updateGameInfo(universeBox.Text)
end)

closeBtn.MouseButton1Click:Connect(function()
	stopAnim()
	gui:Destroy()
end)

if universeBox.Text ~= "" then
	task.spawn(function()
		updateGameInfo(universeBox.Text)
	end)
else
	cardGameName.Text = "Masukkan Universe ID"
end
