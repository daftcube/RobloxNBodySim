--[[

  simulation.lua	

	Simple N-Body Iterative Simulation in Roblox.
	
	You can change the speed of the simulation via
	this script's attributes.
	
	Copyright 2021 (c) Owen Bartolf
	
	Licensed under GNU General Public License v3
	https://opensource.org/licenses/GPL-3.0
		
--]]

local RunService = game:GetService("RunService")

-------------------------------------------------------------------------------------------------
-- CONFIGURATION
-------------------------------------------------------------------------------------------------

local SIMULATION_TIME_MULTIPLIER = 4
local G = 1
local NUMBER_OF_OBJECTS = 12
local PART_RADIUS = 0.2
local MIN_EXTENTS = -50
local MAX_EXTENTS = 50
local RANDOM_VELOCITY_RANGE = 0.7

-------------------------------------------------------------------------------------------------
--[[
	The ObjectWithMass object represents a single particle with a position, mass, and velocity.
	It is the foundation of the simulation.
--]]
-------------------------------------------------------------------------------------------------

local ObjectWithMass = {}
ObjectWithMass.__index = ObjectWithMass

--[[
	Standard Constructor
--]]
function ObjectWithMass.new(mass: number, position: Vector3, velocity: Vector3, part: BasePart)
	local self = setmetatable(
		{
			mass = mass,
			position = position,
			velocity = velocity,
			part = part
		},
		ObjectWithMass
	)
	
	return self
end


-------------------------------------------------------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------------------------------------------------------

--[[
	Initializes the simulation.
--]]
function InitializeObjects(numberOfObjects)
	
	local randomGenerator = Random.new(math.random(0, 100000))
	
	local randomMass = {
		2,
		5,
		7
	}
	local randomMaterialByMass = {
		Enum.Material.Plastic,
		Enum.Material.Wood,
		Enum.Material.DiamondPlate
	}
	local toReturn = table.create(numberOfObjects)
	
	for i = 1, NUMBER_OF_OBJECTS do
		
		local random = randomGenerator:NextInteger(1, 3)
		local mass = randomMass[random]
		local randomPos = Vector3.new(
			randomGenerator:NextNumber(MIN_EXTENTS, MAX_EXTENTS), 
			randomGenerator:NextNumber(MIN_EXTENTS, MAX_EXTENTS), 
			randomGenerator:NextNumber(MIN_EXTENTS, MAX_EXTENTS)
		)
		local randomVel = Vector3.new(
			randomGenerator:NextNumber(-RANDOM_VELOCITY_RANGE, RANDOM_VELOCITY_RANGE), 
			randomGenerator:NextNumber(-RANDOM_VELOCITY_RANGE, RANDOM_VELOCITY_RANGE), 
			randomGenerator:NextNumber(-RANDOM_VELOCITY_RANGE, RANDOM_VELOCITY_RANGE)
		)
		local randomColor = Color3.fromHSV((i-1)/NUMBER_OF_OBJECTS, 1, 1)
		
		-- Initialize part and trail
		local newPlanetPart = Instance.new("Part")
		newPlanetPart.Name = "Planet"
		newPlanetPart.Material = randomMaterialByMass[random]
		newPlanetPart.Size = Vector3.new(PART_RADIUS*2,PART_RADIUS*2,PART_RADIUS*2)
		newPlanetPart.Shape = Enum.PartType.Ball
		newPlanetPart.Position = randomPos
		newPlanetPart.Anchored = true
		newPlanetPart.Color = randomColor
		newPlanetPart.Parent = game.Workspace
		
		local trailAttachment0 = Instance.new("Attachment")
		trailAttachment0.Axis = newPlanetPart.CFrame.LookVector
		trailAttachment0.Position = Vector3.new(PART_RADIUS,0,0)
		local trailAttachment1 = Instance.new("Attachment")
		trailAttachment1.Axis = newPlanetPart.CFrame.LookVector
		trailAttachment1.Position = Vector3.new(-PART_RADIUS,0,0)
		
		local trail = Instance.new("Trail")
		trail.Attachment0 = trailAttachment0
		trail.Attachment1 = trailAttachment1
		trail.Color = ColorSequence.new(randomColor, randomColor)
		trail.Lifetime = math.huge
		trail.MaxLength = math.huge
		trail.FaceCamera = true
		
		trailAttachment0.Parent = newPlanetPart
		trailAttachment1.Parent = newPlanetPart
		trail.Parent = newPlanetPart
		
		-- Add to return table
		toReturn[i] = ObjectWithMass.new(mass, randomPos, randomVel, newPlanetPart)
		
	end
	
	return toReturn
	
end

--[[
	Applies gravity between the bodies. Force is equal and opposite.
--]]
function ApplyGravity(objectWithMassA, objectWithMassB, deltaTime)
	
	-- Force of Gravity
	local directionVector = objectWithMassB.position - objectWithMassA.position 
	local directionNorm = directionVector.Unit
	local dist = directionVector.Magnitude
	
	-- This kinda breaks the laws of physics, but clamp the distance to a minimum of
	-- double the radius of the particles. Any less implies the particles are phasing through one
	-- another.
	dist = math.clamp(dist, 2*PART_RADIUS, math.huge)
	
	local forceMagnitude = G * ((objectWithMassA.mass * objectWithMassB.mass) / (dist * dist))
	
	-- Calculate acceleration due to gravity
	local accelerationA = (forceMagnitude / objectWithMassA.mass) -- m/s^2
	local accelerationB = (forceMagnitude / objectWithMassB.mass)
	
	-- Apply acceleration
	objectWithMassA.velocity += directionNorm * (accelerationA * deltaTime)
	objectWithMassB.velocity -= directionNorm * (accelerationB * deltaTime)
	
end

--[[
	Initializes attributes for easy manipulation of configuration values.
--]]
function InitializeAttributes()
	if not script:GetAttribute("TimeFactor") then
		script:SetAttribute("TimeFactor", SIMULATION_TIME_MULTIPLIER)
	end
	
	script:GetAttributeChangedSignal("TimeFactor"):Connect(
		function(newValue)
		SIMULATION_TIME_MULTIPLIER = script:GetAttribute("TimeFactor")
		end
	)
end

local simulatedObjects = InitializeObjects(NUMBER_OF_OBJECTS)
InitializeAttributes()

RunService.Heartbeat:Connect(
	function(deltaTime)
		
		deltaTime *= SIMULATION_TIME_MULTIPLIER
		
		for i = 1, #simulatedObjects - 1 do
			for j = i+1, #simulatedObjects do
				-- Apply gravity if and only if 
				ApplyGravity(simulatedObjects[i], simulatedObjects[j], deltaTime)
			end
		end
		
		-- Translate planets by velocity
		for _, planet in pairs(simulatedObjects) do			
			planet.position += planet.velocity * deltaTime
			planet.part.Position = planet.position
		end
		
	end
)
