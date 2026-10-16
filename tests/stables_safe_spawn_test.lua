local blocked, ground, loaded = false, true, true
function PlayerPedId() return 1 end
function GetEntityCoords() return {x=0,y=0,z=10} end
function GetEntityHeading() return 0 end
function GetOffsetFromEntityInWorldCoords(_,x,y) return {x=x,y=y,z=10} end
function GetClosestVehicleNodeWithHeading(x,y,z) return true,{x=x,y=y,z=z},0 end
function GetModelDimensions() return {x=-1,y=-2,z=0},{x=1,y=2,z=3} end
function RequestCollisionAtCoord() end
function HasCollisionLoadedAroundPosition() return loaded end
function GetGroundZFor_3dCoord() return ground,10 end
function StartShapeTestBox(...) return 1 end
function GetShapeTestResult() return 2,blocked end
function Wait() end
dofile('vorp_stables/client/spawn.lua')
assert(StableSpawn.find('cart',1,function()return true end))
local horse=StableSpawn.find('horse',1,function()return true end);assert(horse and horse.x^2+horse.y^2 >= 35^2,'New horses must spawn at least 35m away')
blocked=true;assert(not StableSpawn.find('cart',1,function()return true end),'Blocked wagon must not spawn')
blocked=false;ground=false;assert(not StableSpawn.find('horse',1,function()return true end),'Missing ground must fail closed')
ground=true;loaded=false;assert(not StableSpawn.find('cart',1,function()return true end),'Unloaded collision must fail closed')
loaded=true;assert(not StableSpawn.find('cart',1,function()return false end),'Cancelled calls must not spawn')
print('PASS: safe spawn rejects obstruction, missing ground, collision streaming and cancelled calls')
