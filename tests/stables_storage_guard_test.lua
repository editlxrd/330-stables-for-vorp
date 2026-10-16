local state='lab';local slots={};local weapons={};local broken=false
function GetResourceState(name)return (state=='lab'and name=='lab_inventory')or(state=='vorp'and name=='vorp_inventory')and'started'or'stopped'end
-- Use explicit strings; avoid boolean coercion in the fixture.
function GetResourceState(name)if state=='lab'and name=='lab_inventory'or state=='vorp'and name=='vorp_inventory'then return'started'end;return'stopped'end
exports={lab_inventory={ReadContainer=function()if broken then error('Unavailable')end;return{slots=slots}end},vorp_inventory={getCustomInventoryItems=function()return slots end,getCustomInventoryWeapons=function()return weapons end}}
dofile('vorp_stables/server/storage.lua')
local row={id=1,type='cart',modelname='cart01',charidentifier=11}
Config={CustomMaxWeight={},DefaultMaxWeight=125,StackInvIgnore={}}
assert(StableStorage.empty(row))
slots={['1']={id='water',count=1}};assert(not StableStorage.empty(row),'Loaded wagon cannot be sold')
slots={};broken=true;assert(not StableStorage.empty(row),'Unavailable storage must fail closed')
broken=false;state='vorp'
local registered={}
exports.vorp_inventory.isCustomInventoryRegistered=function(_,id)return registered[id]==true end
exports.vorp_inventory.registerInventory=function(_,data)registered[data.id]=true end
exports.vorp_inventory.getCustomInventoryItems=function(_,id)if not registered[id]then return false end;return slots end
exports.vorp_inventory.getCustomInventoryWeapons=function(_,id)if not registered[id]then return false end;return weapons end
weapons={}
assert(StableStorage.empty(row),'Unregistered empty native/legacy bags must be registered before they can be checked')
assert(registered.stable_1 and registered.cart01_11,'Both new and old bag IDs must be checked')
weapons={{id=4}};assert(not StableStorage.empty(row),'Weapon storage also blocks removal')
weapons={};assert(StableStorage.empty(row))
state='none';assert(not StableStorage.empty(row),'Stopped provider cannot authorize permanent removal')
print('PASS storage removal guard: items, weapons, unavailable and stopped providers')
