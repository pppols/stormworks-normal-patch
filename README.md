# stormworks-normal-patch
a small client side exe patcher to solve the commonly named "xml shadow", via correcting incorrectly transformed normal vectors from non-orthonormal transformation matrices

- automatic executable patcher
- self contained windows build
- creates backup of original executable  


## usage
1. either download the standalone patcher executable, or the script and accompanying bin file (ensure you have a sufficient python installation)  
2. ensure stormworks is closed, this must modify the games executable itself  
3. run the patcher, the file explorer will be prompted for you to select the stormworks64.exe executable (select the 64 bit version!)  
4. apply the patch  
5. no more incorrect lighting on xml-ed parts, so long as this is maintained, and hopefully with no bugs


## gallery
### before vs. after
<img width="400" height="200" alt="image" src="https://github.com/user-attachments/assets/940f91a2-ace2-4105-911d-1baa9e948252" />
<img width="400" height="200" alt="image" src="https://github.com/user-attachments/assets/0f3ab568-200a-4c89-ae5d-7765d18d7339" />
<img width="400" height="200" alt="Screenshot 2026-10-26 151013" src="https://github.com/user-attachments/assets/d2648c21-b9bd-4789-abe7-e3647e2df32b" />
<img width="400" height="200" alt="Screenshot 2026-10-26 150831" src="https://github.com/user-attachments/assets/4088751e-c65e-46aa-ac5e-47192b3cfd6f" />
<img width="400" height="200" alt="Screenshot 2026-10-29 145609" src="https://github.com/user-attachments/assets/17f9ad35-18de-40d7-ba77-070474ab1a49" />
<img width="400" height="200" alt="Screenshot 2026-10-29 145410" src="https://github.com/user-attachments/assets/1a3b5f2b-0027-4f36-8a70-c7478072c224" />
<img width="400" height="200" alt="20261029150358_1" src="https://github.com/user-attachments/assets/08543830-f9eb-4fac-855e-fdb2f886689e" />
<img width="400" height="200" alt="Screenshot 2026-10-29 150520" src="https://github.com/user-attachments/assets/897ba072-8c68-416c-bc81-e48771beb7d5" />

[example 4]: normal vector debug view


## note!
being something that modifies the executable itself: any time the game updates and modifies the executable, you will have to apply the patch again  

along with that, new game versions may affect the underlying mesh update systems that this serves to fix, if you are applying this tool on a newer game version, there is a chance it may fail!"

in that case, either reinstate the exe backup it creates in the same folder as the stormworks executable, or verify your game files on steam to return to the original configuration  

yes, windows will flag the application as an unknown publisher, i am a very not known publisher  

all made with my own bad coding practices  


## building it
the bat file runs the gnu assembler on the `fixed_normal_calculation.asm` file and outputs the corresponding bin file 

the bin file is loaded in the python script and is all the code that replaces the original normal vector transformation, besides the internally generated trampoline setup  

for packaging into an exe, i just used pyinstaller, what can i say
