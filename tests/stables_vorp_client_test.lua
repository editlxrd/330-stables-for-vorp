StableInteractions={stop=function()end}
StableLocale={code='en',messages={},text=function(key)return key end,stableName=function(name)return name end}
StableSpawn={find=function()return{x=-370,y=790,z=115},20 end}
function NetworkHasControlOfEntity()return true end
function GetEntitySpeed()return 0 end
function NetworkGetNetworkIdFromEntity(id)return id end
local root='vorp_stables/'
local threads,events,callbacks,commands,timers={}, {}, {}, {}, {}
local messages,requests,created,deleted={}, {}, {}, {}
local whistles={}
local bookCalls,clearedTasks=0,0
function TaskWhistleAnim(ped,style,voice)whistles[#whistles+1]={ped=ped,style=style,voice=voice}end
function SetWhistleConfigForPed()error("Stable must preserve VORP character whistle settings")end
local coords={x=-365.87,y=789.51,z=116.17};local focus,frozen=false,false
local nextEntity=10
function CreateThread(fn)threads[#threads+1]=coroutine.create(fn)end
function SetTimeout(_,fn)timers[#timers+1]=fn end
function Wait()coroutine.yield()end
function RegisterNetEvent(name,fn)events[name]=fn end
function AddEventHandler(name,fn)events[name]=fn end
function RegisterCommand(name,fn)commands[name]=fn end
function RegisterNUICallback(name,fn)callbacks[name]=fn end
function GetCurrentResourceName()return'vorp_stables'end
function GetRandomIntInRange()return 123 end
function PlayerPedId()return 1 end
function PlayerId()return 1 end
function GetEntityCoords(id)return id==1 and coords or {x=-366,y=781,z=115}end
function DoesEntityExist(id)return not deleted[id]end
function IsEntityDead()return false end
function IsNuiFocused()return focus end
function SetNuiFocus(v)focus=v end
function FreezeEntityPosition(id,v)if id==1 then frozen=v end end
function SendNUIMessage(v)messages[#messages+1]=v end
function TriggerServerEvent(name,id,request)assert(name=='330_stables:request');requests[#requests+1]={id=id,request=request}end
function TriggerEvent()end
function GetHashKey(v)return v end
function IsModelValid()return true end
function RequestModel()end
function GetGameTimer()return 100 end
function HasModelLoaded()return true end
function SetModelAsNoLongerNeeded()end
function RequestCollisionAtCoord()end
function CreatePed(model,...)nextEntity=nextEntity+1;created[nextEntity]={model=model,kind='horse',args={...}};return nextEntity end
function CreateVehicle(model,...)nextEntity=nextEntity+1;created[nextEntity]={model=model,kind='cart',args={...}};return nextEntity end
function DeleteEntity(id)deleted[id]=true end
function SetEntityVisible()end
function SetEntityAsMissionEntity()end
function SetEntityInvincible()end
function SetBlockingOfNonTemporaryEvents()end
function CreateCam()return 90 end
function SetCamCoord()end
function PointCamAtCoord()end
local cameraFov
function SetCamFov(_,fov)cameraFov=fov end
function RenderScriptCams()end
function DestroyCam()end
function SetEntityHeading()end
function GetEntityHeading()return 20 end
function RemoveBlip()end
Citizen={ResultAsInteger=function()return nil end,InvokeNative=function(hash)if hash==0x524B54361229154F then bookCalls=bookCalls+1 end;if hash==0xA8BA0BAE0173457B then return 0 end;return 50 end}
function IsPedOnMount()return false end
function GetMount()return 0 end
function IsPedAPlayer()return false end
function GetRiderOfMount()return 0 end
function ClearPedTasks()clearedTasks=clearedTasks+1 end
function ClearPedTasksImmediately()clearedTasks=clearedTasks+1 end
function GetGamePool()return{}end
function IsEntityAttachedToEntity()return false end
local registered={}
exports=setmetatable({lab_inventory={RegisterProviderEntity=function(_,provider,kind,id,entity)registered[#registered+1]={provider,kind,id,entity}end}},{__call=function()end})
function GetResourceState()return'started'end
function TaskGoToEntity()end
function GetOffsetFromEntityInWorldCoords()return{x=-370,y=790,z=116}end
function GetGroundZFor_3dCoord()return true,115 end
function vector3(x,y,z)return{x=x,y=y,z=z}end
json={encode=function()return'{}'end}
LocalPlayer={state={IsInSession=true}}
dofile(root..'shared/keys.lua');dofile(root..'shared/data.lua');dofile(root..'config.lua');dofile(root..'locations.lua');dofile(root..'shared/catalog.lua');dofile(root..'client/preload.lua');dofile(root..'client/reading.lua');dofile(root..'client/main.lua')
local function respond(result,defer)
 local req=requests[#requests];events['330_stables:response'](req.id,result)
 if req.request.action=='open' and result.ok and not defer then
  for i=#messages,1,-1 do if messages[i].action=='loading'then callbacks.assetsReady({ticket=messages[i].ticket},function()end);break end end
  local gate=threads[#threads];if coroutine.status(gate)=='suspended'then assert(coroutine.resume(gate))end
 end
end
HasModelLoaded=function()return false end
commands.stables();assert(requests[#requests].request.action=='open')
assert(messages[#messages].action=='loading','Entry shows loading instead of menu')
local owned={id=7,name='Dakota',modelname='A_C_Horse_AmericanStandardbred_Black',type='horse',gear={},isDefault=1}
local data={rides={owned},offers={},horses={},wagons={},equipment={},cash=500}
respond({ok=true,data=data},true)
local entryGate=threads[#threads];assert(coroutine.resume(entryGate))
assert(messages[#messages].action=='loadingProgress','Menu stays hidden while models stream')
for i=#messages,1,-1 do if messages[i].action=='loading'then callbacks.assetsReady({ticket=messages[i].ticket},function()end);break end end
assert(coroutine.resume(entryGate));assert(messages[#messages].action~='open','UI assets alone do not bypass the model gate')
HasModelLoaded=function()return true end
assert(coroutine.resume(entryGate));assert(messages[#messages].action=='open' and focus and frozen,'Menu opens only after models and UI are ready')
callbacks.select({id=7},function(v)assert(v.ok)end)
local previewThread=threads[#threads];assert(coroutine.resume(previewThread));local stale=nextEntity
callbacks.close({},function()end);assert(not focus and not frozen)
assert(coroutine.resume(previewThread));assert(deleted[stale],'Closing during model initialization deletes stale preview')
commands.stables();respond({ok=true,data=data});callbacks.select({id=7},function()end)
local co=threads[#threads];assert(coroutine.resume(co));assert(coroutine.resume(co));local entity=nextEntity;assert(not deleted[entity])
assert(created[entity].args[1]==Config.Stables[1].SpawnCart[1] and cameraFov==Config.PreviewCamera.HorseFov,'Horse preview uses wagon location and wider configured camera')
local saddle=StableCatalog.equipmentGroups()[1].items[1].coats[1]
local beforeEquipment=nextEntity
callbacks.select({id=7,family='Saddles',hash=saddle.hash},function()end)
assert(nextEntity==beforeEquipment and not deleted[entity],'Tack changes reuse the current preview horse')
assert(#threads>0 and coroutine.status(threads[#threads])=='dead','Tack selection does not start a replacement spawn')

callbacks.select({model='A_C_Horse_AmericanStandardbred_Buckskin',kind='horse'},function()end)
local co2=threads[#threads];assert(coroutine.resume(co2));callbacks.select({model='A_C_Horse_AmericanStandardbred_Black',kind='horse'},function()end)
assert(coroutine.resume(co2));assert(deleted[nextEntity],'New selection invalidates previous creation')
assert(bookCalls>0,'Opened menu starts its configured reading scenario')
callbacks.close({},function()end)
assert(clearedTasks>0,'Closing the menu stops its reading task')
commands.callhorse();assert(requests[#requests].request.action=='spawn');respond({ok=true,spawn=owned})
assert(#whistles==1 and whistles[1].ped==1 and whistles[1].style=='WHISTLEHORSELONG','Successful horse call uses the current character native whistle')
local spawn=threads[#threads];assert(coroutine.resume(spawn));assert(coroutine.status(spawn)=='dead')
assert(registered[1][1]=='vorp_stables' and registered[1][3]==7,'Inventory binds stable row ID')
Config.WhistleOnCall=false
commands.callhorse();respond({ok=true,spawn=owned});assert(#whistles==1,'Whistle can be disabled without changing horse calling')
Config.WhistleOnCall=true
commands.callhorse();respond({ok=false,error='No active horse'});assert(#whistles==1,'Rejected calls do not whistle')
commands.callwagon();respond({ok=false,error='No active wagon'});assert(#whistles==1,'Wagons do not whistle')
local calledHorse=registered[1][4]
commands.fleehorse();local delayedFlee=timers[#timers]
commands.callhorse();respond({ok=true,spawn=owned});delayedFlee()
assert(not deleted[calledHorse],'Recalling a fleeing horse cancels delayed despawn')
commands.fleehorse();timers[#timers]()
assert(deleted[calledHorse],'Flee removes only the owned spawned horse after its delay')
commands.callhorse();local delayed=requests[#requests].id
events['vorp:SelectedCharacter']()
local before=#threads
events['330_stables:response'](delayed,{ok=true,spawn=owned})
assert(#threads==before,'Delayed old character spawn response is ignored')
commands.callhorse();respond({ok=true,spawn=owned})
local oldLoad=threads[#threads]
HasModelLoaded=function()return false end
assert(coroutine.resume(oldLoad))
events['vorp:SelectedCharacter']()
commands.callhorse();local newRequest=requests[#requests].id
assert(coroutine.resume(oldLoad))
HasModelLoaded=function()return true end
events['330_stables:response'](newRequest,{ok=true,spawn=owned})
local newLoad=threads[#threads];assert(newLoad~=oldLoad,'Old loading cleanup cannot cancel a new call')
assert(coroutine.resume(newLoad))
commands.stables();respond({ok=true,data=data})
local staleResult
callbacks.request({action='call',id=7,kind='horse'},function(result)staleResult=result end)
local oldActive=requests[#requests].id
events['vorp:SelectedCharacter']()
commands.stables();respond({ok=true,data=data});assert(focus and frozen)
events['330_stables:response'](oldActive,{ok=true,data=data})
assert(staleResult and not staleResult.ok and focus and frozen,'Delayed old call cannot close new character menu')
events['onResourceStop']('vorp_stables');assert(deleted[nextEntity] and not focus and not frozen)
commands.stables();local cancelled=requests[#requests].id
callbacks.close({},function()end)
events['330_stables:response'](cancelled,{ok=true,data=data})
assert(not focus and not frozen,'Cancelling loading prevents delayed data from opening the menu')
local seats={}
function GetPedInVehicleSeat(_,seat)return seats[seat]or 0 end
commands.stables();respond({ok=true,data=data})
callbacks.select({model='cart01',kind='cart'},function()end)
local wagonPreview=threads[#threads];assert(coroutine.resume(wagonPreview));assert(coroutine.resume(wagonPreview))
assert(created[nextEntity].kind=='cart' and created[nextEntity].args[7]==false,'Preview wagon enables native draft horses')
local oldTimer,oldHeading,oldSetHeading=GetGameTimer,GetEntityHeading,SetEntityHeading
local clock,heading=100,0
GetGameTimer=function()return clock end;GetEntityHeading=function()return heading end;SetEntityHeading=function(_,value)heading=value end
callbacks.rotate({delta=20},function()end);local rotateThread=threads[#threads]
assert(coroutine.resume(rotateThread));clock=220;assert(coroutine.resume(rotateThread));assert(heading>0 and heading<20,'Rotation interpolates instead of snapping')
clock=340;assert(coroutine.resume(rotateThread));assert(heading==20)
GetGameTimer,GetEntityHeading,SetEntityHeading=oldTimer,oldHeading,oldSetHeading
callbacks.close({},function()end)
commands.callwagon();respond({ok=true,spawn={id=8,name='Cart',modelname='cart01',type='cart',gear={},isDefault=1}})
local wagonLoad=threads[#threads];assert(coroutine.resume(wagonLoad));local calledWagon=nextEntity
local countRequests=#requests;commands.callwagon();assert(#requests==countRequests,'Already called wagon bypasses spawn cooldown requests')
commands.callhorse();respond({ok=true,spawn=owned})
local ownHorseLoad=threads[#threads];assert(coroutine.resume(ownHorseLoad));local focusedHorse=nextEntity
local promptId,promptKeys,promptVisible=0,{},{}
function UiPromptRegisterBegin()promptId=promptId+1;return promptId end
function UiPromptSetControlAction(id,key)promptKeys[id]=key end
function UiPromptSetText()end
function UiPromptSetEnabled()end
function UiPromptSetVisible(id,visible)promptVisible[id]=visible end
function UiPromptSetStandardMode()end
function UiPromptSetGroup()end
function UiPromptRegisterEnd()end
function UiPromptSetActiveGroupThisFrame()end
function UiPromptHasStandardModeCompleted()return false end
function VarString(_,_,text)return text end
local blockedControls={}
function DisableControlAction(_,key,blocked)blockedControls[key]=blocked end
function IsControlJustPressed()return false end
function IsDisabledControlJustPressed()return false end
local focusTarget=900
function GetPlayerTargetEntity()return true, focusTarget end
local originalNative=Citizen.InvokeNative
Citizen.InvokeNative=function(hash,entity,index,...)
 if hash==0xA8BA0BAE0173457B then return index==0 and 900 or 0 end
 return originalNative(hash,entity,index,...)
end
local originalInteractions=StableInteractions
StableInteractions={stop=function()end,isLeading=function()return false end,wagonTarget=function(wagon,target,animals)return target==wagon.entity or target==animals[1]end}
assert(coroutine.resume(threads[1]));assert(coroutine.resume(threads[1]))
local visibleDismiss=false
for id,key in pairs(promptKeys)do if key==Keys.F and promptVisible[id]then visibleDismiss=true end end
assert(visibleDismiss,'Dismiss remains visible at the frame boundary when targeting an owned draft horse')
assert(not blockedControls[Keys.F],'Dismiss input must stay enabled or RedM hides its prompt')
focusTarget=focusedHorse
assert(coroutine.resume(threads[1]))
local visibleLead=false
for id,key in pairs(promptKeys)do if key==Keys.E and promptVisible[id]then visibleLead=true end end
assert(visibleLead and not blockedControls[Keys.E],'Normal horse Lead stays visible with draft leading disabled')
focusTarget=900
Config.EnableDraftLeading=true
assert(coroutine.resume(threads[1]))
assert(not blockedControls[Keys.E],'Lead input must stay enabled or RedM hides its prompt')
local beforeStalePrompt=#requests
function UiPromptHasStandardModeCompleted(id)return promptKeys[id]==Keys.F or promptKeys[id]==Keys.E end
assert(coroutine.resume(threads[1]));assert(coroutine.resume(threads[1]))
assert(#requests==beforeStalePrompt,'Stale prompt completion without a fresh key press cannot dismiss or toggle leading')
function UiPromptHasStandardModeCompleted()return false end
local starts,stops=0,0
StableInteractions.lead=function()starts=starts+1 end
StableInteractions.stop=function()stops=stops+1 end
local pressedE=true
function IsDisabledControlJustPressed(_,key)return pressedE and key==Keys.E end
assert(coroutine.resume(threads[1]));pressedE=false
local pendingLead=#requests
assert(requests[pendingLead].request.action=='lead','Lead requests server permission')
pressedE=true;assert(coroutine.resume(threads[1]));pressedE=false
assert(#requests==pendingLead,'Second press cancels the pending lead without another request')
respond({ok=true})
assert(starts==0,'Cancelled permission response cannot start leading later')
pressedE=true;assert(coroutine.resume(threads[1]));pressedE=false
respond({ok=true})
assert(starts==1,'A fresh request can start after cancellation')
assert(coroutine.resume(threads[1]));assert(starts==1,'Holding/releasing focus cannot retrigger leading')
pressedE=true;assert(coroutine.resume(threads[1]));pressedE=false
callbacks.close({},function()end);respond({ok=true})
assert(starts==1,'Closing the menu invalidates an outstanding lead request')
Config.EnableDraftLeading=false
local beforeDisabled=#requests
pressedE=true;assert(coroutine.resume(threads[1]));pressedE=false
assert(#requests==beforeDisabled,'Default configuration does not offer unsupported draft leading')
function IsDisabledControlJustPressed()return false end
StableInteractions=originalInteractions
Citizen.InvokeNative=originalNative

seats[0]=1;commands.dismisswagon();assert(not deleted[calledWagon],'Occupied wagon cannot be stored')
seats={};commands.dismisswagon();respond({ok=false,error='Not your wagon'});assert(not deleted[calledWagon],'Server refusal cannot delete a wagon')
commands.dismisswagon();seats[0]=1;respond({ok=true});assert(not deleted[calledWagon],'Occupancy is rechecked after server authorization')
seats={};commands.dismisswagon();respond({ok=true});assert(deleted[calledWagon],'Store wagon despawns the called entity')
local originalStatus, originalFailed = StablePreload.status, StablePreload.isFailed
StablePreload.status=function()return{total=2,loaded=1,failed=1,pending=0}end
StablePreload.isFailed=function(model)return model=='Missing_Horse'end
commands.stables()
respond({ok=true,data={rides={},offers={},horses={{name='Mixed',coats={{model='Missing_Horse'},{model='Valid_Horse'}}}},wagons={},equipment={}}})
assert(messages[#messages].action=='open','One unavailable model must not block the stable')
assert(#messages[#messages].data.horses[1].coats==1 and messages[#messages].data.horses[1].coats[1].model=='Valid_Horse','Unavailable models are omitted from the vendor catalogue')
callbacks.close({},function()end)
StablePreload.status,StablePreload.isFailed=originalStatus,originalFailed
print('PASS: VORP client server-approved open, selection cancellation, close cleanup, owned spawn and per-ride inventory binding')
