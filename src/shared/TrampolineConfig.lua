-- Общие настройки батута. Лежит в ReplicatedStorage, нужен и серверу, и клиенту.
local Config = {
	StatName = "Сила прыжка", -- имя значения в leaderstats (видно в списке игроков)
	PadTag = "TrampolinePad", -- любой Part с этим тегом становится батутом
	RemoteName = "TrampolineBounce",

	PowerPerBounce = 1, -- сколько силы даёт один прыжок на батуте

	-- Обычный прыжок персонажа: JumpPower = BaseJumpPower + сила (не выше MaxJumpPower)
	BaseJumpPower = 50,
	MaxJumpPower = 300,

	-- Подброс батутом (вертикальная скорость, studs/s): BounceBase + сила * BouncePerPower
	BounceBase = 80,
	BouncePerPower = 2,
	BounceMax = 700,
	BounceCooldown = 0.35, -- сек между засчитанными прыжками

	-- Батут, который создаётся автоматически, если в игре нет ни одного Part с тегом PadTag
	SpawnDefaultTrampoline = true,
	TrampolinePosition = Vector3.new(0, 0, -30), -- точка на земле под центром
	TrampolineRadius = 10,
	TrampolineHeight = 3,
	RimColorA = Color3.fromRGB(0, 170, 255),
	RimColorB = Color3.fromRGB(255, 200, 0),

	-- Сохранение силы между заходами (в Studio нужно включить
	-- Game Settings → Security → Enable Studio Access to API Services)
	SaveData = true,
	DataStoreName = "TrampolineJumpPower_v1",
}

function Config.getBounceSpeed(power: number): number
	return math.min(Config.BounceBase + power * Config.BouncePerPower, Config.BounceMax)
end

function Config.getJumpPower(power: number): number
	return math.min(Config.BaseJumpPower + power, Config.MaxJumpPower)
end

return Config
