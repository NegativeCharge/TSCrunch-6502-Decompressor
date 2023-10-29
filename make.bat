cd .\tests\
for %%x in (*.tsc) do del "%%x" 
for %%x in (*.bin) do ..\tools\tscrunch.exe "%%x" "%%~nx.bin.tsc"

cd ..
cmd /c "BeebAsm.exe -v -i tscrunch_test.s.asm -do tscrunch_test.ssd -opt 3"