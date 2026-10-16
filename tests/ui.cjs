const fs=require('fs'),http=require('http'),path=require('path'),assert=require('assert');
const {chromium}=require('playwright');
const root=path.resolve('vorp_stables/web/dist');
const data={location:'Valentine Stable',cash:1000,gold:4,limits:{total:4},ownedGear:[16,99,99,100],offers:[],rides:[{id:1,name:'Dakota',modelname:'A_C_Horse_Test_Black',type:'horse',isDefault:1,gear:{},status:{}},{id:2,name:'Marlow',modelname:'A_C_Horse_Test_Black',type:'horse',isDefault:0,gear:{},status:{}}],horses:[{name:'American Standardbred',kind:'horse',coats:Array.from({length:9},(_,i)=>({name:'Coat '+i,model:'A_C_Horse_Test_'+i,price:150,goldPrice:3}))}],wagons:[{name:'Hunting wagon',kind:'cart',coats:[{name:'Natural wood',model:'huntercart01',price:450}]}],equipment:[{name:'Saddles',items:[{name:'Lumley Ranch Cutter',family:'Saddles',kind:'equipment',coats:[{name:'Dark leather',hash:16,price:85,goldPrice:1},{name:'Natural leather',hash:17,price:85,goldPrice:1}]}]},{name:'Manes',items:[{name:'Short',family:'Manes',kind:'equipment',coats:[{name:'First',hash:99,price:20},{name:'Second',hash:100,price:20}]}]}]};
const server=http.createServer((req,res)=>{const f=path.resolve(root,'.'+new URL(req.url,'http://localhost').pathname.replace(/^\/$/,'/index.html'));if(!f.startsWith(root+path.sep))return res.writeHead(403).end();if(!fs.existsSync(f))return res.writeHead(404).end();res.setHeader('Content-Type',f.endsWith('.js')?'text/javascript':f.endsWith('.css')?'text/css':f.endsWith('.html')?'text/html':'application/octet-stream');res.end(fs.readFileSync(f));});
(async()=>{await new Promise(r=>server.listen(0,'127.0.0.1',r));const b=await chromium.launch({...(process.env.PLAYWRIGHT_CHANNEL?{channel:process.env.PLAYWRIGHT_CHANNEL}:{}),headless:true});try{
 const p=await b.newPage({viewport:{width:1920,height:1080}}),errors=[],requests=[];
 p.on('pageerror',e=>errors.push(e.message));
 await p.route('https://vorp_stables/**',async route=>{const req=route.request(),body=req.postDataJSON(),endpoint=new URL(req.url()).pathname;requests.push({endpoint,body});let result={ok:true};
  if(endpoint==='/request'){
   await new Promise(r=>setTimeout(r,100));
   if(body.action==='buy'){if(body.currency==='gold')data.gold-=3;else data.cash-=150;data.rides.push({id:3,name:body.name,modelname:body.model,type:body.kind,isDefault:0,gear:{},status:{}});}
   if(body.action==='rename')data.rides.find(r=>r.id===body.id).name=body.name;
   if(body.action==='equip'){data.rides.find(r=>r.id===body.id).gear[body.family]=body.hash;if(!data.ownedGear.includes(body.hash))data.ownedGear.push(body.hash);}
   result={ok:true,data:structuredClone(data),message:'Saved'};
  }
  await route.fulfill({json:result,headers:{'Access-Control-Allow-Origin':'*'}});
 });
 await p.goto(`http://127.0.0.1:${server.address().port}/`);
 async function open(){await p.evaluate(d=>window.postMessage({action:'open',data:d},'*'),data);await p.waitForTimeout(350);}
 await p.evaluate(()=>window.postMessage({action:'loading',ticket:123,location:'Valentine Stable',loaded:0,total:20},'*'));
 await p.waitForTimeout(200);assert(await p.locator('#loading-screen').isVisible());assert(await p.locator('#stables').evaluate(e=>e.hidden));
 await p.waitForFunction(()=>true);assert(requests.some(r=>r.endpoint==='/assetsReady'&&r.body.ticket===123),'Loading acknowledges prepared images and fonts');
 await p.evaluate(()=>window.postMessage({action:'loadingProgress',loaded:10,total:20},'*'));
 await p.waitForTimeout(100);const partial=await p.locator('#loading-fill').evaluate(e=>new DOMMatrixReadOnly(getComputedStyle(e).transform).m11);assert(partial>0&&partial<.5,'Loading fill interpolates between actual progress updates');
 await p.waitForTimeout(500);assert.equal(await p.locator('#loading-progress').getAttribute('aria-valuenow'),'50');
 await p.keyboard.press('Escape');assert(!await p.locator('#loading-screen').isVisible(),'Loading can be cancelled');
 await open();await p.evaluate(()=>document.body.style.background='#625c50');
 const anchor=()=>p.locator('#details,#item-name,.coat-navigation,#primary-button').evaluateAll(es=>es.map(e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,font:getComputedStyle(e).fontSize}}));
 await p.waitForTimeout(200);const horseAnchor=await anchor();
 assert(await p.locator('.coat-card img').count()>0,'Horse cards use installed image assets');
 await p.waitForFunction(()=>[...document.querySelectorAll('.coat-card img')].every(img=>img.complete&&img.naturalWidth>0));
 const longData=structuredClone(data);longData.horses[0].name='American Standardbred with a particularly long descriptive catalogue name';
 await p.evaluate(d=>window.postMessage({action:'open',data:d},'*'),longData);await p.waitForTimeout(500);
 assert.deepEqual(await anchor(),horseAnchor,'Long names stay inside the same fixed title slot');
 await open();await p.waitForTimeout(200);
 const beforeName=await p.locator('#item-name').boundingBox();
 await p.locator('#next-coat').click();
 for(let frame=0;frame<8;frame++){
  await p.waitForTimeout(20);
  assert.deepEqual(await p.locator('#item-name').boundingBox(),beforeName,'Title stays anchored throughout variant changes');
 }
 assert.equal(await p.locator('#details').evaluate(e=>e.getAnimations().filter(a=>a.playState==='running').length),0,'Unchanged title and price do not replay their animation');
 await p.getByRole('button',{name:'MY STABLE',exact:true}).click();
 const sectionName=await p.locator('#item-name').boundingBox();
 for(let frame=0;frame<8;frame++){
  await p.waitForTimeout(20);assert.deepEqual(await p.locator('#item-name').boundingBox(),sectionName,'Title stays anchored during section fade');
 }
 await open();
 await p.locator('.coat-card').nth(7).click({force:true});await p.waitForTimeout(500);
 assert(await p.locator('#details').evaluate(e=>e.getAnimations().every(a=>a.effect.getKeyframes().every(k=>!String(k.transform||'').includes('scale')))),'Detail text never scales');assert.equal(await p.locator('#counter').textContent(),'8 / 9');assert.equal(await p.locator('.coat-card[aria-pressed=true]').evaluate(e=>getComputedStyle(e).backgroundColor),'rgb(146, 47, 41)');assert(await p.locator('#coat-list').evaluate(e=>new DOMMatrixReadOnly(getComputedStyle(e).transform).m41<0));
 await p.getByRole('button',{name:'MY STABLE',exact:true}).click();
 await p.locator('#filter-trigger').click();assert(await p.locator('#filter-options').isVisible());await p.waitForTimeout(200);await p.screenshot({path:'.test-results/UI-picker-preview.png'});
 await p.getByRole('option',{name:'Your wagons',exact:true}).click();assert.equal(await p.locator('#filter').inputValue(),'1');
 await p.locator('#filter-trigger').click();await p.keyboard.press('Escape');assert(!await p.locator('#filter-options').isVisible());assert(await p.locator('#stables').isVisible(),'Picker Escape does not close stable');
 await p.locator('#filter-trigger').click();await p.getByRole('option',{name:'Your horses',exact:true}).click();
 await p.locator('.coat-card').nth(1).click();assert.equal(await p.locator('#item-name').textContent(),'Marlow');
 await p.getByRole('button',{name:'Rename',exact:true}).click();await p.getByLabel('Name',{exact:true}).fill('Dusty');await p.locator('#dialog-submit').click();await p.waitForTimeout(250);assert.equal(await p.locator('#item-name').textContent(),'Dusty');
 await p.getByRole('button',{name:'Equipment',exact:true}).click();await p.waitForTimeout(100);assert.equal(await p.locator('#owned-gear-toggle').textContent(),'My collection (1)','Count includes only owned hashes in the current category');await p.locator('#owned-gear-toggle').click();assert.equal(await p.locator('.coat-card').count(),1,'My collection lists only purchased variants');await p.locator('#owned-gear-toggle').click();assert.equal(await p.locator('#horse-filter').inputValue(),'2');assert.equal(await p.locator('#primary-label').textContent(),'EQUIP');
 await p.locator('#details').evaluate(e=>Promise.all(e.getAnimations().map(a=>a.finished.catch(()=>{}))));assert.deepEqual(await anchor(),horseAnchor,'Switching sections preserves component geometry and font sizes');
 await p.locator('#filter').selectOption('1',{force:true});assert.equal(await p.locator('#owned-gear-toggle').textContent(),'My collection (2)','Category changes recalculate the owned count without duplicate hashes');await p.locator('#filter').selectOption('0',{force:true});assert.equal(await p.locator('#owned-gear-toggle').textContent(),'My collection (1)');
 await p.locator('.coat-card').nth(1).click();await p.getByRole('button',{name:'BUY & EQUIP',exact:false}).click();await p.waitForTimeout(250);assert(requests.some(r=>r.body.action==='equip'&&r.body.id===2&&r.body.hash===17));
 await p.getByRole('button',{name:'WAGONS',exact:true}).click();await p.keyboard.press('Escape');await p.waitForTimeout(250);assert(await p.locator('#stables').evaluate(e=>e.hidden),'Escape works with focused tab button');
 await open();await p.getByRole('button',{name:'BUY HORSE',exact:false}).click();await p.getByLabel('Name',{exact:true}).fill('New Horse');await p.keyboard.press('Enter');await p.waitForTimeout(250);assert.equal(await p.locator('#cash').textContent(),'850');
 for(const viewport of[{width:1280,height:720},{width:2560,height:1440}]){await p.setViewportSize(viewport);assert(await p.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));const boxes=await p.locator('.catalog,.tabs,.controls').evaluateAll(es=>es.map(e=>{const b=e.getBoundingClientRect();return{x:b.x,y:b.y,right:b.right,bottom:b.bottom}}));assert(boxes.every(b=>b.y>=0&&b.bottom<=viewport.height&&b.right<=viewport.width));}
 await p.setViewportSize({width:1920,height:1080});await p.getByRole('button',{name:'MY STABLE',exact:true}).click();await p.waitForTimeout(400);await p.screenshot({path:'.test-results/UI-connected-preview.png'});
 await p.getByRole('button',{name:'Release',exact:true}).click();assert(await p.locator('#action-dialog').evaluate(e=>e.open));await p.keyboard.press('Escape');assert(!await p.locator('#action-dialog').evaluate(e=>e.open));assert(!requests.some(r=>r.body.action==='release'),'Cancelled release sends no mutation');
 const wagons=structuredClone(data);wagons.rides.push({id:40,name:'Road companion',modelname:'cart01',type:'cart',gear:{},status:{},sellPrice:90});
 await p.evaluate(d=>window.postMessage({action:'open',data:d},'*'),wagons);await p.waitForTimeout(350);
 await p.getByRole('button',{name:'MY STABLE',exact:true}).click();await p.locator('#filter-trigger').click();await p.getByRole('option',{name:'Your wagons',exact:true}).click();
 assert(!(await p.locator('[data-action=release]').isVisible()),'Wagons cannot be released without payment');
 await p.locator('[data-action=sell]').click();assert((await p.locator('#dialog-description').textContent()).includes('$90'));await p.locator('#dialog-cancel').click();assert(!requests.some(r=>r.body.action==='sell'),'Cancelled sale sends no request');
 await p.locator('[data-action=store]').click();await p.waitForTimeout(200);assert(requests.some(r=>r.body.action==='store'&&r.body.id===40),'Wagon storage action targets the selected ride');
 await p.getByRole('button',{name:'WAGONS',exact:true}).click();
 assert(await p.locator('#primary-button').evaluate(e=>{const a=e.getBoundingClientRect(),b=e.querySelector('span').getBoundingClientRect();return b.left>=a.left&&b.right<=a.right}),'Buy wagon label fits its button');
 assert(await p.locator('#category-caption').evaluate(e=>e.closest('.catalog')!==null),'Category caption belongs under the item strip');
 await p.keyboard.press('Escape');await p.waitForTimeout(250);await p.evaluate(()=>window.postMessage({action:'error',message:'Wagon stored.'},'*'));await p.waitForTimeout(250);assert(await p.locator('#toast').isVisible(),'World notifications work with the stable closed');
 await open();
 for(const viewport of[{width:1280,height:720},{width:1920,height:1080},{width:2560,height:1440}]){
  await p.setViewportSize(viewport);
  const selector=await p.locator('#payment-method').boundingBox(),wallet=await p.locator('.wallet').boundingBox();
  assert(selector.x>=0&&selector.y>=0&&selector.x+selector.width<wallet.x,'Cash/Gold stays left of the wallet without overlap');
  assert(parseFloat(await p.locator('#payment-method button').first().evaluate(e=>getComputedStyle(e).fontSize))>=14,'Currency controls remain readable');
 }
 await p.setViewportSize({width:1920,height:1080});
 await p.screenshot({path:'.test-results/UI-wallet-preview.png'});
 await p.locator('[data-currency=gold]').click();assert((await p.locator('#price').textContent()).startsWith('G'));assert.equal(await p.locator('.gold-symbol').evaluate(e=>getComputedStyle(e).color),'rgb(242, 234, 219)');assert.equal(await p.locator('#price').evaluate(e=>getComputedStyle(e).color),'rgb(228, 205, 141)');assert(await p.locator('#payment-method').evaluate(e=>!e.closest('#details')),'Currency selector stays outside the item detail');await p.locator('#primary-button').click();await p.getByLabel('Name',{exact:true}).fill('Golden');await p.locator('#dialog-submit').click();await p.waitForTimeout(250);assert(requests.some(r=>r.body.action==='buy'&&r.body.currency==='gold'),'Gold currency is sent for a purchase');
 await p.getByRole('button',{name:'MY STABLE',exact:true}).click();await p.getByRole('button',{name:'Equipment',exact:true}).click();await p.locator('.coat-card').nth(1).click();await p.locator('#primary-button').click();await p.waitForTimeout(250);assert.equal(await p.locator('.coat-card.is-equipped .card-caption').textContent(),'Equipped');assert(await p.locator('#primary-button').isDisabled(),'Equipped gear cannot be charged again through UI');await p.screenshot({path:'.test-results/UI-equipped-preview.png'});
 const cs=JSON.parse(fs.readFileSync(path.join(root,'../../locales/cs.json'),'utf8'));
 await p.evaluate(messages=>window.postMessage({action:'locale',locale:'cs',messages},'*'),cs);await p.waitForTimeout(250);
 assert.equal(await p.locator('html').getAttribute('lang'),'cs');assert.equal(await p.locator('[data-tab=owned]').textContent(),'MOJE STÁJ');assert.equal(await p.locator('[data-currency=gold]').textContent(),'Zlato');
 await p.locator('[data-tab=owned]').click();assert.equal(await p.locator('.coat-card .card-caption').first().textContent(),'Dakota','Owned cards show real horse names');assert.equal(await p.locator('.coat-card .card-state').first().textContent(),'Aktivní','Active horse has a localized badge');
 await p.locator('[data-action=rename]').click();assert.equal(await p.locator('#dialog-title').textContent(),'Pojmenuj svého společníka');assert(await p.getByLabel('Jméno',{exact:true}).isVisible());await p.locator('#dialog-cancel').click();
 await p.evaluate(()=>window.postMessage({action:'error',message:'Please slow down.'},'*'));await p.waitForFunction(()=>document.querySelector('#toast').textContent==='Provádíš akce příliš rychle.');assert.equal(await p.locator('#toast').textContent(),'Provádíš akce příliš rychle.');
 await p.screenshot({path:'.test-results/UI-czech-preview.png'});
 assert.deepEqual(errors,[]);console.log('PASS connected UI: strip motion, owned identity, rename, equipment horse selection, NUI requests, focused Escape, purchase dialog, safe cancellation and 720p/1080p/1440p layouts');
 }finally{await b.close();server.close();}})().catch(e=>{console.error(e);process.exitCode=1;server.close()});
