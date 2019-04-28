
--[[TrityChess
--]]
require "Load/Load"
Processed={}
TextTimer=0
function love.update(dt)
	TextTimer=TextTimer+dt
	if TextTimer>=3 then TextTimer=0 end
	--Rescale everything if window is of different size
	Xmod,Ymod=WindowX/1000,WindowY/1000
	Mod=math.min(Xmod,Ymod)
	--Correct mouse position based on rescaling
	MouseX,MouseY=love.mouse.getX()/Mod,love.mouse.getY()/Mod
	if not(Trity) then
		return nil
	end
	--Silence timer, indicates lack of communication with other processes
	Trity.Silence=Trity.Silence+dt
	--Communicate with other processes
	Trity.Read()
	--Checking if there is analysis being done right now, and checking if it has already finished
	if Trity.Awaiting and (Trity.Silence>0.5 and ChannelIN:getCount()==0 and ChannelOUT:getCount()==0) then
		--Checking if this is the last step of analysis
		if Trity.RequestDepth>0 then
			--Starting another step of analysis
			Trity.Request(Trity.ToSend)
			Trity.ToSend={}
			Trity.RequestDepth=Trity.RequestDepth-1
		else
			--Making turn
			local RES=Trity.ParentalSort(Trity.Boards[Trity.Awaiting][2],2)
			if RES==true then CurrentBoard.Player=-CurrentBoard.Player FINISHED=true
			else CurrentBoard=DeConcatBoard(RES[1][1])
			end
			Trity.Awaiting=nil
			Trity.Boards={}
			Trity.ToSend={}
			Sound.Save:play()
			Highlight={{},{},{},{},{},{},{},{},}
			if SelectX and not(FINISHED) and GetOwner(CurrentBoard[SelectY][SelectX])==CurrentBoard.Player then
				for A,B in ipairs(PieceVariants(CurrentBoard,SelectX,SelectY)) do
					if NewChild(CurrentBoard,SelectX,SelectY,B[1],B[2]) then Highlight[B[2]][B[1]]=true end
				end
			end
		end
	end
end

function love.draw()
	--Rescale everything if window is of different size
	love.graphics.scale(Mod,Mod)
	--Displaying whose turn it is
	local TURN="Black"
	if CurrentBoard.Player==1 then TURN="White" end
	if FINISHED then love.graphics.print("Winner: "..TURN,0,0,0,3,3)
	else love.graphics.print("Turn: "..TURN,0,0,0,3,3) end
	
	if Trity.Awaiting then love.graphics.print("Thinking"..string.rep(".",math.ceil(TextTimer*2)),300,0,0,3,3) end
	--Drawing board
	local SYMB={"A","B","C","D","E","F","G","H"}
	for Y=1,8 do
		love.graphics.setColor(0.6,0.6,0.6)
		love.graphics.print(SYMB[Y],40+100*Y,60,0,2,2)
		love.graphics.print(SYMB[Y],40+100*Y,900,0,2,2)
		love.graphics.print(Y,70,30+100*Y,0,2,2)
		love.graphics.print(Y,900,30+100*Y,0,2,2)
		for X=1,8 do
			if math.fmod(X+Y,2)==0 then love.graphics.setColor(200/255,150/255,150/255) else love.graphics.setColor(100/255,50/255,50/255) end
			if SelectX==X and SelectY==Y then love.graphics.setColor(0,1,0) end
			love.graphics.rectangle("fill",X*100,Y*100,100,100)
			love.graphics.setColor(1,1,1)
			if Highlight[Y][X] then 
				love.graphics.setColor(0.8,0.1,0.1,0.8)
				love.graphics.rectangle("line",3+X*100,3+Y*100,95,95)
				love.graphics.setColor(1,1,1,1)
			end
			if CurrentBoard[Y][X]~=e then
				if GetOwner(CurrentBoard[Y][X])==1 then love.graphics.setShader(Shaders.Reverse) end
				local IMAGE=Textures["ChessPieces/"..(BacktrackTable(Pieces[1],CurrentBoard[Y][X]) or BacktrackTable(Pieces[-1],CurrentBoard[Y][X]))]
				love.graphics.draw(IMAGE,50+X*100,50+Y*100,0,1.3,1.3,IMAGE:getWidth()/2,IMAGE:getHeight()/2)
				if GetOwner(CurrentBoard[Y][X])==1 then love.graphics.setShader() end
			end
		end
	end
end

function love.resize(w,h)
	WindowX,WindowY=love.window.getMode()
	
end

function love.mousepressed(x,y,KEY)
	local targetY,targetX=math.ceil((MouseY-100)/100),math.ceil((MouseX-100)/100)
	
	if KEY==1 and not(Trity.Awaiting) and SelectX and GetOwner(CurrentBoard[SelectY][SelectX])==CurrentBoard.Player and not(targetX>8 or targetY>8 or targetX<1 or targetY<1) and not(GetOwner(CurrentBoard[targetY][targetX])==CurrentBoard.Player) then
		local BOOL=false
		local NEW
		for A,B in ipairs(PieceVariants(CurrentBoard,SelectX,SelectY)) do
			NEW=NewChild(CurrentBoard,SelectX,SelectY,B[1],B[2])
			if B[1]==targetX and B[2]==targetY and NEW then BOOL=true break end
		end
		if BOOL then
			CurrentBoard=NEW
			Trity.RequestDepth=2
			Trity.Silence=-1
			Trity.ToSend={}
			Trity.Boards={}
			Trity.Request({CurrentBoard})
			Trity.Awaiting=ConcatBoard(CurrentBoard)
			TextTimer=0
			SelectX=nil
			SelectY=nil
			Sound.Save:play()
		else
			Sound.Delete:play()
		end
	else
		SelectX=math.ceil((MouseX-100)/100)
		SelectY=math.ceil((MouseY-100)/100)
	end
	Highlight={{},{},{},{},{},{},{},{},}
	if SelectX and not(SelectX>0 and SelectX<9 and SelectY>0 and SelectX<9) then SelectX=nil SelectY=nil end
	if SelectX then
		for A,B in ipairs(PieceVariants(CurrentBoard,SelectX,SelectY)) do
			if NewChild(CurrentBoard,SelectX,SelectY,B[1],B[2]) then Highlight[B[2]][B[1]]=true end
		end
	end
end

function love.keypressed(KEY)
 if KEY=="lctrl" then
	if not(CtrlPressed) then
		CtrlPressed=true
	else
		CtrlPressed=nil
	end
 elseif KEY=="lshift" then ShiftPressed=true
 elseif KEY=="lalt" and not(CtrlPressed) then
	AltPressed=true
	AltSwitch=not(AltSwitch)
 end
 
end

function love.keyreleased(KEY)
	if KEY=="lshift" then ShiftPressed=false
	elseif KEY=="lalt" then AltPressed=false
	end
end









