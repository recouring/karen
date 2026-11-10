-- Сервер: строит батут, хранит/сохраняет силу прыжка и засчитывает прыжки.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("TrampolineConfig"))

local bounceEvent = Instance.new("RemoteEvent")
bounceEvent.Name = Config.RemoteName
bounceEvent.Parent = ReplicatedStorage

-------------------------------------------------------------------------------
-- Модель батута
-------------------------------------------------------------------------------
local VERTICAL = CFrame.Angles(0, 0, math.rad(90)) -- ось цилиндра (X) смотрит вверх

local function newPart(parent: Instance, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = parent
	return part
end

local function buildTrampoline(origin: Vector3)
	local radius = Config.TrampolineRadius
	local height = Config.TrampolineHeight
	local rimRadius = radius + 1.6
	local top = origin + Vector3.new(0, height, 0)

	local model = Instance.new("Model")
	model.Name = "Trampoline"

	local pad = newPart(model, {
		Name = "Pad",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, radius * 2, radius * 2),
		CFrame = CFrame.new(top) * VERTICAL,
		Material = Enum.Material.Fabric,
		Color = Color3.fromRGB(30, 32, 48),
	})
	CollectionService:AddTag(pad, Config.PadTag)

	-- Светящаяся «мишень» в центре; без коллизии, чтобы игрок касался именно Pad
	for i, ring in { { 6, Color3.fromRGB(0, 200, 255) }, { 3, Color3.fromRGB(255, 70, 160) } } do
		newPart(model, {
			Name = "Target",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, ring[1], ring[1]),
			CFrame = CFrame.new(top + Vector3.new(0, 0.02 * i, 0)) * VERTICAL,
			Material = Enum.Material.Neon,
			Color = ring[2],
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		})
	end

	-- Мягкий бортик из сегментов двух цветов
	local segments = 28
	local segLength = 2 * math.pi * rimRadius / segments + 0.2
	for i = 1, segments do
		local angle = i / segments * math.pi * 2
		local pos = top + Vector3.new(math.cos(angle) * rimRadius, 0.15, math.sin(angle) * rimRadius)
		local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
		newPart(model, {
			Name = "Rim",
			Size = Vector3.new(1.4, 0.9, segLength),
			CFrame = CFrame.lookAt(pos, pos + tangent),
			Material = Enum.Material.SmoothPlastic,
			Color = if i % 2 == 0 then Config.RimColorA else Config.RimColorB,
		})
	end

	-- Пружины между сеткой и бортиком
	local springs = 24
	for i = 1, springs do
		local angle = (i + 0.5) / springs * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		local pos = top + dir * (radius + 0.45)
		newPart(model, {
			Name = "Spring",
			Size = Vector3.new(0.25, 0.25, 1.3),
			CFrame = CFrame.lookAt(pos, pos + dir),
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(200, 205, 215),
			CanCollide = false,
		})
	end

	-- Ножки
	local legs = 6
	for i = 1, legs do
		local angle = i / legs * math.pi * 2
		local pos = origin + Vector3.new(math.cos(angle) * rimRadius, height / 2, math.sin(angle) * rimRadius)
		newPart(model, {
			Name = "Leg",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, 0.7, 0.7),
			CFrame = CFrame.new(pos) * VERTICAL,
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(60, 63, 75),
		})
	end

	model.PrimaryPart = pad
	model.Parent = workspace
end

if Config.SpawnDefaultTrampoline and #CollectionService:GetTagged(Config.PadTag) == 0 then
	buildTrampoline(Config.TrampolinePosition)
end

-------------------------------------------------------------------------------
-- Сила прыжка и сохранение
-------------------------------------------------------------------------------
local store: DataStore? = nil
if Config.SaveData then
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, Config.DataStoreName)
	if ok then
		store = result
	else
		warn("[Trampoline] DataStore недоступен, прогресс не сохраняется:", result)
	end
end

local stats: { [Player]: IntValue } = {}
local canSave: { [Player]: boolean } = {}
local lastBounce: { [Player]: number } = {}

local function applyJumpPower(player: Player)
	local stat = stats[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if stat and humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = Config.getJumpPower(stat.Value)
	end
end

local function save(player: Player)
	local stat = stats[player]
	if not (store and stat and canSave[player]) then
		return
	end
	local ok, err = pcall(store.SetAsync, store, tostring(player.UserId), stat.Value)
	if not ok then
		warn("[Trampoline] Не удалось сохранить", player.Name, err)
	end
end

local function onPlayerAdded(player: Player)
	local value = 0
	local loaded = true
	if store then
		local ok, result = pcall(store.GetAsync, store, tostring(player.UserId))
		if ok then
			value = tonumber(result) or 0
		else
			-- Не сохраняем поверх, чтобы не затереть настоящий прогресс нулём
			loaded = false
			warn("[Trampoline] Не удалось загрузить", player.Name, result)
		end
	end
	if not player.Parent then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local stat = Instance.new("IntValue")
	stat.Name = Config.StatName
	stat.Value = value
	stat.Parent = leaderstats

	stats[player] = stat
	canSave[player] = loaded
	-- Родитель ставится после загрузки, чтобы HUD сразу видел итоговое значение
	leaderstats.Parent = player

	stat.Changed:Connect(function()
		applyJumpPower(player)
	end)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		applyJumpPower(player)
	end)
	applyJumpPower(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	stats[player] = nil
	canSave[player] = nil
	lastBounce[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		save(player)
	end
end)

-------------------------------------------------------------------------------
-- Засчитывание прыжка (подбрасывает клиент, сервер проверяет и начисляет)
-------------------------------------------------------------------------------
local function isNearPad(root: BasePart, pad: BasePart): boolean
	local offset = root.Position - pad.Position
	local size = pad.Size
	local horizontalLimit = math.max(size.X, size.Y, size.Z) / 2 + 6
	-- Запас по высоте учитывает задержку репликации при быстром падении
	return Vector2.new(offset.X, offset.Z).Magnitude <= horizontalLimit and offset.Y > -6 and offset.Y < 60
end

bounceEvent.OnServerEvent:Connect(function(player: Player, pad: any)
	local stat = stats[player]
	if not stat or typeof(pad) ~= "Instance" or not pad:IsA("BasePart") then
		return
	end
	if not CollectionService:HasTag(pad, Config.PadTag) then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) or humanoid.Health <= 0 then
		return
	end
	if not isNearPad(root, pad) then
		return
	end

	local now = os.clock()
	if now - (lastBounce[player] or 0) < Config.BounceCooldown then
		return
	end
	lastBounce[player] = now

	stat.Value += Config.PowerPerBounce
end)
