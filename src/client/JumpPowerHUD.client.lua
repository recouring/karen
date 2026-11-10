-- Клиент: HUD с силой прыжка (анимированный счётчик, всплывающее «+1»).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("TrampolineConfig"))

local player = Players.LocalPlayer
local stat = player:WaitForChild("leaderstats"):WaitForChild(Config.StatName) :: IntValue

local TEXT_FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy) -- есть кириллица
local NUMBER_FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

local function create(className: string, props: { [string]: any }, children: { Instance }?): any
	local inst = Instance.new(className)
	for key, value in props do
		(inst :: any)[key] = value
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	return inst
end

local function gradient(colors: { Color3 }, rotation: number): UIGradient
	local keypoints = {}
	for i, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), color))
	end
	return create("UIGradient", { Color = ColorSequence.new(keypoints), Rotation = rotation })
end

local function formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (formatted:gsub("^ ", ""))
end

-------------------------------------------------------------------------------
-- Вёрстка
-------------------------------------------------------------------------------
local strokeGradient = gradient({
	Color3.fromRGB(0, 220, 255),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(255, 80, 180),
	Color3.fromRGB(0, 220, 255),
}, 0)

local cardScale = create("UIScale", { Scale = 1 })

local icon = create("TextLabel", {
	Name = "Icon",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 14, 0.5, 0),
	Size = UDim2.fromOffset(58, 58),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Text = "🦘",
	TextSize = 32,
	FontFace = NUMBER_FONT,
}, {
	create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	gradient({ Color3.fromRGB(255, 190, 40), Color3.fromRGB(255, 100, 60) }, 90),
	create("UIStroke", { Color = Color3.fromRGB(255, 230, 150), Thickness = 2, Transparency = 0.3 }),
})

local title = create("TextLabel", {
	Name = "Title",
	Position = UDim2.fromOffset(86, 14),
	Size = UDim2.new(1, -100, 0, 16),
	BackgroundTransparency = 1,
	Text = "СИЛА ПРЫЖКА",
	TextColor3 = Color3.fromRGB(175, 185, 255),
	TextSize = 13,
	FontFace = TEXT_FONT,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local valueLabel = create("TextLabel", {
	Name = "Value",
	Position = UDim2.fromOffset(86, 30),
	Size = UDim2.new(1, -100, 0, 42),
	BackgroundTransparency = 1,
	Text = formatNumber(stat.Value),
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 40,
	FontFace = NUMBER_FONT,
	TextXAlignment = Enum.TextXAlignment.Left,
}, {
	gradient({ Color3.fromRGB(255, 245, 160), Color3.fromRGB(255, 170, 40) }, 90),
	create("UIStroke", { Color = Color3.fromRGB(70, 30, 0), Thickness = 1.5, Transparency = 0.2 }),
})

local card = create("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 14),
	Size = UDim2.fromOffset(270, 86),
	BackgroundColor3 = Color3.fromRGB(22, 24, 40),
	BackgroundTransparency = 0.12,
}, {
	create("UICorner", { CornerRadius = UDim.new(0, 20) }),
	create("UIStroke", {
		Thickness = 3,
		Color = Color3.new(1, 1, 1),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, { strokeGradient }),
	gradient({ Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 200) }, 90),
	cardScale,
	icon,
	title,
	valueLabel,
})

create("ScreenGui", {
	Name = "JumpPowerHUD",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
}, { card })

-------------------------------------------------------------------------------
-- Анимации
-------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	strokeGradient.Rotation = (strokeGradient.Rotation + dt * 90) % 360
end)

local displayed = Instance.new("NumberValue")
displayed.Value = stat.Value
displayed.Changed:Connect(function(v)
	valueLabel.Text = formatNumber(v)
end)

local function popup(delta: number, milestone: boolean)
	local label = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.6, 0),
		Size = UDim2.fromOffset(90, 30),
		BackgroundTransparency = 1,
		Text = "+" .. formatNumber(delta),
		TextColor3 = if milestone then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(110, 255, 140),
		TextSize = if milestone then 34 else 26,
		FontFace = NUMBER_FONT,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 5,
		Parent = card,
	}, {
		create("UIStroke", { Color = Color3.fromRGB(0, 40, 10), Thickness = 1.5 }),
	})
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(label, info, {
		Position = UDim2.new(1, -14, 0.6, -46),
		TextTransparency = 1,
	})
	TweenService:Create(label:FindFirstChildOfClass("UIStroke"), info, { Transparency = 1 }):Play()
	tween.Completed:Once(function()
		label:Destroy()
	end)
	tween:Play()
end

local iconRest = icon.Position
local previous = stat.Value

stat.Changed:Connect(function(value)
	local delta = value - previous
	local milestone = math.floor(value / 10) > math.floor(previous / 10)
	previous = value

	TweenService:Create(displayed, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { Value = value }):Play()
	if delta <= 0 then
		return
	end

	popup(delta, milestone)

	cardScale.Scale = if milestone then 1.18 else 1.1
	TweenService:Create(cardScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()

	icon.Position = iconRest
	TweenService:Create(
		icon,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{ Position = iconRest - UDim2.fromOffset(0, 8) }
	):Play()
end)
