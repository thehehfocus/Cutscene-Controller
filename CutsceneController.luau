local Controller = {}
type Controller = typeof(Controller)

local Signal = require("./SignalDependency")

Controller._ctsFolder = script.Cutscenes
Controller._ctsCache = {}
Controller._ctsRunning = {}
Controller.CameraControlState = false

Controller.CutsceneStarted = Signal()
Controller.CutsceneEnded = Signal()

function Controller.ToggleCTSCameraControl(self:Controller, Value:boolean, ForceCameraType:Enum.CameraType)
	local Player = game.Players.LocalPlayer
	local Camera = workspace.CurrentCamera

	Controller.CameraControlState = Value
	
	if Value == true then
		Camera.CameraType = ForceCameraType or Enum.CameraType.Scriptable
	elseif Value == false then
		Camera.CameraType = ForceCameraType or Enum.CameraType.Custom
	end
end

function Controller.RunCutscene(self:Controller, CutsceneName:string, Force:boolean?, ...)
	local Cutscene = self._ctsCache[CutsceneName] or self._ctsFolder:FindFirstChild(CutsceneName)
	if not Cutscene then
		warn("Cutscene ".. CutsceneName, "not found.")
		
		return
	end
	
	if not self._ctsCache[CutsceneName] then
		Cutscene = require(Cutscene)
		self._ctsCache[CutsceneName] = Cutscene
	end
	
	if next(self._ctsRunning) ~= nil and not Force then
		warn(`Detected other cutscenes running.. {self._ctsRunning} ..while attempting to run "{CutsceneName}" without force.`)
		
		return
	end
	
	local Args = {...}
	
	task.spawn(function()
		self:ToggleCTSCameraControl(true)
		
		self._ctsRunning[CutsceneName] = true
		self.CutsceneStarted:Fire(CutsceneName, "Started")
		
		local Success, Error = pcall(function()
			Cutscene:Run(Args)
		end)
		
		if not Success then
			warn(Error)
			
			return
		end	
		
		if Cutscene.OnCompletion then
			Cutscene.OnCompletion()
		end
		
		self._ctsRunning[CutsceneName] = nil
		self.CutsceneEnded:Fire(CutsceneName, "Ended")
		
		self:ToggleCTSCameraControl(false)
	end)
end

function Controller.ForceStopCutscene(self:Controller, CutsceneName)
	if not self._ctsRunning[CutsceneName] then
		warn("Cutscene", CutsceneName, "is not running.")
		
		return
	end
	
	self._ctsRunning[CutsceneName] = nil
	
	local Cutscene = self._ctsCache[CutsceneName]
	if Cutscene.Stop then
		Cutscene:Stop()
	end
	if Cutscene.OnStopped then
		Cutscene.OnStopped()
	end
	
	self:ToggleCTSCameraControl(false)
	self.CutsceneEnded:Fire(CutsceneName, "ForceStopped")
end

return Controller
