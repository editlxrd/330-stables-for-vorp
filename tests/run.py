from pathlib import Path
import os,subprocess,sys
from lupa.lua54 import LuaRuntime
os.chdir(Path(__file__).resolve().parents[1])
failed=0
for test in sorted(Path('tests').glob('*_test.lua')):
 try: LuaRuntime(unpack_returned_tuples=True).execute(test.read_text(encoding='utf-8'))
 except Exception as error: print('FAIL',test.name,error);failed+=1
for test in sorted(Path('tests').glob('*_test.py')):
 failed+=subprocess.run([sys.executable,str(test)]).returncode!=0
raise SystemExit(bool(failed))
