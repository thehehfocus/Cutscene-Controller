-- Builder for cutscene class.
-- Usage by creating cutscene modules under "cutscenes" folder.

local CutsceneMaker = {}

local Signal = require(game.ReplicatedStorage.Packages.Signal)

local CutsceneClass = {}
CutsceneClass.__index = CutsceneClass
type Cutscene = typeof(CutsceneMaker.New())

local TimestampClass = {}
TimestampClass.__index = TimestampClass
type Timestamp = typeof(setmetatable({} :: {Cutscene: Cutscene, Execution: () -> ()}, TimestampClass))

CutsceneMaker.CutsceneClass = CutsceneClass
CutsceneClass.TimestampClass = TimestampClass

function CutsceneMaker.New()
	return setmetatable({
		Timeline = {},
		Started = Signal(),
		Ended = Signal(),
		TimestampEvent = Signal()
	}, CutsceneClass)
end

local function TurnToCFrame(Object: CFrame|() -> CFrame|Instance) : CFrame
	if typeof(Object) == "Instance" then
		return Object.CFrame
	elseif typeof(Object) == "function" then
		return Object()
	elseif typeof(Object) == "CFrame" then
		return Object
	end
end

-- Creates a blank timestamp.
function CutsceneClass._createNewTimestamp(self:Cutscene, Index) : Timestamp
	local NewTimestamp = setmetatable({Cutscene = self}, TimestampClass)
	if Index and Index ~= "None" then
		table.insert(self.Timeline, Index, NewTimestamp)
	elseif Index ~= "None" then
		table.insert(self.Timeline, NewTimestamp)
	end
	
	return NewTimestamp
end

function CutsceneClass.CreateCameraTimestamp(self:Cutscene, Cframe:CFrame|() -> CFrame|Instance, TweenProperties:TweenInfo, Duration:number|"Wait", Index:(number|"None")?)
	local NewTimestamp = self:_createNewTimestamp(Index)
	NewTimestamp.CameraCframe = Cframe
	NewTimestamp.TweenProperties = TweenProperties
	NewTimestamp.Execution = NewTimestamp.CameraMovementExecute
	NewTimestamp.Duration = Duration or 0
	
	if Duration == "Wait" then
		NewTimestamp.Duration = 0
		NewTimestamp.Wait = true
	end
	
	return self, NewTimestamp
end

function CutsceneClass.CreateCameraTrackerTimestamp(self:Cutscene, TrackFrom:CFrame|() -> CFrame|Instance, TrackWhat:() -> CFrame|Instance, Duration:number, Intervals:number, Index:(number|"None")?)
	local NewTimestamp = self:_createNewTimestamp(Index)
	NewTimestamp.TrackFrom = TrackFrom
	NewTimestamp.TrackWhat = TrackWhat
	NewTimestamp.Execution = NewTimestamp.CameraTrackerExecute
	NewTimestamp.TrackDuration = Duration
	NewTimestamp.Intervals = Intervals or 0.1
	
	return self, NewTimestamp
end

function CutsceneClass.CreateFunctionTimestamp(self:Cutscene, Function: (any) -> any, Duration:number, Index:(number|"None")?)
	local NewTimestamp = self:_createNewTimestamp(Index)
	NewTimestamp.Function = Function
	NewTimestamp.Execution = NewTimestamp.FunctionExecute
	NewTimestamp.Duration = Duration or 0

	return self, NewTimestamp
end

function CutsceneClass.CreateSignalWaitTimestamp(self:Cutscene, WaitSignal:RBXScriptSignal, Index:(number|"None")?)
	local NewTimestamp = self:_createNewTimestamp(Index)
	NewTimestamp.WaitSignal = WaitSignal
	NewTimestamp.Execution = NewTimestamp.WaitSignalExecute
	
	return self, NewTimestamp
end

function CutsceneClass.Run(self:Cutscene, StartParameters)
	self.Running = true
	
	self.Started:Fire(StartParameters)
	
	for i,Tstp in ipairs(self.Timeline) do
		if not self.Running then
			return
		end
		self.Current = Tstp
		
		if Tstp.Event then
			self.TimestampEvent:Fire(Tstp.Event, Tstp)
		end
		Tstp:Execution(StartParameters)
		
		if Tstp.Duration then
			task.wait(Tstp.Duration)
		end
	end
	self.Ended:Fire(StartParameters)
	
	self.Current = nil
	self.Running = false
end

function TimestampClass.FunctionExecute(self:Timestamp & {Function: () -> ()})
	if self.Function then
		return self.Function()
	end
end

function TimestampClass.WaitSignalExecute(self:Timestamp & {WaitSignal:RBXScriptSignal})
	return self.WaitSignal:Wait()
end

function TimestampClass.CameraMovementExecute(self:Timestamp & {TweenProperties:TweenInfo, CameraCframe:CFrame|() -> CFrame|Instance})
	local Camera = workspace.CurrentCamera
	
	local GoalCF = TurnToCFrame(self.CameraCframe)
	
	local Tween = game:GetService("TweenService"):Create(Camera, self.TweenProperties or TweenInfo.new(1), {CFrame = GoalCF})
	Tween:Play()

	if self.Wait then
		Tween.Completed:Wait()
	end
	
	return true
end

function TimestampClass.CameraTrackerExecute(self:Timestamp & {TrackFrom:CFrame|() -> CFrame|Instance, TrackWhat:(() -> CFrame)|Instance, TrackDuration:number, Intervals:number})
	local Camera = workspace.CurrentCamera
	
	local Start = tick()
	local End = Start + self.TrackDuration
	
	local Intervals = self.Intervals or 0.1
	
	repeat
		local To = TurnToCFrame(self.TrackWhat)
		local From = TurnToCFrame(self.TrackFrom)
		
		print(To.Position, From.Position, tick() - End)
		
		local GoalCFrame = CFrame.lookAt(From.Position, To.Position)
		
		if Intervals >= 0.1 then
			self.CameraMovementExecute({CameraCframe = GoalCFrame, TweenProperties = TweenInfo.new(Intervals * 2)})
		else
			Camera.CFrame = GoalCFrame
		end
		
		task.wait(Intervals)
	until tick() >= End or not self.Cutscene.Running
end

function TimestampClass.SetEvent(self:Timestamp, EventName:string)
	self.Event = EventName
	
	return self.Cutscene, self
end

return CutsceneMaker
