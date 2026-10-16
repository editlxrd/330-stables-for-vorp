local root='vorp_stables/'
local requested,released,messages={},{},{};local loaded={};local clock=100
Config={Preload={Enabled=true,AllModels=true,Distance=12,ReleaseDistance=24,BatchSize=2,MaxConcurrent=3,TimeoutMs=6000},Thumbnails={x='images/example.webp'},Stables={{Name='Test',EnterStable={0,0,0,2}}}}
Data={Horses={A_C_Horse_Test_Black=10,A_C_Horse_Test_White=20},Carts={cart01=50}}
function GetHashKey(model)return model end
function IsModelValid()return true end
function RequestModel(hash)requested[#requested+1]=hash end
function HasModelLoaded(hash)return loaded[hash]or false end
function GetGameTimer()return clock end
function SetModelAsNoLongerNeeded(hash)released[#released+1]=hash end
function SendNUIMessage(value)messages[#messages+1]=value end
dofile(root..'shared/catalog.lua')
dofile(root..'client/preload.lua')
StablePreload.update({x=50,y=0,z=0},false);assert(#requested==0)
StablePreload.update({x=10,y=0,z=0},false);assert(#requested==2,'First batch is paced')
assert(StablePreload.status().total==3,'All vendor horses and wagons queued')
assert(messages[1].action=='preload' and messages[1].images[1]=='images/example.webp')
StablePreload.update({x=5,y=0,z=0},true);assert(#requested==3,'Loading continues inside menu')
for _,hash in ipairs(requested)do loaded[hash]=true end
StablePreload.update({x=5,y=0,z=0},true);assert(StablePreload.status().loaded==3)
StablePreload.update({x=15,y=0,z=0},false);assert(#released==0,'Hysteresis avoids repeated stream-in/stream-out')
StablePreload.release('cart01');assert(#released==0,'Preview cannot release a catalogue-pinned model')
StablePreload.include({{modelname='A_C_Horse_Owned_Rare'}});StablePreload.update({x=5,y=0,z=0},true)
assert(#requested==4,'Owned models outside the vendor list are also warmed')
StablePreload.update({x=40,y=0,z=0},false);assert(#released==4,'Leaving releases every pinned model')
StablePreload.update({x=2,y=0,z=0},false);StablePreload.clear();assert(#released==6)
Config.Preload.Enabled=false;StablePreload.update({x=2,y=0,z=0},false);assert(#requested==6)
Config.Preload.Enabled=true;Config.Preload.AllModels=false
StablePreload.update({x=2,y=0,z=0},false);assert(StablePreload.status().total==1,'Lightweight mode remains configurable')
StablePreload.clear();Config.Preload.AllModels=true
StablePreload.update({x=2,y=0,z=0},false);loaded={};clock=7000;StablePreload.update({x=2,y=0,z=0},true)
assert(StablePreload.status().failed>0,'Failed loads time out without blocking the queue')
StablePreload.clear()
loaded={};clock=100
StablePreload.prepare(1);local before=#requested;StablePreload.requestAll()
assert(#requested-before==3,'Entry requests every remaining model together')
assert(StablePreload.status().pending==3)
for _,hash in ipairs(requested)do loaded[hash]=true end
StablePreload.poll();assert(StablePreload.status().pending==0,'Entry gate can observe all models ready')
StablePreload.clear()
print('PASS: all-catalogue paced preload, owned variants, pinning, menu continuation, hysteresis, release, lightweight mode and timeout')
