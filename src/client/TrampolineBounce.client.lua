-- Клиент: подбрасывает своего персонажа сразу при касании батута
-- (физикой персонажа управляет клиент, так прыжок без задержки).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("TrampolineConfig"))
local bounceEvent = ReplicatedStorage:WaitForChild(Config.RemoteName) :: RemoteEvent

local player = Players.LocalPlayer
local stat = player:WaitForChild("leaderstats"):WaitForChild(Config.StatName) :: IntValue

local lastBounce = 0

local function makeSparks(): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 0)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(14, 26)
	emitter.SpreadAngle = Vector2.new(70, 70)
	emitter.Acceleration = Vector3.new(0, -40, 0)
	return emitter
end

local function burst(position: Vector3)
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain
	local emitter = makeSparks()
	emitter.Parent = attachment
	emitter:Emit(30)
	Debris:AddItem(attachment, 1.5)
end

local function onPadTouched(pad: BasePart, hit: BasePart)
	local character = player.Character
	if not character or not hit:IsDescendantOf(character) then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return
	end
	if root.Position.Y < pad.Position.Y then
		return -- касание сбоку/снизу
	end

	local now = os.clock()
	if now - lastBounce < Config.BounceCooldown then
		return
	end
	lastBounce = now

	local velocity = root.AssemblyLinearVelocity
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	root.AssemblyLinearVelocity = Vector3.new(velocity.X, Config.getBounceSpeed(stat.Value), velocity.Z)

	bounceEvent:FireServer(pad)
	burst(Vector3.new(root.Position.X, pad.Position.Y + 0.5, root.Position.Z))
end

local function setupPad(pad: Instance)
	if pad:IsA("BasePart") then
		pad.Touched:Connect(function(hit)
			onPadTouched(pad, hit)
		end)
	end
end

CollectionService:GetInstanceAddedSignal(Config.PadTag):Connect(setupPad)
for _, pad in CollectionService:GetTagged(Config.PadTag) do
	setupPad(pad)
end
