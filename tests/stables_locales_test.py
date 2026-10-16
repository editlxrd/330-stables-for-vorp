from pathlib import Path
import json,sys

from lupa.lua54 import LuaRuntime
root=Path('vorp_stables')
en=json.loads((root/'locales/en.json').read_text(encoding='utf-8'))
cs=json.loads((root/'locales/cs.json').read_text(encoding='utf-8'))
assert set(en)==set(cs),'Locales must have identical keys'
assert cs['Equipped']=='Nasazeno' and cs['Gold']=='Zlato'
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().LoadResourceFile=lambda resource,file:(root/file).read_text(encoding='utf-8') if(root/file).exists()else None
lua.globals().decode_locale=lambda raw:lua.table_from(json.loads(raw))
lua.execute("Config={Locale='cs'};json={decode=decode_locale};function GetCurrentResourceName()return'vorp_stables'end")
lua.execute((root/'shared/locale.lua').read_text(encoding='utf-8'))
assert lua.eval("StableLocale.text('Equipped')")=='Nasazeno'
assert lua.eval("StableLocale.text('Variant {number}',{number=3})")=='Varianta 3'
assert lua.eval("StableLocale.text('Unknown text')")=='Unknown text'
lua.execute("Config.Locale='missing'")
lua.execute((root/'shared/locale.lua').read_text(encoding='utf-8'))
assert lua.eval("StableLocale.text('Equipped')")=='Equipped'
print('PASS locales: complete EN/CS dictionaries, Czech accents, placeholders and English fallback')
