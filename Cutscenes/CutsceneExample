-- This script would make player's camera follow an assigned npc.

local CutsceneMaker = require(script.Parent.Parent.CutsceneMaker)
local Cutscene = CutsceneMaker.New()

local Player = game.Players.LocalPlayer
local Character:Model = Player.Character
local Humanoid:Humanoid = Character:WaitForChild("Humanoid")

local CurrentNPC : Model & {Head:BasePart, Humanoid:Humanoid}
Cutscene.Started:Connect(function(StartParameters: {["1"]:Model})
	if not StartParameters then
		return
	end
	
	Character = Player.Character
	Humanoid = Character:WaitForChild("Humanoid")
	
	local Head = StartParameters[1].Head
	local Humanoid = StartParameters[1].Humanoid
	
	CurrentNPC = StartParameters[1]
end)

local function GetNpcCFrame(PartName)
	if not CurrentNPC then
		return CFrame.new(0,0,0)
	end
	
	if not PartName then
		return CurrentNPC:GetPivot()
	elseif CurrentNPC[PartName] and CurrentNPC[PartName].CFrame then
		return CurrentNPC[PartName].CFrame
	end
end

local function GetPlayerHeadCFrame()
	return Player.Character.Head.CFrame
end

local function GetLookAt()
	return CFrame.lookAt(GetPlayerHeadCFrame().Position, GetNpcCFrame("Head").Position)
end

local _,TweenTo = Cutscene:CreateCameraTimestamp(GetLookAt, TweenInfo.new(0.2), 0, "None")

Cutscene:CreateFunctionTimestamp(function()
	local Start = tick()
	
	local Affected = {}
	for i,v in pairs(Character:GetDescendants()) do
		if v:IsA("BasePart") or v:IsA("Part") or v:IsA("MeshPart") then
			if v.Transparency == 0 then
				Affected[v] = v
				v.Transparency = 1
			end
		end
	end
	
	local Animation:Animation = Instance.new("Animation", script) or script:FindFirstChild("NpcWave")
	Animation.Name = "NpcWave"
	Animation.AnimationId = "rbxassetid://125067531746435"
	
	print(CurrentNPC)
	if CurrentNPC then
		CurrentNPC.Humanoid.Animator:LoadAnimation(Animation):Play()
	end
	
	repeat
		TweenTo.Execution(TweenTo)
		task.wait(0.1)
	until tick() - Start >= 10
	
	for i,v:Part in pairs(Affected) do
		if v:IsA("BasePart") or v:IsA("Part") or v:IsA("MeshPart") then
			v.Transparency = 0
		end
	end
end,0)

return Cutscene
