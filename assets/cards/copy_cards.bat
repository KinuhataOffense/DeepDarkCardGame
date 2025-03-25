@echo off  
setlocal enabledelayedexpansion  

set "input_file=card.png"  

set "files=hearts_1.png hearts_2.png hearts_3.png hearts_4.png hearts_5.png hearts_6.png hearts_7.png hearts_8.png hearts_9.png hearts_10.png hearts_11.png hearts_12.png hearts_13.png"  
set "files=!files! diamonds_1.png diamonds_2.png diamonds_3.png diamonds_4.png diamonds_5.png diamonds_6.png diamonds_7.png diamonds_8.png diamonds_9.png diamonds_10.png diamonds_11.png diamonds_12.png diamonds_13.png"  
set "files=!files! clubs_1.png clubs_2.png clubs_3.png clubs_4.png clubs_5.png clubs_6.png clubs_7.png clubs_8.png clubs_9.png clubs_10.png clubs_11.png clubs_12.png clubs_13.png"  
set "files=!files! spades_1.png spades_2.png spades_3.png spades_4.png spades_5.png spades_6.png spades_7.png spades_8.png spades_9.png spades_10.png spades_11.png spades_12.png spades_13.png"  
set "files=!files! joker.png forge_stone.png soul_card.png black_fire.png humanity.png chaos.png dragon_pact.png dark_moon.png first_flame.png soul_ring.png time_hourglass.png"  
 
for %%f in (!files!) do (  
    echo Copying from %input_file% to %%f  
    copy "%input_file%" "%%f"  
)  

echo All files copied successfully.  
pause  