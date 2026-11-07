--[[ ================================================================
  ScriptRobloxFull — DIST BUILD (REVISED v11)
  REVISI v12c:
  1. Ambil Terdekat: tetap (skip underfoot + depan Ava) — JANGAN DIUBAH
  2. Spam Item: Z aktif lagi di desktop; HP murni tanpa VIM + ForceDrop reparent
  3. Drop: DoDropFurniture (Z + DropItemEvent + weld putus + parent ke world)
================================================================ ]]

-- ================================================================
-- BAGIAN A — LOADER / LICENSE GATE
-- ================================================================
local API_URL = "https://srf-api.obhkomixsachet1.workers.dev"
local HEARTBEAT_INTERVAL = 300
local DEVICE_FILE = "srf_device.id"
local KEY_FILE    = "srf_key.dat"

-- Link tombol AMBIL KEY:
local KEY_LINK = "https://yourscript-v8.pages.dev/harga-promo/"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

----------------------------------------------------------------
local function HttpPost(url, body)
	local payload = HttpService:JSONEncode(body or {})
	local ok, res
	if syn and syn.request then
		ok, res = pcall(syn.request, { Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" }, Body = payload })
		if ok and res then return res.StatusCode, res.Body end
	elseif request then
		ok, res = pcall(request, { Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" }, Body = payload })
		if ok and res then return res.StatusCode, res.Body end
	elseif http_request then
		ok, res = pcall(http_request, { Url = url, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" }, Body = payload })
		if ok and res then return res.StatusCode, res.Body end
	end
	ok, res = pcall(function() return HttpService:PostAsync(url, payload, Enum.HttpContentType.ApplicationJson) end)
	if ok then return 200, res end
	return nil, tostring(res)
end

local function HttpGet(url)
	if syn and syn.request then
		local r = syn.request({ Url = url, Method = "GET" }); return r.StatusCode, r.Body
	elseif request then
		local r = request({ Url = url, Method = "GET" }); return r.StatusCode, r.Body
	elseif http_request then
		local r = http_request({ Url = url, Method = "GET" }); return r.StatusCode, r.Body
	end
	local ok, res = pcall(function() return HttpService:GetAsync(url) end)
	if ok then return 200, res end
	return nil, tostring(res)
end

----------------------------------------------------------------
local function GetDeviceID()
	local ok, id = pcall(function() return readfile(DEVICE_FILE) end)
	if ok and id and #id > 8 then return id end
	id = "DEV-" .. HttpService:GenerateGUID(false)
	local okW = pcall(function() writefile(DEVICE_FILE, id) end)
	if not okW then id = "DEV-U" .. tostring(LP.UserId) end
	return id
end

local function SaveKey(key) pcall(function() writefile(KEY_FILE, key) end) end
local function LoadKey()
	local ok, k = pcall(function() return readfile(KEY_FILE) end)
	if ok then return k end return nil
end
local function ClearKey() pcall(function() delfile(KEY_FILE) end) end

----------------------------------------------------------------
local function MapError(err)
	local map = {
		INVALID_KEY       = "Key tidak ditemukan. Cek lagi key Anda.",
		USER_MISMATCH     = "Key ini terikat ke User ID lain. 1 Key = 1 User ID!",
		DEVICE_MISMATCH   = "Key terikat ke device lain. Hubungi admin untuk reset device.",
		KEY_IN_USE        = "KEY SEDANG DIPAKAI orang lain! Tunggu ±2 menit lalu coba lagi.",
		LICENSE_EXPIRED   = "License Anda sudah expired. Perpanjang untuk lanjut.",
		LICENSE_REVOKED   = "License Anda dicabut oleh admin.",
		LICENSE_BANNED    = "License Anda diblokir.",
		KEY_ALREADY_BOUND = "Key sudah terikat ke akun lain.",
		RATE_LIMITED      = "Terlalu banyak request. Tunggu beberapa saat.",
		LICENSE_NOT_ACTIVE= "License belum aktif.",
		BAD_RESPONSE      = "Response server tidak valid.",
		NETWORK_ERROR     = "Gagal terhubung ke server. Cek internet Anda.",
	}
	return map[err] or ("Error: " .. tostring(err))
end

----------------------------------------------------------------
local function NewGateGui(name)
	local g = Instance.new("ScreenGui")
	g.Name = name; g.ResetOnSpawn = false; g.DisplayOrder = 999
	pcall(function() g.Parent = gethui and gethui() or game:GetService("CoreGui") end)
	if not g.Parent then g.Parent = LP:WaitForChild("PlayerGui") end
	return g
end

local function CopyToClipboard(text)
	if not pcall(function() toclipboard(text) end) then
		pcall(function() setclipboard(text) end)
	end
end

local function GateResult(title, msg, color)
	local g = NewGateGui("SRF_Gate")
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(0.5, 0, 0.5, 0)
	f.Size = UDim2.new(0, 380, 0, 170)
	f.BackgroundColor3 = Color3.fromRGB(16, 19, 28); f.BorderSizePixel = 0; f.Parent = g
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = f
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = 1.5; s.Parent = f
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -20, 0, 34); t.Position = UDim2.new(0, 10, 0, 18)
	t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = color
	t.TextSize = 18; t.Font = Enum.Font.GothamBlack; t.Parent = f
	local m = Instance.new("TextLabel")
	m.Size = UDim2.new(1, -40, 1, -80); m.Position = UDim2.new(0, 20, 0, 56)
	m.BackgroundTransparency = 1; m.Text = msg; m.TextColor3 = Color3.fromRGB(240, 244, 255)
	m.TextSize = 13; m.Font = Enum.Font.Gotham; m.TextWrapped = true; m.Parent = f
	task.delay(6, function() g:Destroy() end)
	return g
end

----------------------------------------------------------------
local function GateInputBox(detectedUserId, onSubmit)
	local g = NewGateGui("SRF_GateInput")
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(0.5, 0, 0.5, 0)
	f.Size = UDim2.new(0, 400, 0, 262)
	f.BackgroundColor3 = Color3.fromRGB(16, 19, 28); f.BorderSizePixel = 0; f.Parent = g
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = f
	local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(0, 210, 255); s.Thickness = 1.5; s.Parent = f

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -20, 0, 22); t.Position = UDim2.new(0, 10, 0, 12)
	t.BackgroundTransparency = 1; t.Text = "YOURSCRIPT — ACTIVATE LICENSE"
	t.TextColor3 = Color3.fromRGB(0, 210, 255); t.TextSize = 15
	t.Font = Enum.Font.GothamBlack; t.Parent = f

	local uidLbl = Instance.new("TextLabel")
	uidLbl.Size = UDim2.new(1, -40, 0, 14); uidLbl.Position = UDim2.new(0, 20, 0, 36)
	uidLbl.BackgroundTransparency = 1; uidLbl.Text = "USER ID ROBLOX:"
	uidLbl.TextColor3 = Color3.fromRGB(130, 140, 165); uidLbl.TextSize = 10
	uidLbl.Font = Enum.Font.GothamBold; uidLbl.TextXAlignment = Enum.TextXAlignment.Left
	uidLbl.Parent = f

	local uidBox = Instance.new("TextBox")
	uidBox.Size = UDim2.new(1, -40, 0, 30); uidBox.Position = UDim2.new(0, 20, 0, 50)
	uidBox.BackgroundColor3 = Color3.fromRGB(34, 40, 56); uidBox.Text = detectedUserId
	uidBox.TextColor3 = Color3.fromRGB(46, 200, 110)
	uidBox.PlaceholderText = "contoh: 123456789"
	uidBox.PlaceholderColor3 = Color3.fromRGB(130, 140, 165)
	uidBox.TextSize = 13; uidBox.Font = Enum.Font.GothamBold
	uidBox.ClearTextOnFocus = false; uidBox.Parent = f
	local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0, 8); uc.Parent = uidBox

	local uidNote = Instance.new("TextLabel")
	uidNote.Size = UDim2.new(1, -40, 0, 13); uidNote.Position = UDim2.new(0, 20, 0, 80)
	uidNote.BackgroundTransparency = 1
	uidNote.Text = "1 Key hanya untuk 1 User ID — ganti game/server tetap bisa!"
	uidNote.TextColor3 = Color3.fromRGB(255, 160, 50); uidNote.TextSize = 9
	uidNote.Font = Enum.Font.Gotham; uidNote.TextXAlignment = Enum.TextXAlignment.Left
	uidNote.Parent = f

	local keyLbl = Instance.new("TextLabel")
	keyLbl.Size = UDim2.new(1, -40, 0, 14); keyLbl.Position = UDim2.new(0, 20, 0, 96)
	keyLbl.BackgroundTransparency = 1; keyLbl.Text = "LICENSE KEY:"
	keyLbl.TextColor3 = Color3.fromRGB(130, 140, 165); keyLbl.TextSize = 10
	keyLbl.Font = Enum.Font.GothamBold; keyLbl.TextXAlignment = Enum.TextXAlignment.Left
	keyLbl.Parent = f

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -40, 0, 32); box.Position = UDim2.new(0, 20, 0, 109)
	box.BackgroundColor3 = Color3.fromRGB(34, 40, 56)
	box.TextColor3 = Color3.fromRGB(240, 244, 255)
	box.PlaceholderText = "SRF-XXXXXX-XXXXX-XXXXX"
	box.PlaceholderColor3 = Color3.fromRGB(130, 140, 165)
	box.TextSize = 14; box.Font = Enum.Font.GothamBold
	box.ClearTextOnFocus = false; box.Text = ""; box.Parent = f
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = box

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -40, 0, 32); btn.Position = UDim2.new(0, 20, 0, 136)
	btn.BackgroundColor3 = Color3.fromRGB(0, 210, 255)
	btn.Text = "ACTIVATE"; btn.TextColor3 = Color3.fromRGB(8, 12, 20)
	btn.TextSize = 14; btn.Font = Enum.Font.GothamBold; btn.Parent = f
	local bnc = Instance.new("UICorner"); bnc.CornerRadius = UDim.new(0, 8); bnc.Parent = btn

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -40, 0, 13); hint.Position = UDim2.new(0, 20, 0, 172)
	hint.BackgroundTransparency = 1
	hint.Text = "Belum punya key? Klik tombol di bawah:"
	hint.TextColor3 = Color3.fromRGB(130, 140, 165); hint.TextSize = 10
	hint.Font = Enum.Font.Gotham; hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = f

	local err = Instance.new("TextLabel")
	err.Size = UDim2.new(1, -40, 0, 16); err.Position = UDim2.new(0, 20, 0, 206)
	err.BackgroundTransparency = 1; err.Text = ""
	err.TextColor3 = Color3.fromRGB(230, 70, 80); err.TextSize = 11
	err.Font = Enum.Font.GothamBold; err.Parent = f

	local keyBtn = Instance.new("TextButton")
	keyBtn.Size = UDim2.new(1, -40, 0, 28); keyBtn.Position = UDim2.new(0, 20, 0, 224)
	keyBtn.BackgroundColor3 = Color3.fromRGB(0, 210, 255)
	keyBtn.Text = "AMBIL KEY"; keyBtn.TextColor3 = Color3.fromRGB(8, 12, 20)
	keyBtn.TextSize = 12; keyBtn.Font = Enum.Font.GothamBold; keyBtn.Parent = f
	local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0, 8); kc.Parent = keyBtn

	keyBtn.MouseButton1Click:Connect(function()
		CopyToClipboard(KEY_LINK)
		err.TextColor3 = Color3.fromRGB(46, 200, 110)
		err.Text = "Link dicopy — paste di browser"
	end)

	local submitting = false
	local function Submit()
		if submitting then return end
		local key = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
		local uid = uidBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		err.TextColor3 = Color3.fromRGB(230, 70, 80)
		if #uid < 3 or not tonumber(uid) then
			err.Text = "User ID tidak valid (harus angka)"; return
		end
		if #key < 5 then err.Text = "Key tidak valid"; return end
		submitting = true
		btn.Text = "CHECKING..."; btn.Active = false
		task.spawn(function()
			onSubmit(key, uid, err, function(newText)
				btn.Text = "ACTIVATE"; btn.Active = true
				err.Text = newText or ""
				submitting = false
			end)
		end)
	end
	btn.MouseButton1Click:Connect(Submit)
	box.FocusLost:Connect(function(ep) if ep then Submit() end end)
end

----------------------------------------------------------------
local function ApiActivate(key, userId, deviceId)
	local code, body = HttpPost(API_URL .. "/activate", {
		key = key, user_id = userId, device_id = deviceId,
	})
	if not code then return { success = false, error = "NETWORK_ERROR" } end
	local okD, data = pcall(HttpService.JSONDecode, HttpService, body or "{}")
	if not okD then return { success = false, error = "BAD_RESPONSE" } end
	return data
end

local function ApiCheck(key, userId, deviceId)
	local code, body = HttpGet(API_URL ..
		("/check?key=%s&user_id=%s&device_id=%s"):format(
			HttpService:UrlEncode(key), HttpService:UrlEncode(userId), HttpService:UrlEncode(deviceId)))
	if not code then return { success = false, error = "NETWORK_ERROR" } end
	local okD, data = pcall(HttpService.JSONDecode, HttpService, body or "{}")
	if not okD then return { success = false, error = "BAD_RESPONSE" } end
	return data
end

local function IsSuccess(res)
	return res.success == true or res.ok or res.status == "active" or res.already_active or res.valid
end

----------------------------------------------------------------
-- PANEL RUNNER — isi panel di-embed di sini, HANYA jalan setelah license valid
----------------------------------------------------------------
local function RunPanel()
--[[
================================================================
  ScriptRobloxFull PREMIUM PANEL  +  dangerousnight.lua (MERGED)
  Dangerous Night (Malam Yang Berbahaya) Utility
  Premium Edition — Modular · Clean · Configurable
  [MERGED] Semua fitur script asli dangerousnight.lua ditambahkan,
           tanpa menghilangkan fitur manapun dari kedua script.
================================================================
]]

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local Config = {
	Panel = {
		Name = "YOURSCRIPTPanel",
		Title = "YOURSCRIPT",
		Subtitle = "Dangerous Night Utility",
		Edition = "Premium Edition",
		Width = 340,
		Height = 480,
		PosX = 18,
		PosYScale = 0.5,
		PosYOffset = -240,
		Corner = 18,
		Transparency = 0.12,
		Drag = true,
	},
	Theme = {
		Bg        = Color3.fromRGB(11, 13, 17),
		Panel     = Color3.fromRGB(20, 23, 29),
		Panel2    = Color3.fromRGB(27, 31, 39),
		Panel3    = Color3.fromRGB(36, 42, 52),
		Active    = Color3.fromRGB(46, 54, 68),   -- glass terangkat (tab aktif)
		Accent    = Color3.fromRGB(56, 189, 248),
		Accent2   = Color3.fromRGB(14, 116, 184),
		Green     = Color3.fromRGB(45, 212, 191),
		Red       = Color3.fromRGB(251, 113, 133),
		Orange    = Color3.fromRGB(251, 146, 60),
		Purple    = Color3.fromRGB(167, 139, 250),
		Yellow    = Color3.fromRGB(251, 191, 36),
		Text      = Color3.fromRGB(243, 244, 246),
		Sub       = Color3.fromRGB(161, 167, 179),
		Line      = Color3.fromRGB(36, 42, 52),
		Stroke    = Color3.fromRGB(205, 214, 232),
		StrokeT   = 0.35,
	},
	Anim = {
		Tween = 0.30,
		Notif = 0.50,
		Slide = 0.50,
		Pop   = 0.28,
	},
	Font = {
		Title = Enum.Font.GothamBlack,
		Bold  = Enum.Font.GothamBold,
		Reg   = Enum.Font.Gotham,
	},
	Movement = {
		SpeedMin = 0.1, -- bisa slowmo (0.1x) sampai lari cepat (50x)
		SpeedMax = 50,
		SpeedDefault = 2,
		FlySpeed = 80,
	},
	FlyPad = {
		-- [FLY PAD] tombol ▲ / ▼ untuk Fly (muncul otomatis di mobile)
		Side = "left",     -- "left" = sebelah kiri, "right" = sebelah kanan
		PosX = 24,         -- jarak dari sisi kiri/kanan (pixel)
		PosY = 1,          -- posisi vertikal (0 = atas, 0.5 = tengah, 1 = bawah)
		PosYOffset = -40,  -- geser vertikal tambahan (pixel)
		Gap = 10,          -- jarak antar tombol (pixel)
		Size = 56,         -- ukuran tombol (pixel)
		Draggable = true,  -- bisa digeser langsung (tahan handle ✥ lalu geser)
	},
	ESP = {
		MaxDist = 2000,
		-- ANTI-LAG (B): 0.25 = 4x per detik. Jangan di bawah 0.25 (tiap frame = lag).
		UpdateRate = 0.85,
		Colors = {
			Common    = Color3.fromRGB(180, 180, 180),
			Uncommon  = Color3.fromRGB(80, 200, 100),
			Rare      = Color3.fromRGB(60, 140, 255),
			Epic      = Color3.fromRGB(180, 80, 255),
			Legendary = Color3.fromRGB(255, 180, 40),
			Monster   = Color3.fromRGB(255, 60, 60),
			Player    = Color3.fromRGB(0, 210, 255),
			Item      = Color3.fromRGB(255, 220, 100),
		},
	},
	Keybind = {
		TogglePanel=nil, Speed=nil, Fly=nil, Noclip=nil, InfJump=nil,
		Fullbright=nil, NoFog=nil, TPBunker=nil, TPMarket=nil, TPRare=nil,
		ReturnPos=nil, SavePos=nil, CageMonster=nil, AutoCage=nil, FreezeMonster=nil,
		AntiAFK=nil, FPSBoost=nil, ClickTP=nil, PrevPlayer=nil, NextPlayer=nil,
		TPPlayer=nil, Spectate=nil, ItemESP=nil, MonsterESP=nil, PlayerESP=nil,
		Rejoin=nil, ServerHop=nil, HidePanel=nil,
	},
	Keywords = {
		Bunker  = {"bunker", "shelter", "base", "home"},
		Market  = {"mart", "market", "six", "toko", "store"},
		Rare    = {"rare", "warehouse", "gudang", "secret", "backroom", "hidden", "langka", "magazyn", "magazine", "marketwyposazenie", "storage", "depo", "depot", "vault", "mebelki", "beauty", "gaming", "halloween", "christmas", "beanbag", "bean bag", "table8", "warehouseshelves"},
		Monster = {"monster", "zombie", "enemy", "creature", "hantu", "pocong",
			"genderuwo", "killer", "hunter", "beast", "mutan", "npc", "night"},
		Item    = {"item", "loot", "crate", "box", "supply", "food", "water",
			"furniture", "table", "chair", "bed", "sofa", "cabinet", "meja",
			"kursi", "can", "ammo", "weapon", "med", "bandage", "material",
			-- [BARU] perbaiki deteksi yang sering "tidak ditemukan"
			"lemari", "almari", "almiri", "cupboard", "cabinet", "drawer",
			"rak", "almari pakaian", "kabinet", "dresser", "couch"},
		-- [BARU] AREA FILTER — untuk ambil jarak jauh (market saja, kecuali bunker)
		Area    = {
			Market = {"mart", "six", "minimarket", "toko", "store", "market", "sklep", "sklepy", "shops", "shop", "mart6", "sixmart", "minimart", "pasar", "mall", "plaza", "kantin", "warung", "outlet"},
			Bunker = {"bunker", "shelter", "base", "home", "dom", "baza", "hideout", "safehouse", "hq", "camp", "kuartir", "rumah"},
		},
		Pickup  = {"pick", "grab", "take", "collect", "loot", "claim", "interact", "ambil"},
	},
}

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Services = {
	Players    = game:GetService("Players"),
	WS         = game:GetService("Workspace"),
	RS         = game:GetService("RunService"),
	UIS        = game:GetService("UserInputService"),
	TS         = game:GetService("TweenService"),
	Lighting   = game:GetService("Lighting"),
	CG         = game:GetService("CoreGui"),
	VU         = game:GetService("VirtualUser"),
	Http       = game:GetService("HttpService"),
	Teleport   = game:GetService("TeleportService"),
	Stats      = game:GetService("Stats"),
	Rep        = game:GetService("ReplicatedStorage"),
}

local LP = Services.Players.LocalPlayer
local Mouse = LP:GetMouse()

----------------------------------------------------------------
-- STATE / VARIABLES
----------------------------------------------------------------
local State = {
	SpeedOn = false,
	SpeedMul = Config.Movement.SpeedDefault,
	BaseSpeed = nil,
	FlyOn = false,
	NoclipOn = false,
	InfJumpOn = false,
	FullbrightOn = false,
	NoFogOn = false,
	ItemESP = false,
	MonsterESP = false,
	PlayerESP = false,
	Tracers = false,
	DistESP = true,
	NameESP = true,
	Chams = false,
	ItemList = {},          -- daftar nama item unik (dipakai Teleport + Farming)
	ItemName = nil,        -- item yang sedang dipilih untuk TP / Ambil
	PlaceList = {},        -- daftar nama place unik (dipakai Teleport)
	PlaceName = nil,       -- place yang sedang dipilih untuk TP Place
	FlyUp = false,          -- kontrol touch fly mobile
	FlyDown = false,
	FlyMoveX = 0,   -- input analog: kanan(+)/kiri(-), 0..1
	FlyMoveY = 0,   -- input analog: maju(+)/mundur(-), 0..1
	AutoMaterial = false,
	AutoCrate = false,
	AutoReturn = false,
	MonsterAlert = false,
	MonsterTracker = false,
	CageOn = false,
	AutoCage = false,
	FreezeOn = false,
	NoGrass = false,
	NoShadow = false,
	UltraHD = false,
	ZoomUnlock = false,
	FreeCam = false,
	WeatherRain = false,
	WeatherFlood = false,
	WeatherSnow = false,
	SpectateOn = false,
	PlayerTracker = false,
	_mobSpawnDetect = false,
	-- [MERGED] state dari dangerousnight.lua
	SoundSpam = false,
	SpamItemOn = false, -- SPAM ITEM: loop TP-berkeliling ambil item market
	MarketOnly = false, -- SPAM: hanya MarketWyposazenie + Magazine + Market
	SpamMarks = {}, -- multi-mark nama item untuk spam berurutan
	DropPoints = {}, -- multi titik drop saat spam (CFrame list)
	DropPointIdx = 1,
	PendingRespawnPos = nil, -- posisi pulang setelah Drop All Food (bunuh diri)
	PanelVisible = true,
	SavedPos = nil,
	TargetIdx = 1,
	Target = nil,
	SpectateTarget = nil,
	-- [GRIEF]
	GriefExplosion = false,
	GriefParticle = false,
	GriefDecal = false,
	GriefChat = false,
	FloatOn=false, SpinOn=false, SpinSpeed=12, NoGravityOn=false, BaseGravity=196.2,
	XrayOn=false, InvisibleOn=false, AntiFlingOn=false, StalkOn=false, StareOn=false,
	InstantPromptOn=false, Waypoints={}, FlySpeedVal=80,
	AttachOn=false, AttachMode="backpack",
	AimbotOn=false, AimbotFOV=180, AimbotSmooth=0.25, AimbotPart="Head",
	HitboxOn=false, HitboxSize=8, ReachOn=false, ReachSize=12,
	FakeLagOn=false, FakeLagMs=120, ClickFlingOn=false,
	OrbitOn=false, OrbitRadius=8, OrbitSpeed=2,
	GodModeOn=false, MagnetizeOn=false, MagnetizeTarget="",
	CharLightOn=false, SpinFlingOn=false, HiddenFlingOn=false, TouchFlingOn=false,
	TouchFlingPower=5, NPCControlOn=false, WordBotOn=false,
}

local Conn = {}          -- all connections for cleanup
local FlyParts = {}
local CageData = {}
local PlankPool = {}
local ESPFolder = nil
local ESPCache = {}
local UI = {}            -- UI refs
local ToggleFns = {}     -- name -> {set, get, enable, disable}
local NotifQueue = {}

----------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------
local Util = {}

function Util.Root(p)
	p = p or LP
	local c = p.Character
	if not c then return nil end
	return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c.PrimaryPart
end

function Util.Hum(p)
	p = p or LP
	local c = p.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

function Util.Char(p)
	return (p or LP).Character
end

function Util.Tween(obj, props, t, style, dir)
	local ti = TweenInfo.new(
		t or Config.Anim.Tween,
		style or Enum.EasingStyle.Quart,
		dir or Enum.EasingDirection.Out
	)
	local tw = Services.TS:Create(obj, ti, props)
	tw:Play()
	return tw
end

function Util.FadeIn(obj, t)
	if not obj then return end
	pcall(function()
		obj.BackgroundTransparency = 1
		Util.Tween(obj, { BackgroundTransparency = obj:GetAttribute("SRF_BT") or 0.12 }, t or Config.Anim.Tween)
	end)
end

function Util.PopIn(obj, t)
	if not obj or not obj:IsA("GuiObject") then return end
	pcall(function()
		local goal = obj.Size
		obj.Size = UDim2.new(goal.X.Scale, math.floor(goal.X.Offset * 0.94), goal.Y.Scale, math.floor(goal.Y.Offset * 0.94))
		obj.BackgroundTransparency = 1
		Util.Tween(obj, { Size = goal, BackgroundTransparency = obj:GetAttribute("SRF_BT") or 0.12 }, t or Config.Anim.Pop or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local st = obj:FindFirstChildOfClass("UIStroke")
		if st then
			local gt = st.Transparency
			st.Transparency = 1
			Util.Tween(st, { Transparency = gt }, (t or 0.18) * 1.1)
		end
	end)
end

-- Transisi glass AR: scale + fade + soft edge light
function Util.GlassIn(obj, goalSize, t)
	if not obj or not obj:IsA("GuiObject") then return end
	t = t or 0.52
	pcall(function()
		local gs = goalSize or obj.Size
		local ox, oy = gs.X.Offset, gs.Y.Offset
		if ox < 10 then ox = 320 end
		if oy < 10 then oy = 400 end
		obj.Visible = true
		obj.Size = UDim2.new(gs.X.Scale, math.floor(ox * 0.95), gs.Y.Scale, math.floor(oy * 0.95))
		obj.BackgroundTransparency = 1
		local st = obj:FindFirstChildOfClass("UIStroke")
		if st then st.Transparency = 1 end
		local shine = obj:FindFirstChild("SRF_GlassShine")
		if not shine then
			shine = Instance.new("Frame")
			shine.Name = "SRF_GlassShine"
			shine.Size = UDim2.new(0.55, 0, 0, 1)
			shine.Position = UDim2.new(0.225, 0, 0, 0)
			shine.BackgroundColor3 = Color3.fromRGB(210, 220, 255)
			shine.BackgroundTransparency = 1
			shine.BorderSizePixel = 0
			shine.ZIndex = (obj.ZIndex or 1) + 6
			shine.Parent = obj
			local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1, 0); sc.Parent = shine
		end
		Util.Tween(obj, {
			Size = UDim2.new(gs.X.Scale, ox, gs.Y.Scale, oy),
			BackgroundTransparency = obj:GetAttribute("SRF_BT") or 0.1,
		}, t, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
		if st then
			Util.Tween(st, { Transparency = 0.7, Thickness = 1.25 }, t * 0.95, Enum.EasingStyle.Quint)
		end
		Util.Tween(shine, { BackgroundTransparency = 0.25 }, t * 0.55)
		task.delay(t * 0.75, function()
			if shine and shine.Parent then Util.Tween(shine, { BackgroundTransparency = 0.82 }, 0.55) end
		end)
	end)
end

function Util.GlassOut(obj, t, onDone)
	if not obj or not obj:IsA("GuiObject") then if onDone then onDone() end return end
	t = t or 0.32
	pcall(function()
		local cur = obj.Size
		local st = obj:FindFirstChildOfClass("UIStroke")
		local shine = obj:FindFirstChild("SRF_GlassShine")
		Util.Tween(obj, {
			Size = UDim2.new(cur.X.Scale, math.floor(cur.X.Offset * 0.94), cur.Y.Scale, math.floor(cur.Y.Offset * 0.94)),
			BackgroundTransparency = 1,
		}, t, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		if st then Util.Tween(st, { Transparency = 1 }, t * 0.85) end
		if shine then Util.Tween(shine, { BackgroundTransparency = 1 }, t * 0.45) end
		task.delay(t, function()
			if obj and obj.Parent then obj.Visible = false end
			-- restore size so next open works
			pcall(function()
				if obj and obj.Parent and cur then obj.Size = cur end
			end)
			if onDone then onDone() end
		end)
	end)
end


function Util.Connect(name, signal, fn)
	if Conn[name] then
		pcall(function() Conn[name]:Disconnect() end)
	end
	Conn[name] = signal:Connect(fn)
	return Conn[name]
end

function Util.Disconnect(name)
	if Conn[name] then
		pcall(function() Conn[name]:Disconnect() end)
		Conn[name] = nil
	end
end

function Util.DisconnectAll()
	for k, c in pairs(Conn) do
		pcall(function() c:Disconnect() end)
		Conn[k] = nil
	end
end

function Util.Safe(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then warn("[YOURSCRIPT] " .. tostring(err)) end
	return ok, err
end

local _wsCache, _wsCacheAt = nil, 0
function Util.GetWS()
	local now = os.clock()
	-- ANTI-LAG: cache 1 detik (bukan 0.45) — ESP jalan 4x/detik jadi 1 scan melayani ~4 tick.
	if not _wsCache or (now - _wsCacheAt) > 1.0 then
		_wsCache = Services.WS:GetDescendants()
		_wsCacheAt = now
	end
	return _wsCache
end

function Util.FindByKeywords(keywords, root)
	local list = root and root:GetDescendants() or Util.GetWS()
	for _, o in ipairs(list) do
		local n = string.lower(o.Name)
		for _, kw in ipairs(keywords) do
			if n:find(kw, 1, true) then
				local part
				if o:IsA("BasePart") then
					part = o
				elseif o:IsA("Model") then
					part = o.PrimaryPart or o:FindFirstChildOfClass("BasePart")
				end
				if part then return part, o end
			end
		end
	end
	return nil, nil
end

-- [MERGED] dari dangerousnight.lua: cek apakah model berada di dalam folder "Night"
function Util.InNightFolder(model)
	local a = model
	while a do
		if a:IsA("Folder") and string.find(string.lower(a.Name), "night", 1, true) then
			return true
		end
		a = a.Parent
	end
	return false
end

-- [BARU] cek apakah instance berada di dalam area tertentu (nama ancestor)
function Util.InArea(o, kws)
	local a = o
	while a and a ~= Services.WS do
		local n = string.lower(a.Name or "")
		for _, kw in ipairs(kws) do
			if n:find(kw, 1, true) then return true end
		end
		a = a.Parent
	end
	return false
end

function Util.IsMonster(model)
	if not model or not model:IsA("Model") then return false end
	if Services.Players:GetPlayerFromCharacter(model) then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	local nm = string.lower(model.Name)
	for _, kw in ipairs(Config.Keywords.Monster) do
		if nm:find(kw, 1, true) then
			if hum and hum.Health > 0 then return true end
			break
		end
	end
	-- [MERGED] mekanik asli dangerousnight: semua model di folder "Night" = monster
	if Util.InNightFolder(model) then
		if model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildOfClass("BasePart") or model.PrimaryPart then
			return true
		end
	end
	return false
end

function Util.IsItem(obj)
	if not obj then return false end
	if obj:IsA("Model") and Services.Players:GetPlayerFromCharacter(obj) then return false end
	if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return false end
	local nm = string.lower(obj.Name)
	for _, kw in ipairs(Config.Keywords.Item) do
		if nm:find(kw, 1, true) then return true end
	end
	return false
end

function Util.RarityColor(name)
	local n = string.lower(name or "")
	local C = Config.ESP.Colors
	if n:find("legend") or n:find("mythic") then return C.Legendary end
	if n:find("epic") or n:find("rare") then return C.Epic end
	if n:find("uncommon") then return C.Uncommon end
	if n:find("common") then return C.Common end
	return C.Item
end

function Util.GetPlayers()
	local t = {}
	for _, p in ipairs(Services.Players:GetPlayers()) do
		if p ~= LP then table.insert(t, p) end
	end
	return t
end

function Util.Corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or Config.Panel.Corner)
	c.Parent = parent
	return c
end

function Util.Stroke(parent, color, thick, trans)
	local s = Instance.new("UIStroke")
	s.Color = color or Config.Theme.Stroke
	s.Thickness = thick or 1.2
	s.Transparency = trans or Config.Theme.StrokeT
	s.Parent = parent
	return s
end

function Util.Pad(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.Parent = parent
	return p
end

function Util.List(parent, pad)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, pad or 6)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end

----------------------------------------------------------------
-- [GLASS SKIN] Bevel & Emboss — PRESENTATION ONLY
-- Hanya menambah lapisan dekoratif (non-interaktif) di komponen GUI yang
-- sudah ada. Tidak menyentuh fitur, logika, event, remote, atau state.
-- Cahaya virtual dari kiri-atas: tepi atas/kiri terang, bawah/kanan gelap.
----------------------------------------------------------------
local Glass = {}
local GN = "SRFGlass"
local G_WHITE = Color3.fromRGB(255, 255, 255)
local G_BLACK = Color3.fromRGB(0, 0, 0)
Glass.Edge = Color3.fromRGB(205, 214, 232)

local function gNew(cls, parent, props)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	if o:IsA("GuiObject") then pcall(function() o.Interactable = false end) end
	o.Parent = parent
	return o
end
local function gGrad(parent, rot, col, tr)
	local g = Instance.new("UIGradient")
	g.Rotation = rot
	g.Color = col
	if tr then g.Transparency = tr end
	g.Parent = parent
	return g
end
local function CS(...) return ColorSequence.new({ ... }) end
local function CK(t, c) return ColorSequenceKeypoint.new(t, c) end
local function NS(...) return NumberSequence.new({ ... }) end
local function NK(t, v) return NumberSequenceKeypoint.new(t, math.clamp(v, 0, 1)) end

-- kekuatan bevel per jenis komponen (panel > tab > tombol > baris list)
local GS = {
	major = { top = 0.92, mid = 0.99, bot = 0.82, d = 2, outerT = 0.72, rimT = 0.78, r = 18 },
	tab   = { top = 0.90, mid = 0.97, bot = 0.80, d = 1, outerT = 0.74, rimT = 0.80, r = 12 },
	btn   = { top = 0.91, mid = 0.98, bot = 0.82, d = 1, outerT = 0.74, rimT = 0.80, r = 12 },
	row   = { top = 0.93, mid = 0.98, bot = 0.86, d = 1, outerT = 0.80, rimT = 0.84, r = 10 },
	input = { top = 0.78, mid = 0.97, bot = 0.94, d = 1, outerT = 0.76, rimT = 0.80, r = 10 },
}

local function gFill(s, recessed, boost)
	local b = boost or 0
	if recessed then
		return NS(NK(0, s.top), NK(0.35, 0.90), NK(0.8, 0.985), NK(1, s.bot))
	end
	return NS(NK(0, s.top - b), NK(0.2, s.mid + 0.05 - b), NK(0.55, s.mid), NK(1, s.bot - b * 0.5))
end

local function gLines(obj, rad, w, h, kind)
	local inset = math.max(rad * 0.9, 6)
	if (w > 0 and w < inset * 2 + 8) or h < inset * 2 + 8 then return nil end
	local top = gNew("Frame", obj, {
		Name = GN .. "Top", BackgroundColor3 = G_WHITE, BackgroundTransparency = 0.55,
		BorderSizePixel = 0, Size = UDim2.new(1, -inset * 2, 0, 1),
		Position = UDim2.new(0, inset, 0, 1), ZIndex = obj.ZIndex,
	})
	gGrad(top, 0, CS(CK(0, G_WHITE), CK(1, G_WHITE)),
		NS(NK(0, 1), NK(0.25, 0), NK(0.75, 0), NK(1, 1)))
	return top
end


----------------------------------------------------------------
-- IKON VEKTOR (digambar dari Frame/UIStroke) — pengganti emoji, hanya tampilan
----------------------------------------------------------------
local ICON_BY_TAB = {
	ESP = "radar", Move = "chevrons", TP = "crosshair", Farm = "tool", Mob = "skull",
	Visual = "eye", Player = "user", Util = "gear", Game = "pad", Extra = "sparkle",
	Combat = "swords", Load = "box", Troll = "mask",
}
local ICON_BY_GLYPH = {
	["◎"] = "radar", ["◆"] = "diamond", ["☠"] = "skull", ["💀"] = "skull", ["♟"] = "user",
	["👤"] = "user", ["↔"] = "arrows", ["▣"] = "square", ["⌖"] = "crosshair", ["🎯"] = "crosshair",
	["👁"] = "eye", ["⚙"] = "gear", ["✦"] = "sparkle", ["✨"] = "sparkle", ["💥"] = "sparkle",
	["⚔"] = "swords", ["📦"] = "box", ["🎭"] = "mask", ["👻"] = "mask", ["🎮"] = "pad",
	["⚒"] = "tool", ["»"] = "chevrons", ["🔒"] = "lock", ["⚡"] = "bolt", ["📡"] = "radar",
	["🔍"] = "search", ["⏱"] = "clock", ["📍"] = "pin", ["🛡"] = "square", ["⛓"] = "chain",
}

local function gIconDraw(parent, kind, S, col)
	local u = S / 16
	local th = math.max(1.3, S / 11)
	local items = {}
	local function mk(f)
		f.Name = GN .. "Ic"
		f.BorderSizePixel = 0
		f.Parent = parent
	end
	local function ring(cx, cy, r, fill)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset(cx * u, cy * u)
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f
		if fill then
			f.Size = UDim2.fromOffset(r * 2 * u, r * 2 * u)
			f.BackgroundColor3 = col
			items[#items + 1] = { f, "bg" }
		else
			f.Size = UDim2.fromOffset(math.max(r * 2 * u - th, 1), math.max(r * 2 * u - th, 1))
			f.BackgroundTransparency = 1
			local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th; s.Parent = f
			items[#items + 1] = { s, "stroke" }
		end
		mk(f)
	end
	local function rect(x, y, w, h, r, fill, rot)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset((x + w / 2) * u, (y + h / 2) * u)
		if rot then f.Rotation = rot end
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r * u); c.Parent = f
		if fill then
			f.Size = UDim2.fromOffset(w * u, h * u)
			f.BackgroundColor3 = col
			items[#items + 1] = { f, "bg" }
		else
			f.Size = UDim2.fromOffset(math.max(w * u - th, 1), math.max(h * u - th, 1))
			f.BackgroundTransparency = 1
			local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th; s.Parent = f
			items[#items + 1] = { s, "stroke" }
		end
		mk(f)
	end
	local function line(x1, y1, x2, y2)
		local dx, dy = (x2 - x1) * u, (y2 - y1) * u
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset((x1 + x2) / 2 * u, (y1 + y2) / 2 * u)
		f.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), th)
		f.Rotation = math.deg(math.atan2(dy, dx))
		f.BackgroundColor3 = col
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = f
		items[#items + 1] = { f, "bg" }
		mk(f)
	end

	if kind == "radar" then ring(8, 8, 6.5); ring(8, 8, 3.2); ring(8, 8, 1, true)
	elseif kind == "crosshair" then
		ring(8, 8, 4.5); line(8, 1.5, 8, 4.5); line(8, 11.5, 8, 14.5)
		line(1.5, 8, 4.5, 8); line(11.5, 8, 14.5, 8); ring(8, 8, 0.9, true)
	elseif kind == "eye" then rect(1, 4.5, 14, 7, 3.5); ring(8, 8, 1.8, true)
	elseif kind == "user" then ring(8, 5, 2.8); rect(3, 9.5, 10, 5.5, 3)
	elseif kind == "gear" then
		ring(8, 8, 4.2)
		for i = 0, 7 do
			local a = math.rad(i * 45)
			line(8 + math.cos(a) * 5.6, 8 + math.sin(a) * 5.6, 8 + math.cos(a) * 7.3, 8 + math.sin(a) * 7.3)
		end
		ring(8, 8, 1.2, true)
	elseif kind == "chevrons" then
		line(3, 3.5, 7, 8); line(7, 8, 3, 12.5); line(9, 3.5, 13, 8); line(13, 8, 9, 12.5)
	elseif kind == "skull" then
		ring(8, 7, 5.2); ring(6, 7, 1.1, true); ring(10, 7, 1.1, true); rect(5.5, 11.5, 5, 3.2, 1)
	elseif kind == "swords" then
		line(3, 13, 13, 3); line(13, 13, 3, 3); ring(3, 13, 1.2, true); ring(13, 13, 1.2, true)
	elseif kind == "box" then rect(2.5, 5, 11, 9, 2); line(2.5, 8.5, 13.5, 8.5); line(8, 5, 8, 8.5)
	elseif kind == "pad" then
		rect(1.5, 4.5, 13, 8, 4); line(4.5, 8.5, 7.5, 8.5); line(6, 7, 6, 10)
		ring(10.5, 7.5, 0.9, true); ring(12, 9.5, 0.9, true)
	elseif kind == "sparkle" then
		line(8, 1.5, 8, 14.5); line(1.5, 8, 14.5, 8); line(4, 4, 12, 12); ring(8, 8, 1.4, true)
	elseif kind == "mask" then
		ring(8, 8, 6); ring(5.8, 7, 1, true); ring(10.2, 7, 1, true); line(5.5, 10.5, 10.5, 10.5)
	elseif kind == "tool" then line(3, 13, 10, 6); line(8.5, 3.5, 12.5, 7.5); line(8.5, 3.5, 6, 6)
	elseif kind == "diamond" then rect(4.5, 4.5, 7, 7, 1.2, true, 45)
	elseif kind == "square" then rect(2.5, 2.5, 11, 11, 3); rect(5.5, 5.5, 5, 5, 1, true)
	elseif kind == "arrows" then
		line(2, 8, 14, 8); line(2, 8, 5, 5); line(2, 8, 5, 11); line(14, 8, 11, 5); line(14, 8, 11, 11)
	elseif kind == "lock" then ring(8, 5.8, 3.2); rect(3.2, 7.8, 9.6, 6.8, 1.8, true); ring(8, 10.5, 0.9, true)
	elseif kind == "bolt" then line(9.5, 1.5, 4, 9); line(4, 9, 8.5, 9); line(8.5, 9, 6.5, 14.5); line(6.5, 14.5, 12, 7); line(12, 7, 7.5, 7)
	elseif kind == "search" then ring(7, 7, 4.8); line(10.6, 10.6, 14, 14)
	elseif kind == "clock" then ring(8, 8, 6.5); line(8, 8, 8, 4.5); line(8, 8, 10.5, 9.5)
	elseif kind == "chain" then
		rect(1, 5.5, 8.5, 5, 2.5, false, -35); rect(6.5, 5.5, 8.5, 5, 2.5, false, -35)
	elseif kind == "minus" then rect(3, 7, 10, 2, 1, true)
	elseif kind == "plus" then rect(3, 7, 10, 2, 1, true); rect(7, 3, 2, 10, 1, true)
	elseif kind == "cross" then rect(2.5, 7, 11, 2, 1, true, 45); rect(2.5, 7, 11, 2, 1, true, -45)
	elseif kind == "pin" then ring(8, 6.5, 3.5); line(8, 10, 8, 14.5); ring(8, 6.5, 1, true)
	elseif kind == "rain" then
		ring(5.5, 6, 3.2, true); ring(8.5, 5.2, 3.6, true); ring(11.2, 6.2, 2.8, true)
		rect(4, 6.5, 8.5, 3.2, 1.5, true)
		line(5, 11, 4.2, 14); line(8, 11, 7.2, 14.2); line(11, 11, 10.2, 14)
	elseif kind == "wave" then
		line(2, 7, 5, 5); line(5, 5, 8, 8); line(8, 8, 11, 5.5); line(11, 5.5, 14, 7.5)
		line(2, 11, 5, 9); line(5, 9, 8, 12); line(8, 12, 11, 9.5); line(11, 9.5, 14, 11.5)
	elseif kind == "snow" then
		line(8, 2, 8, 14); line(2.5, 5, 13.5, 11); line(13.5, 5, 2.5, 11)
		ring(8, 8, 1.4, true)
		line(5, 3.5, 6.2, 5); line(11, 3.5, 9.8, 5); line(5, 12.5, 6.2, 11); line(11, 12.5, 9.8, 11)
	elseif kind == "leaf" then
		ring(8, 8, 5, false); line(8, 13.5, 8, 3.5); line(8, 8, 11, 5.5); line(8, 8, 5, 5.5)
	elseif kind == "moon" then
		ring(8, 8, 5.5, false); ring(10.5, 6.5, 4, true)
	elseif kind == "sun" then
		ring(8, 8, 3.2, true)
		for i = 0, 7 do
			local a = (i / 8) * math.pi * 2
			line(8 + math.cos(a) * 4.2, 8 + math.sin(a) * 4.2, 8 + math.cos(a) * 6.8, 8 + math.sin(a) * 6.8)
		end
	elseif kind == "plane" then
		line(2, 9, 14, 9); line(8, 9, 5, 5); line(8, 9, 5, 13); line(12, 9, 14, 6); line(12, 9, 14, 12)
	elseif kind == "home" then
		line(3, 8, 8, 3.5); line(8, 3.5, 13, 8); rect(4.5, 8, 7, 6, 1, false); rect(6.8, 10, 2.4, 4, 0.8, true)
	elseif kind == "star" then
		line(8, 2, 9.5, 6.5); line(9.5, 6.5, 14, 6.5); line(14, 6.5, 10.5, 9.5)
		line(10.5, 9.5, 12, 14); line(12, 14, 8, 11); line(8, 11, 4, 14)
		line(4, 14, 5.5, 9.5); line(5.5, 9.5, 2, 6.5); line(2, 6.5, 6.5, 6.5); line(6.5, 6.5, 8, 2)
	elseif kind == "refresh" then
		ring(8, 8, 5, false); line(11.5, 4.5, 13, 3); line(11.5, 4.5, 11.5, 7)
	elseif kind == "warn" then
		line(8, 2.5, 2.5, 13.5); line(8, 2.5, 13.5, 13.5); line(2.5, 13.5, 13.5, 13.5)
		line(8, 6, 8, 10); ring(8, 12, 0.8, true)
	elseif kind == "hex" then
		line(8, 2, 13, 5); line(13, 5, 13, 11); line(13, 11, 8, 14)
		line(8, 14, 3, 11); line(3, 11, 3, 5); line(3, 5, 8, 2)
	elseif kind == "hand" then
		rect(5, 7, 6, 7, 1.5, false); rect(5, 4, 2, 5, 1, false); rect(7.2, 3.5, 1.6, 4, 0.8, false)
		rect(9.2, 4, 1.6, 4, 0.8, false); rect(11, 5, 1.5, 3.5, 0.8, false)
	elseif kind == "infinity" then
		ring(5.5, 8, 3.2, false); ring(10.5, 8, 3.2, false)
	elseif kind == "arrow" then
		line(3, 8, 12, 8); line(12, 8, 9, 5); line(12, 8, 9, 11)
	elseif kind == "back" then
		line(12, 8, 4, 8); line(4, 8, 7, 5); line(4, 8, 7, 11)
	elseif kind == "up" then
		line(8, 12, 8, 4); line(8, 4, 5, 7); line(8, 4, 11, 7)
	elseif kind == "circle" then
		ring(8, 8, 5.5, false)
	elseif kind == "cloud" then
		ring(5.5, 8, 3.2, true); ring(8.5, 7, 3.8, true); ring(11.5, 8.2, 2.8, true)
		rect(4, 8.5, 9, 3, 1.2, true)
	elseif kind == "image" then
		rect(3, 4, 10, 8, 1, false); ring(6, 7, 1.2, true); line(3, 11, 7, 8); line(7, 8, 13, 12)
	elseif kind == "chat" then
		rect(3, 3.5, 10, 7, 1.5, false); line(5, 10.5, 5, 13); line(5, 13, 8, 10.5)
	elseif kind == "rocket" then
		line(8, 2, 5, 10); line(8, 2, 11, 10); line(5, 10, 11, 10); line(6, 10, 5, 14); line(10, 10, 11, 14)
	elseif kind == "heart" then
		ring(5.5, 6, 2.5, true); ring(10.5, 6, 2.5, true); line(3.2, 7, 8, 13); line(12.8, 7, 8, 13)
	elseif kind == "shield" then
		line(8, 2, 13, 5); line(13, 5, 13, 10); line(13, 10, 8, 14); line(8, 14, 3, 10); line(3, 10, 3, 5); line(3, 5, 8, 2)
	elseif kind == "mouse" then
		rect(5, 3, 6, 10, 2, false); line(8, 3, 8, 8)
	elseif kind == "food" then
		ring(8, 9, 5, false); rect(5, 3, 6, 3, 1, true)
	elseif kind == "sound" then
		rect(3, 6, 3, 4, 1, true); line(6, 6, 9, 3); line(6, 10, 9, 13); line(9, 3, 9, 13)
		line(11, 5, 13, 4); line(11, 11, 13, 12)
	elseif kind == "light" then
		ring(8, 9, 3.5, false); line(8, 2, 8, 5); line(8, 12.5, 8, 14.5)
	end

	return function(c)
		for _, it in ipairs(items) do
			if it[2] == "bg" then it[1].BackgroundColor3 = c else it[1].Color = c end
		end
	end
end

local ICON_KIND_NAMES = {
	radar=1, chevrons=1, crosshair=1, tool=1, skull=1, eye=1, user=1, gear=1, pad=1,
	sparkle=1, swords=1, box=1, mask=1, lock=1, chain=1, bolt=1, search=1, clock=1,
	pin=1, diamond=1, square=1, arrows=1, plus=1, minus=1, cross=1, rain=1, wave=1,
	snow=1, leaf=1, moon=1, input=1, btn=1, major=1, tab=1, sun=1, plane=1, home=1,
	star=1, refresh=1, warn=1, hex=1, hand=1, infinity=1, arrow=1, back=1, up=1,
	circle=1, cloud=1, image=1, chat=1, rocket=1, heart=1, shield=1, mouse=1, food=1,
	sound=1, light=1,
}
local function gIconKind(glyph)
	if not glyph or glyph == "" then return nil end
	glyph = tostring(glyph)
	-- nama kind langsung (premium SVG geometry)
	if ICON_KIND_NAMES[glyph] then return glyph end
	glyph = (string.gsub(glyph, "\u{FE0F}", ""))
	local k = ICON_BY_GLYPH[glyph]
	if k then return k end
	local ok, cp = pcall(utf8.codepoint, glyph, 1)
	if ok and cp and (cp >= 0x1F000 or (cp >= 0x2600 and cp <= 0x27BF) or (cp >= 0x2B00 and cp <= 0x2BFF)) then
		return "diamond" -- emoji berwarna lain → ikon geometris netral
	end
	return nil
end

function Glass.Icons(o)
	if o and o.Parent and o:IsA("TextButton") and not o:GetAttribute("SRFIconDone") then
		local k = ((o.Text == "SOON I" or o.Text == "SEGERA I") and "lock") or ((o.Text == "SOON II" or o.Text == "SEGERA II") and "chain") or nil
		if k then
			o:SetAttribute("SRFIconDone", true)
			local holder = gNew("Frame", o, {
				Name = GN .. "Icon", BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 9, 0.5, -6), ZIndex = o.ZIndex + 1,
			})
			local recolor = gIconDraw(holder, k, 12, o.TextColor3)
			o:GetPropertyChangedSignal("TextColor3"):Connect(function() recolor(o.TextColor3) end)
		end
		return
	end
	if not o or not o.Parent or not o:IsA("TextLabel") then return end
	if o:GetAttribute("SRFIconDone") then return end
	local par = o.Parent
	local isTab = par:IsA("TextButton") and par.Parent and par.Parent:IsA("ScrollingFrame")
		and par.Parent.ScrollingDirection == Enum.ScrollingDirection.X
	if isTab then
		local glyph, rest = string.match(o.Text, "^(%S+)%s+(.+)$")
		if not glyph then return end
		local kind = ICON_BY_TAB[rest] or (Glass.I18N and ICON_BY_TAB[Glass.I18N.T(rest, "en")]) or gIconKind(glyph)
		if not kind then return end
		o:SetAttribute("SRFIconDone", true)
		o.Text = rest
		o.Size = UDim2.new(1, -26, 1, 0)
		o.Position = UDim2.new(0, 22, 0, 0)
		local holder = gNew("Frame", par, {
			Name = GN .. "Icon", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 8, 0.5, -7), ZIndex = par.ZIndex + 1,
		})
		local recolor = gIconDraw(holder, kind, 14, o.TextColor3)
		o:GetPropertyChangedSignal("TextColor3"):Connect(function() recolor(o.TextColor3) end)
	elseif o.Size.X.Scale == 0 and o.Size.Y.Scale == 0 and o.Size.X.Offset == 22 and o.Size.Y.Offset == 22 then
		local kind = gIconKind(o.Text)
		if not kind then return end
		o:SetAttribute("SRFIconDone", true)
		o.TextTransparency = 1
		local holder = gNew("Frame", o, {
			Name = GN .. "Icon", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0.5, -6, 0.5, -6), ZIndex = o.ZIndex + 1,
		})
		local recolor = gIconDraw(holder, kind, 12, o.TextColor3)
		o:GetPropertyChangedSignal("TextColor3"):Connect(function() recolor(o.TextColor3) end)
	end
end

function Glass.Skin(obj)
	if not obj or not obj.Parent then return end
	if obj:GetAttribute("SRFGlassDone") then return end
	if string.sub(obj.Name, 1, #GN) == GN then return end
	local bt0 = obj:GetAttribute("SRF_BT") or obj.BackgroundTransparency
	if bt0 >= 0.95 then return end
	local cr = obj:FindFirstChildOfClass("UICorner")
	if not cr then return end
	local w, h = obj.AbsoluteSize.X, obj.AbsoluteSize.Y
	if w <= 0 and obj.Size.X.Scale == 0 then w = obj.Size.X.Offset end
	if h <= 0 and obj.Size.Y.Scale == 0 then h = obj.Size.Y.Offset end
	if h <= 0 then return end
	if h < 20 or (w > 0 and w < 30) then return end

	local T = Config.Theme
	local par = obj.Parent
	local kind
	local isTab = obj:IsA("TextButton") and par:IsA("ScrollingFrame")
		and par.ScrollingDirection == Enum.ScrollingDirection.X
	if obj:IsA("TextBox") then kind = "input"
	elseif isTab then kind = "tab"
	elseif obj:IsA("Frame") and h >= 120 and (w <= 0 or w >= 120) then kind = "major"
	elseif h >= 30 and obj:IsA("TextButton") and not (par:IsA("ScrollingFrame") and h <= 28) then kind = "btn"
	elseif h >= 30 and obj:IsA("Frame") and obj.Active then kind = "btn"
	else kind = "row" end
	obj:SetAttribute("SRFGlassDone", true)

	local s = GS[kind]
	do -- sudut lebih bulat ala kartu glass
		local c0 = cr.CornerRadius
		if c0.Scale == 0 and c0.Offset < s.r then
			cr.CornerRadius = UDim.new(0, math.min(s.r, math.floor(h / 2)))
		end
	end
	local recessed = (kind == "input")
	local d = s.d
	local rad = cr.CornerRadius.Offset
	if cr.CornerRadius.Scale > 0 then rad = cr.CornerRadius.Scale * math.min(w > 0 and w or h, h) end
	local z = obj.ZIndex

	-- 1) Bevel luar: stroke lama diberi pencahayaan terarah (kiri-atas terang, kanan-bawah gelap)
	local st = obj:FindFirstChildOfClass("UIStroke")
	if st then
		local c = st.Color
		local legacy = (c == T.Accent) or (c == T.Panel) or (c == T.Panel2) or (c == T.Panel3)
			or (c.R > 0.95 and c.G > 0.95 and c.B > 0.95)
		if obj:IsA("GuiButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end
		if legacy then
			st.Color = Glass.Edge
			st.Transparency = s.outerT
		end
	else
		st = Instance.new("UIStroke")
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Color = Glass.Edge
		st.Thickness = 1.2
		st.Transparency = s.outerT
		st.Parent = obj
	end
	if not st:FindFirstChild(GN .. "Light") then
		local g
		if recessed then
			g = gGrad(st, 45, CS(CK(0, Color3.fromRGB(35, 37, 44)), CK(0.5, Color3.fromRGB(135, 140, 150)), CK(1, G_WHITE)))
		else
			g = gGrad(st, 45, CS(CK(0, G_WHITE), CK(0.45, Color3.fromRGB(135, 140, 150)), CK(1, Color3.fromRGB(30, 32, 38))))
		end
		g.Name = GN .. "Light"
	end

	-- 2) Permukaan glass: gradasi terang di atas, gelap di bawah (emboss)
	local body = gNew("Frame", obj, {
		Name = GN .. "Body", BackgroundColor3 = G_WHITE, BorderSizePixel = 0,
		Size = UDim2.new(1, -d * 2, 1, -d * 2), Position = UDim2.new(0, d, 0, d),
		ZIndex = z - 1,
	})
	gNew("UICorner", body, { CornerRadius = UDim.new(0, math.max(rad - d, 2)) })
	local bodyGrad = gGrad(body, 90,
		recessed and CS(CK(0, G_BLACK), CK(1, G_WHITE)) or CS(CK(0, G_WHITE), CK(1, G_BLACK)),
		gFill(s, recessed, 0))

	-- 3) Bevel dalam: rim tipis (atas terang -> bawah gelap), terpisah dari bevel luar
	local rim = gNew("UIStroke", body, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = G_WHITE, Thickness = 1, Transparency = 0,
	})
	if recessed then
		gGrad(rim, 90, CS(CK(0, G_BLACK), CK(0.5, Color3.fromRGB(70, 72, 80)), CK(1, G_WHITE)),
			NS(NK(0, 0.30), NK(0.5, 0.85), NK(1, 0.55)))
	else
		gGrad(rim, 90, CS(CK(0, G_WHITE), CK(0.5, Color3.fromRGB(120, 125, 135)), CK(1, G_BLACK)),
			NS(NK(0, s.rimT), NK(0.45, 0.85), NK(0.75, 0.80), NK(1, 0.35)))
	end

	-- 4) Highlight spekular + bayangan tepi (komponen besar, tab, tombol)
	local topLine
	if kind == "major" or kind == "tab" or kind == "btn" then
		topLine = gLines(obj, rad, w, h, kind)
	end

	-- animasi: dekorasi ikut memudar bersama objek (fade in/out mulus di semua transisi)
	local baseBT = bt0
	local topBase = 0.55
	local function apply()
		local f = math.clamp((obj.BackgroundTransparency - baseBT) / math.max(1 - baseBT, 0.01), 0, 1)
		body.BackgroundTransparency = f
		rim.Transparency = f
		if topLine then topLine.BackgroundTransparency = topBase + (1 - topBase) * f end
	end
	obj:GetPropertyChangedSignal("BackgroundTransparency"):Connect(apply)
	apply()

	-- 5) Bayangan jatuh di bawah tab / tombol (tab tampak melayang)
	local drop
	if false then
		drop = gNew("Frame", obj, {
			Name = GN .. "Drop", BackgroundColor3 = G_BLACK, BorderSizePixel = 0,
			Size = UDim2.new(1, -6, 0, 4), Position = UDim2.new(0, 3, 1, -1), ZIndex = z - 1,
		})
		gNew("UICorner", drop, { CornerRadius = UDim.new(0, 2) })
		gGrad(drop, 90, CS(CK(0, G_BLACK), CK(1, G_BLACK)), NS(NK(0, 0.40), NK(1, 1)))
	end

	-- feedback hover/tekan halus (hanya mengubah lapisan dekoratif)
	if obj:IsA("GuiButton") and kind ~= "input" then
		local hv = gNew("Frame", obj, {
			Name = GN .. "Hover", BackgroundColor3 = G_WHITE, BackgroundTransparency = 1,
			BorderSizePixel = 0, Size = UDim2.new(1, -d * 2, 1, -d * 2),
			Position = UDim2.new(0, d, 0, d), ZIndex = z - 1,
		})
		gNew("UICorner", hv, { CornerRadius = UDim.new(0, math.max(rad - d, 2)) })
		local SINE = Enum.EasingStyle.Sine
		obj.MouseEnter:Connect(function() Util.Tween(hv, { BackgroundTransparency = 0.93 }, 0.22, SINE) end)
		obj.MouseLeave:Connect(function()
			Util.Tween(hv, { BackgroundTransparency = 1 }, 0.30, SINE)
			Util.Tween(body, { Position = UDim2.new(0, d, 0, d) }, 0.20, SINE)
		end)
		obj.MouseButton1Down:Connect(function()
			Util.Tween(hv, { BackgroundTransparency = 0.86 }, 0.08, SINE)
			Util.Tween(body, { Position = UDim2.new(0, d, 0, d + 1) }, 0.08, SINE)
		end)
		obj.MouseButton1Up:Connect(function()
			Util.Tween(hv, { BackgroundTransparency = 0.93 }, 0.22, SINE)
			Util.Tween(body, { Position = UDim2.new(0, d, 0, d) }, 0.22, SINE)
		end)
	end

	-- 6) Tab: indikator aksen + wajah lebih terang saat aktif (hanya membaca warna tab)
	if kind == "tab" then
		local function dist(a, b) return (a.R - b.R) ^ 2 + (a.G - b.G) ^ 2 + (a.B - b.B) ^ 2 end
		local function sync()
			if not obj.Parent then return end
			local c = obj.BackgroundColor3
			local on = dist(c, T.Active) < dist(c, T.Panel2)
			bodyGrad.Transparency = gFill(s, false, on and 0.12 or 0)
			st.Transparency = on and 0.45 or s.outerT
			topBase = on and 0.25 or 0.55
			apply()
		end
		obj:GetPropertyChangedSignal("BackgroundColor3"):Connect(sync)
		sync()
	end
end

-- Lapisan bayangan lembut di belakang panel utama (sibling di ScreenGui, mengikuti panel)
function Glass.PanelShadow(panel)
	local gui = panel.Parent
	if not gui then return end
	local sh = Instance.new("ImageLabel")
	sh.Name = GN .. "PanelShadow"
	sh.BackgroundTransparency = 1
	sh.Image = "rbxassetid://6014261993" -- aset yang sudah dipakai script untuk Shadow panel
	sh.ImageColor3 = G_BLACK
	sh.ImageTransparency = 0.45
	sh.ScaleType = Enum.ScaleType.Slice
	sh.SliceCenter = Rect.new(49, 49, 450, 450)
	sh.ZIndex = 0
	pcall(function() sh.Interactable = false end)
	sh.Parent = gui
	local PAD = 24
	local function sync()
		local p, sz = panel.AbsolutePosition, panel.AbsoluteSize
		sh.Position = UDim2.fromOffset(p.X - PAD, p.Y - PAD + 8)
		sh.Size = UDim2.fromOffset(sz.X + PAD * 2, sz.Y + PAD * 2)
		sh.Visible = panel.Visible
	end
	panel:GetPropertyChangedSignal("AbsolutePosition"):Connect(sync)
	panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
	panel:GetPropertyChangedSignal("Visible"):Connect(sync)
	panel.AncestryChanged:Connect(function()
		if not panel.Parent then sh:Destroy() end
	end)
	sync()
end


----------------------------------------------------------------
-- WALLPAPER HOME MENU: atas = gambar tajam, bawah = frosted glass
-- (UI Roblox tidak punya backdrop-blur; efek blur dibuat dari salinan gambar
--  beresolusi rendah yang diperbesar, lalu dipadukan dengan gradient)
----------------------------------------------------------------
local WALL_SHARP = [[
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
]]
local WALL_BLUR = [[
/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAoHBwgHBgoICAgLCgoLDhgQDg0NDh0VFhEYIx8lJCIfIiEmKzcvJik0KSEiMEExNDk7Pj4+JS5ESUM8SDc9Pjv/
wAALCABYAEABAREA/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEI
I0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ip
qrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oACAEBAAA/AFENPEVOEVL5RpDFQYvak8jPalFtntVjysdqcI6innht
1zIwFUxrNsWwDVyG4hm+6wqcR5qRYc9qnjtx6VoPpUEKnfIAawtSuI7GF5CeB0rzzUNYlvLhjuO3PApsExzya2LS6KYIY10mmX/m4R+tbUYBq1FHmti5sYbi
c7sjFeYfECdYG8iJsiuCQ81dhOK0LeUKRzW5Z36KyYAzXYWbiaJXHpWjEDxxUpnvLsfIMBu9eb+PdPe3lDO4YmuJVcGpRJtWkS7bPWtLT53nuUjB5Jr1nQ7G
S2tlMi7gRxV/a+7OzAqreao9jpX7kZYjrXmmrSXus3ZUhmJNYV9p1xYPtmjK/UVUJqFgM5FW9LkdNQhKnncK9508zHTIpD/cFSpLJcQscAYrmLvUxbJtkQMn
vWeninSrV/MW0UuPauc8VeIYtZA2QBCO4Fcg7YNRNJWz4ThW61qIOMqDmvdY7u3FmIgduFxio9NkUytETwa4bVpxIu2uZuYQckCsm4G3NZs3NV8EnFeh/DjS
Y0uftE/U9M16JFFE90yucDtS3EYsGEiNnNcFq4YAkVgfaQcq3BqldAMDisefhqWxjWa8jQ9Ca9e0S3trK1RlbLAVpQ33+kfOPlNXtTKvaI6NkVyV9EJUNcrf
6cwcstZUscqcHNUZYmc/dq5o2mubtXYYANeh2Y2RAe1WvMx3pzXrmLyy3FRNazn+A1Xm0uWQf6usy48PzNnEdUz4buN3+qNaFlok8RB8utZLSdVxsNBtrj+4
aja2uD/Aa//Z
]]

local function gB64(data)
	local alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local lut = {}
	for i = 1, 64 do lut[string.byte(alpha, i)] = i - 1 end
	local out, n, buf, bits = {}, 0, 0, 0
	for i = 1, #data do
		local v = lut[string.byte(data, i)]
		if v then
			buf = buf * 64 + v
			bits = bits + 6
			if bits >= 8 then
				bits = bits - 8
				local p = 2 ^ bits
				local byte = math.floor(buf / p)
				buf = buf % p
				n = n + 1
				out[n] = string.char(byte)
			end
		end
	end
	return table.concat(out)
end

local gWall = nil
local function gWallAssets()
	if gWall ~= nil then return gWall end
	gWall = false
	pcall(function()
		local getAsset = getcustomasset or getsynasset
		if not (writefile and getAsset) then return end
		writefile("srf_home_wall.jpg", gB64(WALL_SHARP))
		writefile("srf_home_blur.jpg", gB64(WALL_BLUR))
		gWall = { sharp = getAsset("srf_home_wall.jpg"), blur = getAsset("srf_home_blur.jpg") }
	end)
	return gWall
end

function Glass.HomeBackdrop(card)
	if card:GetAttribute("SRFWall") then return end
	card:SetAttribute("SRFWall", true)
	local T = Config.Theme
	local cr = card:FindFirstChildOfClass("UICorner")
	local rad = cr and cr.CornerRadius.Offset or 20
	local z = card.ZIndex - 2
	-- [RAPI] wallpaper dipasang masuk 2px dari tepi kartu (sama dengan inset bevel "Body"),
	-- jadi tidak pernah menyentuh / melewati garis stroke luar kartu.
	local INSET = 2
	local wrapRad = math.max(rad - INSET, 2)
	local roundList = {} -- semua lapisan wallpaper ikut lengkungan yang sama
	local function round(inst)
		local c = gNew("UICorner", inst, { CornerRadius = UDim.new(0, wrapRad) })
		roundList[#roundList + 1] = c
		return c
	end
	local wrap = gNew("Frame", card, {
		Name = GN .. "Wall", BackgroundTransparency = 1, BorderSizePixel = 0,
		ClipsDescendants = true, Position = UDim2.fromOffset(INSET, INSET),
		Size = UDim2.new(1, -INSET * 2, 1, -INSET * 2), ZIndex = z,
	})
	round(wrap)
	local tint = Color3.fromRGB(205, 218, 238)
	local fades = {} -- { instance, prop, base }
	local assets = gWallAssets()
	if assets then
		-- ClipsDescendants di Roblox hanya memotong persegi (tidak mengikuti UICorner),
		-- jadi setiap gambar diberi UICorner sendiri supaya pojoknya ikut melengkung.
		local blurImg = gNew("ImageLabel", wrap, {
			Name = GN .. "WallBlur", BackgroundTransparency = 1, BorderSizePixel = 0,
			Image = assets.blur, ScaleType = Enum.ScaleType.Crop, ImageColor3 = tint,
			ImageTransparency = 0.20, Size = UDim2.new(1, 0, 1, 0), ZIndex = z,
		})
		round(blurImg)
		gGrad(blurImg, 90, CS(CK(0, G_WHITE), CK(1, G_WHITE)),
			NS(NK(0, 1), NK(0.30, 0.75), NK(0.65, 0.20), NK(1, 0)))
		fades[#fades + 1] = { blurImg, "ImageTransparency", 0.20 }
		local sharpImg = gNew("ImageLabel", wrap, {
			Name = GN .. "WallSharp", BackgroundTransparency = 1, BorderSizePixel = 0,
			Image = assets.sharp, ScaleType = Enum.ScaleType.Crop, ImageColor3 = tint,
			ImageTransparency = 0.10, Size = UDim2.new(1, 0, 0.64, 0), ZIndex = z,
		})
		round(sharpImg)
		gGrad(sharpImg, 90, CS(CK(0, G_WHITE), CK(1, G_WHITE)),
			NS(NK(0, 0), NK(0.50, 0.08), NK(0.80, 0.55), NK(1, 1)))
		fades[#fades + 1] = { sharpImg, "ImageTransparency", 0.10 }
	end
	-- scrim kaca gelap: ringan di atas (wallpaper terlihat), pekat di bawah (tombol tetap terbaca)
	local scrim = gNew("Frame", wrap, {
		Name = GN .. "WallScrim", BackgroundColor3 = T.Panel, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = z,
	})
	round(scrim)
	gGrad(scrim, 90, CS(CK(0, G_WHITE), CK(1, G_WHITE)),
		NS(NK(0, 0.80), NK(0.40, 0.62), NK(0.70, 0.34), NK(1, 0.18)))
	fades[#fades + 1] = { scrim, "BackgroundTransparency", 0 }

	-- kalau radius sudut kartu berubah (mis. oleh skin), wallpaper ikut menyesuaikan
	if cr then
		cr:GetPropertyChangedSignal("CornerRadius"):Connect(function()
			local r = cr.CornerRadius.Offset
			if cr.CornerRadius.Scale > 0 then
				local sz = card.AbsoluteSize
				r = cr.CornerRadius.Scale * math.min(sz.X, sz.Y)
			end
			wrapRad = math.max(r - INSET, 2)
			for _, c in ipairs(roundList) do c.CornerRadius = UDim.new(0, wrapRad) end
		end)
	end

	-- ikut memudar bersama kartu (GlassIn / GlassOut)
	local baseBT = card:GetAttribute("SRF_BT") or 0.08
	local function sync()
		local f = math.clamp((card.BackgroundTransparency - baseBT) / math.max(1 - baseBT, 0.01), 0, 1)
		for _, it in ipairs(fades) do it[1][it[2]] = it[3] + (1 - it[3]) * f end
	end
	card:GetPropertyChangedSignal("BackgroundTransparency"):Connect(sync)
	sync()
end

-- Pasang skin ke semua GUI yang dibuat (termasuk baris yang dibuat dinamis)
function Glass.Attach(gui)
	local queue, pending = {}, false
	local function flush()
		pending = false
		local q = queue
		queue = {}
		for _, o in ipairs(q) do
			pcall(Glass.Icons, o)
			if o.Name == "HomeCard" then pcall(Glass.HomeBackdrop, o) end
			pcall(Glass.Skin, o)
		end
	end
	gui.DescendantAdded:Connect(function(o)
		if not (o:IsA("Frame") or o:IsA("TextButton") or o:IsA("TextBox") or o:IsA("TextLabel")) then return end
		if string.sub(o.Name, 1, #GN) == GN then return end
		queue[#queue + 1] = o
		if not pending then
			pending = true
			task.defer(flush)
		end
	end)
end


----------------------------------------------------------------
-- [I18N + LOGO + BENDERA] terjemah EN/ID, logo gambar, bendera premium
-- (semua disimpan di tabel Glass supaya tidak menambah variabel local)
----------------------------------------------------------------
Glass.IMG = {
	logo = [==[
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
AfoPeNJXYYvdAAAAAElFTkSuQmCC
]==],
	flag_en = [==[
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
]==],
	ic_minus = [==[
iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABOklEQVR42u3WO07DQBSF4f8QIx6iYx0sAgoKCjaB2AQSHUugpGYFSCkAiU3AHh
BsgJDk0IwlV4g42A7kfJJlF7bnzsy9MwMRERERERERERERERGxHrTMx7YrwL/xrzbNN9qdSfJaz6Rt9ZIBtlWPtu1z4BQYAa89Zq2BfWATuAeu
JU2asXU50hu2K9u3Xh2PtvdKbOosA2xXkqa2z4AbYFJmv1mTfa9fU2ALuJJ0WcfY1QCMJM1sj4FjYA5UA5f/vNxfJB3UGfDTUthoufJWA6383x
kt0vG2A1C/Py7P0zIDQ16fJZaHRpm6qxJQ+WYbuAMOV2T2n4Ej4G3RLGi9DdreAS6AE2C355KoO/gBPJUF8L2XbXCZQ8e/ism2ylF46I5Xy3Re
fzkj1v78HxERERERERERERERsYgv9yMtKrJ3Gx0AAAAASUVORK5CYII=
]==],
	ic_plus = [==[
iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAACc0lEQVR42u2aPY4TQRCFv7KNYC0kAn6ExBm4AQkEBARcAnEJ0uUABBBvxgkQi/
hZcQKCFSAyQoTgAHjXnkdSLY3M2J4emxl7XE9qtdWq6Zp5VdXdr2UIBAKBQCAQCAT2EtaVY0kjQKX3mJmZ9joakqzXGSDJUpQlPQYeAiPgLfDC
zM7KNn2M8EDSSNJL/YsPki67jfXx40feP/IPnkiaevvjY4dl274RMPT+jaSZpPNS9Kc+dppKpa0sGLTJgfeF+7W5tWgAXARocw1ok4Dk68ccIV
Uk0UcCuvS5Gy8TBAQBQUAQEAS0jLWOnBWSdqkvSavsrHQMNvkDKw5Wa0nptQgws2mG+dRJmyyzyZyzUmn+VwIWSNoh8LNGuRXAnYryS1lxS9JR
aUwLJLyAq8AF4B3wvDUpvULSdoV2pPQKSXtesxVLPqTImGcjUtoyCRia2UzSMXDfU7pr7V54/9XMbqcMqFsKudug5taObbq5GTaR0rkEJPtj/z
31COQ01YhoTjv3d3mfSiCHhNwSMH/mEvAKuLsl0f8C3AN+5WaBNVgIzcwk6QB4AjwAxhnz3QSueCbM258B3zNKcQJ8BJ6a2e/WbpSbbDWlHeTI
V+3yneDM+29NfTTd/hppAc8Ay9xylOujLrHrRL7xFuYOpxns17rpLdnYKtLMTE2PzhvRAjnRkpQyp9ZcyT7kcBAQBAQBQUDPCCj2lYC0pV3fJi
XZBQHjBVlQALM+E5B8va6Q0knSnjSRtDsB1w4DSWNJJxXXYZ8l3WjzzxGdkOD9gaRDSZ8knUp6JunaOqpu50jYpKTd1XIYzUtaAoFAIBAIBAKB
QFv4C1cyBM0XNslRAAAAAElFTkSuQmCC
]==],
	ic_cross = [==[
iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAACjklEQVR42u1aTYoTQRT+XjoiE10Og95GcCm4di9ewCvMBUTwBILxAA6CMDPZCu
JCo2dwJeJC0pN0Phe+hqJNp7urKt1dM++DJqFTVe99X/2+egEMBoPBYDAYDAaD4QZCYjRCcgqATpuFiDC2s33ZieWs9NFWqJ1piFOl+iSfAXis
7X0A8EpErkhORGQbi/weO9L7SCA5ITkl+Yb/44LknbJcCPmyfo2dc5J31Rfpk/xUP5+qIznJjT65vrskOfMVoUJ+rm1eOXZW+u7U9akvATL9fE
+yILmu9Mw6RIQ95F0U+nx16nQeBb7Dk5U1RHasLRsADwCckZyJyLaNCEpCtPwcwBMAawC3aqpk+FeBQ0yB584U2IVOI6Flz7Ni8+UQU0B04Zkp
uX2OthKhI/myzSXJE9/hH2Vvroiw9hHBk/w3kvdCd5rgrTBUhAjks6FPfKEiZMmSjyDC7eTJB4pwRvJ1y7LjJe8pQlHzPU3yASJsrg15TxGuF/
kaERYNQ33X1EiXfI0I70huG0QotMxHkid9kJ8cXgNmIvIHwE8NmtgQZAmA3wB+6WmTqfa+e8J76zEFFiH3CWMiPw9YBC+TE6Hj2b7NNpiOCB7k
2x6Exi+CZ1T3SS82vUPplMkvSR7rzfIiWREixPMS41IlVfJZjEuVIclLjHg+gggyhABlZijKZUaACKPJDAVHdR1FyMecGfIOaTuIMOrM0EZ/+w
7goYj80KCoaGq4zCBpAPUIwMLJNI02M7RyeiSPEc/XjITcsbMaS2boYsfwXJK8HxrP14hQtTN4ZuiI5CnJzyS/kHxB8jjWZYYjwj47/W+DTYZj
HlAO+ReZWNNh6q4Ph3CqLzsGg8FgMBgMBoPBcCPwF0DTQSzr1ofCAAAAAElFTkSuQmCC
]==],
	flag_id = [==[
iVBORw0KGgoAAAANSUhEUgAAAGAAAABACAYAAADlNHIOAAAFMElEQVR42u1cTWxUVRT+zr13fvoUS5sOViG2xRQJo3Wlhg2UBMJOlyzZudbElR
uGjSsTXZngCtiRuHLhBgyFkBB0o7VDMBOdVkAJQzKpYaYzfe+e4+K9+SFIgtK5NfF8yd01s/i+953z3XObQxiCiBgiYrl82WFxcR7AG2AuJ831
Eog8wATFU8AIRKybGG/AmCqAn7C0VKMjR5Iex72/pCHyiYhERF4F8O7D698fan/34/749z92+fZGUQiAQAV4GhCEBLDRWCf38kv3o7ffvPX8wb
euAviaiH7pcd0XQEQIRASRw921Oyeb5y4cjX/9bbcRAVsDIeX9X+kgAuMZTITc3lfuTpw8cakws+cciK5kX7xQv+yILG6s/Pzh/c+/PGa6nbE4
54QA0a/+2d0gAOXihLhQ3Nj1wfsXx15/7TMiWhIR03PAXHftzql7pz89gTguemuZRIyyt3UQIrbeG+RynelTH10ozOw5TUR1JysreQDvNc6cP0
7tdjHJ5xhJYkQ52/LO7A2xa7eLjTPnj+/55OMfZGXlC4dyeXb9yvXFpFaf5pxjxF6//FHBwyTGsqnVp9evXF8cP3zwGwdgoXXtxgGTJPCWAP30
R90TYJIErWs3DowfPrjgeHNzIV69XRICJPGad0bdCwBiAuLV2yXe3FxwSXN9Kv7zYdGwAMJqgABgEfCfD4tJc33KwVoPEgF7zfvBbCDpJcFa7y
BCiD3EM6ACBOJfgNgDIuTAjP5RAcI5IOPcAYCwBxJGdi9TjJp/lpRzIBPAC+A9RFSAYAJ4GQgA9unRsU+oGJTx3XcAA57VAUEdwJkADIATwHtA
BQjogATgngOyjqyT55BNuOcApOUHntUBIR3gGQAPOyCBQAehYRzAww7AkAOUnDAOyPh+PAUpN8Ec0BdAMBhFKMI5gNOK4wCGeJ/dhNUC4Rzgh5
qwFy1BwQX421GEKhCuBA2PIrKmoA4Ixf+g52ajiEEsUhOMGJTFfubBKALMEGGIBqEADQCAMGhwERNIp5sea9QBoRzgHACBgyHY8RcgzkGc/l9Q
CAEoEdBzEWAILj/9IvZ++xWsobQ5KEYOYww8C/KTO+FgDNzkOKyxYAAahUbtAIIBQOwBY7IYGicQO5hRK0bch41Jb8IFm6UgosFRBHFBj2t9AN
jufqAUqAD/a6RNWKR/FAGa8BDXjpn7+V/vAeEE6PHuholXAcKBhx/lVQAVQAXo1SVF4CYMAN57WGs1BQUUwHv/aAwdTkOKMCI8EkO1BIUvQY/E
UCJ9D9gWB6gA/wEBvPcwxqgA2xVDdRa0zTFUm/D2CiDM3C9BpK9iIyd/qN+KY2bLzKQOCC4EMbN1zrkHADrMXPTeqwMCpR8i6jjnHjhjzHI+n2
90u92dkkIVGLEGACifzzeMMcsOwPKOHTtutlqteS1BYZAkCaampm4CWHbVanW1XC4vNRqNd5h52nvPRGQ0km4t0rWswtZaY629Nzk5uVStVlf7
ayvb7fapWq12AkCRmZmI9MF+a2s/G2MMgM78/PyFKIqytZXp4ta6iJydnZ2dqNfrx4hozHsvvXql9D17zbfWGhHZmJubuxhF0dmMc+OyrblUqV
SuVioV2rdvX3Ntbe1oq9XabYwhvSE/W9khImJmFAqFuzMzM5eiKDpXqVSuZvuj+YnLuxuNxqFms7m/3W7viuO42PtNpfWpv3rkcrlOFEX3JyYm
bpVKpScv7x4SobdH2gFI19cD5W63WwKgC4X+mQC2UCg0AKTr64EaET22vv4vyEOZr7q65NoAAAAASUVORK5CYII=
]==],
}
Glass._imgCache = {}

-- tombol minimize / silang: gambar ikon vektor premium (ikut warna teks tombol saat hover)
function Glass.IconBtn(btn, map, size)
	size = size or 14
	local holder = Instance.new("Frame")
	holder.Name = GN .. "Icon"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromOffset(size, size)
	holder.Position = UDim2.new(0.5, -size / 2, 0.5, -size / 2)
	holder.ZIndex = btn.ZIndex + 1
	holder.Parent = btn
	local recolor
	local function build()
		for _, c in ipairs(holder:GetChildren()) do c:Destroy() end
		recolor = nil
		local k = map[btn.Text]
		if not k then return end
		local img = Glass.Img("ic_" .. k) -- PNG halus (antialias), ikut warna tombol
		if img then
			local im = Instance.new("ImageLabel")
			im.BackgroundTransparency = 1
			im.BorderSizePixel = 0
			im.Size = UDim2.fromScale(1, 1)
			im.Image = img
			im.ImageColor3 = btn.TextColor3
			im.ZIndex = holder.ZIndex
			im.Parent = holder
			recolor = function(c) im.ImageColor3 = c end
		else
			recolor = gIconDraw(holder, k, size, btn.TextColor3)
		end
	end
	build()
	btn.TextTransparency = 1
	btn:GetPropertyChangedSignal("Text"):Connect(build)
	btn:GetPropertyChangedSignal("TextColor3"):Connect(function()
		if recolor then recolor(btn.TextColor3) end
	end)
end

-- tulis PNG ke workspace executor lalu ambil sebagai asset (sama seperti wallpaper)
function Glass.Img(name)
	local c = Glass._imgCache[name]
	if c ~= nil then return c or nil end
	Glass._imgCache[name] = false
	pcall(function()
		local getAsset = getcustomasset or getsynasset
		if not (writefile and getAsset) then return end
		local fn = "srf_img_" .. name .. ".png"
		writefile(fn, gB64(Glass.IMG[name]))
		local id = getAsset(fn)
		if id and id ~= "" then Glass._imgCache[name] = id end
	end)
	return Glass._imgCache[name] or nil
end

function Glass.MakeLogo(parent, size, pos, z)
	local id = Glass.Img("logo")
	if not id then return nil end
	local im = Instance.new("ImageLabel")
	im.Name = "SRFLogoImg"
	im.BackgroundTransparency = 1
	im.BorderSizePixel = 0
	im.Image = id
	im.ScaleType = Enum.ScaleType.Fit
	im.Size = size
	im.Position = pos
	im.ZIndex = z or 5
	im.Parent = parent
	return im
end

Glass.I18N = {
	lang = "id",
	cache = {},
	cacheN = 0,
}
do
	local I = Glass.I18N
	local orig = setmetatable({}, { __mode = "k" }) -- [objek] = { Text=asli, Text_set=hasil terjemah }

	-- { EN, ID [, "E"] }   "E" = hanya cocok untuk seluruh teks. Tanpa "E" = potongan teks (boleh di tengah kalimat)
	local PAIRS = {
		-- status umum
		{ "Enabled", "Aktif" },
		{ "Disabled", "Nonaktif" },
		{ "STATUS: READY", "STATUS: SIAP" },
		{ "Premium Edition", "Edisi Premium" },
		-- notifikasi gerak / lokasi
		{ "joystick + rotate camera", "joystick + putar kamera" },
		{ "Position Saved", "Posisi Tersimpan" },
		{ "No Saved Position", "Belum Ada Posisi Tersimpan" },
		{ "Returned to Position", "Kembali ke Posisi" },
		{ "Location Not Found: ", "Lokasi Tidak Ditemukan: " },
		{ "Bunker Not Found", "Bunker Tidak Ditemukan" },
		{ "(fallback)", "(cadangan)" },
		{ "Spawn database is empty", "Database spawn kosong" },
		{ "No Target Selected", "Belum Ada Target Dipilih" },
		{ "Target Has No Character", "Target Tidak Punya Karakter" },
		{ "Type a Player Name First", "Ketik Nama Pemain Dulu" },
		{ "Player Not Found: ", "Pemain Tidak Ditemukan: " },
		{ "Select Target First", "Pilih Target Dulu" },
		{ "Spectating ", "Mengamati " },
		{ "Character Not Ready", "Karakter Belum Siap" },
		-- scan / item / farm
		{ "Rescan started...", "Rescan dimulai..." },
		{ "Scan running... partial data", "Scan berjalan... data parsial" },
		{ "List empty — press REFRESH ITEM first", "Daftar kosong — tekan REFRESH ITEM dulu" },
		{ "Item Not in Workspace — try Refresh", "Item Tidak Ada di Workspace — coba Refresh" },
		{ "List empty — wait for scan to finish", "Daftar kosong — tunggu scan selesai" },
		{ "Select Place First", "Pilih Place Dulu" },
		{ "Place Not Found — try Refresh Place", "Place Tidak Ada — coba Refresh Place" },
		{ "Type a Name First", "Ketik Nama Dulu" },
		{ "Not Found: ", "Tidak Ditemukan: " },
		{ "Select an Item First (Refresh Item first)", "Pilih Item Dulu (Refresh Item dulu)" },
		{ "PickupItemEvent remote missing", "Remote PickupItemEvent tidak ada" },
		{ "Pickup: ", "Ambil: " },
		{ "Item Not Found — try Refresh Item", "Item Tidak Ditemukan — coba Refresh Item" },
		{ "Pickup Nearest", "Ambil Terdekat" },
		{ "No nearby items (max ", "Tidak ada item dekat (max " },
		{ " items, returned to position", " item, kembali ke posisi" },
		{ "Remote missing", "Remote tidak ada" },
		{ "Cages Opened", "Kandang Dibuka" },
		{ "Camera Zoom Unlocked", "Zoom Kamera Dibuka" },
		{ "Camera Zoom Restored", "Zoom Kamera Dipulihkan" },
		{ "DRONE ON — PC: WASD+QE | Mobile: left move / right look", "DRONE ON — PC: WASD+QE | Mobile: kiri gerak / kanan lihat" },
		{ "Distance ESP On", "ESP Jarak Aktif" },
		{ "Distance ESP Off", "ESP Jarak Mati" },
		{ "Name ESP On", "ESP Nama Aktif" },
		{ "Name ESP Off", "ESP Nama Mati" },
		-- server / join user
		{ "Server Hopping...", "Pindah Server..." },
		{ "Http Not Available", "Http Tidak Tersedia" },
		{ "No Server Found", "Server Tidak Ditemukan" },
		{ "Enter a username first!", "Masukan username dulu!" },
		{ "Searching user: ", "Mencari user: " },
		{ "' not found", "' tidak ditemukan" },
		{ "User found (ID: ", "User ditemukan (ID: " },
		{ "), checking presence...", "), cek presence..." },
		{ "Presence check failed (API blocked/limit) - fallback server hop", "Gagal cek presence (API blocked/limit) - fallback server hop" },
		{ "' is in your server!", "' satu server denganmu!" },
		{ "Joining server '", "Masuk ke server '" },
		{ "Join failed, normal server-hop...", "Gagal join, server-hop biasa..." },
		{ "' is not in-game (type: ", "' tidak in-game (type: " },
		{ "), normal server hop...", "), hop server biasa..." },
		-- food / furniture / spam
		{ "Dropped All Food (respawn)", "Semua Makanan Dibuang (respawn)" },
		{ "Collected ", "Terkumpul " },
		{ " Food", " Makanan" },
		{ "No Furniture Selected", "Belum Ada Furnitur Dipilih" },
		{ "Brought: ", "Dibawa: " },
		{ "Furniture Not Found", "Furnitur Tidak Ditemukan" },
		{ "Select an item in the Farm tab first (< > / type a name)!", "Pilih item dulu di tab Farm (< > / ketik nama)!" },
		{ "Start: ", "Mulai: " },
		{ " → drop at start point", " → drop di titik awal" },
		{ "STOP — spam stopped", "STOP — spam dihentikan" },
		{ "Select an item first (< >) or type a name", "Pilih item dulu (< >) atau ketik nama" },
		{ "Item not found: ", "Item tidak ditemukan: " },
		{ " → back to position", " → balik ke posisi" },
		{ "Pickup method unavailable", "Metode pickup tidak tersedia" },
		{ "Market raid done: ", "Raid market selesai: " },
		{ " items, returned", " item, kembali" },
		{ "Enter a username / select a target", "Isi username / pilih target" },
		{ "letter not found ", "tidak ketemu huruf " },
		{ "ON - use Reply Word in the box", "ON - pakai Reply Word di box" },
		{ "ON (fling opponent)", "ON (fling lawan)" },
		{ "Failed", "Gagal", "E" },
		{ "none", "tidak ada", "E" },
		-- home / panel
		{ "Coming Soon", "Segera Hadir" },
		{ "This tab is still locked", "Tab ini masih dikunci" },
		{ " not ready", " belum siap" },
		{ "SHOW PANEL", "BUKA PANEL" },
		{ "CLOSE PANEL", "TUTUP PANEL" },
		{ "RESTART", "MULAI ULANG" },
		{ "Panel opened", "Panel dibuka" },
		{ "Panel closed", "Panel ditutup" },
		{ "Restarting panel...", "Restart panel..." },
		{ "Panel reset", "Panel direset" },
		{ "SEARCH", "CARI", "E" },
		-- avatar
		{ "Avatar (No Respawn)", "Avatar (Tanpa Respawn)", "E" },
		{ "LOAD OUTFITS", "MUAT OUTFIT", "E" },
		{ "APPLY", "PAKAI", "E" },
		{ "Avatar from Username / ID", "Avatar dari Username / ID", "E" },
		{ "username or UserId", "username atau UserId", "E" },
		{ "Respawn In Place", "Respawn Di Tempat", "E" },
		{ "Loading outfits...", "Memuat outfit..." },
		{ "Outfits loaded: ", "Outfit dimuat: " },
		{ "No outfits found", "Outfit tidak ditemukan" },
		{ "Load outfits first", "Muat outfit dulu" },
		{ "Avatar applied (local): ", "Avatar dipakai (lokal): " },
		{ "Avatar failed", "Gagal ganti avatar" },
		{ "Enter a username or UserId", "Isi username atau UserId" },
		{ "Respawning in place...", "Respawn di tempat..." },
		-- nama tab
		{ "Move", "Gerak", "E" },
		{ "Mob", "Monster", "E" },
		{ "Visual", "Tampilan", "E" },
		{ "Player", "Pemain", "E" },
		{ "Util", "Utilitas", "E" },
		{ "Extra", "Ekstra", "E" },
		{ "Combat", "Tempur", "E" },
		{ "Load", "Muat", "E" },
		{ "SOON I", "SEGERA I", "E" },
		{ "SOON II", "SEGERA II", "E" },
		-- judul bagian
		{ "ESP Systems", "Sistem ESP", "E" },
		{ "ESP Options", "Opsi ESP", "E" },
		{ "Movement", "Gerakan", "E" },
		{ "Speed Multiplier", "Pengali Speed", "E" },
		{ "Locations", "Lokasi", "E" },
		{ "Position", "Posisi", "E" },
		{ "Control", "Kontrol", "E" },
		{ "Detection", "Deteksi", "E" },
		{ "World", "Dunia", "E" },
		{ "Actions", "Aksi", "E" },
		{ "Session", "Sesi", "E" },
		{ "Food", "Makanan", "E" },
		{ "Item List", "Daftar Item", "E" },
		-- tombol / label
		{ "SAVE POS", "SIMPAN POS", "E" },
		{ "RETURN", "KEMBALI", "E" },
		{ "Player TP", "TP Pemain", "E" },
		{ "TP PLAYER", "TP PEMAIN", "E" },
		{ "TP Player by Name", "TP Pemain via Nama", "E" },
		{ "type player name...", "ketik nama pemain...", "E" },
		{ "Click Teleport", "Teleport Klik", "E" },
		{ "ITEM: Wardrobe", "ITEM: Lemari", "E" },
		{ "Enter item name", "Masukan nama item", "E" },
		{ "e.g. Wardrobe1", "contoh: Wardrobe1", "E" },
		{ "e.g. 25", "contoh: 25", "E" },
		{ "Item not detected — try Refresh", "Item belum terdeteksi — coba Refresh", "E" },
		{ "TP to Item", "TP ke Item", "E" },
		{ "Pickup nearest", "Ambil terdekat", "E" },
		{ "Pickup selected", "Ambil terpilih", "E" },
		{ "TP-Pickup-Return (1 click)", "TP-Ambil-Balik (1 klik)", "E" },
		{ "Spam Item (follows selection above)", "Spam Item (ikut pilihan di atas)", "E" },
		{ "ITEM LIST (", "DAFTAR ITEM (" },
		{ "◀ PREV", "◀ SEBELUM", "E" },
		{ "NEXT ▶", "BERIKUT ▶", "E" },
		{ "< PREV", "< SEBELUM", "E" },
		{ "NEXT >", "BERIKUT >", "E" },
		{ "Catcher zone not in DB", "Catcher zone tidak ada di DB", "E" },
		{ "Save position", "Simpan posisi", "E" },
		{ "Remove Grass", "Hapus Rumput", "E" },
		{ "Remove Shadows", "Hapus Bayangan", "E" },
		{ "Camera Zoom Unlock", "Buka Zoom Kamera", "E" },
		{ "Free Camera", "Kamera Bebas", "E" },
		{ "Select Player (name)", "Pilih Player (nama)", "E" },
		{ "Type a player name first", "Ketik nama player dulu", "E" },
		{ "Player not found: ", "Player tidak ditemukan: " },
		{ "Spectate Player", "Amati Pemain", "E" },
		{ "Player Tracker", "Pelacak Pemain", "E" },
		{ "TP to Target", "TP ke Target", "E" },
		{ "Explosion Spam", "Spam Ledakan", "E" },
		{ "Particle Spam", "Spam Partikel", "E" },
		{ "Rejoin Server", "Gabung Ulang Server", "E" },
		{ "Server Hop", "Pindah Server", "E" },
		{ "Join User Server", "Masuk Server User", "E" },
		{ "username, press Enter", "username, tekan Enter", "E" },
		{ "Join User", "Masuk ke User", "E" },
		{ "Destroy Panel (Cleanup)", "Hancurkan Panel (Bersihkan)", "E" },
		{ "Collect All Food", "Kumpulkan Semua Makanan", "E" },
		{ "Drop All Food", "Buang Semua Makanan", "E" },
		{ "WalkSpeed (Direct)", "WalkSpeed (Langsung)", "E" },
		{ "Set target + toggle in the Farm tab.", "Atur target + toggle di tab Farm.", "E" },
		{ "Character Light", "Cahaya Karakter", "E" },
		{ "Fly Speed", "Kecepatan Fly", "E" },
		{ "Jump Power", "Kekuatan Lompat", "E" },
		{ "No Gravity", "Tanpa Gravitasi", "E" },
		{ "GRAB TOOLS", "AMBIL TOOLS", "E" },
		{ "DROP TOOLS", "JATUHKAN TOOLS", "E" },
		{ "Equip All", "Pakai Semua", "E" },
		{ "Fire All Prompts", "Jalankan Semua Prompt", "E" },
		{ "Fire ClickDetectors", "Jalankan ClickDetector", "E" },
		{ "Instant Prompt", "Prompt Instan", "E" },
		{ "SAVE WP", "SIMPAN WP", "E" },
		{ "Clear WP", "Hapus WP", "E" },
		{ "Copy Coords", "Salin Koordinat", "E" },
		{ "Hint / Word", "Petunjuk / Kata", "E" },
		{ "Hint Text", "Teks Petunjuk", "E" },
		{ "Clear Hint", "Hapus Petunjuk", "E" },
		{ "Reply Word (word chain)", "Reply Word (sambung kata)", "E" },
		{ "NPC Control", "Kontrol NPC", "E" },
		{ "Nearest NPC", "NPC Terdekat", "E" },
		{ "Restore Character", "Pulihkan Karakter", "E" },
		{ "Target Player", "Pemain Target", "E" },
		{ "TARGET: (not selected)", "TARGET: (belum dipilih)", "E" },
		{ "Search / select player name", "Cari / pilih nama player", "E" },
		{ "type name...", "ketik nama...", "E" },
		{ "Not found: ", "Tidak ketemu: " },
		{ "COPY ID", "SALIN ID", "E" },
		{ "COPY NAME", "SALIN NAMA", "E" },
		{ "Smooth", "Halus", "E" },
		{ "Hitbox Expand", "Perbesar Hitbox", "E" },
		{ "Hitbox Size", "Ukuran Hitbox", "E" },
		{ "Reach Size", "Ukuran Reach", "E" },
		{ "Fling (hits opponents)", "Fling (mengenai lawan)", "E" },
		{ "Fling Power", "Kekuatan Fling", "E" },
		{ "Orbit Radius", "Radius Orbit", "E" },
		{ "Clear Mesh", "Hapus Mesh", "E" },
		{ "External loaders", "Loader eksternal", "E" },
		{ "Load Dex Explorer", "Muat Dex Explorer", "E" },
		{ "Load RemoteSpy", "Muat RemoteSpy", "E" },
		{ "Load Infinite Yield", "Muat Infinite Yield", "E" },
		{ "Load Grab Tool", "Muat Grab Tool", "E" },
		{ "Crasher for other servers/clients: not included.", "Crasher server/client orang lain: tidak ditambah.", "E" },
		{ "Search player name", "Cari nama player", "E" },
		-- tombol HP / floating
		{ "ITEM NAME", "NAMA ITEM", "E" },
		{ "SEARCH / ITEM LIST", "SEARCH / DAFTAR ITEM", "E" },
		{ "TP TO ITEM", "TP KE ITEM", "E" },
		{ "PICKUP SELECTED", "AMBIL TERPILIH", "E" },
		{ "PICKUP NEAREST", "AMBIL TERDEKAT", "E" },
		{ "SPAWN DETECT", "DETEKSI SPAWN", "E" },
		{ "Spawn Markers ON", "Penanda Spawn ON", "E" },
		{ "Spawn Markers OFF", "Penanda Spawn OFF", "E" },
		{ "PLAYER NAME", "NAMA PLAYER", "E" },
		{ "SEARCH / PLAYER LIST", "SEARCH / DAFTAR PLAYER", "E" },
		{ "REJOIN", "GABUNG ULANG", "E" },
		{ "SERVER HOP", "PINDAH SERVER", "E" },
		{ "JOIN USER", "MASUK USER", "E" },
		{ "COLLECT FOOD", "KUMPUL MAKANAN", "E" },
		{ "DROP FOOD", "BUANG MAKANAN", "E" },
		{ "NO GRASS", "TANPA RUMPUT", "E" },
		{ "NO SHADOW", "TANPA BAYANGAN", "E" },
		{ "ZOOM UNLOCK", "BUKA ZOOM", "E" },
		{ "FREE CAM", "KAMERA BEBAS", "E" },
		{ "NO GRAV", "TANPA GRAV", "E" },
		{ "RESTORE CHAR", "PULIHKAN KARAKTER", "E" },
		{ "NPC NEAREST", "NPC TERDEKAT", "E" },
		{ "FIRE PROMPT", "JALANKAN PROMPT", "E" },
	}

	local EXen, EXid, FRen, FRid = {}, {}, {}, {}
	local lower, upper = string.lower, string.upper
	for _, p in ipairs(PAIRS) do
		local en, id, flag = p[1], p[2], p[3]
		if en ~= id then
			if flag == "E" then
				EXid[lower(en)] = id -- target ID: kunci = teks EN
				EXen[lower(id)] = en -- target EN: kunci = teks ID
			else
				FRid[#FRid + 1] = { en, id }
				FRen[#FRen + 1] = { id, en }
				local ue, ui = upper(en), upper(id)
				if ue ~= en and ui ~= id then
					FRid[#FRid + 1] = { ue, ui }
					FRen[#FRen + 1] = { ui, ue }
				end
			end
		end
	end
	table.sort(FRid, function(a, b) return #a[1] > #b[1] end)
	table.sort(FRen, function(a, b) return #a[1] > #b[1] end)

	-- terjemahkan satu teks ke bahasa "lang" ("en" / "id")
	function I.T(text, lang)
		if type(text) ~= "string" or text == "" then return text end
		local key = lang .. "|" .. text
		local hit = I.cache[key]
		if hit then return hit end
		local out = text
		local exMap = (lang == "en") and EXen or EXid
		local ex = exMap[lower(text)]
		local gly
		if not ex then
			local g, rest = string.match(text, "^([\128-\255]+)%s+(.+)$")
			if g and exMap[lower(rest)] then gly = g; ex = exMap[lower(rest)] end
		end
		if gly then
			out = gly .. " " .. ex
		elseif ex then
			if text == upper(text) and text ~= lower(text) then ex = upper(ex) end
			out = ex
		else
			local frs = (lang == "en") and FRen or FRid
			local hold, n = nil, 0
			for i = 1, #frs do
				local f = frs[i]
				local s, e = string.find(out, f[1], 1, true)
				while s do
					hold = hold or {}
					n = n + 1
					hold[n] = f[2]
					out = string.sub(out, 1, s - 1) .. "\1" .. n .. "\2" .. string.sub(out, e + 1)
					s, e = string.find(out, f[1], 1, true)
				end
			end
			if hold then
				out = (string.gsub(out, "\1(%d+)\2", function(i) return hold[tonumber(i)] end))
			end
		end
		if I.cacheN > 4000 then I.cache = {}; I.cacheN = 0 end
		I.cache[key] = out
		I.cacheN = I.cacheN + 1
		return out
	end

	local function apply(o, prop)
		local rec = orig[o]
		if not rec then return end
		local cur = o[prop]
		if type(cur) ~= "string" then return end
		if rec[prop .. "_set"] == cur then return end -- tulisan kita sendiri
		rec[prop] = cur
		local t = I.T(cur, I.lang)
		if t ~= cur then
			rec[prop .. "_set"] = t
			o[prop] = t
		else
			rec[prop .. "_set"] = nil
		end
	end

	local function reapply(o, rec, prop)
		local base = rec[prop]
		if base == nil then return end
		local t = I.T(base, I.lang)
		rec[prop .. "_set"] = t
		if o[prop] ~= t then o[prop] = t end
	end

	function I.Track(o)
		if orig[o] then return end
		local isTxt = o:IsA("TextLabel") or o:IsA("TextButton")
		local isBox = o:IsA("TextBox")
		if not (isTxt or isBox) then return end
		if o:GetAttribute("SRF_NoI18N") then return end
		orig[o] = {}
		if isTxt then
			apply(o, "Text")
			o:GetPropertyChangedSignal("Text"):Connect(function() pcall(apply, o, "Text") end)
		else -- TextBox: hanya placeholder (isi ketikan user tidak disentuh)
			apply(o, "PlaceholderText")
			o:GetPropertyChangedSignal("PlaceholderText"):Connect(function() pcall(apply, o, "PlaceholderText") end)
		end
	end

	function I.SetLang(lang)
		if lang ~= "en" and lang ~= "id" then return end
		I.lang = lang
		State.Lang = lang
		pcall(function() if writefile then writefile("srf_lang.dat", lang) end end)
		for o, rec in pairs(orig) do
			if o.Parent then
				pcall(function()
					if rec.Text ~= nil then reapply(o, rec, "Text") end
					if rec.PlaceholderText ~= nil then reapply(o, rec, "PlaceholderText") end
				end)
			end
		end
	end

	function I.Attach(gui)
		pcall(function()
			if readfile then
				local s = string.match(readfile("srf_lang.dat"), "%a+")
				if s == "en" or s == "id" then I.lang = s end
			end
		end)
		State.Lang = I.lang
		gui.DescendantAdded:Connect(function(o) pcall(I.Track, o) end)
		for _, o in ipairs(gui:GetDescendants()) do pcall(I.Track, o) end
	end
end

function Util.KeyName(kc)
	if not kc then return "?" end
	local n = tostring(kc):gsub("Enum.KeyCode.", "")
	local map = {
		One = "1", Two = "2", Three = "3", Four = "4", Five = "5",
		Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
		LeftBracket = "[", RightBracket = "]", Equals = "=", Minus = "-",
	}
	return map[n] or n
end

----------------------------------------------------------------
-- CLEANUP OLD (REVISI: bunuh instansi lama + semua host UI)
----------------------------------------------------------------
-- [BARU] bunuh instansi script sebelumnya lewat bridge getgenv
-- (mematikan SEMUA koneksi & loop script lama, bukan cuma GUI-nya)
pcall(function()
	if getgenv and getgenv().YOURSCRIPT_Cleanup then
		getgenv().YOURSCRIPT_Cleanup()
		getgenv().YOURSCRIPT_Cleanup = nil
	end
end)

Util.Safe(function()
	-- kumpulkan semua host UI yang mungkin dipakai
	local hosts = {}
	pcall(function() table.insert(hosts, Services.CG) end)                 -- CoreGui
	pcall(function()
		if gethui then table.insert(hosts, gethui()) end                   -- executor hidden UI
	end)
	pcall(function()
		local pg = LP:FindFirstChild("PlayerGui")
		if pg then table.insert(hosts, pg) end
	end)

	local names = {
		Config.Panel.Name,
		"YOURSCRIPTPanel",
		"DNCheatGUI",
		"YOURSCRIPTPanel",
	}
	for _, host in ipairs(hosts) do
		for _, n in ipairs(names) do
			local o = host:FindFirstChild(n)
			if o then o:Destroy() end
		end
	end
end)

----------------------------------------------------------------
-- NOTIFICATION
----------------------------------------------------------------
local function EnsureNotifHost()
	if UI.NotifHost then return end
	local h = Instance.new("Frame")
	h.Name = "NotifHost"
	h.Size = UDim2.new(0, 280, 1, 0)
	h.Position = UDim2.new(1, -300, 0, 60)
	h.BackgroundTransparency = 1
	h.Parent = UI.Gui
	Util.List(h, 8)
	UI.NotifHost = h
end

local function Notify(title, msg, color)
	EnsureNotifHost()
	color = color or Config.Theme.Accent
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 56)
	card.BackgroundColor3 = Config.Theme.Panel
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.Parent = UI.NotifHost
	Util.Corner(card, 14)
	Util.Stroke(card, Color3.fromRGB(255,255,255), 1, 0.85)
	-- slide-in
	card.Position = UDim2.new(0, 24, 0, 0)
	Util.Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, Config.Anim.Notif, Enum.EasingStyle.Quint)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 1, -12)
	bar.Position = UDim2.new(0, 8, 0, 6)
	bar.BackgroundColor3 = color
	bar.BorderSizePixel = 0
	bar.Parent = card
	Util.Corner(bar, 2)

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -24, 0, 18)
	t.Position = UDim2.new(0, 18, 0, 8)
	t.BackgroundTransparency = 1
	t.Text = title or "YOURSCRIPT"
	t.TextColor3 = color
	t.TextSize = 12
	t.Font = Config.Font.Bold
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = card

	local m = Instance.new("TextLabel")
	m.Size = UDim2.new(1, -24, 0, 18)
	m.Position = UDim2.new(0, 18, 0, 28)
	m.BackgroundTransparency = 1
	m.Text = msg or ""
	m.TextColor3 = Config.Theme.Text
	m.TextSize = 11
	m.Font = Config.Font.Reg
	m.TextXAlignment = Enum.TextXAlignment.Left
	m.Parent = card

	card.Position = UDim2.new(1, 40, 0, 0)
	Util.Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, Config.Anim.Notif)

	task.delay(2.4, function()
		Util.Tween(card, { BackgroundTransparency = 1 }, 0.25)
		pcall(function()
			Util.Tween(t, { TextTransparency = 1 }, 0.25)
			Util.Tween(m, { TextTransparency = 1 }, 0.25)
			Util.Tween(bar, { BackgroundTransparency = 1 }, 0.25)
			if card:FindFirstChildOfClass("UIStroke") then
				Util.Tween(card:FindFirstChildOfClass("UIStroke"), { Transparency = 1 }, 0.25)
			end
		end)
		task.wait(0.3)
		card:Destroy()
	end)
end

----------------------------------------------------------------
-- ESP MODULE
----------------------------------------------------------------
local ESP = {}

function ESP.EnsureFolder()
	if ESPFolder and ESPFolder.Parent then return ESPFolder end
	local f = Instance.new("Folder")
	f.Name = "YOURSCRIPT_ESP"
	f.Parent = Services.WS
	ESPFolder = f
	return f
end

function ESP.Clear(tag)
	-- Hancurkan billboard di cache saja (ANTI-LAG: jangan GetDescendants workspace)
	local function wipeCache(cache)
		if not cache then return end
		for _, entry in pairs(cache) do
			pcall(function() if entry.bb then entry.bb:Destroy() end end)
			pcall(function() if entry.hl then entry.hl:Destroy() end end)
			pcall(function() if entry.lbl then entry.lbl:Destroy() end end)
		end
	end
	if tag == "item" or not tag then
		wipeCache(ESP._cache)
		ESP._cache = nil
	end
	if tag == "monster" or not tag then
		wipeCache(ESP._mcache)
		ESP._mcache = nil
	end
	if tag == "player" or not tag then
		wipeCache(ESP._pcache)
		ESP._pcache = nil
	end
	if not ESPFolder then return end
	for _, o in ipairs(ESPFolder:GetChildren()) do
		if not tag or o:GetAttribute("Tag") == tag then
			pcall(function() o:Destroy() end)
		end
	end
end

function ESP.Billboard(adornee, text, color, tag)
	local bb = Instance.new("BillboardGui")
	bb.Name = "ESP_" .. (tag or "x")
	bb.Adornee = adornee
	bb.Size = UDim2.new(0, 160, 0, 40)
	bb.AlwaysOnTop = true
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb:SetAttribute("Tag", tag or "")
	bb.Parent = ESP.EnsureFolder()

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0.4
	lbl.TextSize = 12
	lbl.Font = Config.Font.Bold
	lbl.Parent = bb
	return bb, lbl
end

function ESP.Highlight(model, color, tag)
	local h = Instance.new("Highlight")
	h.Name = "CHAMS_" .. (tag or "")
	h.Adornee = model
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 0.65
	h.OutlineTransparency = 0.2
	h:SetAttribute("Tag", tag or "")
	h.Parent = ESP.EnsureFolder()
	return h
end

function ESP.UpdateItems(desc)
	-- Item ESP SUPER RINGAN (mobile-friendly)
	if not State.ItemESP then
		ESP.Clear("item")
		return
	end

	local root = Util.Root()
	if not root then return end

	-- throttle 1 detik (bukan 0.5)
	local now = os.clock()
	if ESP._itemLast and (now - ESP._itemLast) < 1.0 then return end
	ESP._itemLast = now

	local keep = {}
	local n = 0
	local maxItems = 25  -- cap ketat anti-lag
	local maxDist = math.min(Config.ESP.MaxDist or 2000, 400)  -- radius lebih kecil
	local rootPos = root.Position

	local list = {}
	local seen = {}
	local function add(o)
		if o and o.Parent and not seen[o] then
			seen[o] = true
			table.insert(list, o)
		end
	end

	-- 1. Hanya children langsung Wyposazenie (tidak GetDescendants)
	local wy = Services.WS:FindFirstChild("Wyposazenie")
	if wy then
		for _, c in ipairs(wy:GetChildren()) do
			local nm = tostring(c.Name)
			if not nm:match("^%d+_Wyposazenie$") and (c:IsA("Model") or c:IsA("Tool")) then
				add(c)
			end
		end
	end

	-- 2. Market: hanya folder top-level, children 1 level (bukan full descendants)
	local mkw = {"market", "mart", "six", "shop", "sklep", "toko", "warehouse", "gudang"}
	for _, o in ipairs(Services.WS:GetChildren()) do
		local nm = string.lower(o.Name)
		local ok = false
		for _, kw in ipairs(mkw) do
			if nm:find(kw, 1, true) then ok = true; break end
		end
		if ok then
			for _, d in ipairs(o:GetChildren()) do
				if d:IsA("Model") or d:IsA("Tool") then
					add(d)
				elseif d:IsA("Folder") then
					for _, e in ipairs(d:GetChildren()) do
						if e:IsA("Model") or e:IsA("Tool") then add(e) end
					end
				end
			end
		end
	end

	-- sort by distance, ambil terdekat saja
	local scored = {}
	for _, o in ipairs(list) do
		local part
		if o:IsA("BasePart") then part = o
		elseif o:IsA("Model") then part = o.PrimaryPart or o:FindFirstChildOfClass("BasePart") end
		if part then
			local dist = (part.Position - rootPos).Magnitude
			if dist <= maxDist then
				table.insert(scored, { o = o, part = part, dist = dist })
			end
		end
	end
	table.sort(scored, function(a, b) return a.dist < b.dist end)

	for i, s in ipairs(scored) do
		if n >= maxItems then break end
		local o, part, dist = s.o, s.part, s.dist
		local key = tostring(o)
		keep[key] = true
		local entry = ESP._cache and ESP._cache[key]
		local labelText = string.format("%s [%.0fm]", o.Name, dist)
		if not entry then
			entry = {}
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 130, 0, 18)
			bb.AlwaysOnTop = true
			bb.Adornee = part
			bb.Name = "SRF_ItemTrack"
			bb.StudsOffset = Vector3.new(0, 1.5, 0)
			bb.Parent = part
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = labelText
			lbl.TextColor3 = Config.ESP.Colors.Item
			lbl.TextSize = 11
			lbl.Font = Config.Font.Bold
			lbl.TextStrokeTransparency = 0.45
			lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
			lbl.Parent = bb
			entry.bb = bb
			entry.lbl = lbl
			ESP._cache = ESP._cache or {}
			ESP._cache[key] = entry
		else
			if entry.lbl then entry.lbl.Text = labelText end
			if entry.bb then entry.bb.Adornee = part end
		end
		n = n + 1
	end

	if ESP._cache then
		for k, entry in pairs(ESP._cache) do
			if not keep[k] then
				pcall(function() if entry.bb then entry.bb:Destroy() end end)
				ESP._cache[k] = nil
			end
		end
	end
end

function ESP.UpdateMonsters(desc)
	-- Monster ESP: track SEMUA monster di folder *Night
	if not State.MonsterESP and not State.MonsterTracker then
		ESP.Clear("monster")
		return
	end

	-- ANTI-LAG throttle 1.0s
	local now = os.clock()
	if ESP._monsterLast and (now - ESP._monsterLast) < 1.0 then return end
	ESP._monsterLast = now

	local root = Util.Root()
	if not root then return end

	local keep = {}
	local candidates = {}
	local seen = {}

	local function getPart(model)
		if not model then return nil end
		return model.PrimaryPart
			or model:FindFirstChild("HumanoidRootPart")
			or model:FindFirstChild("Torso")
			or model:FindFirstChild("UpperTorso")
			or model:FindFirstChild("Head")
			or model:FindFirstChildWhichIsA("BasePart", true)
	end

	local function consider(o)
		if not o or seen[o] then return end
		if not o:IsA("Model") then return end
		if Services.Players:GetPlayerFromCharacter(o) then return end
		seen[o] = true

		-- Semua model di dalam folder *Night = monster
		if Util.InNightFolder(o) then
			table.insert(candidates, o)
			return
		end
		if Util.IsMonster(o) then
			table.insert(candidates, o)
			return
		end
		-- fallback nama
		local nm = string.lower(o.Name)
		if nm:find("lurker") or nm:find("pocong") or nm:find("jumper")
			or nm:find("samara") or nm:find("catcher") or nm:find("monster") then
			table.insert(candidates, o)
		end
	end

	-- 1. Scan semua folder *Night (children only — ANTI-LAG, skip nested GetDescendants)
	for _, folder in ipairs(Services.WS:GetChildren()) do
		if (folder:IsA("Folder") or folder:IsA("Model")) and folder.Name:match("Night$") then
			for _, child in ipairs(folder:GetChildren()) do
				consider(child)
			end
		end
	end

	-- 2. Top-level
	for _, o in ipairs(Services.WS:GetChildren()) do
		consider(o)
	end

	local nearest, nearDist = nil, math.huge

	for _, o in ipairs(candidates) do
		local part = getPart(o)
		if part then
			local dist = (part.Position - root.Position).Magnitude

			-- unique key per instance (bukan per nama)
			local key = "m_" .. tostring(o:GetDebugId() or o)

			if State.MonsterESP and dist <= Config.ESP.MaxDist then
				keep[key] = true
				local entry = ESP._mcache and ESP._mcache[key]
				local txt = o.Name
				if State.DistESP then
					txt = txt .. string.format(" [%.0fm]", dist)
				end

				if not entry then
					entry = {}
					local bb, lbl = ESP.Billboard(part, txt, Config.ESP.Colors.Monster, "monster")
					entry.bb, entry.lbl = bb, lbl
					if State.Chams then
						entry.hl = ESP.Highlight(o, Config.ESP.Colors.Monster, "monster")
					end
					ESP._mcache = ESP._mcache or {}
					ESP._mcache[key] = entry
				else
					if entry.lbl then
						entry.lbl.Text = txt
					end
					if entry.bb then
						entry.bb.Adornee = part
					end
				end
			end

			if dist < nearDist then
				nearest, nearDist = o, dist
			end
		end
	end

	if ESP._mcache then
		for k, entry in pairs(ESP._mcache) do
			if not keep[k] then
				pcall(function() if entry.bb then entry.bb:Destroy() end end)
				pcall(function() if entry.hl then entry.hl:Destroy() end end)
				ESP._mcache[k] = nil
			end
		end
	end

	if State.MonsterAlert and nearest and nearDist < 80 then
		if not State._lastAlert or os.clock() - State._lastAlert > 4 then
			State._lastAlert = os.clock()
			Notify("MONSTER ALERT", string.format("%s  %.0fm", nearest.Name, nearDist), Config.Theme.Red)
		end
	end

	if State.MonsterTracker and UI.TrackerLbl then
		if nearest then
			UI.TrackerLbl.Text = string.format("MONSTER: %s  %.0fm", nearest.Name, nearDist)
			UI.TrackerLbl.TextColor3 = Config.Theme.Red
		else
			UI.TrackerLbl.Text = "MONSTER: -"
			UI.TrackerLbl.TextColor3 = Config.Theme.Sub
		end
	end
end

function ESP.UpdatePlayers()
	if not State.PlayerESP and not State.PlayerTracker then ESP.Clear("player"); return end
	-- ANTI-LAG throttle 0.75s
	local now = os.clock()
	if ESP._playerLast and (now - ESP._playerLast) < 0.75 then return end
	ESP._playerLast = now
	local root = Util.Root()
	if not root then return end
	local nearest, nearDist = nil, math.huge
	local keep = {}
	for _, plr in ipairs(Util.GetPlayers()) do
		local r = Util.Root(plr)
		if r then
			local dist = (r.Position - root.Position).Magnitude
			if State.PlayerESP and dist <= Config.ESP.MaxDist then
				local col = Config.ESP.Colors.Player
				local key = "p_" .. tostring(plr.UserId)
				keep[key] = true
				local entry = ESP._pcache and ESP._pcache[key]
				if not entry then
					entry = {}
					local txt = plr.DisplayName or plr.Name
					if State.DistESP then txt = txt .. string.format(" [%.0fm]", dist) end
					local bb, lbl = ESP.Billboard(r, txt, col, "player")
					entry.bb, entry.lbl = bb, lbl
					if State.Chams and plr.Character then
						entry.hl = ESP.Highlight(plr.Character, col, "player")
					end
					ESP._pcache = ESP._pcache or {}
					ESP._pcache[key] = entry
				else
					if entry.lbl and State.DistESP then
						entry.lbl.Text = (plr.DisplayName or plr.Name) .. string.format(" [%.0fm]", dist)
					end
					if entry.bb then entry.bb.Adornee = r end
				end
			end
			if dist < nearDist then nearest, nearDist = plr, dist end
		end
	end
	if ESP._pcache then
		for k, entry in pairs(ESP._pcache) do
			if not keep[k] then
				if entry.bb then pcall(function() entry.bb:Destroy() end) end
				if entry.hl then pcall(function() entry.hl:Destroy() end) end
				ESP._pcache[k] = nil
			end
		end
	end
	if State.PlayerTracker and UI.PTrackerLbl then
		if nearest then
			UI.PTrackerLbl.Text = string.format("PLAYER: %s  %.0fm", nearest.DisplayName or nearest.Name, nearDist)
			UI.PTrackerLbl.TextColor3 = Config.Theme.Accent
		else
			UI.PTrackerLbl.Text = "PLAYER: -"
			UI.PTrackerLbl.TextColor3 = Config.Theme.Sub
		end
	end
end

function ESP.StartLoop()
	Util.Disconnect("ESPLoop")
	local acc = 0
	-- ANTI-LAG (B): label/highlight max 4x per detik, bukan tiap RenderStepped.
	-- Heartbeat + akumulator: update hanya tiap Config.ESP.UpdateRate (diset 0.25 = 4x/detik).
	Util.Connect("ESPLoop", Services.RS.Heartbeat, function(dt)
		acc = acc + dt
		if acc < Config.ESP.UpdateRate then return end
		acc = 0
		-- ANTI-LAG (C): loop mati sendiri kalau semua fitur berat mati (tidak jalan hampa tiap frame)
		if not State.ItemESP and not State.MonsterESP and not State.PlayerESP
			and not State.MonsterTracker and not State.PlayerTracker then
			Util.Disconnect("ESPLoop")
			return
		end
		-- ANTI-LAG: jangan panggil GetWS() penuh tiap tick (Update* sudah scan sendiri ringan)
		Util.Safe(function() ESP.UpdateItems(nil) end)
		Util.Safe(function() ESP.UpdateMonsters(nil) end)
		Util.Safe(ESP.UpdatePlayers)
	end)
end

function ESP.StopAll()
	Util.Disconnect("ESPLoop")
	ESP._cache, ESP._mcache, ESP._pcache = nil, nil, nil
	ESP.Clear()
	if ESPFolder then ESPFolder:Destroy(); ESPFolder = nil end
end

----------------------------------------------------------------
-- MOVEMENT MODULE
----------------------------------------------------------------
local Movement = {}

-- base walkspeed normal (jangan pakai nilai yang sudah di-multiply)
local function MovementBaseSpeed(hum)
	if State.BaseSpeed and State.BaseSpeed > 0 and State.BaseSpeed <= 24 then
		return State.BaseSpeed
	end
	local ws = hum and hum.WalkSpeed or 16
	-- kalau hum sudah di-boost, jangan jadikan base
	if ws <= 0 or ws > 24 then ws = 16 end
	return ws
end

function Movement.EnableSpeed()
	local hum = Util.Hum()
	if not hum then return end
	-- selalu hitung base bersih (16-ish), jangan ambil WalkSpeed yang sudah x multiplier
	if not State.BaseSpeed or State.BaseSpeed > 24 then
		State.BaseSpeed = MovementBaseSpeed(hum)
	end
	local base = State.BaseSpeed or 16
	hum.WalkSpeed = base * (State.SpeedMul or 1)
	State.SpeedOn = true
	Util.Disconnect("SpeedKeep") -- ganti koneksi lama
	Util.Connect("SpeedKeep", Services.RS.Heartbeat, function(dt)
		if not State.SpeedOn then return end
		SpdAcc = (SpdAcc or 0) + dt
		if SpdAcc < 0.1 then return end
		SpdAcc = 0
		local h = Util.Hum()
		if not h then return end
		local b = State.BaseSpeed or 16
		if b > 24 then b = 16; State.BaseSpeed = 16 end
		h.WalkSpeed = b * (State.SpeedMul or 1)
	end)
	Notify("YOURSCRIPT", "Speed Enabled  x" .. string.format("%.1f", State.SpeedMul or 1), Config.Theme.Green)
end

function Movement.DisableSpeed()
	State.SpeedOn = false
	Util.Disconnect("SpeedKeep")
	local base = 16
	if State.BaseSpeed and State.BaseSpeed > 0 and State.BaseSpeed <= 24 then
		base = State.BaseSpeed
	end
	State.BaseSpeed = nil -- jangan bawa base rusak ke sesi berikutnya
	local hum = Util.Hum()
	if hum then
		hum.WalkSpeed = base
	end
	Notify("YOURSCRIPT", "Speed Disabled", Config.Theme.Sub)
end

function Movement.ToggleSpeed()
	if State.SpeedOn then Movement.DisableSpeed() else Movement.EnableSpeed() end
end

-- langkah tombol -/+ : 0.1 di rentang slowmo (0.1 - 1), 1.0 di atas 1
function Movement.SpeedStep(cur, dir)
	local v
	if dir > 0 then
		v = (cur < 1 - 1e-6) and (cur + 0.1) or (cur + 1)
	else
		v = (cur <= 1 + 1e-6) and (cur - 0.1) or (cur - 1)
	end
	return math.floor(v * 10 + 0.5) / 10
end

function Movement.SetSpeedMul(v)
	v = math.floor(v * 10 + 0.5) / 10
	State.SpeedMul = math.clamp(v, Config.Movement.SpeedMin, Config.Movement.SpeedMax)
	if State.SpeedOn then
		local hum = Util.Hum()
		local b = State.BaseSpeed or 16
		if b > 24 then b = 16; State.BaseSpeed = 16 end
		if hum then hum.WalkSpeed = b * State.SpeedMul end
	end
end

function Movement.EnableFly()
	local root, hum = Util.Root(), Util.Hum()
	if not root or not hum then return end
	if State._flyConn then return end

	hum.PlatformStand = true
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)

	pcall(function()
		if FlyParts.gyro then FlyParts.gyro:Destroy() end
		if FlyParts.vel then FlyParts.vel:Destroy() end
	end)
	FlyParts = {}

	local gyro = Instance.new("BodyGyro")
	gyro.Name = "SRF_FlyGyro"
	gyro.P = 3e4
	gyro.D = 500
	gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	gyro.CFrame = root.CFrame
	gyro.Parent = root

	local vel = Instance.new("BodyVelocity")
	vel.Name = "SRF_FlyVel"
	vel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	vel.P = 1250
	vel.Velocity = Vector3.zero
	vel.Parent = root

	FlyParts.gyro, FlyParts.vel = gyro, vel
	local speed = State.FlySpeedVal or Config.Movement.FlySpeed or 80
	local smooth = Vector3.zero

	State._flyConn = Services.RS.RenderStepped:Connect(function(dt)
		if not State.FlyOn then return end
		local r = Util.Root()
		local h = Util.Hum()
		if not r or not FlyParts.vel or not FlyParts.gyro then return end
		local cam = Services.WS.CurrentCamera
		if not cam then return end

		local UIS = Services.UIS
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local mv = Vector3.zero

		speed = State.FlySpeedVal or Config.Movement.FlySpeed or 80
		local ax = State.FlyMoveX or 0
		local ay = State.FlyMoveY or 0
		if UIS:IsKeyDown(Enum.KeyCode.W) then ay = ay + 1 end
		if UIS:IsKeyDown(Enum.KeyCode.S) then ay = ay - 1 end
		if UIS:IsKeyDown(Enum.KeyCode.A) then ax = ax - 1 end
		if UIS:IsKeyDown(Enum.KeyCode.D) then ax = ax + 1 end

		if h and (math.abs(ax) + math.abs(ay)) < 0.05 then
			local md = h.MoveDirection
			if md.Magnitude > 0.05 then
				local lookFlat = Vector3.new(look.X, 0, look.Z)
				local rightFlat = Vector3.new(right.X, 0, right.Z)
				if lookFlat.Magnitude > 0.01 then lookFlat = lookFlat.Unit end
				if rightFlat.Magnitude > 0.01 then rightFlat = rightFlat.Unit end
				mv = look * md:Dot(lookFlat) + right * md:Dot(rightFlat)
			end
		else
			mv = look * ay + right * ax
		end

		if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.E) then
			mv = mv + Vector3.new(0, 1, 0)
		end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl)
			or UIS:IsKeyDown(Enum.KeyCode.Q) then
			mv = mv - Vector3.new(0, 1, 0)
		end

		-- Orientasi tegak
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude < 0.05 then
			flatLook = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
		end
		if flatLook.Magnitude > 0.05 then
			FlyParts.gyro.CFrame = CFrame.lookAt(r.Position, r.Position + flatLook.Unit)
		end

		-- Smooth velocity + hold altitude saat idle
		local target = Vector3.zero
		if mv.Magnitude > 0.05 then
			target = mv.Unit * speed
		end
		smooth = smooth:Lerp(target, math.clamp(dt * 8, 0.1, 1))
		FlyParts.vel.Velocity = smooth
		r.AssemblyAngularVelocity = Vector3.zero
	end)

	State.FlyOn = true
	if UI.FlyUpBtn then UI.FlyUpBtn.Visible = false end
	if UI.FlyDownBtn then UI.FlyDownBtn.Visible = false end
	if UI.FlyPad then UI.FlyPad.Visible = false end
	Notify("YOURSCRIPT", "Fly ON — joystick + putar kamera", Config.Theme.Green)
end

function Movement.DisableFly()
	Util.Disconnect("Fly")
	if State._flyConn then
		pcall(function() State._flyConn:Disconnect() end)
		State._flyConn = nil
	end
	pcall(function()
		if FlyParts.gyro then FlyParts.gyro:Destroy() end
		if FlyParts.vel then FlyParts.vel:Destroy() end
	end)
	FlyParts = {}
	local hum = Util.Hum()
	if hum then
		hum.PlatformStand = false
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
	end
	State.FlyOn = false
	State.FlyUp, State.FlyDown = false, false
	State.FlyMoveX, State.FlyMoveY = 0, 0
	if UI.FlyUpBtn then UI.FlyUpBtn.Visible = false end
	if UI.FlyDownBtn then UI.FlyDownBtn.Visible = false end
	if UI.FlyPad then UI.FlyPad.Visible = false end
	Notify("YOURSCRIPT", "Fly Disabled", Config.Theme.Sub)
end

function Movement.ToggleFly()
	if State.FlyOn then Movement.DisableFly() else Movement.EnableFly() end
end

function Movement.EnableNoclip()
	State.NoclipOn = true
	local ncParts, ncChar = {}, nil
	Util.Connect("Noclip", Services.RS.Stepped, function()
		if not State.NoclipOn then return end
		local c = Util.Char()
		if not c then ncParts, ncChar = {}, nil; return end
		if c ~= ncChar then
			ncChar, ncParts = c, {}
			for _, bp in ipairs(c:GetDescendants()) do
				if bp:IsA("BasePart") then table.insert(ncParts, bp) end
			end
		end
		for _, bp in ipairs(ncParts) do bp.CanCollide = false end
	end)
	Notify("YOURSCRIPT", "Noclip Enabled", Config.Theme.Green)
end

function Movement.DisableNoclip()
	State.NoclipOn = false
	Util.Disconnect("Noclip")
	Notify("YOURSCRIPT", "Noclip Disabled", Config.Theme.Sub)
end

function Movement.ToggleNoclip()
	if State.NoclipOn then Movement.DisableNoclip() else Movement.EnableNoclip() end
end

function Movement.EnableInfJump()
	State.InfJumpOn = true
	Util.Connect("InfJump", Services.UIS.JumpRequest, function()
		if not State.InfJumpOn then return end
		local hum = Util.Hum()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
	Notify("YOURSCRIPT", "Infinite Jump Enabled", Config.Theme.Green)
end

function Movement.DisableInfJump()
	State.InfJumpOn = false
	Util.Disconnect("InfJump")
	Notify("YOURSCRIPT", "Infinite Jump Disabled", Config.Theme.Sub)
end

function Movement.ToggleInfJump()
	if State.InfJumpOn then Movement.DisableInfJump() else Movement.EnableInfJump() end
end

----------------------------------------------------------------
-- TELEPORT MODULE
----------------------------------------------------------------
local Teleport = {}

function Teleport.SavePos()
	local r = Util.Root()
	if r then
		State.SavedPos = r.CFrame
		Notify("YOURSCRIPT", "Position Saved", Config.Theme.Accent)
	end
end

function Teleport.ReturnPos()
	local r = Util.Root()
	if not r or not State.SavedPos then
		Notify("YOURSCRIPT", "No Saved Position", Config.Theme.Orange)
		return
	end
	local cur = r.CFrame
	r.CFrame = State.SavedPos
	State.SavedPos = cur
	Notify("YOURSCRIPT", "Returned to Position", Config.Theme.Accent)
end

function Teleport.ToPart(part)
	local r = Util.Root()
	if r and part then
		if not State.SavedPos then State.SavedPos = r.CFrame end
		r.CFrame = part.CFrame * CFrame.new(0, 3, 0)
		return true
	end
	return false
end

function Teleport.ToKeywords(kws, label)
	local part = Util.FindByKeywords(kws)
	if part and Teleport.ToPart(part) then
		Notify("YOURSCRIPT", "TP " .. (label or "OK"), Config.Theme.Accent)
		return true
	end
	Notify("YOURSCRIPT", "Location Not Found: " .. (label or "?"), Config.Theme.Orange)
	return false
end

-- [MERGED] TP Bunker: pakai metode asli dangerousnight (attribute + folder Bunkers),
-- lalu fallback ke pencarian keyword YOURSCRIPT.
function Teleport.Bunker()
	local r = Util.Root()
	if r then
		local bunkerName = LP:GetAttribute("AssignedBunkerName")
		local bunkers = Services.WS:FindFirstChild("Bunkers")
		if bunkerName and bunkers then
			local bunker = bunkers:FindFirstChild(bunkerName)
			if bunker then
				local spawn = bunker:FindFirstChild("SpawnLocation")
				if spawn then
					Teleport.ToPart(spawn)
					Notify("YOURSCRIPT", "TP Bunker", Config.Theme.Accent)
					return
				end
			end
		end
	end
	if Teleport.ToKeywords(Config.Keywords.Bunker, "Bunker") then return end
	Notify("YOURSCRIPT", "Bunker Not Found", Config.Theme.Orange)
end

function Teleport.Market()
	if not Teleport.ToKeywords(Config.Keywords.Market, "Market") then
		local r = Util.Root()
		if r then
			if not State.SavedPos then State.SavedPos = r.CFrame end
			r.CFrame = CFrame.new(143, 5, -118)
			Notify("YOURSCRIPT", "TP Market (fallback)", Config.Theme.Accent)
		end
	end
end

function Teleport.Rare()
	if not Teleport.ToKeywords(Config.Keywords.Rare, "Rare Room") then
		local r = Util.Root()
		if r then
			if not State.SavedPos then State.SavedPos = r.CFrame end
			r.CFrame = CFrame.new(143, 5, -60)
			Notify("YOURSCRIPT", "TP Rare (fallback)", Config.Theme.Accent)
		end
	end
end



-- Titik spawn monster (dari log in-game — posisi pertama kali muncul)
State._spawnDB = State._spawnDB or {
	{ name = "Pocong A",     pos = Vector3.new(410, 8, 290) },
	{ name = "Pocong B",     pos = Vector3.new(410, 8, -630) },
	{ name = "Pocong C",     pos = Vector3.new(390, 8, 575) },
	{ name = "Pocong D",     pos = Vector3.new(415, 8, -330) },
	{ name = "Pocong E",     pos = Vector3.new(85, 8, -330) },
	{ name = "Pocong F",     pos = Vector3.new(115, 8, 280) },
	{ name = "Pocong G",     pos = Vector3.new(90, 9, -5) },
	{ name = "Pocong/Lurker", pos = Vector3.new(-13, 9, 167) },
	{ name = "Pocong H",     pos = Vector3.new(390, 8, -35) },
	{ name = "Lurker A",     pos = Vector3.new(403, 8, -23) },
	{ name = "Lurker B",     pos = Vector3.new(403, 9, 279) },
	{ name = "Jumper2 A",    pos = Vector3.new(45, 10, -225) },
	{ name = "Jumper2 B",    pos = Vector3.new(44, 10, 179) },
	{ name = "Jumper2 C",    pos = Vector3.new(335, 9, 580) },
	{ name = "Jumper2 D",    pos = Vector3.new(320, 9, -615) },
	{ name = "Jumper2 E",    pos = Vector3.new(360, 9, -320) },
	{ name = "Jumper2 F",    pos = Vector3.new(330, 9, 229) },
	{ name = "Jumper2 G",    pos = Vector3.new(380, 9, -50) },
	{ name = "JumperDoor A", pos = Vector3.new(738, 5.5, -734) },
	{ name = "JumperDoor B", pos = Vector3.new(736, 5.5, -740) },
	{ name = "JumperDoor C", pos = Vector3.new(733, 5, -746) },
	{ name = "JumperDoor D", pos = Vector3.new(740, 5.5, -742) },
	{ name = "Samara A",     pos = Vector3.new(121, 6, 178) },
	{ name = "Samara B",     pos = Vector3.new(75, 6, -136) },
	{ name = "Samara C",     pos = Vector3.new(369, 5, 150) },
	{ name = "Samara D",     pos = Vector3.new(393, 5, -118) },
	{ name = "Samara E",     pos = Vector3.new(-45, 6, 42) },
	{ name = "Samara F",     pos = Vector3.new(-189, 6, 42) },
	-- Catcher chamber area (dari scan ReplicatedStorage TRAP)
	{ name = "Catcher Zone", pos = Vector3.new(411, 14, 0) },
}

State._spawnIdx = State._spawnIdx or 1

function Teleport.ToSpawn(idx)
	local db = State._spawnDB
	if not db or #db == 0 then
		Notify("Spawn", "Database spawn kosong", Config.Theme.Orange)
		return
	end
	idx = idx or State._spawnIdx or 1
	if idx < 1 then idx = #db end
	if idx > #db then idx = 1 end
	State._spawnIdx = idx
	local sp = db[idx]
	local root = Util.Root()
	if not root then return end
	root.CFrame = CFrame.new(sp.pos + Vector3.new(0, 3, 0))
	Notify("Spawn", string.format("TP → %s  (%d/%d)", sp.name, idx, #db), Config.Theme.Accent)
	if UI.SpawnLbl then
		UI.SpawnLbl.Text = string.format("SPAWN: %s (%d/%d)", sp.name, idx, #db)
	end
end

function Teleport.NextSpawn()
	State._spawnIdx = (State._spawnIdx or 1) + 1
	Teleport.ToSpawn(State._spawnIdx)
end

function Teleport.PrevSpawn()
	State._spawnIdx = (State._spawnIdx or 1) - 1
	Teleport.ToSpawn(State._spawnIdx)
end

function Teleport.ToPlayer(plr)
	plr = plr or State.TargetPlayer or State.Target
	if not plr then
		Notify("YOURSCRIPT", "No Target Selected", Config.Theme.Orange)
		return
	end
	local tr = Util.Root(plr)
	if not tr then
		Notify("YOURSCRIPT", "Target Has No Character", Config.Theme.Orange)
		return
	end
	Teleport.ToPart(tr)
	Notify("YOURSCRIPT", "TP to " .. (plr.DisplayName or plr.Name), Config.Theme.Accent)
end

-- [MERGED] dari dangerousnight.lua: TP ke player berdasarkan nama (fuzzy match)
function Teleport.ToPlayerByName(name)
	name = tostring(name or ""):lower()
	if name == "" then
		Notify("YOURSCRIPT", "Type a Player Name First", Config.Theme.Orange)
		return
	end
	for _, p in ipairs(Services.Players:GetPlayers()) do
		if p ~= LP then
			local n = p.Name:lower()
			local dn = (p.DisplayName or ""):lower()
			if string.find(n, name, 1, true) or string.find(dn, name, 1, true) then
				State.TargetPlayer = p
				State.Target = p
				local list = Util.GetPlayers()
				for i, pl in ipairs(list) do
					if pl == p then State.TargetIdx = i; break end
				end
				pcall(Teleport.RefreshTarget)
				State.TargetPlayer = p
				State.Target = p
				Teleport.ToPlayer(p)
				return
			end
		end
	end
	Notify("YOURSCRIPT", "Player Not Found: " .. name, Config.Theme.Orange)
end

function Teleport.EnableClickTP()
	State.ClickTP = true
	Util.Connect("ClickTP", Mouse.Button1Down, function()
		if not State.ClickTP then return end
		if Services.UIS:IsKeyDown(Enum.KeyCode.LeftControl) or true then
			local r = Util.Root()
			if r and Mouse.Hit then
				r.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
			end
		end
	end)
	Notify("YOURSCRIPT", "Click TP Enabled", Config.Theme.Green)
end

function Teleport.DisableClickTP()
	State.ClickTP = false
	Util.Disconnect("ClickTP")
	Notify("YOURSCRIPT", "Click TP Disabled", Config.Theme.Sub)
end

function Teleport.ToggleClickTP()
	if State.ClickTP then Teleport.DisableClickTP() else Teleport.EnableClickTP() end
end

function Teleport.RefreshTarget()
	local list = Util.GetPlayers()
	if #list == 0 then
		State.Target = nil
		State.TargetPlayer = nil
		if UI.TargetLbl then UI.TargetLbl.Text = "TARGET: -" end
		if UI.TargetLbl2 then UI.TargetLbl2.Text = "TARGET: -" end
		return
	end
	if State.TargetIdx < 1 or State.TargetIdx > #list then State.TargetIdx = 1 end
	State.Target = list[State.TargetIdx]
	State.TargetPlayer = State.Target -- [FIX] Spectate + TP Target nyambung
	local targetName = State.Target.DisplayName or State.Target.Name
	if UI.TargetLbl then UI.TargetLbl.Text = "TARGET: " .. targetName end
	if UI.TargetLbl2 then UI.TargetLbl2.Text = "TARGET: " .. targetName end
end

function Teleport.PrevPlayer()
	local list = Util.GetPlayers()
	if #list == 0 then Teleport.RefreshTarget(); return end
	State.TargetIdx = State.TargetIdx - 1
	if State.TargetIdx < 1 then State.TargetIdx = #list end
	Teleport.RefreshTarget()
end

function Teleport.NextPlayer()
	local list = Util.GetPlayers()
	if #list == 0 then Teleport.RefreshTarget(); return end
	State.TargetIdx = State.TargetIdx + 1
	if State.TargetIdx > #list then State.TargetIdx = 1 end
	Teleport.RefreshTarget()
end

-- [REVISI] Scan HANYA saat dipanggil (tombol REFRESH), bukan tiap tekan </>
function Teleport.IsItemCandidate(obj)
	if not obj then return false end
	if obj:IsA("Model") and Services.Players:GetPlayerFromCharacter(obj) then return false end
	if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return false end
	if obj:IsA("BasePart") and obj.Parent and Services.Players:GetPlayerFromCharacter(obj.Parent) then return false end
	if obj:IsA("Terrain") or obj:IsA("Camera") then return false end
	return obj:IsA("BasePart") or obj:IsA("Model")
end

-- [REVISI] Place = benda statis (tidak bisa diambil), Item = benda yang bisa diambil
local PLACE_EXCLUDE = nil -- opsional: daftar nama yang dikecualikan, contoh: {"Grass", "Water"}

local function GetPartOf(o)
	return o:IsA("BasePart") and o
		or (o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildOfClass("BasePart")))
end

-- [REVISI] Deteksi grabbable yang lebih lengkap:
-- Tool dengan Handle, punya ProximityPrompt, punya ClickDetector,
-- atau nama mengandung kata pickup (ambil/grab/pick/collect/dll)
local function HasPickupTrait(o)
	-- cek langsung (murah)
	if o:FindFirstChildOfClass("ProximityPrompt") then return true end
	if o:FindFirstChildOfClass("ClickDetector") then return true end
	-- cek 1 level ke dalam (part/tool di dalam model)
	for _, c in ipairs(o:GetChildren()) do
		if c:IsA("ProximityPrompt") or c:IsA("ClickDetector") then return true end
		if c:IsA("BasePart") and (c:FindFirstChildOfClass("ProximityPrompt") or c:FindFirstChildOfClass("ClickDetector")) then
			return true
		end
		-- Tool sebagai child (misal model berisi tool yang bisa diambil)
		if c:IsA("Tool") and c:FindFirstChild("Handle") then return true end
	end
	-- keyword pickup dari nama
	local nm = string.lower(o.Name)
	for _, kw in ipairs(Config.Keywords.Pickup) do
		if nm:find(kw, 1, true) then return true end
	end
	return false
end

local function PartHasPickupTrait(o)
	if o:IsA("BasePart") and (o:FindFirstChildOfClass("ProximityPrompt") or o:FindFirstChildOfClass("ClickDetector")) then
		return true
	end
	-- [REVISI] batasi ke 2 level (GetChildren, bukan GetDescendants) — hindari scan ribuan objek
	if o:IsA("Model") or o:IsA("Tool") then
		for _, c in ipairs(o:GetChildren()) do
			if c:IsA("ProximityPrompt") or c:IsA("ClickDetector") then return true end
			if c:IsA("BasePart") and (c:FindFirstChildOfClass("ProximityPrompt") or c:FindFirstChildOfClass("ClickDetector")) then
				return true
			end
			if c:IsA("Model") or c:IsA("Tool") then
				for _, g in ipairs(c:GetChildren()) do
					if g:IsA("ProximityPrompt") or g:IsA("ClickDetector") then return true end
					if g:IsA("BasePart") and (g:FindFirstChildOfClass("ProximityPrompt") or g:FindFirstChildOfClass("ClickDetector")) then
						return true
					end
				end
			end
		end
	end
	return false
end

local function IsGrabbable(o)
	-- [BARU] semua model di folder Wyposazenie = item yang bisa diambil (lemari dll)
	local p = o
	while p and p ~= Services.WS do
		if p.Name == "Wyposazenie" then return true end
		p = p.Parent
	end
	if o:IsA("Tool") and o:FindFirstChild("Handle") then return true end
	if o:IsA("BasePart") and (o:FindFirstChildOfClass("ProximityPrompt") or o:FindFirstChildOfClass("ClickDetector")) then
		return true
	end
	if (o:IsA("Model") or o:IsA("Tool")) and PartHasPickupTrait(o) then return true end
	if Util.IsItem(o) and GetPartOf(o) then return true end
	if HasPickupTrait(o) and GetPartOf(o) then return true end
	return false
end

local function IsExcludedPlace(name)
	if type(PLACE_EXCLUDE) ~= "table" then return false end
	local n = string.lower(name or "")
	for _, kw in ipairs(PLACE_EXCLUDE) do
		if n:find(string.lower(tostring(kw)), 1, true) then return true end
	end
	return false
end

local function IsPlaceCandidate(o)
	if not o then return false end
	if o:IsA("Terrain") or o:IsA("Camera") or o:IsA("Light") then return false end
	if o:IsA("BasePart") and o.Parent and Services.Players:GetPlayerFromCharacter(o.Parent) then return false end
	if o:IsA("Model") and Services.Players:GetPlayerFromCharacter(o) then return false end
	if o:FindFirstChildOfClass("Humanoid") then return false end
	if IsGrabbable(o) then return false end   -- yang bisa diambil = ITEM, bukan PLACE
	if GetPartOf(o) == nil then return false end
	return true
end

----------------------------------------------------------------
-- [REVISI] BACKGROUND SCAN CACHE — anti-lag
-- Workspace discan bertahap di background; tombol refresh hanya baca cache.
----------------------------------------------------------------
local ScanCache = {
	Items = {},   -- semua instance grabbable (Tool/item)
	Places = {},  -- semua benda statis (BasePart/Model, bukan player)
	Ready = false,
	Scanning = false,
	Progress = 0,
	Total = 0,
}

-- [REVISI] daftar nama parent yang di-skip (sangat besar, tidak berguna utk item/place)
local SCAN_SKIP = { Terrain = true, Camera = true }

-- scan SATU daftar descendant (dipanggil bertahap, per chunk)
-- ANTI-LAG (A): yield tiap 400 objek + budget waktu 8ms per chunk — HP kentang tidak freeze.
local function ScanChunk(descList)
	local processed = 0
	local t0 = os.clock()
	for _, o in ipairs(descList) do
		-- skip karakter & semua bagian tubuh player (paling banyak partnya)
		local owner = o.Parent and Services.Players:GetPlayerFromCharacter(o.Parent)
			or Services.Players:GetPlayerFromCharacter(o)
		if not owner then
			if o:IsA("BasePart") then
				-- [REVISI] BasePart TIDAK di-skip lagi — cek trait pickup langsung di part
				if o:FindFirstChildOfClass("ProximityPrompt") or o:FindFirstChildOfClass("ClickDetector") then
					table.insert(ScanCache.Items, o)
				else
					-- benda statis → PLACE
					local holder = o.Parent
					local isModelPlace = holder and holder:IsA("Model")
						and not Services.Players:GetPlayerFromCharacter(holder)
						and not holder:FindFirstChildOfClass("Humanoid")
						and not IsGrabbable(holder)
					if isModelPlace then
						-- daftarkan model-nya sekali saja (cek pertama part dari model)
						if holder.PrimaryPart == o or holder:FindFirstChildOfClass("BasePart") == o then
							table.insert(ScanCache.Places, holder)
						end
					elseif o:IsA("MeshPart") or (o.Anchored and o.Size.Magnitude > 4) then
						table.insert(ScanCache.Places, o)
					end
				end
			elseif not o:IsA("BasePart") then
				-- Tool / Model / Folder seperti sebelumnya
				if not Services.Players:GetPlayerFromCharacter(o) then
					if IsGrabbable(o) then
						table.insert(ScanCache.Items, o)
					elseif IsPlaceCandidate(o) then
						table.insert(ScanCache.Places, o)
					end
				end
			end
		end

		-- [REVISI] ANTI-LAG: yield tiap 400 objek ATAU tiap 8ms (bukan tiap beberapa sumber)
		processed = processed + 1
		if processed % 400 == 0 or (os.clock() - t0) > 0.008 then
			task.wait()
			t0 = os.clock()
		end
	end
end

-- scan bertahap: proses workspace per-children utama, tiap chunk task.wait()
-- [REVISI] scan penuh SEKALI saja, lalu incremental via DescendantAdded
-- ANTI-LAG (A): throttle — tolak StartScan baru kalau scan terakhir < 5 detik lalu (kecuali manual paksa).
function Teleport.StartScan(force)
	if ScanCache.Scanning then return end
	if not force and ScanCache._lastScanAt and (os.clock() - ScanCache._lastScanAt) < 5 then return end
	ScanCache.Scanning = true
	ScanCache._lastScanAt = os.clock()
	task.spawn(function()
		-- putus koneksi incremental lama bila ada (hindari duplikat event)
		pcall(function()
			if ScanCache._addConn then ScanCache._addConn:Disconnect() ScanCache._addConn = nil end
		end)
		-- scan penuh SEKALI saja
		ScanCache.Items = {}
		ScanCache.Places = {}
		ScanCache.Ready = false

		-- ANTI-LAG (A): scan folder item yang dikenal DULU (SixMarket/dll) supaya daftar cepat terisi;
		-- folder raksasa diproses belakangan, tetap per sumber + task.wait() tiap sumber.
		local sources = {}
		local deferred = {}
		for _, o in ipairs(Services.WS:GetChildren()) do
			local nm = string.lower(o.Name or "")
			local isMarket = false
			for _, kw in ipairs(Config.Keywords.Area.Market) do
				if nm:find(kw, 1, true) then isMarket = true break end
			end
			if isMarket then table.insert(sources, 1, o)
			else table.insert(deferred, o) end
		end
		for _, o in ipairs(deferred) do table.insert(sources, o) end
		ScanCache.Total = #sources
		ScanCache.Progress = 0

		for i, src in ipairs(sources) do
			if not ScanCache.Scanning then break end
			-- [REVISI] skip objek besar/tak berguna — Terrain bisa ratusan ribu chunk
			if not SCAN_SKIP[src.Name] and not src:IsA("Terrain") and not src:IsA("Camera") then
				Util.Safe(ScanChunk, src:GetDescendants())
			end
			ScanCache.Progress = i
			if UI.ScanLbl then
				UI.ScanLbl.Text = string.format("SCAN: %d/%d", i, ScanCache.Total)
			end
			task.wait() -- yield setiap sumber
		end

		ScanCache.Ready = true
		Teleport.UpdateLabelsFromCache()
		Teleport.RefreshItem()
		Teleport.RefreshPlaceList()
		if UI.ScanLbl then
			UI.ScanLbl.Text = string.format("SCAN: OK (%d item / %d place)", #ScanCache.Items, #ScanCache.Places)
		end

		-- [REVISI] tidak ada full-rescan berkala.
		-- Update incremental via DescendantAdded (murah: hanya 1 objek per event)
		ScanCache._addConn = Services.WS.DescendantAdded:Connect(function(o)
			if not ScanCache.Scanning then return end
			local owner = Services.Players:GetPlayerFromCharacter(o.Parent)
			if owner then return end
			if o:IsA("Tool") and o:FindFirstChild("Handle") then
				table.insert(ScanCache.Items, o)
			elseif o:IsA("BasePart") and (o:FindFirstChildOfClass("ProximityPrompt") or o:FindFirstChildOfClass("ClickDetector")) then
				table.insert(ScanCache.Items, o)
			elseif IsGrabbable(o) then
				table.insert(ScanCache.Items, o)
			end
			-- hapus instance mati dari cache secara lazy saat dibaca (sudah ditangani filter o.Parent)
		end)
		-- [REVISI] tandai boot selesai — RefreshItem baru boleh auto-bootstrap setelah ini
		ScanCache._bootDone = true
	end)
end

function Teleport.StopScan()
	ScanCache.Scanning = false
	pcall(function()
		if ScanCache._addConn then ScanCache._addConn:Disconnect() ScanCache._addConn = nil end
	end)
end

-- [REVISI] rescan penuh manual (bertahap, tidak lag) — untuk place/item yang hilang
-- ANTI-LAG (C): tombol manual selalu paksa (force=true), auto-bootstrap tetap kena throttle 5 detik.
function Teleport.FullRescan()
	Teleport.StopScan()
	Notify("YOURSCRIPT", "Rescan dimulai...", Config.Theme.Accent)
	task.wait(0.1)
	Teleport.StartScan(true)
end

-- label ITEM & PLACE dibaca dari cache — instan
function Teleport.UpdateLabelsFromCache()
	local r = Util.Root()
	if not r then return end

	-- ITEM label
	if UI.ItemLbl then
		UI.ItemLbl.Text = State.ItemName and ("ITEM: " .. State.ItemName) or "ITEM: (none)"
	end
	-- [BARU] AutoFarmItem harus sinkron dengan pilihan < > juga
	if State.ItemName then State.AutoFarmItem = State.ItemName end

	-- PLACE label: tampilkan place terpilih (+ jarak instance terdekatnya)
	if UI.PlaceLbl then
		if State.PlaceName then
			-- cari jarak instance terdekat dari nama place terpilih
			local near = math.huge
			if r then
				for _, o in ipairs(ScanCache.Places) do
					if o.Parent and o.Name == State.PlaceName then
						local part = GetPartOf(o)
						if part then
							local d = (part.Position - r.Position).Magnitude
							if d < near then near = d end
						end
					end
				end
			end
			UI.PlaceLbl.Text = near < math.huge
				and string.format("PLACE: %s (%.0fm)", State.PlaceName, near)
				or ("PLACE: " .. State.PlaceName)
		else
			UI.PlaceLbl.Text = "PLACE: (none)"
		end
	end
end

-- [REVISI] refresh item = hanya baca cache (instan, tanpa GetDescendants)
function Teleport.RefreshItem(silent)
	-- bootstrap scan hanya jika panel sudah lama hidup (bukan saat init)
	if not ScanCache.Scanning and ScanCache._bootDone then
		Teleport.StartScan()
	end
	-- ANTI-LAG: pakai set hash, bukan table.find O(n^2)
	local names, seen = {}, {}
	for _, o in ipairs(ScanCache.Items) do
		if o.Parent then
			local nm = o.Name
			if nm and not seen[nm] then
				seen[nm] = true
				table.insert(names, nm)
			end
		end
	end
	table.sort(names)
	State.ItemList = names
	if not State.ItemName or not seen[State.ItemName] then
		State.ItemName = names[1]
	end
	Teleport.UpdateLabelsFromCache()
	if not ScanCache.Ready and not silent then
		Notify("YOURSCRIPT", "Scan berjalan... data parsial", Config.Theme.Orange)
	end
end

function Teleport.PrevItem()
	local list = State.ItemList or {}
	if #list == 0 then
		Notify("YOURSCRIPT", "Daftar kosong — tekan REFRESH ITEM dulu", Config.Theme.Orange)
		return
	end
	local i = table.find(list, State.ItemName) or 1
	i = i - 1; if i < 1 then i = #list end
	State.ItemName = list[i]
	Teleport.UpdateLabelsFromCache()
end

function Teleport.NextItem()
	local list = State.ItemList or {}
	if #list == 0 then
		Notify("YOURSCRIPT", "Daftar kosong — tekan REFRESH ITEM dulu", Config.Theme.Orange)
		return
	end
	local i = table.find(list, State.ItemName) or 0
	i = i + 1; if i > #list then i = 1 end
	State.ItemName = list[i]
	Teleport.UpdateLabelsFromCache()
end

-- [REVISI] TP ke instance TERDEKAT dari nama item (baca cache, tanpa scan)
function Teleport.TPToItem()
	local r = Util.Root()
	if not r then return end
	if not State.ItemName then
		Notify("YOURSCRIPT", "Daftar kosong — tekan REFRESH ITEM dulu", Config.Theme.Orange)
		return
	end
	local best, bestDist = nil, math.huge
	for _, o in ipairs(ScanCache.Items) do
		if o.Parent and o.Name == State.ItemName then
			local part = GetPartOf(o)
			if part then
				local d = (part.Position - r.Position).Magnitude
				if d < bestDist then best, bestDist = part, d end
			end
		end
	end
	if best then
		Teleport.ToPart(best)
		Notify("YOURSCRIPT", string.format("TP %s (%.0fm)", State.ItemName, bestDist), Config.Theme.Accent)
	else
		Notify("YOURSCRIPT", "Item Tidak Ada di Workspace — coba Refresh", Config.Theme.Orange)
	end
end

-- [REVISI] Refresh Place = baca cache + update label, instan
function Teleport.RefreshPlace()
	Teleport.UpdateLabelsFromCache()
	if not ScanCache.Ready then
		Notify("YOURSCRIPT", "Scan berjalan... data parsial", Config.Theme.Orange)
	end
	-- sekalian bangun daftar place agar </> & TP PLACE siap
	Teleport.RefreshPlaceList()
end

function Teleport.RefreshPlaceList()
	local names = {}
	for _, o in ipairs(ScanCache.Places) do
		if o.Parent and not table.find(names, o.Name) then
			table.insert(names, o.Name)
		end
	end
	table.sort(names)
	State.PlaceList = names
	if not State.PlaceName or not table.find(names, State.PlaceName) then
		State.PlaceName = names[1]
	end
	Teleport.UpdateLabelsFromCache()
end

function Teleport.PrevPlace()
	local list = State.PlaceList or {}
	if #list == 0 then
		Notify("YOURSCRIPT", "Daftar kosong — tunggu scan selesai", Config.Theme.Orange)
		return
	end
	local i = table.find(list, State.PlaceName) or 1
	i = i - 1; if i < 1 then i = #list end
	State.PlaceName = list[i]
	Teleport.UpdateLabelsFromCache()
end

function Teleport.NextPlace()
	local list = State.PlaceList or {}
	if #list == 0 then
		Notify("YOURSCRIPT", "Daftar kosong — tunggu scan selesai", Config.Theme.Orange)
		return
	end
	local i = table.find(list, State.PlaceName) or 0
	i = i + 1; if i > #list then i = 1 end
	State.PlaceName = list[i]
	Teleport.UpdateLabelsFromCache()
end

-- [BARU] TP ke instance Place TERDEKAT sesuai pilihan
function Teleport.TPToPlace()
	local r = Util.Root()
	if not r then return end
	if not State.PlaceName then
		Notify("YOURSCRIPT", "Pilih Place Dulu", Config.Theme.Orange)
		return
	end
	local best, bestDist = nil, math.huge
	for _, o in ipairs(ScanCache.Places) do
		if o.Parent and o.Name == State.PlaceName then
			local part = GetPartOf(o)
			if part then
				local d = (part.Position - r.Position).Magnitude
				if d < bestDist then best, bestDist = part, d end
			end
		end
	end
	if best then
		Teleport.ToPart(best)
		Notify("YOURSCRIPT", string.format("TP %s (%.0fm)", State.PlaceName, bestDist), Config.Theme.Accent)
	else
		Notify("YOURSCRIPT", "Place Tidak Ada — coba Refresh Place", Config.Theme.Orange)
	end
end

-- [REVISI] TP by name dari CACHE — instan, tanpa GetDescendants()
function Teleport.TPByName(name, usePlaces)
	name = tostring(name or ""):lower()
	if name == "" then
		Notify("YOURSCRIPT", "Ketik Nama Dulu", Config.Theme.Orange)
		return
	end
	local r = Util.Root()
	local best, bestDist = nil, math.huge
	local cache = usePlaces and ScanCache.Places or ScanCache.Items
	for _, o in ipairs(cache) do
		if o.Parent and string.find(o.Name:lower(), name, 1, true) then
			local part = GetPartOf(o)
			if part and r then
				local d = (part.Position - r.Position).Magnitude
				if d < bestDist then best, bestDist = part, d end
			end
		end
	end
	if best then
		Teleport.ToPart(best)
		Notify("YOURSCRIPT", string.format("TP: %s (%.0fm)", best.Parent.Name, bestDist), Config.Theme.Accent)
	else
		Notify("YOURSCRIPT", "Tidak Ditemukan: " .. name, Config.Theme.Orange)
	end
end

-- backward compatible
function Teleport.TPToItemByName(name) Teleport.TPByName(name, false) end
function Teleport.TPToPlaceByName(name) Teleport.TPByName(name, true) end

-- [BARU] TP by name + full-scan fallback (untuk place yang belum masuk cache)
function Teleport.TPByNameGlobal(name, usePlaces)
	name = tostring(name or ""):lower()
	if name == "" then
		Notify("YOURSCRIPT", "Ketik Nama Dulu", Config.Theme.Orange)
		return
	end
	local r = Util.Root()
	local best, bestDist = nil, math.huge
	for _, o in ipairs(Services.WS:GetDescendants()) do
		if (o:IsA("BasePart") or o:IsA("Model")) and not Services.Players:GetPlayerFromCharacter(o) then
			local holder = o:IsA("BasePart") and o.Parent or o
			if holder and string.find(holder.Name:lower(), name, 1, true) then
				local part = GetPartOf(holder)
				if part and r then
					local d = (part.Position - r.Position).Magnitude
					if d < bestDist then best, bestDist = part, d end
				end
			end
		end
	end
	if best then
		Teleport.ToPart(best)
		Notify("YOURSCRIPT", string.format("TP Global: %s (%.0fm)", best.Name, bestDist), Config.Theme.Accent)
	else
		Notify("YOURSCRIPT", "Tidak Ditemukan: " .. name, Config.Theme.Orange)
	end
end

----------------------------------------------------------------
-- FARMING MODULE (FINAL)
----------------------------------------------------------------
local Farming = {}

-- [REVISI] target ambil dari cache (hanya yang parent-nya masih ada)
-- + Tool di Workspace root (baru dropped, belum ke-cache)
local function GrabTargets()
	local out = {}
	for _, o in ipairs(ScanCache.Items) do
		if o.Parent then table.insert(out, o) end
	end
	-- Tool yang baru dropped sering muncul langsung di Workspace — pastikan tercakup
	for _, o in ipairs(Services.WS:GetChildren()) do
		if o:IsA("Tool") and o:FindFirstChild("Handle") and not table.find(out, o) then
			table.insert(out, o)
		end
	end
	return out
end

function Farming.GrabRemoteOne()
	if not State.ItemName then
		Notify("YOURSCRIPT", "Pilih Item Dulu (Refresh Item dulu)", Config.Theme.Orange)
		return
	end
	local ev = Services.Rep:FindFirstChild("PickupItemEvent")
	if not ev then
		Notify("YOURSCRIPT", "Remote PickupItemEvent tidak ada", Config.Theme.Orange)
		return
	end
	local found = false
	for _, o in ipairs(GrabTargets()) do
		if o.Name == State.ItemName then
			pcall(function() ev:FireServer(o) end)
			found = true
		end
	end
	if found then
		Notify("YOURSCRIPT", "Ambil: " .. State.ItemName, Config.Theme.Green)
	else
		Notify("YOURSCRIPT", "Item Tidak Ditemukan — coba Refresh Item", Config.Theme.Orange)
	end
end

-- AMBIL TERDEKAT (v2 — TP -> prompt -> balik)
-- Pakai cache ScanCache.Items (hasil Teleport.RefreshItem/StartScan), TANPA scan workspace saat klik.
-- Alasan: FireServer dari jarak jauh ditolak server; TP dulu ke item lalu fire prompt paling reliabel.
local function GetPromptFromGrab(model)
	if not model then return nil end
	local ok, p = pcall(function() return model:FindFirstChildOfClass("ProximityPrompt") end)
	if ok and p then return p end
	-- scan descendants (FindFirstChildOfClass recursive tidak selalu ada di semua executor)
	local ok2, res = pcall(function()
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ProximityPrompt") then return d end
		end
		return nil
	end)
	if ok2 and res then return res end
	return nil
end

local function GetGrabPart(o)
	if not o then return nil end
	if o:IsA("BasePart") then return o end
	if o:IsA("Model") or o:IsA("Tool") then
		if o:IsA("Model") and o.PrimaryPart then return o.PrimaryPart end
		local h = o:FindFirstChild("Handle")
		if h and h:IsA("BasePart") then return h end
		local b = o:FindFirstChildWhichIsA("BasePart", true)
		if b then return b end
	end
	return GetPartOf(o)
end

local _GrabBusy = false
function Farming.GrabNearest()
	--[[
		Ambil item yang masuk akal di depan Ava.
		- Abaikan item di bawah kaki (diinjak)
		- Prioritas item di depan arah hadap
		- Baru pilih jarak terkecil di antara yang lolos
		PC & mobile: logika sama.
		[FIX] debounce anti-lag/macet di desktop
	]]
	if _GrabBusy then return end
	_GrabBusy = true
	local function releaseBusy()
		task.delay(0.28, function() _GrabBusy = false end) -- ANTI-LAG: debounce ringkas (scan sudah ringan)
	end

	local r = Util.Root()
	if not r then
		Notify("Ambil Terdekat", "Character Not Ready", Config.Theme.Orange)
		releaseBusy()
		return
	end

	local myPos = r.Position
	local look = r.CFrame.LookVector
	local lookFlat = Vector3.new(look.X, 0, look.Z)
	if lookFlat.Magnitude > 0.05 then lookFlat = lookFlat.Unit else lookFlat = Vector3.new(0, 0, -1) end
	local RADIUS = 30

	local BODY_PARTS = {
		UpperTorso = true, LowerTorso = true, HumanoidRootPart = true,
		Head = true, Torso = true,
		LeftArm = true, RightArm = true, LeftLeg = true, RightLeg = true,
		LeftHand = true, RightHand = true, LeftFoot = true, RightFoot = true,
		LeftUpperArm = true, LeftLowerArm = true, RightUpperArm = true, RightLowerArm = true,
		LeftUpperLeg = true, LeftLowerLeg = true, RightUpperLeg = true, RightLowerLeg = true,
	}

	local candidates = {}
	local seen = {}

	local function isCharacterStuff(o)
		if not o then return true end
		local a = o
		while a and a ~= Services.WS do
			if a:IsA("Model") then
				if Services.Players:GetPlayerFromCharacter(a) then return true end
				if a:FindFirstChildOfClass("Humanoid") then return true end
			end
			if a:IsA("Accessory") or a:IsA("Accoutrement") or a:IsA("Clothing") then return true end
			a = a.Parent
		end
		return false
	end

	local function getPart(o)
		if not o then return nil end
		if o:IsA("BasePart") then return o end
		if o:IsA("Tool") then
			return o:FindFirstChild("Handle") or o:FindFirstChildOfClass("BasePart")
		end
		if o:IsA("Model") then
			return o.PrimaryPart or o:FindFirstChild("Handle") or o:FindFirstChildOfClass("BasePart")
		end
		return nil
	end

	-- item yang sedang diinjak (dekat horizontal + di kaki)
	local function isUnderfoot(pos)
		local flat = Vector3.new(pos.X - myPos.X, 0, pos.Z - myPos.Z).Magnitude
		local dy = pos.Y - myPos.Y
		return flat < 2.0 and dy > -4 and dy < 1.2
	end

	local function consider(o)
		if not o or seen[o] or not o.Parent then return end
		if isCharacterStuff(o) then return end
		if o:IsA("BasePart") then
			local par = o.Parent
			if not par or par == Services.WS then return end
			if isCharacterStuff(par) then return end
			if par:IsA("Model") or par:IsA("Tool") then
				o = par
				if seen[o] or isCharacterStuff(o) then return end
			else
				return
			end
		end
		seen[o] = true
		local p2 = getPart(o)
		if not p2 then return end
		local pos = p2.Position
		local d = (pos - myPos).Magnitude
		if d > RADIUS then return end
		local flat = Vector3.new(pos.X - myPos.X, 0, pos.Z - myPos.Z)
		local front = 0
		if flat.Magnitude > 0.05 then
			front = lookFlat:Dot(flat.Unit)
		end
		table.insert(candidates, {
			o = o, dist = d, part = p2, pos = pos,
			under = isUnderfoot(pos), front = front,
		})
	end

	-- ANTI-LAG: prioritas spatial query dulu (ringan), cache hanya sebagai fallback
	do
		local parts = nil
		pcall(function()
			local op = OverlapParams.new()
			op.FilterType = Enum.RaycastFilterType.Exclude
			if LP.Character then op.FilterDescendantsInstances = { LP.Character } end
			parts = Services.WS:GetPartBoundsInRadius(myPos, math.min(RADIUS, 16), op)
		end)
		if parts then
			local n = 0
			for _, part in ipairs(parts) do
				n = n + 1
				if n > 30 then break end
				if not BODY_PARTS[part.Name] and not isCharacterStuff(part) then
					local par = part.Parent
					if par and (par:IsA("Model") or par:IsA("Tool")) then
						consider(par)
					elseif part:IsA("BasePart") and (part:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ClickDetector")) then
						consider(part)
					end
				end
			end
		end
	end
	-- Tools di root Workspace (sering dropped)
	for _, o in ipairs(Services.WS:GetChildren()) do
		if o:IsA("Tool") and o:FindFirstChild("Handle") then consider(o) end
	end
	-- Fallback cache hanya jika masih kosong (jangan iterate ratusan item tiap klik)
	if #candidates < 2 then
		local checked = 0
		for _, o in ipairs(ScanCache and ScanCache.Items or {}) do
			checked = checked + 1
			if checked > 80 then break end
			consider(o)
		end
		local wy = Services.WS:FindFirstChild("Wyposazenie")
		if wy then
			for _, c in ipairs(wy:GetChildren()) do
				local n = tostring(c.Name)
				if not n:match("^%d+_Wyposazenie$") and (c:IsA("Model") or c:IsA("Tool")) then
					consider(c)
				end
			end
		end
	end

	if #candidates == 0 then
		Notify("Ambil Terdekat", "Tidak ada item dekat (max " .. RADIUS .. "m)", Config.Theme.Orange)
		releaseBusy()
		return
	end

	-- 1) bukan underfoot + di depan (dot > 0.15)
	-- 2) bukan underfoot (jarak terdekat)
	-- 3) fallback semua (jarak terdekat)
	local function pick(list)
		local b = nil
		for _, c in ipairs(list) do
			if not b or c.dist < b.dist then b = c end
		end
		return b
	end

	local frontList, safeList = {}, {}
	for _, c in ipairs(candidates) do
		if not c.under then
			table.insert(safeList, c)
			if c.front > 0.15 then table.insert(frontList, c) end
		end
	end

	local bestEntry = pick(frontList) or pick(safeList) or pick(candidates)
	if not bestEntry then
		Notify("Ambil Terdekat", "Tidak ada item dekat (max " .. RADIUS .. "m)", Config.Theme.Orange)
		releaseBusy()
		return
	end
	local best, bestDist, bestPart = bestEntry.o, bestEntry.dist, bestEntry.part

	local function findPrompt(o)
		local p = o:FindFirstChildOfClass("ProximityPrompt")
		if p then return p end
		local ok, deep = pcall(function() return o:FindFirstChildOfClass("ProximityPrompt", true) end)
		if ok and deep then return deep end
		return nil
	end
	local function findClick(o)
		local p = o:FindFirstChildOfClass("ClickDetector")
		if p then return p end
		local ok, deep = pcall(function() return o:FindFirstChildOfClass("ClickDetector", true) end)
		if ok and deep then return deep end
		return nil
	end

	local prompt = findPrompt(best)
	local clickDet = findClick(best)

	pcall(function()
		local ev = Services.Rep:FindFirstChild("PickupItemEvent")
			or Services.Rep:FindFirstChild("PickupItemEvent", true)
		if ev then
			ev:FireServer(best)
			if bestPart and bestPart ~= best then
				pcall(function() ev:FireServer(bestPart) end)
			end
		end
	end)
	if prompt then
		if fireproximityprompt then
			pcall(function() fireproximityprompt(prompt, prompt.MaxActivationDistance or 12) end)
		else
			task.spawn(function()
				pcall(function()
					prompt:InputHoldBegin()
					task.wait(math.min((prompt.HoldDuration or 0.3), 0.4))
					prompt:InputHoldEnd()
				end)
			end)
		end
	end
	if clickDet and fireclickdetector then
		pcall(function() fireclickdetector(clickDet, 0) end)
	end

	Notify("Ambil Terdekat", string.format("%s (%.2fm)", tostring(best.Name), bestDist), Config.Theme.Green)
	releaseBusy()
end

function Farming.RaidMarketReturn()
	if not State.SavedPos then Teleport.SavePos() end
	local r = Util.Root()
	if not r then return end
	local ev = Services.Rep:FindFirstChild("PickupItemEvent")
	local n = 0
	for _, o in ipairs(Services.WS:GetDescendants()) do
		local holder = o:IsA("BasePart") and o.Parent or o
		if holder and not Services.Players:GetPlayerFromCharacter(holder)
			and Util.InArea(holder, Config.Keywords.Area.Market)
			and not Util.InArea(holder, Config.Keywords.Area.Bunker) then
			local part = o:IsA("BasePart") and o
				or (holder.PrimaryPart or holder:FindFirstChildOfClass("BasePart"))
			if part then
				r.CFrame = part.CFrame * CFrame.new(0, 3, 0)
				task.wait(0.15)
				local pp = o:IsA("BasePart") and o:FindFirstChildOfClass("ProximityPrompt")
					or holder:FindFirstChildOfClass("ProximityPrompt", true)
				if pp and fireproximityprompt then pcall(fireproximityprompt, pp, pp.MaxActivationDistance) end
				if ev then pcall(function() ev:FireServer(holder) end) end
				n = n + 1
			end
		end
	end
	task.wait(0.3)
	r.CFrame = State.SavedPos
	Notify("YOURSCRIPT", "Market Raid: " .. n .. " item, kembali ke posisi", Config.Theme.Accent)
end

-- [BARU] state Auto Farm
State.AutoFarmOn     = false
State.AutoFarmItem   = ""     -- diisi lewat textbox
State.AutoFarmPlace  = ""     -- diisi lewat textbox
State.AutoFarmExcludeBunker = true

function Farming.SetAutoFarmItem(v)  State.AutoFarmItem  = tostring(v or "") end
function Farming.SetAutoFarmPlace(v) State.AutoFarmPlace = tostring(v or "") end
function Farming.GetAutoFarmItem()  return State.AutoFarmItem end

function Farming.EnableAutoFarm()
	State.AutoFarmOn = true
	task.spawn(function()
		while State.AutoFarmOn do
			-- pakai GrabAllMarket (baca ScanCache, 1x pass, tanpa GetDescendants)
			Farming.GrabAllMarket()
			-- optional: TP ke place yang diketik (jalan sekali per siklus)
			if State.AutoFarmPlace ~= "" then
				Teleport.TPByName(State.AutoFarmPlace, true)
			end
			task.wait(2.5)
		end
	end)
	Notify("YOURSCRIPT", "Auto Farm Enabled", Config.Theme.Green)
end

function Farming.DisableAutoFarm()
	State.AutoFarmOn = false
	Notify("YOURSCRIPT", "Auto Farm Disabled", Config.Theme.Sub)
end

function Farming.ToggleAutoFarm()
	if State.AutoFarmOn then Farming.DisableAutoFarm() else Farming.EnableAutoFarm() end
end

-- [BARU] ambil semua item di market, KECUALI yang di bunker (1x jalan)
function Farming.GrabAllMarket()
	local ev = Services.Rep:FindFirstChild("PickupItemEvent")
	if not ev then Notify("YOURSCRIPT", "Remote tidak ada", Config.Theme.Orange); return end
	local n = 0
	for _, o in ipairs(ScanCache.Items) do
		if o.Parent
			and Util.InArea(o, Config.Keywords.Area.Market)
			and not Util.InArea(o, Config.Keywords.Area.Bunker) then
			pcall(function() ev:FireServer(o) end)
			n = n + 1
		end
	end
	Notify("YOURSCRIPT", "Market Raid: " .. n .. " item", Config.Theme.Accent)
end

----------------------------------------------------------------
-- MONSTER MODULE
----------------------------------------------------------------
local Monster = {}

local function GetPlank()
	if #PlankPool > 0 then return table.remove(PlankPool) end
	local p = Instance.new("Part")
	p.Name = "YOURSCRIPT_Cage"
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 50, 50)
	p.Transparency = 0.35
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

function Monster.GetAll()
	local out = {}
	for _, o in ipairs(Util.GetWS()) do
		if Util.IsMonster(o) then table.insert(out, o) end
	end
	return out
end

function Monster.CageOne(model)
	if CageData[model] then return end
	local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model.PrimaryPart
	if not root then return end
	local data = { planks = {} }
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		data.hum, data.ws, data.jp = hum, hum.WalkSpeed, hum.JumpPower
		pcall(function()
			hum.WalkSpeed = 0
			hum.JumpPower = 0
			hum.AutoRotate = false
		end)
	end
	data.root = root
	data.anchored = root.Anchored
	pcall(function() root.Anchored = true end)
	local cf = root.CFrame
	data.center = cf
	local walls = {
		cf * CFrame.new(0, 3.2, 5.2),
		cf * CFrame.new(0, 3.2, -5.2),
		cf * CFrame.new(5.2, 3.2, 0) * CFrame.Angles(0, math.rad(90), 0),
		cf * CFrame.new(-5.2, 3.2, 0) * CFrame.Angles(0, math.rad(90), 0),
	}
	for _, wcf in ipairs(walls) do
		local p = GetPlank()
		p.Size = Vector3.new(10, 6.4, 1)
		p.CFrame = wcf
		p.Parent = Services.WS
		table.insert(data.planks, p)
	end
	for _, y in ipairs({6.6, -0.4}) do
		local p = GetPlank()
		p.Size = Vector3.new(10.4, 1, 10.4)
		p.CFrame = cf * CFrame.new(0, y, 0)
		p.Parent = Services.WS
		table.insert(data.planks, p)
	end
	CageData[model] = data
	Monster.EnsureCageDrag()
end

function Monster.EnsureCageDrag()
	if State._cageDragOn then return end
	State._cageDragOn = true
	task.spawn(function()
		while State._cageDragOn do
			local any = false
			for model, data in pairs(CageData) do
				any = true
				local root = data.root
				if not model.Parent or not root or not root.Parent then
					CageData[model] = nil
					if data.planks then
						for _, p in ipairs(data.planks) do table.insert(PlankPool, p); p.Parent = nil end
					end
				else
					pcall(function()
						root.CFrame = data.center
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						if data.hum then data.hum.WalkSpeed = 0; data.hum.JumpPower = 0 end
					end)
				end
			end
			if not any then break end
			task.wait(0.15)
		end
		State._cageDragOn = false
	end)
end

function Monster.ClearCages()
	State._cageDragOn = false
	for model, data in pairs(CageData) do
		CageData[model] = nil
		if data.planks then
			for _, p in ipairs(data.planks) do
				table.insert(PlankPool, p)
				p.Parent = nil
			end
		end
		if data.hum then
			pcall(function()
				data.hum.WalkSpeed = data.ws or 16
				data.hum.JumpPower = data.jp or 50
				data.hum.AutoRotate = true
			end)
		end
		if data.root then pcall(function() data.root.Anchored = data.anchored end) end
	end
	CageData = {}
end

function Monster.CageAll()
	local n = 0
	for _, m in ipairs(Monster.GetAll()) do
		Monster.CageOne(m)
		n = n + 1
	end
	return n
end

function Monster.EnableCage()
	State.CageOn = true
	local n = Monster.CageAll()
	Notify("YOURSCRIPT", "Caged " .. n .. " Monster(s)", Config.Theme.Green)
end

function Monster.DisableCage()
	State.CageOn = false
	Monster.ClearCages()
	Notify("YOURSCRIPT", "Cages Opened", Config.Theme.Sub)
end

function Monster.ToggleCage()
	if State.CageOn then Monster.DisableCage() else Monster.EnableCage() end
end

function Monster.EnableAutoCage()
	State.AutoCage = true
	task.spawn(function()
		while State.AutoCage do
			for _, m in ipairs(Monster.GetAll()) do
				if not CageData[m] then Monster.CageOne(m) end
			end
			for m, data in pairs(CageData) do
				if not m.Parent then
					CageData[m] = nil
					if data.planks then
						for _, p in ipairs(data.planks) do table.insert(PlankPool, p); p.Parent = nil end
					end
				end
			end
			task.wait(1.2)
		end
	end)
	Notify("YOURSCRIPT", "Auto Cage Enabled", Config.Theme.Green)
end

function Monster.DisableAutoCage()
	State.AutoCage = false
	Notify("YOURSCRIPT", "Auto Cage Disabled", Config.Theme.Sub)
end

function Monster.ToggleAutoCage()
	if State.AutoCage then Monster.DisableAutoCage() else Monster.EnableAutoCage() end
end

function Monster.EnableFreeze()
	State.FreezeOn = true
	Util.Disconnect("Freeze")
	task.spawn(function()
		while State.FreezeOn do
			for _, m in ipairs(Monster.GetAll()) do
				local hum = m:FindFirstChildOfClass("Humanoid")
				local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
				if hum then pcall(function() hum.WalkSpeed = 0; hum.JumpPower = 0 end) end
				if root then
					pcall(function()
						root.AssemblyLinearVelocity = Vector3.zero
						root.Anchored = true
					end)
				end
			end
			task.wait(0.35)
		end
	end)
	Notify("YOURSCRIPT", "Freeze Monster Enabled", Config.Theme.Green)
end

function Monster.DisableFreeze()
	State.FreezeOn = false
	for _, m in ipairs(Monster.GetAll()) do
		local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
		if root then pcall(function() root.Anchored = false end) end
	end
	Notify("YOURSCRIPT", "Freeze Monster Disabled", Config.Theme.Sub)
end

function Monster.ToggleFreeze()
	if State.FreezeOn then Monster.DisableFreeze() else Monster.EnableFreeze() end
end

function Monster.EnableAlert()
	State.MonsterAlert = true
	ESP.StartLoop()
	Notify("YOURSCRIPT", "Monster Alert Enabled", Config.Theme.Green)
end

function Monster.DisableAlert()
	State.MonsterAlert = false
	Notify("YOURSCRIPT", "Monster Alert Disabled", Config.Theme.Sub)
end

function Monster.ToggleAlert()
	if State.MonsterAlert then Monster.DisableAlert() else Monster.EnableAlert() end
end

function Monster.EnableTracker()
	State.MonsterTracker = true
	ESP.StartLoop()
	Notify("YOURSCRIPT", "Monster Tracker Enabled", Config.Theme.Green)
end

function Monster.DisableTracker()
	State.MonsterTracker = false
	if UI.TrackerLbl then UI.TrackerLbl.Text = "MONSTER: -" end
	if not State.ItemESP and not State.MonsterESP and not State.PlayerESP
		and not State.MonsterTracker and not State.PlayerTracker then
		Util.Disconnect("ESPLoop")
	end
	Notify("YOURSCRIPT", "Monster Tracker Disabled", Config.Theme.Sub)
end

function Monster.ToggleTracker()
	if State.MonsterTracker then Monster.DisableTracker() else Monster.EnableTracker() end
end

----------------------------------------------------------------
-- VISUAL MODULE
----------------------------------------------------------------
local Visual = {}

function Visual.EnableFullbright()
	if State.FullbrightOn then return end
	State.FullbrightOn = true

	-- simpan nilai lighting asli untuk restore saat disable
	State._fbBackup = {
		Brightness       = Services.Lighting.Brightness,
		ClockTime        = Services.Lighting.ClockTime,
		FogEnd           = Services.Lighting.FogEnd,
		FogStart         = Services.Lighting.FogStart,
		GlobalShadows    = Services.Lighting.GlobalShadows,
		OutdoorAmbient   = Services.Lighting.OutdoorAmbient,
		Ambient          = Services.Lighting.Ambient,
		ExposureCompensation = Services.Lighting.ExposureCompensation,
	}
	Util.Connect("FB", Services.RS.Heartbeat, function()
		if not State.FullbrightOn then return end
		local L = Services.Lighting
		-- dipaksa SETIAP FRAME agar game tidak bisa menimpa kembali
		L.Brightness = 2
		L.ClockTime = 14
		L.FogEnd = 1e6
		L.FogStart = 0
		L.GlobalShadows = false
		L.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
		L.Ambient = Color3.fromRGB(140, 140, 140)
		L.ExposureCompensation = 0.4
	end)
	Notify("YOURSCRIPT", "Fullbright Enabled", Config.Theme.Green)
end

function Visual.DisableFullbright()
	if not State.FullbrightOn then return end
	State.FullbrightOn = false
	Util.Disconnect("FB")
	local b = State._fbBackup
	if b then
		local L = Services.Lighting
		pcall(function()
			L.Brightness       = b.Brightness
			L.ClockTime        = b.ClockTime
			L.FogEnd           = b.FogEnd
			L.FogStart         = b.FogStart
			L.GlobalShadows    = b.GlobalShadows
			L.OutdoorAmbient   = b.OutdoorAmbient
			L.Ambient          = b.Ambient
			L.ExposureCompensation = b.ExposureCompensation
		end)
		State._fbBackup = nil
	elseif not State.NoShadow then
		Services.Lighting.GlobalShadows = true
	end
	Notify("YOURSCRIPT", "Fullbright Disabled", Config.Theme.Sub)
end

function Visual.ToggleFullbright()
	if State.FullbrightOn then Visual.DisableFullbright() else Visual.EnableFullbright() end
end

function Visual.EnableNoFog()
	State.NoFogOn = true
	Util.Connect("NoFog", Services.RS.Heartbeat, function(dt)
		if not State.NoFogOn then return end
		NFAcc = (NFAcc or 0) + dt
		if NFAcc < 0.5 then return end
		NFAcc = 0
		Services.Lighting.FogEnd = 1e6
		Services.Lighting.FogStart = 0
	end)
	Notify("YOURSCRIPT", "No Fog Enabled", Config.Theme.Green)
end

function Visual.DisableNoFog()
	State.NoFogOn = false
	Util.Disconnect("NoFog")
	Notify("YOURSCRIPT", "No Fog Disabled", Config.Theme.Sub)
end

function Visual.ToggleNoFog()
	if State.NoFogOn then Visual.DisableNoFog() else Visual.EnableNoFog() end
end

function Visual.EnableNoGrass()
	State.NoGrass = true
	for _, o in ipairs(Services.WS:GetDescendants()) do
		if o:IsA("Terrain") then
			pcall(function() o.Decoration = false end)
		end
		local n = string.lower(o.Name)
		if n:find("grass") or n:find("leaf") or n:find("bush") then
			if o:IsA("BasePart") or o:IsA("MeshPart") then
				o.LocalTransparencyModifier = 1
			elseif o:IsA("Model") then
				for _, p in ipairs(o:GetDescendants()) do
					if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
				end
			end
		end
	end
	Notify("YOURSCRIPT", "Remove Grass Enabled", Config.Theme.Green)
end

function Visual.DisableNoGrass()
	State.NoGrass = false
	for _, o in ipairs(Services.WS:GetDescendants()) do
		if o:IsA("BasePart") then o.LocalTransparencyModifier = 0 end
	end
	Notify("YOURSCRIPT", "Remove Grass Disabled", Config.Theme.Sub)
end

function Visual.ToggleNoGrass()
	if State.NoGrass then Visual.DisableNoGrass() else Visual.EnableNoGrass() end
end

function Visual.EnableNoShadow()
	State.NoShadow = true
	Services.Lighting.GlobalShadows = false
	Notify("YOURSCRIPT", "Remove Shadows Enabled", Config.Theme.Green)
end

function Visual.DisableNoShadow()
	State.NoShadow = false
	if not State.FullbrightOn then Services.Lighting.GlobalShadows = true end
	Notify("YOURSCRIPT", "Remove Shadows Disabled", Config.Theme.Sub)
end

function Visual.ToggleNoShadow()
	if State.NoShadow then Visual.DisableNoShadow() else Visual.EnableNoShadow() end
end

-- Preset grafis maksimum tetap; tidak menurunkan QualityLevel ketika FPS turun.
function Visual.EnableUltraHD()
	if State.UltraHD then return end
	local lighting = Services.Lighting
	State._ultraHDBackup = {
		EnvironmentDiffuseScale = lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = lighting.EnvironmentSpecularScale,
		LightingStyle = lighting.LightingStyle,
		PrioritizeLightingQuality = lighting.PrioritizeLightingQuality,
	}
	local okQuality, rendering = pcall(function() return settings().Rendering end)
	if okQuality and rendering then
		local okCurrent, quality = pcall(function() return rendering.QualityLevel end)
		if okCurrent then State._ultraHDQualityBackup = quality end
	end
	State.UltraHD = true
	pcall(function()
		lighting.EnvironmentDiffuseScale = 1
		lighting.EnvironmentSpecularScale = 1
		lighting.LightingStyle = Enum.LightingStyle.Realistic
		lighting.PrioritizeLightingQuality = true
	end)
	local okMax = pcall(function()
		State._ultraHDRendering = settings().Rendering
		State._ultraHDRendering.QualityLevel = Enum.QualityLevel.Level21
		State._ultraHDQuality = 21
	end)
	if not okMax then
		Visual.DisableUltraHD()
		Notify("YOURSCRIPT", "Graphics quality tidak dapat diubah di client ini", Config.Theme.Orange)
		return
	end
	local deviceLabel = Services.UIS.TouchEnabled and "Extreme / Hyper (Mobile)" or "Maxed Out (PC)"
	Notify("YOURSCRIPT", "Ultra HD Level 21 aktif — " .. deviceLabel, Config.Theme.Green)
end

function Visual.DisableUltraHD()
	if not State.UltraHD then return end
	State.UltraHD = false
	local backup = State._ultraHDBackup
	State._ultraHDBackup = nil
	if backup then
		pcall(function()
			Services.Lighting.EnvironmentDiffuseScale = backup.EnvironmentDiffuseScale
			Services.Lighting.EnvironmentSpecularScale = backup.EnvironmentSpecularScale
			Services.Lighting.LightingStyle = backup.LightingStyle
			Services.Lighting.PrioritizeLightingQuality = backup.PrioritizeLightingQuality
		end)
	end
	local qualityBackup = State._ultraHDQualityBackup
	State._ultraHDQualityBackup = nil
	State._ultraHDRendering = nil
	State._ultraHDQuality = nil
	if qualityBackup then
		pcall(function()
			settings().Rendering.QualityLevel = State.FPSBoost and Enum.QualityLevel.Level01 or qualityBackup
		end)
	end
	Notify("YOURSCRIPT", "Ultra HD Maxed Disabled", Config.Theme.Sub)
end

function Visual.EnableZoomUnlock()
	State.ZoomUnlock = true
	LP.CameraMaxZoomDistance = 1000
	LP.CameraMinZoomDistance = 0.5
	Notify("YOURSCRIPT", "Camera Zoom Unlocked", Config.Theme.Green)
end

function Visual.DisableZoomUnlock()
	State.ZoomUnlock = false
	LP.CameraMaxZoomDistance = 128
	Notify("YOURSCRIPT", "Camera Zoom Restored", Config.Theme.Sub)
end

function Visual.ToggleZoomUnlock()
	if State.ZoomUnlock then Visual.DisableZoomUnlock() else Visual.EnableZoomUnlock() end
end

function Visual.EnableFreeCam()
	if State.FreeCam then return end
	State.FreeCam = true
	local cam = workspace.CurrentCamera
	local hum = Util.Hum()
	local root = Util.Root()
	State._camType = cam and cam.CameraType or Enum.CameraType.Custom
	State._camSubject = cam and cam.CameraSubject or hum
	State._fcWalk = hum and hum.WalkSpeed or 16
	State._fcJump = hum and (hum.UseJumpPower and hum.JumpPower or hum.JumpHeight) or 50
	State._fcMouseBehavior = Services.UIS.MouseBehavior
	State._fcMouseIconEnabled = Services.UIS.MouseIconEnabled
	-- Keep mouse deltas flowing even when the pointer reaches the screen edge.
	if not Services.UIS.TouchEnabled then
		pcall(function()
			Services.UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
			Services.UIS.MouseIconEnabled = false
		end)
	end
	-- freeze character (drone body stay)
	if root then
		State._fcAnchor = root.CFrame
		root.Anchored = true
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	if hum then
		hum.WalkSpeed = 0
		pcall(function() if hum.UseJumpPower then hum.JumpPower = 0 else hum.JumpHeight = 0 end end)
		pcall(function() hum.AutoRotate = false end)
		pcall(function() hum.PlatformStand = true end)
	end
	if cam then
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CameraSubject = nil
	end
	local startCF = cam and cam.CFrame or (root and root.CFrame) or CFrame.new()
	local pos = startCF.Position
	local look = startCF.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local pitch = math.asin(math.clamp(look.Y, -0.99, 0.99))
	local vel = Vector3.zero
	local keys = {}
	-- touch: kiri = gerak, kanan = lihat (drone mobile)
	local moveTouch, lookTouch = nil, nil
	local moveVec = Vector3.zero -- x=strafe, z=forward in camera space
	local lookLast = nil

	local function isKey(k) return keys[k] == true end

	Util.Connect("FreeCamIn", Services.UIS.InputBegan, function(input, gp)
		if not State.FreeCam then return end
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			keys[input.KeyCode] = true
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
			local x = input.Position.X
			if x < vp.X * 0.45 and not moveTouch then
				moveTouch = input
				moveVec = Vector3.zero
			elseif x >= vp.X * 0.45 and not lookTouch then
				lookTouch = input
				lookLast = Vector2.new(input.Position.X, input.Position.Y)
			end
		end
	end)
	Util.Connect("FreeCamOut", Services.UIS.InputEnded, function(input)
		if input.KeyCode ~= Enum.KeyCode.Unknown then keys[input.KeyCode] = nil end
		if input == moveTouch then moveTouch = nil; moveVec = Vector3.zero end
		if input == lookTouch then lookTouch = nil; lookLast = nil end
	end)
	Util.Connect("FreeCamLook", Services.UIS.InputChanged, function(input)
		if not State.FreeCam then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			yaw = yaw - input.Delta.X * 0.003
			pitch = math.clamp(pitch - input.Delta.Y * 0.003, -1.4, 1.4)
		elseif input.UserInputType == Enum.UserInputType.Touch then
			if input == lookTouch and lookLast then
				local cur = Vector2.new(input.Position.X, input.Position.Y)
				local d = cur - lookLast
				lookLast = cur
				yaw = yaw - d.X * 0.004
				pitch = math.clamp(pitch - d.Y * 0.004, -1.4, 1.4)
			elseif input == moveTouch then
				local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
				-- virtual stick dari titik sentuh kiri
				local cx = vp.X * 0.22
				local cy = vp.Y * 0.72
				local dx = (input.Position.X - cx) / 80
				local dy = (input.Position.Y - cy) / 80
				dx = math.clamp(dx, -1, 1)
				dy = math.clamp(dy, -1, 1)
				moveVec = Vector3.new(dx, 0, -dy) -- z maju
			end
		end
	end)

	Util.Connect("FreeCam", Services.RS.RenderStepped, function(dt)
		if not State.FreeCam then return end
		local c = workspace.CurrentCamera
		if not c then return end
		dt = math.clamp(dt or 0.016, 0, 0.05)
		local boost = (isKey(Enum.KeyCode.LeftShift) or isKey(Enum.KeyCode.RightShift)) and 2.2 or 1
		local maxSpd = 55 * boost
		local accel = 120 * boost
		-- Dedicated keyboard look controls; WASD remains available for movement.
		local turnRate = 1.8 * dt
		if isKey(Enum.KeyCode.J) then yaw = yaw + turnRate end
		if isKey(Enum.KeyCode.L) then yaw = yaw - turnRate end
		if isKey(Enum.KeyCode.I) then pitch = math.clamp(pitch + turnRate, -1.4, 1.4) end
		if isKey(Enum.KeyCode.K) then pitch = math.clamp(pitch - turnRate, -1.4, 1.4) end
		local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
		local wish = Vector3.zero
		-- PC keys
		if isKey(Enum.KeyCode.W) or isKey(Enum.KeyCode.Up) then wish = wish + rot.LookVector end
		if isKey(Enum.KeyCode.S) or isKey(Enum.KeyCode.Down) then wish = wish - rot.LookVector end
		if isKey(Enum.KeyCode.A) or isKey(Enum.KeyCode.Left) then wish = wish - rot.RightVector end
		if isKey(Enum.KeyCode.D) or isKey(Enum.KeyCode.Right) then wish = wish + rot.RightVector end
		if isKey(Enum.KeyCode.E) or isKey(Enum.KeyCode.Space) then wish = wish + Vector3.yAxis end
		if isKey(Enum.KeyCode.Q) or isKey(Enum.KeyCode.LeftControl) then wish = wish - Vector3.yAxis end
		-- mobile stick
		if moveTouch and moveVec.Magnitude > 0.05 then
			wish = wish + rot.LookVector * moveVec.Z + rot.RightVector * moveVec.X
		end
		if wish.Magnitude > 1e-3 then
			wish = wish.Unit * maxSpd
		else
			wish = Vector3.zero
		end
		-- smooth drone acceleration
		vel = vel:Lerp(wish, math.clamp(accel * dt / maxSpd, 0, 1))
		if wish.Magnitude < 1e-3 then
			vel = vel * math.clamp(1 - 4 * dt, 0, 1) -- drag stop
		end
		pos = pos + vel * dt
		c.CFrame = CFrame.new(pos) * rot
		-- keep body frozen
		local r = Util.Root()
		if r and State._fcAnchor then
			r.Anchored = true
			r.CFrame = State._fcAnchor
			r.AssemblyLinearVelocity = Vector3.zero
		end
	end)

	Notify("FreeCam", "DRONE ON — PC: WASD+QE, putar J/L + I/K | Mobile: kiri gerak / kanan lihat", Config.Theme.Green)
end

function Visual.DisableFreeCam()
	State.FreeCam = false
	Util.Disconnect("FreeCam")
	Util.Disconnect("FreeCamLook")
	Util.Disconnect("FreeCamIn")
	Util.Disconnect("FreeCamOut")
	local cam = workspace.CurrentCamera
	local hum = Util.Hum()
	local root = Util.Root()
	if root then
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
	end
	if hum then
		hum.WalkSpeed = State._fcWalk or 16
		pcall(function()
			if hum.UseJumpPower then hum.JumpPower = State._fcJump or 50
			else hum.JumpHeight = State._fcJump or 7.2 end
		end)
		pcall(function() hum.AutoRotate = true end)
		pcall(function() hum.PlatformStand = false end)
	end
	if cam then
		cam.CameraType = State._camType or Enum.CameraType.Custom
		cam.CameraSubject = State._camSubject or hum
	end
	pcall(function()
		if State._fcMouseBehavior then Services.UIS.MouseBehavior = State._fcMouseBehavior end
		if State._fcMouseIconEnabled ~= nil then Services.UIS.MouseIconEnabled = State._fcMouseIconEnabled end
	end)
	State._fcMouseBehavior = nil
	State._fcMouseIconEnabled = nil
	State._fcAnchor = nil
	Notify("FreeCam", "OFF", Config.Theme.Sub)
end


-- ============================================================
-- WEATHER (Hujan / Banjir / Salju) — TAHAP PENGEMBANGAN (dikunci)
-- ============================================================
local function weatherLockedNotify(name)
	Notify("Tahap pengembangan", (name or "Fitur cuaca") .. " masih dikunci", Config.Theme.Sub)
end

function Visual.DisableAllWeather()
	State.WeatherRain = false
	State.WeatherFlood = false
	State.WeatherSnow = false
end

function Visual.EnableRain()
	State.WeatherRain = false
	weatherLockedNotify("Hujan")
end
function Visual.DisableRain()
	State.WeatherRain = false
end

function Visual.EnableFlood()
	State.WeatherFlood = false
	weatherLockedNotify("Banjir")
end
function Visual.DisableFlood()
	State.WeatherFlood = false
end

function Visual.EnableSnow()
	State.WeatherSnow = false
	weatherLockedNotify("Salju")
end
function Visual.DisableSnow()
	State.WeatherSnow = false
end





function Visual.ToggleFreeCam()
	if State.FreeCam then Visual.DisableFreeCam() else Visual.EnableFreeCam() end
end

-- ESP toggles
-- ANTI-LAG (C): tiap toggle OFF cek — kalau semua fitur berat mati, loop dihentikan (tidak jalan hampa).
local function ESPMaybeStop()
	if not State.ItemESP and not State.MonsterESP and not State.PlayerESP
		and not State.MonsterTracker and not State.PlayerTracker then
		Util.Disconnect("ESPLoop")
	end
end

function Visual.ToggleItemESP()
	State.ItemESP = not State.ItemESP
	if State.ItemESP then ESP.StartLoop(); Notify("YOURSCRIPT", "Item ESP Enabled", Config.Theme.Green)
	else ESP.Clear("item"); ESPMaybeStop(); Notify("YOURSCRIPT", "Item ESP Disabled", Config.Theme.Sub) end
end

function Visual.ToggleMonsterESP()
	State.MonsterESP = not State.MonsterESP
	if State.MonsterESP then ESP.StartLoop(); Notify("YOURSCRIPT", "Monster ESP Enabled", Config.Theme.Green)
	else ESP.Clear("monster"); ESPMaybeStop(); Notify("YOURSCRIPT", "Monster ESP Disabled", Config.Theme.Sub) end
end

function Visual.TogglePlayerESP()
	State.PlayerESP = not State.PlayerESP
	if State.PlayerESP then ESP.StartLoop(); Notify("YOURSCRIPT", "Player ESP Enabled", Config.Theme.Green)
	else ESP.Clear("player"); ESPMaybeStop(); Notify("YOURSCRIPT", "Player ESP Disabled", Config.Theme.Sub) end
end

function Visual.ToggleTracers()
	State.Tracers = not State.Tracers
	Notify("YOURSCRIPT", State.Tracers and "Tracers Enabled" or "Tracers Disabled",
		State.Tracers and Config.Theme.Green or Config.Theme.Sub)
end

function Visual.ToggleDistESP()
	State.DistESP = not State.DistESP
	Notify("YOURSCRIPT", State.DistESP and "Distance ESP On" or "Distance ESP Off", Config.Theme.Accent)
end

function Visual.ToggleNameESP()
	State.NameESP = not State.NameESP
	Notify("YOURSCRIPT", State.NameESP and "Name ESP On" or "Name ESP Off", Config.Theme.Accent)
end

function Visual.ToggleChams()
	State.Chams = not State.Chams
	if not State.Chams then
		if ESPFolder then
			for _, o in ipairs(ESPFolder:GetChildren()) do
				if o:IsA("Highlight") then o:Destroy() end
			end
		end
		local function wipeHl(cache)
			if not cache then return end
			for _, e in pairs(cache) do e.hl = nil end
		end
		wipeHl(ESP._cache); wipeHl(ESP._mcache); wipeHl(ESP._pcache)
	else
		ESP._cache, ESP._mcache, ESP._pcache = nil, nil, nil
	end
	Notify("YOURSCRIPT", State.Chams and "Chams Enabled" or "Chams Disabled",
		State.Chams and Config.Theme.Green or Config.Theme.Sub)
end

----------------------------------------------------------------
-- PLAYER MODULE
----------------------------------------------------------------
local PlayerMod = {}

function PlayerMod.EnableSpectate()
	local t = State.TargetPlayer or State.Target
	if not t then
		Notify("YOURSCRIPT", "Select Target First", Config.Theme.Orange)
		return
	end
	local hum = Util.Hum(t)
	if not hum then
		Notify("YOURSCRIPT", "Target Has No Character", Config.Theme.Orange)
		return
	end
	State.SpectateOn = true
	State.SpectateTarget = t
	local cam = Services.WS.CurrentCamera
	if cam then cam.CameraSubject = hum end
	Notify("YOURSCRIPT", "Spectating " .. (t.DisplayName or t.Name), Config.Theme.Green)
end

function PlayerMod.DisableSpectate()
	State.SpectateOn = false
	State.SpectateTarget = nil
	local cam = Services.WS.CurrentCamera
	local hum = Util.Hum()
	if cam and hum then cam.CameraSubject = hum end
	Notify("YOURSCRIPT", "Spectate Disabled", Config.Theme.Sub)
end

function PlayerMod.ToggleSpectate()
	if State.SpectateOn then PlayerMod.DisableSpectate() else PlayerMod.EnableSpectate() end
end

function PlayerMod.EnableTracker()
	State.PlayerTracker = true
	ESP.StartLoop()
	Notify("YOURSCRIPT", "Player Tracker Enabled", Config.Theme.Green)
end

function PlayerMod.DisableTracker()
	State.PlayerTracker = false
	if UI.PTrackerLbl then UI.PTrackerLbl.Text = "PLAYER: -" end
	if not State.ItemESP and not State.MonsterESP and not State.PlayerESP
		and not State.MonsterTracker and not State.PlayerTracker then
		Util.Disconnect("ESPLoop")
	end
	Notify("YOURSCRIPT", "Player Tracker Disabled", Config.Theme.Sub)
end

function PlayerMod.ToggleTracker()
	if State.PlayerTracker then PlayerMod.DisableTracker() else PlayerMod.EnableTracker() end
end

----------------------------------------------------------------
-- UTILITY MODULE
----------------------------------------------------------------
local Utility = {}

function Utility.EnableAntiAFK()
	State.AntiAFK = true
	Util.Connect("AntiAFK", Services.Players.LocalPlayer.Idled, function()
		Util.Safe(function()
			Services.VU:CaptureController()
			Services.VU:ClickButton2(Vector2.new())
		end)
	end)
	Notify("YOURSCRIPT", "Anti AFK Enabled", Config.Theme.Green)
end

function Utility.DisableAntiAFK()
	State.AntiAFK = false
	Util.Disconnect("AntiAFK")
	Notify("YOURSCRIPT", "Anti AFK Disabled", Config.Theme.Sub)
end

function Utility.ToggleAntiAFK()
	if State.AntiAFK then Utility.DisableAntiAFK() else Utility.EnableAntiAFK() end
end

function Utility.EnableFPSBoost()
	-- FPS Boost changes shadows, fog, particles, and quality; keep the active
	-- Ultra HD preset untouched instead of silently degrading its appearance.
	if State.UltraHD then
		Notify("YOURSCRIPT", "FPS Boost tidak bisa dipakai saat Ultra HD aktif", Config.Theme.Orange)
		return
	end
	State.FPSBoost = true
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	Services.Lighting.GlobalShadows = false
	Services.Lighting.FogEnd = 1e6
	for _, v in ipairs(Services.WS:GetDescendants()) do
		if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
			v.Enabled = false
		end
		if v:IsA("Explosion") then v:Destroy() end
	end
	Notify("YOURSCRIPT", "FPS Boost Enabled", Config.Theme.Green)
end

function Utility.DisableFPSBoost()
	State.FPSBoost = false
	if not State.UltraHD then
		settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
	end
	Notify("YOURSCRIPT", "FPS Boost Disabled", Config.Theme.Sub)
end

function Utility.ToggleFPSBoost()
	if State.FPSBoost then Utility.DisableFPSBoost() else Utility.EnableFPSBoost() end
end

function Utility.Rejoin()
	Notify("YOURSCRIPT", "Rejoining...", Config.Theme.Accent)
	task.wait(0.4)
	Util.Safe(function()
		Services.Teleport:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
	end)
end

function Utility.ServerHop()
	Notify("YOURSCRIPT", "Server Hopping...", Config.Theme.Accent)
	task.spawn(function()
		Util.Safe(function()
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
			local raw
			if syn and syn.request then
				raw = syn.request({ Url = url, Method = "GET" }).Body
			elseif request then
				raw = request({ Url = url, Method = "GET" }).Body
			elseif game.HttpGet then
				raw = game:HttpGet(url)
			end
			if not raw then
				Notify("YOURSCRIPT", "Http Not Available", Config.Theme.Orange)
				return
			end
			local data = Services.Http:JSONDecode(raw)
			if data and data.data then
				for _, s in ipairs(data.data) do
					if s.playing < s.maxPlayers and s.id ~= game.JobId then
						Services.Teleport:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
						return
					end
				end
			end
			Notify("YOURSCRIPT", "No Server Found", Config.Theme.Orange)
		end)
	end)
end

----------------------------------------------------------------
-- [BARU] SERVERHOP TO USER — join server siapapun via username
-- username -> userId (users.roblox.com) -> presence (PlaceId + GameId)
--            -> TeleportService:TeleportToPlaceInstance(placeId, jobId, LP)
-- fallback : server-hop biasa di game yang sama (Utility.ServerHop)
----------------------------------------------------------------
function Utility.JoinUserServer(username)
	username = tostring(username or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if username == "" then
		Notify("ServerHop", "Masukan username dulu!", Config.Theme.Accent)
		return
	end

	Notify("ServerHop", "Mencari user: " .. username .. "...", Config.Theme.Accent)

	-- 1) username -> userId (multiple endpoints for reliability)
	local uid = nil
	local endpoints = {
		"https://users.roblox.com/v1/usernames/users",
		"https://api.roblox.com/users/get-by-username?username=" .. HttpService:UrlEncode(username),
	}
	
	for _, ep in ipairs(endpoints) do
		local code, body
		if ep:find("usernames/users") then
			code, body = HttpPost(ep, { usernames = { username }, excludeBannedUsers = false })
		else
			code, body = HttpGet(ep)
		end
		
		if code and body then
			local ok, data = pcall(function() return Services.Http:JSONDecode(body) end)
			if ok and data then
				if data.data and data.data[1] and data.data[1].id then
					uid = data.data[1].id
					break
				elseif data.Id then
					uid = data.Id
					break
				end
			end
		end
		task.wait(0.2)
	end
	
	if not uid then
		Notify("ServerHop", "User '" .. username .. "' tidak ditemukan", Config.Theme.Red)
		return
	end

	Notify("ServerHop", "User ditemukan (ID: " .. uid .. "), cek presence...", Config.Theme.Accent)

	-- 2) userId -> presence (multiple endpoints with better error handling)
	local pres = nil
	local presenceEndpoints = {
		{ url = "https://presence.roblox.com/v1/presence/users", method = "POST", body = { userIds = { uid } } },
		{ url = "https://www.roblox.com/presence/user?userId=" .. uid, method = "GET" },
		{ url = "https://presence.roblox.com/v1/presence/user/" .. uid, method = "GET" },
	}
	
	for _, ep in ipairs(presenceEndpoints) do
		local code, body
		if ep.method == "POST" then
			code, body = HttpPost(ep.url, ep.body)
		else
			code, body = HttpGet(ep.url)
		end
		
		if code and body then
			local ok, data = pcall(function() return Services.Http:JSONDecode(body) end)
			if ok and data then
				if data.userPresences and data.userPresences[1] then
					pres = data.userPresences[1]
					break
				elseif data.userPresenceType then
					pres = data
					break
				end
			end
		end
		task.wait(0.2)
	end

	if not pres then
		Notify("ServerHop", "Gagal cek presence (API blocked/limit) - fallback server hop", Config.Theme.Orange)
		Utility.ServerHop()
		return
	end

	-- 3) baca presence — dukung camelCase (API baru) & PascalCase (endpoint lama)
	local pType   = tonumber(pres.userPresenceType or pres.UserPresenceType)
	local placeId = pres.placeId or pres.PlaceId or pres.rootPlaceId or pres.RootPlaceId
	local jobId   = pres.gameId or pres.GameId

	print("[ServerHop Debug] pType:", pType, "placeId:", placeId, "jobId:", jobId)

	if pType == 2 and placeId and jobId and jobId ~= "" then
		-- sudah satu server? tidak usah teleport (biar nggak rejoin percuma)
		if tostring(jobId) == tostring(game.JobId) and tonumber(placeId) == game.PlaceId then
			Notify("ServerHop", "'" .. username .. "' satu server denganmu!", Config.Theme.Green)
			return
		end
		Notify("ServerHop", "Joining server '" .. username .. "' (Place: " .. placeId .. ")...", Config.Theme.Accent)
		task.wait(1)
		local okTp = Util.Safe(function()
			Services.Teleport:TeleportToPlaceInstance(placeId, jobId, LP)
		end)
		if not okTp then
			Notify("ServerHop", "Gagal join, server-hop biasa...", Config.Theme.Orange)
			task.wait(0.5)
			Utility.ServerHop()
		end
	else
		Notify("ServerHop", "'" .. username .. "' tidak in-game (type: " .. tostring(pType) .. "), hop server biasa...", Config.Theme.Accent)
		Utility.ServerHop()
	end
end

----------------------------------------------------------------
-- [MERGED] GAME MODULE — fitur dari dangerousnight.lua
----------------------------------------------------------------
local Game = {}

-- Collect All Food: teleport ke tiap Tool (makanan) + fire proximity prompt
function Game.CollectAllFood()
	local r = Util.Root()
	if not r then
		Notify("YOURSCRIPT", "Character Not Ready", Config.Theme.Orange)
		return
	end
	local lastPos = r.CFrame
	local count = 0
	for _, food in ipairs(Services.WS:GetChildren()) do
		if food:IsA("Tool") then
			local handle = food:FindFirstChild("Handle")
			local prompt = handle and handle:FindFirstChildOfClass("ProximityPrompt")
			if handle and prompt then
				Util.Safe(function()
					r.CFrame = handle.CFrame * CFrame.new(0, 5, 0)
					task.wait(0.25)
					if fireproximityprompt then
						fireproximityprompt(prompt, prompt.MaxActivationDistance)
					end
					count = count + 1
				end)
			end
		end
	end
	task.wait(0.25)
	local r2 = Util.Root()
	if r2 then r2.CFrame = lastPos end
	Notify("YOURSCRIPT", "Collected " .. count .. " Food", Config.Theme.Accent)
end

-- Drop All Food: pindahkan backpack ke karakter lalu mati agar item jatuh, respawn otomatis ke posisi semula
function Game.DropAllFood()
	local r = Util.Root()
	if not r then
		Notify("YOURSCRIPT", "Character Not Ready", Config.Theme.Orange)
		return
	end
	State.PendingRespawnPos = r.CFrame
	for _, food in ipairs(LP.Backpack:GetChildren()) do
		food.Parent = LP.Character
	end
	task.wait(0.25)
	local hum = Util.Hum()
	if hum then hum.Health = 0 end
	Notify("YOURSCRIPT", "Dropped All Food (respawn)", Config.Theme.Orange)
end

-- Furniture (legacy dangerousnight, dipertahankan agar API lama tidak error;
-- UI-nya sudah dihapus — Spam Item kini ikut State.ItemName tab Farm)
local FurnitureSelected = nil

local function ReturnFurniture()
	local Names = {}
	local wypos = Services.WS:FindFirstChild("Wyposazenie")
	if not wypos then return Names end
	for _, item in ipairs(wypos:GetChildren()) do
		if item:IsA("Folder") then
			for _, interno in ipairs(item:GetChildren()) do
				if interno:IsA("Model") and not table.find(Names, interno.Name) then
					table.insert(Names, interno.Name)
				end
			end
		elseif item:IsA("Model") and not table.find(Names, item.Name) then
			table.insert(Names, item.Name)
		end
	end
	return Names
end

local function GetFurniture()
	local wypos = Services.WS:FindFirstChild("Wyposazenie")
	if not wypos then return false end
	for _, furniture in ipairs(wypos:GetChildren()) do
		if furniture:IsA("Folder") then
			for _, interno in ipairs(furniture:GetChildren()) do
				if interno:IsA("Model") and interno.Name == FurnitureSelected then
					local ev = Services.Rep:FindFirstChild("PickupItemEvent")
					if ev then ev:FireServer(interno) end
					return true
				end
			end
		elseif furniture:IsA("Model") and furniture.Name == FurnitureSelected then
			local ev = Services.Rep:FindFirstChild("PickupItemEvent")
			if ev then ev:FireServer(furniture) end
			return true
		end
	end
	return false
end

-- [LEGACY] API furniture lama dipertahankan (tidak ada UI yang memanggil lagi).
-- Spam Item kini memakai State.ItemName dari tab Farm.
function Game.RefreshFurnitureList()
	local names = ReturnFurniture()
	if #names == 0 then
		FurnitureSelected = nil
		return
	end
	if not FurnitureSelected or not table.find(names, FurnitureSelected) then
		FurnitureSelected = names[1]
	end
end

function Game.FurnPrev()
	local names = ReturnFurniture()
	if #names == 0 then Game.RefreshFurnitureList(); return end
	local i = table.find(names, FurnitureSelected) or 1
	i = i - 1
	if i < 1 then i = #names end
	FurnitureSelected = names[i]
end

function Game.FurnNext()
	local names = ReturnFurniture()
	if #names == 0 then Game.RefreshFurnitureList(); return end
	local i = table.find(names, FurnitureSelected) or 0
	i = i + 1
	if i > #names then i = 1 end
	FurnitureSelected = names[i]
end

function Game.BringFurniture()
	if not FurnitureSelected then
		Notify("YOURSCRIPT", "No Furniture Selected", Config.Theme.Orange)
		return
	end
	if GetFurniture() then
		Notify("YOURSCRIPT", "Brought: " .. FurnitureSelected, Config.Theme.Accent)
	else
		Notify("YOURSCRIPT", "Furniture Not Found", Config.Theme.Orange)
	end
end

----------------------------------------------------------------
-- SPAM ITEM (REVISI TOTAL v2 — Dangerous Night carry system)
-- Cara kerja game (dari diagnostic + source resmi):
--   • Furniture market ada di Workspace.Wyposazenie
--   • Item bunker ada di Workspace.Wyposazenie.{UserId}_Wyposazenie
--   • Pickup furniture = tekan / hold Z  (+ ProximityPrompt Take + PickupItemEvent)
--   • Saat dipegang = Model pindah ke Workspace.Camera, di-Weld ke HRP
--   • Drop = tekan Z lagi
--   • Hanya 1 item bisa dipegang sekaligus
--
-- Flow yang dijalankan:
--   1. Simpan StartPosition SEKALI saat toggle ON
--   2. Cari SEMUA item nama cocok yang BUKAN di folder bunker
--   3. Urut jarak terdekat
--   4. TP → pickup (Z + prompt + remote) → tunggu held
--   5. TP balik StartPosition → tekan Z (drop)
--   6. Mark visited → item berikutnya
--   7. Habis → rescan → ulangi sampai Stop ditekan
----------------------------------------------------------------

-- true jika object berada di dalam folder bunker pemain ({UserId}_Wyposazenie)
local function IsBunkerItem(o)
	local a = o
	while a and a ~= Services.WS do
		local n = tostring(a.Name or "")
		-- folder khas bunker: 123456789_Wyposazenie
		if n:match("^%d+_Wyposazenie$") or n:match("^%d+_wyposazenie$") then
			return true
		end
		-- attribute yang dipasang game saat item di bunker
		if a:GetAttribute("BunkerSlotOrigin") then
			return true
		end
		-- keyword bunker klasik
		local low = string.lower(n)
		for _, kw in ipairs(Config.Keywords.Area.Bunker) do
			if low:find(kw, 1, true) then return true end
		end
		a = a.Parent
	end
	return false
end

-- true jika sedang memegang furniture (ada model di Camera yang di-weld ke HRP)
local function IsHoldingFurniture()
	local hrp = Util.Root()
	if not hrp then return false, nil end
	local cams = {}
	local c1 = workspace:FindFirstChild("Camera")
	local c2 = workspace.CurrentCamera
	if c1 then table.insert(cams, c1) end
	if c2 and c2 ~= c1 then table.insert(cams, c2) end
	for _, cam in ipairs(cams) do
		for _, child in ipairs(cam:GetChildren()) do
			if child:IsA("Model") then
				-- wajib: ada weld HRP ↔ part di model (cara DN men-carry)
				for _, w in ipairs(hrp:GetChildren()) do
					if w:IsA("Weld") or w:IsA("WeldConstraint") or w:IsA("ManualWeld") then
						local other = (w.Part0 == hrp) and w.Part1 or w.Part0
						if other and other:IsDescendantOf(child) then
							return true, child
						end
					end
				end
			end
		end
	end
	return false, nil
end

-- true hanya HP murni (touch + tanpa keyboard). Laptop touch tetap pakai Z.
local function IsPureMobile()
	local ok, r = pcall(function()
		local uis = Services.UIS
		return uis.TouchEnabled and (not uis.KeyboardEnabled)
	end)
	return ok and r == true
end

-- tekan Z (pickup/drop). Di HP murni: skip VIM (anti force-close).
local function PressZ()
	if IsPureMobile() then
		return false
	end
	local ok = pcall(function()
		local vim = game:GetService("VirtualInputManager")
		vim:SendKeyEvent(true, Enum.KeyCode.Z, false, game)
		task.wait(0.08)
		vim:SendKeyEvent(false, Enum.KeyCode.Z, false, game)
	end)
	if ok then return true end
	ok = pcall(function()
		if keypress then
			keypress(0x5A)
			task.wait(0.08)
			if keyrelease then keyrelease(0x5A) end
		else
			error("no keypress")
		end
	end)
	return ok
end

-- Posisi drop stabil di lantai (raycast), tidak di udara / tidak nge-fling
local function StableDropCF(atCF)
	local hrp = Util.Root()
	local base = (atCF and atCF.Position) or (hrp and hrp.Position) or Vector3.zero
	local origin = base + Vector3.new(0, 6, 0)
	local hit = nil
	pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local char = Util.Char and Util.Char() or (hrp and hrp.Parent)
		params.FilterDescendantsInstances = { char }
		hit = workspace:Raycast(origin, Vector3.new(0, -40, 0), params)
	end)
	local pos
	if hit then
		pos = hit.Position + Vector3.new(0, 0.15, 0)
	else
		pos = Vector3.new(base.X, base.Y - 2.5, base.Z)
	end
	local look = (atCF and atCF.LookVector) or (hrp and hrp.CFrame.LookVector) or Vector3.new(0, 0, -1)
	return CFrame.new(pos, pos + Vector3.new(look.X, 0, look.Z))
end

-- Drop paksa stabil: putus weld, taruh di lantai, anchor sebentar, zero velocity
local function ForceDropFurniture(atCF)
	local hrp = Util.Root()
	if not hrp then return end
	local cam = workspace:FindFirstChild("Camera") or workspace.CurrentCamera
	if not cam then return end

	local heldModels = {}
	for _, child in ipairs(cam:GetChildren()) do
		if child:IsA("Model") then
			for _, w in ipairs(hrp:GetChildren()) do
				if w:IsA("Weld") or w:IsA("WeldConstraint") or w:IsA("ManualWeld") then
					local other = (w.Part0 == hrp) and w.Part1 or w.Part0
					if other and other:IsDescendantOf(child) then
						heldModels[child] = true
						pcall(function() w:Destroy() end)
					end
				end
			end
		end
	end
	for _, w in ipairs(hrp:GetChildren()) do
		if w:IsA("Weld") or w:IsA("WeldConstraint") or w:IsA("ManualWeld") then
			local other = (w.Part0 == hrp) and w.Part1 or w.Part0
			if other and cam and other:IsDescendantOf(cam) then
				local m = other.Parent
				while m and m.Parent and m.Parent ~= cam do m = m.Parent end
				if m and m:IsA("Model") then heldModels[m] = true end
				pcall(function() w:Destroy() end)
			end
		end
	end

	local destParent = Services.WS:FindFirstChild("Wyposazenie") or Services.WS
	local dropCF = StableDropCF(atCF)
	for model in pairs(heldModels) do
		pcall(function()
			-- hentikan fisika dulu
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					d.AssemblyLinearVelocity = Vector3.zero
					d.AssemblyAngularVelocity = Vector3.zero
					d.Anchored = true
				end
			end
			model.Parent = destParent
			if model.PivotTo then
				model:PivotTo(dropCF)
			else
				local p = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
				if p then p.CFrame = dropCF end
			end
			-- pastikan diam di posisi drop
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					d.AssemblyLinearVelocity = Vector3.zero
					d.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end)
		-- lepas anchor setelah settle (supaya game tetap bisa interact)
		task.delay(0.35, function()
			pcall(function()
				if not model or not model.Parent then return end
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("BasePart") then
						d.AssemblyLinearVelocity = Vector3.zero
						d.AssemblyAngularVelocity = Vector3.zero
						d.Anchored = false
					end
				end
			end)
		end)
	end
	-- pastikan kamera tetap ke Humanoid (bukan model furniture)
	pcall(function()
		local cam = workspace.CurrentCamera
		local hum = Util.Hum()
		if cam and hum then cam.CameraSubject = hum end
	end)
end

-- Drop lengkap: remote + Z dulu, baru force stabil (jangan spam force)
local function DoDropFurniture(atCF)
	pcall(function()
		local ev = Services.Rep:FindFirstChild("DropItemEvent", true)
		if ev then ev:FireServer() end
	end)
	PressZ()
	task.wait(0.1)
	if IsHoldingFurniture() then
		ForceDropFurniture(atCF)
		task.wait(0.08)
	end
	if IsHoldingFurniture() then
		PressZ()
		task.wait(0.08)
		ForceDropFurniture(atCF)
	end
	-- anti zoom: subject kembali ke Humanoid
	pcall(function()
		local cam = workspace.CurrentCamera
		local hum = Util.Hum()
		if cam and hum then cam.CameraSubject = hum end
	end)
end

-- cari semua item market yang cocok nama & BELUM di bunker

-- Daftar nama item GUDANG LANGKA saja (whitelist dari observasi map)
local function IsGudangLangkaName(nm)
	nm = string.lower(tostring(nm or ""))
	if nm == "" then return false end
	-- whitelist pola nama (bukan lokasi — lokasi MarketWyposazenie campur barang market)
	local patterns = {
		"beanbag",
		"wallshelf", "wall shelf",
		"walldecor", "wall decor", "wall_decor",
		"sofa4", "sofa5", "sofa6",
		"armchair3", "armchair4",
		"tire",
		"table6", "table7", "table8",
		"warehouseshelf", "warehouse shelf",
		"bookshelf",
		"speaker",
		"box1", "box2", "box3",
		"wardrobe",
		"ceilingfan", "cellingfan", "ceiling fan",
		"nightstand",
		"workbench", "workbanch",
		"rubberduck", "rubber duck",
		"radio",
		"pouf",
		"destroyer",
	}
	for _, p in ipairs(patterns) do
		if nm:find(p, 1, true) then return true end
	end
	-- Shelf + angka (Shelf5, Shelf6, ...)
	if nm:match("^shelf%d") then return true end
	return false
end

local function GetGudangLangkaNames()
	local names, seen = {}, {}
	local function add(n)
		if n and n ~= "" and not seen[n] and IsGudangLangkaName(n) then
			seen[n] = true
			table.insert(names, n)
		end
	end
	local function scan(root, deep)
		if not root then return end
		if deep then
			for _, c in ipairs(root:GetDescendants()) do
				if c:IsA("Model") or c:IsA("Tool") then add(c.Name) end
			end
		else
			for _, c in ipairs(root:GetChildren()) do
				if c:IsA("Model") or c:IsA("Tool") then add(c.Name) end
			end
		end
	end
	-- prioritaskan folder gudang, tapi tetap filter nama
	local mw = Services.WS:FindFirstChild("MarketWyposazenie")
		or Services.WS:FindFirstChild("MarketWyposazenie", true)
	scan(mw, false)
	local mag = Services.WS:FindFirstChild("Magazine")
	scan(mag, true)
	local wy = Services.WS:FindFirstChild("Wyposazenie")
	if wy then
		for _, c in ipairs(wy:GetChildren()) do
			local nm = tostring(c.Name)
			if not nm:match("^%d+_Wyposazenie$") then
				if c:IsA("Model") or c:IsA("Tool") then add(c.Name) end
			end
		end
	end
	for _, o in ipairs(ScanCache.Items or {}) do
		if o and o.Parent then add(o.Name) end
	end
	table.sort(names)
	return names
end

local function PosKey(pos)
	-- grid 6 stud — supaya item yang sama (instance baru) tidak di-spam ulang
	return string.format("%d_%d_%d", math.floor(pos.X / 6), math.floor(pos.Y / 6), math.floor(pos.Z / 6))
end

local function IsInMarketOrGudang(o)
	local a = o
	while a and a ~= Services.WS do
		local n = tostring(a.Name or "")
		if n == "MarketWyposazenie" or n == "Magazine" or n == "Market" then
			return true
		end
		-- folder market klasik
		local low = string.lower(n)
		if low:find("market", 1, true) or low:find("sklep", 1, true) or low:find("mart", 1, true) then
			return true
		end
		a = a.Parent
	end
	return false
end


local function ToggleSpamMark(name)
	if not name or name == "" then return false end
	if not State.SpamMarks then State.SpamMarks = {} end
	if State.SpamMarks[name] then
		State.SpamMarks[name] = nil
		return false
	else
		State.SpamMarks[name] = true
		return true
	end
end

local function IsSpamMarked(name)
	return State.SpamMarks and State.SpamMarks[name] == true
end

local function GetSpamMarkList()
	local t = {}
	if State.SpamMarks then
		for name, on in pairs(State.SpamMarks) do
			if on then table.insert(t, name) end
		end
	end
	table.sort(t)
	return t
end

local function ClearSpamMarks()
	State.SpamMarks = {}
end

local function AddDropPoint()
	local hrp = Util.Root()
	if not hrp then
		Notify("Drop Point", "Character Not Ready", Config.Theme.Red)
		return
	end
	if not State.DropPoints then State.DropPoints = {} end
	table.insert(State.DropPoints, hrp.CFrame)
	Notify("Drop Point", "Titik #" .. #State.DropPoints .. " disimpan", Config.Theme.Green)
end

local function ClearDropPoints()
	State.DropPoints = {}
	State.DropPointIdx = 1
	Notify("Drop Point", "Semua titik drop dihapus", Config.Theme.Sub)
end

-- ambil CFrame drop berikutnya (putar). fallback = homeCF
local function NextDropCF(homeCF)
	local list = State.DropPoints
	if not list or #list == 0 then
		return homeCF
	end
	local i = State.DropPointIdx or 1
	if i < 1 or i > #list then i = 1 end
	local cf = list[i]
	State.DropPointIdx = (i % #list) + 1
	return cf
end


-- Kunci kamera saat spam (anti zoom in/out karena furniture di Camera)
local function CaptureCamZoom()
	local snap = {}
	pcall(function()
		local cam = workspace.CurrentCamera
		local LP = Services.LP
		if cam then
			snap.FOV = cam.FieldOfView
			snap.CamType = cam.CameraType
		end
		if LP then
			snap.MinZ = LP.CameraMinZoomDistance
			snap.MaxZ = LP.CameraMaxZoomDistance
		end
		local hum = Util.Hum()
		if hum then snap.Subject = hum end
	end)
	return snap
end

local function ApplyCamZoom(snap)
	if not snap then return end
	pcall(function()
		local cam = workspace.CurrentCamera
		local LP = Services.LP
		if cam then
			if snap.FOV then cam.FieldOfView = snap.FOV end
			-- jangan biarkan subject loncat ke model furniture
			local hum = Util.Hum() or snap.Subject
			if hum and cam.CameraSubject ~= hum then
				cam.CameraSubject = hum
			end
			if snap.CamType and cam.CameraType ~= Enum.CameraType.Custom and cam.CameraType ~= Enum.CameraType.Scriptable then
				-- biarkan Custom; hanya perbaiki subject
			end
		end
		if LP then
			if snap.MinZ then LP.CameraMinZoomDistance = snap.MinZ end
			if snap.MaxZ then LP.CameraMaxZoomDistance = snap.MaxZ end
		end
	end)
end

local function GetSpamMarketItems(target, visited, homePos)
	local out = {}
	if not target or target == "" then return out end
	local targetLower = string.lower(target)
	local seen = {}

	local function consider(o)
		if not o or not o.Parent or seen[o] then return end
		seen[o] = true

		local nm = string.lower(o.Name)
		if nm ~= targetLower and not string.find(nm, targetLower, 1, true) then return end

		if IsBunkerItem(o) then return end

		-- Market Only: hanya Market / MarketWyposazenie / Magazine
		if State.MarketOnly and not IsInMarketOrGudang(o) then return end

		local cam = workspace:FindFirstChild("Camera") or workspace.CurrentCamera
		if cam and o:IsDescendantOf(cam) then return end

		local part = GetGrabPart(o)
		if not part then return end

		-- skip hasil drop di titik home (radius lebih besar anti-regrab)
		if homePos and (part.Position - homePos).Magnitude < 18 then return end

		-- visited by model ATAU posisi (anti bolak-balik instance baru)
		local pk = PosKey(part.Position)
		if visited then
			if visited[o] or visited[pk] then return end
		end

		table.insert(out, { model = o, part = part, posKey = pk })
	end

	if State.MarketOnly then
		-- sumber ketat: MarketWyposazenie + Magazine + Market
		local mw = Services.WS:FindFirstChild("MarketWyposazenie")
			or Services.WS:FindFirstChild("MarketWyposazenie", true)
		if mw then
			for _, c in ipairs(mw:GetChildren()) do
				if c:IsA("Model") or c:IsA("Tool") then consider(c) end
			end
		end
		local mag = Services.WS:FindFirstChild("Magazine")
		if mag then
			for _, c in ipairs(mag:GetDescendants()) do
				if c:IsA("Model") or c:IsA("Tool") then consider(c) end
			end
		end
		local market = Services.WS:FindFirstChild("Market")
		if market then
			for _, c in ipairs(market:GetDescendants()) do
				if c:IsA("Model") or c:IsA("Tool") then consider(c) end
			end
		end
	else
		for _, o in ipairs(ScanCache.Items or {}) do
			consider(o)
		end
		local wy = Services.WS:FindFirstChild("Wyposazenie")
		if wy then
			for _, child in ipairs(wy:GetChildren()) do
				local n = tostring(child.Name)
				if not (n:match("^%d+_Wyposazenie$") or n:match("^%d+_wyposazenie$")) then
					if child:IsA("Model") or child:IsA("Tool") then consider(child) end
					for _, desc in ipairs(child:GetChildren()) do
						if desc:IsA("Model") or desc:IsA("Tool") then consider(desc) end
					end
				end
			end
		end
		local mw = Services.WS:FindFirstChild("MarketWyposazenie")
			or Services.WS:FindFirstChild("MarketWyposazenie", true)
		if mw then
			for _, c in ipairs(mw:GetChildren()) do
				if c:IsA("Model") or c:IsA("Tool") then consider(c) end
			end
		end
	end

	if homePos then
		table.sort(out, function(a, b)
			return (a.part.Position - homePos).Magnitude > (b.part.Position - homePos).Magnitude
		end)
	end
	return out
end

-- coba pickup satu item dengan semua metode yang diketahui
local function TryPickup(model)
	if not model or not model.Parent then return end
	-- TIDAK TP di sini (TP sekali di loop spam) — hindari getar/lompat

	-- 1) remote dulu (sama seperti TPGrabReturn / Ambil terdekat)
	pcall(function()
		local ev = Services.Rep:FindFirstChild("PickupItemEvent")
			or Services.Rep:FindFirstChild("PickupItemEvent", true)
		if ev then ev:FireServer(model) end
	end)

	-- 2) ProximityPrompt 1x
	local prompt = GetPromptFromGrab(model)
	if not prompt then
		pcall(function()
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("ProximityPrompt") then prompt = d; break end
			end
		end)
	end
	if prompt then
		pcall(function()
			if fireproximityprompt then
				fireproximityprompt(prompt, prompt.MaxActivationDistance or 12)
			else
				local hold = math.min(tonumber(prompt.HoldDuration) or 0.4, 0.6)
				prompt:InputHoldBegin()
				task.wait(hold + 0.05)
				prompt:InputHoldEnd()
			end
		end)
	end

	-- 3) Z sekali (desktop)
	PressZ()
end

function Game.EnableSpamItem()
	if State.SpamItemOn then return end

	local targets = GetSpamMarkList()
	if #targets == 0 then
		local one = (State.ItemName and State.ItemName ~= "") and State.ItemName or State.AutoFarmItem
		if one and one ~= "" then targets = { one } end
	end
	if #targets == 0 then
		Notify("Spam Item", "Tandai item di list (★) atau pilih 1 item dulu!", Config.Theme.Red)
		return
	end

	local hrp0 = Util.Root()
	if not hrp0 then
		Notify("Spam Item", "Character Not Ready", Config.Theme.Red)
		return
	end

	State.SpamItemOn = true
	local homeCF = hrp0.CFrame
	local homePos = homeCF.Position
	local modeTxt = State.MarketOnly and " [Market Only]" or ""
	local markTxt = (#targets > 1) and (" x" .. #targets) or (" " .. targets[1])
	Notify("Spam Item", "Mulai:" .. markTxt .. modeTxt, Config.Theme.Accent)

	local gen = _G.SRF_GEN
	local visited = {}
	local emptyRounds = 0
	local ti = 1
	local camSnap = CaptureCamZoom()

	task.spawn(function()
		while State.SpamItemOn and gen == _G.SRF_GEN do
			local hrp = Util.Root()
			if not hrp then
				task.wait(0.35)
			else
				-- lepas dulu kalau masih bawa
				if IsHoldingFurniture() then
					local dcf = NextDropCF(homeCF)
					hrp.CFrame = dcf
					task.wait(0.15)
					DoDropFurniture(dcf)
					pcall(function()
						local cam = workspace.CurrentCamera
						local hum = Util.Hum()
						if cam and hum then cam.CameraSubject = hum end
						if camSnap and camSnap.FOV and cam then cam.FieldOfView = camSnap.FOV end
					end)
					task.wait(0.2)
				end

				local live = GetSpamMarkList()
				if #live > 0 then
					targets = live
					if ti > #targets then ti = 1 end
				end

				local target = targets[ti]
				local items = GetSpamMarketItems(target, visited, homePos)

				if #items == 0 then
					ti = ti + 1
					if ti > #targets then
						ti = 1
						emptyRounds = emptyRounds + 1
						if emptyRounds >= 2 then
							visited = {}
							emptyRounds = 0
						end
						task.wait(0.55)
					else
						task.wait(0.12)
					end
				else
					emptyRounds = 0
					for _, it in ipairs(items) do
						if not State.SpamItemOn or gen ~= _G.SRF_GEN then break end
						if not it.model.Parent or not it.part.Parent then
							visited[it.model] = true
							if it.posKey then visited[it.posKey] = true end
						else
							hrp = Util.Root()
							if not hrp then break end

							if IsHoldingFurniture() then
								local dcf = NextDropCF(homeCF)
								hrp.CFrame = dcf
								task.wait(0.12)
								DoDropFurniture(dcf)
								task.wait(0.18)
							end

							-- SATU TP stabil (bukan CFrame berulang) — anti getar
							local part = it.part
							if not part or not part.Parent then
								visited[it.model] = true
								if it.posKey then visited[it.posKey] = true end
							else
								hrp.CFrame = part.CFrame * CFrame.new(0, 3, 0)
								task.wait(0.25)

								TryPickup(it.model)

								local held = false
								for attempt = 1, 12 do
									if not State.SpamItemOn or gen ~= _G.SRF_GEN then break end
									if IsHoldingFurniture() then
										held = true
										break
									end
									if attempt == 4 or attempt == 8 then
										-- retry pickup TANPA TP ulang
										TryPickup(it.model)
									end
									task.wait(0.12)
								end

								if held then
									visited[it.model] = true
									if it.posKey then visited[it.posKey] = true end

									hrp = Util.Root()
									if hrp then
										local dropCF = NextDropCF(homeCF)
										local dropPos = dropCF.Position
										hrp.CFrame = dropCF
										task.wait(0.2)
										DoDropFurniture(dropCF)
										-- kembalikan kamera (anti zoom) — jangan kunci min/max zoom
										pcall(function()
											local cam = workspace.CurrentCamera
											local hum = Util.Hum()
											if cam and hum then cam.CameraSubject = hum end
											if camSnap and camSnap.FOV and cam then
												cam.FieldOfView = camSnap.FOV
											end
										end)
										task.wait(0.18)
										if IsHoldingFurniture() then
											DoDropFurniture(dropCF)
											task.wait(0.12)
										end
										visited[PosKey(dropPos)] = true
									end
								else
									visited[it.model] = true
									if it.posKey then visited[it.posKey] = true end
									task.wait(0.08)
								end
							end
						end
					end
				end
			end
		end
	end)
end

function Game.DisableSpamItem()
	State.SpamItemOn = false
	pcall(function()
		local LP = Services.LP
		if LP then
			LP.CameraMinZoomDistance = 0.5
			LP.CameraMaxZoomDistance = 128
		end
		local cam = workspace.CurrentCamera
		local hum = Util.Hum()
		if cam and hum then cam.CameraSubject = hum end
	end)
	pcall(function()
		if IsHoldingFurniture() then
			local hrp = Util.Root()
			DoDropFurniture(hrp and hrp.CFrame or nil)
		end
	end)
	pcall(function()
		local hum = Util.Hum()
		if hum then
			hum.PlatformStand = false
			hum.Sit = false
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
		end
	end)
	Notify("Spam Item", "STOP — spam dihentikan", Config.Theme.Sub)
end

function Game.ToggleSpamItem()
	if State.SpamItemOn then Game.DisableSpamItem() else Game.EnableSpamItem() end
end

-- Sound Spam: spam SoundEvent "Drink"/"Eat" (persis script asli)
-- ANTI-LAG (c): throttle 0.25 dtk + cache remote — bukan FireServer tiap frame tanpa batas.
function Game.EnableSoundSpam()
	State.SoundSpam = true
	task.spawn(function()
		local ev = Services.Rep:FindFirstChild("SoundEvent")
		while State.SoundSpam do
			if ev and ev.Parent then
				pcall(function() ev:FireServer("Drink") end)
				pcall(function() ev:FireServer("Eat") end)
			else
				ev = Services.Rep:FindFirstChild("SoundEvent")
			end
			task.wait(0.25)
		end
	end)
	Notify("YOURSCRIPT", "Sound Spam Enabled", Config.Theme.Green)
end

function Game.DisableSoundSpam()
	State.SoundSpam = false
	Notify("YOURSCRIPT", "Sound Spam Disabled", Config.Theme.Sub)
end

function Game.ToggleSoundSpam()
	if State.SoundSpam then Game.DisableSoundSpam() else Game.EnableSoundSpam() end
end

-- WalkSpeed langsung (box) — dari script asli
function Game.SetWalkSpeedDirect(v)
	v = tonumber(v)
	if not v then return end
	local hum = Util.Hum()
	if hum then hum.WalkSpeed = v end
end

----------------------------------------------------------------
-- GRIEF MODULE — ngerusuhin server
----------------------------------------------------------------
local Grief = {}

function Grief.ToggleExplosion()
	State.GriefExplosion = not State.GriefExplosion
	if State.GriefExplosion then
		Util.Connect("GriefExp", Services.RS.Heartbeat, function()
			if not State.GriefExplosion then return end
			State._expAcc = (State._expAcc or 0) + 1
			if State._expAcc < 30 then return end
			State._expAcc = 0
			for _, p in ipairs(Util.GetPlayers()) do
				if p ~= LP then
					local r = Util.Root(p)
					if r then
						local exp = Instance.new("Explosion")
						exp.Position = r.Position + Vector3.new(math.random(-4,4), 2, math.random(-4,4))
						exp.BlastRadius = 6
						exp.BlastPressure = 500000
						exp.DestroyJointRadiusPercent = 0
						exp.ExplosionType = Enum.ExplosionType.NoCraters
						exp.Parent = Services.WS
					end
				end
			end
		end)
		Notify("YOURSCRIPT", "Explosion Spam ON", Config.Theme.Red)
	else
		Util.Disconnect("GriefExp")
		Notify("YOURSCRIPT", "Explosion Spam OFF", Config.Theme.Sub)
	end
end

function Grief.ToggleParticle()
	State.GriefParticle = not State.GriefParticle
	if State.GriefParticle then
		Util.Connect("GriefParticle", Services.RS.Heartbeat, function()
			if not State.GriefParticle then return end
			local acc = (State._particleAcc or 0) + 1
			State._particleAcc = acc
			if acc < 10 then return end
			State._particleAcc = 0
			local ws = Util.GetWS()
			local n = 0
			for _, obj in ipairs(ws) do
				if n >= 40 then break end
				if obj:IsA("BasePart") and not obj:FindFirstChild("YOURSCRIPT_Grain") then
					local p = Instance.new("ParticleEmitter")
					p.Name = "YOURSCRIPT_Grain"
					p.Texture = "rbxassetid://248625108"
					p.Color = ColorSequence.new(Color3.fromRGB(255,0,0), Color3.fromRGB(255,255,0))
					p.LightEmission = 1
					p.Size = NumberSequence.new(1.5)
					p.Rate = 100
					p.Lifetime = NumberRange.new(2)
					p.Speed = NumberRange.new(10)
					p.Parent = obj
					n = n + 1
				end
			end
		end)
		Notify("YOURSCRIPT", "Particle Spam ON", Config.Theme.Red)
	else
		Util.Disconnect("GriefParticle")
		State._particleAcc = 0
		for _, obj in ipairs(Util.GetWS()) do
			local p = obj:FindFirstChild("YOURSCRIPT_Grain")
			if p then p:Destroy() end
		end
		Notify("YOURSCRIPT", "Particle Spam OFF", Config.Theme.Sub)
	end
end

function Grief.ToggleDecal()
	State.GriefDecal = not State.GriefDecal
	if State.GriefDecal then
		Util.Connect("GriefDecal", Services.RS.Heartbeat, function()
			if not State.GriefDecal then return end
			local acc = (State._decalAcc or 0) + 1
			State._decalAcc = acc
			if acc < 10 then return end
			State._decalAcc = 0
			local ws = Util.GetWS()
			local n = 0
			for _, obj in ipairs(ws) do
				if n >= 40 then break end
				if obj:IsA("BasePart") and not obj:FindFirstChild("YOURSCRIPT_Decals") then
					for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
						local d = Instance.new("Decal")
						d.Name = "YOURSCRIPT_Decals"
						d.Texture = "rbxassetid://483446277"
						d.Face = face
						d.Transparency = math.random(0, 50) / 100
						d.Parent = obj
					end
					n = n + 1
				end
			end
		end)
		Notify("YOURSCRIPT", "Decal Spam ON", Config.Theme.Red)
	else
		Util.Disconnect("GriefDecal")
		State._decalAcc = 0
		for _, obj in ipairs(Util.GetWS()) do
			for _, d in ipairs(obj:GetChildren()) do
				if d.Name == "YOURSCRIPT_Decals" then pcall(function() d:Destroy() end) end
			end
		end
		Notify("YOURSCRIPT", "Decal Spam OFF", Config.Theme.Sub)
	end
end

function Grief.ToggleChat()
	State.GriefChat = not State.GriefChat
	if State.GriefChat then
		Util.Connect("GriefChat", Services.RS.Heartbeat, function()
			if not State.GriefChat then return end
			local acc = (State._chatAcc or 0) + 1
			State._chatAcc = acc
			if acc < 30 then return end
			State._chatAcc = 0
			local msgs = {
				"anjing", "tolol", "goblok", "bego",
				"NGAPA KAMU Main??", "YOURSCRIPT WAS HERE", "HAHAHA",
			}
			local msg = msgs[math.random(1, #msgs)]
			Util.Safe(function()
				local rep = Services.Rep:FindFirstChild("DefaultChat")
				if rep and rep:FindFirstChild("SayMessageRequest") then
					rep.SayMessageRequest:FireServer(msg, "All")
				elseif Services.Players:FindFirstChild("LocalPlayer") then
					pcall(function() Services.Players.LocalPlayer:SendNotification(msg) end)
				end
			end)
		end)
		Notify("YOURSCRIPT", "Chat Spam ON", Config.Theme.Red)
	else
		Util.Disconnect("GriefChat")
		State._chatAcc = 0
		Notify("YOURSCRIPT", "Chat Spam OFF", Config.Theme.Sub)
	end
	end

-- ================= SIMPLE FARM PATCH =================
local PickupEvent = Services.Rep:FindFirstChild("PickupItemEvent")

local function InArea(obj, kws)          -- true kalau ada ancestor bernama sesuai keyword
	local a = obj
	while a and a ~= Services.WS do
		local n = string.lower(tostring(a.Name))
		for _, kw in ipairs(kws) do
			if n:find(kw, 1, true) then return true end
		end
		a = a.Parent
	end
	return false
end

local MARKET_KWS = {"mart", "six", "minimarket", "toko", "store", "market", "sklep", "sklepy", "shops"}
local BUNKER_KWS = {"bunker", "shelter", "base", "home", "dom"}

local function GetPart(o)
	return o:IsA("BasePart") and o
		or (o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildOfClass("BasePart")))
end

-- AMBIL TERDEKAT (v2 — TP -> prompt -> balik, versi mandiri patch sederhana)
-- Konsisten dengan Farming.GrabNearest: pakai cache ScanCache.Items, tanpa scan workspace saat klik.
local function GrabNearest2()
	-- Langsung ke Farming.GrabNearest (tanpa TP, tanpa freeze)
	pcall(function()
		if Farming and Farming.GrabNearest then
			Farming.GrabNearest()
		end
	end)
end

-- expose biar UI bisa panggil
_G.SRF_GrabNearest  = GrabNearest2
-- =====================================================
-- TP → ambil → balik, SEKALI PENCET (pakai item dari pilihan < > di UI)
function Farming.TPGrabReturn()
	local r = Util.Root()
	if not r then Notify("YOURSCRIPT", "Character Not Ready", Color3.fromRGB(255,160,50)) return end

	-- item target = dari pilihan < > di UI (State.ItemName), fallback ke textbox
	local target = State.ItemName or State.AutoFarmItem
	if not target or target == "" then
		Notify("YOURSCRIPT", "Pilih item dulu (< >) atau ketik nama", Color3.fromRGB(255,160,50))
		return
	end

	-- ANTI-LAG: cari dari cache + Wyposazenie (bukan GetDescendants penuh)
	local best, bestDist = nil, math.huge
	local done = {}
	local targetLower = target:lower()
	local function considerTP(o)
		if not o or done[o] or not o.Parent then return end
		if not (o:IsA("Model") or o:IsA("Tool")) then return end
		if Services.Players:GetPlayerFromCharacter(o) then return end
		if o:FindFirstChildOfClass("Humanoid") then return end
		if not string.find(o.Name:lower(), targetLower, 1, true) then return end
		if InArea and InArea(o, BUNKER_KWS) then return end
		done[o] = true
		local p = GetPart(o)
		if p then
			local d = (p.Position - r.Position).Magnitude
			if d < bestDist then best, bestDist = o, d end
		end
	end
	for _, o in ipairs(ScanCache and ScanCache.Items or {}) do considerTP(o) end
	local wy = Services.WS:FindFirstChild("Wyposazenie")
	if wy then
		for _, c in ipairs(wy:GetChildren()) do
			considerTP(c)
			if c:IsA("Folder") or c:IsA("Model") then
				for _, g in ipairs(c:GetChildren()) do considerTP(g) end
			end
		end
	end
	for _, o in ipairs(Services.WS:GetChildren()) do considerTP(o) end

	if not best then
		Notify("YOURSCRIPT", "Item tidak ditemukan: " .. target, Color3.fromRGB(255,160,50))
		return
	end

	local part = GetPart(best)
	if not part then return end

	-- 1) simpan posisi awal
	local startPos = r.CFrame

	-- 2) teleport ke item
	r.CFrame = part.CFrame * CFrame.new(0, 3, 0)
	task.wait(0.2)

	-- 3) ambil: remote + prompt + clickdetector
	local grabbed = false
	if PickupEvent then
		pcall(function() PickupEvent:FireServer(best) end)
	end
	local pp = best:FindFirstChildOfClass("ProximityPrompt", true)
		or (part and part:FindFirstChildOfClass("ProximityPrompt"))
	if pp then
		if fireproximityprompt then
			pcall(fireproximityprompt, pp, pp.MaxActivationDistance)
		else
			pcall(function()
				pp:InputHoldBegin()
				task.wait(pp.HoldDuration + 0.05)
				pp:InputHoldEnd()
			end)
		end
		grabbed = true
	end
	local cd = best:FindFirstChildOfClass("ClickDetector", true)
		or (part and part:FindFirstChildOfClass("ClickDetector"))
	if cd and fireclickdetector then
		pcall(fireclickdetector, cd, 0)
		grabbed = true
	end

	-- 4) tunggu sebentar, lalu BALIK ke titik awal
	task.wait(0.35)
	local r2 = Util.Root()
	if r2 then r2.CFrame = startPos end

	if grabbed or PickupEvent then
		Notify("YOURSCRIPT", string.format("✓ %s (%.0fm) → balik ke posisi", best.Name, bestDist), Color3.fromRGB(46,200,110))
	else
		Notify("YOURSCRIPT", "Metode pickup tidak tersedia", Color3.fromRGB(255,160,50))
	end
end

-- RAID SEMUA item market sekaligus (TP berputar, KECUALI bunker), lalu pulang — SEKALI PENCET
function Farming.RaidAllMarketReturn()
	local r = Util.Root()
	if not r then return end
	local startPos = r.CFrame
	local n = 0
	local done = {}
	for _, o in ipairs(Services.WS:GetDescendants()) do
		if (o:IsA("Model") or o:IsA("Tool")) and not done[o]
			and not Services.Players:GetPlayerFromCharacter(o)
			and not o:FindFirstChildOfClass("Humanoid")
			and InArea(o, MARKET_KWS) and not InArea(o, BUNKER_KWS) then
			local p = GetPart(o)
			if p then
				r.CFrame = p.CFrame * CFrame.new(0, 3, 0)
				task.wait(0.15)
				if PickupEvent then pcall(function() PickupEvent:FireServer(o) end) end
				local pp = o:FindFirstChildOfClass("ProximityPrompt", true)
				if pp then
					if fireproximityprompt then pcall(fireproximityprompt, pp, pp.MaxActivationDistance)
					else pcall(function() pp:InputHoldBegin() task.wait(pp.HoldDuration + 0.05) pp:InputHoldEnd() end) end
				end
				local cd = o:FindFirstChildOfClass("ClickDetector", true)
				if cd and fireclickdetector then pcall(fireclickdetector, cd, 0) end
				n = n + 1
				done[o] = true
			end
		end
	end
	task.wait(0.3)
	r.CFrame = startPos
	Notify("YOURSCRIPT", "Raid market selesai: " .. n .. " item, kembali", Color3.fromRGB(46,200,110))
end


----------------------------------------------------------------
-- EXTRA + COMBAT + LOADERS + MAGNETIZE + 8 NEW FEATURES
----------------------------------------------------------------
local Extra = {}
local _xrayCache, _floatPart, _wpIdx = {}, nil, 1
local _hitboxOrig, _reachOrig = {}, {}
local _orbitAng = 0
local _magAttach = nil
local _spinFlingConn, _hiddenFlingFlag = nil, false
local _npcHighlight, _origCharName = nil, nil
local ATTACH_OFF = {
	backpack = CFrame.new(0, 0.2, 1.1) * CFrame.Angles(0, math.pi, 0),
	bang = CFrame.new(0, 0.5, 1.2) * CFrame.Angles(math.rad(-10), math.pi, 0),
	facebang = CFrame.new(0, 1.6, 0.9) * CFrame.Angles(math.rad(80), math.pi, 0),
	headsit = CFrame.new(0, 2.2, 0),
	shouldersit = CFrame.new(1.1, 1.4, 0) * CFrame.Angles(0, math.rad(-90), 0),
	carpet = CFrame.new(0, -2.2, 0) * CFrame.Angles(math.rad(90), 0, 0),
}
local WORD_DICT = {"apel","lampu","ular","rumah","hutan","naga","awan","nasi","ikan","nangka","api","ikan","nama","air","roti","ikan","nanas","sapi","ibu","udang","gajah","hutan","nuri","ibu","uang","gigi","ikan"}

function Extra.SetFlySpeed(v) State.FlySpeedVal = math.clamp(tonumber(v) or 80, 10, 500); Config.Movement.FlySpeed = State.FlySpeedVal; Notify("FlySpeed", tostring(State.FlySpeedVal), Config.Theme.Accent) end
function Extra.SetJumpPower(v) local h=Util.Hum(); if h then pcall(function() h.UseJumpPower=true; h.JumpPower=tonumber(v)or 50; h.JumpHeight=(tonumber(v)or 50)/7.5 end) end; Notify("Jump", tostring(v), Config.Theme.Accent) end
function Extra.SetGravity(v) v=tonumber(v); if v then State.BaseGravity=v; Services.WS.Gravity=v; Notify("Gravity", tostring(v), Config.Theme.Accent) end end
function Extra.EnableNoGravity() State.NoGravityOn=true; pcall(function() State.BaseGravity=Services.WS.Gravity end); Services.WS.Gravity=0; Util.Connect("NoGrav", Services.RS.Heartbeat, function() if State.NoGravityOn then Services.WS.Gravity=0 end end); Notify("Gravity","0",Config.Theme.Green) end
function Extra.DisableNoGravity() State.NoGravityOn=false; Util.Disconnect("NoGrav"); Services.WS.Gravity=State.BaseGravity or 196.2; Notify("Gravity","reset",Config.Theme.Sub) end
function Extra.EnableFloat()
	State.FloatOn=true; local root=Util.Root(); if not root then return end
	pcall(function() if _floatPart then _floatPart:Destroy() end end)
	local p=Instance.new("Part"); p.Name="SRF_FloatPlat"; p.Size=Vector3.new(6,0.4,6); p.Anchored=true; p.CanCollide=true; p.Transparency=0.55; p.Material=Enum.Material.ForceField; p.Color=Color3.fromRGB(0,210,255); p.CFrame=root.CFrame*CFrame.new(0,-3.2,0); p.Parent=Services.WS; _floatPart=p
	Util.Connect("Float", Services.RS.Heartbeat, function()
		if not State.FloatOn or not _floatPart then return end; local r=Util.Root(); if not r then return end
		local off=0; if Services.UIS:IsKeyDown(Enum.KeyCode.E) or State.FlyUp then off=0.35 end; if Services.UIS:IsKeyDown(Enum.KeyCode.Q) or State.FlyDown then off=-0.35 end
		_floatPart.CFrame=CFrame.new(r.Position.X, _floatPart.Position.Y+off, r.Position.Z)
	end); Notify("Float","ON",Config.Theme.Green)
end
function Extra.DisableFloat() State.FloatOn=false; Util.Disconnect("Float"); pcall(function() if _floatPart then _floatPart:Destroy() end end); _floatPart=nil; Notify("Float","OFF",Config.Theme.Sub) end
function Extra.EnableSpin() State.SpinOn=true; Util.Connect("Spin", Services.RS.Heartbeat, function(dt) if not State.SpinOn then return end; local r=Util.Root(); if r then r.CFrame=r.CFrame*CFrame.Angles(0,math.rad((State.SpinSpeed or 12)*60*dt),0) end end); Notify("Spin","ON",Config.Theme.Green) end
function Extra.DisableSpin() State.SpinOn=false; Util.Disconnect("Spin"); Notify("Spin","OFF",Config.Theme.Sub) end
function Extra.SelfFling() local r=Util.Root(); if not r then return end; local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Velocity=Vector3.new(math.random(-250,250),300,math.random(-250,250)); bv.Parent=r; task.delay(0.35,function() pcall(function() bv:Destroy() end) end); Notify("Fling","!",Config.Theme.Orange) end
function Extra.EnableAntiFling() State.AntiFlingOn=true; Util.Connect("AntiFling", Services.RS.Stepped, function() if not State.AntiFlingOn then return end; for _,plr in ipairs(Util.GetPlayers()) do local c=plr.Character; if c then for _,bp in ipairs(c:GetDescendants()) do if bp:IsA("BasePart") then bp.CanCollide=false end end end end end); Notify("AntiFling","ON",Config.Theme.Green) end
function Extra.DisableAntiFling() State.AntiFlingOn=false; Util.Disconnect("AntiFling"); Notify("AntiFling","OFF",Config.Theme.Sub) end
function Extra.EnableXray() State.XrayOn=true; _xrayCache={}; local my=Util.Char(); for _,o in ipairs(Services.WS:GetDescendants()) do if o:IsA("BasePart") and (not my or not o:IsDescendantOf(my)) then local owner=Services.Players:GetPlayerFromCharacter(o.Parent); if not owner then _xrayCache[o]=o.LocalTransparencyModifier; o.LocalTransparencyModifier=0.65 end end end; Notify("Xray","ON",Config.Theme.Green) end
function Extra.DisableXray() State.XrayOn=false; for o,t in pairs(_xrayCache) do pcall(function() o.LocalTransparencyModifier=t end) end; _xrayCache={}; Notify("Xray","OFF",Config.Theme.Sub) end
function Extra.EnableInvisible() State.InvisibleOn=true; local c=Util.Char(); if not c then return end; for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") or d:IsA("Decal") then d.Transparency=1 elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled=false end end; Notify("Invisible","ON",Config.Theme.Green) end
function Extra.DisableInvisible() State.InvisibleOn=false; local c=Util.Char(); if not c then return end; for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") and d.Name~="HumanoidRootPart" then d.Transparency=0 elseif d.Name=="HumanoidRootPart" then d.Transparency=1 elseif d:IsA("Decal") then d.Transparency=0 elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled=true end end; Notify("Invisible","OFF",Config.Theme.Sub) end
function Extra.EnableStalk() State.StalkOn=true; Util.Connect("Stalk", Services.RS.Heartbeat, function() if not State.StalkOn then return end; State._stAcc=(State._stAcc or 0)+0.016; if State._stAcc<0.05 then return end; State._stAcc=0; local tr=(State.TargetPlayer or State.Target) and Util.Root(State.TargetPlayer or State.Target); local r=Util.Root(); if r and tr then r.CFrame=tr.CFrame*CFrame.new(0,0,3) end end); Notify("Stalk","ON",Config.Theme.Orange) end
function Extra.DisableStalk() State.StalkOn=false; Util.Disconnect("Stalk"); Notify("Stalk","OFF",Config.Theme.Sub) end
function Extra.EnableStare() State.StareOn=true; Util.Connect("Stare", Services.RS.Heartbeat, function() if not State.StareOn then return end; State._srAcc=(State._srAcc or 0)+0.016; if State._srAcc<0.05 then return end; State._srAcc=0; local tr=(State.TargetPlayer or State.Target) and Util.Root(State.TargetPlayer or State.Target); local r=Util.Root(); if r and tr then local p=r.Position; r.CFrame=CFrame.lookAt(p, Vector3.new(tr.Position.X,p.Y,tr.Position.Z)) end end); Notify("Stare","ON",Config.Theme.Orange) end
function Extra.DisableStare() State.StareOn=false; Util.Disconnect("Stare"); Notify("Stare","OFF",Config.Theme.Sub) end
function Extra.GrabTools()
	-- Ambil tool via remote + prompt (bukan cuma Parent) supaya server acknowledge
	local n = 0
	local ev = Services.Rep:FindFirstChild("PickupItemEvent") or Services.Rep:FindFirstChild("PickupItemEvent", true)
	local candidates = {}
	local function consider(o)
		if not o or not o.Parent then return end
		if not o:IsA("Tool") then return end
		if not o:FindFirstChild("Handle") then return end
		-- skip yang sudah di backpack / character
		if o:IsDescendantOf(LP) then return end
		local char = Util.Char()
		if char and o:IsDescendantOf(char) then return end
		table.insert(candidates, o)
	end
	-- Workspace root tools
	for _, o in ipairs(Services.WS:GetChildren()) do consider(o) end
	-- Wyposazenie children (1 level)
	local wy = Services.WS:FindFirstChild("Wyposazenie")
	if wy then
		for _, c in ipairs(wy:GetChildren()) do
			consider(c)
			if c:IsA("Folder") or c:IsA("Model") then
				for _, g in ipairs(c:GetChildren()) do consider(g) end
			end
		end
	end
	-- cache
	for _, o in ipairs(ScanCache and ScanCache.Items or {}) do consider(o) end
	for _, tool in ipairs(candidates) do
		local handle = tool:FindFirstChild("Handle")
		-- 1) remote server
		if ev then pcall(function() ev:FireServer(tool) end) end
		-- 2) proximity / click
		local pp = tool:FindFirstChildOfClass("ProximityPrompt") or (handle and handle:FindFirstChildOfClass("ProximityPrompt"))
		if pp then
			if fireproximityprompt then
				pcall(fireproximityprompt, pp, pp.MaxActivationDistance or 12)
			else
				pcall(function()
					pp:InputHoldBegin()
					task.wait(math.min(pp.HoldDuration or 0.2, 0.35))
					pp:InputHoldEnd()
				end)
			end
		end
		local cd = tool:FindFirstChildOfClass("ClickDetector") or (handle and handle:FindFirstChildOfClass("ClickDetector"))
		if cd and fireclickdetector then pcall(fireclickdetector, cd, 0) end
		-- 3) fallback client parent (setelah remote)
		pcall(function()
			if tool.Parent and not tool:IsDescendantOf(LP) then
				tool.Parent = LP.Backpack
			end
		end)
		n = n + 1
	end
	Notify("Tools", "Grab " .. n, Config.Theme.Green)
end

function Extra.DropTools()
	-- Drop tool DI DEPAN AVA (bukan balik ke posisi semula)
	local root = Util.Root()
	if not root then
		Notify("Tools", "Character Not Ready", Config.Theme.Orange)
		return
	end
	local dropCF = root.CFrame * CFrame.new(0, 0, -3) -- 3 stud di depan
	local destParent = Services.WS:FindFirstChild("Wyposazenie") or Services.WS
	local dropEv = Services.Rep:FindFirstChild("DropItemEvent") or Services.Rep:FindFirstChild("DropItemEvent", true)
	local n = 0
	local bags = {}
	if LP.Backpack then table.insert(bags, LP.Backpack) end
	local char = Util.Char()
	if char then table.insert(bags, char) end
	-- unequip dulu biar tidak nempel di tangan
	local hum = Util.Hum()
	if hum then pcall(function() hum:UnequipTools() end) end
	task.wait(0.05)
	for _, bag in ipairs(bags) do
		for _, t in ipairs(bag:GetChildren()) do
			if t:IsA("Tool") then
				pcall(function()
					-- server drop
					if dropEv then dropEv:FireServer(t) end
					local handle = t:FindFirstChild("Handle") or t:FindFirstChildOfClass("BasePart")
					-- posisikan dulu di depan ava
					if handle then
						handle.CFrame = dropCF
						handle.AssemblyLinearVelocity = Vector3.zero
						handle.AssemblyAngularVelocity = Vector3.zero
					end
					if t.PivotTo then
						t:PivotTo(dropCF)
					end
					-- putus weld ke character
					for _, w in ipairs(t:GetDescendants()) do
						if w:IsA("Weld") or w:IsA("WeldConstraint") or w:IsA("ManualWeld") then
							pcall(function() w:Destroy() end)
						end
					end
					t.Parent = destParent
					-- set ulang CFrame setelah parent (anti snap balik)
					if handle then
						handle.CFrame = dropCF
						handle.Anchored = false
					end
					if t.PivotTo then t:PivotTo(dropCF) end
				end)
				n = n + 1
			end
		end
	end
	Notify("Tools", "Drop " .. n .. " di depan Ava", Config.Theme.Orange)
end

function Extra.EquipAllTools()
	local char = Util.Char()
	local hum = Util.Hum()
	if not char or not hum then return end
	for _, t in ipairs(LP.Backpack:GetChildren()) do
		if t:IsA("Tool") then
			pcall(function()
				-- EquipTool lebih stabil daripada Parent=char
				hum:EquipTool(t)
			end)
			task.wait(0.05)
		end
	end
	Notify("Tools", "Equip All", Config.Theme.Green)
end
function Extra.FireAllPrompts() local n=0; for _,o in ipairs(Services.WS:GetDescendants()) do if o:IsA("ProximityPrompt") then n=n+1; if fireproximityprompt then pcall(fireproximityprompt,o) else pcall(function() o:InputHoldBegin(); task.wait((o.HoldDuration or 0)+0.05); o:InputHoldEnd() end) end end end; Notify("Prompt",tostring(n),Config.Theme.Green) end
function Extra.FireAllClickDetectors() local n=0; for _,o in ipairs(Services.WS:GetDescendants()) do if o:IsA("ClickDetector") then n=n+1; if fireclickdetector then pcall(fireclickdetector,o) end end end; Notify("Click",tostring(n),Config.Theme.Green) end
function Extra.EnableInstantPrompt() State.InstantPromptOn=true; Util.Connect("InstPrompt", Services.WS.DescendantAdded, function(o) if o:IsA("ProximityPrompt") then pcall(function() o.HoldDuration=0 end) end end); for _,o in ipairs(Services.WS:GetDescendants()) do if o:IsA("ProximityPrompt") then pcall(function() o.HoldDuration=0 end) end end; Notify("Prompt","Instant",Config.Theme.Green) end
function Extra.DisableInstantPrompt() State.InstantPromptOn=false; Util.Disconnect("InstPrompt"); Notify("Prompt","OFF",Config.Theme.Sub) end
function Extra.SaveWaypoint() local r=Util.Root(); if not r then return end; table.insert(State.Waypoints,{name="WP"..(#State.Waypoints+1),cf=r.CFrame}); _wpIdx=#State.Waypoints; Notify("WP","#".._wpIdx,Config.Theme.Accent) end
function Extra.TPWaypoint() if #State.Waypoints==0 then Notify("WP","kosong",Config.Theme.Orange); return end; if _wpIdx<1 or _wpIdx>#State.Waypoints then _wpIdx=1 end; local r=Util.Root(); if r then r.CFrame=State.Waypoints[_wpIdx].cf end end
function Extra.NextWaypoint() if #State.Waypoints==0 then return end; _wpIdx=_wpIdx+1; if _wpIdx>#State.Waypoints then _wpIdx=1 end; Extra.TPWaypoint() end
function Extra.PrevWaypoint() if #State.Waypoints==0 then return end; _wpIdx=_wpIdx-1; if _wpIdx<1 then _wpIdx=#State.Waypoints end; Extra.TPWaypoint() end
function Extra.ClearWaypoints() State.Waypoints={}; _wpIdx=1; Notify("WP","cleared",Config.Theme.Sub) end
function Extra.CopyCoords() local r=Util.Root(); if not r then return end; local p=r.Position; local s=string.format("%.1f, %.1f, %.1f",p.X,p.Y,p.Z); pcall(function() if toclipboard then toclipboard(s) elseif setclipboard then setclipboard(s) end end); Notify("Coords",s,Config.Theme.Accent) end
function Extra.CopyPlayerId() local t=State.TargetPlayer or State.Target; if not t then Notify("Copy","no target",Config.Theme.Orange); return end; local s=tostring(t.UserId); pcall(function() if toclipboard then toclipboard(s) elseif setclipboard then setclipboard(s) end end); Notify("ID",t.DisplayName or t.Name,Config.Theme.Accent) end
function Extra.CopyPlayerName() local t=State.TargetPlayer or State.Target; if not t then Notify("Copy","no target",Config.Theme.Orange); return end; local nm=t.DisplayName or t.Name; pcall(function() if toclipboard then toclipboard(nm) elseif setclipboard then setclipboard(nm) end end); Notify("Name",nm,Config.Theme.Accent) end
function Extra.Platform() local r=Util.Root(); if not r then return end; local p=Instance.new("Part"); p.Name="SRF_Platform"; p.Size=Vector3.new(12,1,12); p.Anchored=true; p.CanCollide=true; p.Material=Enum.Material.SmoothPlastic; p.Color=Color3.fromRGB(40,50,70); p.CFrame=r.CFrame*CFrame.new(0,-3.5,0); p.Parent=Services.WS; Notify("Platform","ok",Config.Theme.Accent) end

function Extra.StartAttach(mode)
	mode=mode or State.AttachMode or "backpack"; State.AttachMode=mode; State.AttachOn=true
	local off=ATTACH_OFF[mode] or ATTACH_OFF.backpack
	Util.Connect("Attach", Services.RS.Heartbeat, function()
		if not State.AttachOn then return end
		local tgt=State.TargetPlayer or State.Target; local tr=tgt and Util.Root(tgt); local r=Util.Root(); local hum=Util.Hum()
		if not r or not tr then return end
		if hum then pcall(function() hum.Sit=true end) end
		r.CFrame=tr.CFrame*off; r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
	end); Notify("Attach", mode.." ON", Config.Theme.Orange)
end
function Extra.StopAttach() State.AttachOn=false; Util.Disconnect("Attach"); local hum=Util.Hum(); if hum then pcall(function() hum.Sit=false end) end; Notify("Attach","OFF",Config.Theme.Sub) end
function Extra.ToggleAttach(mode) if State.AttachOn and (not mode or mode==State.AttachMode) then Extra.StopAttach() else Extra.StartAttach(mode or State.AttachMode) end end

function Extra.EnableAimbot()
	State.AimbotOn=true
	Util.Connect("Aimbot", Services.RS.Heartbeat, function()
		if not State.AimbotOn then return end
		State._aimAcc=(State._aimAcc or 0)+0.016
		if State._aimAcc<0.04 then return end
		State._aimAcc=0
		local cam=Services.WS.CurrentCamera; if not cam then return end
		local best, bestDist=nil, State.AimbotFOV or 180
		local prefer=State.TargetPlayer or State.Target
		local function score(plr)
			local char=plr.Character; if not char then return end
			local part=char:FindFirstChild(State.AimbotPart or "Head") or char:FindFirstChild("HumanoidRootPart"); if not part then return end
			local hum=char:FindFirstChildOfClass("Humanoid"); if hum and hum.Health<=0 then return end
			local sp, onScreen=cam:WorldToViewportPoint(part.Position); if not onScreen then return end
			local mouse=Services.UIS:GetMouseLocation()
			local d=(Vector2.new(sp.X,sp.Y)-Vector2.new(mouse.X,mouse.Y)).Magnitude
			if d<bestDist then bestDist=d; best=part end
		end
		if prefer and prefer~=LP then score(prefer) end
		if not best then for _,p in ipairs(Util.GetPlayers()) do score(p) end end
		if best then local goal=CFrame.new(cam.CFrame.Position, best.Position); cam.CFrame=cam.CFrame:Lerp(goal, math.clamp(State.AimbotSmooth or 0.25, 0.05, 1)) end
	end); Notify("Aimbot","ON",Config.Theme.Green)
end
function Extra.DisableAimbot() State.AimbotOn=false; Util.Disconnect("Aimbot"); Notify("Aimbot","OFF",Config.Theme.Sub) end
function Extra.EnableHitbox()
	State.HitboxOn=true
	Util.Connect("Hitbox", Services.RS.Heartbeat, function()
		if not State.HitboxOn then return end
		State._hbAcc=(State._hbAcc or 0)+0.016
		if State._hbAcc<0.12 then return end
		State._hbAcc=0
		local sz=State.HitboxSize or 8
		for _,plr in ipairs(Util.GetPlayers()) do local r=Util.Root(plr); if r then if not _hitboxOrig[r] then _hitboxOrig[r]=r.Size end; r.Size=Vector3.new(sz,sz,sz); r.Transparency=0.7; r.CanCollide=false; r.Massless=true end end
	end); Notify("Hitbox","ON",Config.Theme.Green)
end
function Extra.DisableHitbox() State.HitboxOn=false; Util.Disconnect("Hitbox"); for r,s in pairs(_hitboxOrig) do pcall(function() r.Size=s; r.Transparency=1; r.Massless=false end) end; _hitboxOrig={}; Notify("Hitbox","OFF",Config.Theme.Sub) end
function Extra.EnableReach()
	State.ReachOn=true
	Util.Connect("Reach", Services.RS.Heartbeat, function()
		if not State.ReachOn then return end
		State._rchAcc=(State._rchAcc or 0)+0.016
		if State._rchAcc<0.15 then return end
		State._rchAcc=0
		local char=Util.Char(); if not char then return end
		for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") then local h=t:FindFirstChild("Handle"); if h and h:IsA("BasePart") then if not _reachOrig[h] then _reachOrig[h]=h.Size end; local s=State.ReachSize or 12; h.Size=Vector3.new(s,s,s); h.Massless=true end end end
	end); Notify("Reach","ON",Config.Theme.Green)
end
function Extra.DisableReach() State.ReachOn=false; Util.Disconnect("Reach"); for h,s in pairs(_reachOrig) do pcall(function() h.Size=s; h.Massless=false end) end; _reachOrig={}; Notify("Reach","OFF",Config.Theme.Sub) end
function Extra.EnableFakeLag()
	State.FakeLagOn=true; local last,hold=os.clock(),nil
	Util.Connect("FakeLag", Services.RS.Heartbeat, function()
		if not State.FakeLagOn then return end; local r=Util.Root(); if not r then return end
		local now=os.clock(); local ms=(State.FakeLagMs or 120)/1000
		if not hold then hold=r.CFrame end
		if now-last>=ms then hold=r.CFrame; last=now else r.CFrame=hold end
	end); Notify("FakeLag","ON",Config.Theme.Orange)
end
function Extra.DisableFakeLag() State.FakeLagOn=false; Util.Disconnect("FakeLag"); Notify("FakeLag","OFF",Config.Theme.Sub) end
function Extra.EnableClickFling()
	State.ClickFlingOn=true
	Util.Connect("ClickFling", Mouse.Button1Down, function()
		if not State.ClickFlingOn then return end
		local plr = nil
		local t = Mouse.Target
		if t then
			local model = t:FindFirstAncestorOfClass("Model")
			plr = model and Services.Players:GetPlayerFromCharacter(model)
		end
		if not plr or plr == LP then plr = State.TargetPlayer or State.Target end
		if not plr or plr == LP then return end
		local tr = Util.Root(plr)
		if not tr then return end
		local mult = (State.TouchFlingPower or 5)
		local power = 80 * mult
		pcall(function()
			tr.AssemblyLinearVelocity = Vector3.new((math.random()-0.5)*2*power, power*1.2, (math.random()-0.5)*2*power)
			tr.AssemblyAngularVelocity = Vector3.new(0, 40*mult, 0)
		end)
		local bv = Instance.new("BodyVelocity")
		bv.Name = "SRF_FlingThem"
		bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bv.Velocity = Vector3.new((math.random()-0.5)*2*power, power*1.2, (math.random()-0.5)*2*power)
		bv.Parent = tr
		local bav = Instance.new("BodyAngularVelocity")
		bav.Name = "SRF_FlingThemSpin"
		bav.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
		bav.AngularVelocity = Vector3.new(math.random(-20,20), 80*mult, math.random(-20,20))
		bav.Parent = tr
		task.delay(0.35, function()
			pcall(function() bv:Destroy() end)
			pcall(function() bav:Destroy() end)
		end)
		Notify("ClickFling", "→ "..(plr.DisplayName or plr.Name), Config.Theme.Red)
	end); Notify("ClickFling","ON (target)",Config.Theme.Orange)
end
function Extra.DisableClickFling() State.ClickFlingOn=false; Util.Disconnect("ClickFling"); Notify("ClickFling","OFF",Config.Theme.Sub) end
function Extra.EnableOrbit()
	State.OrbitOn=true; _orbitAng=0
	Util.Connect("Orbit", Services.RS.Heartbeat, function(dt)
		if not State.OrbitOn then return end
		local tgt=State.TargetPlayer or State.Target; local tr=tgt and Util.Root(tgt); local r=Util.Root(); if not r or not tr then return end
		_orbitAng=_orbitAng+(State.OrbitSpeed or 2)*dt
		local rad=State.OrbitRadius or 8
		local pos=tr.Position+Vector3.new(math.cos(_orbitAng)*rad, 2, math.sin(_orbitAng)*rad)
		r.CFrame=CFrame.lookAt(pos, tr.Position)
	end); Notify("Orbit","ON",Config.Theme.Orange)
end
function Extra.DisableOrbit() State.OrbitOn=false; Util.Disconnect("Orbit"); Notify("Orbit","OFF",Config.Theme.Sub) end
function Extra.EnableGodMode()
	State.GodModeOn=true
	Util.Connect("GodMode", Services.RS.Heartbeat, function()
		if not State.GodModeOn then return end
		State._gmAcc=(State._gmAcc or 0)+0.016
		if State._gmAcc<0.2 then return end
		State._gmAcc=0
		local hum=Util.Hum(); if hum then hum.Health=hum.MaxHealth end
	end); Notify("GodMode","ON",Config.Theme.Green)
end
function Extra.DisableGodMode() State.GodModeOn=false; Util.Disconnect("GodMode"); Notify("GodMode","OFF",Config.Theme.Sub) end

function Extra.FindPlayerByName(targetName)
	if not targetName or targetName == "" then return nil end
	local exactU, exactD, partU, partD = nil, nil, nil, nil
	local low = targetName:lower()
	for _, player in ipairs(Services.Players:GetPlayers()) do
		if player ~= LP then
			if player.Name == targetName then exactU = player
			elseif player.DisplayName == targetName then exactD = player
			elseif string.find(player.Name:lower(), low, 1, true) then partU = player
			elseif string.find(player.DisplayName:lower(), low, 1, true) then partD = player
			end
		end
	end
	return exactU or exactD or partU or partD
end

function Extra.EnableMagnetize(name)
	name = name or State.MagnetizeTarget or ""
	if name == "" then
		local t = State.TargetPlayer or State.Target
		if t then name = t.Name end
	end
	if not name or name == "" then Notify("Magnetize", "Isi username / pilih target", Config.Theme.Orange); return end
	State.MagnetizeTarget = name; State.MagnetizeOn = true
	Util.Connect("MagNoclip", Services.RS.Stepped, function()
		if not State.MagnetizeOn then return end
		local c = Util.Char(); if not c then return end
		for _, v in ipairs(c:GetChildren()) do if v:IsA("BasePart") then v.CanCollide = false end end
	end)
	Util.Connect("Magnetize", Services.RS.Heartbeat, function()
		if not State.MagnetizeOn then return end
		local plr = Extra.FindPlayerByName(State.MagnetizeTarget) or State.TargetPlayer or State.Target
		local tr = plr and Util.Root(plr); local r = Util.Root()
		if not r or not tr then return end
		if not _magAttach or not _magAttach.Parent then
			pcall(function() if _magAttach then _magAttach:Destroy() end end)
			local att0 = r:FindFirstChild("SRF_MagAtt0") or Instance.new("Attachment"); att0.Name="SRF_MagAtt0"; att0.Parent=r
			local att1 = tr:FindFirstChild("SRF_MagAtt1") or Instance.new("Attachment"); att1.Name="SRF_MagAtt1"; att1.Parent=tr
			local ap = Instance.new("AlignPosition"); ap.Name="SRF_Magnetize"; ap.Attachment0=att0; ap.Attachment1=att1
			ap.MaxForce=1e6; ap.MaxVelocity=200; ap.Responsiveness=80; ap.ApplyAtCenterOfMass=true; ap.Parent=r; _magAttach=ap
		end
		local dir = (tr.Position - r.Position)
		if dir.Magnitude > 2 then r.AssemblyLinearVelocity = dir.Unit * math.min(dir.Magnitude * 8, 180) end
	end)
	Notify("Magnetize", "ON → "..name, Config.Theme.Green)
end
function Extra.DisableMagnetize()
	State.MagnetizeOn=false; Util.Disconnect("Magnetize"); Util.Disconnect("MagNoclip")
	pcall(function() if _magAttach then _magAttach:Destroy() end end); _magAttach=nil
	Notify("Magnetize","OFF",Config.Theme.Sub)
end

-- 1. Character Light
function Extra.EnableCharLight()
	State.CharLightOn = true
	local function addLight(char)
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		if not root then return end
		local old = root:FindFirstChild("CharacterLight")
		if old then old:Destroy() end
		local light = Instance.new("PointLight")
		light.Name = "CharacterLight"
		light.Color = Color3.fromRGB(255, 255, 255)
		light.Brightness = 1
		light.Range = 60
		light.Shadows = false
		light.Parent = root
	end
	addLight(Util.Char())
	Util.Connect("CharLight", LP.CharacterAdded, addLight)
	Notify("Light", "ON", Config.Theme.Green)
end
function Extra.DisableCharLight()
	State.CharLightOn = false
	Util.Disconnect("CharLight")
	local r = Util.Root()
	if r then local L = r:FindFirstChild("CharacterLight"); if L then L:Destroy() end end
	Notify("Light", "OFF", Config.Theme.Sub)
end

-- 2. Word chain bot (sambung kata) - kirim chat otomatis
function Extra.ReplyWord(lastWord)
	if not lastWord or lastWord == "" then return end
	local lastLetter = string.lower(string.sub(lastWord, -1))
	local match = nil
	for _, word in ipairs(WORD_DICT) do
		if string.sub(word, 1, 1) == lastLetter then match = word; break end
	end
	if not match then Notify("WordBot", "tidak ketemu huruf "..lastLetter, Config.Theme.Orange); return end
	pcall(function()
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
		if ev and ev:FindFirstChild("SayMessageRequest") then
			ev.SayMessageRequest:FireServer(match, "All")
		elseif Services.TextChatService then
			-- TextChatService path
			local ch = Services.TextChatService:FindFirstChild("TextChannels")
			ch = ch and (ch:FindFirstChild("RBXGeneral") or ch:FindFirstChildWhichIsA("TextChannel"))
			if ch then ch:SendAsync(match) end
		end
	end)
	Notify("WordBot", "→ "..match, Config.Theme.Accent)
end
function Extra.EnableWordBot()
	State.WordBotOn = true
	-- listen chat dari player lain (basic)
	Util.Connect("WordBot", Services.Players.PlayerAdded, function() end) -- keep alive flag
	Notify("WordBot", "ON - pakai Reply Word di box", Config.Theme.Green)
end
function Extra.DisableWordBot() State.WordBotOn=false; Util.Disconnect("WordBot"); Notify("WordBot","OFF",Config.Theme.Sub) end

-- 3. NPC Controller (Ctrl+Click / nearest / restore)
function Extra.SetNPCCharacter(model)
	if not model or not model:FindFirstChildOfClass("Humanoid") then return end
	if not _origCharName then _origCharName = LP.Name end
	pcall(function()
		LP.Character = model
		Services.WS.CurrentCamera.CameraSubject = model
		if _npcHighlight then _npcHighlight:Destroy() end
		local hl = Instance.new("Highlight")
		hl.Name = "SRF_NPCHighlight"
		hl.FillColor = Color3.fromRGB(0, 255, 100)
		hl.FillTransparency = 0.6
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = model
		hl.Parent = model
		_npcHighlight = hl
		local anim = model:FindFirstChild("Animate")
		if anim then anim.Disabled = true; task.delay(0.1, function() if anim then anim.Disabled = false end end) end
	end)
	pcall(function()
		LP.MaximumSimulationRadius = math.huge
		if typeof(setsimulationradius) == "function" then setsimulationradius(math.huge) end
	end)
	Notify("NPC", model.Name, Config.Theme.Green)
end
function Extra.ControlNearestNPC()
	local r = Util.Root(); if not r then return end
	local best, bestD = nil, math.huge
	for _, obj in ipairs(Services.WS:GetChildren()) do
		if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= Util.Char() then
			local rp = obj:FindFirstChild("HumanoidRootPart")
			if rp then
				local d = (r.Position - rp.Position).Magnitude
				if d < bestD then bestD = d; best = obj end
			end
		end
	end
	if best then Extra.SetNPCCharacter(best) else Notify("NPC", "tidak ada", Config.Theme.Orange) end
end
function Extra.RestoreOriginalCharacter()
	local name = _origCharName or LP.Name
	for _, d in ipairs(Services.WS:GetDescendants()) do
		if d:IsA("Model") and d.Name == name and d:FindFirstChildOfClass("Humanoid") then
			Extra.SetNPCCharacter(d); return
		end
	end
	-- fallback respawn-ish
	pcall(function() if LP.Character then Services.WS.CurrentCamera.CameraSubject = LP.Character end end)
	if _npcHighlight then pcall(function() _npcHighlight:Destroy() end); _npcHighlight=nil end
	Notify("NPC", "restore", Config.Theme.Sub)
end

-- ================================================================
-- AVATAR SWITCH TANPA RESPAWN
-- Pakai HumanoidDescription (outfit akun / avatar user lain) langsung ke karakter yang sedang hidup,
-- jadi posisi tidak berubah dan tidak balik ke bunker. Perubahan ini di sisi client (terlihat di layar kamu).
-- ================================================================
Extra.AV = { list = {}, idx = 0, busy = false }

function Extra.AvLabel()
	if not UI.AvLbl then return end
	local e = Extra.AV.list[Extra.AV.idx]
	if e then
		UI.AvLbl.Text = "AVATAR: " .. e.name .. "  (" .. Extra.AV.idx .. "/" .. #Extra.AV.list .. ")"
	else
		UI.AvLbl.Text = "AVATAR: -"
	end
end

-- cadangan kalau ApplyDescription ditolak: tempel aksesoris/baju/warna dari model hasil description
function Extra.AvManual(hum, desc)
	local char = hum.Parent
	local model = Services.Players:CreateHumanoidModelFromDescription(desc, hum.RigType)
	local function isLook(c)
		return c:IsA("Accessory") or c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") or c:IsA("BodyColors")
	end
	for _, c in ipairs(char:GetChildren()) do if isLook(c) then c:Destroy() end end
	for _, c in ipairs(model:GetChildren()) do
		if isLook(c) then
			local cl = c:Clone()
			if cl:IsA("Accessory") then hum:AddAccessory(cl) else cl.Parent = char end
		end
	end
	local mh, ch = model:FindFirstChild("Head"), char:FindFirstChild("Head")
	if mh and ch then
		local f1, f2 = mh:FindFirstChildOfClass("Decal"), ch:FindFirstChildOfClass("Decal")
		if f2 then f2:Destroy() end
		if f1 then f1:Clone().Parent = ch end
	end
	model:Destroy()
end

function Extra.AvApply(entry)
	if not entry then Notify("Avatar", "Load outfits first", Config.Theme.Orange); return end
	local hum = Util.Hum()
	if not hum then Notify("Avatar", "Character Not Ready", Config.Theme.Orange); return end
	if Extra.AV.busy then return end
	Extra.AV.busy = true
	task.spawn(function()
		local ok, err = pcall(function()
			local P = Services.Players
			local desc
			if entry.outfitId then
				desc = P:GetHumanoidDescriptionFromOutfitId(entry.outfitId)
			else
				desc = P:GetHumanoidDescriptionFromUserId(entry.userId or LP.UserId)
			end
			local root = Util.Root()
			local cf = root and root.CFrame
			local ok2 = pcall(function() hum:ApplyDescription(desc) end)
			if not ok2 then Extra.AvManual(hum, desc) end
			local r2 = Util.Root()
			if r2 and cf and (r2.Position - cf.Position).Magnitude > 3 then r2.CFrame = cf end -- jaga posisi
		end)
		Extra.AV.busy = false
		if ok then
			Notify("Avatar", "Avatar applied (local): " .. tostring(entry.name), Config.Theme.Green)
		else
			Notify("Avatar", "Avatar failed", Config.Theme.Red)
			warn("[YOURSCRIPT] Avatar:", err)
		end
	end)
end

function Extra.AvLoad()
	if Extra.AV.busy then return end
	Notify("Avatar", "Loading outfits...", Config.Theme.Sub)
	task.spawn(function()
		local list = { { name = "Avatar Utama", userId = LP.UserId } }
		local url = "https://avatar.roblox.com/v1/users/" .. LP.UserId .. "/outfits?page=1&itemsPerPage=100&isEditable=true"
		local code, body = HttpGet(url)
		if code and code >= 200 and code < 300 then
			local ok, data = pcall(function() return Services.Http:JSONDecode(body) end)
			if ok and data and data.data then
				for _, o in ipairs(data.data) do
					list[#list + 1] = { name = tostring(o.name), outfitId = o.id }
				end
			end
		end
		Extra.AV.list = list
		Extra.AV.idx = 1
		Extra.AvLabel()
		if #list <= 1 then
			Notify("Avatar", "No outfits found", Config.Theme.Orange)
		else
			Notify("Avatar", "Outfits loaded: " .. (#list - 1), Config.Theme.Green)
		end
	end)
end

function Extra.AvPrev()
	local n = #Extra.AV.list
	if n == 0 then Notify("Avatar", "Load outfits first", Config.Theme.Orange); return end
	Extra.AV.idx = (Extra.AV.idx - 2) % n + 1
	Extra.AvLabel()
end

function Extra.AvNext()
	local n = #Extra.AV.list
	if n == 0 then Notify("Avatar", "Load outfits first", Config.Theme.Orange); return end
	Extra.AV.idx = Extra.AV.idx % n + 1
	Extra.AvLabel()
end

function Extra.AvApplySelected() Extra.AvApply(Extra.AV.list[Extra.AV.idx]) end
function Extra.AvNextApply() Extra.AvNext(); if #Extra.AV.list > 0 then Extra.AvApplySelected() end end
function Extra.AvPrevApply() Extra.AvPrev(); if #Extra.AV.list > 0 then Extra.AvApplySelected() end end

-- avatar milik user lain / akun alt (username atau UserId)
function Extra.AvApplyUser(text)
	text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then Notify("Avatar", "Enter a username or UserId", Config.Theme.Orange); return end
	task.spawn(function()
		local uid = tonumber(text)
		if not uid then
			local ok, res = pcall(function() return Services.Players:GetUserIdFromNameAsync(text) end)
			if ok then uid = res end
		end
		if not uid then Notify("Avatar", "Not Found: " .. text, Config.Theme.Orange); return end
		Extra.AvApply({ name = text, userId = uid })
	end)
end

-- ganti avatar asli (sudah diubah di Roblox) lalu respawn, otomatis balik ke posisi semula
function Extra.RespawnHere()
	local r, hum = Util.Root(), Util.Hum()
	if not (r and hum) then Notify("Avatar", "Character Not Ready", Config.Theme.Orange); return end
	State.PendingRespawnPos = r.CFrame
	hum.Health = 0
	Notify("Avatar", "Respawning in place...", Config.Theme.Orange)
end

function Extra.EnableNPCClick()
	State.NPCControlOn = true
	Util.Connect("NPCClick", Mouse.Button1Down, function()
		if not State.NPCControlOn then return end
		if not Services.UIS:IsKeyDown(Enum.KeyCode.LeftControl) then return end
		local t = Mouse.Target; if not t then return end
		local model = t:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChildOfClass("Humanoid") then Extra.SetNPCCharacter(model) end
	end)
	Notify("NPC", "Ctrl+Click ON", Config.Theme.Green)
end
function Extra.DisableNPCClick()
	State.NPCControlOn = false
	Util.Disconnect("NPCClick")
	Notify("NPC", "Ctrl+Click OFF", Config.Theme.Sub)
end

-- 4. Workspace Hint
function Extra.ShowHint(text)
	text = text or "YOURSCRIPT"
	for _, h in ipairs(Services.WS:GetChildren()) do
		if h:IsA("Hint") and h.Name == "SRF_Hint" then h:Destroy() end
	end
	local h = Instance.new("Hint")
	h.Name = "SRF_Hint"
	h.Text = tostring(text)
	h.Parent = Services.WS
	Notify("Hint", "shown", Config.Theme.Accent)
end
function Extra.ClearHint()
	for _, h in ipairs(Services.WS:GetChildren()) do
		if h:IsA("Hint") and h.Name == "SRF_Hint" then h:Destroy() end
	end
end

-- 5. Spin Fling (continuous BodyAngularVelocity) - fixed
function Extra.EnableSpinFling()
	local r = Util.Root(); if not r then return end
	Extra.DisableSpinFling()
	State.SpinFlingOn = true
	local bv = Instance.new("BodyAngularVelocity")
	bv.Name = "FlingBV"
	bv.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bv.P = 1e9
	bv.AngularVelocity = Vector3.new(0, 9e5, 0)
	bv.Parent = r
	Util.Connect("SpinFling", Services.RS.Stepped, function()
		if not State.SpinFlingOn then return end
		local c = Util.Char(); if not c then return end
		for _, v in ipairs(c:GetChildren()) do
			if v:IsA("BasePart") then v.CanCollide = false; v.Massless = true end
		end
	end)
	Notify("SpinFling", "ON", Config.Theme.Orange)
end
function Extra.DisableSpinFling()
	State.SpinFlingOn = false
	Util.Disconnect("SpinFling")
	local r = Util.Root()
	if r then local bv = r:FindFirstChild("FlingBV"); if bv then bv:Destroy() end end
	Notify("SpinFling", "OFF", Config.Theme.Sub)
end

-- 7. Touch Fling (sentuh player = fling)
function Extra.EnableTouchFling()
	State.TouchFlingOn = true
	local lastFling = 0
	local function bindHRP(char)
		local r = char and char:FindFirstChild("HumanoidRootPart"); if not r then return end
		Util.Connect("TouchFlingHit", r.Touched, function(hit)
			if not State.TouchFlingOn then return end
			if not hit or not hit.Parent then return end
			if hit.Transparency >= 1 then return end
			local model = hit:FindFirstAncestorOfClass("Model")
			if not model or model == char then return end
			if not model:FindFirstChildOfClass("Humanoid") then return end
			local victimRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
			if not victimRoot then return end
			local now = os.clock()
			if now - lastFling < 0.35 then return end
			lastFling = now
			local mult = (State.TouchFlingPower or 5)
			local power = 70 * mult
			pcall(function()
				victimRoot.AssemblyLinearVelocity = Vector3.new(
					(math.random()-0.5)*2*power, power*1.1, (math.random()-0.5)*2*power)
			end)
			local bv = Instance.new("BodyVelocity")
			bv.Name = "SRF_TouchFling"
			bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			bv.Velocity = Vector3.new((math.random()-0.5)*2*power, power*1.1, (math.random()-0.5)*2*power)
			bv.Parent = victimRoot
			task.delay(0.3, function() pcall(function() bv:Destroy() end) end)
		end)
	end
	bindHRP(Util.Char())
	Util.Connect("TouchFlingChar", LP.CharacterAdded, bindHRP)
	Notify("TouchFling", "ON (fling lawan)", Config.Theme.Orange)
end
function Extra.DisableTouchFling()
	State.TouchFlingOn = false
	Util.Disconnect("TouchFling"); Util.Disconnect("TouchFlingHit"); Util.Disconnect("TouchFlingChar")
	Notify("TouchFling", "OFF", Config.Theme.Sub)
end

-- 8. Hidden Fling (velocity pulse) - fixed
function Extra.EnableHiddenFling()
	State.HiddenFlingOn = true
	Util.Connect("HiddenFling", Services.RS.Heartbeat, function()
		if not State.HiddenFlingOn then return end
		local c = Util.Char(); local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local vel = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = vel * 1000000 + Vector3.new(0, 1000000, 0)
		Services.RS.RenderStepped:Wait()
		if hrp and hrp.Parent then hrp.AssemblyLinearVelocity = vel end
		Services.RS.Stepped:Wait()
		if hrp and hrp.Parent then
			hrp.AssemblyLinearVelocity = vel + Vector3.new(0, 0.1, 0)
		end
	end)
	Notify("HiddenFling", "ON (Pos)", Config.Theme.Red)
end
function Extra.DisableHiddenFling()
	State.HiddenFlingOn = false
	Util.Disconnect("HiddenFling")
	Notify("HiddenFling", "OFF (Neg)", Config.Theme.Sub)
end

function Extra.MeshTroll(kind)
	local c=Util.Char(); if not c then return end
	local partName=({dick="LowerTorso",ass="LowerTorso",tits="UpperTorso"})[kind] or "LowerTorso"
	local part=c:FindFirstChild(partName) or c:FindFirstChild("Torso") or Util.Root(); if not part then return end
	pcall(function()
		local old=part:FindFirstChild("SRF_MeshTroll"); if old then old:Destroy() end
		local m=Instance.new("SpecialMesh"); m.Name="SRF_MeshTroll"; m.MeshType=Enum.MeshType.Sphere
		m.Scale=Vector3.new(1.2,1.8,1.2); if kind=="tits" then m.Scale=Vector3.new(2.2,1.4,1.6) end; if kind=="ass" then m.Scale=Vector3.new(1.8,1.2,1.5) end
		m.Parent=part
	end); Notify("Troll",kind,Config.Theme.Purple)
end
function Extra.ClearMeshTroll() local c=Util.Char(); if not c then return end; for _,d in ipairs(c:GetDescendants()) do if d.Name=="SRF_MeshTroll" then pcall(function() d:Destroy() end) end end end

function Extra.LoadDex()
	Notify("Loader","Dex...",Config.Theme.Accent)
	task.spawn(function()
		for _,u in ipairs({"https://raw.githubusercontent.com/infyiff/backup/main/dex.lua","https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"}) do
			if pcall(function() loadstring(game:HttpGet(u))() end) then Notify("Dex","Loaded",Config.Theme.Green); return end
		end
		Notify("Dex","Gagal",Config.Theme.Orange)
	end)
end
function Extra.LoadRemoteSpy()
	Notify("Loader","RemoteSpy...",Config.Theme.Accent)
	task.spawn(function()
		if pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))() end) then
			Notify("Spy","Loaded",Config.Theme.Green) else Notify("Spy","Gagal",Config.Theme.Orange) end
	end)
end
function Extra.LoadIY()
	Notify("Loader","IY...",Config.Theme.Accent)
	task.spawn(function()
		if pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end) then
			Notify("IY","Loaded",Config.Theme.Green) else Notify("IY","Gagal",Config.Theme.Orange) end
	end)
end
-- 6. Grab Tool external
function Extra.LoadGrabTool()
	Notify("Loader","Grab Tool...",Config.Theme.Accent)
	task.spawn(function()
		local ok = pcall(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/TheVoll/Grab-Tool-for-Roblox/refs/heads/main/Grab%20Tools.lua"))()
		end)
		if ok then Notify("GrabTool","Loaded",Config.Theme.Green) else Notify("GrabTool","Gagal",Config.Theme.Orange) end
	end)
end

function Extra.Cleanup()
	Extra.DisableFloat(); Extra.DisableSpin(); Extra.DisableNoGravity()
	Extra.DisableXray(); Extra.DisableInvisible(); Extra.DisableAntiFling()
	Extra.DisableStalk(); Extra.DisableStare(); Extra.DisableInstantPrompt()
	Extra.StopAttach(); Extra.DisableAimbot(); Extra.DisableHitbox()
	Extra.DisableReach(); Extra.DisableFakeLag(); Extra.DisableClickFling()
	Extra.DisableOrbit(); Extra.DisableGodMode(); Extra.DisableMagnetize()
	Extra.DisableCharLight(); Extra.DisableWordBot(); Extra.DisableNPCClick()
	Extra.DisableSpinFling(); Extra.DisableTouchFling(); Extra.DisableHiddenFling()
	Extra.ClearHint(); Extra.ClearMeshTroll()
	if _npcHighlight then pcall(function() _npcHighlight:Destroy() end); _npcHighlight=nil end
end


----------------------------------------------------------------
-- UI BUILDER
----------------------------------------------------------------
local function BuildUI()
	local T = Config.Theme
	local P = Config.Panel

	local vp = Vector2.new(1280, 720)
	pcall(function()
		if Services.WS.CurrentCamera then vp = Services.WS.CurrentCamera.ViewportSize end
	end)
	local isMobile = Services.UIS.TouchEnabled
		or (vp.X > 0 and vp.X < 700)
		or (vp.Y > 0 and vp.X > 0 and (vp.Y / math.max(vp.X, 1)) > 1.25)
	UI.IsMobile = isMobile
	if isMobile then
		P.Width = math.floor(P.Width * 0.78)
		P.PosX = 8
		P.PosYScale = 0.35
		P.PosYOffset = -160
	end
	print("[YOURSCRIPT] Mobile detect:", isMobile, "Touch=", Services.UIS.TouchEnabled, "VP=", vp)

	local gui = Instance.new("ScreenGui")
	gui.Name = P.Name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999
	gui.IgnoreGuiInset = true
	-- [REVISI] fallback berantai: CoreGui → gethui() → PlayerGui
	local parented = false
	pcall(function() gui.Parent = Services.CG; parented = gui.Parent ~= nil end)
	if not parented and gethui then
		pcall(function() gui.Parent = gethui(); parented = gui.Parent ~= nil end)
	end
	if not parented then
		gui.Parent = LP:WaitForChild("PlayerGui")
		gui.ResetOnSpawn = false -- penting agar tidak hilang saat respawn
	end
	UI.Gui = gui
	Glass.Attach(gui) -- [GLASS SKIN] visual saja
	pcall(Glass.I18N.Attach, gui) -- [I18N] terjemah EN/ID otomatis untuk seluruh teks GUI
	-- verifikasi: kalau parent nil (sangat jarang), tampilkan error jelas
	if not UI.Gui.Parent then
		warn("[YOURSCRIPT] Gagal memasang GUI di host manapun!")
	end

	-- Watermark
	local wm = Instance.new("Frame")
	wm.Name = "Watermark"
	wm.Size = UDim2.new(0, 220, 0, 28)
	wm.Position = UDim2.new(0, 12, 0, 8)
	wm.BackgroundColor3 = T.Panel
	wm.BackgroundTransparency = 0.15
	wm.BorderSizePixel = 0
	wm.Parent = gui
	Util.Corner(wm, 8)
	Util.Stroke(wm, T.Accent, 1, 0.5)
	local wmL = Instance.new("TextLabel")
	wmL.Size = UDim2.new(1, -10, 1, 0)
	wmL.Position = UDim2.new(0, 8, 0, 0)
	wmL.BackgroundTransparency = 1
	wmL.Text = "YOURSCRIPT  |  -- fps  |  -- ms  |  --:--"
	wmL.TextColor3 = T.Text
	wmL.TextSize = 11
	wmL.Font = Config.Font.Bold
	wmL.TextXAlignment = Enum.TextXAlignment.Left
	wmL.Parent = wm
	UI.Watermark = wmL

	-- Main Panel
	local panel = Instance.new("Frame")
	panel.Name = "Main"
	panel.Size = UDim2.new(0, P.Width, 0, P.Height)
	panel.Position = UDim2.new(0, P.PosX, P.PosYScale, P.PosYOffset)
	panel.BackgroundColor3 = T.Bg
	panel.BackgroundTransparency = P.Transparency
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	panel.Active = true
	panel.Parent = gui
	Util.Corner(panel, P.Corner)
	Util.Stroke(panel, T.Accent, 1.4, T.StrokeT)
	local pGrad = Instance.new("UIGradient")
	pGrad.Color = ColorSequence.new(Color3.fromRGB(22, 25, 32), Color3.fromRGB(10, 12, 16))
	pGrad.Rotation = 90
	pGrad.Parent = panel
	UI.Panel = panel
	Glass.PanelShadow(panel) -- [GLASS SKIN] visual saja
	if isMobile then
		local uiScale = Instance.new("UIScale")
		uiScale.Scale = 0.72
		uiScale.Parent = panel
	end

	-- Shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6014261993"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.45
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.ZIndex = 0
	shadow.Parent = panel

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 58)
	header.BackgroundColor3 = T.Panel
	header.BorderSizePixel = 0
	header.Parent = panel
	Util.Corner(header, P.Corner)
	local hGrad = Instance.new("UIGradient")
	hGrad.Color = ColorSequence.new(Color3.fromRGB(34, 39, 50), Color3.fromRGB(20, 23, 29))
	hGrad.Rotation = 90
	hGrad.Parent = header

	local logo = Instance.new("Frame")
	logo.Size = UDim2.new(0, 32, 0, 32)
	logo.Position = UDim2.new(0, 12, 0, 13)
	logo.BackgroundColor3 = T.Accent
	logo.BorderSizePixel = 0
	logo.Parent = header
	Util.Corner(logo, 8)
	local logoT = Instance.new("TextLabel")
	logoT.Size = UDim2.new(1, 0, 1, 0)
	logoT.BackgroundTransparency = 1
	logoT.Text = "V"
	logoT.TextColor3 = Color3.fromRGB(8, 12, 20)
	logoT.TextSize = 18
	logoT.Font = Config.Font.Title
	logoT.Parent = logo

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -120, 0, 20)
	title.Position = UDim2.new(0, 52, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = P.Title
	title.TextColor3 = T.Text
	title.TextSize = 16
	title.Font = Config.Font.Title
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -120, 0, 14)
	sub.Position = UDim2.new(0, 52, 0, 28)
	sub.BackgroundTransparency = 1
	sub.Text = P.Subtitle
	sub.TextColor3 = T.Accent
	sub.TextSize = 10
	sub.Font = Config.Font.Bold
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Parent = header

	local ed = Instance.new("TextLabel")
	ed.Size = UDim2.new(1, -120, 0, 12)
	ed.Position = UDim2.new(0, 52, 0, 42)
	ed.BackgroundTransparency = 1
	ed.Text = P.Edition
	ed.TextColor3 = T.Sub
	ed.TextSize = 9
	ed.Font = Config.Font.Reg
	ed.TextXAlignment = Enum.TextXAlignment.Left
	ed.Parent = header

	-- [LOGO] gambar logo menggantikan kotak "V" + teks judul (ukuran setara teks lama)
	do
		local img = Glass.MakeLogo(header, UDim2.new(0, 138, 0, 40), UDim2.new(0, 8, 0, 9), 5)
		if img then
			logo.Visible = false
			title.Visible = false
			sub.Position = UDim2.new(0, 152, 0, 14)
			sub.Size = UDim2.new(0, 112, 0, 14)
			sub.TextSize = 9
			sub.TextTruncate = Enum.TextTruncate.AtEnd
			ed.Position = UDim2.new(0, 152, 0, 30)
			ed.Size = UDim2.new(0, 112, 0, 12)
			ed.TextSize = 8
		end
	end

	local function HeadBtn(txt, xOff, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0, 28, 0, 28)
		b.Position = UDim2.new(1, xOff, 0, 15)
		b.BackgroundColor3 = T.Panel3
		b.BackgroundTransparency = 0.15
		b.Text = txt
		b.TextColor3 = T.Sub
		b.TextSize = 14
		b.Font = Config.Font.Bold
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Parent = header
		Util.Corner(b, 8)
		Util.Stroke(b, Color3.fromRGB(255,255,255), 1, 0.85)
		b.MouseEnter:Connect(function()
			Util.Tween(b, { BackgroundColor3 = color, TextColor3 = T.Text, BackgroundTransparency = 0.05 }, 0.12)
		end)
		b.MouseLeave:Connect(function()
			Util.Tween(b, { BackgroundColor3 = T.Panel3, TextColor3 = T.Sub, BackgroundTransparency = 0.15 }, 0.12)
		end)
		return b
	end

	local hideBtn = HeadBtn("−", -70, T.Accent2)
	local closeBtn = HeadBtn("✕", -36, T.Red)
	Glass.IconBtn(hideBtn, { ["−"] = "minus" }, 22)
	Glass.IconBtn(closeBtn, { ["✕"] = "cross" }, 22)

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(1, 0, 0, 2)
	accentBar.Position = UDim2.new(0, 0, 1, -2)
	accentBar.BackgroundColor3 = T.Accent
	accentBar.BorderSizePixel = 0
	accentBar.Parent = header

	-- Status bar under header
	local status = Instance.new("Frame")
	status.Size = UDim2.new(1, 0, 0, 22)
	status.Position = UDim2.new(0, 0, 0, 58)
	status.BackgroundColor3 = T.Panel2
	status.BorderSizePixel = 0
	status.Parent = panel
	local stDot = Instance.new("Frame")
	stDot.Size = UDim2.new(0, 7, 0, 7)
	stDot.Position = UDim2.new(0, 12, 0.5, -3)
	stDot.BackgroundColor3 = T.Green
	stDot.BorderSizePixel = 0
	stDot.Parent = status
	Util.Corner(stDot, 4)
	local stLbl = Instance.new("TextLabel")
	stLbl.Size = UDim2.new(1, -30, 1, 0)
	stLbl.Position = UDim2.new(0, 24, 0, 0)
	stLbl.BackgroundTransparency = 1
	stLbl.Text = "STATUS: READY"
	stLbl.TextColor3 = T.Sub
	stLbl.TextSize = 10
	stLbl.Font = Config.Font.Bold
	stLbl.TextXAlignment = Enum.TextXAlignment.Left
	stLbl.Parent = status
	UI.Status = stLbl
	UI.StatusDot = stDot

	-- Tab bar
	local tabBar = Instance.new("ScrollingFrame")
	tabBar.Size = UDim2.new(1, -16, 0, 36)
	tabBar.Position = UDim2.new(0, 8, 0, 84)
	tabBar.BackgroundTransparency = 1
	tabBar.BorderSizePixel = 0
	tabBar.ScrollBarThickness = 3
	tabBar.ScrollBarImageColor3 = T.Accent
	tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabBar.ScrollingDirection = Enum.ScrollingDirection.X
	tabBar.Parent = panel
	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Horizontal
	tabList.Padding = UDim.new(0, 5)
	tabList.Parent = tabBar

	-- Content pages
	local pages = Instance.new("Frame")
	pages.Size = UDim2.new(1, -16, 1, -130)
	pages.Position = UDim2.new(0, 8, 0, 122)
	pages.BackgroundTransparency = 1
	pages.ClipsDescendants = true
	pages.Parent = panel
	UI.Pages = pages

	local tabs = {}
	local currentTab = nil
	local pageOrder = 0

	local function MakePage(name, icon)
		pageOrder = pageOrder + 1
		local page = Instance.new("ScrollingFrame")
		page.Name = name
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = T.Accent
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.Visible = false
		page.Parent = pages
		Util.List(page, 5)
		Util.Pad(page, 4, 12, 2, 2)

		local tab = Instance.new("TextButton")
		tab.Size = UDim2.new(0, 70, 0, 28)
		tab.BackgroundColor3 = T.Panel2
		tab.Text = ""
		tab.BorderSizePixel = 0
		tab.AutoButtonColor = false
		tab.Parent = tabBar
		Util.Corner(tab, 8)
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, -6, 1, 0)
		tl.Position = UDim2.new(0, 3, 0, 0)
		tl.BackgroundTransparency = 1
		tl.Text = name
		-- ikon premium digambar Glass.Icons / gIconDraw (bukan emoji)
		pcall(function()
			local kind = gIconKind(icon) or ICON_BY_TAB[name]
			if kind then
				local hold = Instance.new("Frame")
				hold.Name = "SRF_TabIcon"
				hold.BackgroundTransparency = 1
				hold.Size = UDim2.fromOffset(12, 12)
				hold.Position = UDim2.new(0, 6, 0.5, -6)
				hold.ZIndex = tab.ZIndex + 2
				hold.Parent = tab
				gIconDraw(hold, kind, 12, T.Sub)
				tl.Position = UDim2.new(0, 20, 0, 0)
				tl.Size = UDim2.new(1, -24, 1, 0)
			end
		end)
		tl.TextColor3 = T.Sub
		tl.TextSize = 10
		tl.Font = Config.Font.Bold
		tl.Parent = tab

		local function select()
			if currentTab == name then return end
			for n, d in pairs(tabs) do
				d.page.Visible = false
				Util.Tween(d.tab, { BackgroundColor3 = T.Pill or T.Panel2 }, 0.2)
				d.label.TextColor3 = T.Sub
			end
			page.Visible = true
			page.CanvasPosition = Vector2.zero
			pcall(function()
				for i, ch in ipairs(page:GetChildren()) do
					if ch:IsA("GuiObject") and ch.BackgroundTransparency < 0.99 then
						local bt = ch.BackgroundTransparency
						ch.BackgroundTransparency = 1
						task.delay(math.min(i * 0.012, 0.1), function()
							if ch and ch.Parent then
								Util.Tween(ch, { BackgroundTransparency = bt }, 0.3, Enum.EasingStyle.Quint)
							end
						end)
					end
				end
			end)
			Util.Tween(tab, { BackgroundColor3 = T.Active or T.Panel3 }, 0.22, Enum.EasingStyle.Quint)
			tl.TextColor3 = T.Text
			currentTab = name
			if UI.OnTabSelect then pcall(UI.OnTabSelect, name) end
		end
		tab.MouseButton1Click:Connect(select)
		tabs[name] = { page = page, tab = tab, label = tl, select = select }

		local order = 0
		local api = {}
		function api:Section(txt)
			order = order + 1
			local s = Instance.new("Frame")
			s.Size = UDim2.new(1, 0, 0, 22)
			s.BackgroundColor3 = T.Panel2
			s.BorderSizePixel = 0
			s.LayoutOrder = order
			s.Parent = page
			Util.Corner(s, 6)
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0, 3, 0, 12)
			bar.Position = UDim2.new(0, 8, 0.5, -6)
			bar.BackgroundColor3 = T.Accent
			bar.BorderSizePixel = 0
			bar.Parent = s
			Util.Corner(bar, 2)
			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, -20, 1, 0)
			l.Position = UDim2.new(0, 16, 0, 0)
			l.BackgroundTransparency = 1
			l.Text = string.upper(txt)
			l.TextColor3 = T.Text
			l.TextSize = 11
			l.Font = Config.Font.Bold
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Parent = s
		end

		function api:Toggle(label, icon, key, default, getState, enableFn, disableFn)
			order = order + 1
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 36)
			row.BackgroundColor3 = T.Panel
			row.BorderSizePixel = 0
			row.LayoutOrder = order
			row.Parent = page
			Util.Corner(row, 8)

			local ic = Instance.new("Frame")
			ic.Size = UDim2.new(0, 22, 0, 22)
			ic.Position = UDim2.new(0, 8, 0.5, -11)
			ic.BackgroundColor3 = T.Panel3
			ic.BorderSizePixel = 0
			ic.Parent = row
			Util.Corner(ic, 6)
			do
				local kind = gIconKind(icon) or "sparkle"
				local hold = Instance.new("Frame")
				hold.BackgroundTransparency = 1
				hold.Size = UDim2.fromOffset(14, 14)
				hold.Position = UDim2.new(0.5, -7, 0.5, -7)
				hold.Parent = ic
				pcall(function() gIconDraw(hold, kind, 14, T.Accent) end)
			end

			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, -100, 1, 0)
			l.Position = UDim2.new(0, 36, 0, 0)
			l.BackgroundTransparency = 1
			l.Text = label
			l.TextColor3 = T.Text
			l.TextSize = 12
			l.Font = Config.Font.Bold
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Parent = row

			if key then
				local kb = Instance.new("TextLabel")
				kb.Size = UDim2.new(0, 20, 0, 18)
				kb.Position = UDim2.new(1, -78, 0.5, -9)
				kb.BackgroundColor3 = T.Panel3
				kb.Text = Util.KeyName(key)
				kb.TextColor3 = T.Accent
				kb.TextSize = 9
				kb.Font = Config.Font.Title
				kb.BorderSizePixel = 0
				kb.Parent = row
				Util.Corner(kb, 4)
				Util.Stroke(kb, T.Accent, 1, 0.5)
			end

			local track = Instance.new("TextButton")
			track.Size = UDim2.new(0, 44, 0, 24)
			track.Position = UDim2.new(1, -52, 0.5, -12)
			track.BackgroundColor3 = T.Panel3
			track.Text = ""
			track.BorderSizePixel = 0
			track.AutoButtonColor = false
			track.Parent = row
			Util.Corner(track, 12)

			local knob = Instance.new("Frame")
			knob.Size = UDim2.new(0, 18, 0, 18)
			knob.Position = UDim2.new(0, 3, 0.5, -9)
			knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
			knob.BorderSizePixel = 0
			knob.Parent = track
			Util.Corner(knob, 9)

			local on = default and true or false
			local function paint(animate)
				local col = on and T.Green or T.Panel3
				local kx = on and 23 or 3
				if animate then
					Util.Tween(track, { BackgroundColor3 = col }, 0.12)
					Util.Tween(knob, { Position = UDim2.new(0, kx, 0.5, -9) }, 0.12)
				else
					track.BackgroundColor3 = col
					knob.Position = UDim2.new(0, kx, 0.5, -9)
				end
			end
			local function set(v, silent)
				if v == on then return end
				on = v
				paint(true)
				if on then enableFn() else disableFn() end
			end
			local function flip()
				set(not on)
			end
			track.MouseButton1Click:Connect(flip)
			paint(false)

			local id = name .. "_" .. label
			ToggleFns[id] = {
				set = set,
				get = function() return on end,
				enable = enableFn,
				disable = disableFn,
				flip = flip,
			}
			return ToggleFns[id]
		end

		function api:Button(label, icon, key, color, fn)
			order = order + 1
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 34)
			b.BackgroundColor3 = color or T.Panel2
			b.Text = ""
			b.BorderSizePixel = 0
			b.AutoButtonColor = false
			b.LayoutOrder = order
			b.Parent = page
			Util.Corner(b, 8)
			Util.Stroke(b, color or T.Panel2, 1, 0.3)

			local ic = Instance.new("Frame")
			ic.Size = UDim2.new(0, 22, 0, 22)
			ic.Position = UDim2.new(0, 8, 0.5, -11)
			ic.BackgroundColor3 = T.Panel3
			ic.BorderSizePixel = 0
			ic.Parent = b
			Util.Corner(ic, 6)
			local lockedBtn = (icon == "lock")
			local iconCol = lockedBtn and Color3.fromRGB(90, 95, 110) or T.Accent
			local textCol = lockedBtn and Color3.fromRGB(90, 95, 110) or T.Text
			do
				local kind = gIconKind(icon) or "sparkle"
				local hold = Instance.new("Frame")
				hold.BackgroundTransparency = 1
				hold.Size = UDim2.fromOffset(14, 14)
				hold.Position = UDim2.new(0.5, -7, 0.5, -7)
				hold.Parent = ic
				pcall(function() gIconDraw(hold, kind, 14, iconCol) end)
			end

			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, -70, 1, 0)
			l.Position = UDim2.new(0, 36, 0, 0)
			l.BackgroundTransparency = 1
			l.Text = label
			l.TextColor3 = textCol
			l.TextSize = 12
			l.Font = Config.Font.Bold
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Parent = b

			if key then
				local kb = Instance.new("TextLabel")
				kb.Size = UDim2.new(0, 20, 0, 18)
				kb.Position = UDim2.new(1, -28, 0.5, -9)
				kb.BackgroundColor3 = T.Panel3
				kb.Text = Util.KeyName(key)
				kb.TextColor3 = T.Accent
				kb.TextSize = 9
				kb.Font = Config.Font.Title
				kb.BorderSizePixel = 0
				kb.Parent = b
				Util.Corner(kb, 4)
			end

			b.MouseEnter:Connect(function()
				Util.Tween(b, { BackgroundColor3 = Color3.fromRGB(
					math.min(255, (color or T.Panel2).R * 255 + 18),
					math.min(255, (color or T.Panel2).G * 255 + 18),
					math.min(255, (color or T.Panel2).B * 255 + 18)
				) }, 0.1)
			end)
			b.MouseLeave:Connect(function()
				Util.Tween(b, { BackgroundColor3 = color or T.Panel2 }, 0.1)
			end)
			b.MouseButton1Click:Connect(function()
				local r = Instance.new("Frame")
				r.Size = UDim2.new(0, 0, 0, 0)
				r.Position = UDim2.new(0.5, 0, 0.5, 0)
				r.AnchorPoint = Vector2.new(0.5, 0.5)
				r.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				r.BackgroundTransparency = 0.7
				r.BorderSizePixel = 0
				r.Parent = b
				Util.Corner(r, 40)
				Util.Tween(r, { Size = UDim2.new(0, 200, 0, 200), BackgroundTransparency = 1 }, 0.35)
				task.delay(0.4, function() r:Destroy() end)
				Util.Safe(fn)
			end)
			return b
		end

		-- [MERGED] elemen Box (input teks) untuk WalkSpeed & TP by Name dari dangerousnight
		function api:Box(label, placeholder, default, onCommit)
			order = order + 1
			local f = Instance.new("Frame")
			f.Size = UDim2.new(1, 0, 0, 54)
			f.BackgroundColor3 = T.Panel
			f.BorderSizePixel = 0
			f.LayoutOrder = order
			f.Parent = page
			Util.Corner(f, 8)

			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, -20, 0, 18)
			l.Position = UDim2.new(0, 10, 0, 6)
			l.BackgroundTransparency = 1
			l.Text = label
			l.TextColor3 = T.Text
			l.TextSize = 11
			l.Font = Config.Font.Bold
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Parent = f

			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, -20, 0, 24)
			box.Position = UDim2.new(0, 10, 0, 24)
			box.BackgroundColor3 = T.Panel3
			box.Text = default or ""
			box.PlaceholderText = placeholder or ""
			box.PlaceholderColor3 = T.Sub
			box.TextColor3 = T.Text
			box.TextSize = 12
			box.Font = Config.Font.Bold
			box.ClearTextOnFocus = false
			box.BorderSizePixel = 0
			box.Parent = f
			Util.Corner(box, 6)
			Util.Stroke(box, T.Accent, 1, 0.4)

			box.FocusLost:Connect(function()
				Util.Safe(function() onCommit(box.Text) end)
			end)
			return box
		end

		function api:Slider(label, min, max, default, onChange, opts)
			opts = opts or {}
			order = order + 1
			local f = Instance.new("Frame")
			f.Size = UDim2.new(1, 0, 0, 52)
			f.BackgroundColor3 = T.Panel
			f.BorderSizePixel = 0
			f.LayoutOrder = order
			f.Parent = page
			Util.Corner(f, 8)

			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(0.6, 0, 0, 18)
			l.Position = UDim2.new(0, 10, 0, 6)
			l.BackgroundTransparency = 1
			l.Text = label
			l.TextColor3 = T.Text
			l.TextSize = 11
			l.Font = Config.Font.Bold
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Parent = f

			local val = Instance.new("TextLabel")
			val.Size = UDim2.new(0.35, 0, 0, 18)
			val.Position = UDim2.new(0.62, 0, 0, 6)
			val.BackgroundTransparency = 1
			val.Text = string.format("%.1f", default)
			val.TextColor3 = T.Accent
			val.TextSize = 12
			val.Font = Config.Font.Title
			val.TextXAlignment = Enum.TextXAlignment.Right
			val.Parent = f

			local minus = Instance.new("TextButton")
			minus.Size = UDim2.new(0, 28, 0, 22)
			minus.Position = UDim2.new(0, 10, 0, 26)
			minus.BackgroundColor3 = T.Panel3
			minus.Text = "−"
			minus.TextColor3 = T.Text
			minus.TextSize = 14
			minus.Font = Config.Font.Bold
			minus.BorderSizePixel = 0
			minus.Parent = f
			Util.Corner(minus, 6)

			local plus = Instance.new("TextButton")
			plus.Size = UDim2.new(0, 28, 0, 22)
			plus.Position = UDim2.new(1, -38, 0, 26)
			plus.BackgroundColor3 = T.Panel3
			plus.Text = "+"
			plus.TextColor3 = T.Text
			plus.TextSize = 14
			plus.Font = Config.Font.Bold
			plus.BorderSizePixel = 0
			plus.Parent = f
			Util.Corner(plus, 6)

			local barBg = Instance.new("Frame")
			barBg.Size = UDim2.new(1, -90, 0, 6)
			barBg.Position = UDim2.new(0, 44, 0, 34)
			barBg.BackgroundColor3 = T.Panel3
			barBg.BorderSizePixel = 0
			barBg.Parent = f
			Util.Corner(barBg, 3)

			local fill = Instance.new("Frame")
			local function relOf(v)
				if opts.log then return math.clamp(math.log(v / min) / math.log(max / min), 0, 1) end
				return (v - min) / (max - min)
			end
			fill.Size = UDim2.new(relOf(default), 0, 1, 0)
			fill.BackgroundColor3 = T.Accent
			fill.BorderSizePixel = 0
			fill.Parent = barBg
			Util.Corner(fill, 3)

			local cur = default
			local function apply(v)
				if opts.round then v = math.floor(v / opts.round + 0.5) * opts.round end
				cur = math.clamp(v, min, max)
				val.Text = string.format("%.1f", cur)
				fill.Size = UDim2.new(relOf(cur), 0, 1, 0)
				onChange(cur)
			end
			minus.MouseButton1Click:Connect(function() apply(opts.step and opts.step(cur, -1) or (cur - 1)) end)
			plus.MouseButton1Click:Connect(function() apply(opts.step and opts.step(cur, 1) or (cur + 1)) end)

			local dragging = false
			local barBtn = Instance.new("TextButton")
			barBtn.Size = UDim2.new(1, 0, 1, 16)
			barBtn.Position = UDim2.new(0, 0, 0, -5)
			barBtn.BackgroundTransparency = 1
			barBtn.Text = ""
			barBtn.Parent = barBg
			barBtn.MouseButton1Down:Connect(function() dragging = true end)
			Util.Connect("Slider_" .. label, Services.UIS.InputEnded, function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1
					or inp.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			Util.Connect("SliderM_" .. label, Services.UIS.InputChanged, function(inp)
				if not dragging then return end
				if inp.UserInputType == Enum.UserInputType.MouseMovement
					or inp.UserInputType == Enum.UserInputType.Touch then
					local ax = barBg.AbsolutePosition.X
					local aw = barBg.AbsoluteSize.X
					if aw <= 0 then return end
					local rel = math.clamp((inp.Position.X - ax) / aw, 0, 1)
					if opts.log then apply(min * (max / min) ^ rel) else apply(min + rel * (max - min)) end
				end
			end)

			return { set = apply, get = function() return cur end }
		end

		function api:Label(txt, color)
			order = order + 1
			local l = Instance.new("TextLabel")
			l.Size = UDim2.new(1, 0, 0, 20)
			l.BackgroundColor3 = T.Panel
			l.BorderSizePixel = 0
			l.Text = txt
			l.TextColor3 = color or T.Sub
			l.TextSize = 11
			l.Font = Config.Font.Bold
			l.LayoutOrder = order
			l.Parent = page
			Util.Corner(l, 6)
			return l
		end

		function api:Row(btns)
			order = order + 1
			local f = Instance.new("Frame")
			f.Size = UDim2.new(1, 0, 0, 34)
			f.BackgroundTransparency = 1
			f.LayoutOrder = order
			f.Parent = page
			local x = 0
			local total = 0
			for _, b in ipairs(btns) do total = total + (b.w or 1) end
			local gap = 5
			local avail = P.Width - 20 - gap * (#btns - 1)
			for _, it in ipairs(btns) do
				local w = math.floor(avail * ((it.w or 1) / total))
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(0, w, 0, 34)
				b.Position = UDim2.new(0, x, 0, 0)
				b.BackgroundColor3 = it.c or T.Panel2
				b.Text = ""
				b.BorderSizePixel = 0
				b.AutoButtonColor = false
				b.Parent = f
				Util.Corner(b, 8)
				local l = Instance.new("TextLabel")
				l.Size = UDim2.new(1, it.k and -28 or -8, 1, 0)
				l.Position = UDim2.new(0, 8, 0, 0)
				l.BackgroundTransparency = 1
				l.Text = it.t
				l.TextColor3 = (it.c == T.Accent) and Color3.fromRGB(8, 12, 20) or T.Text
				l.TextSize = 11
				l.Font = Config.Font.Bold
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.Parent = b
				if it.k then
					local kb = Instance.new("TextLabel")
					kb.Size = UDim2.new(0, 18, 0, 16)
					kb.Position = UDim2.new(1, -22, 0.5, -8)
					kb.BackgroundColor3 = T.Panel3
					kb.Text = Util.KeyName(it.k)
					kb.TextColor3 = T.Accent
					kb.TextSize = 9
					kb.Font = Config.Font.Title
					kb.BorderSizePixel = 0
					kb.Parent = b
					Util.Corner(kb, 4)
				end
				b.MouseButton1Click:Connect(function() Util.Safe(it.f) end)
				-- true press-and-hold (mobile touch + mouse) untuk kontrol Bus/dll
				if it.hold then
					b.MouseButton1Down:Connect(function()
						pcall(it.hold, true)
					end)
					b.MouseButton1Up:Connect(function()
						pcall(it.hold, false)
					end)
					b.MouseLeave:Connect(function()
						pcall(it.hold, false)
					end)
				end
				x = x + w + gap
			end
		end

		return api
	end

	-- ===== PAGES CONTENT =====
	local KB = Config.Keybind

	-- ESP
	local esp = MakePage("ESP", "radar")
	esp:Section("ESP Systems")
	local tItemESP = esp:Toggle("Item ESP", "diamond", KB.ItemESP, false,
		function() return State.ItemESP end,
		function() State.ItemESP = true; ESP.StartLoop(); Notify("YOURSCRIPT", "Item ESP Enabled", T.Green) end,
		function() State.ItemESP = false; ESP.Clear("item"); ESPMaybeStop(); Notify("YOURSCRIPT", "Item ESP Disabled", T.Sub) end)
	local tMonESP = esp:Toggle("Monster ESP", "skull", KB.MonsterESP, false,
		function() return State.MonsterESP end,
		function() State.MonsterESP = true; ESP.StartLoop(); Notify("YOURSCRIPT", "Monster ESP Enabled", T.Green) end,
		function() State.MonsterESP = false; ESP.Clear("monster"); Notify("YOURSCRIPT", "Monster ESP Disabled", T.Sub) end)
	local tPlrESP = esp:Toggle("Player ESP", "user", KB.PlayerESP, false,
		function() return State.PlayerESP end,
		function() State.PlayerESP = true; ESP.StartLoop(); Notify("YOURSCRIPT", "Player ESP Enabled", T.Green) end,
		function() State.PlayerESP = false; ESP.Clear("player"); Notify("YOURSCRIPT", "Player ESP Disabled", T.Sub) end)
	esp:Section("ESP Options")
	esp:Toggle("Name ESP", "Aa", nil, true,
		function() return State.NameESP end,
		function() State.NameESP = true; Notify("YOURSCRIPT", "Name ESP On", T.Accent) end,
		function() State.NameESP = false; Notify("YOURSCRIPT", "Name ESP Off", T.Sub) end)
	esp:Toggle("Distance ESP", "arrows", nil, true,
		function() return State.DistESP end,
		function() State.DistESP = true; Notify("YOURSCRIPT", "Distance ESP On", T.Accent) end,
		function() State.DistESP = false; Notify("YOURSCRIPT", "Distance ESP Off", T.Sub) end)
	esp:Toggle("Chams", "square", nil, false,
		function() return State.Chams end,
		function() State.Chams = true; Notify("YOURSCRIPT", "Chams Enabled", T.Green) end,
		function() State.Chams = false; Notify("YOURSCRIPT", "Chams Disabled", T.Sub) end)
	esp:Toggle("Tracers", "arrow", nil, false,
		function() return State.Tracers end,
		function() State.Tracers = true; Notify("YOURSCRIPT", "Tracers Enabled", T.Green) end,
		function() State.Tracers = false; Notify("YOURSCRIPT", "Tracers Disabled", T.Sub) end)
	esp:Section("Lighting")
	local tFB = esp:Toggle("Fullbright", "sun", KB.Fullbright, false,
		function() return State.FullbrightOn end, Visual.EnableFullbright, Visual.DisableFullbright)
	local tNF = esp:Toggle("No Fog", "cloud", KB.NoFog, false,
		function() return State.NoFogOn end, Visual.EnableNoFog, Visual.DisableNoFog)

	-- MOVEMENT
	local mov = MakePage("Move", "chevrons")
	mov:Section("Movement")
	local tSpeed = mov:Toggle("Speed", "bolt", KB.Speed, false,
		function() return State.SpeedOn end, Movement.EnableSpeed, Movement.DisableSpeed)
	local speedSlider = mov:Slider("Speed Multiplier", Config.Movement.SpeedMin, Config.Movement.SpeedMax,
		Config.Movement.SpeedDefault, function(v) Movement.SetSpeedMul(v) end,
		{ log = true, round = 0.1, step = Movement.SpeedStep })
	local tFly = mov:Toggle("Fly", "plane", KB.Fly, false,
		function() return State.FlyOn end, Movement.EnableFly, Movement.DisableFly)
	local tNC = mov:Toggle("Noclip", "circle", KB.Noclip, false,
		function() return State.NoclipOn end, Movement.EnableNoclip, Movement.DisableNoclip)
	local tIJ = mov:Toggle("Infinite Jump", "up", KB.InfJump, false,
		function() return State.InfJumpOn end, Movement.EnableInfJump, Movement.DisableInfJump)

	-- TELEPORT
	local tp = MakePage("TP", "crosshair")
	tp:Section("Locations")
	tp:Button("TP Bunker", "home", KB.TPBunker, T.Panel2, Teleport.Bunker)
	tp:Button("TP Market / Six Mart", "home", KB.TPMarket, T.Panel2, Teleport.Market)
	tp:Button("TP Rare Room", "star", KB.TPRare, T.Panel2, Teleport.Rare)
	tp:Section("Position")
	tp:Row({
		{ t = "SAVE POS", k = KB.SavePos, w = 1, c = T.Panel2, f = Teleport.SavePos },
		{ t = "RETURN", k = KB.ReturnPos, w = 1, c = T.Panel2, f = Teleport.ReturnPos },
	})
	tp:Section("Player TP")
	tp:Row({
		{ t = "<", k = KB.PrevPlayer, w = 1, c = T.Panel2, f = Teleport.PrevPlayer },
		{ t = ">", k = KB.NextPlayer, w = 1, c = T.Panel2, f = Teleport.NextPlayer },
		{ t = "TP PLAYER", k = KB.TPPlayer, w = 2, c = T.Accent, f = function() Teleport.ToPlayer() end },
	})
	UI.TargetLbl = tp:Label("TARGET: -", T.Green)
	-- [MERGED] TP ke player by nama (fuzzy) dari dangerousnight
	tp:Box("TP Player by Name", "ketik nama pemain...", "", function(name)
		Teleport.ToPlayerByName(name)
	end)
	local tCTP = tp:Toggle("Click Teleport", "mouse", KB.ClickTP, false,
		function() return State.ClickTP end, Teleport.EnableClickTP, Teleport.DisableClickTP)

	-- FARMING (SIMPLE)
	local farm = MakePage("Farm", "tool")
	farm:Section("Item")
	UI.ItemLbl = farm:Label("ITEM: Lemari", T.Green)
	UI.ScanLbl = farm:Label("SCAN: -", T.Sub)

	farm:Row({
		{ t = "<", w = 1, c = T.Panel2, f = Teleport.PrevItem },
		{ t = ">", w = 1, c = T.Panel2, f = Teleport.NextItem },
	})

	farm:Box("Masukan nama item", "contoh: Wardrobe1", "", function(v)
		Teleport.RefreshItem(true)
		local r = Util.Root()
		-- cari item by name (cache + fallback full-scan)
		local found = false
		for _, o in ipairs(ScanCache.Items) do
			if o.Parent and string.find(o.Name:lower(), v:lower(), 1, true) then
				found = true
				break
			end
		end
		if not found then
			for _, o in ipairs(Services.WS:GetDescendants()) do
				local owner = Services.Players:GetPlayerFromCharacter(o)
				if not owner and (o:IsA("Model") or o:IsA("Tool")) then
					local p = o.Parent and o.Parent.Name == "Wyposazenie"
					if p or string.find(o.Name:lower(), v:lower(), 1, true) then
						found = true
						break
					end
				end
			end
			for _, o in ipairs(Services.WS:GetDescendants()) do
				if o.Parent and o.Parent.Name == "Wyposazenie" then
					found = true
				end
				if found then break end
				if o:IsA("Model") and string.find(o.Name:lower(), v:lower(), 1, true) then
					found = true
				end
			end
		end
		-- set ItemName ke hasil ketikan
		if found then
			State.ItemName = v
			Teleport.UpdateLabelsFromCache()
		else
			Notify("YOURSCRIPT", "Item belum terdeteksi — coba Refresh", Config.Theme.Orange)
		end
		State.AutoFarmItem = v
	end)

	farm:Row({
		{ t = "TP to Item", w = 1, c = T.Accent, f = function() Teleport.TPToItem() end },
		{ t = "Ambil terdekat", w = 1, c = T.Green, f = function() _G.SRF_GrabNearest() end },
	})
	farm:Row({
		{ t = "Ambil terpilih", w = 2, c = T.Green, f = Farming.GrabRemoteOne },
	})
	farm:Row({
		{ t = "TP-Ambil-Balik (1 klik)", w = 2, c = T.Green, f = function() Farming.TPGrabReturn() end },
	})
	farm:Toggle("Spam Item (item ditandai / pilihan)", "refresh", nil, false,
		function() return State.SpamItemOn end,
		Game.EnableSpamItem, Game.DisableSpamItem)
	farm:Toggle("Market Only", "home", nil, false,
		function() return State.MarketOnly end,
		function() State.MarketOnly = true; Notify("Market Only", "ON — spam hanya market + gudang langka", Config.Theme.Green) end,
		function() State.MarketOnly = false; Notify("Market Only", "OFF — semua area (kecuali bunker)", Config.Theme.Sub) end)
	farm:Button("Hapus semua tanda", "cross", nil, T.Panel2, function()
		ClearSpamMarks()
		Notify("Spam Marks", "Semua tanda dihapus", Config.Theme.Sub)
	end)
	farm:Section("Drop Points (Spam)")
	farm:Row({
		{ t = "+ DROP POINT", w = 1, c = T.Green, f = function() AddDropPoint() end },
		{ t = "CLEAR DROPS", w = 1, c = T.Orange, f = function() ClearDropPoints() end },
	})

	farm:Button("Refresh item", "refresh", nil, T.Panel2, function()
		Teleport.RefreshItem()
	end)
	-- Dua tombol sejajar: Daftar Item | Gudang Langka (mudah dilihat)
	farm:Row({
		{ t = "DAFTAR ITEM", w = 1, c = T.Purple, f = function()
			if UI._itemListGui and UI._itemListGui.Parent then
				UI._itemListGui:Destroy()
				UI._itemListGui = nil
				return
			end
			-- tutup rare popup kalau terbuka
			if UI._rareListGui and UI._rareListGui.Parent then
				UI._rareListGui:Destroy()
				UI._rareListGui = nil
			end
			local names, seen = {}, {}
			for _, o in ipairs(ScanCache.Items or {}) do
				if o and o.Parent and o.Name and not seen[o.Name] then
					seen[o.Name] = true
					table.insert(names, o.Name)
				end
			end
			local wy = Services.WS:FindFirstChild("Wyposazenie")
			if wy then
				for _, c in ipairs(wy:GetChildren()) do
					local nm = tostring(c.Name)
					if not nm:match("^%d+_Wyposazenie$") and (c:IsA("Model") or c:IsA("Tool")) and not seen[c.Name] then
						seen[c.Name] = true
						table.insert(names, c.Name)
					end
				end
			end
			table.sort(names)
			local pop = Instance.new("Frame")
			pop.Name = "ItemListPopup"
			pop.Size = UDim2.new(0, 240, 0, 320)
			pop.Position = UDim2.new(1, 8, 0, 40)
			pop.BackgroundColor3 = Config.Theme.Panel
			pop.BorderSizePixel = 0
			pop.ZIndex = 80
			pop.Parent = UI.Panel
			Util.Corner(pop, 10)
			Util.Stroke(pop, Config.Theme.Accent, 1, 0.4)
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -30, 0, 28)
			title.Position = UDim2.new(0, 8, 0, 4)
			title.BackgroundTransparency = 1
			title.Text = "DAFTAR ITEM (" .. #names .. ")"
			title.TextColor3 = Config.Theme.Accent
			title.TextSize = 12
			title.Font = Config.Font.Bold
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.ZIndex = 81
			title.Parent = pop
			local xc = Instance.new("TextButton")
			xc.Size = UDim2.new(0, 24, 0, 24)
			xc.Position = UDim2.new(1, -28, 0, 4)
			xc.BackgroundTransparency = 1
			xc.Text = "X"
			xc.TextColor3 = Config.Theme.Red
			xc.TextSize = 14
			xc.Font = Config.Font.Bold
			xc.ZIndex = 81
			xc.Parent = pop
			xc.MouseButton1Click:Connect(function() pop:Destroy(); UI._itemListGui = nil end)
			local search = Instance.new("TextBox")
			search.Size = UDim2.new(1, -16, 0, 26)
			search.Position = UDim2.new(0, 8, 0, 32)
			search.BackgroundColor3 = Config.Theme.Panel2
			search.Text = ""
			search.PlaceholderText = "cari..."
			search.PlaceholderColor3 = Config.Theme.Sub
			search.TextColor3 = Config.Theme.Text
			search.TextSize = 12
			search.Font = Config.Font.Bold
			search.ClearTextOnFocus = false
			search.ZIndex = 81
			search.Parent = pop
			Util.Corner(search, 6)
			local scroll = Instance.new("ScrollingFrame")
			scroll.Size = UDim2.new(1, -12, 1, -68)
			scroll.Position = UDim2.new(0, 6, 0, 64)
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 4
			scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			scroll.ZIndex = 81
			scroll.Parent = pop
			local lay = Instance.new("UIListLayout")
			lay.Padding = UDim.new(0, 3)
			lay.Parent = scroll
			local function rebuild(filter)
				for _, ch in ipairs(scroll:GetChildren()) do
					if ch:IsA("TextButton") then ch:Destroy() end
				end
				local f = string.lower(filter or "")
				local n = 0
				for _, name in ipairs(names) do
					if f == "" or string.find(string.lower(name), f, 1, true) then
						local marked = IsSpamMarked(name)
						local b = Instance.new("TextButton")
						b.Size = UDim2.new(1, -4, 0, 26)
						b.BackgroundColor3 = marked and Color3.fromRGB(30, 55, 40) or Config.Theme.Panel2
						b.Text = (marked and "  *  " or "  ") .. name
						b.TextColor3 = marked and Config.Theme.Green or Config.Theme.Text
						b.TextSize = 11
						b.Font = Config.Font.Bold
						b.TextXAlignment = Enum.TextXAlignment.Left
						b.BorderSizePixel = 0
						b.ZIndex = 82
						b.Parent = scroll
						Util.Corner(b, 6)
						b.MouseButton1Click:Connect(function()
							local on = ToggleSpamMark(name)
							State.ItemName = name
							State.AutoFarmItem = name
							pcall(Teleport.UpdateLabelsFromCache)
							b.Text = (on and "  *  " or "  ") .. name
							b.TextColor3 = on and Config.Theme.Green or Config.Theme.Text
							b.BackgroundColor3 = on and Color3.fromRGB(30, 55, 40) or Config.Theme.Panel2
							Notify(on and "★ Ditandai" or "Hapus tanda", name .. "  (" .. #GetSpamMarkList() .. " ditandai)", on and Config.Theme.Green or Config.Theme.Sub)
						end)
						n = n + 1
					end
				end
				scroll.CanvasSize = UDim2.new(0, 0, 0, n * 29)
			end
			rebuild("")
			local acc = 0
			search:GetPropertyChangedSignal("Text"):Connect(function()
				acc = acc + 1
				local a = acc
				task.delay(0.1, function()
					if a == acc and pop.Parent then rebuild(search.Text) end
				end)
			end)
			UI._itemListGui = pop
		end },
		{ t = "GUDANG LANGKA", w = 1, c = T.Yellow, f = function()
			if UI._rareListGui and UI._rareListGui.Parent then
				UI._rareListGui:Destroy()
				UI._rareListGui = nil
				return
			end
			if UI._itemListGui and UI._itemListGui.Parent then
				UI._itemListGui:Destroy()
				UI._itemListGui = nil
			end
			local rareNames = GetGudangLangkaNames()
			table.sort(rareNames)
			local pop = Instance.new("Frame")
			pop.Name = "RareItemListPopup"
			pop.Size = UDim2.new(0, 250, 0, 340)
			pop.Position = UDim2.new(1, 8, 0, 40)
			pop.BackgroundColor3 = Config.Theme.Panel
			pop.BorderSizePixel = 0
			pop.ZIndex = 90
			pop.Parent = UI.Gui or UI.Panel
			Util.Corner(pop, 10)
			Util.Stroke(pop, Config.Theme.Yellow, 2, 0.25)
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -30, 0, 28)
			title.Position = UDim2.new(0, 8, 0, 4)
			title.BackgroundTransparency = 1
			title.Text = "GUDANG LANGKA (" .. #rareNames .. ")"
			title.TextColor3 = Config.Theme.Yellow
			title.TextSize = 13
			title.Font = Config.Font.Bold
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.ZIndex = 91
			title.Parent = pop
			local xc = Instance.new("TextButton")
			xc.Size = UDim2.new(0, 24, 0, 24)
			xc.Position = UDim2.new(1, -28, 0, 4)
			xc.BackgroundTransparency = 1
			xc.Text = "X"
			xc.TextColor3 = Config.Theme.Red
			xc.TextSize = 14
			xc.Font = Config.Font.Bold
			xc.ZIndex = 91
			xc.Parent = pop
			xc.MouseButton1Click:Connect(function() pop:Destroy(); UI._rareListGui = nil end)
			local search = Instance.new("TextBox")
			search.Size = UDim2.new(1, -16, 0, 26)
			search.Position = UDim2.new(0, 8, 0, 34)
			search.BackgroundColor3 = Config.Theme.Panel2
			search.Text = ""
			search.PlaceholderText = "cari di gudang langka..."
			search.PlaceholderColor3 = Config.Theme.Sub
			search.TextColor3 = Config.Theme.Text
			search.TextSize = 12
			search.Font = Config.Font.Bold
			search.ClearTextOnFocus = false
			search.ZIndex = 91
			search.Parent = pop
			Util.Corner(search, 6)
			local scroll = Instance.new("ScrollingFrame")
			scroll.Size = UDim2.new(1, -12, 1, -70)
			scroll.Position = UDim2.new(0, 6, 0, 66)
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 4
			scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			scroll.ZIndex = 91
			scroll.Parent = pop
			local lay = Instance.new("UIListLayout")
			lay.Padding = UDim.new(0, 3)
			lay.Parent = scroll
			local function rebuild(filter)
				for _, ch in ipairs(scroll:GetChildren()) do
					if ch:IsA("TextButton") or ch:IsA("TextLabel") then ch:Destroy() end
				end
				local f = string.lower(filter or "")
				local n = 0
				if #rareNames == 0 then
					local empty = Instance.new("TextLabel")
					empty.Size = UDim2.new(1, -4, 0, 90)
					empty.BackgroundTransparency = 1
					empty.Text = "Belum terdeteksi.\nPergi ke gudang langka,\ntekan Refresh Item,\nlalu buka lagi.\n\nAtau jalankan SCANNER."
					empty.TextColor3 = Config.Theme.Sub
					empty.TextSize = 11
					empty.Font = Config.Font.Reg
					empty.TextWrapped = true
					empty.ZIndex = 92
					empty.Parent = scroll
					n = 3
				else
					for _, name in ipairs(rareNames) do
						if f == "" or string.find(string.lower(name), f, 1, true) then
							local marked = IsSpamMarked(name)
							local b = Instance.new("TextButton")
							b.Size = UDim2.new(1, -4, 0, 28)
							b.BackgroundColor3 = marked and Color3.fromRGB(30, 55, 40) or Color3.fromRGB(55, 42, 20)
							b.Text = (marked and "  *  " or "  *  ") .. name
							b.TextColor3 = marked and Config.Theme.Green or Config.Theme.Yellow
							b.TextSize = 12
							b.Font = Config.Font.Bold
							b.TextXAlignment = Enum.TextXAlignment.Left
							b.BorderSizePixel = 0
							b.ZIndex = 92
							b.Parent = scroll
							Util.Corner(b, 6)
							b.MouseButton1Click:Connect(function()
								local on = ToggleSpamMark(name)
								State.ItemName = name
								State.AutoFarmItem = name
								pcall(Teleport.UpdateLabelsFromCache)
								b.Text = (on and "  *  " or "  *  ") .. name
								b.TextColor3 = on and Config.Theme.Green or Config.Theme.Yellow
								b.BackgroundColor3 = on and Color3.fromRGB(30, 55, 40) or Color3.fromRGB(55, 42, 20)
								Notify(on and "★ Ditandai" or "Hapus tanda", name .. "  (" .. #GetSpamMarkList() .. " ditandai)", on and Config.Theme.Green or Config.Theme.Sub)
							end)
							n = n + 1
						end
					end
				end
				scroll.CanvasSize = UDim2.new(0, 0, 0, n * 31 + 8)
			end
			rebuild("")
			local acc = 0
			search:GetPropertyChangedSignal("Text"):Connect(function()
				acc = acc + 1
				local a = acc
				task.delay(0.1, function()
					if a == acc and pop.Parent then rebuild(search.Text) end
				end)
			end)
			UI._rareListGui = pop
			Notify("Gudang Langka", #rareNames .. " item", Config.Theme.Yellow)
		end },
	})

	farm:Section("Monster Spawn TP")
	UI.SpawnLbl = farm:Label("SPAWN: -", T.Orange)
	farm:Row({
		{ t = "◀ PREV", k = nil, w = 1, c = T.Panel2, f = Teleport.PrevSpawn },
		{ t = "TP SPAWN", k = nil, w = 2, c = T.Accent, f = function() Teleport.ToSpawn() end },
		{ t = "NEXT ▶", k = nil, w = 1, c = T.Panel2, f = Teleport.NextSpawn },
	})
	farm:Button("TP Catcher Zone", "skull", nil, T.Red, function()
		for i, sp in ipairs(State._spawnDB or {}) do
			if sp.name:find("Catcher") then
				Teleport.ToSpawn(i)
				return
			end
		end
		Notify("Spawn", "Catcher zone tidak ada di DB", T.Orange)
	end)
	farm:Section("Position")
	farm:Button("Save position", "pin", KB.SavePos, T.Panel2, Teleport.SavePos)


	-- MONSTER
	local mon = MakePage("Mob", "skull")
	mon:Section("Detection")
	local tAlert = mon:Toggle("Monster Alert", "warn", nil, false,
		function() return State.MonsterAlert end, Monster.EnableAlert, Monster.DisableAlert)
	local tMTrack = mon:Toggle("Monster Tracker", "radar", nil, false,
		function() return State.MonsterTracker end, Monster.EnableTracker, Monster.DisableTracker)
	UI.TrackerLbl = mon:Label("MONSTER: -", T.Sub)
	mon:Section("Control")
	local tCage = mon:Toggle("Cage Monster", "hex", KB.CageMonster, false,
		function() return State.CageOn end, Monster.EnableCage, Monster.DisableCage)
	local tACage = mon:Toggle("Auto Cage Monster", "refresh", KB.AutoCage, false,
		function() return State.AutoCage end, Monster.EnableAutoCage, Monster.DisableAutoCage)
	local tFrz = mon:Toggle("Freeze Monster", "snow", KB.FreezeMonster, false,
		function() return State.FreezeOn end, Monster.EnableFreeze, Monster.DisableFreeze)

	-- VISUAL
	local vis = MakePage("Visual", "eye")
	vis:Section("World")
	vis:Toggle("Remove Grass", "leaf", nil, false,
		function() return State.NoGrass end, Visual.EnableNoGrass, Visual.DisableNoGrass)
	vis:Toggle("Remove Shadows", "moon", nil, false,
		function() return State.NoShadow end, Visual.EnableNoShadow, Visual.DisableNoShadow)
	vis:Section("Graphics")
	vis:Toggle("Ultra HD (Maxed Out)", "sparkle", nil, false,
		function() return State.UltraHD end, Visual.EnableUltraHD, Visual.DisableUltraHD)
	vis:Section("Camera")
	vis:Toggle("Camera Zoom Unlock", "search", nil, false,
		function() return State.ZoomUnlock end, Visual.EnableZoomUnlock, Visual.DisableZoomUnlock)
	vis:Toggle("Free Camera", "eye", nil, false,
		function() return State.FreeCam end, Visual.EnableFreeCam, Visual.DisableFreeCam)
	vis:Section("Cuaca (Tahap pengembangan)")
	vis:Button("Hujan", "lock", nil, Color3.fromRGB(24, 24, 28), function()
		Notify("Tahap pengembangan", "Hujan masih dikunci", Config.Theme.Sub)
	end)
	vis:Button("Banjir", "lock", nil, Color3.fromRGB(24, 24, 28), function()
		Notify("Tahap pengembangan", "Banjir masih dikunci", Config.Theme.Sub)
	end)
	vis:Button("Salju", "lock", nil, Color3.fromRGB(24, 24, 28), function()
		Notify("Tahap pengembangan", "Salju masih dikunci", Config.Theme.Sub)
	end)

	-- PLAYER
	local plrP = MakePage("Player", "user")
	plrP:Section("Target")
	plrP:Row({
		{ t = "< PREV", k = KB.PrevPlayer, w = 1, c = T.Panel2, f = Teleport.PrevPlayer },
		{ t = "NEXT >", k = KB.NextPlayer, w = 1, c = T.Panel2, f = Teleport.NextPlayer },
	})
	UI.TargetLbl2 = plrP:Label("TARGET: -", T.Green)
	local oldRefresh = Teleport.RefreshTarget
	function Teleport.RefreshTarget()
		oldRefresh()
		local txt = UI.TargetLbl and UI.TargetLbl.Text or "TARGET: -"
		if UI.TargetLbl2 then UI.TargetLbl2.Text = txt end
		if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = txt end
		if UI.TrollTargetLbl then UI.TrollTargetLbl.Text = txt end
	end
	plrP:Box("Pilih Player (nama)", "ketik nama pemain...", "", function(name)
		name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then Notify("Player", "Ketik nama player dulu", T.Orange) return end
		local found, lname = nil, string.lower(name)
		for _, p in ipairs(Services.Players:GetPlayers()) do
			if p ~= LP and (string.find(string.lower(p.Name), lname, 1, true)
				or string.find(string.lower(p.DisplayName or ""), lname, 1, true)) then
				found = p; break
			end
		end
		if not found then Notify("Player", "Player tidak ditemukan: " .. name, T.Orange) return end
		State.TargetPlayer, State.Target = found, found
		local list = Util.GetPlayers()
		for i, p in ipairs(list) do if p == found then State.TargetIdx = i; break end end
		pcall(Teleport.RefreshTarget)
		State.TargetPlayer, State.Target = found, found
		local displayName = found.DisplayName or found.Name
		if UI.TargetLbl2 then UI.TargetLbl2.Text = "TARGET: " .. displayName end
		if UI.TargetLbl then UI.TargetLbl.Text = "TARGET: " .. displayName end
		Notify("Player", "Target: " .. displayName, T.Green)
	end)
	plrP:Section("Actions")
	local tSpec = plrP:Toggle("Spectate Player", "eye", KB.Spectate, false,
		function() return State.SpectateOn end, PlayerMod.EnableSpectate, PlayerMod.DisableSpectate)
	local tPTrack = plrP:Toggle("Player Tracker", "radar", nil, false,
		function() return State.PlayerTracker end, PlayerMod.EnableTracker, PlayerMod.DisableTracker)
	UI.PTrackerLbl = plrP:Label("PLAYER: -", T.Sub)
	plrP:Button("TP to Target", "crosshair", KB.TPPlayer, T.Accent, function() Teleport.ToPlayer() end)
	plrP:Section("Grief")
	plrP:Toggle("Explosion Spam", "sparkle", nil, false,
		function() return State.GriefExplosion end, Grief.ToggleExplosion, Grief.ToggleExplosion)
	plrP:Toggle("Particle Spam", "sparkle", nil, false,
		function() return State.GriefParticle end, Grief.ToggleParticle, Grief.ToggleParticle)
	plrP:Toggle("Decal Spam", "image", nil, false,
		function() return State.GriefDecal end, Grief.ToggleDecal, Grief.ToggleDecal)
	plrP:Toggle("Chat Spam", "chat", nil, false,
		function() return State.GriefChat end, Grief.ToggleChat, Grief.ToggleChat)

	-- UTILITY
	local utilP = MakePage("Util", "gear")
	utilP:Section("Session")
	local tAFK = utilP:Toggle("Anti AFK", "clock", KB.AntiAFK, false,
		function() return State.AntiAFK end, Utility.EnableAntiAFK, Utility.DisableAntiAFK)
	local tFPS = utilP:Toggle("FPS Boost", "rocket", KB.FPSBoost, false,
		function() return State.FPSBoost end, Utility.EnableFPSBoost, Utility.DisableFPSBoost)
	utilP:Section("Server")
	utilP:Button("Rejoin Server", "refresh", KB.Rejoin, T.Panel2, Utility.Rejoin)
	utilP:Button("Server Hop", "refresh", KB.ServerHop, T.Panel2, Utility.ServerHop)
	-- [BARU] join ke server user manapun via username (masukin username → Enter/Tombol)
	local joinBox = utilP:Box("Join User Server", "username, tekan Enter", "", function(v)
		Utility.JoinUserServer(v)
	end)
	utilP:Button("Join User", "◈", nil, T.Accent, function()
		if joinBox and joinBox.Text ~= "" then
			Utility.JoinUserServer(joinBox.Text)
		else
			Notify("ServerHop", "Masukan username dulu!", Config.Theme.Accent)
		end
	end)

	utilP:Section("Panel")
	utilP:Button("Destroy Panel (Cleanup)", "cross", nil, T.Red, function()
		CleanupAll()
	end)

	-- [MERGED] GAME — fitur dari dangerousnight.lua
	local gm = MakePage("Game", "pad")
	gm:Section("Food")
	gm:Button("Collect All Food", "food", nil, T.Panel2, Game.CollectAllFood)
	gm:Button("Drop All Food", "skull", nil, T.Panel2, Game.DropAllFood)
	gm:Box("WalkSpeed (Direct)", "contoh: 25", "", function(v)
		Game.SetWalkSpeedDirect(v)
	end)
	gm:Section("Spam Item")
	gm:Label("Atur target + toggle di tab Farm.", T.Sub)
	gm:Section("Audio")
	local tSound = gm:Toggle("Sound Spam", "sound", nil, false,
		function() return State.SoundSpam end,
		Game.EnableSoundSpam, Game.DisableSoundSpam)

	local ex = MakePage("Extra", "sparkle")
	ex:Section("Visual")
	ex:Toggle("Xray", "◉", nil, false, function() return State.XrayOn end, Extra.EnableXray, Extra.DisableXray)
	ex:Toggle("Invisible", "mask", nil, false, function() return State.InvisibleOn end, Extra.EnableInvisible, Extra.DisableInvisible)
	ex:Toggle("Character Light", "light", nil, false, function() return State.CharLightOn end, Extra.EnableCharLight, Extra.DisableCharLight)
	ex:Section("Movement+")
	ex:Slider("Fly Speed", 10, 300, State.FlySpeedVal or 80, function(v) Extra.SetFlySpeed(v) end)
	ex:Box("Jump Power", "50", "", function(v) Extra.SetJumpPower(v) end)
	ex:Box("Gravity", "196.2", "", function(v) Extra.SetGravity(v) end)
	ex:Toggle("No Gravity", "cloud", nil, false, function() return State.NoGravityOn end, Extra.EnableNoGravity, Extra.DisableNoGravity)
	ex:Toggle("Float", "▭", nil, false, function() return State.FloatOn end, Extra.EnableFloat, Extra.DisableFloat)
	ex:Toggle("Spin", "↻", nil, false, function() return State.SpinOn end, Extra.EnableSpin, Extra.DisableSpin)
	ex:Toggle("GodMode (client)", "heart", nil, false, function() return State.GodModeOn end, Extra.EnableGodMode, Extra.DisableGodMode)
	ex:Button("Platform", "▬", nil, T.Panel2, Extra.Platform)
	ex:Button("Self Fling", "sparkle", nil, T.Orange, Extra.SelfFling)
	ex:Section("Tools / Prompt")
	ex:Toggle("Anti Fling", "shield", nil, false, function() return State.AntiFlingOn end, Extra.EnableAntiFling, Extra.DisableAntiFling)
	ex:Row({{ t="GRAB TOOLS", w=1, c=T.Green, f=Extra.GrabTools },{ t="DROP TOOLS", w=1, c=T.Orange, f=Extra.DropTools }})
	ex:Button("Equip All", "swords", nil, T.Panel2, Extra.EquipAllTools)
	ex:Button("Fire All Prompts", "bolt", nil, T.Accent, Extra.FireAllPrompts)
	ex:Button("Fire ClickDetectors", "mouse", nil, T.Panel2, Extra.FireAllClickDetectors)
	ex:Toggle("Instant Prompt", "clock", nil, false, function() return State.InstantPromptOn end, Extra.EnableInstantPrompt, Extra.DisableInstantPrompt)
	ex:Section("Waypoint")
	ex:Row({{ t="SAVE WP", w=1, c=T.Accent, f=Extra.SaveWaypoint },{ t="TP WP", w=1, c=T.Green, f=Extra.TPWaypoint }})
	ex:Row({{ t="◀ WP", w=1, c=T.Panel2, f=Extra.PrevWaypoint },{ t="WP ▶", w=1, c=T.Panel2, f=Extra.NextWaypoint }})
	ex:Button("Clear WP", "cross", nil, T.Red, Extra.ClearWaypoints)
	ex:Button("Copy Coords", "pin", nil, T.Panel2, Extra.CopyCoords)
	ex:Section("Hint / Word")
	ex:Box("Hint Text", "text...", "", function(v) Extra.ShowHint(v) end)
	ex:Button("Clear Hint", "cross", nil, T.Panel2, Extra.ClearHint)
	ex:Box("Reply Word (sambung kata)", "jeruk", "", function(v) Extra.ReplyWord(v) end)
	ex:Section("NPC Control")
	ex:Toggle("Ctrl+Click NPC", "pad", nil, false, function() return State.NPCControlOn end, Extra.EnableNPCClick, Extra.DisableNPCClick)
	ex:Button("Nearest NPC", "arrow", nil, T.Accent, Extra.ControlNearestNPC)
	ex:Button("Restore Character", "back", nil, T.Panel2, Extra.RestoreOriginalCharacter)
	ex:Section("Avatar (No Respawn)")
	UI.AvLbl = ex:Label("AVATAR: -", T.Green)
	ex:Row({{ t="LOAD OUTFITS", w=1, c=T.Accent, f=Extra.AvLoad },{ t="APPLY", w=1, c=T.Green, f=Extra.AvApplySelected }})
	ex:Row({{ t="◀ OUTFIT", w=1, c=T.Panel2, f=Extra.AvPrev },{ t="OUTFIT ▶", w=1, c=T.Panel2, f=Extra.AvNext }})
	ex:Box("Avatar from Username / ID", "username or UserId", "", function(v) Extra.AvApplyUser(v) end)
	ex:Button("Respawn In Place", "back", nil, T.Orange, Extra.RespawnHere)

	local cb = MakePage("Combat", "swords")
	-- TARGET PLAYER (paling atas — semua fitur combat pakai ini)
	cb:Section("Target Player")
	UI.CombatTargetLbl = cb:Label("TARGET: (belum dipilih)", T.Green)
	cb:Row({
		{ t = "< PREV", w = 1, c = T.Panel2, f = function()
			Teleport.PrevPlayer()
			local t = State.TargetPlayer or State.Target
			if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = t and ("TARGET: "..(t.DisplayName or t.Name)) or "TARGET: -" end
		end },
		{ t = "NEXT >", w = 1, c = T.Panel2, f = function()
			Teleport.NextPlayer()
			local t = State.TargetPlayer or State.Target
			if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = t and ("TARGET: "..(t.DisplayName or t.Name)) or "TARGET: -" end
		end },
	})
	cb:Box("Cari / pilih nama player", "ketik nama...", "", function(name)
		name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then return end
		local found, lname = nil, string.lower(name)
		for _, p in ipairs(Services.Players:GetPlayers()) do
			if p ~= LP and (string.find(string.lower(p.Name), lname, 1, true)
				or string.find(string.lower(p.DisplayName or ""), lname, 1, true)) then
				found = p; break
			end
		end
		if not found then Notify("Combat", "Tidak ketemu: "..name, T.Orange) return end
		State.TargetPlayer, State.Target = found, found
		local list = Util.GetPlayers()
		for i, p in ipairs(list) do if p == found then State.TargetIdx = i; break end end
		pcall(Teleport.RefreshTarget)
		if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = "TARGET: "..(found.DisplayName or found.Name) end
		if UI.TargetLbl then UI.TargetLbl.Text = "TARGET: "..(found.DisplayName or found.Name) end
		if UI.TargetLbl2 then UI.TargetLbl2.Text = "TARGET: "..(found.DisplayName or found.Name) end
		Notify("Combat", "Target: "..found.Name, T.Green)
	end)
	cb:Row({{ t="COPY ID", w=1, c=T.Panel2, f=Extra.CopyPlayerId },{ t="COPY NAME", w=1, c=T.Panel2, f=Extra.CopyPlayerName }})
	cb:Section("Aimbot")
	cb:Toggle("Aimbot", "crosshair", nil, false, function() return State.AimbotOn end, Extra.EnableAimbot, Extra.DisableAimbot)
	cb:Slider("FOV", 50, 500, State.AimbotFOV or 180, function(v) State.AimbotFOV=v end)
	cb:Slider("Smooth", 0.05, 1, State.AimbotSmooth or 0.25, function(v) State.AimbotSmooth=v end)
	cb:Section("Hitbox / Reach")
	cb:Toggle("Hitbox Expand", "square", nil, false, function() return State.HitboxOn end, Extra.EnableHitbox, Extra.DisableHitbox)
	cb:Slider("Hitbox Size", 2, 30, State.HitboxSize or 8, function(v) State.HitboxSize=v end)
	cb:Toggle("Reach", "arrow", nil, false, function() return State.ReachOn end, Extra.EnableReach, Extra.DisableReach)
	cb:Slider("Reach Size", 2, 40, State.ReachSize or 12, function(v) State.ReachSize=v end)
	cb:Section("Fling (mengenai lawan)")
	cb:Toggle("Spin Fling", "refresh", nil, false, function() return State.SpinFlingOn end, Extra.EnableSpinFling, Extra.DisableSpinFling)
	cb:Toggle("Hidden Fling", "skull", nil, false, function() return State.HiddenFlingOn end, Extra.EnableHiddenFling, Extra.DisableHiddenFling)
	cb:Toggle("Touch Fling", "hand", nil, false, function() return State.TouchFlingOn end, Extra.EnableTouchFling, Extra.DisableTouchFling)
	cb:Slider("Fling Power", 1, 10, State.TouchFlingPower or 5, function(v) State.TouchFlingPower=v end)
	cb:Toggle("Click Fling", "sparkle", nil, false, function() return State.ClickFlingOn end, Extra.EnableClickFling, Extra.DisableClickFling)
	cb:Toggle("Orbit Target", "refresh", nil, false, function() return State.OrbitOn end, Extra.EnableOrbit, Extra.DisableOrbit)
	cb:Slider("Orbit Radius", 2, 30, State.OrbitRadius or 8, function(v) State.OrbitRadius=v end)
	cb:Toggle("FakeLag", "radar", nil, false, function() return State.FakeLagOn end, Extra.EnableFakeLag, Extra.DisableFakeLag)
	cb:Toggle("Stalk", "eye", nil, false, function() return State.StalkOn end, Extra.EnableStalk, Extra.DisableStalk)
	cb:Toggle("Stare", "radar", nil, false, function() return State.StareOn end, Extra.EnableStare, Extra.DisableStare)
	cb:Section("Mesh troll")
	cb:Row({
		{ t="DICK", w=1, c=T.Purple, f=function() Extra.MeshTroll("dick") end },
		{ t="ASS", w=1, c=T.Purple, f=function() Extra.MeshTroll("ass") end },
		{ t="TITS", w=1, c=T.Purple, f=function() Extra.MeshTroll("tits") end },
	})
	cb:Button("Clear Mesh", "cross", nil, T.Red, Extra.ClearMeshTroll)

	local ld = MakePage("Load", "box")
	ld:Section("External loaders")
	ld:Button("Load Dex Explorer", "leaf", nil, T.Accent, Extra.LoadDex)
	ld:Button("Load RemoteSpy", "radar", nil, T.Accent, Extra.LoadRemoteSpy)
	ld:Button("Load Infinite Yield", "infinity", nil, T.Green, Extra.LoadIY)
	ld:Button("Load Grab Tool", "hand", nil, T.Orange, Extra.LoadGrabTool)
	ld:Label("Crasher server/client orang lain: tidak ditambah.", T.Orange)

	-- Menu utama: toggle ringkas untuk semua fitur tambahan.
	-- TROLL tab (attach + magnetize + target list)
	local tr = MakePage("Troll", "mask")
	tr:Section("Daftar Player")
	UI.TrollTargetLbl = tr:Label("TARGET: (belum dipilih)", T.Green)
	tr:Row({
		{ t = "< PREV", w = 1, c = T.Panel2, f = function()
			Teleport.PrevPlayer()
			local t = State.TargetPlayer or State.Target
			local txt = t and ("TARGET: "..(t.DisplayName or t.Name)) or "TARGET: -"
			if UI.TrollTargetLbl then UI.TrollTargetLbl.Text = txt end
			if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = txt end
		end },
		{ t = "NEXT >", w = 1, c = T.Panel2, f = function()
			Teleport.NextPlayer()
			local t = State.TargetPlayer or State.Target
			local txt = t and ("TARGET: "..(t.DisplayName or t.Name)) or "TARGET: -"
			if UI.TrollTargetLbl then UI.TrollTargetLbl.Text = txt end
			if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = txt end
		end },
	})
	tr:Box("Cari / daftar player", "ketik nama...", "", function(name)
		name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then return end
		local found, lname = nil, string.lower(name)
		for _, p in ipairs(Services.Players:GetPlayers()) do
			if p ~= LP and (string.find(string.lower(p.Name), lname, 1, true)
				or string.find(string.lower(p.DisplayName or ""), lname, 1, true)) then
				found = p; break
			end
		end
		if not found then Notify("Troll", "Tidak ketemu: "..name, T.Orange) return end
		State.TargetPlayer, State.Target = found, found
		local list = Util.GetPlayers()
		for i, p in ipairs(list) do if p == found then State.TargetIdx = i; break end end
		pcall(Teleport.RefreshTarget)
		local displayName = found.DisplayName or found.Name
		if UI.TrollTargetLbl then UI.TrollTargetLbl.Text = "TARGET: "..displayName end
		if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = "TARGET: "..displayName end
		if UI.TargetLbl then UI.TargetLbl.Text = "TARGET: "..displayName end
		if UI.TargetLbl2 then UI.TargetLbl2.Text = "TARGET: "..displayName end
		Notify("Troll", "Target: "..displayName, T.Green)
	end)
	tr:Section("Attach (on/off)")
	tr:Toggle("Backpack", "box", nil, false,
		function() return State.AttachOn and State.AttachMode=="backpack" end,
		function() Extra.StartAttach("backpack") end,
		function() if State.AttachMode=="backpack" then Extra.StopAttach() end end)
	tr:Toggle("Bang", "bolt", nil, false,
		function() return State.AttachOn and State.AttachMode=="bang" end,
		function() Extra.StartAttach("bang") end,
		function() if State.AttachMode=="bang" then Extra.StopAttach() end end)
	tr:Toggle("Facebang", "mask", nil, false,
		function() return State.AttachOn and State.AttachMode=="facebang" end,
		function() Extra.StartAttach("facebang") end,
		function() if State.AttachMode=="facebang" then Extra.StopAttach() end end)
	tr:Toggle("Headsit", "user", nil, false,
		function() return State.AttachOn and State.AttachMode=="headsit" end,
		function() Extra.StartAttach("headsit") end,
		function() if State.AttachMode=="headsit" then Extra.StopAttach() end end)
	tr:Toggle("Shouldersit", "user", nil, false,
		function() return State.AttachOn and State.AttachMode=="shouldersit" end,
		function() Extra.StartAttach("shouldersit") end,
		function() if State.AttachMode=="shouldersit" then Extra.StopAttach() end end)
	tr:Toggle("Carpet", "square", nil, false,
		function() return State.AttachOn and State.AttachMode=="carpet" end,
		function() Extra.StartAttach("carpet") end,
		function() if State.AttachMode=="carpet" then Extra.StopAttach() end end)
	tr:Section("Magnetize")
	tr:Box("Magnetize Username", "username", "", function(v) State.MagnetizeTarget = tostring(v or "") end)
	tr:Toggle("Magnetize", "pin", nil, false, function() return State.MagnetizeOn end,
		function() Extra.EnableMagnetize(State.MagnetizeTarget) end, Extra.DisableMagnetize)


	do
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

local rad, deg, rnd = math.rad, math.deg, math.random
local sin, cos, pi, abs, max, min = math.sin, math.cos, math.pi, math.abs, math.max, math.min
local sqrt, exp, atan2, floor, acos = math.sqrt, math.exp, math.atan2, math.floor, math.acos
local V3, CF, ANG = Vector3.new, CFrame.new, CFrame.Angles
local C = Color3.fromRGB
local IDENT = CF()
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local MAT = Enum.Material
local G = V3(0, -196.2, 0)

local Hub = { baseShake = 0 }
local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local function rr(a) return (rnd() * 2 - 1) * a end
local function clamp(x, a, b) return math.clamp(x, a, b) end
local function lerp(a, b, t) return a + (b - a) * t end
local function smooth(t) t = clamp(t, 0, 1) return t * t * (3 - 2 * t) end
local function damp(k, dt) return 1 - exp(-k * dt) end
local function flat(v) return V3(v.X, 0, v.Z) end
local function wrapAng(x) return (x + pi) % (2 * pi) - pi end
local function shade(c, f) return c:Lerp(Color3.new(0, 0, 0), f) end
local function tint(c, f) return c:Lerp(Color3.new(1, 1, 1), f) end

-- ===== folder efek + raycast tanah =====
local fxRoot = Instance.new("Folder")
fxRoot.Name = "SujudHubFX"
fxRoot.Parent = workspace

local rayP = RaycastParams.new()
rayP.FilterType = Enum.RaycastFilterType.Exclude
local function groundAt(x, z, fromY, default)
    local f = { fxRoot }
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then f[#f + 1] = p.Character end
    end
    rayP.FilterDescendantsInstances = f
    local r = workspace:Raycast(V3(x, fromY, z), V3(0, -800, 0), rayP)
    return r and r.Position.Y or default
end

local function fxPart(parent, size, color, mat, shape, cf)
    local p = Instance.new("Part")
    p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
    p.Size, p.Color = size, color
    p.Material = mat or MAT.SmoothPlastic
    if shape then p.Shape = shape end
    if cf then p.CFrame = cf end
    p.Parent = parent
    return p
end

-- ===== guncangan kamera =====
local shake = 0
local function addShake(a) shake = min(10, shake + a) end
RS:BindToRenderStep("SujudHubShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local amp = shake + Hub.baseShake
    shake = shake * exp(-dt * 2.5)
    if amp < 0.02 then return end
    local c = workspace.CurrentCamera
    if c then
        c.CFrame = c.CFrame * ANG(rr(amp * 0.004), rr(amp * 0.004), rr(amp * 0.002))
            * CF(rr(amp * 0.03), rr(amp * 0.03), 0)
    end
end)

-- ===== efek bersama: ledakan, percikan, debu =====
local FX = {}
local expls, bits = {}, {}

local function emitter(parent, props)
    local e = Instance.new("ParticleEmitter")
    e.Rate = 0
    for k, v in pairs(props) do e[k] = v end
    e.Parent = parent
    return e
end

function FX.explode(pos, s)
    if #expls >= 14 then return end
    local fire = fxPart(fxRoot, V3(3, 3, 3), C(255, 150, 40), MAT.Neon, BALL, CF(pos))
    local smoke = fxPart(fxRoot, V3(4, 4, 4), C(62, 60, 62), nil, BALL, CF(pos))
    smoke.Transparency = 0.5
    local light = Instance.new("PointLight")
    light.Color, light.Brightness, light.Range = C(255, 160, 60), 7, 30 + 20 * s
    light.Parent = fire
    local ring = fxPart(fxRoot, V3(.3, 3, 3), C(232, 218, 196), nil, CYL,
        CF(pos.X, pos.Y + 0.3, pos.Z) * ANG(0, 0, rad(90)))
    ring.Transparency = 0.5
    local debris = {}
    for _ = 1, 8 do
        local sz = 0.3 + rnd() * 0.6
        local dp = fxPart(fxRoot, V3(sz, sz, sz), C(88, 68, 48), MAT.Slate, nil, CF(pos))
        debris[#debris + 1] = { p = dp, v = V3(rr(20), 30 + rnd() * 32, rr(20)) * min(s, 1.5) }
    end
    local em = fxPart(fxRoot, V3(1, 1, 1), C(0, 0, 0), nil, nil, CF(pos + V3(0, 1, 0)))
    em.Transparency = 1
    local sm = emitter(em, { Lifetime = NumberRange.new(1.4, 2.4), Speed = NumberRange.new(4, 14 * s + 4),
        SpreadAngle = Vector2.new(180, 180), Color = ColorSequence.new(C(80, 76, 74)),
        Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3 * s + 1), NumberSequenceKeypoint.new(1, 11 * s + 3) }),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }),
        Acceleration = V3(0, 6, 0), RotSpeed = NumberRange.new(-60, 60) })
    sm:Emit(14)
    local eb = emitter(em, { Lifetime = NumberRange.new(0.5, 1.2), Speed = NumberRange.new(18, 46),
        SpreadAngle = Vector2.new(180, 180), Color = ColorSequence.new(C(255, 170, 60), C(220, 60, 20)),
        LightEmission = 1, Size = NumberSequence.new(0.35, 0), Acceleration = V3(0, -70, 0),
        Transparency = NumberSequence.new(0, 1) })
    eb:Emit(16)
    expls[#expls + 1] = { fire = fire, smoke = smoke, light = light, ring = ring, debris = debris, em = em,
        pos = pos, t = 0, s = s }
    local cam = workspace.CurrentCamera
    if cam then
        local d = (cam.CFrame.Position - pos).Magnitude
        addShake(clamp((1 - d / 500) * s * 4, 0, 5))
    end
end

function FX.spark(pos)
    if #bits >= 50 then return end
    local p = fxPart(fxRoot, V3(.7, .7, .7), C(255, 220, 120), MAT.Neon, BALL, CF(pos))
    bits[#bits + 1] = { p = p, t = 0, pos = pos, life = 0.07 }
end

function FX.dust(pos, scale, color)
    if #bits >= 50 then return end
    local p = fxPart(fxRoot, V3(1, 1, 1), color or C(125, 105, 80), nil, BALL, CF(pos))
    p.Transparency = 0.45
    bits[#bits + 1] = { p = p, t = 0, pos = pos, dust = true, s = scale or 1, life = 0.7 }
end

function FX.update(dt)
    for i = #expls, 1, -1 do
        local e = expls[i]
        e.t = e.t + dt
        if e.t >= 2.6 then
            e.em:Destroy()
            table.remove(expls, i)
        elseif e.t >= 1.4 then
            if not e.done then
                e.done = true
                e.fire:Destroy() e.smoke:Destroy() e.ring:Destroy()
                for _, d in ipairs(e.debris) do d.p:Destroy() end
            end
        else
            local kf = clamp(e.t / 0.45, 0, 1)
            local ks = clamp(e.t / 1.4, 0, 1)
            local fs = 3 + 13 * e.s * kf
            e.fire.Size = V3(fs, fs, fs)
            e.fire.Transparency = kf
            e.light.Brightness = 7 * (1 - kf)
            local ss = 4 + 16 * e.s * ks
            e.smoke.Size = V3(ss, ss, ss)
            e.smoke.CFrame = CF(e.pos + V3(0, ks * 7, 0))
            e.smoke.Transparency = 0.5 + 0.5 * ks
            local rf = clamp(e.t / 0.5, 0, 1)
            local rs = 3 + 24 * e.s * rf
            e.ring.Size = V3(.3, rs, rs)
            e.ring.Transparency = 0.5 + 0.5 * rf
            for _, d in ipairs(e.debris) do
                local pp = e.pos + d.v * e.t + 0.5 * G * e.t * e.t
                if pp.Y < e.pos.Y + 0.25 then pp = V3(pp.X, e.pos.Y + 0.25, pp.Z) end
                d.p.CFrame = CF(pp) * ANG(e.t * 7, e.t * 5, 0)
            end
        end
    end
    for i = #bits, 1, -1 do
        local b = bits[i]
        b.t = b.t + dt
        if b.t >= b.life then
            b.p:Destroy()
            table.remove(bits, i)
        elseif b.dust then
            local k = b.t / b.life
            local sz = (1 + 4 * k) * b.s
            b.p.Size = V3(sz, sz, sz)
            b.p.Transparency = 0.45 + 0.55 * k
            b.p.CFrame = CF(b.pos + V3(0, k * 2.2, 0))
        end
    end
end

function FX.clear()
    for _, e in ipairs(expls) do
        e.em:Destroy()
        if not e.done then
            e.fire:Destroy() e.smoke:Destroy() e.ring:Destroy()
            for _, d in ipairs(e.debris) do d.p:Destroy() end
        end
    end
    for _, b in ipairs(bits) do b.p:Destroy() end
    expls, bits = {}, {}
end

-- ===== rig pemain bersama (untuk fitur yang menggerakkan karakter) =====
local rigs = {}
local CORE_KEYS = { dirty = 1, joints = 1, phase = 1, p = 1, char = 1, root = 1, hum = 1, animate = 1,
    rootOff = 1, cc = 1, charConn = 1 }

local function rigHook(p)
    if rigs[p] then return end
    local d = { dirty = true, joints = {}, phase = rnd() * 6.28, p = p }
    rigs[p] = d
    local function onChar(c)
        d.char, d.root, d.dirty = c, nil, true
        if d.cc then for _, x in ipairs(d.cc) do x:Disconnect() end end
        d.cc = {
            c.DescendantAdded:Connect(function(x) if x:IsA("AnimationConstraint") then d.dirty = true end end),
            c.DescendantRemoving:Connect(function(x) if x:IsA("AnimationConstraint") then d.dirty = true end end),
        }
    end
    d.charConn = p.CharacterAdded:Connect(onChar)
    if p.Character then onChar(p.Character) end
end

local function rigUnhook(p)
    local d = rigs[p]
    if not d then return end
    if d.charConn then d.charConn:Disconnect() end
    if d.cc then for _, x in ipairs(d.cc) do x:Disconnect() end end
    rigs[p] = nil
end

local function rigRefresh(d)
    local c = d.char
    d.dirty = false
    if not c then return end
    d.root = c:FindFirstChild("HumanoidRootPart")
    d.hum = c:FindFirstChildOfClass("Humanoid")
    d.animate = c:FindFirstChild("Animate")
    d.rootOff = (d.hum and d.hum.HipHeight or 2) + (d.root and d.root.Size.Y / 2 or 1)
    local j = {}
    for _, x in ipairs(c:GetDescendants()) do
        if x:IsA("AnimationConstraint") then j[#j + 1] = x end
    end
    d.joints = j
end

local function rig(p)
    local d = rigs[p]
    if d and d.dirty then rigRefresh(d) end
    return d
end

local function rigPlace(d, cf)
    local r = d.root
    r.CFrame = cf
    r.AssemblyLinearVelocity = V3()
    r.AssemblyAngularVelocity = V3()
end

local function rigPose(d, pose, doStop)
    if doStop then
        if d.animate and d.animate:IsA("LocalScript") then d.animate.Disabled = true end
        if d.hum then
            for _, t in ipairs(d.hum:GetPlayingAnimationTracks()) do t:Stop(0) end
        end
    end
    local js = d.joints
    for k = 1, #js do
        local jt = js[k]
        jt.Transform = pose[jt.Name] or IDENT
    end
end

local function rigRelease(d)
    if d.animate and d.animate.Parent and d.animate:IsA("LocalScript") then d.animate.Disabled = false end
    for _, jt in ipairs(d.joints) do
        if jt.Parent then jt.Transform = IDENT end
    end
    for k in pairs(d) do
        if not CORE_KEYS[k] then d[k] = nil end
    end
end

local function releaseAllRigs()
    for _, d in pairs(rigs) do rigRelease(d) end
end

for _, p in ipairs(Players:GetPlayers()) do rigHook(p) end

-- tinggi pinggul turun akibat lutut menekuk (agar kaki tetap menapak)
local function reach(h, k) return cos(rad(h)) + cos(rad(h - k)) end
local function legDrop(lh, lk, rh, rk)
    return max(0, 2 - (reach(lh, lk) + reach(rh, rk)) / 2)
end

-- ===== registri fitur =====
local Modules = {}
local function register(m)
    Modules[#Modules + 1] = m
    m.on = false
    m.say = m.say or function() end
end

function Hub.setOn(m, on)
    if m.on == on then return end
    if on then
        if m.excl then
            for _, o in ipairs(Modules) do
                if o ~= m and o.excl and o.on then Hub.setOn(o, false) end
            end
        end
        m.on = true
        local ok, res, msg = pcall(m.start)
        if not ok then
            m.on = false
            m.say("ERROR: " .. tostring(res))
            warn("[SujudHub] " .. m.name .. ": " .. tostring(res))
            pcall(m.stop)
        elseif res == false then
            m.on = false
            m.say(msg or "gagal dimulai")
        end
    else
        m.on = false
        local ok, e = pcall(m.stop)
        if not ok then warn("[SujudHub] " .. m.name .. " stop: " .. tostring(e)) end
        if m.excl then releaseAllRigs() end
    end
    if m.refreshBtn then m.refreshBtn() end
    if State._HomeFeatureRefresh then pcall(State._HomeFeatureRefresh) end
end

function Hub.fail(m, e)
    warn("[SujudHub] " .. m.name .. ": " .. tostring(e))
    m.say("ERROR: " .. tostring(e))
    Hub.setOn(m, false)
end

-- UI adapter: seluruh kontrol modul tambahan ditempatkan di tab Troll.
local UI = { refreshers = {} }
function UI.page(name)
	-- Grafis pindah ke tab Visual; modul troll lain tetap di Troll
	if name == "Grafis" and vis then
		vis:Section(name)
		return vis
	end
	tr:Section(name)
	return tr
end
function UI.refresh() end
function UI.button(page, text, cb, color) return page:Button(text, "arrow", nil, color, cb) end
function UI.label(page, text, h) return page:Label(text, T.Sub) end
function UI.row(page, specs)
	local row = {}
	for _, sp in ipairs(specs) do
		local active = false
		local entry = {
			t = sp.text, w = 1, c = sp.color or T.Panel2,
			f = sp.cb or function()
				-- fallback toggle (desktop click) bila hold tidak terpasang di Down/Up
				if sp.hold then active = not active; sp.hold(active) end
			end,
		}
		if sp.hold and not sp.cb then
			entry.hold = sp.hold  -- Row akan pasang MouseButton1Down/Up + touch
			entry.f = function() end  -- jangan toggle ganda di Click
		end
		row[#row + 1] = entry
	end
	page:Row(row)
end
function UI.stepper(page, text, get, set, step, fmt)
	local label = page:Label("", T.Sub)
	local function refresh()
		local ok, value = pcall(get)
		if ok then
			local okFmt, result = pcall(string.format, fmt or "%g", value)
			label.Text = text .. ": " .. (okFmt and result or tostring(value))
		end
	end
	page:Row({
		{ t = text .. " −", w = 1, c = T.Panel2, f = function() set(get() - step); refresh() end },
		{ t = text .. " +", w = 1, c = T.Panel2, f = function() set(get() + step); refresh() end },
	})
	refresh()
end
function UI.toggleOpt(page, text, get, set)
	page:Toggle(text, "diamond", nil, false, get,
		function() set(true); UI.refresh() end,
		function() set(false); UI.refresh() end)
end
function UI.module(page, m, text)
	local toggles = {}
	local function addToggle(target)
		local toggle = target:Toggle(text, "sparkle", nil, false, function() return m.on end,
			function() Hub.setOn(m, true) end,
			function() Hub.setOn(m, false) end)
		if toggle then toggles[#toggles + 1] = toggle end
	end
	addToggle(page)
	m.refreshBtn = function()
		for _, toggle in ipairs(toggles) do toggle.set(m.on, true) end
	end
	local lab = page:Label("siap", T.Sub)
	m.say = function(message) lab.Text = tostring(message or "") end
end
-- ===== MODUL: GRAFIS 2026 + ULTRA HD (pasca-proses, atmosfer, bayangan, kualitas render) =====
do
    local m = { name = "Grafis", key = Enum.KeyCode.Y, color = C(60, 70, 120) }
    local pg = UI.page("Grafis")
    local inten = 1
    local ultra = true
    local saved, fx, atm, atmOwn, savedAtm, us = {}, {}, nil, false, {}, {}
    local LK = { "Brightness", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness",
        "GlobalShadows", "ExposureCompensation" }

    local function ultraStart()
        us = {}
        pcall(function()
            local r = settings().Rendering
            us.q, us.mesh = r.QualityLevel, r.MeshPartDetailLevel
            r.QualityLevel = Enum.QualityLevel.Level21
            r.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
        end)
        pcall(function()
            if gethiddenproperty and sethiddenproperty then
                us.tech = gethiddenproperty(Lighting, "Technology")
                sethiddenproperty(Lighting, "Technology", Enum.Technology.Future)
            end
        end)
        pcall(function()
            us.deco = workspace.Terrain.Decoration
            workspace.Terrain.Decoration = true
        end)
    end

    local function ultraStop()
        pcall(function()
            local r = settings().Rendering
            if us.q then r.QualityLevel = us.q end
            if us.mesh then r.MeshPartDetailLevel = us.mesh end
        end)
        pcall(function()
            if us.tech and sethiddenproperty then sethiddenproperty(Lighting, "Technology", us.tech) end
        end)
        pcall(function()
            if us.deco ~= nil then workspace.Terrain.Decoration = us.deco end
        end)
        us = {}
    end

    local function apply()
        local k = inten
        local u = ultra and 1 or 0
        if fx.cc then
            fx.cc.Contrast = (0.07 + 0.06 * u) * k
            fx.cc.Saturation = (0.14 + 0.05 * u) * k
            fx.cc.TintColor = Color3.new(1, 1, 1):Lerp(C(255, 244, 230), min(1, k))
        end
        if fx.bloom then
            fx.bloom.Intensity = (0.45 - 0.1 * u) * k
            fx.bloom.Size = ultra and 24 or 30
            fx.bloom.Threshold = ultra and 0.9 or 0.95
        end
        if fx.rays then fx.rays.Intensity, fx.rays.Spread = (0.1 + 0.04 * u) * k, 0.7 end
        if fx.dof then
            fx.dof.FarIntensity, fx.dof.NearIntensity = (ultra and 0.08 or 0.18) * k, 0
            fx.dof.FocusDistance, fx.dof.InFocusRadius = 90, ultra and 120 or 70
        end
        if atm then
            atm.Density, atm.Offset, atm.Haze, atm.Glare = 0.28, 0.25, 1.4 * k, 0.3 * k
        end
        pcall(function()
            Lighting.EnvironmentDiffuseScale = 1
            Lighting.EnvironmentSpecularScale = 1
            Lighting.ShadowSoftness = ultra and 0.05 or 0.15
            Lighting.GlobalShadows = true
            Lighting.ExposureCompensation = 0.15 * k
        end)
    end

    m.start = function()
        saved = {}
        for _, k in ipairs(LK) do
            local ok, v = pcall(function() return Lighting[k] end)
            if ok then saved[k] = v end
        end
        atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            atmOwn = false
            savedAtm = { Density = atm.Density, Offset = atm.Offset, Haze = atm.Haze, Glare = atm.Glare }
        else
            atmOwn = true
            atm = Instance.new("Atmosphere")
            atm.Color, atm.Decay = C(199, 214, 235), C(106, 112, 125)
            atm.Parent = Lighting
        end
        fx.cc = Instance.new("ColorCorrectionEffect")
        fx.bloom = Instance.new("BloomEffect")
        fx.rays = Instance.new("SunRaysEffect")
        fx.dof = Instance.new("DepthOfFieldEffect")
        for _, e in pairs(fx) do e.Name = "SujudGrafis" e.Parent = Lighting end
        if ultra then ultraStart() end
        apply()
        m.say("Grafis 2026" .. (ultra and " ULTRA HD" or "") .. " aktif | intensitas " .. string.format("%.2f", inten))
    end

    m.stop = function()
        for _, e in pairs(fx) do e:Destroy() end
        fx = {}
        for k, v in pairs(saved) do pcall(function() Lighting[k] = v end) end
        if atm then
            if atmOwn then atm:Destroy()
            else for k, v in pairs(savedAtm) do pcall(function() atm[k] = v end) end end
        end
        atm = nil
        ultraStop()
        m.say("mati")
    end

    UI.module(pg, m, "Grafis 2026 (Y)")
    UI.toggleOpt(pg, "Ultra HD", function() return ultra end, function(v)
        ultra = v
        if m.on then
            ultraStop()
            if v then ultraStart() end
            apply()
            m.say("Grafis 2026" .. (v and " ULTRA HD" or "") .. " aktif | intensitas " .. string.format("%.2f", inten))
        end
    end)
    UI.stepper(pg, "Intensitas", function() return inten end, function(v)
        inten = clamp(v, 0.25, 2)
        if m.on then apply() end
    end, 0.25, "%.2f")
    UI.label(pg, "Waktu (hanya di layarmu):", 16)
    UI.row(pg, {
        { text = "Pagi", cb = function() Lighting.ClockTime = 7.5 end },
        { text = "Siang", cb = function() Lighting.ClockTime = 13 end },
        { text = "Sore", cb = function() Lighting.ClockTime = 17.5 end },
        { text = "Malam", cb = function() Lighting.ClockTime = 21.5 end },
    })
    register(m)
end

-- ===== MODUL: BARISAN KEHORMATAN + KARPET MERAH (tanpa lampu) =====
do
    local m = { name = "Barisan", excl = true, key = Enum.KeyCode.G }
    local pg = UI.page("Barisan")
    local spacing, sideOffset = 4, 6
    local arm, abd, elbow = 30, 75, 150
    local sA, sB, sE = 1, 1, 1
    local includeMe = false
    local carpetWidth, carpetExtra = 6, 10
    local salute = {}
    local targets, dirty = {}, true
    local fold, carpet = nil, nil
    local t0 = 0
    local faceL, faceR = ANG(0, -pi / 2, 0), ANG(0, pi / 2, 0)

    local function recalc()
        salute = {
            RightShoulder = ANG(rad(arm) * sA, 0, rad(abd) * sB),
            RightElbow = ANG(rad(elbow) * sE, 0, 0),
        }
    end
    recalc()

    local function info()
        return string.format("lengan %d | samping %d | siku %d | lebar %d | rapat %d",
            arm, abd, elbow, sideOffset, spacing)
    end

    local function rebuild()
        targets = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if (p ~= lp or includeMe) and rigs[p] then targets[#targets + 1] = p end
        end
        table.sort(targets, function(a, b) return a.Name < b.Name end)
        dirty = false
    end
    m.roster = function() dirty = true end

    local function makeCarpet()
        carpet = fxPart(fold, V3(carpetWidth, 0.2, 20), C(170, 15, 25), MAT.Fabric)
        for _, s in ipairs({ -1, 1 }) do
            local trim = fxPart(carpet, V3(0.3, 0.22, 20), C(235, 190, 60))
            trim:SetAttribute("side", s)
        end
    end

    local function placeCarpet(fl, floorY, length, now)
        carpet.Size = V3(carpetWidth, 0.2, length)
        local base = CF(fl.Position.X, floorY + 0.1, fl.Position.Z) * (fl - fl.Position)
        carpet.CFrame = base
        for _, t in ipairs(carpet:GetChildren()) do
            local s = t:GetAttribute("side")
            if s then
                t.Size = V3(0.3, 0.22, length)
                t.CFrame = base * CF(s * (carpetWidth / 2 - 0.15), 0.01, 0)
            end
        end
    end

    m.place = function(now, doStop)
        local char = lp.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot or not carpet then return end
        local myHum = char:FindFirstChildOfClass("Humanoid")
        if dirty then rebuild() end
        local fl = CF(myRoot.Position) * ANG(0, select(2, myRoot.CFrame:ToEulerAnglesYXZ()), 0)
        local n = #targets
        local nLeft = math.ceil(n / 2)
        local nRight = n - nLeft
        for i = 1, n do
            local d = rig(targets[i])
            if d and d.root and d.root.Parent then
                local idx = i - 1
                local side, k = idx % 2, floor(idx / 2)
                local cnt = side == 0 and nLeft or nRight
                local z = -((k - (cnt - 1) / 2) * spacing)
                local x = side == 0 and -sideOffset or sideOffset
                local ph = d.phase
                local cf = fl * CF(x, 0, z) * (side == 0 and faceL or faceR)
                -- napas halus + sedikit goyang berat badan
                local pos = cf * CF(0, sin(now * 1.5 + ph) * 0.025, 0) * ANG(0, sin(now * 0.6 + ph) * 0.015, 0)
                rigPlace(d, pos)
                -- hormat perlahan-lahan bergiliran, kepala mengikuti pemimpin barisan
                local kk = smooth((now - t0 - i * 0.07) / 0.8)
                local lv = cf:PointToObjectSpace(myRoot.Position)
                local target = clamp(atan2(-lv.X, -lv.Z) * 0.35, -0.7, 0.7)
                d.hy = lerp(d.hy or 0, target, 0.08)
                local pose = d.pose
                if not pose then pose = {} d.pose = pose end
                pose.RightShoulder = IDENT:Lerp(salute.RightShoulder, kk)
                pose.RightElbow = IDENT:Lerp(salute.RightElbow, kk)
                pose.Neck = ANG(0, d.hy, 0)
                rigPose(d, pose, doStop)
            end
        end
        local hip = myHum and myHum.HipHeight or 2
        local floorY = myRoot.Position.Y - (hip + myRoot.Size.Y / 2)
        placeCarpet(fl, floorY, max(nLeft, 1) * spacing + carpetExtra, now)
    end

    m.start = function()
        if not (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) then
            return false, "karaktermu belum siap"
        end
        fold = Instance.new("Folder")
        fold.Name = "Barisan"
        fold.Parent = fxRoot
        makeCarpet()
        t0 = os.clock()
        rebuild()
        m.say("AKTIF (" .. #targets .. " penjaga) | " .. info())
    end
    m.stop = function()
        if fold then fold:Destroy() fold = nil end
        carpet = nil
        m.say("mati | " .. info())
    end

    UI.module(pg, m, "Barisan + Karpet Merah (G)")
    UI.stepper(pg, "Lengan", function() return arm end, function(v) arm = clamp(v, -30, 180) recalc() end, 10, "%d")
    UI.stepper(pg, "Samping", function() return abd end, function(v) abd = clamp(v, 0, 120) recalc() end, 10, "%d")
    UI.stepper(pg, "Siku", function() return elbow end, function(v) elbow = clamp(v, 0, 150) recalc() end, 10, "%d")
    UI.stepper(pg, "Lebar barisan", function() return sideOffset end, function(v) sideOffset = clamp(v, 4, 20) end, 1, "%d")
    UI.stepper(pg, "Kerapatan", function() return spacing end, function(v) spacing = clamp(v, 2, 10) end, 1, "%d")
    UI.row(pg, {
        { text = "Balik lengan", cb = function() sA = -sA recalc() end },
        { text = "Balik samping", cb = function() sB = -sB recalc() end },
        { text = "Balik siku", cb = function() sE = -sE recalc() end },
    })
    UI.toggleOpt(pg, "Termasuk aku", function() return includeMe end, function(v) includeMe = v dirty = true end)
    register(m)
end

-- ===== MODUL: BUS REALISTIS =====
do
    local m = { name = "Bus", excl = true, key = Enum.KeyCode.B }
    local pg = UI.page("Bus")
    local maxSpeed, accel, turnRate = 60, 35, 1.6
    local sitY, minRows = 3.6, 5
    local dl, da = 1, 1
    local kb, bt = {}, {}
    local bus, busLen
    local busCF, vis, speed, busY = CF(), CF(), 0, 0
    local slots, order = {}, {}
    local wheels, tails, sigs, stir = {}, {}, {}, nil
    local spin, steerVis, pitch, roll, prevSpeed = 0, 0, 0, 0, 0
    local bumpY, bumpV = 0, 0
    local saved, fovSaved = {}, nil
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local poseP, poseD = {}, {}
    local lastInfo = 0

    local function recalc()
        local hip = ANG(rad(90) * dl, 0, 0)
        local knee = ANG(-rad(90) * dl, 0, 0)
        poseP = { LeftHip = hip, RightHip = hip, LeftKnee = knee, RightKnee = knee }
        local sh, el = ANG(rad(70) * da, 0, 0), ANG(rad(20) * da, 0, 0)
        poseD = { LeftHip = hip, RightHip = hip, LeftKnee = knee, RightKnee = knee,
            LeftShoulder = sh, RightShoulder = sh, LeftElbow = el, RightElbow = el }
    end
    recalc()

    local function info()
        return string.format("%d km/j | duduk %.1f | kaki %s | tangan %s", floor(abs(speed) * 1.8), sitY,
            dl == 1 and "normal" or "balik", da == 1 and "normal" or "balik")
    end

    local function bp(size, cf, color, mat, tr, shape)
        local p = fxPart(bus, size, color, mat, shape, cf)
        p.Transparency = tr or 0
        return p
    end

    local function sign(p, text, face, col)
        local g = Instance.new("SurfaceGui")
        g.Face, g.SizingMode, g.PixelsPerStud = face, Enum.SurfaceGuiSizingMode.PixelsPerStud, 50
        g.Parent = p
        local t = Instance.new("TextLabel")
        t.Size, t.BackgroundTransparency, t.Text, t.TextScaled = UDim2.fromScale(1, 1), 1, text, true
        t.Font, t.TextColor3 = Enum.Font.GothamBold, col
        t.Parent = g
    end

    local function makeWheel(front, off)
        local w = Instance.new("Model")
        w.Name = "Roda"
        local tire = fxPart(w, V3(0.9, 2.6, 2.6), C(22, 22, 25), MAT.Rubber, CYL, CF())
        w.PrimaryPart = tire
        fxPart(w, V3(0.95, 1.6, 1.6), C(170, 172, 178), MAT.Metal, CYL, CF())
        fxPart(w, V3(1.0, 0.5, 0.5), C(40, 40, 45), MAT.Metal, CYL, CF())
        for a = 0, 2 do
            fxPart(w, V3(0.98, 0.22, 1.5), C(110, 112, 118), MAT.Metal, nil, ANG(rad(a * 60), 0, 0))
        end
        w.Parent = bus
        wheels[#wheels + 1] = { m = w, front = front, off = off }
    end

    local function buildBus(rows)
        if bus then bus:Destroy() end
        wheels, tails, sigs, stir = {}, {}, {}, nil
        bus = Instance.new("Model")
        bus.Name = "BusSaya"
        local L = rows * 3.5 + 9
        busLen = L
        local W = 8.4
        local yellow, white = C(245, 190, 30), C(235, 235, 238)
        local glass, dark, chrome = C(150, 200, 230), C(30, 30, 35), C(200, 202, 208)
        local blue, blueLight = C(45, 70, 150), C(70, 100, 190)

        local origin = bp(V3(1, 1, 1), CF(), dark, nil, 1)
        bus.PrimaryPart = origin

        bp(V3(W - 0.4, 0.4, L - 0.4), CF(0, 1.6, 0), dark)
        bp(V3(2.6, 0.05, L - 1), CF(0, 1.83, 0), C(80, 80, 90), MAT.DiamondPlate)

        for _, s in ipairs({ -1, 1 }) do
            bp(V3(0.3, 2.4, L), CF(s * W / 2, 2.2, 0), yellow)
            bp(V3(0.32, 0.25, L), CF(s * W / 2, 2.3, 0), dark)
            bp(V3(0.15, 3.2, L), CF(s * W / 2, 5.0, 0), glass, MAT.Glass, 0.55)
            for k = 0, rows + 1 do
                local z = -L / 2 + 0.2 + k * (L - 0.4) / (rows + 1)
                bp(V3(0.4, 3.2, 0.35), CF(s * W / 2, 5.0, z), yellow)
            end
            bp(V3(0.9, 0.1, 0.1), CF(s * (W / 2 + 0.45), 4.2, -L / 2 + 0.6), dark)
            bp(V3(0.15, 1.1, 0.6), CF(s * (W / 2 + 0.95), 4.3, -L / 2 + 0.6), dark)
        end

        bp(V3(W, 0.4, L + 0.4), CF(0, 6.8, 0), white)
        bp(V3(W - 1, 0.25, 2.2), CF(0, 7.05, L / 4), C(200, 200, 205))

        bp(V3(W, 2.4, 0.4), CF(0, 2.2, -L / 2), yellow)
        bp(V3(W - 0.6, 3.2, 0.15), CF(0, 5.0, -L / 2), glass, MAT.Glass, 0.55)
        bp(V3(0.3, 3.2, 0.3), CF(0, 5.0, -L / 2), yellow)
        bp(V3(3.2, 1.0, 0.1), CF(0, 2.0, -L / 2 - 0.25), dark)
        for _, s in ipairs({ -1, 1 }) do
            local hl = bp(V3(0.9, 0.6, 0.2), CF(s * 3, 2.5, -L / 2 - 0.25), C(255, 250, 205), MAT.Neon)
            local sp = Instance.new("SpotLight")
            sp.Face, sp.Range, sp.Angle, sp.Brightness = Enum.NormalId.Front, 55, 70, 2
            sp.Parent = hl
            bp(V3(0.5, 0.35, 0.15), CF(s * 3.6, 1.7, -L / 2 - 0.25), C(255, 170, 40), MAT.Neon)
            sigs[#sigs + 1] = { p = bp(V3(0.5, 0.3, 0.15), CF(s * (W / 2 - 0.4), 3.0, -L / 2 - 0.22), C(120, 80, 10)), side = s }
            sigs[#sigs + 1] = { p = bp(V3(0.5, 0.3, 0.15), CF(s * (W / 2 - 0.4), 3.0, L / 2 + 0.22), C(120, 80, 10)), side = s }
        end
        bp(V3(W + 0.2, 0.5, 0.7), CF(0, 1.2, -L / 2 - 0.3), dark)
        local dest = bp(V3(5, 0.8, 0.15), CF(0, 6.3, -L / 2 - 0.05), C(15, 15, 18))
        sign(dest, "BUS KOTA", Enum.NormalId.Front, C(255, 170, 40))
        local plateF = bp(V3(1.8, 0.6, 0.1), CF(0, 1.55, -L / 2 - 0.68), white)
        sign(plateF, "B 1234 BUS", Enum.NormalId.Front, C(20, 20, 20))
        for _, x in ipairs({ -1.6, 1.4 }) do
            bp(V3(1.8, 0.08, 0.08), CF(x, 3.9, -L / 2 + 0.2) * ANG(0, 0, rad(12)), dark)
        end

        bp(V3(W, 5.6, 0.4), CF(0, 3.8, L / 2), yellow)
        bp(V3(5, 1.6, 0.1), CF(0, 5.5, L / 2 + 0.22), glass, MAT.Glass, 0.5)
        for _, s in ipairs({ -1, 1 }) do
            tails[#tails + 1] = bp(V3(0.8, 0.5, 0.15), CF(s * 3.5, 2.6, L / 2 + 0.22), C(110, 10, 10))
        end
        bp(V3(W + 0.2, 0.5, 0.7), CF(0, 1.2, L / 2 + 0.3), dark)
        local plateR = bp(V3(1.8, 0.6, 0.1), CF(0, 2.0, L / 2 + 0.25), white)
        sign(plateR, "B 1234 BUS", Enum.NormalId.Back, C(20, 20, 20))

        local doorZ = -L / 2 + 2.4
        bp(V3(0.35, 4.4, 2.2), CF(W / 2 + 0.03, 4.0, doorZ), dark)
        bp(V3(0.2, 3.6, 1.9), CF(W / 2 + 0.12, 4.2, doorZ), glass, MAT.Glass, 0.5)
        bp(V3(1.0, 0.2, 2.0), CF(W / 2 + 0.4, 1.3, doorZ), dark, MAT.DiamondPlate)

        local fz, rz = -L / 2 + 5.0, L / 2 - 4.2
        for _, s in ipairs({ -1, 1 }) do
            makeWheel(true, V3(s * (W / 2 - 0.1), 1.3, fz))
            makeWheel(false, V3(s * (W / 2 - 0.1), 1.3, rz))
        end

        local driverZ = -L / 2 + 2.6
        bp(V3(W - 0.8, 0.9, 1.0), CF(0, 3.0, -L / 2 + 0.6), dark)
        bp(V3(1.2, 0.5, 0.1), CF(-2.4, 3.55, -L / 2 + 1.0), C(20, 40, 30), MAT.Neon)
        stir = Instance.new("Model")
        stir.Name = "Stir"
        local rim = fxPart(stir, V3(0.15, 1.5, 1.5), C(25, 25, 28), nil, CYL, CF())
        stir.PrimaryPart = rim
        fxPart(stir, V3(0.12, 1.4, 0.18), C(40, 40, 45), nil, nil, CF())
        fxPart(stir, V3(0.12, 0.18, 1.4), C(40, 40, 45), nil, nil, CF())
        stir.Parent = bus

        slots = {}
        bp(V3(1.9, 0.9, 1.9), CF(-2.4, 2.25, driverZ), dark)
        bp(V3(1.9, 2.0, 0.35), CF(-2.4, 3.7, driverZ + 0.9), dark)
        bp(V3(1.0, 0.6, 0.3), CF(-2.4, 4.9, driverZ + 0.95), dark)
        slots[0] = V3(-2.4, 0, driverZ)

        local z0 = -L / 2 + 6.8
        for r = 0, rows - 1 do
            local z = z0 + r * 3.5
            for _, x in ipairs({ -2.6, 2.6 }) do
                bp(V3(1.9, 0.9, 1.9), CF(x, 2.25, z), blue, MAT.Fabric)
                bp(V3(1.9, 0.12, 1.9), CF(x, 2.75, z), blueLight, MAT.Fabric)
                bp(V3(1.9, 2.0, 0.35), CF(x, 3.7, z + 0.9), blue, MAT.Fabric)
                bp(V3(1.0, 0.6, 0.3), CF(x, 4.9, z + 0.95), blueLight, MAT.Fabric)
                slots[#slots + 1] = V3(x, 0, z)
            end
            for _, x in ipairs({ -1.25, 1.25 }) do
                bp(V3(4.8, 0.15, 0.15), CF(x, 4.2, z - 1.0) * ANG(0, 0, rad(90)), chrome, MAT.Metal, 0, CYL)
            end
            if r % 2 == 0 then
                bp(V3(1.6, 0.1, 0.6), CF(0, 6.55, z), C(255, 250, 225), MAT.Neon)
            end
        end
        for _, x in ipairs({ -1.25, 1.25 }) do
            bp(V3(L - 3, 0.15, 0.15), CF(x, 6.35, 0) * ANG(0, rad(90), 0), chrome, MAT.Metal, 0, CYL)
        end
        local lamp = Instance.new("PointLight")
        lamp.Range, lamp.Brightness = 22, 0.8
        lamp.Parent = origin
        bus.Parent = fxRoot
    end

    local function sim(dt, now)
        local thr = ((kb.f or bt.f) and 1 or 0) - ((kb.b or bt.b) and 1 or 0)
        local str = ((kb.l or bt.l) and 1 or 0) - ((kb.r or bt.r) and 1 or 0)
        -- Mobile / touch joystick: pakai Humanoid.MoveDirection bila tidak ada input keyboard/tombol
        if thr == 0 and str == 0 then
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                local md = hum.MoveDirection
                if md.Magnitude > 0.05 then
                    local look = busCF.LookVector
                    local right = busCF.RightVector
                    local flatLook = V3(look.X, 0, look.Z)
                    local flatRight = V3(right.X, 0, right.Z)
                    if flatLook.Magnitude > 1e-3 then flatLook = flatLook.Unit end
                    if flatRight.Magnitude > 1e-3 then flatRight = flatRight.Unit end
                    thr = clamp(md:Dot(flatLook), -1, 1)
                    str = clamp(-md:Dot(flatRight), -1, 1)
                end
            end
        end
        local braking = kb.brake or bt.brake
        if braking then
            speed = speed * (1 - min(1, 5 * dt))
        elseif thr ~= 0 then
            speed = clamp(speed + thr * accel * dt, -maxSpeed * 0.4, maxSpeed)
        else
            speed = speed * (1 - min(1, 1.5 * dt))
        end
        local pos = busCF.Position
        local rot = (busCF - pos) * ANG(0, str * turnRate * dt * clamp(speed / 12, -1, 1), 0)
        local nxt = (CF(pos) * rot) * CF(0, 0, -speed * dt)
        local np = nxt.Position
        local hit = workspace:Raycast(np + V3(0, 12, 0), V3(0, -60, 0), rp)
        if hit then busY = busY + (hit.Position.Y - busY) * min(1, 12 * dt) end
        busCF = CF(np.X, busY, np.Z) * (nxt - np)

        spin = (spin - speed * dt / 1.3) % (pi * 2)
        steerVis = steerVis + (str * 0.5 - steerVis) * min(1, 8 * dt)
        local acc = (speed - prevSpeed) / max(dt, 1e-3)
        prevSpeed = speed
        pitch = pitch + (clamp(acc * 0.0006, -0.03, 0.03) - pitch) * min(1, 6 * dt)
        roll = roll + (-str * clamp(speed / maxSpeed, -1, 1) * 0.04 - roll) * min(1, 6 * dt)

        -- jalan bergelombang: pegas suspensi + getaran mesin
        if abs(speed) > 8 and rnd() < dt * 0.7 then
            bumpV = bumpV + 1.4 + rnd() * 1.6
            addShake(0.25)
        end
        bumpV = bumpV + (-bumpY * 120 - bumpV * 10) * dt
        bumpY = bumpY + bumpV * dt
        local vib = sin(now * 55) * 0.012 * (1 + abs(speed) / maxSpeed * 0.8)
        vis = busCF * ANG(pitch, 0, roll) * CF(0, vib + bumpY, 0)

        local rem = braking or thr < 0
        for _, t in ipairs(tails) do
            t.Color = rem and C(255, 40, 40) or C(110, 10, 10)
            t.Material = rem and MAT.Neon or MAT.SmoothPlastic
        end
        local blink = sin(now * 9) > 0
        for _, s in ipairs(sigs) do
            local on = blink and ((str > 0 and s.side == -1) or (str < 0 and s.side == 1))
            s.p.Color = on and C(255, 175, 30) or C(120, 80, 10)
            s.p.Material = on and MAT.Neon or MAT.SmoothPlastic
        end
        local cam = workspace.CurrentCamera
        if cam and fovSaved then
            cam.FieldOfView = lerp(cam.FieldOfView, fovSaved + abs(speed) / maxSpeed * 12, damp(3, dt))
        end
    end

    local function seat(d, lv, pose, now, doStop)
        if not (d and d.root and d.root.Parent) then return end
        local bpz = d.bpose
        if not bpz then bpz = {} d.bpose = bpz end
        for k, v in pairs(pose) do bpz[k] = v end
        bpz.Neck = ANG(-pitch * 5 + sin(now * 1.7 + d.phase) * 0.015, 0, roll * 6 + bumpY * 0.8)
        rigPlace(d, vis * CF(lv.X, sitY, lv.Z + bumpY * 0.3))
        rigPose(d, bpz, doStop)
    end

    m.update = function(dt, now)
        if not bus then return end
        sim(dt, now)
        if now - lastInfo > 0.25 then
            lastInfo = now
            m.say("NAIK BUS | " .. info())
        end
    end

    m.place = function(now, doStop)
        if not bus then return end
        bus:PivotTo(vis)
        for _, w in ipairs(wheels) do
            local yaw = w.front and steerVis or 0
            w.m:PivotTo(vis * CF(w.off) * ANG(0, yaw, 0) * ANG(spin, 0, 0))
        end
        if stir then
            stir:PivotTo(vis * CF(-2.4, 3.9, -busLen / 2 + 1.5) * ANG(rad(-35), 0, 0)
                * ANG(0, rad(90), 0) * ANG(steerVis * 4, 0, 0))
        end
        local me = rig(lp)
        if me and slots[0] then seat(me, slots[0], poseD, now, doStop) end
        local i = 0
        for _, p in ipairs(order) do
            local d = rig(p)
            if d then
                i = i + 1
                if slots[i] then seat(d, slots[i], poseP, now, doStop) end
            end
        end
    end

    local function resort()
        order = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and rigs[p] then order[#order + 1] = p end
        end
        table.sort(order, function(a, b) return a.Name < b.Name end)
    end
    m.roster = resort

    m.start = function()
        local char = lp.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local h = char and char:FindFirstChildOfClass("Humanoid")
        if not myRoot or not h then return false, "karaktermu belum siap" end
        saved = { ws = h.WalkSpeed, jp = h.JumpPower, jh = h.JumpHeight, hum = h }
        h.WalkSpeed, h.JumpPower, h.JumpHeight = 0, 0, 0
        resort()
        buildBus(max(minRows, math.ceil(max(#order, 1) / 2)))
        local look = myRoot.CFrame.LookVector
        local yaw = atan2(-look.X, -look.Z)
        local floorY = myRoot.Position.Y - (h.HipHeight + myRoot.Size.Y / 2)
        busY = floorY
        busCF = CF(myRoot.Position.X, floorY, myRoot.Position.Z) * ANG(0, yaw, 0)
        vis = busCF
        spin, steerVis, pitch, roll, prevSpeed, speed, bumpY, bumpV = 0, 0, 0, 0, 0, 0, 0, 0
        rp.FilterDescendantsInstances = { bus, char }
        local cam = workspace.CurrentCamera
        fovSaved = cam and cam.FieldOfView or nil
        m.say("NAIK BUS | " .. info())
    end

    m.stop = function()
        local h = saved.hum
        if h and h.Parent and saved.ws then
            h.WalkSpeed, h.JumpPower, h.JumpHeight = saved.ws, saved.jp, saved.jh
        end
        saved = {}
        local cam = workspace.CurrentCamera
        if cam and fovSaved then cam.FieldOfView = fovSaved end
        fovSaved = nil
        if bus then bus:Destroy() bus = nil end
        wheels, tails, sigs, stir = {}, {}, {}, nil
        kb, speed = {}, 0
        m.say("turun | " .. info())
    end

    bind(UIS.InputBegan, function(i, gp)
        if gp or not m.on then return end
        local k = i.KeyCode
        if k == Enum.KeyCode.W then kb.f = true
        elseif k == Enum.KeyCode.S then kb.b = true
        elseif k == Enum.KeyCode.A then kb.l = true
        elseif k == Enum.KeyCode.D then kb.r = true
        elseif k == Enum.KeyCode.Space then kb.brake = true end
    end)
    bind(UIS.InputEnded, function(i)
        local k = i.KeyCode
        if k == Enum.KeyCode.W then kb.f = false
        elseif k == Enum.KeyCode.S then kb.b = false
        elseif k == Enum.KeyCode.A then kb.l = false
        elseif k == Enum.KeyCode.D then kb.r = false
        elseif k == Enum.KeyCode.Space then kb.brake = false end
    end)

    UI.module(pg, m, "Naik Bus (B)")
    UI.row(pg, { { text = "Maju", hold = function(v) bt.f = v end }, { text = "Mundur", hold = function(v) bt.b = v end } })
    UI.row(pg, { { text = "Kiri", hold = function(v) bt.l = v end }, { text = "Kanan", hold = function(v) bt.r = v end } })
    UI.row(pg, { { text = "REM", color = T.bad, hold = function(v) bt.brake = v end } })
    UI.stepper(pg, "Tinggi duduk", function() return sitY end, function(v) sitY = clamp(v, 2, 6) end, 0.1, "%.1f")
    UI.row(pg, {
        { text = "Balik kaki", cb = function() dl = -dl recalc() end },
        { text = "Balik tangan", cb = function() da = -da recalc() end },
    })
    UI.label(pg, "WASD = nyetir | Spasi = rem. Suspensi, lampu sein, lampu rem, FOV dinamis aktif otomatis.", 32)
    register(m)
end

-- ===== MODUL: PERANG 2 KUBU =====
do
    local m = { name = "Perang", excl = true, key = Enum.KeyCode.P, color = C(120, 40, 40) }
    local pg = UI.page("Perang")
    local gap, spacing, rankGap, ranks = 70, 5, 4, 2
    local includeMe = false
    local intensity = 1
    local aimR, aimL, elbR, elbL = 80, 70, 45, 60
    local sA, sE = 1, 1
    local MAX_BULLETS, BSPD = 90, 260
    local HIT_CHANCE, KILL_CHANCE = 0.012, 0.5
    local casualties = true
    local MAX_CASINGS = 25
    local CROUCH_DROP = legDrop(55, 105, 55, 105)

    local TEAMS = {
        { name = "MERAH", color = C(190, 30, 30), tracer = C(255, 130, 60), side = -1 },
        { name = "BIRU", color = C(30, 80, 205), tracer = C(100, 210, 255), side = 1 },
    }
    local gunC, gunC2 = C(35, 35, 40), C(65, 67, 74)
    local woodC, oliveC = C(110, 70, 35), C(75, 85, 55)
    local tanC, dirtC, brassC = C(185, 160, 110), C(95, 75, 52), C(200, 160, 60)

    local fold
    local teamList = { {}, {} }
    local fieldRoot, fieldFloor, floorY, rootOff = CF(), CF(), 0, 3
    local bullets, rockets, grenades, casings, pool = {}, {}, {}, {}, {}
    local faceL, faceR = ANG(0, -pi / 2, 0), ANG(0, pi / 2, 0)

    local B = CF(0.35, 0.1, -0.8)
    local ROLES = {
        rifle = { base = B, muzzle = CF(0, .05, -2.3), b1 = 3, b2 = 5, iv = .12, r1 = .8, r2 = 2, parts = {
            { V3(.28, .35, 1.8), CF(0, 0, -.4), gunC }, { V3(.12, .12, 1.2), CF(0, .05, -1.6), gunC2 },
            { V3(.3, .5, .8), CF(0, -.05, .9), woodC }, { V3(.2, .7, .3), CF(0, -.5, -.2) * ANG(rad(15), 0, 0), gunC },
            { V3(.15, .2, .4), CF(0, .28, -.4), gunC2 } } },
        smg = { base = B, muzzle = CF(0, .05, -1.4), b1 = 6, b2 = 10, iv = .07, r1 = .6, r2 = 1.5, parts = {
            { V3(.3, .4, 1.1), CF(0, 0, -.2), gunC }, { V3(.1, .1, .6), CF(0, .05, -1), gunC2 },
            { V3(.18, .9, .25), CF(0, -.6, -.1), gunC }, { V3(.25, .35, .5), CF(0, -.05, .6), gunC2 } } },
        sniper = { base = B, muzzle = CF(0, .05, -3), acc = 6, b1 = 1, b2 = 1, iv = .1, r1 = 2.5, r2 = 4, parts = {
            { V3(.25, .3, 2.2), CF(0, 0, -.2), gunC }, { V3(.1, .1, 1.8), CF(0, .05, -2), gunC2 },
            { V3(.3, .5, 1), CF(0, -.05, 1.1), woodC }, { V3(1, .3, .3), CF(0, .3, -.3) * ANG(0, rad(90), 0), gunC2, CYL },
            { V3(.1, .5, .1), CF(0, -.4, -1.3) * ANG(rad(20), 0, 0), gunC } } },
        shotgun = { base = B, muzzle = CF(0, 0, -1.55), pellets = 5, b1 = 1, b2 = 1, iv = .1, r1 = 1.8, r2 = 3, parts = {
            { V3(.28, .3, 2), CF(0, 0, -.5), gunC }, { V3(.35, .3, .8), CF(0, -.25, -.8), woodC },
            { V3(.3, .5, .9), CF(0, -.05, .9), woodC } } },
        cmd = { base = B, muzzle = CF(0, .05, -.8), acc = 2, b1 = 1, b2 = 1, iv = .2, r1 = .8, r2 = 1.6, parts = {
            { V3(.2, .3, .8), CF(0, 0, -.3), gunC }, { V3(.18, .5, .25), CF(0, -.35, 0) * ANG(rad(12), 0, 0), gunC2 } } },
        bazooka = { base = CF(.9, .6, -.5), muzzle = CF(0, 0, -2), rocket = true, parts = {
            { V3(3.4, .55, .55), ANG(0, rad(90), 0), gunC2, CYL }, { V3(.4, .8, .8), CF(0, 0, -1.7) * ANG(0, rad(90), 0), gunC, CYL },
            { V3(.5, .85, .85), CF(0, 0, 1.7) * ANG(0, rad(90), 0), gunC, CYL }, { V3(.2, .6, .2), CF(0, -.5, -.3), gunC },
            { V3(.15, .25, .4), CF(0, .4, -.5), gunC } } },
    }
    local ROLEORDER = { "cmd", "rifle", "rifle", "smg", "rifle", "sniper", "rifle", "shotgun", "rifle", "bazooka" }

    local function info()
        return string.format("%s | MERAH %d vs BIRU %d | tembak x%.2f | korban %s",
            m.on and "PERANG" or "siap", #teamList[1], #teamList[2], intensity, casualties and "ON" or "OFF")
    end

    local function destroyGear(d)
        if d.gear then d.gear:Destroy() d.gear = nil end
        d.flash, d.flashLight = nil, nil
    end

    local function weld(parent, base, size, cf, color, mat, shape)
        local p = Instance.new("Part")
        p.Size, p.Color = size, color
        p.Material = mat or MAT.SmoothPlastic
        p.Massless, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
        p.Anchored = false
        if shape then p.Shape = shape end
        p.CFrame = base.CFrame * cf
        p.Parent = parent
        local w = Instance.new("Weld")
        w.Part0, w.Part1, w.C0 = base, p, cf
        w.Parent = p
        return p
    end

    local function equip(d)
        destroyGear(d)
        local c = d.char
        local torso = c and (c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
        local head = c and c:FindFirstChild("Head")
        if not (torso and head and d.team and d.role) then return false end
        local Tm, R = TEAMS[d.team], ROLES[d.role]
        local g = Instance.new("Folder")
        g.Name = "Gear"
        g.Parent = fold or fxRoot
        d.gear = g
        weld(g, torso, V3(2.15, 1.5, 1.15), CF(), Tm.color, MAT.Fabric)
        weld(g, head, V3(1.5, 0.95, 1.5), CF(0, 0.25, 0), Tm.color:Lerp(oliveC, 0.5), MAT.Metal, BALL)
        weld(g, torso, V3(1.3, 1.5, 0.7), CF(0, 0, 0.85), oliveC, MAT.Fabric)
        weld(g, torso, V3(2.25, 0.25, 1.25), CF(0, -0.55, 0), woodC, MAT.Fabric)
        weld(g, torso, V3(.5, .55, .35), CF(-.6, -.3, -.65), woodC, MAT.Fabric)
        weld(g, torso, V3(.5, .55, .35), CF(.2, -.3, -.65), woodC, MAT.Fabric)
        weld(g, torso, V3(.45, .7, .45), CF(.9, -.5, .7), C(60, 80, 55), MAT.Metal, CYL)
        for _, s in ipairs(R.parts) do
            weld(g, torso, s[1], R.base * s[2], s[3], MAT.Metal, s[4])
        end
        local fl = weld(g, torso, V3(.6, .6, .6), R.base * R.muzzle, C(255, 220, 120), MAT.Neon, BALL)
        fl.Transparency = 1
        local light = Instance.new("PointLight")
        light.Color, light.Brightness, light.Range, light.Enabled = C(255, 190, 90), 3, 14, false
        light.Parent = fl
        d.flash, d.flashLight = fl, light
        if d.role == "cmd" then
            local steel = C(205, 208, 218)
            weld(g, torso, V3(.1, 2.6, .35), CF(-.6, .1, 1.05), steel, MAT.Metal)
            weld(g, torso, V3(.6, .12, .2), CF(-.6, 1.35, 1.05), gunC)
            weld(g, torso, V3(.14, .5, .14), CF(-.6, 1.7, 1.05), woodC)
            weld(g, torso, V3(.12, 5, .12), CF(.7, 1.5, 1.0), woodC)
            weld(g, torso, V3(2.2, 1.4, .08), CF(1.8, 3.3, 1.0), Tm.color, MAT.Fabric)
        end
        return true
    end

    local function assign()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if (p ~= lp or includeMe) and rigs[p] then list[#list + 1] = p end
        end
        table.sort(list, function(a, b) return a.Name < b.Name end)
        teamList = { {}, {} }
        local counts = { 0, 0 }
        local now = os.clock()
        for i, p in ipairs(list) do
            local d = rigs[p]
            local ti = (i - 1) % 2 + 1
            counts[ti] = counts[ti] + 1
            local role = ROLEORDER[(counts[ti] - 1) % #ROLEORDER + 1]
            if d.team ~= ti or d.role ~= role or not d.gear then d.gearDirty = true end
            d.team, d.role = ti, role
            d.nextFire = now + rnd() * 3
            d.nextGren = now + 5 + rnd() * 15
            d.burstLeft, d.deadAt, d.reloadUntil = 0, nil, nil
            table.insert(teamList[ti], d)
        end
        for ti, l in ipairs(teamList) do
            local n = #l
            local cols = max(1, math.ceil(n / ranks))
            local side = TEAMS[ti].side
            for k, d in ipairs(l) do
                local k0 = k - 1
                local rank, col = k0 % ranks, floor(k0 / ranks)
                local z = (col - (cols - 1) / 2) * spacing
                local x = side * (gap / 2 + rank * rankGap)
                d.crouch = (rank == 0 and col % 2 == 0)
                d.cf = fieldRoot * CF(x + rr(1), 0, z + rr(.8)) * (side == -1 and faceL or faceR) * ANG(0, rr(.1), 0)
            end
        end
    end
    m.roster = function() if m.on then assign() end end

    local function buildField()
        local lineLen = math.ceil(max(#teamList[1], #teamList[2]) / ranks) * spacing + 12
        local count = math.ceil(lineLen / 3.3)
        for ti, Tm in ipairs(TEAMS) do
            local side = Tm.side
            local x = side * (gap / 2 - 4)
            for layer = 0, 1 do
                for i = 0, count - 1 do
                    local z = (i - (count - 1) / 2) * 3.3 + layer * 1.6
                    fxPart(fold, V3(1.6, 1.1, 3.2), tanC:Lerp(C(150, 130, 90), rnd() * 0.5), MAT.Fabric, nil,
                        fieldFloor * CF(x + rr(.15), 0.55 + layer * 1.05, z) * ANG(0, rr(.08), 0))
                end
            end
            local fx = side * (gap / 2 + rankGap + 8)
            fxPart(fold, V3(14, 0.3, 0.3), woodC, MAT.Wood, CYL, fieldFloor * CF(fx, 7, 0) * ANG(0, 0, rad(90)))
            fxPart(fold, V3(0.15, 3, 5), Tm.color, MAT.Fabric, nil, fieldFloor * CF(fx, 12, 2.7))
        end
        for _ = 1, 14 do
            local s = 3 + rnd() * 5
            fxPart(fold, V3(0.15, s, s), C(60, 48, 36), MAT.Slate, CYL,
                fieldFloor * CF(rr(gap / 2 - 8), 0.08, rr(lineLen / 2)) * ANG(0, 0, rad(90)))
        end
        -- tong terbakar di tengah medan
        for _ = 1, 4 do
            local b = fxPart(fold, V3(2.2, 1.6, 1.6), C(60, 50, 45), MAT.Metal, CYL,
                fieldFloor * CF(rr(gap / 2 - 12), 1.1, rr(lineLen / 2)) * ANG(0, 0, rad(90)))
            local f = Instance.new("Fire")
            f.Size, f.Heat = 8, 9
            f.Parent = b
            local l = Instance.new("PointLight")
            l.Color, l.Range, l.Brightness = C(255, 150, 60), 22, 1.4
            l.Parent = b
        end
        -- kabut debu & asap medan perang
        local haze = fxPart(fold, V3(gap, 1, lineLen), C(0, 0, 0), nil, nil, fieldFloor * CF(0, 5, 0))
        haze.Transparency = 1
        local he = Instance.new("ParticleEmitter")
        he.Rate, he.Lifetime, he.Speed = 7, NumberRange.new(7, 11), NumberRange.new(0.5, 2)
        he.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 14), NumberSequenceKeypoint.new(1, 26) })
        he.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.88),
            NumberSequenceKeypoint.new(1, 1) })
        he.Color = ColorSequence.new(C(130, 118, 100))
        pcall(function() he.Shape = Enum.ParticleEmitterShape.Box end)
        he.Acceleration = V3(2, 0, 1)
        he.Parent = haze
    end

    local function acquireTracer(color)
        local p = table.remove(pool)
        if not p then p = fxPart(fxRoot, V3(.1, .1, 2.2), color, MAT.Neon) end
        p.Color = color
        p.Parent = fold
        return p
    end
    local function freeTracer(p) p.Parent = nil pool[#pool + 1] = p end

    local function pickEnemy(team)
        local l = teamList[3 - team]
        if #l == 0 then return nil end
        for _ = 1, 4 do
            local d = l[rnd(#l)]
            if d.root and d.root.Parent and not d.deadAt then return d end
        end
        return nil
    end

    local function kill(d, now)
        if d.deadAt or not casualties then return end
        d.deadAt = now
        d.lieFor = 7.5 + rnd() * 5
        d.fallDir = rnd() < 0.5 and 1 or -1
        if d.flash then d.flash.Transparency = 1 end
        if d.flashLight then d.flashLight.Enabled = false end
    end

    local function deathAngle(d, now)
        if not d.deadAt then return nil end
        local t = now - d.deadAt
        if t < 0.5 then return 90 * (t / 0.5) ^ 2
        elseif t < d.lieFor then return 90
        elseif t < d.lieFor + 0.8 then return 90 * (1 - (t - d.lieFor) / 0.8) end
        d.deadAt = nil
        return nil
    end

    local function flash(d, now, big)
        if d.flash and d.flash.Parent then
            local s = (0.5 + rnd() * 0.7) * (big or 1)
            d.flash.Size = V3(s, s, s)
            d.flash.Transparency = 0
            if d.flashLight then d.flashLight.Enabled = true end
            d.flashOff = now + 0.05
            FX.dust(d.flash.Position + d.flash.CFrame.LookVector * 0.6, 0.22, C(185, 185, 190))
        end
        d.kickT = now
    end

    local function eject(d)
        if #casings >= MAX_CASINGS or not (d.flash and d.flash.Parent) then return end
        local f = d.flash.CFrame
        local p = fxPart(fold, V3(.08, .08, .28), brassC, MAT.Metal)
        local v = f.RightVector * (4 + rnd() * 3) + f.UpVector * (7 + rnd() * 3) + f.LookVector * rr(2)
        casings[#casings + 1] = { p = p, p0 = f.Position, v = v, t = 0 }
    end

    local function blast(pos, s)
        FX.explode(pos, s)
        if casualties then
            local R = 10 * s
            local now = os.clock()
            for ti = 1, 2 do
                for _, d in ipairs(teamList[ti]) do
                    if d.root and not d.deadAt then
                        local dx, dz = d.root.Position.X - pos.X, d.root.Position.Z - pos.Z
                        if dx * dx + dz * dz < R * R and rnd() < 0.6 then kill(d, now) end
                    end
                end
            end
        end
    end

    local function shoot(d, now)
        local R = ROLES[d.role]
        local tgt = pickEnemy(d.team)
        if not (tgt and d.flash and d.flash.Parent) then d.nextFire = now + 1 return end
        local a = d.flash.Position
        if R.rocket then
            if #rockets < 8 then
                local to = tgt.root.Position + V3(rr(8), rr(2), rr(8))
                local dir = to - a
                local part = fxPart(fold, V3(.5, .5, 2), C(255, 160, 60), MAT.Neon)
                local em = Instance.new("ParticleEmitter")
                em.Rate, em.Lifetime, em.Speed = 80, NumberRange.new(.5, .9), NumberRange.new(1, 3)
                em.Size = NumberSequence.new(.8, 2.5)
                em.Transparency = NumberSequence.new(.3, 1)
                em.Color = ColorSequence.new(C(185, 185, 190))
                em.Parent = part
                rockets[#rockets + 1] = { p = part, a = a, dir = dir.Unit, dist = dir.Magnitude, t = 0 }
                flash(d, now, 2)
                FX.dust(a - d.flash.CFrame.LookVector * 3.5, 1.4, C(170, 160, 145))
            end
            d.nextFire = now + (6 + rnd() * 5) / intensity
            return
        end
        local acc = R.acc or 1
        for _ = 1, (R.pellets or 1) do
            if #bullets < MAX_BULLETS then
                local hit = rnd() < HIT_CHANCE * acc
                local to = hit and (tgt.root.Position + V3(rr(.5), rr(1), rr(.5)))
                    or (tgt.root.Position + V3(rr(9), rr(2.5), rr(9)))
                local dir = to - a
                local dist = dir.Magnitude
                dir = dir.Unit
                local ground = false
                if not hit then
                    dist = dist + rnd() * 40
                    if dir.Y < -0.001 then
                        local tg = (floorY - a.Y) / dir.Y
                        if tg > 0 and tg < dist then dist, ground = tg, true end
                    end
                end
                bullets[#bullets + 1] = { p = acquireTracer(TEAMS[d.team].tracer), a = a, dir = dir, dist = dist,
                    t = 0, hit = hit, ground = ground, tgt = tgt }
            end
        end
        flash(d, now)
        eject(d)
        if (d.burstLeft or 0) <= 0 then d.burstLeft = rnd(R.b1, R.b2) end
        d.burstLeft = d.burstLeft - 1
        if d.burstLeft > 0 then
            d.nextFire = now + R.iv
        elseif R.b2 >= 3 and rnd() < 0.14 then
            d.reloadUntil = now + 1.8
            d.nextFire = d.reloadUntil + 0.3
        else
            d.nextFire = now + (R.r1 + rnd() * (R.r2 - R.r1)) / intensity
        end
    end

    local function throwGrenade(d)
        local tgt = pickEnemy(d.team)
        if not (tgt and d.root and #grenades < 15) then return end
        local p0 = d.root.Position + V3(0, 3, 0)
        local to = V3(tgt.root.Position.X + rr(6), floorY + 0.3, tgt.root.Position.Z + rr(6))
        local Tt = 1.5
        local v0 = (to - p0 - 0.5 * G * Tt * Tt) / Tt
        local part = fxPart(fold, V3(.7, .7, .7), C(50, 70, 40), MAT.Metal, BALL, CF(p0))
        grenades[#grenades + 1] = { p = part, p0 = p0, v0 = v0, t = 0, T = Tt }
    end

    local function fxStep(dt, now)
        local spawned = 0
        for ti = 1, 2 do
            for _, d in ipairs(teamList[ti]) do
                if spawned < 8 and d.root and d.root.Parent and not d.deadAt then
                    if now >= (d.nextFire or 0) then shoot(d, now) spawned = spawned + 1 end
                    if d.role ~= "sniper" and now >= (d.nextGren or 0) then
                        throwGrenade(d)
                        d.nextGren = now + (10 + rnd() * 20) / intensity
                    end
                end
            end
        end
        for i = #bullets, 1, -1 do
            local b = bullets[i]
            b.t = b.t + dt
            local dd = b.t * BSPD
            if dd >= b.dist then
                local e = b.a + b.dir * b.dist
                if b.hit then
                    FX.spark(e)
                    if b.tgt and not b.tgt.deadAt and rnd() < KILL_CHANCE then kill(b.tgt, now) end
                elseif b.ground then
                    FX.dust(V3(e.X, floorY + 0.4, e.Z), 0.5)
                end
                freeTracer(b.p)
                table.remove(bullets, i)
            else
                local pos = b.a + b.dir * dd
                b.p.CFrame = CFrame.lookAt(pos, pos + b.dir)
            end
        end
        for i = #rockets, 1, -1 do
            local r = rockets[i]
            r.t = r.t + dt
            local dd = r.t * 110
            if dd >= r.dist then
                blast(r.a + r.dir * r.dist, 1)
                r.p:Destroy()
                table.remove(rockets, i)
            else
                local pos = r.a + r.dir * dd
                r.p.CFrame = CFrame.lookAt(pos, pos + r.dir)
            end
        end
        for i = #grenades, 1, -1 do
            local g = grenades[i]
            g.t = g.t + dt
            local pos = g.p0 + g.v0 * g.t + 0.5 * G * g.t * g.t
            if g.t >= g.T then
                blast(V3(pos.X, floorY + 0.5, pos.Z), 0.55)
                g.p:Destroy()
                table.remove(grenades, i)
            else
                g.p.CFrame = CF(pos) * ANG(g.t * 9, g.t * 6, 0)
            end
        end
        for i = #casings, 1, -1 do
            local c = casings[i]
            c.t = c.t + dt
            if c.t > 2.5 then
                c.p:Destroy()
                table.remove(casings, i)
            elseif not c.landed then
                local pos = c.p0 + c.v * c.t + 0.5 * G * c.t * c.t
                if pos.Y <= floorY + 0.05 then
                    c.landed = CF(pos.X, floorY + 0.05, pos.Z) * ANG(0, rnd() * 6, 0)
                    c.p.CFrame = c.landed
                else
                    c.p.CFrame = CF(pos) * ANG(c.t * 20, c.t * 13, 0)
                end
            end
        end
    end

    local lastInfo = 0
    m.update = function(dt, now)
        fxStep(dt, now)
        if now - lastInfo > 0.5 then lastInfo = now m.say(info()) end
    end

    m.place = function(now, doStop)
        for ti = 1, 2 do
            for _, d in ipairs(teamList[ti]) do
                if d.dirty then rigRefresh(d) end
                if d.gearDirty and fold then
                    if equip(d) then d.gearDirty = false end
                end
                local root = d.root
                if root and root.Parent and d.cf then
                    local ang = deathAngle(d, now)
                    local pose = d.pose
                    if not pose then pose = {} d.pose = pose end
                    local ro = d.rootOff or rootOff
                    if ang then
                        local P = d.cf * CF(0, -ro, 0)
                        rigPlace(d, P * CF(0, 0.6 * ang / 90, 0) * ANG(rad(ang) * (d.fallDir or 1), 0, 0) * CF(0, ro, 0))
                        for k in pairs(pose) do pose[k] = nil end
                    else
                        local kick = d.kickT and max(0, 1 - (now - d.kickT) * 9) or 0
                        local ph = d.phase
                        local drop = d.crouch and CROUCH_DROP or 0
                        rigPlace(d, d.cf * CF(0, sin(now * 1.6 + ph) * 0.03 - drop, 0)
                            * ANG(rad(kick * 3), sin(now * 0.7 + ph) * 0.025, 0))
                        local sway = sin(now * 1.1 + ph) * 1.5
                        local aR, aL, eR, eL = aimR + sway, aimL - sway, elbR, elbL
                        if d.reloadUntil and now < d.reloadUntil then
                            aR, aL, eR, eL = aR - 35, aL - 30, eR + 40, eL + 55
                        end
                        pose.RightShoulder = ANG(rad(aR + 6 * kick) * sA, 0, 0)
                        pose.LeftShoulder = ANG(rad(aL + 6 * kick) * sA, 0, 0)
                        pose.RightElbow = ANG(rad(eR) * sE, 0, 0)
                        pose.LeftElbow = ANG(rad(eL) * sE, 0, 0)
                        if d.crouch then
                            local h, k = ANG(rad(55), 0, 0), ANG(-rad(105), 0, 0)
                            pose.LeftHip, pose.RightHip, pose.LeftKnee, pose.RightKnee = h, h, k, k
                        else
                            pose.LeftHip, pose.RightHip, pose.LeftKnee, pose.RightKnee = nil, nil, nil, nil
                        end
                    end
                    rigPose(d, pose, doStop)
                    if d.flashOff and now >= d.flashOff then
                        if d.flash then d.flash.Transparency = 1 end
                        if d.flashLight then d.flashLight.Enabled = false end
                        d.flashOff = nil
                    end
                end
            end
        end
    end

    m.start = function()
        local char = lp.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local h = char and char:FindFirstChildOfClass("Humanoid")
        if not myRoot or not h then return false, "karaktermu belum siap" end
        rootOff = h.HipHeight + myRoot.Size.Y / 2
        local yaw = select(2, myRoot.CFrame:ToEulerAnglesYXZ())
        fieldRoot = CF(myRoot.Position) * ANG(0, yaw, 0)
        fieldFloor = fieldRoot * CF(0, -rootOff, 0)
        floorY = myRoot.Position.Y - rootOff
        fold = Instance.new("Folder")
        fold.Name = "Perang"
        fold.Parent = fxRoot
        assign()
        buildField()
        m.say(info())
    end

    m.stop = function()
        for ti = 1, 2 do
            for _, d in ipairs(teamList[ti]) do destroyGear(d) end
        end
        for _, d in pairs(rigs) do destroyGear(d) end
        teamList = { {}, {} }
        bullets, rockets, grenades, casings, pool = {}, {}, {}, {}, {}
        if fold then fold:Destroy() fold = nil end
        FX.clear()
        m.say("siap")
    end

    UI.module(pg, m, "Perang 2 Kubu (P)")
    UI.stepper(pg, "Tembakan", function() return intensity end, function(v) intensity = clamp(v, 0.5, 3) end, 0.25, "x%.2f")
    UI.toggleOpt(pg, "Korban jatuh", function() return casualties end, function(v) casualties = v end)
    UI.toggleOpt(pg, "Termasuk aku", function() return includeMe end, function(v) includeMe = v if m.on then assign() end end)
    UI.row(pg, {
        { text = "Balik lengan", cb = function() sA = -sA end },
        { text = "Balik siku", cb = function() sE = -sE end },
    })
    UI.label(pg, "Baris depan berlutut, ada reload, selongsong, asap moncong, tong terbakar & kabut medan.", 32)
    register(m)
end

-- ===== MODUL: KIAMAT =====
do
    local m = { name = "Kiamat", key = Enum.KeyCode.K, color = C(150, 40, 20) }
    local pg = UI.page("Kiamat")
    local DURATION = 90
    local intensity = 1
    local MAX_METEORS, MAX_SCORCH, MAX_FIRES, MAX_CRACKS = 25, 40, 14, 12

    local ending, fade = false, false
    local fold, whiteFrame
    local meteors, scorches, fires, cracks, bolts = {}, {}, {}, {}, {}
    local floorY, t0, endT = 0, 0, 0
    local meteorAcc, nextBolt, nextCrack = 0, 0, 0
    local lightT = -10
    local planet, glow, planetDir = nil, nil, V3(0, 1, 0)
    local ashPart, ash, ember = nil, nil, nil
    local saved, atm, atmOwn, savedAtm, cc, bloom, blur = {}, nil, false, {}, nil, nil, nil
    local LKEYS = { "Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "FogColor", "FogEnd", "FogStart",
        "ColorShift_Top", "ExposureCompensation" }
    local kp = RaycastParams.new()
    kp.FilterType = Enum.RaycastFilterType.Exclude
    local function cam() return workspace.CurrentCamera end

    local function kGround(x, z, fromY)
        kp.FilterDescendantsInstances = { lp.Character, fxRoot }
        local r = workspace:Raycast(V3(x, fromY, z), V3(0, -1500, 0), kp)
        return r and r.Position.Y or floorY
    end

    local function impact(pos, size)
        local s = size / 7
        FX.explode(pos, s)
        local d = 4 + 10 * s
        scorches[#scorches + 1] = fxPart(fold, V3(.1, d, d), C(22, 17, 14), MAT.Slate, CYL,
            CF(pos.X, pos.Y + 0.06, pos.Z) * ANG(0, 0, rad(90)))
        if #scorches > MAX_SCORCH then scorches[1]:Destroy() table.remove(scorches, 1) end
        if #fires < MAX_FIRES then
            local fp = fxPart(fold, V3(1, 1, 1), C(0, 0, 0), nil, nil, CF(pos + V3(0, 0.5, 0)))
            fp.Transparency = 1
            local f = Instance.new("Fire")
            f.Size, f.Heat = 6 + 6 * s, 9
            f.Color, f.SecondaryColor = C(255, 150, 40), C(200, 40, 20)
            f.Parent = fp
            fires[#fires + 1] = { p = fp, t = 0, life = 8 + rnd() * 5 }
        end
        local c = cam()
        if c then
            local dist = (c.CFrame.Position - pos).Magnitude
            addShake(clamp((1 - dist / 500) * s * 3, 0, 4))
        end
    end

    local function spawnMeteor()
        if #meteors >= MAX_METEORS then return end
        local c = cam()
        if not c then return end
        local cp = c.CFrame.Position
        local ang, r = rnd() * pi * 2, 20 + rnd() ^ 1.5 * 260
        local tx, tz = cp.X + cos(ang) * r, cp.Z + sin(ang) * r
        local ty = kGround(tx, tz, cp.Y + 250)
        local size = 3 + rnd() ^ 2 * 14
        local to = V3(tx, ty, tz)
        local from = to + V3(rr(160), 380 + rnd() * 150, rr(160))
        local dir = to - from
        local rock = fxPart(fold, V3(size, size, size), C(45, 32, 28), MAT.Slate, BALL, CF(from))
        local light = Instance.new("PointLight")
        light.Color, light.Brightness, light.Range = C(255, 140, 50), 4, 40 + size
        light.Parent = rock
        local fe = Instance.new("ParticleEmitter")
        fe.Rate, fe.Lifetime, fe.Speed = 40 + size * 5, NumberRange.new(.5, .9), NumberRange.new(0, 2)
        fe.Size = NumberSequence.new(size * 0.9, 0)
        fe.Color = ColorSequence.new(C(255, 170, 60), C(220, 50, 20))
        fe.LightEmission = 1
        fe.Transparency = NumberSequence.new(0, 1)
        fe.Parent = rock
        local se = Instance.new("ParticleEmitter")
        se.Rate, se.Lifetime, se.Speed = 30, NumberRange.new(2, 3), NumberRange.new(0, 2)
        se.Size = NumberSequence.new(size * 0.8, size * 2.5)
        se.Color = ColorSequence.new(C(60, 55, 55))
        se.Transparency = NumberSequence.new(0.4, 1)
        se.Parent = rock
        meteors[#meteors + 1] = { p = rock, from = from, dirU = dir.Unit, dist = dir.Magnitude, to = to, size = size,
            speed = 170 + rnd() * 60, t = 0 }
    end

    local function spawnCrack()
        local c = cam()
        if not c then return end
        local cp = c.CFrame.Position
        local ang, r = rnd() * pi * 2, 15 + rnd() * 110
        local x, z = cp.X + cos(ang) * r, cp.Z + sin(ang) * r
        local y = kGround(x, z, cp.Y + 100)
        local heading = rnd() * pi * 2
        local parts = {}
        for i = 1, 9 do
            local len = 5 + rnd() * 5
            heading = heading + rr(.6)
            local dx, dz = cos(heading) * len, sin(heading) * len
            local mid = V3(x + dx / 2, y + 0.08, z + dz / 2)
            parts[i] = fxPart(fold, V3(0.6 + rnd() * 0.5, 0.1, len + 0.3), C(255, 110, 30), MAT.Neon, nil,
                CFrame.lookAt(mid, mid + V3(dx, 0, dz)))
            if i == 3 or i == 7 then
                local l = Instance.new("PointLight")
                l.Color, l.Range, l.Brightness = C(255, 110, 40), 16, 1.5
                l.Parent = parts[i]
            end
            x, z = x + dx, z + dz
        end
        cracks[#cracks + 1] = parts
        if #cracks > MAX_CRACKS then
            for _, p in ipairs(cracks[1]) do p:Destroy() end
            table.remove(cracks, 1)
        end
    end

    local function spawnBolt(now)
        if #bolts >= 3 then return end
        local c = cam()
        if not c then return end
        local cp = c.CFrame.Position
        local ang, r = rnd() * pi * 2, 60 + rnd() * 300
        local x, z = cp.X + cos(ang) * r, cp.Z + sin(ang) * r
        local gy = kGround(x, z, cp.Y + 250)
        local prev = V3(x + rr(40), gy + 350, z + rr(40))
        local list = {}
        local segs = 10
        for i = 1, segs do
            local nxt
            if i == segs then
                nxt = V3(x, gy, z)
            else
                nxt = prev:Lerp(V3(x, gy, z), 1 / (segs - i + 1)) + V3(rr(15), 0, rr(15))
            end
            local len = (nxt - prev).Magnitude
            list[#list + 1] = fxPart(fold, V3(.7, .7, len), C(225, 232, 255), MAT.Neon, nil,
                CFrame.lookAt((nxt + prev) / 2, nxt))
            prev = nxt
        end
        bolts[#bolts + 1] = { parts = list, t = 0 }
        lightT = now
        addShake(0.8)
    end

    local function saveLighting()
        saved = {}
        for _, k in ipairs(LKEYS) do saved[k] = Lighting[k] end
        atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            atmOwn = false
            savedAtm = { Density = atm.Density, Offset = atm.Offset, Color = atm.Color, Decay = atm.Decay,
                Glare = atm.Glare, Haze = atm.Haze }
        else
            atmOwn = true
            atm = Instance.new("Atmosphere")
            atm.Parent = Lighting
        end
        cc = Instance.new("ColorCorrectionEffect")
        cc.Parent = Lighting
        bloom = Instance.new("BloomEffect")
        bloom.Size, bloom.Threshold = 24, 0.9
        bloom.Parent = Lighting
        blur = Instance.new("BlurEffect")
        blur.Size = 0
        blur.Parent = Lighting
    end

    local function restoreLighting()
        for k, v in pairs(saved) do pcall(function() Lighting[k] = v end) end
        if atm then
            if atmOwn then atm:Destroy()
            else for k, v in pairs(savedAtm) do pcall(function() atm[k] = v end) end end
        end
        atm = nil
        if cc then cc:Destroy() cc = nil end
        if bloom then bloom:Destroy() bloom = nil end
        if blur then blur:Destroy() blur = nil end
    end

    local function applyLighting(p, now)
        local ft = now - lightT
        local fl = 0
        if ft < 0.3 then fl = max(0, 1 - ft / 0.3) * (abs(sin(ft * 40)) * 0.5 + 0.5) end
        local dusk = min(1, p * 8)
        Lighting.Brightness = saved.Brightness * (1 - 0.65 * p) + fl * 2
        Lighting.ClockTime = saved.ClockTime + (17.8 - saved.ClockTime) * dusk
        local dark = C(90, 35, 25)
        Lighting.Ambient = saved.Ambient:Lerp(dark, p):Lerp(Color3.new(1, 1, 1), fl * 0.8)
        Lighting.OutdoorAmbient = saved.OutdoorAmbient:Lerp(dark, p):Lerp(Color3.new(1, 1, 1), fl * 0.8)
        Lighting.FogColor = saved.FogColor:Lerp(C(90, 30, 20), p)
        Lighting.FogEnd = saved.FogEnd + (900 - saved.FogEnd) * p
        Lighting.FogStart = saved.FogStart + (50 - saved.FogStart) * p
        Lighting.ColorShift_Top = saved.ColorShift_Top:Lerp(C(255, 120, 60), p)
        if atm then
            atm.Density, atm.Offset = 0.25 + 0.3 * p, 0.2
            atm.Color = C(199, 170, 150):Lerp(C(230, 80, 40), min(1, p * 2))
            atm.Decay = C(110, 35, 20)
            atm.Glare, atm.Haze = 2 * p, 2 + 3 * p
        end
        if cc then
            cc.TintColor = Color3.new(1, 1, 1):Lerp(C(255, 140, 100), p)
            cc.Saturation, cc.Contrast = -0.1 * p, 0.1 * p
            cc.Brightness = -0.05 * p + fl * 0.25
        end
        if bloom then bloom.Intensity = 0.4 + 0.6 * p end
        if blur then blur.Size = clamp((p - 0.85) / 0.15, 0, 1) * 14 end
    end

    m.update = function(dt, now)
        local t = now - t0
        local p = clamp(t / DURATION, 0, 1)
        if t >= DURATION and not ending then
            ending, endT = true, now
            if whiteFrame then TweenService:Create(whiteFrame, TweenInfo.new(1.4), { BackgroundTransparency = 0 }):Play() end
        end
        applyLighting(p, now)
        Hub.baseShake = 0.15 + 1.2 * p + (ending and 4 or 0)

        meteorAcc = meteorAcc + (0.4 + 7 * p ^ 1.3) * intensity * dt
        while meteorAcc >= 1 do
            meteorAcc = meteorAcc - 1
            spawnMeteor()
        end
        for i = #meteors, 1, -1 do
            local mt = meteors[i]
            mt.t = mt.t + dt
            local dd = mt.t * mt.speed
            if dd >= mt.dist then
                impact(mt.to, mt.size)
                mt.p:Destroy()
                table.remove(meteors, i)
            else
                mt.p.CFrame = CF(mt.from + mt.dirU * dd) * ANG(mt.t * 2, mt.t * 1.3, 0)
            end
        end
        if p > 0.12 and now >= nextBolt then
            spawnBolt(now)
            nextBolt = now + (3 + rnd() * 5) / (0.4 + p * 1.5)
        end
        if p > 0.2 and now >= nextCrack then
            spawnCrack()
            nextCrack = now + 2 / (0.5 + p)
        end
        for i = #bolts, 1, -1 do
            local b = bolts[i]
            b.t = b.t + dt
            if b.t > 0.18 then
                for _, x in ipairs(b.parts) do x:Destroy() end
                table.remove(bolts, i)
            end
        end
        for i = #fires, 1, -1 do
            local f = fires[i]
            f.t = f.t + dt
            if f.t > f.life then f.p:Destroy() table.remove(fires, i) end
        end
        if ash then ash.Rate = (40 + 260 * p) * intensity end
        if ember then ember.Rate = 120 * p * intensity end
        if planet then
            planet.Transparency = 1 - clamp(p / 0.2, 0, 1) * 0.9
            local sz = 400 + 1600 * p ^ 1.5
            planet.Size = V3(sz, sz, sz)
            if glow then
                glow.Size = V3(sz * 1.18, sz * 1.18, sz * 1.18)
                glow.Transparency = 1 - clamp(p / 0.2, 0, 1) * 0.16
            end
        end
        local phase = p < 0.17 and "Langit memerah..." or (p < 0.5 and "Hujan meteor" or (p < 0.85 and "Bumi bergetar" or "Akhir..."))
        m.say(string.format("%s | sisa %ds | meteor x%.2f", phase, max(0, math.ceil(DURATION - t)), intensity))
        if ending and now - endT > 3.5 then
            fade = true
            Hub.setOn(m, false)
        end
    end

    m.render = function()
        local c = cam()
        if not c then return end
        local cp = c.CFrame.Position
        if planet then
            local p = clamp((os.clock() - t0) / DURATION, 0, 1)
            local cf = CF(cp + planetDir * (5000 - 3300 * p ^ 1.5))
            planet.CFrame = cf
            if glow then glow.CFrame = cf end
        end
        if ashPart then ashPart.CFrame = CF(cp + V3(0, 25, 0)) end
    end

    m.start = function()
        local c = cam()
        if not c then return false, "kamera belum siap" end
        local ch = lp.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        floorY = (root and h) and (root.Position.Y - (h.HipHeight + root.Size.Y / 2)) or (c.CFrame.Position.Y - 5)
        ending = false
        t0 = os.clock()
        meteorAcc, nextBolt, nextCrack, lightT = 0, t0 + 6, t0 + 10, -10
        fold = Instance.new("Folder")
        fold.Name = "Kiamat"
        fold.Parent = fxRoot
        saveLighting()
        local look = c.CFrame.LookVector
        local hv = V3(look.X, 0, look.Z)
        if hv.Magnitude < 0.1 then hv = V3(0, 0, -1) end
        planetDir = (hv.Unit * 0.9 + V3(0, 0.55, 0)).Unit
        planet = fxPart(fold, V3(400, 400, 400), C(255, 90, 40), MAT.Neon, BALL)
        planet.Transparency, planet.CastShadow = 1, false
        glow = fxPart(fold, V3(470, 470, 470), C(255, 60, 20), MAT.Neon, BALL)
        glow.Transparency, glow.CastShadow = 1, false
        ashPart = fxPart(fold, V3(160, 1, 160), C(0, 0, 0), nil, nil, c.CFrame)
        ashPart.Transparency = 1
        ash = Instance.new("ParticleEmitter")
        ash.Rate = 0
        ash.Lifetime, ash.Speed = NumberRange.new(6, 8), NumberRange.new(4, 10)
        ash.EmissionDirection = Enum.NormalId.Bottom
        ash.Size = NumberSequence.new(0.25)
        ash.Color = ColorSequence.new(C(70, 60, 55))
        ash.Transparency = NumberSequence.new(0.2, 0.9)
        ash.Acceleration = V3(10, -4, 4)
        ash.RotSpeed = NumberRange.new(-90, 90)
        ash.Parent = ashPart
        ember = Instance.new("ParticleEmitter")
        ember.Rate = 0
        ember.Lifetime, ember.Speed = NumberRange.new(3, 5), NumberRange.new(2, 6)
        ember.EmissionDirection = Enum.NormalId.Bottom
        ember.Size = NumberSequence.new(0.2)
        ember.Color = ColorSequence.new(C(255, 140, 50))
        ember.LightEmission = 1
        ember.Transparency = NumberSequence.new(0, 1)
        ember.Acceleration = V3(8, 2, 3)
        ember.Parent = ashPart
    end

    m.stop = function()
        local wasFade = fade
        fade = false
        ending = false
        restoreLighting()
        Hub.baseShake = 0
        if fold then fold:Destroy() fold = nil end
        meteors, scorches, fires, cracks, bolts = {}, {}, {}, {}, {}
        planet, glow, ashPart, ash, ember = nil, nil, nil, nil, nil
        FX.clear()
        if whiteFrame then
            if wasFade then
                TweenService:Create(whiteFrame, TweenInfo.new(2.5), { BackgroundTransparency = 1 }):Play()
            else
                whiteFrame.BackgroundTransparency = 1
            end
        end
        m.say("siap | tekan K untuk kiamat")
    end

    whiteFrame = Instance.new("Frame")
    whiteFrame.Size = UDim2.fromScale(1, 1)
    whiteFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    whiteFrame.BackgroundTransparency = 1
    whiteFrame.BorderSizePixel = 0
    whiteFrame.Active = false
    whiteFrame.ZIndex = 0
    whiteFrame.Parent = gui

    UI.module(pg, m, "Kiamat (K)")
    UI.stepper(pg, "Meteor", function() return intensity end, function(v) intensity = clamp(v, 0.25, 3) end, 0.25, "x%.2f")
    UI.stepper(pg, "Durasi (detik)", function() return DURATION end, function(v)
        if not m.on then DURATION = clamp(v, 30, 240) end
    end, 15, "%d")
    UI.label(pg, "Langit memerah, hujan meteor, petir, retakan lava, planet mendekat, ledakan putih, lalu normal lagi. Panel tetap bisa dipakai.", 44)
    register(m)
end

-- ===== MODUL: SEMUA PLAYER BERANTEM =====
do
    local m = { name = "Berantem", excl = true, key = Enum.KeyCode.H, color = C(150, 70, 20) }
    local pg = UI.page("Berantem")
    local intensity = 1
    local sA, sE, sT, sL = 1, 1, 1, 1
    local SEP = 3.4
    local STANCE_YAW = rad(24)
    local MAX_FX = 40
    local COMIC = false
    local HIT_TEXT = { "POW!", "BAM!", "DUAK!", "BUK!", "PLAK!", "WHAM!" }
    local KO_TEXT = { "KRAK!!", "HANTAM!!" }
    local MOVE_KEYS = { "jabL", "crossR", "hookL", "hookR", "jabL", "crossR" }

    local duels, all = {}, {}
    local fold
    local pows = {}
    local floorY = 0
    local lastInfo = 0

    local function info()
        local spec = 0
        for _, d in ipairs(all) do if d.spectator then spec = spec + 1 end end
        return string.format("%s | %d pasangan, wasit %d | sengit x%.2f", m.on and "BERANTEM" or "siap", #duels, spec, intensity)
    end

    -- ===== pose (derajat) =====
    local LEGD = { lh = 14, lk = 18, rh = -14, rk = 26 }
    local function mk(t)
        for k, v in pairs(LEGD) do if t[k] == nil then t[k] = v end end
        return t
    end
    local GUARD = mk { rS = 50, rE = 105, rY = -5, lS = 55, lE = 110, lY = 5, tw = 0 }
    local HITP = mk { rS = 15, rE = 28, rY = -10, lS = 22, lE = 35, lY = 10, tw = -10, lh = -6, lk = 24, rh = -18, rk = 30 }
    local BLOCK = mk { rS = 100, rE = 135, rY = -12, lS = 100, lE = 135, lY = 12, tw = 0 }
    local DODGEP = mk { rS = 50, rE = 105, rY = -5, lS = 55, lE = 110, lY = 5, tw = -18, lh = 30, lk = 55, rh = 30, rk = 55 }
    local CHEER = mk { rS = 150, rE = 70, rY = -8, lS = 150, lE = 70, lY = 8, tw = 0, lh = 0, lk = 4, rh = 0, rk = 4 }
    local REF = mk { rS = 8, rE = 15, rY = 0, lS = 8, lE = 15, lY = 0, tw = 0 }
    local MOVES = {
        jabL = { W = mk { rS = 50, rE = 105, rY = -5, lS = 58, lE = 135, lY = 8, tw = 4 },
            S = mk { rS = 50, rE = 105, rY = -5, lS = 88, lE = 6, lY = -4, tw = -10 } },
        crossR = { W = mk { rS = 48, rE = 135, rY = -8, lS = 55, lE = 110, lY = 5, tw = -8 },
            S = mk { rS = 88, rE = 6, rY = 4, lS = 58, lE = 115, lY = 5, tw = 24 } },
        hookR = { W = mk { rS = 85, rE = 95, rY = -55, lS = 55, lE = 110, lY = 5, tw = -14 },
            S = mk { rS = 88, rE = 90, rY = 38, lS = 55, lE = 110, lY = 5, tw = 32 } },
        hookL = { W = mk { rS = 50, rE = 105, rY = -5, lS = 85, lE = 95, lY = 55, tw = 14 },
            S = mk { rS = 50, rE = 105, rY = -5, lS = 88, lE = 90, lY = -38, tw = -32 } },
    }

    local tmp = {}
    local function lerpP(a, b, t)
        t = smooth(t)
        for k, v in pairs(a) do tmp[k] = v + (b[k] - v) * t end
    end

    local function poseFor(d, now)
        local st = d.state
        tmp.nx, tmp.ny = 0, 0
        if d.spectator then
            lerpP(REF, REF, 0)
            local w = now * 5 + d.phase
            tmp.lh, tmp.rh = 22 * sin(w), -22 * sin(w)
            tmp.lk = 8 + 16 * max(0, sin(w + 1.2))
            tmp.rk = 8 + 16 * max(0, -sin(w + 1.2))
            tmp.rS, tmp.lS = 8 - 12 * sin(w), 8 + 12 * sin(w)
        elseif st == "punch" then
            local u = clamp((now - d.stT) / d.dur, 0, 1)
            local mv = MOVES[d.move]
            if u < 0.25 then lerpP(GUARD, mv.W, u / 0.25)
            elseif u < 0.45 then lerpP(mv.W, mv.S, (u - 0.25) / 0.2)
            else lerpP(mv.S, GUARD, (u - 0.45) / 0.55) end
            local bump = sin(u * pi)
            tmp.lh, tmp.lk = tmp.lh + 14 * bump, tmp.lk + 8 * bump
            tmp.rh, tmp.rk = tmp.rh + 10 * bump, tmp.rk - 6 * bump
        elseif st == "hit" then
            local u = clamp((now - d.stT) / d.stDur, 0, 1)
            if u < 0.3 then lerpP(GUARD, HITP, u / 0.3) else lerpP(HITP, GUARD, (u - 0.3) / 0.7) end
        elseif st == "block" then
            local u = clamp((now - d.stT) / d.stDur, 0, 1)
            if u < 0.3 then lerpP(GUARD, BLOCK, u / 0.3) else lerpP(BLOCK, GUARD, (u - 0.3) / 0.7) end
        elseif st == "dodge" then
            local u = clamp((now - d.stT) / d.stDur, 0, 1)
            if u < 0.4 then lerpP(GUARD, DODGEP, u / 0.4) else lerpP(DODGEP, GUARD, (u - 0.4) / 0.6) end
        elseif d.opp and d.opp.state == "down" then
            local s = sin(now * 5 + d.phase)
            lerpP(CHEER, CHEER, 0)
            tmp.rS, tmp.lS = 150 + s * 6, 150 - s * 6
        else
            lerpP(GUARD, GUARD, 0)
            local tired = d.hp < 35
            local sp = tired and 3.5 or 5
            local amp = tired and 1.5 or 1
            tmp.rE = tmp.rE + 4 * amp * sin(now * sp + d.phase)
            tmp.lE = tmp.lE + 4 * amp * sin(now * sp + d.phase + 1.5)
            tmp.tw = 3 * sin(now * 2 + d.phase)
            tmp.lh = tmp.lh + 4 * sin(now * sp + d.phase)
            tmp.rh = tmp.rh - 4 * sin(now * sp + d.phase)
            tmp.lk = tmp.lk + 5 * (sin(now * sp + d.phase) * 0.5 + 0.5)
            tmp.rk = tmp.rk + 5 * (sin(now * sp + d.phase + pi) * 0.5 + 0.5)
            if tired then tmp.rS, tmp.lS = tmp.rS - 12, tmp.lS - 12 end
        end
        if d.jT then
            local k = 1 - clamp((now - d.jT) / 0.4, 0, 1)
            tmp.nx, tmp.ny = d.jx * k, d.jy * k
        end
        if d.yaw and d.yaw ~= 0 then tmp.ny = tmp.ny - deg(d.yaw) * 0.8 end
        return tmp
    end

    local jp = {}
    local function buildPoses(ps)
        jp.RightShoulder = ANG(0, rad(ps.rY) * sT, 0) * ANG(rad(ps.rS) * sA, 0, 0)
        jp.LeftShoulder = ANG(0, rad(ps.lY) * sT, 0) * ANG(rad(ps.lS) * sA, 0, 0)
        jp.RightElbow = ANG(rad(ps.rE) * sE, 0, 0)
        jp.LeftElbow = ANG(rad(ps.lE) * sE, 0, 0)
        jp.Waist = ANG(0, rad(ps.tw) * sT, 0)
        jp.Neck = ANG(rad(ps.nx), rad(ps.ny), 0)
        jp.LeftHip = ANG(rad(ps.lh) * sL, 0, 0)
        jp.RightHip = ANG(rad(ps.rh) * sL, 0, 0)
        jp.LeftKnee = ANG(-rad(ps.lk) * sL, 0, 0)
        jp.RightKnee = ANG(-rad(ps.rk) * sL, 0, 0)
    end

    -- ===== efek komik (opsional) =====
    local function spark(pos)
        if COMIC then FX.spark(pos) end
    end
    local function pow(pos, text, color, big)
        if not COMIC or #pows >= 14 or not fold then return end
        local p = fxPart(fold, V3(.2, .2, .2), C(0, 0, 0), nil, nil, CF(pos))
        p.Transparency = 1
        local bg = Instance.new("BillboardGui")
        bg.Size = UDim2.fromOffset(big and 150 or 100, big and 60 or 40)
        bg.AlwaysOnTop = true
        bg.Parent = p
        local tlb = Instance.new("TextLabel")
        tlb.Size, tlb.BackgroundTransparency, tlb.Text = UDim2.fromScale(1, 1), 1, text
        tlb.Font, tlb.TextScaled, tlb.TextColor3, tlb.TextStrokeTransparency = Enum.Font.GothamBlack, true, color, 0
        tlb.Parent = bg
        pows[#pows + 1] = { p = p, tl = tlb, t = 0, pos = pos }
    end
    local function fxUpdate(dt)
        for i = #pows, 1, -1 do
            local w = pows[i]
            w.t = w.t + dt
            if w.t >= 0.7 then
                w.p:Destroy()
                table.remove(pows, i)
            else
                w.p.CFrame = CF(w.pos + V3(0, w.t * 4, 0))
                if w.t > 0.4 then
                    local f = (w.t - 0.4) / 0.3
                    w.tl.TextTransparency, w.tl.TextStrokeTransparency = f, f
                end
            end
        end
    end

    -- ===== pertarungan =====
    local function knockdown(v, now)
        v.state, v.deadAt = "down", now
        v.lieFor = 3.1 + rnd() * 2
        v.fallDir = rnd() < 0.5 and 1 or -1
        v.hp = 100
        local pos = v.pos or V3()
        FX.dust(pos - V3(0, (v.rootOff or 3) - 0.3, 0), 1)
        pow(pos + V3(0, 3, 0), KO_TEXT[rnd(#KO_TEXT)], C(255, 70, 50), true)
    end

    local function awayFrom(vic, att)
        local away = flat(vic.pos - att.pos)
        if away.Magnitude < 0.01 then away = att.fwd end
        return away.Unit
    end

    local function hit(vic, att, now)
        local crit = rnd() < 0.1 or (att.move == "crossR" and rnd() < 0.12)
        vic.hp = vic.hp - (7 + rnd() * 8) * (crit and 2 or 1)
        vic.state, vic.stT, vic.stDur = "hit", now, 0.4
        local away = awayFrom(vic, att)
        vic.kbT = now
        vic.kbVec = away * (crit and 3.2 or 1.4)
        if att.move == "hookL" or att.move == "hookR" then
            vic.jx = rr(8)
            vic.jy = (rnd() < 0.5 and 1 or -1) * (25 + (crit and 15 or 0))
        else
            vic.jx = 14 + (crit and 25 or 0) + rr(6)
            vic.jy = rr(8)
        end
        vic.jT = now
        local hp = vic.pos - away * 0.8 + V3(0, 1, 0)
        spark(hp)
        pow(hp + V3(0, 1.5, 0), crit and KO_TEXT[rnd(#KO_TEXT)] or HIT_TEXT[rnd(#HIT_TEXT)],
            crit and C(255, 120, 50) or C(255, 230, 90), crit)
        local cam = workspace.CurrentCamera
        if crit and cam and (cam.CFrame.Position - vic.pos).Magnitude < 60 then addShake(0.5) end
        if vic.hp <= 0 or (crit and rnd() < 0.4) then knockdown(vic, now) end
    end

    local function block(vic, att, now)
        vic.state, vic.stT, vic.stDur = "block", now, 0.35
        vic.kbT = now
        vic.kbVec = awayFrom(vic, att) * 0.5
        local hp = vic.pos - awayFrom(vic, att) * 0.8 + V3(0, 1.2, 0)
        spark(hp)
        pow(hp + V3(0, 1.2, 0), "TANG!", Color3.new(1, 1, 1), false)
    end

    local function dodge(vic, att, now)
        vic.state, vic.stT, vic.stDur = "dodge", now, 0.35
        local away = awayFrom(vic, att)
        local side = V3(-away.Z, 0, away.X) * (rnd() < 0.5 and 1 or -1)
        vic.kbT = now
        vic.kbVec = side * 1.6 + away * 0.6
    end

    local function resolve(att, vic, now)
        if vic.state == "down" then return end
        local r = rnd()
        if r < 0.55 then hit(vic, att, now)
        elseif r < 0.75 then block(vic, att, now)
        else dodge(vic, att, now) end
    end

    local function startAttack(d, now, chain)
        local mv = MOVE_KEYS[rnd(#MOVE_KEYS)]
        if chain and mv == d.move then mv = MOVE_KEYS[rnd(#MOVE_KEYS)] end
        d.move = mv
        d.dur = 0.28 + rnd() * 0.14
        d.state, d.stT, d.struck = "punch", now, false
    end

    local function deathAngle(d, now)
        if not d.deadAt then return nil end
        local t = now - d.deadAt
        if t < 0.5 then return 90 * (t / 0.5) ^ 2
        elseif t < d.lieFor then return 90
        elseif t < d.lieFor + 0.8 then return 90 * (1 - (t - d.lieFor) / 0.8) end
        d.deadAt = nil
        d.state = "guard"
        d.nextAtk = now + 1
        return nil
    end

    local function motion(d, now)
        local ro = d.rootOff or 3
        if d.spectator then
            local pr = d.spec.pr
            local a = pr.th + pi / 2 + sin(now * 0.3 + d.phase) * 0.7
            local pos = pr.c + V3(cos(a), 0, sin(a)) * 6.5
            d.pos = V3(pos.X, pr.gy + ro, pos.Z)
            d.fwd = flat(pr.c - pos).Unit
            d.tilt, d.yaw = 0, 0
            return
        end
        local pr = d.pair
        local u = V3(cos(pr.th), 0, sin(pr.th))
        local sg = d.idx == 1 and 1 or -1
        local sep = SEP + 0.25 * sin(now * 1.3 + pr.ph)
        local base = pr.c + u * (sep / 2 * sg)
        local fwd = -u * sg
        local off = V3()
        if d.kbT then
            local t = now - d.kbT
            if t > 0.5 then
                d.kbT = nil
            else
                local f = t < 0.08 and t / 0.08 or max(0, 1 - (t - 0.08) / 0.4) ^ 2
                off = off + d.kbVec * f
            end
        end
        local tilt, yaw = 0, -STANCE_YAW
        if d.state == "punch" then
            local bump = sin(clamp((now - d.stT) / d.dur, 0, 1) * pi)
            off = off + fwd * 0.7 * bump
            tilt = -rad(8) * bump
            local open = (d.move == "crossR" or d.move == "hookR") and 0.7 or 0.3
            yaw = yaw * (1 - open * bump)
        elseif d.state == "hit" then
            tilt = rad(14) * (1 - clamp((now - d.stT) / 0.4, 0, 1))
        elseif d.state == "dodge" then
            tilt = rad(10) * (1 - clamp((now - d.stT) / 0.35, 0, 1))
        else
            tilt = rad(2) * sin(now * 2 + d.phase)
        end
        d.pos = V3(base.X + off.X, pr.gy + ro, base.Z + off.Z)
        d.fwd = fwd
        d.tilt, d.yaw = tilt, yaw
    end

    local function logicFighter(d, now)
        if d.spectator then return end
        local opp, st = d.opp, d.state
        if st == "punch" then
            local t = now - d.stT
            if not d.struck and t >= d.dur * 0.45 then
                d.struck = true
                if opp then resolve(d, opp, now) end
            end
            if t >= d.dur then
                local chain = (d.combo or 1) < 3 and rnd() < 0.3 and opp and opp.state ~= "down"
                if chain then
                    d.combo = (d.combo or 1) + 1
                    startAttack(d, now, true)
                else
                    d.combo = 1
                    d.state = "guard"
                    d.nextAtk = now + (0.5 + rnd() * 1.3) / intensity * (d.hp < 35 and 1.5 or 1)
                end
            end
        elseif st == "hit" or st == "block" or st == "dodge" then
            if now - d.stT >= d.stDur then d.state = "guard" end
        elseif st == "guard" then
            if now >= (d.nextAtk or 0) and opp and opp.state ~= "down" then
                d.combo = 1
                startAttack(d, now, false)
            end
        end
    end

    local function assign(myPos, myYaw)
        if fold then fold:ClearAllChildren() end
        pows = {}
        local order = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and rigs[p] then order[#order + 1] = p end
        end
        table.sort(order, function(a, b) return a.Name < b.Name end)
        duels, all = {}, {}
        local now = os.clock()
        local nDuel = floor(#order / 2)
        local R = max(14, nDuel * 4.5)
        local function setup(d)
            d.state, d.hp, d.deadAt, d.kbT, d.jT, d.combo = "guard", 100, nil, nil, nil, 1
            d.nextAtk = now + rnd() * 1.5
            all[#all + 1] = d
        end
        for k = 1, nDuel do
            local da, db = rigs[order[2 * k - 1]], rigs[order[2 * k]]
            local ang = myYaw + (k - 1) * (2 * pi / nDuel)
            local cx, cz = myPos.X + (-sin(ang)) * R, myPos.Z + (-cos(ang)) * R
            local pr = { a = da, b = db, th = rnd() * 6.28, om = rr(0.35), ph = rnd() * 6.28 }
            pr.gy = groundAt(cx, cz, myPos.Y + 60, floorY)
            pr.c = V3(cx, pr.gy, cz)
            -- ring arena di bawah tiap pasangan
            fxPart(fold, V3(0.1, 14.4, 14.4), C(230, 205, 120), MAT.SmoothPlastic, CYL, CF(cx, pr.gy + 0.05, cz) * ANG(0, 0, rad(90)))
            fxPart(fold, V3(0.14, 13, 13), C(34, 34, 42), MAT.Slate, CYL, CF(cx, pr.gy + 0.08, cz) * ANG(0, 0, rad(90)))
            setup(da) setup(db)
            da.pair, da.idx, da.opp, da.spectator, da.spec = pr, 1, db, false, nil
            db.pair, db.idx, db.opp, db.spectator, db.spec = pr, 2, da, false, nil
            duels[#duels + 1] = pr
        end
        if #order % 2 == 1 and duels[1] then
            local d = rigs[order[#order]]
            if d then
                setup(d)
                d.spectator, d.pair, d.opp = true, nil, nil
                d.spec = { pr = duels[1] }
            end
        end
        for _, d in ipairs(all) do
            if d.dirty then rigRefresh(d) end
            motion(d, now)
        end
    end

    local function myInfo()
        local char = lp.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        return myRoot.Position, select(2, myRoot.CFrame:ToEulerAnglesYXZ())
    end
    m.roster = function()
        if not m.on then return end
        local pos, yaw = myInfo()
        if pos then assign(pos, yaw) end
    end

    m.update = function(dt, now)
        for _, pr in ipairs(duels) do
            pr.th = pr.th + pr.om * dt
            motion(pr.a, now)
            motion(pr.b, now)
            logicFighter(pr.a, now)
            logicFighter(pr.b, now)
        end
        for _, d in ipairs(all) do
            if d.spectator then motion(d, now) end
        end
        fxUpdate(dt)
        if now - lastInfo > 0.5 then lastInfo = now m.say(info()) end
    end

    m.place = function(now, doStop)
        for _, d in ipairs(all) do
            if d.dirty then rigRefresh(d) end
            local root = d.root
            if root and root.Parent and d.pos then
                local ro = d.rootOff or 3
                local ang = deathAngle(d, now)
                local ps = nil
                if not ang then ps = poseFor(d, now) end
                if ang then
                    local P = CFrame.lookAt(d.pos, d.pos + d.fwd) * CF(0, -ro, 0)
                    rigPlace(d, P * CF(0, 0.6 * ang / 90, 0) * ANG(rad(ang) * (d.fallDir or 1), 0, 0) * CF(0, ro, 0))
                    for k in pairs(jp) do jp[k] = nil end
                else
                    local p0 = d.pos - V3(0, legDrop(ps.lh, ps.lk, ps.rh, ps.rk), 0)
                    rigPlace(d, CFrame.lookAt(p0, p0 + d.fwd)
                        * ANG(d.tilt or 0, (d.yaw or 0) + 0.03 * sin(now * 0.9 + d.phase), 0))
                    buildPoses(ps)
                end
                rigPose(d, jp, doStop)
            end
        end
    end

    m.start = function()
        local char = lp.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        local h = char and char:FindFirstChildOfClass("Humanoid")
        local others = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and rigs[p] then others = others + 1 end
        end
        if not myRoot or not h then return false, "karaktermu belum siap" end
        if others < 2 then return false, "butuh minimal 2 pemain lain" end
        floorY = myRoot.Position.Y - (h.HipHeight + myRoot.Size.Y / 2)
        fold = Instance.new("Folder")
        fold.Name = "Berantem"
        fold.Parent = fxRoot
        local pos, yaw = myInfo()
        assign(pos, yaw)
        m.say(info())
    end

    m.stop = function()
        duels, all, pows = {}, {}, {}
        if fold then fold:Destroy() fold = nil end
        FX.clear()
        m.say("siap")
    end

    UI.module(pg, m, "Berantem (H)")
    UI.stepper(pg, "Sengit", function() return intensity end, function(v) intensity = clamp(v, 0.5, 3) end, 0.25, "x%.2f")
    UI.toggleOpt(pg, "Teks komik (POW!)", function() return COMIC end, function(v) COMIC = v end)
    UI.row(pg, {
        { text = "Balik lengan", cb = function() sA = -sA end },
        { text = "Balik siku", cb = function() sE = -sE end },
    })
    UI.row(pg, {
        { text = "Balik badan", cb = function() sT = -sT end },
        { text = "Balik kaki", cb = function() sL = -sL end },
    })
    UI.label(pg, "Kuda-kuda, kombo 1-3 pukulan, tangkis, mengelak, petarung lelah, KO, wasit berkeliling, ring di tanah.", 32)
    register(m)
end

-- ===== MODUL: SEMUA PLAYER JADI HEWAN =====
do
    local m = { name = "Hewan", excl = true, key = Enum.KeyCode.J, color = C(40, 110, 60) }
    local pg = UI.page("Hewan")
    local SIZE, INCLUDE_ME = 1.25, true
    local fold
    local A, assigned, used = {}, {}, {}
    local reroll = 0
    local SMOOTH, FUR = MAT.SmoothPlastic, MAT.Fabric
    local lastLabel = 0

    local function pick(rng, t) return t[rng:NextInteger(1, #t)] end
    local function rn(rng, a, b) return rng:NextNumber(a, b) end

    -- ===== rig: tulang + bagian =====
    local function newSpec() return { bones = {}, idx = {}, B = {}, leg = {} } end
    local function bone(sp, name, parent, off)
        local b = { name = name, parent = parent and sp.idx[parent] or nil, off = off or CF(),
            parts = {}, rot = CF(), pos = V3(), base = CF() }
        sp.bones[#sp.bones + 1] = b
        sp.idx[name] = #sp.bones
        sp.B[name] = b
        return b
    end
    local function part(b, kind, size, cf, color, mat)
        b.parts[#b.parts + 1] = { kind = kind, size = size, cf = cf, color = color, mat = mat or SMOOTH }
    end
    local function blk(b, size, cf, color, mat) part(b, "block", size, cf, color, mat) end
    local function ball(b, size, cf, color, mat) part(b, "ball", size, cf, color, mat) end
    local function cyl(b, dia, len, cf, color, mat) part(b, "cyl", V3(dia, len, dia), cf, color, mat) end
    local function cylZ(b, dia, len, cf, color, mat) part(b, "cyl", V3(dia, len, dia), cf * ANG(pi / 2, 0, 0), color, mat) end

    local function instantiate(sp, parent)
        local inst = { bones = sp.bones, plist = {}, cfs = {} }
        local folder = Instance.new("Folder")
        folder.Name = "Hewan"
        folder.Parent = parent
        inst.folder = folder
        for _, b in ipairs(sp.bones) do
            b.world = CF()
            for _, pd in ipairs(b.parts) do
                local p = Instance.new("Part")
                p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = true, false, false, false, true
                p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
                p.CastShadow = pd.size.Magnitude > 1.6
                p.Color, p.Material = pd.color, pd.mat
                if pd.kind == "ball" then
                    p.Shape = BALL
                    p.Size = pd.size
                elseif pd.kind == "cyl" then
                    p.Shape = CYL
                    p.Size = V3(pd.size.Y, pd.size.X, pd.size.Z)
                    pd.fix = ANG(0, 0, pi / 2)
                else
                    p.Size = pd.size
                end
                p.Parent = folder
                inst.plist[#inst.plist + 1] = p
            end
        end
        return inst
    end

    local function updateInst(inst, base)
        local bones, cfs = inst.bones, inst.cfs
        local n = 0
        for i = 1, #bones do
            local b = bones[i]
            local pw = b.parent and bones[b.parent].world or base
            local w = pw * b.off * CF(b.pos) * b.rot
            b.world = w
            local ps = b.parts
            for j = 1, #ps do
                local pd = ps[j]
                n = n + 1
                cfs[n] = pd.fix and (w * pd.cf * pd.fix) or (w * pd.cf)
            end
        end
        workspace:BulkMoveTo(inst.plist, cfs, Enum.BulkMoveMode.FireCFrameChanged)
    end

    -- IK 2 ruas: k=-1 siku ke belakang (kaki depan), k=+1 lutut ke depan (kaki belakang)
    local function ik2(a, b, f, y, k)
        local d = sqrt(f * f + y * y)
        local dmax = (a + b) * 0.999
        local dmin = abs(a - b) + 0.02 * (a + b)
        if d > dmax then
            f, y, d = f * dmax / d, y * dmax / d, dmax
        elseif d < dmin then
            if d < 1e-4 then f, y = 0, -dmin else f, y = f * dmin / d, y * dmin / d end
            d = dmin
        end
        local phi = atan2(f, -y)
        local al = acos(clamp((a * a + d * d - b * b) / (2 * a * d), -1, 1))
        local be = acos(clamp((b * b + d * d - a * a) / (2 * b * d), -1, 1))
        return phi + k * al, phi - k * be
    end

    local function setLeg(sp, nm, fx, yt, psi)
        local L, B = sp.leg[nm], sp.B
        local t1, t2 = ik2(L.a, L.b, fx, yt, L.k)
        B[nm .. "1"].rot = ANG(t1, 0, 0)
        B[nm .. "2"].rot = ANG(t2 - t1, 0, 0)
        B[nm .. "3"].rot = ANG(psi - t2, 0, 0)
    end

    -- ===== pembangun berkaki empat =====
    local function buildQuad(P, rng)
        local sp = newSpec()
        local k = P.k * SIZE
        local function S(x) return x * k end
        local BL, BW, BH, hh = S(P.BL), S(P.BW), S(P.BH), S(P.hh)
        local ext = P.ext or 0.8
        local coat = P.coat
        local belly = P.belly or coat
        local hc = P.headColor or coat
        local mzc = P.muzzleColor or hc
        sp.kind, sp.P, sp.hh = "quad", P, hh
        sp.walkMax, sp.trotMax = 4.2 * hh, 11 * hh
        sp.hop = P.hop
        local hipY = -BH * 0.12
        local Hc = hh - hipY
        sp.Hc, sp.lieH = Hc, BH * 0.46

        bone(sp, "Root", nil, CF())
        local body = bone(sp, "Body", "Root", CF(0, Hc, 0))
        ball(body, V3(BW, BH, BL), CF(), coat, FUR)
        ball(body, V3(BW * 0.98, BH * 1.06, BL * 0.52), CF(0, BH * 0.03, -BL * 0.22), coat, FUR)
        ball(body, V3(BW * 0.96, BH * 0.98, BL * 0.5), CF(0, BH * 0.02, BL * 0.24), coat, FUR)
        ball(body, V3(BW * 0.8, BH * 0.5, BL * 0.7), CF(0, -BH * 0.28, 0), belly, FUR)
        if P.hump then ball(body, V3(BW * 0.8, BH * 0.5, BL * 0.3), CF(0, BH * 0.38, -BL * 0.25), coat, FUR) end
        for _, set in ipairs(P.patchSets or {}) do
            for _ = 1, set.n do
                local th = rng:NextNumber(-2.3, 2.3)
                local z = rng:NextNumber(-0.42, 0.42) * BL
                local w = rng:NextNumber(0.16, 0.34) * (set.w and set.w / 0.25 or 1)
                local zl = (set.zlen or rng:NextNumber(0.1, 0.22)) * BL
                ball(body, V3(BW * w * 1.2, BH * w * 1.2, zl), CF(sin(th) * BW * 0.44, cos(th) * BH * 0.44, z), set.color, FUR)
            end
        end
        if P.udder then ball(body, V3(BW * 0.5, BH * 0.3, BL * 0.14), CF(0, -BH * 0.5, BL * 0.3), C(236, 170, 170), SMOOTH) end

        local function mkLeg(name, sx, front)
            local c = hh * P.cFrac * (front and 1 or (P.cHind or 1))
            local total = (hh - c) / ext
            local ratio = front and (P.ratioF or 0.5) or (P.ratioH or 0.5)
            local a, b = total * ratio, total * (1 - ratio)
            local hz = front and -BL * 0.33 or BL * 0.33
            local b1 = bone(sp, name .. "1", "Body", CF(sx * BW * 0.32, hipY, hz))
            local b2 = bone(sp, name .. "2", name .. "1", CF(0, -a, 0))
            local b3 = bone(sp, name .. "3", name .. "2", CF(0, -b, 0))
            local tU = S(P.legT) * (front and 1 or (P.legTh or 1.2))
            local tL, tC = S(P.legT) * 0.72, S(P.legT) * 0.55
            local lc = P.legColor or coat
            cyl(b1, tU, a, CF(0, -a / 2, 0), coat, FUR)
            ball(b1, V3(tU * 1.5, a * 0.85, tU * 1.6), CF(0, -a * 0.38, 0), coat, FUR)
            ball(b2, V3(tL * 1.15, tL * 1.15, tL * 1.15), CF(), lc, FUR)
            cyl(b2, tL, b, CF(0, -b / 2, 0), lc, FUR)
            ball(b3, V3(tC * 1.2, tC * 1.2, tC * 1.2), CF(), lc, FUR)
            cyl(b3, tC, c * 0.85, CF(0, -c * 0.45, 0), lc, FUR)
            local pw = P.paw
            if P.hoof then
                blk(b3, V3(S(pw.w), S(pw.h), S(pw.l)), CF(0, -c + S(pw.h) / 2, -S(pw.l) * 0.08), P.hoofColor or C(42, 36, 33), SMOOTH)
            else
                ball(b3, V3(S(pw.w), S(pw.h), S(pw.l)), CF(0, -c + S(pw.h) / 2, -S(pw.l) * 0.18), P.pawColor or lc, FUR)
            end
            sp.leg[name] = { a = a, b = b, c = c, hy = hipY, k = front and -1 or 1 }
        end
        mkLeg("FL", -1, true) mkLeg("FR", 1, true) mkLeg("BL", -1, false) mkLeg("BR", 1, false)

        local nL, nT = S(P.neck.len), S(P.neck.th)
        local neck = bone(sp, "Neck", "Body", CF(0, BH * (P.neckY or 0.18), -BL * 0.40))
        cylZ(neck, nT, nL * 1.05, CF(0, 0, -nL / 2), coat, FUR)
        ball(neck, V3(nT * 1.4, nT * 1.4, nT * 1.5), CF(), coat, FUR)
        if P.mane then
            local n = P.mane.n
            for i = 1, n do
                blk(neck, V3(nT * 0.22, S(P.mane.h), nL / n * 1.25),
                    CF(0, nT * 0.5 + S(P.mane.h) * 0.3, -nL * (i - 0.5) / n) * ANG(-0.2, 0, 0), P.mane.color, FUR)
            end
        end

        local head = bone(sp, "Head", "Neck", CF(0, 0, -nL))
        local hl, hw, hhh = S(P.head.hl), S(P.head.hw), S(P.head.hh)
        local ml, mw, mh = S(P.head.ml), S(P.head.mw), S(P.head.mh)
        ball(head, V3(hw, hhh, hl * 0.6), CF(0, 0, -hl * 0.22), hc, FUR)
        local mz, my = -(hl * 0.42 + ml / 2), -hhh * 0.2
        if P.longMuzzle then
            blk(head, V3(mw, mh, ml), CF(0, my, mz), mzc, FUR)
            ball(head, V3(mw * 1.05, mh * 1.05, ml * 0.25), CF(0, my, mz - ml * 0.42), mzc, FUR)
        else
            ball(head, V3(mw, mh, ml), CF(0, my, mz), mzc, FUR)
        end
        ball(head, V3(mw * 0.8, mh * 0.5, mw * 0.55), CF(0, my + mh * 0.18, mz - ml * 0.5), P.noseColor or C(22, 20, 20), SMOOTH)
        if P.snoutDisk then
            cylZ(head, mw * 1.15, ml * 0.22, CF(0, my, mz - ml * 0.5), C(236, 160, 160), SMOOTH)
            for _, sx in ipairs({ -1, 1 }) do
                ball(head, V3(mw * 0.14, mw * 0.2, mw * 0.1), CF(sx * mw * 0.2, my, mz - ml * 0.62), C(90, 50, 50), SMOOTH)
            end
        end
        local jaw = bone(sp, "Jaw", "Head", CF(0, my - mh * 0.5, -hl * 0.40))
        ball(jaw, V3(mw * 0.88, mh * 0.32, ml * 0.95), CF(0, -mh * 0.12, -ml * 0.5), mzc, FUR)
        local es = S(P.eye or 0.1)
        local ec = P.eyeColor or C(30, 22, 18)
        for _, sx in ipairs({ -1, 1 }) do
            local ex, ey, ez
            if P.eyeFront then ex, ey, ez = sx * hw * 0.3, hhh * 0.15, -hl * 0.36
            else ex, ey, ez = sx * hw * 0.46, hhh * 0.12, -hl * 0.15 end
            ball(head, V3(es, es, es), CF(ex, ey, ez), ec, SMOOTH)
            ball(head, V3(es * 0.3, es * 0.3, es * 0.3), CF(ex + (P.eyeFront and 0 or sx * es * 0.25), ey + es * 0.2, ez - es * 0.3), C(250, 250, 250), SMOOTH)
        end
        local E = P.ear
        local el, ew, et = S(E.len), S(E.w), S(E.th)
        sp.earKind = E.kind
        for _, sx in ipairs({ -1, 1 }) do
            local eb = bone(sp, sx < 0 and "EarL" or "EarR", "Head", CF(sx * hw * E.x, hhh * 0.4, -hl * 0.05))
            if E.kind == "floppy" then
                ball(eb, V3(ew, el, et), CF(0, -el * 0.45, 0), P.earColor or hc, FUR)
                eb.base = ANG(0, 0, sx * E.tilt)
            else
                ball(eb, V3(ew, el, et), CF(0, el * 0.45, 0), P.earColor or hc, FUR)
                if E.kind == "perk" then ball(eb, V3(ew * 0.6, el * 0.7, et * 0.5), CF(0, el * 0.4, -et * 0.35), C(226, 160, 150), SMOOTH) end
                eb.base = ANG(E.back or 0, 0, -sx * E.tilt)
            end
            eb.rot = eb.base
        end
        if P.horns then
            local H = P.horns
            local hlen, hth = S(H.len), S(H.th)
            for _, sx in ipairs({ -1, 1 }) do
                local b0 = CF(sx * hw * 0.38, hhh * 0.45, -hl * 0.05) * ANG(0, 0, -sx * 1.1)
                cyl(head, hth, hlen, b0 * CF(0, hlen / 2, 0), H.color, SMOOTH)
                local b1 = b0 * CF(0, hlen, 0) * ANG(0, 0, sx * 1.2)
                cyl(head, hth * 0.75, hlen * 0.8, b1 * CF(0, hlen * 0.4, 0), H.color, SMOOTH)
                if H.curl then
                    local b2 = b1 * CF(0, hlen * 0.8, 0) * ANG(-0.8, 0, sx * 0.6)
                    cyl(head, hth * 0.55, hlen * 0.6, b2 * CF(0, hlen * 0.3, 0), H.color, SMOOTH)
                end
            end
        end
        if P.antlers then
            local al, ath = S(P.antlers.len), S(0.07)
            for _, sx in ipairs({ -1, 1 }) do
                local base = CF(sx * hw * 0.3, hhh * 0.5, 0) * ANG(0.35, 0, -sx * 0.45)
                cyl(head, ath, al, base * CF(0, al / 2, 0), P.antlers.color, SMOOTH)
                for i = 1, 3 do
                    local t0 = base * CF(0, al * (0.2 + 0.22 * i), 0) * ANG(-0.9, 0, sx * 0.3)
                    cyl(head, ath * 0.7, al * 0.35, t0 * CF(0, al * 0.175, 0), P.antlers.color, SMOOTH)
                end
            end
        end
        if P.forelock then ball(head, V3(hw * 0.5, hhh * 0.4, hl * 0.18), CF(0, hhh * 0.45, -hl * 0.3), P.forelock, FUR) end

        local T = P.tail
        local l1, l2, tt = S(T.l1), S(T.l2 or 0), S(T.th)
        local tailColor = P.tailColor or coat
        local tb1 = bone(sp, "Tail1", "Body", CF(0, BH * (P.tailY or 0.2), BL * 0.49))
        if T.bushy then ball(tb1, V3(tt * 1.7, tt * 1.7, l1 * 1.15), CF(0, 0, l1 * 0.5), tailColor, FUR)
        else cylZ(tb1, tt, l1, CF(0, 0, l1 / 2), tailColor, FUR) end
        ball(tb1, V3(tt * 1.3, tt * 1.3, tt * 1.3), CF(), tailColor, FUR)
        if l2 > 0 then
            local tb2 = bone(sp, "Tail2", "Tail1", CF(0, 0, l1))
            if T.bushy then ball(tb2, V3(tt * 1.6, tt * 1.6, l2 * 1.15), CF(0, 0, l2 * 0.5), tailColor, FUR)
            else cylZ(tb2, tt * 0.9, l2, CF(0, 0, l2 / 2), tailColor, FUR) end
            if P.tuftColor then ball(tb2, V3(tt * 1.9, tt * 1.9, l2 * 0.45), CF(0, 0, l2 * 0.95), P.tuftColor, FUR) end
        elseif P.tuftColor then
            ball(tb1, V3(tt * 1.9, tt * 1.9, tt * 1.9), CF(0, 0, l1), P.tuftColor, FUR)
        end
        return sp
    end

    -- ===== pembangun burung =====
    local function buildBird(P, rng)
        local sp = newSpec()
        local k = P.k * SIZE
        local function S(x) return x * k end
        local BL, BW, BH, hh = S(P.BL), S(P.BW), S(P.BH), S(P.hh)
        local coat = P.coat
        sp.kind, sp.P, sp.hh = "bird", P, hh
        sp.walkMax = 4.5 * hh
        local hipY = -BH * 0.25
        local Hc = hh - hipY
        sp.Hc, sp.lieH = Hc, BH * 0.45

        bone(sp, "Root", nil, CF())
        bone(sp, "Body", "Root", CF(0, Hc, 0))
        local torso = bone(sp, "Torso", "Body", CF())
        ball(torso, V3(BW, BH, BL), CF(), coat, FUR)
        ball(torso, V3(BW * 0.92, BH * 0.98, BL * 0.5), CF(0, -BH * 0.04, -BL * 0.24), P.breast or coat, FUR)
        ball(torso, V3(BW * 0.86, BH * 0.82, BL * 0.45), CF(0, BH * 0.08, BL * 0.28), coat, FUR)
        for _, set in ipairs(P.patchSets or {}) do
            for _ = 1, set.n do
                local th = rng:NextNumber(-2.2, 2.2)
                local w = rng:NextNumber(0.2, 0.34)
                ball(torso, V3(BW * w * 1.2, BH * w * 1.2, BL * rng:NextNumber(0.12, 0.22)),
                    CF(sin(th) * BW * 0.42, cos(th) * BH * 0.42, rng:NextNumber(-0.35, 0.35) * BL), set.color, FUR)
            end
        end

        local c = hh * P.cFrac
        local total = (hh - c) / 0.8
        local a, b = total * 0.5, total * 0.5
        local legC = P.legColor
        for _, nm in ipairs({ "L", "R" }) do
            local sx = nm == "L" and -1 or 1
            local b1 = bone(sp, nm .. "1", "Body", CF(sx * BW * 0.22, hipY, BL * (P.legZ or 0.02)))
            local b2 = bone(sp, nm .. "2", nm .. "1", CF(0, -a, 0))
            local b3 = bone(sp, nm .. "3", nm .. "2", CF(0, -b, 0))
            ball(b1, V3(BW * 0.42, a * 1.5, BW * 0.42), CF(0, -a * 0.35, 0), coat, FUR)
            ball(b2, V3(BW * 0.2, b * 0.9, BW * 0.2), CF(0, -b * 0.3, 0), P.thigh or coat, FUR)
            cyl(b3, S(0.07), c * 1.05, CF(0, -c * 0.5, 0), legC, SMOOTH)
            ball(b3, V3(S(0.1), S(0.1), S(0.1)), CF(), legC, SMOOTH)
            if P.webbed then
                blk(b3, V3(S(0.36), S(0.03), S(0.42)), CF(0, -c + S(0.015), -S(0.16)), legC, SMOOTH)
            else
                for _, an in ipairs({ -0.45, 0, 0.45 }) do
                    blk(b3, V3(S(0.05), S(0.04), S(0.3)), CF(0, -c + S(0.02), 0) * ANG(0, an, 0) * CF(0, 0, -S(0.15)), legC, SMOOTH)
                end
                blk(b3, V3(S(0.05), S(0.04), S(0.16)), CF(0, -c + S(0.02), S(0.07)), legC, SMOOTH)
            end
            sp.leg[nm] = { a = a, b = b, c = c, hy = hipY, k = 1 }
        end

        local nL, nT = S(P.neck.len), S(P.neck.th)
        local neck = bone(sp, "Neck", "Torso", CF(0, BH * 0.25, -BL * 0.36))
        cylZ(neck, nT, nL * 1.05, CF(0, 0, -nL / 2), P.neckColor or coat, FUR)
        ball(neck, V3(nT * 1.5, nT * 1.5, nT * 1.5), CF(), P.neckColor or coat, FUR)
        local last, lastLen = "Neck", nL
        if P.neck2 then
            local n2L = S(P.neck2.len)
            local n2 = bone(sp, "Neck2", "Neck", CF(0, 0, -nL))
            cylZ(n2, nT * 0.95, n2L * 1.05, CF(0, 0, -n2L / 2), P.neckColor or coat, FUR)
            ball(n2, V3(nT * 1.1, nT * 1.1, nT * 1.1), CF(), P.neckColor or coat, FUR)
            last, lastLen = "Neck2", n2L
        end
        local head = bone(sp, "Head", last, CF(0, 0, -lastLen))
        local hs = S(P.headSize)
        ball(head, V3(hs * 0.85, hs, hs * 1.15), CF(0, 0, -hs * 0.3), P.headColor or coat, FUR)
        if P.webbed then
            blk(head, V3(S(0.2), S(0.07), S(0.32)), CF(0, -hs * 0.12, -hs * 0.95), P.beakColor, SMOOTH)
            blk(head, V3(S(0.18), S(0.04), S(0.28)), CF(0, -hs * 0.2, -hs * 0.92), P.beakColor, SMOOTH)
        else
            ball(head, V3(hs * 0.28, hs * 0.3, hs * 0.5), CF(0, -hs * 0.08, -hs * 0.8), P.beakColor, SMOOTH)
            ball(head, V3(hs * 0.26, hs * 0.2, hs * 0.42), CF(0, -hs * 0.22, -hs * 0.75), P.beakColor, SMOOTH)
            for i = 0, 2 do
                ball(head, V3(hs * 0.12, hs * (0.34 - i * 0.06), hs * 0.22), CF(0, hs * (0.55 + i * 0.03), -hs * (0.15 + i * 0.2)), C(200, 30, 35), SMOOTH)
            end
            ball(head, V3(hs * 0.14, hs * 0.3, hs * 0.14), CF(0, -hs * 0.45, -hs * 0.65), C(200, 30, 35), SMOOTH)
        end
        for _, sx in ipairs({ -1, 1 }) do
            ball(head, V3(hs * 0.2, hs * 0.2, hs * 0.2), CF(sx * hs * 0.42, hs * 0.1, -hs * 0.35), C(20, 16, 14), SMOOTH)
            ball(head, V3(hs * 0.06, hs * 0.06, hs * 0.06), CF(sx * hs * 0.5, hs * 0.16, -hs * 0.4), C(250, 250, 250), SMOOTH)
        end
        local ws, wc = S(P.wingSpan), S(P.wingChord)
        for _, sx in ipairs({ -1, 1 }) do
            local wb = bone(sp, sx < 0 and "WingL" or "WingR", "Torso", CF(sx * BW * 0.45, BH * 0.2, -BL * 0.02))
            ball(wb, V3(BW * 0.14, ws, wc), CF(sx * BW * 0.02, -ws / 2, 0), P.wingColor or coat, FUR)
            ball(wb, V3(BW * 0.1, ws * 0.55, wc * 0.8), CF(sx * BW * 0.04, -ws * 0.7, wc * 0.12), P.wingTip or shade(coat, 0.2), FUR)
        end
        local tl = S(P.tailLen)
        local tb = bone(sp, "Tail", "Torso", CF(0, BH * 0.12, BL * 0.46))
        for i = -2, 2 do
            ball(tb, V3(S(0.07), tl, S(0.26)), ANG(0, 0, i * 0.3) * CF(0, tl * 0.5, 0), P.tailColor or coat, FUR)
        end
        tb.base = ANG(P.tailBack or 0.4, 0, 0)
        return sp
    end

    -- ===== jenis hewan =====
    local function dogP(rng)
        local c = pick(rng, { { C(214, 164, 92), C(238, 210, 160) }, { C(40, 38, 38), C(66, 60, 58) }, { C(124, 84, 54), C(192, 152, 112) },
            { C(236, 222, 192), C(250, 242, 225) }, { C(138, 138, 146), C(236, 236, 238) }, { C(176, 120, 60), C(228, 192, 140) } })
        local floppy = rng:NextNumber() < 0.5
        return { k = rn(rng, 0.9, 1.1), BL = 1.9, BW = .78, BH = .9, hh = 1.05, cFrac = .3, legT = .28, legTh = 1.3,
            paw = { w = .32, h = .2, l = .44 }, pawColor = c[1], neck = { len = .5, th = .42, pitch = .85 },
            head = { hl = .62, hw = .5, hh = .5, ml = .5, mw = .3, mh = .28, pitch = -.12 }, eye = .09,
            ear = floppy and { kind = "floppy", len = .44, w = .26, th = .07, x = .34, tilt = .35 }
                or { kind = "perk", len = .42, w = .22, th = .07, x = .3, tilt = .2 },
            tail = { l1 = .55, l2 = .5, th = .16, p1 = -.3, p2 = -.5 }, coat = c[1], belly = c[2], pants = true,
            headBob = .02, tailSway = .4, tailHz = 3, tailRun = .3, sniff = true }
    end
    local function catP(rng)
        local c = pick(rng, { { C(206, 132, 62), "tabby" }, { C(128, 128, 134), "tabby" }, { C(32, 31, 33), "solid" },
            { C(236, 234, 228), "solid" }, { C(226, 196, 150), "tabby" }, { C(236, 234, 228), "calico" } })
        local P = { k = rn(rng, 0.9, 1.1), BL = 1.05, BW = .44, BH = .5, hh = .62, cFrac = .28, legT = .16, legTh = 1.25,
            paw = { w = .2, h = .12, l = .26 }, pawColor = c[1], neck = { len = .26, th = .26, pitch = .7 },
            head = { hl = .38, hw = .38, hh = .33, ml = .12, mw = .16, mh = .12, pitch = -.05 },
            eye = .1, eyeFront = true, eyeColor = pick(rng, { C(150, 190, 60), C(210, 170, 50), C(90, 150, 190) }),
            ear = { kind = "perk", len = .2, w = .2, th = .05, x = .27, tilt = .12 },
            tail = { l1 = .5, l2 = .5, th = .09, p1 = .3, p2 = -.6 }, coat = c[1], belly = tint(c[1], .35),
            noseColor = C(200, 120, 120), headBob = .01, tailSway = .3, tailHz = 1.6, tailRun = .2, sniff = true }
        if c[2] == "tabby" then P.patchSets = { { n = 16, color = shade(c[1], .45), w = .12, zlen = .05 } }
        elseif c[2] == "calico" then P.patchSets = { { n = 4, color = C(205, 125, 55), w = .3 }, { n = 3, color = C(40, 38, 38), w = .28 } } end
        return P
    end
    local function cowP(rng)
        local kind = pick(rng, { "holstein", "holstein", "brown", "hereford" })
        local P = { k = rn(rng, 0.93, 1.07), BL = 4.4, BW = 1.9, BH = 2.1, hh = 2.2, cFrac = .38, ext = .82, legT = .6,
            paw = { w = .58, h = .3, l = .66 }, hoof = true, neck = { len = 1.1, th = .95, pitch = .3 }, neckY = .1,
            head = { hl = 1.5, hw = .86, hh = .9, ml = .7, mw = .62, mh = .56, pitch = -.55 }, eye = .14,
            ear = { kind = "round", len = .5, w = .34, th = .08, x = .55, tilt = 1.3 },
            tail = { l1 = 1.7, l2 = .5, th = .11, p1 = .1, p2 = .05 }, graze = { neck = -.75, head = -.5 },
            headBob = .04, tailSway = .18, tailHz = 1.2, udder = rng:NextNumber() < 0.6, muzzleColor = C(224, 176, 170) }
        if rng:NextNumber() < 0.5 then P.horns = { len = .5, th = .14, color = C(228, 222, 200) } end
        if kind == "holstein" then
            P.coat, P.belly = C(240, 238, 232), C(240, 238, 232)
            P.patchSets = { { n = 9, color = C(32, 30, 30), w = .3 } }
            P.tuftColor = C(35, 33, 33)
        elseif kind == "brown" then
            P.coat, P.belly, P.tuftColor = C(128, 80, 46), C(158, 108, 70), C(60, 40, 28)
        else
            P.coat, P.belly, P.headColor, P.tuftColor = C(150, 76, 38), C(240, 236, 226), C(240, 236, 228), C(240, 236, 228)
        end
        return P
    end
    local function pigP(rng)
        local c = pick(rng, { { C(232, 170, 168), C(240, 200, 195) }, { C(232, 170, 168), C(240, 200, 195), "spot" }, { C(70, 60, 58), C(96, 86, 82) } })
        local P = { k = rn(rng, 0.92, 1.08), BL = 2.5, BW = 1.35, BH = 1.45, hh = 1.05, cFrac = .22, legT = .36,
            paw = { w = .34, h = .2, l = .38 }, hoof = true, hoofColor = C(70, 58, 54),
            neck = { len = .35, th = .95, pitch = .1 }, neckY = .05,
            head = { hl = 1.05, hw = .85, hh = .8, ml = .55, mw = .58, mh = .52, pitch = -.4 }, eye = .1,
            ear = { kind = "floppy", len = .55, w = .42, th = .07, x = .36, tilt = .7 },
            tail = { l1 = .22, l2 = .28, th = .07, p1 = -.9, p2 = 1.4 }, coat = c[1], belly = c[2], snoutDisk = true,
            headBob = .03, tailSway = .5, tailHz = 4, tailRun = 0, sniff = true, noseColor = C(150, 90, 90) }
        if c[3] == "spot" then P.patchSets = { { n = 6, color = C(60, 52, 50), w = .32 } } end
        return P
    end
    local function sheepP(rng)
        local dark = rng:NextNumber() < 0.6
        local hcol = dark and C(55, 48, 46) or C(205, 180, 150)
        local P = { k = rn(rng, 0.92, 1.08), BL = 2.3, BW = 1.3, BH = 1.35, hh = 1.45, cFrac = .34, legT = .24,
            paw = { w = .3, h = .2, l = .34 }, hoof = true, legColor = C(70, 60, 55), neck = { len = .6, th = .55, pitch = .55 },
            head = { hl = .85, hw = .5, hh = .55, ml = .45, mw = .3, mh = .32, pitch = -.35 }, eye = .1,
            ear = { kind = "round", len = .4, w = .22, th = .06, x = .3, tilt = 1.2 }, tail = { l1 = .3, th = .2, p1 = .5 },
            coat = C(238, 234, 222), headColor = hcol, earColor = hcol,
            patchSets = { { n = 26, color = C(246, 242, 232), w = .42, zlen = .2 } },
            graze = { neck = -.7, head = -.45 }, headBob = .03, tailSway = .3, tailHz = 3, tailColor = C(238, 234, 222) }
        if rng:NextNumber() < 0.35 then P.horns = { len = .45, th = .13, color = C(200, 190, 165), curl = true } end
        return P
    end
    local function horseP(rng)
        local c = pick(rng, { { coat = C(130, 80, 45), mane = C(30, 24, 22), leg = C(40, 32, 28) },
            { coat = C(150, 85, 40), mane = C(125, 68, 32), leg = C(150, 85, 40) },
            { coat = C(34, 32, 33), mane = C(24, 22, 22), leg = C(34, 32, 33) },
            { coat = C(215, 175, 110), mane = C(240, 228, 200), leg = C(215, 175, 110) },
            { coat = C(165, 165, 170), mane = C(110, 110, 116), leg = C(120, 120, 126) } })
        return { k = rn(rng, 0.94, 1.06), BL = 5.0, BW = 1.7, BH = 2.2, hh = 2.7, cFrac = .42, ext = .85, legT = .55,
            paw = { w = .5, h = .35, l = .55 }, hoof = true, legColor = c.leg, tailColor = c.mane,
            neck = { len = 2.1, th = 1.0, pitch = .9 }, neckY = .25,
            head = { hl = 1.7, hw = .75, hh = .85, ml = .95, mw = .5, mh = .55, pitch = -.85 }, longMuzzle = true, eye = .16,
            ear = { kind = "perk", len = .5, w = .22, th = .08, x = .25, tilt = .15 },
            tail = { l1 = 1.4, l2 = 1.4, th = .3, p1 = .45, p2 = .25, bushy = true }, coat = c.coat, belly = shade(c.coat, .08),
            mane = { n = 7, h = .55, color = c.mane }, forelock = c.mane, graze = { neck = -1.0, head = -.55 },
            headBob = .06, tailSway = .2, tailHz = 1.4, tailRun = .5, earBack = .3 }
    end
    local function deerP(rng)
        local P = { k = rn(rng, 0.94, 1.06), BL = 3.3, BW = 1.2, BH = 1.5, hh = 2.35, cFrac = .44, ext = .85, legT = .26,
            paw = { w = .24, h = .22, l = .3 }, hoof = true, legColor = C(120, 85, 55), neck = { len = 1.2, th = .5, pitch = .8 },
            head = { hl = .95, hw = .45, hh = .5, ml = .55, mw = .26, mh = .28, pitch = -.5 }, longMuzzle = true, eye = .12,
            ear = { kind = "perk", len = .5, w = .3, th = .06, x = .3, tilt = .6 }, tail = { l1 = .35, th = .25, p1 = -.3 },
            tailColor = C(240, 235, 225), coat = C(160, 110, 65), belly = C(235, 225, 205), graze = { neck = -.9, head = -.5 },
            headBob = .05, tailSway = .2, tailHz = 2, tailRun = .6, earBack = .25 }
        if rng:NextNumber() < 0.6 then P.antlers = { len = .9, color = C(210, 195, 165) } end
        if rng:NextNumber() < 0.25 then P.patchSets = { { n = 18, color = C(240, 235, 225), w = .12 } } end
        return P
    end
    local function rabbitP(rng)
        local c = pick(rng, { { C(150, 125, 95), C(235, 225, 210) }, { C(238, 236, 232), C(250, 248, 244) },
            { C(96, 84, 74), C(190, 178, 165) }, { C(190, 160, 120), C(240, 230, 215) } })
        return { k = rn(rng, 0.9, 1.1), BL = .95, BW = .5, BH = .55, hh = .4, cFrac = .3, legT = .17, legTh = 1.6, hump = true,
            paw = { w = .16, h = .1, l = .26 }, pawColor = c[1], neck = { len = .14, th = .3, pitch = .5 },
            head = { hl = .4, hw = .3, hh = .3, ml = .16, mw = .17, mh = .14, pitch = -.1 }, eye = .08,
            ear = { kind = "perk", len = .75, w = .16, th = .05, x = .12, tilt = .12, back = .25 },
            tail = { l1 = .12, th = .22 }, tailColor = C(248, 246, 242), coat = c[1], belly = c[2],
            noseColor = C(200, 130, 130), hop = true, headBob = .02, tailSway = .05, tailHz = 2, sniff = true }
    end
    local function bearP(rng)
        local c = pick(rng, { C(95, 65, 42), C(30, 28, 28), C(125, 95, 68), C(150, 98, 52) })
        return { k = rn(rng, 0.94, 1.06), BL = 3.4, BW = 1.7, BH = 2.0, hh = 1.7, cFrac = .25, legT = .6, hump = true,
            paw = { w = .6, h = .3, l = .8 }, pawColor = shade(c, .15), neck = { len = .7, th = 1.1, pitch = .15 },
            head = { hl = 1.1, hw = .9, hh = .85, ml = .6, mw = .5, mh = .45, pitch = -.35 }, eye = .1,
            ear = { kind = "round", len = .22, w = .26, th = .1, x = .38, tilt = .5 }, tail = { l1 = .25, th = .3 },
            coat = c, belly = shade(c, .08), muzzleColor = tint(c, .22), headBob = .05, tailSway = .05, tailHz = 1,
            sniff = true, pants = true }
    end
    local function wolfP(rng)
        local c = pick(rng, { { C(130, 128, 125), C(200, 195, 185) }, { C(232, 232, 228), C(245, 245, 242) }, { C(48, 46, 46), C(90, 84, 80) } })
        return { k = rn(rng, 0.94, 1.06), BL = 2.6, BW = .85, BH = 1.05, hh = 1.7, cFrac = .36, legT = .3,
            paw = { w = .36, h = .2, l = .5 }, pawColor = c[1], neck = { len = .7, th = .5, pitch = .55 },
            head = { hl = .85, hw = .5, hh = .5, ml = .62, mw = .3, mh = .27, pitch = -.2 }, eye = .1,
            eyeColor = C(210, 160, 40), eyeFront = true, ear = { kind = "perk", len = .38, w = .2, th = .06, x = .27, tilt = .15 },
            tail = { l1 = .8, l2 = .6, th = .22, p1 = .55, p2 = .15, bushy = true }, coat = c[1], belly = c[2],
            patchSets = { { n = 5, color = shade(c[1], .3), w = .3 } }, pants = true, headBob = .03, tailSway = .15,
            tailHz = 1.5, tailRun = .5, sniff = true }
    end
    local function foxP(rng)
        return { k = rn(rng, 0.92, 1.08), BL = 1.5, BW = .55, BH = .62, hh = .95, cFrac = .36, legT = .18,
            paw = { w = .2, h = .12, l = .3 }, pawColor = C(30, 24, 22), legColor = C(40, 32, 30),
            neck = { len = .38, th = .3, pitch = .6 }, head = { hl = .55, hw = .36, hh = .34, ml = .42, mw = .17, mh = .16, pitch = -.15 },
            eye = .07, eyeFront = true, eyeColor = C(190, 130, 30), ear = { kind = "perk", len = .38, w = .2, th = .05, x = .26, tilt = .15 },
            earColor = C(50, 36, 30), tail = { l1 = .7, l2 = .5, th = .3, p1 = .35, p2 = .1, bushy = true }, tuftColor = C(245, 242, 235),
            coat = C(205, 105, 40), belly = C(242, 236, 226), muzzleColor = C(236, 228, 214), pants = true, headBob = .03,
            tailSway = .2, tailHz = 1.6, tailRun = .4, sniff = true }
    end
    local function chickenP(rng)
        local c = pick(rng, { { C(240, 238, 230), C(240, 238, 230) }, { C(150, 95, 50), C(176, 120, 68) },
            { C(40, 42, 46), C(60, 62, 66) }, { C(170, 70, 40), C(190, 100, 55) } })
        return { k = rn(rng, 0.92, 1.08), BL = .95, BW = .6, BH = .75, hh = .8, cFrac = .5, pitch = -.3,
            neck = { len = .45, th = .22, pitch = 1.15 }, headSize = .26, beakColor = C(236, 190, 70), coat = c[1], breast = c[2],
            wingSpan = .6, wingChord = .55, tailLen = .55, tailBack = .3, legColor = C(226, 190, 70),
            tailColor = shade(c[1], rng:NextNumber() < 0.5 and .55 or 0), peck = true, headBob = .1, waddle = .04, wingRun = true }
    end
    local function duckP(rng)
        local kind = pick(rng, { "mallard", "white", "brown" })
        local P = { k = rn(rng, 0.92, 1.08), BL = 1.3, BW = .72, BH = .62, hh = .45, cFrac = .5, pitch = .05, legZ = .06,
            neck = { len = .45, th = .22, pitch = .95 }, neck2 = { len = .35, pitch = -.75 }, headSize = .3,
            beakColor = C(236, 150, 40), webbed = true, legColor = C(236, 140, 40), wingSpan = .5, wingChord = .75,
            tailLen = .22, tailBack = 1.1, headBob = .06, waddle = .16 }
        if kind == "mallard" then
            P.coat, P.breast, P.headColor, P.neckColor = C(140, 112, 86), C(130, 96, 76), C(30, 96, 56), C(30, 96, 56)
            P.beakColor = C(220, 200, 60)
        elseif kind == "white" then
            P.coat, P.breast = C(244, 242, 236), C(244, 242, 236)
        else
            P.coat, P.breast = C(150, 118, 84), C(170, 136, 100)
        end
        return P
    end

    local SPECIES = {
        { name = "Anjing", build = function(r) return buildQuad(dogP(r), r) end },
        { name = "Kucing", build = function(r) return buildQuad(catP(r), r) end },
        { name = "Sapi", build = function(r) return buildQuad(cowP(r), r) end },
        { name = "Babi", build = function(r) return buildQuad(pigP(r), r) end },
        { name = "Domba", build = function(r) return buildQuad(sheepP(r), r) end },
        { name = "Kuda", build = function(r) return buildQuad(horseP(r), r) end },
        { name = "Rusa", build = function(r) return buildQuad(deerP(r), r) end },
        { name = "Kelinci", build = function(r) return buildQuad(rabbitP(r), r) end },
        { name = "Beruang", build = function(r) return buildQuad(bearP(r), r) end },
        { name = "Serigala", build = function(r) return buildQuad(wolfP(r), r) end },
        { name = "Rubah", build = function(r) return buildQuad(foxP(r), r) end },
        { name = "Ayam", build = function(r) return buildBird(chickenP(r), r) end },
        { name = "Bebek", build = function(r) return buildBird(duckP(r), r) end },
    }

    -- ===== perilaku saat diam =====
    local function updateBeh(a, now, idle)
        local P = a.spec.P
        if not idle then
            a.beh = nil
            a.nextBeh = now + 2 + rnd() * 4
            return
        end
        if a.beh and now > a.beh.t1 then
            a.beh = nil
            a.nextBeh = now + 1 + rnd() * 4
        end
        if not a.beh and now >= a.nextBeh then
            local r = rnd()
            if P.graze and r < 0.45 then
                a.beh = { n = "graze", t1 = now + 3 + rnd() * 5 }
            elseif r < 0.85 or not P.sniff then
                a.beh = { n = "look", t1 = now + 1.5 + rnd() * 2.5, yaw = rr(0.9), pitch = rr(0.2) }
            else
                a.beh = { n = "sniff", t1 = now + 2 + rnd() * 3 }
            end
        end
    end

    -- ===== animasi =====
    local GAITS = {
        walk = { off = { FL = .25, FR = .75, BL = 0, BR = .5 }, beta = .64, sl = 1.55, lift = .2, bob = .012, pitch = 0 },
        trot = { off = { FL = 0, BR = 0, FR = .5, BL = .5 }, beta = .45, sl = 2.2, lift = .26, bob = .03, pitch = 0 },
        gallop = { off = { BR = 0, BL = .1, FL = .5, FR = .6 }, beta = .27, sl = 3.6, lift = .4, bob = .07, pitch = .12 },
    }
    local LEGN = { "FL", "FR", "BL", "BR" }
    local BIRDG = { walk = { beta = .62, sl = 1.4, lift = .3 }, run = { beta = .4, sl = 3.0, lift = .45 } }

    local function finishQuad(a, dt, now, o)
        local sp, P = a.spec, a.spec.P
        local B = sp.B
        local mm, gf = o.m, o.gf
        B.Body.rot = ANG(o.pitch, o.yaw, o.roll)
        -- napas halus
        B.Body.pos = V3(0, o.bob + (o.hcDelta or 0) + sin(now * 1.9 + a.seed) * 0.006 * sp.hh, 0)
        local tNeck, tHead, tYaw, tHYaw = P.neck.pitch, P.head.pitch, 0, 0
        local beh = a.beh
        local chew = 0
        if beh then
            if beh.n == "graze" and P.graze then
                tNeck, tHead, chew = P.graze.neck, P.graze.head, 1
            elseif beh.n == "look" then
                tYaw, tHYaw = beh.yaw * 0.6, beh.yaw * 0.4
                tHead, tNeck = tHead + beh.pitch, tNeck + beh.pitch * 0.5
            elseif beh.n == "sniff" then
                tNeck, tHead = tNeck - 0.35, tHead - 0.3 + 0.06 * sin(now * 9)
            end
        end
        tNeck = tNeck + (P.headBob or 0.03) * mm * sin(4 * pi * a.phase + 1) * (1 + gf)
        local k2 = 1 - exp(-dt * 4)
        a.nP, a.hP = lerp(a.nP, tNeck, k2), lerp(a.hP, tHead, k2)
        a.nY, a.hY = lerp(a.nY, tYaw, k2), lerp(a.hY, tHYaw, k2)
        B.Neck.rot = ANG(a.nP, 0, 0) * ANG(0, a.nY, 0)
        B.Head.rot = ANG(a.hP - a.nP - o.pitch, 0, 0) * ANG(0, a.hY, 0)
        local open = 0
        if chew > 0 then open = 0.1 + 0.08 * sin(now * 9) end
        if P.pants and gf > 0.1 then open = 0.18 + 0.1 * sin(now * 13)
        elseif P.pants and mm > 0.5 then open = 0.1 + 0.05 * sin(now * 10) end
        B.Jaw.rot = ANG(-open, 0, 0)
        local tp = P.tail.p1 - gf * (P.tailRun or 0.3)
        local sway = (P.tailSway or 0.2) * sin(now * (P.tailHz or 2) + a.seed) * (1 + mm)
        B.Tail1.rot = ANG(tp, 0, 0) * ANG(0, sway, 0)
        if B.Tail2 then B.Tail2.rot = ANG((P.tail.p2 or 0) + 0.15 * sin(now * 2.5 + a.seed + 1), sway * 0.7, 0) end
        local bs = sp.earKind == "floppy" and -1 or 1
        for i, nm in ipairs({ "EarL", "EarR" }) do
            if now >= a.earNext[i] then
                a.earStart[i] = now
                a.earNext[i] = now + 2 + rnd() * 6
            end
            local u = (now - a.earStart[i]) / 0.25
            local tw = u < 1 and sin(pi * u) * 0.35 or 0
            B[nm].rot = B[nm].base * ANG(bs * (P.earBack or 0.2) * gf, 0, tw * (i == 1 and -1 or 1))
        end
    end

    local function animHop(a, dt, now, spd, air, lie, turn)
        local sp = a.spec
        local hh, Hc = sp.hh, sp.Hc
        local moving = spd > 0.8
        local hopF = clamp(2.2 + spd * 0.05, 2.2, 3.4)
        local hopDist = spd / hopF
        local Sd = 0.9 * hh
        local beta = clamp(Sd / max(hopDist, 0.01), 0.18, 0.6)
        if moving then
            a.phase = (a.phase + dt * hopF) % 1
        else
            local t = clamp(dt * 6, 0, 1)
            if a.phase < 0.5 then a.phase = a.phase * (1 - t) else a.phase = a.phase + (1 - a.phase) * t end
        end
        local Sx = moving and min(Sd, hopDist * beta) or 0
        local ph = a.phase
        local airU = (ph > beta) and ((ph - beta) / (1 - beta)) or nil
        local hopH = clamp(hopDist * 0.17, 0.15 * hh, 1.6 * hh)
        local bobY = airU and hopH * sin(pi * airU) or 0
        local pitch = airU and (0.45 * cos(pi * airU)) or 0.12
        if not moving then pitch, bobY = 0.05, 0 end
        local HcE = lerp(Hc, sp.lieH, lie)
        for _, nm in ipairs(LEGN) do
            local L = sp.leg[nm]
            local front = nm:sub(1, 1) == "F"
            local p = (ph + (front and 0.06 or 0)) % 1
            local fx, lift = 0, 0
            if p < beta then
                fx = Sx * (0.5 - p / beta)
            else
                local u = (p - beta) / (1 - beta)
                fx = Sx * (-0.5 + smooth(u)) + (front and -0.15 or 0.3) * hh * sin(pi * u) * (moving and 1 or 0)
                lift = bobY + sin(pi * u) * 0.35 * (hh - L.c)
            end
            local yt = (-(HcE) + L.c + lift) - L.hy
            if lie > 0.01 then
                fx = lerp(fx, (front and 0.45 or -0.2) * hh, lie)
                yt = lerp(yt, -0.45 * (hh - L.c), lie)
            end
            if air > 0.01 then
                fx = lerp(fx, (front and 0.5 or -0.45) * hh, air)
                yt = lerp(yt, -(hh - L.c) * 0.78, air)
            end
            setLeg(sp, nm, fx, yt, 0)
        end
        local o = a.o
        o.pitch, o.yaw, o.roll = pitch, 0, turn
        o.bob, o.hcDelta, o.m, o.gf = bobY, HcE - Hc, moving and 1 or 0, 0
        finishQuad(a, dt, now, o)
    end

    local function animQuad(a, dt, now, spd, dirSign, air, lie, turn)
        local sp = a.spec
        if sp.hop then return animHop(a, dt, now, spd, air, lie, turn) end
        local hh, Hc = sp.hh, sp.Hc
        local g = a.g
        local gn = a.gait or "idle"
        local wm, tm = sp.walkMax, sp.trotMax
        if gn == "idle" then
            if spd > 0.6 then gn = "walk" end
        elseif spd < 0.35 then
            gn = "idle"
        end
        if gn ~= "idle" then
            local up1 = (gn == "walk") and wm or wm * 0.9
            local up2 = (gn == "gallop") and tm * 0.9 or tm
            if spd < up1 then gn = "walk" elseif spd < up2 then gn = "trot" else gn = "gallop" end
        end
        a.gait = gn
        local tg = GAITS[gn == "idle" and "walk" or gn]
        local kk = 1 - exp(-dt * 5)
        g.beta, g.sl, g.lift = lerp(g.beta, tg.beta, kk), lerp(g.sl, tg.sl, kk), lerp(g.lift, tg.lift, kk)
        g.bob, g.pitch = lerp(g.bob, tg.bob, kk), lerp(g.pitch, tg.pitch, kk)
        for nm, v in pairs(tg.off) do g.off[nm] = lerp(g.off[nm], v, kk) end

        local strideLen = g.sl * hh * (0.6 + 0.4 * clamp(spd / wm, 0, 1))
        local mm = smooth(spd / 1.0)
        local Sd = g.beta * strideLen * mm
        if spd > 0.02 then a.phase = (a.phase + dirSign * dt * spd / strideLen) % 1 end
        local ph = a.phase
        local gf = clamp(g.pitch / 0.12, 0, 1)
        local bobY = g.bob * hh * cos(4 * pi * (ph - g.beta * 0.5)) * mm
        local pitch, roll, yawS = 0, 0.035 * sin(2 * pi * ph) * mm * (1 - gf) + turn, 0.03 * sin(2 * pi * ph) * mm
        if gf > 0.01 then
            bobY = lerp(bobY, g.bob * hh * cos(2 * pi * (ph - 0.2)) * mm, gf)
            pitch = g.pitch * sin(2 * pi * (ph + 0.05)) * gf * mm
        end
        bobY = bobY + 0.008 * hh * sin(now * 2.3 + a.seed)
        local HcE = lerp(Hc, sp.lieH, lie)
        for _, nm in ipairs(LEGN) do
            local L = sp.leg[nm]
            local front = nm:sub(1, 1) == "F"
            local p = (ph + g.off[nm]) % 1
            local fx, lift, su = 0, 0, nil
            if p < g.beta then
                fx = Sd * (0.5 - p / g.beta)
            else
                local u = (p - g.beta) / (1 - g.beta)
                su = u
                fx = Sd * (-0.5 + smooth(u))
                lift = sin(pi * u) * g.lift * hh * mm
            end
            local yt = (-(HcE + bobY) + L.c + lift) - L.hy
            if lie > 0.01 then
                fx = lerp(fx, (front and 0.45 or -0.2) * hh, lie)
                yt = lerp(yt, -0.45 * (hh - L.c), lie)
            end
            if air > 0.01 then
                fx = lerp(fx, (front and 0.5 or -0.45) * hh, air)
                yt = lerp(yt, -(hh - L.c) * 0.78, air)
            end
            setLeg(sp, nm, fx, yt, su and (-sin(pi * su) * 0.8 * mm) or 0)
        end
        updateBeh(a, now, spd < 0.4 and air < 0.2 and lie < 0.2)
        local o = a.o
        o.pitch, o.yaw, o.roll = pitch, yawS, roll
        o.bob, o.hcDelta, o.m, o.gf = bobY, HcE - Hc, mm, gf
        finishQuad(a, dt, now, o)
    end

    local function animBird(a, dt, now, spd, dirSign, air, lie, turn)
        local sp, P = a.spec, a.spec.P
        local B = sp.B
        local hh, Hc = sp.hh, sp.Hc
        local run = spd > sp.walkMax
        local tg = run and BIRDG.run or BIRDG.walk
        local g = a.g
        local kk = 1 - exp(-dt * 5)
        g.beta, g.sl, g.lift = lerp(g.beta, tg.beta, kk), lerp(g.sl, tg.sl, kk), lerp(g.lift, tg.lift, kk)
        local strideLen = g.sl * hh * (0.6 + 0.4 * clamp(spd / sp.walkMax, 0, 1))
        local mm = smooth(spd / 1.0)
        local Sd = g.beta * strideLen * mm
        if spd > 0.02 then a.phase = (a.phase + dirSign * dt * spd / strideLen) % 1 end
        local ph = a.phase
        local bobY = 0.03 * hh * cos(4 * pi * (ph - g.beta * 0.5)) * mm + 0.006 * hh * sin(now * 2.3 + a.seed)
        local HcE = lerp(Hc, sp.lieH, lie)
        for _, nm in ipairs({ "L", "R" }) do
            local p = (ph + (nm == "R" and 0.5 or 0)) % 1
            local L = sp.leg[nm]
            local fx, lift, su = 0, 0, nil
            if p < g.beta then
                fx = Sd * (0.5 - p / g.beta)
            else
                local u = (p - g.beta) / (1 - g.beta)
                su = u
                fx = Sd * (-0.5 + smooth(u))
                lift = sin(pi * u) * g.lift * hh * mm
            end
            local yt = (-(HcE + bobY) + L.c + lift) - L.hy
            if lie > 0.01 then
                fx = lerp(fx, 0.1 * hh, lie)
                yt = lerp(yt, -0.45 * (hh - L.c), lie)
            end
            if air > 0.01 then
                fx = lerp(fx, -0.3 * hh, air)
                yt = lerp(yt, -(hh - L.c) * 0.7, air)
            end
            setLeg(sp, nm, fx, yt, su and (-sin(pi * su) * 0.9 * mm) or 0)
        end
        local idle = spd < 0.4 and air < 0.2 and lie < 0.2
        local peck = 0
        if P.peck and idle then
            if a.pk then
                local u = (now - a.pk.t0) / 0.42
                local idx = floor(u)
                if idx >= a.pk.n then a.pk, a.nextPk = nil, now + 2 + rnd() * 4
                else peck = sin(pi * (u - idx)) ^ 2 end
            elseif now >= (a.nextPk or 0) then
                a.pk = { t0 = now, n = rnd(1, 3) }
            end
            updateBeh(a, now, false)
        else
            a.pk = nil
            updateBeh(a, now, idle)
        end
        local beh = a.beh
        local tYaw, tHYaw = 0, 0
        if beh and beh.n == "look" then tYaw, tHYaw = beh.yaw * 0.6, beh.yaw * 0.4 end
        local k2 = 1 - exp(-dt * 4)
        a.nY, a.hY = lerp(a.nY, tYaw, k2), lerp(a.hY, tHYaw, k2)
        local torsoPitch = (P.pitch or 0) + peck * 0.35 - (run and 0.15 or 0)
        B.Body.rot = ANG(0, 0, (P.waddle or 0.05) * sin(2 * pi * ph) * mm + turn)
        B.Body.pos = V3(0, bobY + (HcE - Hc), 0)
        B.Torso.rot = ANG(torsoPitch, 0, 0)
        local nP = P.neck.pitch - 1.5 * peck - (run and 0.25 or 0)
        B.Neck.rot = ANG(nP, 0, 0) * ANG(0, a.nY, 0)
        B.Neck.pos = V3(0, 0, -(P.headBob or 0) * cos(2 * pi * ph) * mm)
        local n2 = 0
        if B.Neck2 then
            n2 = P.neck2.pitch
            B.Neck2.rot = ANG(n2, 0, 0)
        end
        B.Head.rot = ANG(-torsoPitch - nP - n2 + (P.headPitch or -0.1) - 0.3 * peck, 0, 0) * ANG(0, a.hY, 0)
        local open, flap = 0, 0
        if air > 0.2 then open, flap = 1.0, 0.6 * sin(now * 22)
        elseif P.wingRun and run then open, flap = 0.5, 0.2 * sin(now * 30) end
        local wo = 0.05 + open + flap
        B.WingL.rot = ANG(0, 0, -wo)
        B.WingR.rot = ANG(0, 0, wo)
        B.Tail.rot = B.Tail.base * ANG(0.08 * sin(now * 3 + a.seed) + (run and -0.2 or 0) + peck * 0.2, 0, 0)
    end

    -- ===== kelola hewan per pemain =====
    local function hideInst(a, x)
        if x:IsA("BasePart") or x:IsA("Decal") then
            if a.store[x] == nil then a.store[x] = x.Transparency end
            x.Transparency = 1
        end
    end

    local function refreshRef(a)
        a.dirty = false
        local c = a.char
        if not c then return end
        a.root = c:FindFirstChild("HumanoidRootPart")
        a.hum = c:FindFirstChildOfClass("Humanoid")
        if a.root and a.hum then
            if a.hum.RigType == Enum.HumanoidRigType.R15 then
                a.rootOff = a.hum.HipHeight + a.root.Size.Y / 2
            else
                local leg = c:FindFirstChild("Left Leg")
                a.rootOff = (leg and leg.Size.Y or 2) + a.root.Size.Y / 2
            end
        end
    end

    local function attachChar(a, c)
        a.char, a.root, a.hum, a.lastPos = c, nil, nil, nil
        if a.cc then a.cc:Disconnect() end
        for _, x in ipairs(c:GetDescendants()) do hideInst(a, x) end
        a.cc = c.DescendantAdded:Connect(function(x) hideInst(a, x) end)
        a.dirty = true
    end

    local function chooseSpecies(p)
        if assigned[p.UserId] then return assigned[p.UserId] end
        local best, bu = {}, 1e9
        for i = 1, #SPECIES do
            local u = used[i] or 0
            if u < bu then bu, best = u, { i } elseif u == bu then best[#best + 1] = i end
        end
        local rng = Random.new(p.UserId + reroll * 7919)
        local si = best[rng:NextInteger(1, #best)]
        assigned[p.UserId] = si
        used[si] = (used[si] or 0) + 1
        return si
    end

    local function createAnimal(p)
        if A[p] or not fold then return end
        if p == lp and not INCLUDE_ME then return end
        local si = chooseSpecies(p)
        local rng = Random.new(p.UserId * 31 + reroll * 101 + si)
        local sp = SPECIES[si].build(rng)
        local a = {
            p = p, si = si, spec = sp, seed = rng:NextNumber() * 6.28, phase = 0, gait = "idle",
            air = 0, lie = 0, dead = 0, vel = V3(), yaw = 0, yawRate = 0, store = {}, o = {}, lastDust = 0,
            g = { beta = .64, sl = 1.55, lift = .2, bob = .012, pitch = 0, off = { FL = .25, FR = .75, BL = 0, BR = .5 } },
            nP = sp.P.neck and sp.P.neck.pitch or 0, hP = sp.P.head and sp.P.head.pitch or 0, nY = 0, hY = 0,
            nextBeh = os.clock() + 2 + rnd() * 4, earNext = { os.clock() + 2, os.clock() + 3 }, earStart = { 0, 0 },
        }
        a.inst = instantiate(sp, fold)
        A[p] = a
        if p.Character then attachChar(a, p.Character) end
        a.charConn = p.CharacterAdded:Connect(function(c) attachChar(a, c) end)
    end

    local function removeAnimal(p)
        local a = A[p]
        if not a then return end
        if a.cc then a.cc:Disconnect() end
        if a.charConn then a.charConn:Disconnect() end
        for x, tr in pairs(a.store) do
            if x.Parent then x.Transparency = tr end
        end
        if a.inst and a.inst.folder then a.inst.folder:Destroy() end
        A[p] = nil
    end

    local function removeAll()
        local list = {}
        for p in pairs(A) do list[#list + 1] = p end
        for _, p in ipairs(list) do removeAnimal(p) end
    end

    local function updateAnimal(a, dt, now)
        if a.dirty then refreshRef(a) end
        local root, hum = a.root, a.hum
        if not (root and root.Parent and hum and hum.Parent) then
            a.inst.folder.Parent = nil
            return
        end
        a.inst.folder.Parent = fold
        local pos = root.Position
        local look = root.CFrame.LookVector
        local yaw = atan2(-look.X, -look.Z)
        if not a.lastPos then a.lastPos, a.yaw, a.vel = pos, yaw, V3() end
        local v = (pos - a.lastPos) / max(dt, 1e-3)
        if v.Magnitude > 220 then v = V3() end
        a.lastPos = pos
        a.vel = a.vel:Lerp(v, 1 - exp(-dt * 12))
        local hv = V3(a.vel.X, 0, a.vel.Z)
        local spd = hv.Magnitude
        local diff = wrapAng(yaw - a.yaw)
        a.yaw = a.yaw + diff * (1 - exp(-dt * 14))
        local rate = diff / max(dt, 1e-3)
        a.yawRate = lerp(a.yawRate, clamp(rate, -9, 9), 1 - exp(-dt * 8))
        local turn = clamp(a.yawRate * min(spd, 20) * 0.006, -0.25, 0.25)
        local fwd = V3(-sin(a.yaw), 0, -cos(a.yaw))
        local dirSign = hv:Dot(fwd) >= -0.25 * spd and 1 or -1

        local st = hum:GetState()
        local isAir = st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Jumping
            or st == Enum.HumanoidStateType.Flying or abs(a.vel.Y) > 14
        a.air = a.air + ((isAir and 1 or 0) - a.air) * (1 - exp(-dt * 10))
        a.lie = a.lie + ((hum.Sit and 1 or 0) - a.lie) * (1 - exp(-dt * 4))
        a.dead = a.dead + ((hum.Health <= 0 and 1 or 0) - a.dead) * (1 - exp(-dt * 3))

        local base = CF(pos.X, pos.Y - (a.rootOff or 3), pos.Z) * ANG(0, a.yaw, 0)
        if a.dead > 0.01 then
            local sp = a.spec
            local side = (a.seed > 3.14) and 1 or -1
            base = base * CF(0, sp.Hc - (sp.Hc - (sp.P.BW or 1) * SIZE * 0.5) * a.dead, 0)
                * ANG(0, 0, side * pi / 2 * a.dead) * CF(0, -sp.Hc, 0)
        end
        if a.spec.kind == "bird" then
            animBird(a, dt, now, spd, dirSign, a.air, a.lie, turn)
        else
            animQuad(a, dt, now, spd, dirSign, a.air, a.lie, turn)
        end
        updateInst(a.inst, base)
        -- debu terangkat saat berlari kencang
        if a.gait == "gallop" and spd > 16 and a.air < 0.3 and now - a.lastDust > 0.14 then
            a.lastDust = now
            FX.dust(V3(pos.X, pos.Y - (a.rootOff or 3) + 0.3, pos.Z), 0.35)
        end
    end

    local function refreshLabel()
        local n = 0
        for _ in pairs(A) do n = n + 1 end
        local lines = { string.format("%s | %d hewan | ukuran x%.2f", m.on and "AKTIF" or "siap", n, SIZE) }
        local c = 0
        for p, a in pairs(A) do
            c = c + 1
            if c <= 6 then lines[#lines + 1] = p.DisplayName .. ": " .. SPECIES[a.si].name end
        end
        if n > 6 then lines[#lines + 1] = "+" .. (n - 6) .. " lainnya" end
        m.say(table.concat(lines, "\n"))
    end

    local function createAll()
        for _, p in ipairs(Players:GetPlayers()) do createAnimal(p) end
    end
    local function rebuildAll()
        if not m.on then return end
        removeAll()
        createAll()
        refreshLabel()
    end

    m.roster = function(p, removed)
        if not p then return end
        if removed then
            local si = assigned[p.UserId]
            if si then used[si] = max(0, (used[si] or 1) - 1) assigned[p.UserId] = nil end
            removeAnimal(p)
        else
            createAnimal(p)
        end
        refreshLabel()
    end

    m.render = function(dt, now)
        dt = min(dt, 0.1)
        for _, a in pairs(A) do updateAnimal(a, dt, now) end
    end
    m.update = function(dt, now)
        if now - lastLabel > 1 then lastLabel = now refreshLabel() end
    end

    m.start = function()
        fold = Instance.new("Folder")
        fold.Name = "Hewan"
        fold.Parent = fxRoot
        createAll()
        refreshLabel()
    end
    m.stop = function()
        removeAll()
        if fold then fold:Destroy() fold = nil end
        m.say("siap")
    end

    UI.module(pg, m, "Jadi Hewan (J)")
    UI.row(pg, { { text = "Acak ulang hewan", cb = function()
        reroll = reroll + 1
        assigned, used = {}, {}
        rebuildAll()
    end } })
    UI.stepper(pg, "Ukuran", function() return SIZE end, function(v) SIZE = clamp(v, 0.6, 3) rebuildAll() end, 0.15, "x%.2f")
    UI.toggleOpt(pg, "Termasuk aku", function() return INCLUDE_ME end, function(v)
        INCLUDE_ME = v
        if m.on then
            if v then createAnimal(lp) else removeAnimal(lp) end
            refreshLabel()
        end
    end)
    UI.label(pg, "13 jenis hewan: tulang, IK kaki, jalan-trot-lari kencang, merumput, mengendus, mematuk, debu saat berlari. Posisi pemain tidak berubah.", 44)
    register(m)
end

State._HomeFeatureModules = Modules
State._SujudHub = Hub

-- Runtime SUJUD terikat pada lifecycle panel YOURSCRIPT (tanpa panel SUJUD).
local lastStop = 0
local function cleanupSujud()
	for _, m in ipairs(Modules) do
		if m.on then Hub.setOn(m, false) end
	end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() RS:UnbindFromRenderStep("SujudHubShake") end)
	releaseAllRigs()
	for p in pairs(rigs) do rigUnhook(p) end
	FX.clear()
	if fxRoot then fxRoot:Destroy() end
end
State._SujudCleanup = cleanupSujud

local function placeStep()
	local now = os.clock()
	local doStop = now - lastStop > 0.1
	if doStop then lastStop = now end
	for _, m in ipairs(Modules) do
		if m.on and m.place then
			local ok, err = pcall(m.place, now, doStop)
			if not ok then Hub.fail(m, err) end
		end
	end
end
bind(RS.Heartbeat, function(dt)
	dt = min(dt, 0.1)
	local now = os.clock()
	FX.update(dt)
	for _, m in ipairs(Modules) do
		if m.on and m.update then
			local ok, err = pcall(m.update, dt, now)
			if not ok then Hub.fail(m, err) end
		end
	end
	placeStep()
end)
bind(RS.Stepped, placeStep)
bind(RS.RenderStepped, function(dt)
	local now = os.clock()
	for _, m in ipairs(Modules) do
		if m.on and m.render then
			local ok, err = pcall(m.render, dt, now)
			if not ok then Hub.fail(m, err) end
		end
	end
	placeStep()
end)
bind(Players.PlayerAdded, function(p)
	rigHook(p)
	for _, m in ipairs(Modules) do
		if m.on and m.roster then pcall(m.roster, p, false) end
	end
end)
bind(Players.PlayerRemoving, function(p)
	rigUnhook(p)
	for _, m in ipairs(Modules) do
		if m.on and m.roster then pcall(m.roster, p, true) end
	end
end)
bind(UIS.InputBegan, function(input, processed)
	if processed then return end
	for _, m in ipairs(Modules) do
		if m.key and input.KeyCode == m.key then Hub.setOn(m, not m.on) end
	end
end)
	end
	-- Coming Soon locked tabs (tidak bisa diklik)
	local function MakeLockedTab(name, icon)
		local tab = Instance.new("TextButton")
		tab.Size = UDim2.new(0, 88, 0, 28)
		tab.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
		tab.Text = ""
		tab.BorderSizePixel = 0
		tab.AutoButtonColor = false
		tab.Active = false
		tab.Parent = tabBar
		Util.Corner(tab, 8)
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, -4, 1, 0)
		tl.Position = UDim2.new(0, 2, 0, 0)
		tl.BackgroundTransparency = 1
		tl.Text = (icon or "🔒") .. " " .. name
		tl.TextColor3 = Color3.fromRGB(90, 95, 110)
		tl.TextSize = 9
		tl.Font = Config.Font.Bold
		tl.Parent = tab
		tab.MouseButton1Click:Connect(function()
			Notify("Coming Soon", name.." masih dikunci", T.Sub)
		end)
	end
	MakeLockedTab("Soon", "🔒")
	MakeLockedTab("Soon", "⛓️")




	-- [FLY PAD] Tombol touch naik/turun Fly (mobile) — di sebelah kiri & bisa diatur posisinya
	if isMobile then
		local FC = Config.FlyPad
		local size, gap = FC.Size, FC.Gap
		local headH = 20
		local padH = headH + gap + size + gap + size

		local flyPad = Instance.new("Frame")
		flyPad.Name = "FlyPad"
		flyPad.Size = UDim2.new(0, size, 0, padH)
		flyPad.BackgroundTransparency = 1
		flyPad.Parent = gui

		-- posisi awal diambil dari Config (default: sebelah kiri)
		local posX = (FC.Side == "right") and UDim.new(1, -(FC.PosX + size)) or UDim.new(0, FC.PosX)
		local posY = UDim.new(FC.PosY, FC.PosYOffset)
		flyPad.Position = UDim2.new(posX.Scale, posX.Offset, posY.Scale, posY.Offset)

		-- handle "✥" untuk menggeser (mengatur) posisi pad
		local handle = Instance.new("TextButton")
		handle.Name = "FlyPadHandle"
		handle.Size = UDim2.new(1, 0, 0, headH)
		handle.Position = UDim2.new(0, 0, 0, 0)
		handle.BackgroundColor3 = T.Panel3
		handle.BackgroundTransparency = 0.35
		handle.Text = "+"
		handle.TextColor3 = T.Accent
		handle.TextSize = 12
		handle.Font = Config.Font.Bold
		handle.BorderSizePixel = 0
		handle.AutoButtonColor = false
		handle.Parent = flyPad
		Util.Corner(handle, 6)

		if FC.Draggable then
			local dragging, dragStart, startX, startY
			handle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					local ap = flyPad.AbsolutePosition
					startX, startY = ap.X, ap.Y
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then dragging = false end
					end)
				end
			end)
			Util.Connect("FlyPadDrag", Services.UIS.InputChanged, function(input)
				if not dragging then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch then
					local vp = Vector2.new(1280, 720)
					pcall(function()
						if Services.WS.CurrentCamera then
							vp = Services.WS.CurrentCamera.ViewportSize
						end
					end)
					local d = input.Position - dragStart
					local nx = math.clamp(startX + d.X, 0, math.max(0, vp.X - size))
					local ny = math.clamp(startY + d.Y, 0, math.max(0, vp.Y - padH))
					flyPad.Position = UDim2.new(0, nx, 0, ny)
				end
			end)
		end

		-- tombol ▲ / ▼ (logika asli tidak diubah)
		for _, data in ipairs({
			{ txt = "▲", y = headH + gap, key = "FlyUp" },
			{ txt = "▼", y = headH + gap + size + gap, key = "FlyDown" },
		}) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, size, 0, size)
			b.Position = UDim2.new(0, 0, 0, data.y)
			b.BackgroundColor3 = T.Panel3
			b.BackgroundTransparency = 0.35
			b.Text = data.txt
			b.TextColor3 = T.Text
			b.TextSize = 22
			b.Font = Config.Font.Title
			b.BorderSizePixel = 0
			b.Visible = false
			b.Parent = flyPad
			Util.Corner(b, 12)
			local function press(v) return function() State[data.key] = v end end
			b.MouseButton1Down:Connect(press(true))
			b.MouseButton1Up:Connect(press(false))
			b.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.Touch then State[data.key] = true end
			end)
			b.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.Touch then State[data.key] = false end
			end)
			UI[data.key .. "Btn"] = b
		end

		-- [BARU] ANALOG JOYSTICK untuk Fly
		local stickBase = Instance.new("Frame")
		stickBase.Name = "FlyStick"
		stickBase.Size = UDim2.new(0, size * 2, 0, size * 2)
		stickBase.Position = UDim2.new(0, 0, 0, padH + gap)
		stickBase.BackgroundColor3 = T.Panel3
		stickBase.BackgroundTransparency = 0.45
		stickBase.BorderSizePixel = 0
		stickBase.Visible = false
		stickBase.Parent = flyPad
		Util.Corner(stickBase, size * 2) -- lingkaran penuh

		local stickKnob = Instance.new("Frame")
		stickKnob.Size = UDim2.new(0, size, 0, size)
		stickKnob.AnchorPoint = Vector2.new(0.5, 0.5)
		stickKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
		stickKnob.BackgroundColor3 = T.Accent
		stickKnob.BackgroundTransparency = 0.25
		stickKnob.BorderSizePixel = 0
		stickKnob.Parent = stickBase
		Util.Corner(stickKnob, size)

		local maxR = size * 0.75 -- radius gerak knob
		local stickTouch = nil

		stickBase.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				stickTouch = i
				local ap = stickBase.AbsolutePosition
				local as = stickBase.AbsoluteSize
				local cx, cy = ap.X + as.X / 2, ap.Y + as.Y / 2
				local function apply(pos)
					local dx, dy = pos.X - cx, pos.Y - cy
					local mag = math.sqrt(dx * dx + dy * dy)
					if mag > maxR then dx, dy = dx / mag * maxR, dy / mag * maxR end
					stickKnob.Position = UDim2.new(0.5, dx, 0.5, dy)
					-- layar: atas = maju, kanan = kanan → State
					State.FlyMoveY = -dy / maxR   -- layar Y terbalik
					State.FlyMoveX = dx / maxR
				end
				apply(i.Position)
				Util.Connect("FlyStickMove", Services.UIS.InputChanged, function(inp)
					if inp == stickTouch then apply(inp.Position) end
				end)
				Util.Connect("FlyStickEnd", Services.UIS.InputEnded, function(inp)
					if inp == stickTouch then
						stickTouch = nil
						stickKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
						State.FlyMoveX, State.FlyMoveY = 0, 0
						Util.Disconnect("FlyStickMove")
						Util.Disconnect("FlyStickEnd")
					end
				end)
			end
		end)

		-- joystick hanya tampil saat Fly aktif (mengikuti visible tombol fly)
		local function SyncStick()
			stickBase.Visible = State.FlyOn
			-- tinggi pad diperbesar saat joystick tampil
			flyPad.Size = UDim2.new(0, size * 2, 0, padH + gap + size * 2)
		end
		Util.Connect("FlyStickSync", UI.FlyUpBtn:GetPropertyChangedSignal("Visible"), SyncStick)
		SyncStick()

		-- handle ikut sembunyi saat Fly tidak aktif
		-- (hanya memantau properti Visible, modul Movement tidak diubah)
		local function SyncFlyPad()
			local up = UI.FlyUpBtn and UI.FlyUpBtn.Visible
			local dn = UI.FlyDownBtn and UI.FlyDownBtn.Visible
			flyPad.Visible = (up or dn) and true or false
		end
		if UI.FlyUpBtn then
			Util.Connect("FlyPadUp", UI.FlyUpBtn:GetPropertyChangedSignal("Visible"), SyncFlyPad)
		end
		if UI.FlyDownBtn then
			Util.Connect("FlyPadDown", UI.FlyDownBtn:GetPropertyChangedSignal("Visible"), SyncFlyPad)
		end
		SyncFlyPad()
		UI.FlyPad = flyPad
		UI.FlyPadHandle = handle
	end

	-- default tab
	-- [UNIFIED DESKTOP] tidak auto-select Move; Home Hub yang tampil
	-- if not (UI.IsMobile or isMobile) then tabs["Move"].select() end

	-- Drag
	if P.Drag then
		local dragging, dragStart, startPos
		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = panel.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		Util.Connect("Drag", Services.UIS.InputChanged, function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local d = input.Position - dragStart
				panel.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end)
	end

	-- Resize handles (pojok + tepi) — panel karet, tab ikut menyesuaikan
	do
		local minW, minH, maxW, maxH = 220, 280, 700, 900
		local function startResize(input, mode)
			local start = input.Position
			local startSize = panel.Size
			local startPos = panel.Position
			local connMove, connEnd
			connMove = Services.UIS.InputChanged:Connect(function(inp)
				if inp.UserInputType ~= Enum.UserInputType.MouseMovement
					and inp.UserInputType ~= Enum.UserInputType.Touch then return end
				local d = inp.Position - start
				local w = startSize.X.Offset
				local h = startSize.Y.Offset
				local px, py = startPos.X.Offset, startPos.Y.Offset
				if mode:find("r") then w = math.clamp(startSize.X.Offset + d.X, minW, maxW) end
				if mode:find("b") then h = math.clamp(startSize.Y.Offset + d.Y, minH, maxH) end
				if mode:find("l") then
					w = math.clamp(startSize.X.Offset - d.X, minW, maxW)
					px = startPos.X.Offset + (startSize.X.Offset - w)
				end
				if mode:find("t") then
					h = math.clamp(startSize.Y.Offset - d.Y, minH, maxH)
					py = startPos.Y.Offset + (startSize.Y.Offset - h)
				end
				panel.Size = UDim2.new(0, w, 0, h)
				panel.Position = UDim2.new(startPos.X.Scale, px, startPos.Y.Scale, py)
				P.Width, P.Height = w, h
			end)
			connEnd = Services.UIS.InputEnded:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1
					or inp.UserInputType == Enum.UserInputType.Touch then
					if connMove then connMove:Disconnect() end
					if connEnd then connEnd:Disconnect() end
				end
			end)
		end
		local function mkHandle(name, size, pos, mode, cursor)
			local h = Instance.new("TextButton")
			h.Name = name
			h.Size = size
			h.Position = pos
			h.BackgroundColor3 = T.Accent
			h.BackgroundTransparency = 0.55
			h.Text = ""
			h.BorderSizePixel = 0
			h.ZIndex = 20
			h.Parent = panel
			Util.Corner(h, 4)
			h.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					startResize(input, mode)
				end
			end)
		end
		mkHandle("RS_BR", UDim2.new(0, 16, 0, 16), UDim2.new(1, -16, 1, -16), "rb")
		mkHandle("RS_R", UDim2.new(0, 8, 1, -32), UDim2.new(1, -8, 0, 16), "r")
		mkHandle("RS_B", UDim2.new(1, -32, 0, 8), UDim2.new(0, 16, 1, -8), "b")
		mkHandle("RS_L", UDim2.new(0, 8, 1, -32), UDim2.new(0, 0, 0, 16), "l")
		mkHandle("RS_T", UDim2.new(1, -32, 0, 8), UDim2.new(0, 16, 0, 0), "t")
	end

	-- Hide / Show
	local tabOpen = Instance.new("TextButton")
	tabOpen.Size = UDim2.new(0, 28, 0, 72)
	tabOpen.Position = UDim2.new(0, -40, 0.5, -36)
	tabOpen.BackgroundColor3 = T.Accent
	tabOpen.Text = "S\nI\nD\nE"
	tabOpen.TextColor3 = Color3.fromRGB(8, 12, 20)
	tabOpen.TextSize = 9
	tabOpen.Font = Config.Font.Title
	tabOpen.BorderSizePixel = 0
	tabOpen.Visible = false
	tabOpen.Parent = gui
	Util.Corner(tabOpen, 8)

	local function SetPanelVisible(v)
		State.PanelVisible = v
		local goalSize = UDim2.new(0, panel.Size.X.Offset > 0 and panel.Size.X.Offset or P.Width, 0, panel.Size.Y.Offset > 0 and panel.Size.Y.Offset or P.Height)
		if v then
			-- pastikan posisi tetap di tempat (glass materialize)
			panel.Position = UDim2.new(0, P.PosX, P.PosYScale, P.PosYOffset)
			panel:SetAttribute("SRF_BT", P.Transparency or 0.08)
			Util.GlassIn(panel, goalSize, 0.45)
			tabOpen.Visible = false
		else
			Util.GlassOut(panel, 0.32, function()
				if not State.PanelVisible then panel.Visible = false end
			end)
			tabOpen.Visible = true
			tabOpen.BackgroundTransparency = 1
			Util.Tween(tabOpen, { BackgroundTransparency = 0.12 }, 0.25, Enum.EasingStyle.Quint)
			tabOpen.Position = UDim2.new(0, 0, 0.5, -36)
		end
	end

	function TogglePanel()
		SetPanelVisible(not State.PanelVisible)
	end

	hideBtn.MouseButton1Click:Connect(function() SetPanelVisible(false) end)
	tabOpen.MouseButton1Click:Connect(function() SetPanelVisible(true) end)
	closeBtn.MouseButton1Click:Connect(function() CleanupAll() end)

	UI.SetPanelVisible = SetPanelVisible
	UI.TogglePanel = TogglePanel

	-- store toggle refs for keybinds
	UI.Toggles = {
		Speed = tSpeed, Fly = tFly, Noclip = tNC, InfJump = tIJ,
		Fullbright = tFB, NoFog = tNF,
		ItemESP = tItemESP, MonsterESP = tMonESP, PlayerESP = tPlrESP,
		Cage = tCage, AutoCage = tACage, Freeze = tFrz,
		ClickTP = tCTP,
		AntiAFK = tAFK, FPSBoost = tFPS,
		Spectate = tSpec,
		-- [MERGED]
		SoundSpam = tSound,
	}
	UI.SpeedSlider = speedSlider

	----------------------------------------------------------------
	-- MOBILE Home Hub + Floating (fungsi tetap sama, hanya layout)
	----------------------------------------------------------------
	local MobileHUD = { Host = nil }

	local function DestroyMobileHUD()
		if MobileHUD.Host then pcall(function() MobileHUD.Host:Destroy() end) end
		MobileHUD.Host = nil
		MobileHUD.TabLayers = {}
	end

	local function MakeDrag(frame)
		-- drag via UIS (Frame.InputChanged sering tidak fire Touch di mobile)
		local dragging, dragInput, startIn, startPos
		frame.Active = true
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragInput = input
				startIn = input.Position
				startPos = frame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						dragInput = nil
					end
				end)
			end
		end)
		Services.UIS.InputChanged:Connect(function(input)
			if not dragging then return end
			if input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local d = input.Position - startIn
				frame.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end)
	end

	-- FBtn mobile-friendly premium: pill + soft stroke + pop-in
	local function FBtn(host, text, color, pos, onClick, isToggle, getOn, isLocked)
		local locked = isLocked and true or false
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0, 118, 0, 40)
		if pos then f.Position = pos end
		f.BackgroundColor3 = locked and Color3.fromRGB(24, 24, 28) or (color or T.Pill or T.Panel2)
		f.BackgroundTransparency = locked and 0.05 or 0.08
		f:SetAttribute("SRF_BT", locked and 0.05 or 0.08)
		f.BorderSizePixel = 0
		f.ZIndex = 60
		f.Active = true
		f.Parent = host
		Util.Corner(f, 14)
		Util.Stroke(f, Color3.fromRGB(255,255,255), 1, locked and 0.92 or 0.88)

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, locked and -22 or -8, 1, 0)
		btn.Position = UDim2.new(0, locked and 20 or 4, 0, 0)
		btn.BackgroundTransparency = 1
		btn.Text = text
		btn.TextColor3 = locked and Color3.fromRGB(90, 95, 110) or T.Text
		btn.TextSize = 11
		btn.Font = Config.Font.Bold
		btn.ZIndex = 61
		btn.AutoButtonColor = not locked
		btn.Parent = f
		if locked then
			pcall(function()
				local holder = Instance.new("Frame")
				holder.Name = "SRF_LockIcon"
				holder.BackgroundTransparency = 1
				holder.BorderSizePixel = 0
				holder.Size = UDim2.fromOffset(12, 12)
				holder.Position = UDim2.new(0, 8, 0.5, -6)
				holder.ZIndex = 62
				holder.Parent = f
				gIconDraw(holder, "lock", 12, Color3.fromRGB(90, 95, 110))
			end)
		end

		local function refresh()
			if not isToggle then return end
			local on = getOn and getOn()
			btn.Text = text .. (on and " · ON" or " · OFF")
			Util.Tween(f, { BackgroundColor3 = on and T.Green or (color or T.Pill or T.Panel2) }, 0.15)
			btn.TextColor3 = on and Color3.fromRGB(12, 14, 16) or T.Text
		end
		if isToggle then refresh() end
		btn.MouseButton1Click:Connect(function()
			-- micro press
			Util.Tween(f, { Size = UDim2.new(0, 112, 0, 36) }, 0.06)
			task.delay(0.06, function()
				if f and f.Parent then Util.Tween(f, { Size = UDim2.new(0, 118, 0, 40) }, 0.1, Enum.EasingStyle.Back) end
			end)
			Util.Safe(onClick)
			if isToggle then task.defer(refresh) end
		end)
		MakeDrag(f)
		pcall(function() Util.PopIn(f, Config.Anim.Pop) end)
		return f
	end


	local function SpawnHomeHub()
		-- tutup panel lama + sembunyikan semua float tab (anti numpuk)
		pcall(function() if UI.SetPanelVisible then UI.SetPanelVisible(false) end end)
		if MobileHUD.TabLayers then
			for _, layer in pairs(MobileHUD.TabLayers) do
				if layer and layer.Parent then layer.Visible = false end
			end
		end
		-- [UNIFIED DESKTOP] Home Hub aktif di desktop & mobile
		-- JANGAN DestroyMobileHUD() — pertahankan floating buttons dari tab lain
		local host = MobileHUD.Host
		if not host or not host.Parent then
			host = Instance.new("Frame")
			host.Name = "MobileTabHUD"
			host.Size = UDim2.new(1, 0, 1, 0)
			host.BackgroundTransparency = 1
			host.Parent = gui
			MobileHUD.Host = host
		end
		-- Hapus hanya HomeCard lama, biarkan FBtn / float tab lain tetap ada
		local oldCard = host:FindFirstChild("HomeCard")
		if oldCard then pcall(function() oldCard:Destroy() end) end
		local card = Instance.new("Frame")
		card.Name = "HomeCard"
		card.Size = UDim2.new(0, 320, 0, 346)
		card.Position = UDim2.new(0.5, -160, 0.5, -173)
		card.BackgroundColor3 = T.Panel
		card.BackgroundTransparency = 0.06
		card:SetAttribute("SRF_BT", 0.06)
		card.BorderSizePixel = 0
		card.ZIndex = 50
		card.Parent = host
		Util.Corner(card, 20)
		Util.Stroke(card, Color3.fromRGB(255,255,255), 1, 0.88)
		MakeDrag(card)
		card:SetAttribute("SRF_BT", 0.08)
		pcall(function() Util.GlassIn(card, card.Size, 0.4) end)
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -180, 0, 28)
		title.Position = UDim2.new(0, 12, 0, 6)
		title.BackgroundTransparency = 1
		title.Text = "YOURSCRIPT · HOME"
		title.TextColor3 = T.Text
		title.TextSize = 12
		title.Font = Config.Font.Bold
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 51
		title.Parent = card

		-- [LOGO] gambar logo menggantikan teks "YOURSCRIPT" (ukuran setara teks lama)
		do
			local img = Glass.MakeLogo(card, UDim2.new(0, 104, 0, 30), UDim2.new(0, 8, 0, 3), 52)
			if img then
				title.Visible = false
				local hm = Instance.new("TextLabel")
				hm.Name = "HomeTag"
				hm.Size = UDim2.new(0, 56, 0, 18)
				hm.Position = UDim2.new(0, 116, 0, 9)
				hm.BackgroundTransparency = 1
				hm.Text = "· HOME"
				hm.TextColor3 = T.Sub
				hm.TextSize = 10
				hm.Font = Config.Font.Bold
				hm.TextXAlignment = Enum.TextXAlignment.Left
				hm.ZIndex = 52
				hm.Parent = card
			end
		end

		-- Language switcher: bendera premium (kecil). EN = Inggris, ID = Indonesia
		State.Lang = Glass.I18N.lang or State.Lang or "id"
		local flagBtns = {}
		local function makeLangBtn(code, xOff)
			local imgId = Glass.Img(code == "en" and "flag_en" or "flag_id")
			local b
			if imgId then
				b = Instance.new("ImageButton")
				b.BackgroundTransparency = 1
				b.Image = imgId
				b.ScaleType = Enum.ScaleType.Fit
			else -- cadangan kalau executor tidak punya getcustomasset
				b = Instance.new("TextButton")
				b.Text = string.upper(code)
				b.TextSize = 9
				b.Font = Config.Font.Bold
				b.BackgroundColor3 = T.Panel2
				b.BackgroundTransparency = 0.2
				b.TextColor3 = T.Sub
			end
			b.Name = "Lang_" .. code
			b.Size = UDim2.new(0, 27, 0, 18)
			b.Position = UDim2.new(1, xOff, 0, 9)
			b.BorderSizePixel = 0
			b.ZIndex = 55
			b.AutoButtonColor = false
			b.Parent = card
			Util.Corner(b, 5)
			local st = Util.Stroke(b, T.Accent, 1.5, 0.9)
			flagBtns[code] = { btn = b, stroke = st, isImg = imgId ~= nil }
			return b
		end
		local enBtn = makeLangBtn("en", -128)
		local idBtn = makeLangBtn("id", -97)
		local function paintLang()
			for code, f in pairs(flagBtns) do
				local on = (State.Lang == code)
				f.stroke.Transparency = on and 0 or 0.9
				if f.isImg then
					f.btn.ImageTransparency = on and 0 or 0.55
				else
					f.btn.BackgroundColor3 = on and T.Accent or T.Panel2
					f.btn.TextColor3 = on and Color3.fromRGB(8,12,20) or T.Sub
				end
			end
		end
		paintLang()
		local function setLang(lang)
			if State.Lang == lang then paintLang() return end
			Glass.I18N.SetLang(lang) -- terjemahkan seluruh teks GUI
			paintLang()
			Notify("YOURSCRIPT", lang == "en" and "Language: ENGLISH" or "Bahasa: INDONESIA", T.Accent)
		end
		enBtn.MouseButton1Click:Connect(function() setLang("en") end)
		idBtn.MouseButton1Click:Connect(function() setLang("id") end)

		-- Minimize (−) dan Close (✕) di pojok kanan atas Home — premium style
		local minBtn = Instance.new("TextButton")
		minBtn.Name = "HomeMin"
		minBtn.Size = UDim2.new(0, 28, 0, 24)
		minBtn.Position = UDim2.new(1, -62, 0, 7)
		minBtn.BackgroundColor3 = T.Panel2
		minBtn.BackgroundTransparency = 0.15
		minBtn.Text = "−"
		minBtn.TextColor3 = T.Sub
		minBtn.TextSize = 16
		minBtn.Font = Config.Font.Bold
		minBtn.BorderSizePixel = 0
		minBtn.ZIndex = 55
		minBtn.Parent = card
		Util.Corner(minBtn, 8)
		Util.Stroke(minBtn, Color3.fromRGB(255,255,255), 1, 0.85)
		minBtn.MouseEnter:Connect(function()
			Util.Tween(minBtn, { BackgroundColor3 = T.Accent2, TextColor3 = T.Text, BackgroundTransparency = 0.05 }, 0.12)
		end)
		minBtn.MouseLeave:Connect(function()
			Util.Tween(minBtn, { BackgroundColor3 = T.Panel2, TextColor3 = T.Sub, BackgroundTransparency = 0.15 }, 0.12)
		end)

		local closeBtn = Instance.new("TextButton")
		closeBtn.Name = "HomeClose"
		closeBtn.Size = UDim2.new(0, 28, 0, 24)
		closeBtn.Position = UDim2.new(1, -30, 0, 7)
		closeBtn.BackgroundColor3 = T.Panel2
		closeBtn.BackgroundTransparency = 0.15
		closeBtn.Text = "✕"
		closeBtn.TextColor3 = T.Red
		closeBtn.TextSize = 14
		closeBtn.Font = Config.Font.Bold
		closeBtn.BorderSizePixel = 0
		closeBtn.ZIndex = 55
		closeBtn.Parent = card
		Util.Corner(closeBtn, 8)
		Util.Stroke(closeBtn, Color3.fromRGB(255,255,255), 1, 0.85)
		closeBtn.MouseEnter:Connect(function()
			Util.Tween(closeBtn, { BackgroundColor3 = T.Red, TextColor3 = T.Text, BackgroundTransparency = 0.05 }, 0.12)
		end)
		closeBtn.MouseLeave:Connect(function()
			Util.Tween(closeBtn, { BackgroundColor3 = T.Panel2, TextColor3 = T.Red, BackgroundTransparency = 0.15 }, 0.12)
		end)

		Glass.IconBtn(minBtn, { ["−"] = "minus", ["+"] = "plus" }, 22)
		Glass.IconBtn(closeBtn, { ["✕"] = "cross" }, 22)

		-- body (kategori + tombol) bisa di-minimize
		local body = Instance.new("Frame")
		body.Name = "HomeBody"
		body.Size = UDim2.new(1, 0, 1, -36)
		body.Position = UDim2.new(0, 0, 0, 36)
		body.BackgroundTransparency = 1
		body.ZIndex = 51
		body.Parent = card

		local homeMinimized = false
		minBtn.MouseButton1Click:Connect(function()
			homeMinimized = not homeMinimized
			body.Visible = not homeMinimized
			card.Size = homeMinimized and UDim2.new(0, 320, 0, 36) or UDim2.new(0, 320, 0, 346)
			minBtn.Text = homeMinimized and "+" or "−"
		end)
		closeBtn.MouseButton1Click:Connect(function()
			pcall(function() card:Destroy() end)
		end)
		local cats = {
			{"ESP","ESP"},{"MOVE","Move"},{"TELEPORT","TP"},
			{"FARM","Farm"},{"MOB","Mob"},{"VISUAL","Visual"},
			{"PLAYER","Player"},{"UTIL","Util"},{"GAME","Game"},
			{"EXTRA","Extra"},{"COMBAT","Combat"},{"LOAD","Load"},
			{"TROLL","Troll"},{"SOON I","_locked1"},{"SOON II","_locked2"},
		}
		for i, c in ipairs(cats) do
			local col, row = (i-1)%3, math.floor((i-1)/3)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, 94, 0, 40)
			b.Position = UDim2.new(0, 12+col*102, 0, 10+row*48)
			local locked = (c[2] == "_locked1" or c[2] == "_locked2")
			local isNew = (c[2] == "Extra" or c[2] == "Combat" or c[2] == "Load" or c[2] == "Troll")
			b.BackgroundColor3 = locked and Color3.fromRGB(24,24,28) or (isNew and T.Active or T.Pill or T.Panel2)
			b.BackgroundTransparency = locked and 0.05 or 0.05
			b.Text = c[1]
			b.TextColor3 = locked and Color3.fromRGB(90,95,110) or T.Text
			b.TextSize = 11
			b.Font = Config.Font.Bold
			b.BorderSizePixel = 0
			b.ZIndex = 52
			b.AutoButtonColor = not locked
			b.Parent = body
			Util.Corner(b, 14)
			Util.Stroke(b, Color3.fromRGB(255,255,255), 1, locked and 0.92 or 0.88)
			-- staggered pop
			task.delay((i-1)*0.03, function()
				if b and b.Parent then pcall(function() Util.PopIn(b, 0.14) end) end
			end)
			local tn = c[2]
			b.MouseButton1Click:Connect(function()
				if locked then
					Notify("Coming Soon", "Tab ini masih dikunci", T.Sub)
					return
				end
				UI._skipMobileHUD = false
				if tabs[tn] then
					currentTab = nil
					tabs[tn].select()
				else
					Notify("Home", "Tab "..tostring(tn).." belum siap", T.Orange)
				end
			end)
		end

		-- Panel show / close + Restart
		local function makeHomeBtn(txt, x, y, col, fn)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, 92, 0, 34)
			b.Position = UDim2.new(0, x, 0, y)
			b.BackgroundColor3 = col or T.Panel2
			b.BackgroundTransparency = 0.08
			b.Text = txt
			b.TextColor3 = (col == T.Accent) and Color3.fromRGB(8,12,20) or T.Text
			b.TextSize = 11
			b.Font = Config.Font.Bold
			b.BorderSizePixel = 0
			b.ZIndex = 52
			b.Parent = body
			Util.Corner(b, 10)
			Util.Stroke(b, T.Accent, 1, 0.45)
			b.MouseButton1Click:Connect(fn)
			return b
		end
		makeHomeBtn("SHOW PANEL", 12, 266, T.Accent, function()
			UI._skipMobileHUD = true
			if UI.SetPanelVisible then UI.SetPanelVisible(true) end
			Notify("Home", "Panel dibuka", T.Green)
		end)
		makeHomeBtn("CLOSE PANEL", 113, 266, T.Panel2, function()
			if UI.SetPanelVisible then UI.SetPanelVisible(false) end
			Notify("Home", "Panel ditutup", T.Sub)
		end)
		makeHomeBtn("RESTART", 214, 266, T.Orange, function()
			Notify("Home", "Restart panel...", T.Orange)
			-- Bersihkan semua float build yang berantakan
			pcall(function()
				if MobileHUD.Host then MobileHUD.Host:Destroy() end
			end)
			MobileHUD.Host = nil
			MobileHUD.TabLayers = {}
			-- Tampilkan panel utama lagi
			UI._skipMobileHUD = true
			if UI.SetPanelVisible then UI.SetPanelVisible(true) end
			task.delay(0.35, function()
				UI._skipMobileHUD = false
				SpawnHomeHub()
				Notify("Home", "Panel direset", T.Green)
			end)
		end)

		UI.SetPanelVisible(false)
	end

	local function SpawnTabFloat(tabName)
		-- Mobile-first: tombol kiri/kanan, mudah di-tap; anti menumpuk antar-tab
		if tabName == "Home" then SpawnHomeHub() return end

		local root = MobileHUD.Host
		if not root or not root.Parent then
			root = Instance.new("Frame")
			root.Name = "MobileTabHUD"
			root.Size = UDim2.new(1, 0, 1, 0)
			root.BackgroundTransparency = 1
			root.Parent = gui
			MobileHUD.Host = root
		end
		MobileHUD.TabLayers = MobileHUD.TabLayers or {}

		local hc = root:FindFirstChild("HomeCard")
		if hc then hc.Visible = false end

		-- Sembunyikan layer tab lain (jangan numpuk)
		for n, layer in pairs(MobileHUD.TabLayers) do
			if layer and layer.Parent then
				layer.Visible = (n == tabName)
			end
		end

		if MobileHUD.TabLayers[tabName] and MobileHUD.TabLayers[tabName].Parent then
			MobileHUD.TabLayers[tabName].Visible = true
			return
		end

		local layer = Instance.new("Frame")
		layer.Name = "TabFloat_" .. tabName
		layer.Size = UDim2.new(1, 0, 1, 0)
		layer.BackgroundTransparency = 1
		layer.Parent = root
		MobileHUD.TabLayers[tabName] = layer
		local host = layer

		-- Posisi mobile-friendly: kiri & kanan, tidak menutup tengah layar
		local function ly(i) return UDim2.new(0, 10, 0, 50+(i-1)*48) end
		local function ry(i) return UDim2.new(1, -128, 0, 50+(i-1)*48) end
		local function flip(k) return function() if UI.Toggles[k] then UI.Toggles[k].flip() end end end
		local function getT(k) return function() return UI.Toggles[k] and UI.Toggles[k].get() end end


		-- helper: center search+list panel (Farm / Player)
		local function MakeSearchList(title, getNames, onPick, selectedLabel)
			local card = Instance.new("Frame")
			card.Size = UDim2.new(0, 200, 0, 220)
			card.Position = UDim2.new(0.5, -100, 0.35, -80)
			card.BackgroundColor3 = T.Panel
			card.BackgroundTransparency = 0.12
			card.BorderSizePixel = 0
			card.ZIndex = 55
			card.Parent = host
			Util.Corner(card, 12)
			Util.Stroke(card, T.Accent, 1, 0.4)
			MakeDrag(card)
			local head = Instance.new("TextLabel")
			head.Size = UDim2.new(1, -30, 0, 22)
			head.Position = UDim2.new(0, 8, 0, 4)
			head.BackgroundTransparency = 1
			head.Text = title
			head.TextColor3 = T.Accent
			head.TextSize = 11
			head.Font = Config.Font.Bold
			head.TextXAlignment = Enum.TextXAlignment.Left
			head.ZIndex = 56
			head.Parent = card
			local minb = Instance.new("TextButton")
			minb.Size = UDim2.new(0, 22, 0, 18)
			minb.Position = UDim2.new(1, -26, 0, 4)
			minb.BackgroundTransparency = 1
			minb.Text = "—"
			minb.TextColor3 = T.Sub
			minb.TextSize = 14
			minb.ZIndex = 57
			minb.Parent = card
			local body = Instance.new("Frame")
			body.Size = UDim2.new(1, -12, 1, -32)
			body.Position = UDim2.new(0, 6, 0, 28)
			body.BackgroundTransparency = 1
			body.ZIndex = 56
			body.Parent = card
			minb.MouseButton1Click:Connect(function()
				body.Visible = not body.Visible
				card.Size = body.Visible and UDim2.new(0, 200, 0, 220) or UDim2.new(0, 200, 0, 28)
			end)
			local sbox = Instance.new("TextBox")
			sbox.Size = UDim2.new(1, 0, 0, 26)
			sbox.BackgroundColor3 = T.Panel2
			sbox.PlaceholderText = "SEARCH"
			sbox.PlaceholderColor3 = T.Sub
			sbox.Text = ""
			sbox.TextColor3 = T.Text
			sbox.TextSize = 12
			sbox.Font = Config.Font.Bold
			sbox.ClearTextOnFocus = false
			sbox.ZIndex = 57
			sbox.Parent = body
			Util.Corner(sbox, 6)
			local scroll = Instance.new("ScrollingFrame")
			scroll.Size = UDim2.new(1, 0, 1, -30)
			scroll.Position = UDim2.new(0, 0, 0, 30)
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 3
			scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
			scroll.ZIndex = 57
			scroll.Parent = body
			local lay = Instance.new("UIListLayout")
			lay.Padding = UDim.new(0, 3)
			lay.Parent = scroll
			local function rebuild(filter)
				for _, ch in ipairs(scroll:GetChildren()) do
					if ch:IsA("TextButton") then ch:Destroy() end
				end
				local names = getNames()
				local f = string.lower(filter or "")
				local n = 0
				for _, name in ipairs(names) do
					if f == "" or string.find(string.lower(name), f, 1, true) then
						n = n + 1
						local b = Instance.new("TextButton")
						b.Size = UDim2.new(1, -2, 0, 24)
						b.BackgroundColor3 = T.Panel2
						b.Text = "  " .. name
						b.TextColor3 = T.Text
						b.TextSize = 11
						b.Font = Config.Font.Bold
						b.TextXAlignment = Enum.TextXAlignment.Left
						b.BorderSizePixel = 0
						b.ZIndex = 58
						b.Parent = scroll
						Util.Corner(b, 5)
						local marked = IsSpamMarked(name)
						if marked then
							b.Text = "  *  " .. name
							b.TextColor3 = T.Green
							b.BackgroundColor3 = Color3.fromRGB(30, 55, 40)
						end
						b.MouseButton1Click:Connect(function()
							local on = ToggleSpamMark(name)
							b.Text = (on and "  *  " or "  ") .. name
							b.TextColor3 = on and T.Green or T.Text
							b.BackgroundColor3 = on and Color3.fromRGB(30, 55, 40) or T.Panel2
							onPick(name)
							if selectedLabel then
								local n = #GetSpamMarkList()
								selectedLabel.Text = n > 0 and ("*" .. n .. " " .. name) or name
							end
							Notify(on and "★ Ditandai" or "Hapus tanda", name .. " (" .. #GetSpamMarkList() .. ")", on and T.Green or T.Sub)
						end)
					end
				end
				scroll.CanvasSize = UDim2.new(0, 0, 0, n * 27)
			end
			sbox:GetPropertyChangedSignal("Text"):Connect(function() rebuild(sbox.Text) end)
			rebuild("")
			return card
		end

		if tabName == "Move" then
			FBtn(host, "SPEED", nil, ly(1), flip("Speed"), true, getT("Speed"))
			FBtn(host, "FLY", nil, ly(2), flip("Fly"), true, getT("Fly"))
			FBtn(host, "NOCLIP", nil, ry(1), flip("Noclip"), true, getT("Noclip"))
			FBtn(host, "INF JUMP", nil, ry(2), flip("InfJump"), true, getT("InfJump"))
			-- R4: speed value widget
			local spd = Instance.new("Frame")
			spd.Size = UDim2.new(0, 130, 0, 44)
			spd.Position = ly(3)
			spd.BackgroundColor3 = T.Panel2
			spd.BackgroundTransparency = 0.28
			spd.BorderSizePixel = 0
			spd.ZIndex = 60
			spd.Parent = host
			Util.Corner(spd, 12)
			Util.Stroke(spd, T.Accent, 1, 0.4)
			local spdLbl = Instance.new("TextLabel")
			spdLbl.Size = UDim2.new(1, 0, 0, 16)
			spdLbl.Position = UDim2.new(0, 0, 0, 2)
			spdLbl.BackgroundTransparency = 1
			spdLbl.Text = "SPD: " .. string.format("%.1f", State.SpeedMul or Config.Movement.SpeedDefault)
			spdLbl.TextColor3 = T.Accent
			spdLbl.TextSize = 11
			spdLbl.Font = Config.Font.Bold
			spdLbl.ZIndex = 61
			spdLbl.Parent = spd
			local minus = Instance.new("TextButton")
			minus.Size = UDim2.new(0.45, -4, 0, 22)
			minus.Position = UDim2.new(0.05, 0, 0, 18)
			minus.BackgroundColor3 = T.Panel3
			minus.Text = "−"
			minus.TextColor3 = T.Text
			minus.TextSize = 16
			minus.Font = Config.Font.Bold
			minus.BorderSizePixel = 0
			minus.ZIndex = 61
			minus.Parent = spd
			Util.Corner(minus, 6)
			local plus = Instance.new("TextButton")
			plus.Size = UDim2.new(0.45, -4, 0, 22)
			plus.Position = UDim2.new(0.5, 2, 0, 18)
			plus.BackgroundColor3 = T.Panel3
			plus.Text = "+"
			plus.TextColor3 = T.Text
			plus.TextSize = 16
			plus.Font = Config.Font.Bold
			plus.BorderSizePixel = 0
			plus.ZIndex = 61
			plus.Parent = spd
			Util.Corner(plus, 6)
			local function setSpd(v)
				v = math.clamp(math.floor(v * 10 + 0.5) / 10, Config.Movement.SpeedMin, Config.Movement.SpeedMax)
				if UI.SpeedSlider then UI.SpeedSlider.set(v) end
				State.SpeedMul = v
				spdLbl.Text = "SPD: " .. string.format("%.1f", v)
			end
			minus.MouseButton1Click:Connect(function() setSpd(Movement.SpeedStep(State.SpeedMul or 2, -1)) end)
			plus.MouseButton1Click:Connect(function() setSpd(Movement.SpeedStep(State.SpeedMul or 2, 1)) end)
			MakeDrag(spd)

		elseif tabName == "TP" then
			FBtn(host, "TP BUNKER", T.Accent, ly(1), Teleport.Bunker)
			FBtn(host, "TP MARKET", T.Accent, ly(2), Teleport.Market)
			FBtn(host, "TP RARE", T.Accent, ly(3), Teleport.Rare)
			FBtn(host, "SAVE POS", T.Panel2, ry(1), Teleport.SavePos)
			FBtn(host, "RETURN", T.Panel2, ry(2), Teleport.ReturnPos)
			FBtn(host, "CLICK TP", nil, ry(3), flip("ClickTP"), true, getT("ClickTP"))

		elseif tabName == "Farm" then
			-- R6: layout sesuai sketsa + Gudang Langka di menu utama
			local selLbl = Instance.new("TextButton")
			selLbl.Size = UDim2.new(0, 130, 0, 36)
			selLbl.Position = UDim2.new(0.5, -65, 1, -90)
			selLbl.BackgroundColor3 = T.Panel2
			selLbl.BackgroundTransparency = 0.2
			selLbl.Text = State.ItemName ~= "" and State.ItemName or "NAMA ITEM"
			selLbl.TextColor3 = T.Green
			selLbl.TextSize = 12
			selLbl.Font = Config.Font.Bold
			selLbl.BorderSizePixel = 0
			selLbl.ZIndex = 60
			selLbl.Parent = host
			Util.Corner(selLbl, 10)
			MakeDrag(selLbl)

			local function onPickItem(name)
				State.ItemName = name
				State.AutoFarmItem = name
				pcall(Teleport.UpdateLabelsFromCache)
				Notify("Farm", "Item: " .. name, T.Green)
			end

			-- Daftar Item (kiri)
			local listAll = MakeSearchList("DAFTAR ITEM", function()
				local names, seen = {}, {}
				local function add(n)
					if n and n ~= "" and not seen[n] then seen[n]=true; table.insert(names, n) end
				end
				for _, o in ipairs(ScanCache.Items or {}) do if o and o.Parent then add(o.Name) end end
				local wy = Services.WS:FindFirstChild("Wyposazenie")
				if wy then
					for _, c in ipairs(wy:GetChildren()) do
						local nm = tostring(c.Name)
						if not nm:match("^%d+_Wyposazenie$") then
							if c:IsA("Model") or c:IsA("Tool") then add(c.Name) end
						end
					end
				end
				local mw = Services.WS:FindFirstChild("MarketWyposazenie")
					or Services.WS:FindFirstChild("MarketWyposazenie", true)
				if mw then
					for _, c in ipairs(mw:GetChildren()) do
						if c:IsA("Model") or c:IsA("Tool") then add(c.Name) end
					end
				end
				table.sort(names)
				return names
			end, onPickItem, selLbl)
			listAll.Position = UDim2.new(0.5, -210, 0.32, -80)

			-- Gudang Langka (kanan) — menu utama
			local listRare = MakeSearchList("GUDANG LANGKA", function()
				return GetGudangLangkaNames()
			end, function(name)
				State.ItemName = name
				State.AutoFarmItem = name
				pcall(Teleport.UpdateLabelsFromCache)
				Notify("Gudang Langka", name, T.Yellow)
			end, selLbl)
			listRare.Position = UDim2.new(0.5, 12, 0.32, -80)
			-- warnai header jadi kuning
			for _, ch in ipairs(listRare:GetChildren()) do
				if ch:IsA("TextLabel") and ch.Text == "GUDANG LANGKA" then
					ch.TextColor3 = T.Yellow
				end
			end
			Util.Stroke(listRare, T.Yellow, 1.5, 0.35)

			FBtn(host, "TP TO ITEM", T.Accent, ly(1), function() Teleport.TPToItem() end)
			FBtn(host, "AMBIL TERPILIH", T.Green, ly(2), function() Farming.GrabRemoteOne() end)
			FBtn(host, "REFRESH ITEM", T.Panel2, ly(3), function() Teleport.RefreshItem() end)
			FBtn(host, "< SPAWN", T.Panel2, ly(4), function() Teleport.PrevSpawn() end)
			FBtn(host, "AMBIL TERDEKAT", T.Green, ry(1), function() if _G.SRF_GrabNearest then _G.SRF_GrabNearest() else Farming.GrabNearest() end end)
			FBtn(host, "SPAM ITEM", nil, ry(2), function() Game.ToggleSpamItem() end, true, function() return State.SpamItemOn end)
			FBtn(host, "MARKET ONLY", T.Yellow, ry(3), function()
				State.MarketOnly = not State.MarketOnly
				Notify("Market Only", State.MarketOnly and "ON" or "OFF", State.MarketOnly and T.Green or T.Sub)
			end, true, function() return State.MarketOnly end)
			FBtn(host, "CLEAR *", T.Orange, ry(4), function()
				ClearSpamMarks()
				if selLbl then selLbl.Text = State.ItemName ~= "" and State.ItemName or "NAMA ITEM" end
				Notify("Spam Marks", "Tanda dihapus", T.Sub)
			end)
			FBtn(host, "+ DROP PT", T.Green, ly(5), function() AddDropPoint() end)
			FBtn(host, "CLR DROPS", T.Orange, ry(5), function() ClearDropPoints() end)
			FBtn(host, "SPAWN >", T.Orange, ly(6), function() Teleport.NextSpawn() end)
			FBtn(host, "SAVE POS", T.Accent, ry(6), Teleport.SavePos)


		elseif tabName == "ESP" then
			FBtn(host, "ITEM ESP", nil, ly(1), flip("ItemESP"), true, getT("ItemESP"))
			FBtn(host, "MONSTER ESP", nil, ly(2), flip("MonsterESP"), true, getT("MonsterESP"))
			FBtn(host, "PLAYER ESP", nil, ly(3), flip("PlayerESP"), true, getT("PlayerESP"))
			FBtn(host, "FULLBRIGHT", nil, ry(1), flip("Fullbright"), true, getT("Fullbright"))
			FBtn(host, "NO FOG", nil, ry(2), flip("NoFog"), true, getT("NoFog"))

		elseif tabName == "Mob" then
			-- R7: spawn detector (cage/freeze sering tidak berpengaruh di game)
			FBtn(host, "SPAWN DETECT", nil, ly(1), function()
				State._mobSpawnDetect = not State._mobSpawnDetect
				if State._mobSpawnDetect then
					Notify("Mob", "Spawn Markers ON", T.Green)

					-- ikon + warna khas tiap monster
					local MONSTER_STYLE = {
						Lurker = { icon = "👁", color = Color3.fromRGB(180, 180, 200), label = "LURKER" },
						Pocong = { icon = "👻", color = Color3.fromRGB(200, 255, 200), label = "POCONG" },
						Jumper = { icon = "🦴", color = Color3.fromRGB(255, 160, 120), label = "JUMPER" },
						Jumper2 = { icon = "🦴", color = Color3.fromRGB(255, 140, 100), label = "JUMPER" },
						JumperDoor = { icon = "🚪", color = Color3.fromRGB(255, 100, 80), label = "JUMPER DOOR" },
						Samara = { icon = "👧", color = Color3.fromRGB(180, 100, 255), label = "SAMARA" },
						Catcher = { icon = "🦾", color = Color3.fromRGB(255, 60, 60), label = "CATCHER" },
					}

					local function styleFor(name)
						local n = string.lower(name or "")
						for key, st in pairs(MONSTER_STYLE) do
							if n:find(string.lower(key), 1, true) then return st end
						end
						return { icon = "◆", color = Color3.fromRGB(255, 80, 80), label = name or "SPAWN" }
					end

					if not State._knownSpawns then
						State._knownSpawns = {
							{410, 8, 290, "Pocong"},
							{410, 8, -630, "Pocong"},
							{390, 8, 575, "Pocong"},
							{415, 8, -330, "Pocong"},
							{85, 8, -330, "Pocong"},
							{115, 8, 280, "Pocong"},
							{90, 9, -5, "Pocong"},
							{-13, 9, 167, "Pocong"},
							{390, 8, -35, "Pocong"},
							{403, 8, -23, "Lurker"},
							{403, 9, 279, "Lurker"},
							{45, 10, -225, "Jumper2"},
							{44, 10, 179, "Jumper2"},
							{335, 9, 580, "Jumper2"},
							{320, 9, -615, "Jumper2"},
							{360, 9, -320, "Jumper2"},
							{330, 9, 229, "Jumper2"},
							{380, 9, -50, "Jumper2"},
							{738, 5.5, -734, "JumperDoor"},
							{736, 5.5, -740, "JumperDoor"},
							{733, 5, -746, "JumperDoor"},
							{740, 5.5, -742, "JumperDoor"},
							{121, 6, 178, "Samara"},
							{75, 6, -136, "Samara"},
							{369, 5, 150, "Samara"},
							{393, 5, -118, "Samara"},
							{-45, 6, 42, "Samara"},
							{-189, 6, 42, "Samara"},
							{411, 14, 0, "Catcher"},
						}
					end

					for _, obj in ipairs(Services.WS:GetChildren()) do
						if obj.Name == "SRF_SpawnPoint" then
							pcall(function() obj:Destroy() end)
						end
					end

					local function findTemplate(label)
						local n = string.lower(label or "")
						local map = {
							lurker = {"LurkerNight", "DN_TheLurker_01", "TheLurker"},
							pocong = {"PocongNight", "DN_Pocong_01", "Pocong"},
							jumper = {"JumperNight", "DN_Jumper2_01", "Jumper2"},
							jumpe = {"JumperNight", "DN_JumperDoor_01", "JumperDoor"},
							samara = {"SamaraNight", "DN_Samara_01", "Samara"},
							catcher = {"CatcherNight", "DN_TheCatcher_01", "TheCatcher"},
						}
						for key, info in pairs(map) do
							if n:find(key, 1, true) then
								local folder = Services.Rep:FindFirstChild(info[1])
								if folder then
									local m = folder:FindFirstChild(info[2]) or folder:FindFirstChild(info[3])
									if m then return m end
									for _, ch in ipairs(folder:GetChildren()) do
										if ch:IsA("Model") then return ch end
									end
								end
							end
						end
						return nil
					end

					local function makeMarker(x, y, z, label)
						local st = styleFor(label)
						local template = findTemplate(label)

						if template then
							-- clone model asli monster (bentuk mereka)
							local ok, clone = pcall(function() return template:Clone() end)
							if ok and clone then
								clone.Name = "SRF_SpawnPoint"
								for _, d in ipairs(clone:GetDescendants()) do
									if d:IsA("BasePart") then
										d.Anchored = true
										d.CanCollide = false
										d.Transparency = math.clamp(d.Transparency, 0.35, 0.7)
									end
									if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Humanoid") then
										pcall(function() d:Destroy() end)
									end
								end
								-- scale kecil biar tidak nutupin
								pcall(function()
									if clone:IsA("Model") then
										local pp = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
										if pp then clone:PivotTo(CFrame.new(x, y, z)) end
									end
								end)
								clone.Parent = Services.WS

								-- label nama di atas
								local part = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
								if part then
									local bb = Instance.new("BillboardGui")
									bb.Size = UDim2.new(0, 100, 0, 22)
									bb.AlwaysOnTop = true
									bb.StudsOffset = Vector3.new(0, 4, 0)
									bb.Adornee = part
									bb.Parent = part
									local tl = Instance.new("TextLabel")
									tl.Size = UDim2.new(1, 0, 1, 0)
									tl.BackgroundTransparency = 1
									tl.Text = st.label
									tl.TextColor3 = st.color
									tl.TextSize = 12
									tl.Font = Config.Font.Bold
									tl.TextStrokeTransparency = 0.3
									tl.Parent = bb
								end
								return clone
							end
						end

						-- fallback: ikon billboard
						local anchor = Instance.new("Part")
						anchor.Name = "SRF_SpawnPoint"
						anchor.Size = Vector3.new(0.15, 0.15, 0.15)
						anchor.Anchored = true
						anchor.CanCollide = false
						anchor.Transparency = 1
						anchor.CFrame = CFrame.new(x, y + 2, z)
						anchor.Parent = Services.WS

						local bb = Instance.new("BillboardGui")
						bb.Size = UDim2.new(0, 90, 0, 50)
						bb.AlwaysOnTop = true
						bb.Adornee = anchor
						bb.Parent = anchor

						local icon = Instance.new("TextLabel")
						icon.Size = UDim2.new(1, 0, 0, 28)
						icon.BackgroundTransparency = 1
						icon.Text = st.icon
						icon.TextColor3 = st.color
						icon.TextSize = 24
						icon.Font = Config.Font.Bold
						icon.Parent = bb

						local tl = Instance.new("TextLabel")
						tl.Size = UDim2.new(1, 0, 0, 18)
						tl.Position = UDim2.new(0, 0, 0, 28)
						tl.BackgroundTransparency = 1
						tl.Text = st.label
						tl.TextColor3 = st.color
						tl.TextSize = 11
						tl.Font = Config.Font.Bold
						tl.TextStrokeTransparency = 0.3
						tl.TextStrokeColor3 = Color3.new(0, 0, 0)
						tl.Parent = bb

						return anchor
					end

					for _, sp in ipairs(State._knownSpawns) do
						makeMarker(sp[1], sp[2], sp[3], sp[4])
					end

					-- belajar posisi PERTAMA kali saja
					task.spawn(function()
						local gen = _G.SRF_GEN
						local seenModels = {}
						while State._mobSpawnDetect and gen == _G.SRF_GEN do
							for _, folder in ipairs(Services.WS:GetChildren()) do
								if (folder:IsA("Folder") or folder:IsA("Model")) and folder.Name:match("Night$") then
									for _, model in ipairs(folder:GetChildren()) do
										if model:IsA("Model") and not seenModels[model] then
											local part = model.PrimaryPart
												or model:FindFirstChild("HumanoidRootPart")
												or model:FindFirstChildOfClass("BasePart")
											if part then
												seenModels[model] = true
												local px = math.floor(part.Position.X + 0.5)
												local py = math.floor(part.Position.Y + 0.5)
												local pz = math.floor(part.Position.Z + 0.5)
												local exists = false
												for _, sp in ipairs(State._knownSpawns) do
													local dx, dy, dz = sp[1]-px, sp[2]-py, sp[3]-pz
													if dx*dx + dy*dy + dz*dz < 144 then exists = true; break end
												end
												if not exists then
													table.insert(State._knownSpawns, {px, py, pz, model.Name})
													makeMarker(px, py, pz, model.Name)
												end
											end
										end
									end
								end
							end
							task.wait(2.5)
						end
					end)
				else
					Notify("Mob", "Spawn Markers OFF", T.Sub)
					for _, obj in ipairs(Services.WS:GetChildren()) do
						if obj.Name == "SRF_SpawnPoint" then
							pcall(function() obj:Destroy() end)
						end
					end
				end
			end, true, function() return State._mobSpawnDetect end)
			FBtn(host, "CAGE", nil, ly(2), flip("Cage"), true, getT("Cage"))
			FBtn(host, "AUTO CAGE", nil, ry(1), flip("AutoCage"), true, getT("AutoCage"))
			FBtn(host, "FREEZE", nil, ry(2), flip("Freeze"), true, getT("Freeze"))

		elseif tabName == "Player" then
			-- R9: search + list + tracker
			local pSel = Instance.new("TextButton")
			pSel.Size = UDim2.new(0, 130, 0, 36)
			pSel.Position = UDim2.new(0.5, -65, 1, -90)
			pSel.BackgroundColor3 = T.Panel2
			pSel.BackgroundTransparency = 0.2
			pSel.Text = (State.TargetPlayer and (State.TargetPlayer.DisplayName or State.TargetPlayer.Name)) or "NAMA PLAYER"
			pSel.TextColor3 = T.Accent
			pSel.TextSize = 12
			pSel.Font = Config.Font.Bold
			pSel.BorderSizePixel = 0
			pSel.ZIndex = 60
			pSel.Parent = host
			Util.Corner(pSel, 10)
			MakeDrag(pSel)

			MakeSearchList("SEARCH / DAFTAR PLAYER", function()
				local names = {}
				for _, p in ipairs(Services.Players:GetPlayers()) do
					if p ~= LP then table.insert(names, p.DisplayName or p.Name) end
				end
				table.sort(names)
				return names
			end, function(name)
				local plr
				for _, candidate in ipairs(Services.Players:GetPlayers()) do
					if candidate ~= LP and (candidate.DisplayName or candidate.Name) == name then plr = candidate; break end
				end
				if plr then
					local list = Util.GetPlayers()
					for i, p in ipairs(list) do
						if p == plr then State.TargetIdx = i; break end
					end
					State.TargetPlayer, State.Target = plr, plr
					pcall(Teleport.RefreshTarget)
					State.TargetPlayer, State.Target = plr, plr
					if pSel then pSel.Text = plr.DisplayName or plr.Name end
					if State.SpectateOn then
						local hum = Util.Hum(plr)
						local cam = Services.WS.CurrentCamera
						if hum and cam then cam.CameraSubject = hum; State.SpectateTarget = plr end
					end
					Notify("Player", "Target: " .. (plr.DisplayName or plr.Name), T.Green)
				end
			end, pSel)

			FBtn(host, "TP TARGET", T.Accent, ly(1), function() Teleport.ToPlayer() end)
			FBtn(host, "SPECTATE", nil, ly(2), flip("Spectate"), true, getT("Spectate"))
			FBtn(host, "PLAYER TRACK", nil, ry(1), function()
				State.PlayerTracker = not State.PlayerTracker
				if State.PlayerTracker then
					ESP.StartLoop()
					Notify("Player", "Tracker ON", T.Green)
				else
					Notify("Player", "Tracker OFF", T.Sub)
				end
			end, true, function() return State.PlayerTracker end)

		elseif tabName == "Util" then
			-- R10: + Join User
			FBtn(host, "ANTI AFK", nil, ly(1), flip("AntiAFK"), true, getT("AntiAFK"))
			FBtn(host, "FPS BOOST", nil, ly(2), flip("FPSBoost"), true, getT("FPSBoost"))
			FBtn(host, "REJOIN", T.Panel2, ry(1), Utility.Rejoin)
			FBtn(host, "SERVER HOP", T.Panel2, ry(2), Utility.ServerHop)
			local jbox = Instance.new("TextBox")
			jbox.Size = UDim2.new(0, 130, 0, 36)
			jbox.Position = ly(3)
			jbox.BackgroundColor3 = T.Panel2
			jbox.BackgroundTransparency = 0.2
			jbox.PlaceholderText = "username"
			jbox.PlaceholderColor3 = T.Sub
			jbox.Text = ""
			jbox.TextColor3 = T.Text
			jbox.TextSize = 12
			jbox.Font = Config.Font.Bold
			jbox.ClearTextOnFocus = false
			jbox.ZIndex = 60
			jbox.Parent = host
			Util.Corner(jbox, 10)
			MakeDrag(jbox)
			FBtn(host, "JOIN USER", T.Accent, ry(3), function()
				Utility.JoinUserServer(jbox.Text)
			end)

		elseif tabName == "Game" then
			-- R11: tanpa walkspeed
			FBtn(host, "COLLECT FOOD", T.Accent, ly(1), Game.CollectAllFood)
			FBtn(host, "DROP FOOD", T.Orange, ly(2), Game.DropAllFood)
			FBtn(host, "SOUND SPAM", nil, ry(1), flip("SoundSpam"), true, getT("SoundSpam"))

		elseif tabName == "Visual" then
			-- R8: sinkron panel lama
			FBtn(host, "NO GRASS", nil, ly(1), function()
				Visual.ToggleNoGrass()
			end, true, function() return State.NoGrass end)
			FBtn(host, "NO SHADOW", nil, ly(2), function()
				Visual.ToggleNoShadow()
			end, true, function() return State.NoShadow end)
			FBtn(host, "ZOOM UNLOCK", nil, ry(1), function()
				if State.ZoomUnlock then Visual.DisableZoomUnlock() else Visual.EnableZoomUnlock() end
			end, true, function() return State.ZoomUnlock end)
			FBtn(host, "FREE CAM", nil, ry(2), function()
				if State.FreeCam then Visual.DisableFreeCam() else Visual.EnableFreeCam() end
			end, true, function() return State.FreeCam end)
			FBtn(host, "FULLBRIGHT", nil, ly(3), flip("Fullbright"), true, getT("Fullbright"))
			FBtn(host, "NO FOG", nil, ry(3), flip("NoFog"), true, getT("NoFog"))
			FBtn(host, "ULTRA HD", nil, ly(4), function()
				if State.UltraHD then Visual.DisableUltraHD() else Visual.EnableUltraHD() end
			end, true, function() return State.UltraHD end)
			FBtn(host, "HUJAN", Color3.fromRGB(24, 24, 28), ly(5), function()
				Notify("Tahap pengembangan", "Hujan masih dikunci", Config.Theme.Sub)
			end, nil, nil, true)
			FBtn(host, "BANJIR", Color3.fromRGB(24, 24, 28), ry(5), function()
				Notify("Tahap pengembangan", "Banjir masih dikunci", Config.Theme.Sub)
			end, nil, nil, true)
			FBtn(host, "SALJU", Color3.fromRGB(24, 24, 28), ly(6), function()
				Notify("Tahap pengembangan", "Salju masih dikunci", Config.Theme.Sub)
			end, nil, nil, true)
			-- Grafis (SujudHub) dipindah dari Troll ke Visual
			do
				local mods = State._HomeFeatureModules or {}
				local hub = State._SujudHub
				if hub then
					for _, m in ipairs(mods) do
						if m.name == "Grafis" then
							FBtn(host, "GRAFIS", m.color or T.Accent, ry(4), function()
								hub.setOn(m, not m.on)
							end, true, function() return m.on end)
							break
						end
					end
				end
			end

		elseif tabName == "Extra" then
			FBtn(host, "XRAY", nil, ly(1), function() if State.XrayOn then Extra.DisableXray() else Extra.EnableXray() end end, true, function() return State.XrayOn end)
			FBtn(host, "INVISIBLE", nil, ly(2), function() if State.InvisibleOn then Extra.DisableInvisible() else Extra.EnableInvisible() end end, true, function() return State.InvisibleOn end)
			FBtn(host, "LIGHT", nil, ly(3), function() if State.CharLightOn then Extra.DisableCharLight() else Extra.EnableCharLight() end end, true, function() return State.CharLightOn end)
			FBtn(host, "FLOAT", nil, ry(1), function() if State.FloatOn then Extra.DisableFloat() else Extra.EnableFloat() end end, true, function() return State.FloatOn end)
			FBtn(host, "SPIN", nil, ry(2), function() if State.SpinOn then Extra.DisableSpin() else Extra.EnableSpin() end end, true, function() return State.SpinOn end)
			FBtn(host, "NO GRAV", nil, ry(3), function() if State.NoGravityOn then Extra.DisableNoGravity() else Extra.EnableNoGravity() end end, true, function() return State.NoGravityOn end)
			FBtn(host, "GODMODE", nil, ly(4), function() if State.GodModeOn then Extra.DisableGodMode() else Extra.EnableGodMode() end end, true, function() return State.GodModeOn end)
			FBtn(host, "ANTI FLING", nil, ry(4), function() if State.AntiFlingOn then Extra.DisableAntiFling() else Extra.EnableAntiFling() end end, true, function() return State.AntiFlingOn end)
			FBtn(host, "GRAB TOOLS", T.Green, ly(5), Extra.GrabTools)
			FBtn(host, "DROP TOOLS", T.Orange, ry(5), Extra.DropTools)
			FBtn(host, "FIRE PROMPT", T.Accent, ly(6), Extra.FireAllPrompts)
			FBtn(host, "INSTANT PP", nil, ry(6), function() if State.InstantPromptOn then Extra.DisableInstantPrompt() else Extra.EnableInstantPrompt() end end, true, function() return State.InstantPromptOn end)
			FBtn(host, "SAVE WP", T.Accent, ly(7), Extra.SaveWaypoint)
			FBtn(host, "TP WP", T.Green, ry(7), Extra.TPWaypoint)
			FBtn(host, "NPC NEAREST", T.Accent, ly(8), Extra.ControlNearestNPC)
			FBtn(host, "NPC CLICK", nil, ry(8), function() if State.NPCControlOn then Extra.DisableNPCClick() else Extra.EnableNPCClick() end end, true, function() return State.NPCControlOn end)
			FBtn(host, "RESTORE CHAR", T.Panel2, ly(9), Extra.RestoreOriginalCharacter)
			FBtn(host, "PLATFORM", T.Panel2, ry(9), Extra.Platform)
			local function cy(i) return UDim2.new(0.5, -59, 0, 50+(i-1)*48) end
			FBtn(host, "LOAD OUTFITS", T.Accent, cy(1), Extra.AvLoad)
			FBtn(host, "< AVATAR", T.Panel2, cy(2), Extra.AvPrevApply)
			FBtn(host, "AVATAR >", T.Panel2, cy(3), Extra.AvNextApply)

		elseif tabName == "Combat" then
			local tLbl = Instance.new("TextButton")
			tLbl.Size = UDim2.new(0, 160, 0, 32)
			tLbl.Position = UDim2.new(0.5, -80, 0, 8)
			tLbl.BackgroundColor3 = T.Panel
			tLbl.BackgroundTransparency = 0.15
			tLbl.Text = (State.TargetPlayer and ("🎯 "..(State.TargetPlayer.DisplayName or State.TargetPlayer.Name))) or "🎯 TARGET"
			tLbl.TextColor3 = T.Accent
			tLbl.TextSize = 12
			tLbl.Font = Config.Font.Bold
			tLbl.BorderSizePixel = 0
			tLbl.ZIndex = 60
			tLbl.Parent = host
			Util.Corner(tLbl, 10)
			MakeDrag(tLbl)
			FBtn(host, "< TARGET", T.Panel2, ly(1), function()
				Teleport.PrevPlayer()
				local t = State.TargetPlayer or State.Target
				tLbl.Text = t and ("🎯 "..(t.DisplayName or t.Name)) or "🎯 TARGET"
				if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = t and ("TARGET: "..(t.DisplayName or t.Name)) or "TARGET: -" end
			end)
			FBtn(host, "TARGET >", T.Panel2, ry(1), function()
				Teleport.NextPlayer()
				local t = State.TargetPlayer or State.Target
				tLbl.Text = t and ("🎯 "..(t.DisplayName or t.Name)) or "🎯 TARGET"
				if UI.CombatTargetLbl then UI.CombatTargetLbl.Text = t and ("TARGET: "..(t.DisplayName or t.Name)) or "TARGET: -" end
			end)
			FBtn(host, "AIMBOT", nil, ly(2), function() if State.AimbotOn then Extra.DisableAimbot() else Extra.EnableAimbot() end end, true, function() return State.AimbotOn end)
			FBtn(host, "HITBOX", nil, ly(3), function() if State.HitboxOn then Extra.DisableHitbox() else Extra.EnableHitbox() end end, true, function() return State.HitboxOn end)
			FBtn(host, "REACH", nil, ly(4), function() if State.ReachOn then Extra.DisableReach() else Extra.EnableReach() end end, true, function() return State.ReachOn end)
			FBtn(host, "MAGNETIZE", T.Accent, ry(2), function() if State.MagnetizeOn then Extra.DisableMagnetize() else Extra.EnableMagnetize(State.MagnetizeTarget) end end, true, function() return State.MagnetizeOn end)
			FBtn(host, "SPIN FLING", T.Orange, ry(3), function() if State.SpinFlingOn then Extra.DisableSpinFling() else Extra.EnableSpinFling() end end, true, function() return State.SpinFlingOn end)
			FBtn(host, "HIDDEN FLING", T.Red, ry(4), function() if State.HiddenFlingOn then Extra.DisableHiddenFling() else Extra.EnableHiddenFling() end end, true, function() return State.HiddenFlingOn end)
			FBtn(host, "TOUCH FLING", nil, ly(5), function() if State.TouchFlingOn then Extra.DisableTouchFling() else Extra.EnableTouchFling() end end, true, function() return State.TouchFlingOn end)
			FBtn(host, "CLICK FLING", nil, ry(5), function() if State.ClickFlingOn then Extra.DisableClickFling() else Extra.EnableClickFling() end end, true, function() return State.ClickFlingOn end)
			FBtn(host, "ORBIT", nil, ly(6), function() if State.OrbitOn then Extra.DisableOrbit() else Extra.EnableOrbit() end end, true, function() return State.OrbitOn end)
			FBtn(host, "FAKELAG", nil, ry(6), function() if State.FakeLagOn then Extra.DisableFakeLag() else Extra.EnableFakeLag() end end, true, function() return State.FakeLagOn end)
			FBtn(host, "STALK", nil, ly(7), function() if State.StalkOn then Extra.DisableStalk() else Extra.EnableStalk() end end, true, function() return State.StalkOn end)
			FBtn(host, "STARE", nil, ry(7), function() if State.StareOn then Extra.DisableStare() else Extra.EnableStare() end end, true, function() return State.StareOn end)
			FBtn(host, "SELF FLING", T.Orange, ly(8), Extra.SelfFling)

		elseif tabName == "Troll" then
			-- Daftar player (draggable) + Attach
			local pSel = Instance.new("TextButton")
			pSel.Size = UDim2.new(0, 130, 0, 36)
			pSel.Position = UDim2.new(0.5, -65, 1, -90)
			pSel.BackgroundColor3 = T.Panel2
			pSel.BackgroundTransparency = 0.2
			pSel.Text = (State.TargetPlayer and (State.TargetPlayer.DisplayName or State.TargetPlayer.Name)) or "NAMA PLAYER"
			pSel.TextColor3 = T.Accent
			pSel.TextSize = 12
			pSel.Font = Config.Font.Bold
			pSel.BorderSizePixel = 0
			pSel.ZIndex = 60
			pSel.Parent = host
			Util.Corner(pSel, 10)
			MakeDrag(pSel)
			MakeSearchList("DAFTAR PLAYER", function()
				local names = {}
				for _, p in ipairs(Services.Players:GetPlayers()) do
					if p ~= LP then table.insert(names, p.DisplayName or p.Name) end
				end
				table.sort(names)
				return names
			end, function(name)
				local plr
				for _, candidate in ipairs(Services.Players:GetPlayers()) do
					if candidate ~= LP and (candidate.DisplayName or candidate.Name) == name then plr = candidate; break end
				end
				if plr then
					local list = Util.GetPlayers()
					for i, p in ipairs(list) do
						if p == plr then State.TargetIdx = i; break end
					end
					State.TargetPlayer, State.Target = plr, plr
					pcall(Teleport.RefreshTarget)
					if pSel then pSel.Text = plr.DisplayName or plr.Name end
					if UI.TrollTargetLbl then UI.TrollTargetLbl.Text = "TARGET: "..(plr.DisplayName or plr.Name) end
					Notify("Troll", "Target: " .. (plr.DisplayName or plr.Name), T.Green)
				end
			end, pSel)
			FBtn(host, "BACKPACK", nil, ly(1), function()
				if State.AttachOn and State.AttachMode=="backpack" then Extra.StopAttach() else Extra.StartAttach("backpack") end
			end, true, function() return State.AttachOn and State.AttachMode=="backpack" end)
			FBtn(host, "BANG", T.Orange, ry(1), function()
				if State.AttachOn and State.AttachMode=="bang" then Extra.StopAttach() else Extra.StartAttach("bang") end
			end, true, function() return State.AttachOn and State.AttachMode=="bang" end)
			FBtn(host, "FACEBANG", T.Orange, ly(2), function()
				if State.AttachOn and State.AttachMode=="facebang" then Extra.StopAttach() else Extra.StartAttach("facebang") end
			end, true, function() return State.AttachOn and State.AttachMode=="facebang" end)
			FBtn(host, "HEADSIT", nil, ry(2), function()
				if State.AttachOn and State.AttachMode=="headsit" then Extra.StopAttach() else Extra.StartAttach("headsit") end
			end, true, function() return State.AttachOn and State.AttachMode=="headsit" end)
			FBtn(host, "SHOULDERSIT", nil, ly(3), function()
				if State.AttachOn and State.AttachMode=="shouldersit" then Extra.StopAttach() else Extra.StartAttach("shouldersit") end
			end, true, function() return State.AttachOn and State.AttachMode=="shouldersit" end)
			FBtn(host, "CARPET", nil, ry(3), function()
				if State.AttachOn and State.AttachMode=="carpet" then Extra.StopAttach() else Extra.StartAttach("carpet") end
			end, true, function() return State.AttachOn and State.AttachMode=="carpet" end)
			FBtn(host, "MAGNETIZE", T.Accent, ly(4), function()
				if State.MagnetizeOn then Extra.DisableMagnetize() else Extra.EnableMagnetize(State.MagnetizeTarget) end
			end, true, function() return State.MagnetizeOn end)
			FBtn(host, "STOP ATTACH", T.Red, ry(4), Extra.StopAttach)

			-- SujudHub modul di float Troll (Grafis dikecualikan — sudah di tab Visual)
			do
				local mods = State._HomeFeatureModules or {}
				local hub = State._SujudHub
				if hub and #mods > 0 then
					local n = 0
					for _, m in ipairs(mods) do
						if m.name ~= "Grafis" then
							n = n + 1
							local idx = 4 + math.ceil(n / 2)
							local pos = (n % 2 == 1) and ly(idx) or ry(idx)
							local col = m.color or T.Purple
							FBtn(host, string.upper(tostring(m.name or ("M"..n))), col, pos, function()
								hub.setOn(m, not m.on)
							end, true, function() return m.on end)
						end
					end
				end
			end

		elseif tabName == "Load" then
			FBtn(host, "DEX", T.Accent, ly(1), Extra.LoadDex)
			FBtn(host, "REMOTESPY", T.Accent, ly(2), Extra.LoadRemoteSpy)
			FBtn(host, "INFINITE YIELD", T.Green, ry(1), Extra.LoadIY)
			FBtn(host, "GRAB TOOL", T.Orange, ry(2), Extra.LoadGrabTool)
		end

		-- Bawah layar: mudah di-tap di mobile
		local peek = Instance.new("TextButton")
		peek.Size = UDim2.new(0, 100, 0, 36)
		peek.Position = UDim2.new(0.5, -108, 1, -48)
		peek.BackgroundColor3 = T.Panel
		peek.BackgroundTransparency = 0.15
		peek.Text = "PANEL"
		peek.TextColor3 = T.Accent
		peek.TextSize = 13
		peek.Font = Config.Font.Bold
		peek.BorderSizePixel = 0
		peek.ZIndex = 70
		peek.Active = true
		peek.Parent = host
		Util.Corner(peek, 12)
		MakeDrag(peek)
		peek.MouseButton1Click:Connect(function()
			layer.Visible = false
			UI._skipMobileHUD = true
			UI.SetPanelVisible(true)
		end)
		local home = Instance.new("TextButton")
		home.Size = UDim2.new(0, 100, 0, 36)
		home.Position = UDim2.new(0.5, 8, 1, -48)
		home.BackgroundColor3 = T.Panel
		home.BackgroundTransparency = 0.15
		home.Text = "HOME"
		home.TextColor3 = T.Text
		home.TextSize = 13
		home.Font = Config.Font.Bold
		home.BorderSizePixel = 0
		home.ZIndex = 70
		home.Active = true
		home.Parent = host
		Util.Corner(home, 12)
		MakeDrag(home)
		home.MouseButton1Click:Connect(function()
			layer.Visible = false
			SpawnHomeHub()
		end)
		UI.SetPanelVisible(false)
	end

	UI.OnTabSelect = function(name)
		if UI._skipMobileHUD then UI._skipMobileHUD = false return end
		-- Panel lama terbuka: biarkan MakePage ganti page, jangan paksa float
		if State.PanelVisible then return end
		SpawnTabFloat(name)
	end
	UI.DestroyMobileHUD = DestroyMobileHUD

	-- [UNIFIED DESKTOP] selalu tampilkan Home Hub di desktop & mobile
	task.defer(SpawnHomeHub)
	print("[YOURSCRIPT] Unified HUD ready IsMobile=", UI.IsMobile)
end

----------------------------------------------------------------
-- KEYBINDS
----------------------------------------------------------------
local function BindKeys()
	-- Keybind keyboard OFF
	return
end

----------------------------------------------------------------
-- WATERMARK LOOP (FPS / PING / TIME)
----------------------------------------------------------------
local function StartWatermark()
	local frames, last = 0, os.clock()
	Util.Connect("WM", Services.RS.Heartbeat, function()
		frames = frames + 1
		local now = os.clock()
		if now - last >= 0.5 then
			local fps = math.floor(frames / (now - last))
			frames, last = 0, now
			local ping = 0
			pcall(function()
				ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			local t = os.date("%H:%M:%S")
			if UI.Watermark then
				UI.Watermark.Text = string.format("YOURSCRIPT  |  %d fps  |  %d ms  |  %s", fps, ping, t)
			end
		end
	end)
end

----------------------------------------------------------------
-- RESPAWN HANDLER
----------------------------------------------------------------
local function OnRespawn()
	Util.Connect("Char", LP.CharacterAdded, function(char)
		-- cleanup fly parts
		pcall(function()
			if FlyParts.gyro then FlyParts.gyro:Destroy() end
			if FlyParts.vel then FlyParts.vel:Destroy() end
		end)
		FlyParts = {}
		Util.Disconnect("Fly")
		task.wait(0.8)
		-- pastikan humanoid baru bersih dulu
		local newHum = char:FindFirstChildOfClass("Humanoid")
			or char:WaitForChild("Humanoid", 3)
		if State.FlyOn then Movement.EnableFly() end
		if State.SpeedOn then
			-- re-apply speed di body baru dengan base bersih
			State.BaseSpeed = nil
			Util.Disconnect("SpeedKeep")
			Movement.EnableSpeed()
		else
			-- SPEED OFF: pastikan tidak ada keep + WalkSpeed normal
			State.BaseSpeed = nil
			Util.Disconnect("SpeedKeep")
			if newHum then
				newHum.WalkSpeed = 16
			end
		end
		if State.InfJumpOn then Movement.EnableInfJump() end
		if State.NoclipOn then Movement.EnableNoclip() end
		if State.SpectateOn then PlayerMod.DisableSpectate() end

		-- [MERGED] Drop All Food: kembali ke posisi sebelum karakter mati
		if State.PendingRespawnPos then
			local hrp = char:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				task.wait(0.5)
				hrp.CFrame = State.PendingRespawnPos
			end
			State.PendingRespawnPos = nil
		end
	end)
end

----------------------------------------------------------------
-- CLEANUP
----------------------------------------------------------------
function CleanupAll()
	if State._SujudCleanup then pcall(State._SujudCleanup); State._SujudCleanup = nil end
	pcall(function()
		if UI and UI.DestroyMobileHUD then UI.DestroyMobileHUD() end
		if UI and UI.Gui then
			local h = UI.Gui:FindFirstChild("MobileTabHUD")
			if h then h:Destroy() end
		end
	end)
	-- 1) matikan semua fitur dulu (masih boleh Notify, GUI masih ada)
	pcall(Movement.DisableFly)
	pcall(Movement.DisableSpeed)
	pcall(Movement.DisableNoclip)
	pcall(Movement.DisableInfJump)
	pcall(Visual.DisableFullbright)
	pcall(Visual.DisableNoFog)
	pcall(Visual.DisableUltraHD)
	pcall(Visual.DisableFreeCam)
	pcall(Monster.ClearCages)
	pcall(ESP.StopAll)
	pcall(Game.DisableSoundSpam)
	pcall(function() if Extra and Extra.Cleanup then Extra.Cleanup() end end)
	pcall(function() Teleport.StopScan() end)

	-- 2) matikan SEMUA koneksi (keybind, watermark, dll)
	Util.DisconnectAll()

	-- 3) bersihkan jejak grief di workspace
	State.GriefExplosion = false
	State.GriefParticle = false
	State.GriefDecal = false
	State.GriefChat = false
	State._particleAcc = nil
	State._decalAcc = nil
	State._chatAcc = nil
	State._expAcc = nil
	Util.Safe(function()
		for _, obj in ipairs(Util.GetWS()) do
			local p = obj:FindFirstChild("YOURSCRIPT_Grain")
			if p then p:Destroy() end
			for _, d in ipairs(obj:GetChildren()) do
				if d.Name == "YOURSCRIPT_Decals" then pcall(function() d:Destroy() end) end
			end
		end
	end)
	-- [DIPERTAHANKAN] reset flag loop task.spawn: Util.DisconnectAll TIDAK bisa
	-- menghentikan loop `while State.X` (FreezeMonster & AutoCage) yang tidak
	-- terdaftar di Util — tanpa baris ini loop nyasar tetap jalan setelah panel hancur
	State.FlyUp, State.FlyDown = false, false
	State.AutoMaterial = false
	State.AutoCrate = false
	State.AutoReturn = false
	State.AutoCage = false
	State.FreezeOn = false
	State.SpamItemOn = false -- SPAM ITEM: matikan loop TP-berkeliling saat panel hancur
	State.PendingRespawnPos = nil
	FurnitureSelected = nil

	-- 4) baru destroy GUI paling akhir
	for _, p in ipairs(PlankPool) do pcall(function() p:Destroy() end) end
	PlankPool = {}
	if UI.Gui then UI.Gui:Destroy() end
	-- [BARU] lepas bridge agar eksekusi berikutnya tahu tidak ada instansi aktif
	pcall(function() getgenv().YOURSCRIPT_Cleanup = nil end)
	print("[YOURSCRIPT] PANEL DESTROYED — ALL CLEANED")
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------
BuildUI()
BindKeys()
StartWatermark()
OnRespawn()
Teleport.RefreshTarget()
Teleport.RefreshItem(true)
Services.Players.PlayerAdded:Connect(function() Teleport.RefreshTarget() end)
Services.Players.PlayerRemoving:Connect(function() Teleport.RefreshTarget() end)

Notify("YOURSCRIPT", "Premium + dangerousnight Loaded", Config.Theme.Accent)
print("===== ScriptRobloxFull  PREMIUM PANEL (MERGED) =====")
print("Dangerous Night Utility — Premium Edition + dangerousnight.lua")
-- [REVISI] JANGAN scan langsung saat INIT — tunggu panel tampil dulu (anti-lag mobile)
task.delay(3, function()
	if UI.Gui and UI.Gui.Parent then
		Teleport.StartScan()
	end
end)
print("Keybind OFF | Full Extra+Combat+8features | Destroy via Util")

-- [BARU] daftarkan cleanup ke bridge — eksekusi baru akan memanggil ini
-- untuk membunuh instansi lama (termasuk semua koneksi & loop-nya)
pcall(function()
	getgenv().YOURSCRIPT_Cleanup = CleanupAll
end)
end

----------------------------------------------------------------
function LoadAllParts()
	if _G.SRF_DEAD then return end
	local ok, err = pcall(RunPanel)
	if not ok then
		warn("[YOURSCRIPT] PANEL ERROR:", err)
		return
	end
	_G.SRF = _G.SRF or {}
	-- [REVISI] ambil cleanup ASLI dari panel (bukan fallback kosong)
	local _bridgeFn = nil
	pcall(function()
		if getgenv then _bridgeFn = getgenv().YOURSCRIPT_Cleanup end
	end)
	if type(_bridgeFn) == "function" then
		_G.SRF.CleanupAll = _bridgeFn
	elseif type(_G.SRF.CleanupAll) ~= "function" then
		_G.SRF.CleanupAll = function() end
	end
	-- [REVISI] pemutus heartbeat: loop lama (while SessionKey) berhenti saat re-execute
	_G.SRF.StopHeartbeat = function() SessionKey = nil end
	StartHeartbeat()
	print("[YOURSCRIPT] All parts loaded.")
end

----------------------------------------------------------------
local DEVICE_ID = GetDeviceID()
local DETECTED_USER_ID = tostring(LP.UserId)
local SessionKey, SessionUser = nil, nil

function StartHeartbeat()
	_G.SRF_GEN = (_G.SRF_GEN or 0) + 1
	local myGen = _G.SRF_GEN
	task.spawn(function()
		while SessionKey and myGen == _G.SRF_GEN do
			task.wait(HEARTBEAT_INTERVAL)
			if myGen ~= _G.SRF_GEN then break end
			if not SessionKey then break end
			local res = ApiCheck(SessionKey, SessionUser, DEVICE_ID)
			if myGen ~= _G.SRF_GEN then break end
			if not IsSuccess(res) then
				warn("[YOURSCRIPT] Heartbeat FAILED:", res.error)
				_G.SRF_DEAD = true
				if _G.SRF and type(_G.SRF.CleanupAll) == "function" then pcall(_G.SRF.CleanupAll) end
				GateResult("LICENSE TERMINATED", MapError(res.error), Color3.fromRGB(230, 70, 80))
				SessionKey = nil
				break
			end
		end
	end)
end

local function StartGate()
	local savedKey = LoadKey()
	if savedKey and #savedKey > 5 then
		local res = ApiCheck(savedKey, DETECTED_USER_ID, DEVICE_ID)
		if IsSuccess(res) then
			SessionKey, SessionUser = savedKey, DETECTED_USER_ID
			LoadAllParts()
			return true
		end
		if res.error == "USER_MISMATCH" or res.error == "INVALID_KEY" then ClearKey() end
	end

	GateInputBox(DETECTED_USER_ID, function(key, uid, errLabel, resetBtn)
		local res = ApiActivate(key, uid, DEVICE_ID)
		if IsSuccess(res) then
			SaveKey(key)
			local gui = errLabel.Parent.Parent
			local gr = GateResult("LICENSE ACTIVE", "Selamat datang! Panel akan terbuka dalam 2 detik.",
				Color3.fromRGB(46, 200, 110))
			if gui then gui:Destroy() end
			SessionKey, SessionUser = key, uid
			task.wait(2)
			if gr then gr:Destroy() end
			LoadAllParts()
		else
			resetBtn(MapError(res.error or "UNKNOWN"))
		end
	end)
	return false
end

----------------------------------------------------------------
-- [REVISI] RE-EXECUTE SUPPORT:
-- 1) bunuh instansi lama (panel + heartbeat) SEKARANG, sebelum guard apa pun
-- Naikkan generasi: heartbeat lama dari eksekusi sebelumnya akan berhenti sendiri.
-- Matikan loop lama via StopHeartbeat (SessionKey=nil) + bump generasi.
_G.SRF_GEN = (_G.SRF_GEN or 0) + 1
pcall(function()
	if _G.SRF and type(_G.SRF.StopHeartbeat) == "function" then
		pcall(_G.SRF.StopHeartbeat)
	end
end)
pcall(function()
	if getgenv and getgenv().YOURSCRIPT_Cleanup then
		getgenv().YOURSCRIPT_Cleanup()
		getgenv().YOURSCRIPT_Cleanup = nil
	end
end)
pcall(function()
	if _G.SRF and type(_G.SRF.CleanupAll) == "function" then
		pcall(_G.SRF.CleanupAll)
	end
end)
_G.SRF = nil

-- 2) bersihkan GUI gate lama yang masih menempel
pcall(function()
	local hosts = {}
	pcall(function() hosts[#hosts + 1] = game:GetService("CoreGui") end)
	pcall(function() if gethui then hosts[#hosts + 1] = gethui() end end)
	pcall(function() hosts[#hosts + 1] = LP:FindFirstChild("PlayerGui") end)
	for _, host in ipairs(hosts) do
		for _, n in ipairs({ "SRF_Gate", "SRF_GateInput" }) do
			local o = host and host:FindFirstChild(n)
			if o then o:Destroy() end
		end
	end
end)

-- 3) reset flag: eksekusi baru HARUS boleh jalan
-- _G.SRF_DEAD = false penting: kalau heartbeat pernah gagal sekali di sesi lama,
-- flag itu true permanen dan LoadAllParts menolak memuat panel selamanya,
-- bahkan setelah key valid.
_G.SRF_STARTED = nil
_G.SRF_DEAD = false

StartGate()
