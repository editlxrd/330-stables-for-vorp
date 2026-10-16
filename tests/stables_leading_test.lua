local clock,timers,led,player=0,{},0,1
local exists,dead,riders,control={},{},{},{}
local mounted,vehicle=false,false
local calls,stops,requests=0,0,0
local results={}
function PlayerPedId()return player end
function DoesEntityExist(id)return id~=0 and exists[id]~=false end
function IsEntityDead(id)return dead[id] or false end
function IsPedOnMount()return mounted end
function IsPedInAnyVehicle()return vehicle end
function GetEntityCoords(id)return{x=id==player and 0 or 2,y=0,z=0}end
function NetworkHasControlOfEntity(id)return control[id]~=false end
function NetworkRequestControlOfEntity(id)requests=requests+1 end
function GetRiderOfMount(id)return riders[id]or 0 end
function TaskLeadHorse()calls=calls+1 end
function TaskStopLeadingHorse()stops=stops+1;led=0 end
function GetGameTimer()return clock end
function SetTimeout(ms,fn)timers[#timers+1]={at=clock+ms,fn=fn}end
Citizen={ResultAsInteger=function()return nil end,InvokeNative=function(hash)
 if hash==0xEFC4303DDC6E60D3 then return led~=0 end
 if hash==0xED1F514AF4732258 then return led end
 error('Unexpected native')
end}
local function advance(ms)
 local goal=clock+ms
 while true do
  local which,at
  for i,timer in ipairs(timers)do if timer.at<=goal and(not at or timer.at<at)then which,at=i,timer.at end end
  if not which then break end
  local timer=table.remove(timers,which);clock=timer.at;timer.fn()
 end
 clock=goal
end
local function reset()
 clock,timers,led,player=0,{},0,1
 exists,dead,riders,control={},{},{},{}
 mounted,vehicle=false,false
 calls,stops,requests=0,0,0;results={}
 dofile('vorp_stables/client/interactions.lua')
end
local function start(entity,animal)
 StableInteractions.lead(entity or 10,animal or 20,function(ok,message)results[#results+1]={ok=ok,message=message}end)
end
local function active()
 start();led=20;advance(200)
 assert(results[1]and results[1].ok,'Native confirmation starts leading')
end
reset();active();led=0
assert(not StableInteractions.isLeading(10),'Stop leading label must clear after the game ends the rope task')
reset();active();led=30
assert(not StableInteractions.isLeading(10),'Leading another animal must not leave the previous ride active')
reset();active();StableInteractions.stop();assert(not StableInteractions.isLeading(10),'Explicit stop clears the label immediately')
advance(5000);assert(#results==1,'Old timers cannot resurrect a stopped session')
reset();start();StableInteractions.stop();advance(5000)
assert(#results==0 and calls==1,'Cancellation while approaching has no late success/error callback')
reset();start();advance(1800);assert(#results==0,'Approaching has time to finish')
led=20;advance(200);assert(results[1].ok,'Delayed start succeeds')
reset();start();advance(4200);assert(#results==1 and not results[1].ok,'Rejected native task fails once')
assert(not StableInteractions.isLeading(10),'Rejected task clears pending state')
reset();active();dead[20]=true;advance(200)
assert(not StableInteractions.isLeading(10),'Dead horse clears leading')
reset();active();exists[10]=false;advance(200)
assert(not StableInteractions.isLeading(10),'Missing wagon clears its leading session')
reset();active();player=2;advance(200)
assert(not StableInteractions.isLeading(10),'Changing character/ped clears the old session')
reset();active();mounted=true;advance(200)
assert(not StableInteractions.isLeading(10),'Mounting interrupts leading')
reset();active();riders[20]=9;advance(200)
assert(not StableInteractions.isLeading(10),'Another rider interrupts leading')
reset();active();led=30;StableInteractions.isLeading(10);local count=stops
StableInteractions.stop();assert(stops==count,'Cleanup cannot stop an unrelated native lead task')
reset();active();StableInteractions.stop(99)
assert(StableInteractions.isLeading(10),'Cleanup for another ride preserves leading')
reset();active();StableInteractions.stop();StableInteractions.stop()
assert(stops==1,'Stopping is idempotent')
reset();riders[20]=9;start();assert(calls==0 and not results[1].ok,'Occupied horse is rejected')
reset();mounted=true;start();assert(calls==0 and not results[1].ok,'Mounted player is rejected')
reset();vehicle=true;start();assert(calls==0 and not results[1].ok,'Player in a wagon is rejected')
reset();control[20]=false;start();advance(200);control[20]=true;advance(200)
assert(calls==1 and requests>0,'Draft horse control can be acquired before starting')
reset();control[20]=false;start();advance(2000)
assert(calls==0 and #results==1 and not results[1].ok,'Control request is bounded')
reset();start();start();assert(calls==1,'Repeated request does not restart the same approaching task')
reset();start();StableInteractions.stop();start();led=20;advance(200)
assert(#results==1 and results[1].ok,'Only the replacement session may complete')
reset();active()
local invoke=Citizen.InvokeNative
Citizen.InvokeNative=function(hash,...)
 if hash==0xEFC4303DDC6E60D3 then return 0 end
 return invoke(hash,...)
end
assert(not StableInteractions.isLeading(10),'Numeric native false cannot keep leading active in Lua')
Citizen.InvokeNative=invoke
reset();control[20]=false;start();StableInteractions.stop();control[20]=true;advance(2000)
assert(calls==0 and #results==0,'Cancelled network acquisition cannot start a task later')
reset()
assert(StableInteractions.wagonTarget({entity=10},20,{20,21}),'Draft target belongs to wagon')
assert(not StableInteractions.wagonTarget({entity=10},22,{20,21}),'Unrelated horse is not a wagon target')
print('PASS 25 leading scenarios: actual rope state, cancellation, restart, identity, guards, draft control and bounded failures')
