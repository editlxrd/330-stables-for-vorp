local root='vorp_stables/'
local callbacks,events,threads={},{},{}
local attached={[20]=true,[21]=false};local deleted={};local stopped=0
function GetGamePool()return{20,21}end
function IsEntityAttachedToEntity(id,ped)return attached[id]and ped==1 end
function DoesEntityExist(id)return not deleted[id]end
function ClearPedTasksImmediately()stopped=stopped+1 end
function GetEntityModel()return 999 end
function GetHashKey(v)return v end
function SetEntityAsMissionEntity()end
function DetachEntity(id)attached[id]=false end
function DeleteEntity(id)deleted[id]=true end
function GetEntityHeading()return 0 end
function PlayerPedId()return 1 end
Citizen={InvokeNative=function()attached[21]=true end}
dofile(root..'client/reading.lua')
StableReading.start(1,{Enabled=true,Scenario='BOOK'})
StableReading.stop()
assert(deleted[21] and not deleted[20],'Delete newly attached reading prop, preserve existing player props')
assert(stopped==1,'Stop scenario immediately before returning control')
StableReading.stop();assert(stopped==1,'Repeated cleanup is idempotent')
StableReading.start(1,{Enabled=false,Scenario='BOOK'});StableReading.stop();assert(stopped==1)
GetEntityModel=function()return 1210783447 end
StableReading.start(1,{Enabled=true,Scenario='BOOK'});StableReading.stop();assert(deleted[20],'Previously stranded scenario book is removed too')
print('PASS reading cleanup: own book removed, unrelated attachment preserved, repeated close safe')
