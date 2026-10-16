local root='vorp_stables/'
local function copy(v)if type(v)~='table'then return v end local o={}for k,x in pairs(v)do o[k]=copy(x)end return o end
Data={Horses={A_C_Horse_Test_Black=100,A_C_Horse_Test_White=120},Carts={cart01=200},Complements={Saddles={Classic={'0x10','0x11',2}}}}
Config={MaxHorses=2,MaxCarts=1,StableSlots=3,DisableBuyOption=false,JobRequired=false,LongTermHealth=100,Stables={{Name='Valentine Stable',horses={A_C_Horse_Test_Black=75},carts={cart01=180}}}}
dofile(root..'shared/catalog.lua')
dofile(root..'server/service.lua')
local rows,comps={},{};local chars={[1]={id=11,identifier='a',money=1000,gold=4,job='civilian'},[2]={id=22,identifier='b',money=1000,gold=0,job='civilian'}}
local near,writeFail,nextId=true,false,0
local a={}
function a.character(src)return chars[src]end
function a.valid(src,c)return chars[src]==c end
function a.nearStable()return near end
function a.nearPlayers()return near end
function a.players()return{1,2}end
function a.rows(id)local out={}for _,r in pairs(rows)do if r.charidentifier==id or(r.status and r.status.transferTarget==id)then out[#out+1]=copy(r)end end return out end
function a.row(id)return copy(rows[id])end
function a.complements(id)return copy(comps[id]or{})end
function a.insert(c,name,model,kind,active,paid)if writeFail then error('DB failure')end nextId=nextId+1;rows[nextId]={id=nextId,charidentifier=c.id,identifier=c.identifier,name=name,modelname=model,type=kind,isDefault=active and 1 or 0,gear={},injured=0,status={purchasePrice=paid}};return nextId end
function a.update(id,owner,fields)if writeFail then error('DB failure')end local r=rows[id];if not r or r.charidentifier~=owner then return false end for k,v in pairs(fields)do r[k]=copy(v)end return true end
function a.delete(id,owner)if writeFail then error('DB failure')end if not rows[id]or rows[id].charidentifier~=owner then return false end rows[id]=nil;return true end
function a.setDefault(id,owner,kind)if writeFail then error('DB failure')end for _,r in pairs(rows)do if r.charidentifier==owner and r.type==kind then r.isDefault=r.id==id and 1 or 0 end end return true end
function a.equipment(id,owner,gear,owned)if writeFail then error('DB failure')end rows[id].gear=copy(gear);comps[owner]=copy(owned);return true end
function a.transfer(id,owner,target)if writeFail then error('DB failure')end rows[id].charidentifier=target.id;rows[id].identifier=target.identifier;rows[id].status=nil;rows[id].isDefault=0;return true end
function a.debit(c,n)c.money=c.money-n end
function a.credit(c,n)c.money=c.money+n end
function a.sell(c,row,amount)if writeFail then return false end;if not a.delete(row.id,c.id)then return false end;a.credit(c,amount);return true end
local s=StableService.new(a)
local function request(src,action,fields)local r=fields or{};r.action=action;r.stable=1;return s.handle(src,r)end
local r=request(1,'open');assert(r.ok and r.data.cash==1000)
assert(request(1,'buy',{model='A_C_Horse_Test_White',kind='horse',name='White'}).ok==false,'Vendor whitelist enforced')
r=request(1,'buy',{model='A_C_Horse_Test_Black',kind='horse',name='Dakota',price=-999});assert(r.ok and chars[1].money==925 and rows[1].isDefault==1,'Server vendor price and first active')
assert(not request(2,'rename',{id=1,name='Stolen'}).ok,'Foreign owner rejected')
assert(not request(1,'buy',{model='bad',kind='horse',name='Ghost'}).ok)
assert(not request(1,'buy',{model='A_C_Horse_Test_Black',kind='invalid',name='Ghost'}).ok)
assert(not request(1,'rename',{id=1,name='x'}).ok)
assert(request(1,'rename',{id=1,name='Marlow'}).ok and rows[1].name=='Marlow')
assert(request(1,'buy',{model='A_C_Horse_Test_Black',kind='horse',name='Second'}).ok)
assert(not request(1,'buy',{model='A_C_Horse_Test_Black',kind='horse',name='Third'}).ok,'Horse cap enforced')
assert(request(1,'buy',{model='cart01',kind='cart',name='Wagon'}).ok and chars[1].money==670)
assert(not request(1,'buy',{model='cart01',kind='cart',name='More'}).ok,'Cart/total cap enforced')
assert(request(1,'dismiss',{id=3}).ok,'Owner may request dismissal')
assert(not request(2,'dismiss',{id=3}).ok,'Foreign player cannot dismiss a wagon')
assert(request(1,'lead',{id=3}).ok,'Owner may lead the draft team')
assert(not request(2,'lead',{id=3}).ok,'Foreign player cannot lead the draft team')
assert(not request(1,'dismiss',{id=1}).ok,'Horse is not a wagon')
assert(request(1,'active',{id=2}).ok and rows[1].isDefault==0 and rows[2].isDefault==1)
local before=chars[1].money
assert(request(1,'equip',{id=2,family='Saddles',hash=16,price=0}).ok and chars[1].money==before-20 and rows[2].gear.Saddles==16)
assert(request(1,'equip',{id=2,family='Saddles',hash=16}).ok and chars[1].money==before-20,'Owned gear free')
assert(not request(1,'equip',{id=2,family='Saddles',hash=999}).ok,'Unknown gear rejected')
assert(not request(2,'equip',{id=2,family='Saddles',hash=17}).ok)
assert(request(1,'removeGear',{id=2}).ok and next(rows[2].gear)==nil)
near=false;assert(not request(1,'buy',{model='cart01',kind='cart',name='Remote'}).ok);assert(not request(1,'release',{id=1,confirm=true}).ok);near=true
assert(not request(1,'release',{id=1}).ok,'Explicit destructive confirmation')
assert(request(1,'offer',{id=1,target=2,price=50}).ok)
assert(not request(1,'accept',{id=1}).ok,'Seller cannot accept own offer')
assert(request(2,'open').data.offers[1].id==1)
assert(request(2,'accept',{id=1}).ok and rows[1].charidentifier==22 and chars[2].money==950 and chars[1].money==before+30,'Transfer agreed price used and both balances changed')
assert(not request(2,'accept',{id=1}).ok,'Offer cannot be accepted twice')
assert(request(2,'offer',{id=1,target=1,price=0}).ok)
assert(request(1,'reject',{id=1}).ok and rows[1].status==false)
assert(request(2,'offer',{id=1,target=1,price=0}).ok)
Config.StableSlots=2
assert(not request(1,'accept',{id=1}).ok,'Recipient total slots enforced')
Config.StableSlots=3
assert(request(2,'cancelOffer',{id=1}).ok)
writeFail=true;before=chars[2].money
r=request(2,'buy',{model='cart01',kind='cart',name='Failure'});assert(not r.ok and chars[2].money==before,'Database failure refunds debit')
writeFail=false
assert(request(1,'spawn',{kind='horse'}).spawn.id==2)
assert(not request(2,'spawn',{kind='horse'}).ok,'Transferred horse requires selecting active')
assert(request(2,'active',{id=1}).ok and request(2,'spawn',{kind='horse'}).spawn.id==1)
local oldRows=a.rows;a.rows=function(id)chars[2]=nil;return oldRows(id)end
assert(not request(2,'buy',{model='cart01',kind='cart',name='Disconnected'}).ok,'Disconnect during read prevents debit')
a.rows=oldRows;chars[2]={id=22,identifier='b',money=500,gold=0}
local oldInsert=a.insert;a.insert=function(...)coroutine.yield();return oldInsert(...)end
local co=coroutine.create(function()return request(2,'buy',{model='cart01',kind='cart',name='Serialized'})end);assert(coroutine.resume(co));assert(not request(2,'buy',{model='cart01',kind='cart',name='Duplicate'}).ok,'Concurrent mutation locked');assert(coroutine.resume(co));a.insert=oldInsert
assert(request(1,'release',{id=2,confirm=true}).ok and not rows[2])
local saleBefore=chars[1].money
assert(not request(1,'release',{id=3,confirm=true}).ok,'Wagons must use a paid sale, not release')
assert(not request(2,'sell',{id=3,confirm=true}).ok,'Other owner cannot sell wagon')
assert(not request(1,'sell',{id=3}).ok,'Sale needs confirmation')
writeFail=true;assert(not request(1,'sell',{id=3,confirm=true}).ok and rows[3] and chars[1].money==saleBefore,'Failed sale keeps ownership and balance')
writeFail=false
assert(request(1,'sell',{id=3,confirm=true,price=999999}).ok and chars[1].money==saleBefore+108 and not rows[3],'Sale pays server-computed 60 percent of the recorded purchase price')
assert(not request(1,'sell',{id=3,confirm=true}).ok and chars[1].money==saleBefore+108,'Duplicate sale cannot pay twice')
print('PASS: VORP service pricing, limits, ownership, gear, defaults, consent transfers, refunds, stale sessions and concurrent mutations')
