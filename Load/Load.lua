 
 
 Font=love.graphics.newFont("GOST-type-B-Standard.ttf",20)
 require "GeneralFunctions"
 require "ChessFunctions"

function love.load()
 WindowX,WindowY=love.graphics.getDimensions()
 MouseX=0
 MouseY=0
 Textures={}
 Shaders={}
 love.graphics.setFont(Font)
 love.graphics.setLineWidth(5)
 
 
 Display=0
 CurrentBoard={Player=1,WR=0,BR=0,
 {r,k,b,i,q,b,k,r},
 {p,p,p,p,p,p,p,p},
 {e,e,e,e,e,e,e,e},
 {e,e,e,e,e,e,e,e},
 {e,e,e,e,e,e,e,e},
 {e,e,e,e,e,e,e,e},
 {P,P,P,P,P,P,P,P},
 {R,K,B,I,Q,B,K,R},
 }
 Highlight={{},{},{},{},{},{},{},{},}
 
 AmountOfProcesses=love.system.getProcessorCount()
 Trity=require"Trity"
 
 ImageFolder("ChessPieces")
 Shaders.Reverse=require"Shaders/Reverse"
 love.audio.setVolume(0.1)
 Sound={}
 Sound.Save=love.audio.newSource("Sound/Save.wav","static")
 Sound.Delete=love.audio.newSource("Sound/Delete.wav","static")
end




