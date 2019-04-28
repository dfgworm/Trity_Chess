local Trity={
	Processors={},
	CurrentPlayer=1,
	Boards={},
	RequestDepth=-1,
	Silence=0,
	ToSend={},
	}

--Channels for communicating with other processes
ChannelIN=love.thread.getChannel("Results")
ChannelOUT=love.thread.getChannel("Requests")
--Communicate with other processes
function Trity.Read()
	local Message=ChannelIN:pop()
	while Message do
		if type(Message[2])=="table" then
			if not(Trity.Boards[Message[1]][2]) then
				Trity.Boards[Message[1]][2]={}
				for A,B in ipairs(Message[2]) do
					local CONCAT=ConcatBoard(B)
					if not(Trity.Boards[CONCAT]) then Trity.Boards[CONCAT]={CONCAT} end
					table.insert(Trity.Boards[Message[1]][2],Trity.Boards[CONCAT])
				end
			end
			for A,B in ipairs(Message[2]) do
				table.insert(Trity.ToSend,B)
			end
		else
			if not(Trity.Boards[Message[1]]) then Trity.Boards[Message[1]]={Message[1]} end
			if not(Trity.Boards[Message[1]][3]) then Trity.Boards[Message[1]][3]=Message[2] end
		end
		Message=ChannelIN:pop()
		Trity.Silence=0
	end
end

local PLAYER
local function SORTA(a,b) return a[3]*PLAYER>b[3]*PLAYER end
--Sort a list of boards based on their real state
local function RealSort(Array)
	if #Array==0 then return true end
	PLAYER=(Array[1][1]:sub(1,1)=="1" and -1) or 1
	table.sort(Array,SORTA)
	return Array
end

do
local Player
local function SORTB(a,b) if b[4]==nil then error(a[1]) end return a[4]*Player>b[4]*Player end
--Sort a list of boards based on their possible outcomes
function Trity.ParentalSort(Array,Depth,REPEAT)
	REPEAT=REPEAT or {}
	Array=CopyArray(Array,false)
	if not(Depth) or Depth==0 or #Array==0 then return RealSort(Array) end
	Player=(Array[1][1]:sub(1,1)=="1" and -1) or 1
	local PLAYER=Player
	local REMOVAL={}
	for A,B in ipairs(Array) do
		if not(REPEAT[B[1]]) then
			REPEAT[B[1]]=true
			local C=Trity.ParentalSort(B[2],Depth-1,REPEAT)
			if C==true then
				local Board=DeConcatBoard(B[1])
				local KCOORD=DetectKing(Board,Player)
				if PlayerHits(Board,KCOORD[1],KCOORD[2],-Player) then
					B[4]=80*-Player
				else
					B[4]=60*-Player
				end
			else B[4]=C[1][4] or C[1][3] end
		else table.insert(REMOVAL,A) end
	end
	if #REMOVAL>=#Array then return RealSort(Array) end
	for B=#REMOVAL,1,-1 do table.remove(Array,B) end
	Player=PLAYER
	table.sort(Array,SORTB)
	return Array
end
end

--Send boards to other processes for analysis
function Trity.Request(Array)
	for A,B in ipairs(Array) do
		local CONCAT=ConcatBoard(B)
		if not(Trity.Boards[CONCAT]) then Trity.Boards[CONCAT]={CONCAT} end
		if Trity.RequestDepth>1 then B.R=1
		else B.R=2 end
		if not(Trity.Boards[CONCAT][2]) then ChannelOUT:push(B) end
	end
end

local Lower=string.lower
--Diagonal turns for bishop and queen
local function DiagonalVariants(Board,Var,X,Y,Player,IncludeAlly)
	for AMP=-1,1,2 do
		for YMOD=-1,1,2 do
			local I=AMP
			while true do
				if Y+I*YMOD>8 or Y+I*YMOD<1 or X+I>8 or X+I<1 or (GetOwner(Board[Y+I*YMOD][X+I])==Player and not(IncludeAlly)) then break end
				table.insert(Var,{X+I,Y+I*YMOD})
				if Board[Y+I*YMOD][X+I]~=e then break end
				I=I+AMP
			end
		end
	end
end
--Line turns for rook and queen
local function StraightVariants(Board,Var,X,Y,Player,IncludeAlly)
	for AMP=-1,1,2 do
		local I=AMP
		while true do
			if X+I>8 or X+I<1 or (GetOwner(Board[Y][X+I])==Player and not(IncludeAlly)) then break end
			table.insert(Var,{X+I,Y})
			if Board[Y][X+I]~=e then break end
			I=I+AMP
		end
	end
	for AMP=-1,1,2 do
		local I=AMP
		while true do
			if Y+I>8 or Y+I<1 or (GetOwner(Board[Y+I][X])==Player and not(IncludeAlly)) then break end
			table.insert(Var,{X,Y+I})
			if Board[Y+I][X]~=e then break end
			I=I+AMP
		end
	end
end

--Complex function which returns all possible turns for a piece at X,Y
function PieceVariants(Board,X,Y)
	local ARRAY={}
	local LETTER=Board[Y][X]
	local Player=GetOwner(LETTER)
	if Player then
		if Lower(LETTER)==i then
			for I=-1,1,1 do
				for J=-1,1,1 do
					if X+I<9 and X+I>0 and Y+J<9 and Y+J>0 and not(I==0 and J==0) and not(GetOwner(Board[Y+J][X+I])==Player and not(IncludeAlly)) then table.insert(ARRAY,{X+I,Y+J}) end
				end
				if (Board.Player==1 and Board.WR~=2) or (Board.Player==-1 and Board.BR~=2) then
					if ((Board.Player==1 and Board.WR~=1) or (Board.Player==-1 and Board.BR~=1)) and Board[Y][2]==e and Board[Y][3]==e and not(PlayerHits(Board,1,Y,-Board.Player) or PlayerHits(Board,2,Y,-Board.Player) or PlayerHits(Board,3,Y,-Board.Player) or PlayerHits(Board,4,Y,-Board.Player)) then
						table.insert(ARRAY,{2,Y})
					end
					if ((Board.Player==1 and Board.WR~=3) or (Board.Player==-1 and Board.BR~=3)) and Board[Y][5]==e and Board[Y][6]==e and Board[Y][7]==e and not(PlayerHits(Board,4,Y,-Board.Player) or PlayerHits(Board,5,Y,-Board.Player) or PlayerHits(Board,6,Y,-Board.Player) or PlayerHits(Board,7,Y,-Board.Player) or PlayerHits(Board,8,Y,-Board.Player)) then
						table.insert(ARRAY,{6,Y})
					end
				end
			end
		elseif Lower(LETTER)==q then
			local Variants={}
			DiagonalVariants(Board,Variants,X,Y,Player,IncludeAlly)
			StraightVariants(Board,Variants,X,Y,Player,IncludeAlly)
			for NUM2,VALUE2 in ipairs(Variants) do
				local X2=VALUE2[1]
				local Y2=VALUE2[2]
				table.insert(ARRAY,{X2,Y2})
			end
		elseif Lower(LETTER)==p then
			if Y+Player>0 and Y+Player<9 and X+1<9 and GetOwner(Board[Y+Player][X+1])==-Player then table.insert(ARRAY,{X+1,Y+Player}) end
			if Y+Player>0 and Y+Player<9 and X-1>0 and GetOwner(Board[Y+Player][X-1])==-Player then table.insert(ARRAY,{X-1,Y+Player}) end
			if Y+Player>0 and Y+Player<9 and Board[Y+Player][X]==e then
				table.insert(ARRAY,{X,Y+Player})
				if Y+Player*2.5==4.5 and Board[Y+2*Player][X]==e then table.insert(ARRAY,{X,Y+2*Player}) end
			end
		elseif Lower(LETTER)==k then
			for I=-1,1,2 do
				for J=-1,1,2 do
					if Y+J*I>0 and Y+J*I<9 and X+2*I<9 and X+2*I>0 and not(GetOwner(Board[Y+J*I][X+2*I])==Player and not(IncludeAlly)) then table.insert(ARRAY,{X+2*I,Y+J*I}) end
					if Y+2*I>0 and Y+2*I<9 and X+J*I<9 and X+J*I>0 and not(GetOwner(Board[Y+2*I][X+J*I])==Player and not(IncludeAlly)) then table.insert(ARRAY,{X+J*I,Y+2*I}) end
				end
			end
		elseif Lower(LETTER)==r then
			local Variants={}
			StraightVariants(Board,Variants,X,Y,Player,IncludeAlly)
			for NUM2,VALUE2 in ipairs(Variants) do
				local X2=VALUE2[1]
				local Y2=VALUE2[2]
				table.insert(ARRAY,{X2,Y2})
			end
		elseif Lower(LETTER)==b then
			local Variants={}
			DiagonalVariants(Board,Variants,X,Y,Player,IncludeAlly)
			for NUM2,VALUE2 in ipairs(Variants) do
				local X2=VALUE2[1]
				local Y2=VALUE2[2]
				table.insert(ARRAY,{X2,Y2})
			end
		end
	end
	return ARRAY
end

--Making a proper turn
function NewChild(Board,X1,Y1,X2,Y2)
	if type(Board)=="string" then Board=DeConcatBoard(Board) end
	local NEWBOARD=CopyBoard(Board)
	local l=Lower(Board[Y1][X1])
	if l==i then
		if Board.Player==1 then
			NEWBOARD.WR=2
		else
			NEWBOARD.BR=2
		end
		if math.abs(X1-X2)==2 then
			if X2==2 then
				NEWBOARD[Y1][3]=NEWBOARD[Y1][1]
				NEWBOARD[Y1][1]=e
			elseif X2==6 then
				NEWBOARD[Y1][5]=NEWBOARD[Y1][8]
				NEWBOARD[Y1][8]=e
			end
		end
	elseif l==r then
		if Board.WR~=2 and Board.Player==1 then
			if Board[1][1]~=r then
				if Board.WR==0 then NEWBOARD.WR=1
				elseif Board.WR==3 then NEWBOARD.WR=2
				end
			end
			if Board[1][8]~=r then
				if Board.WR==0 then NEWBOARD.WR=3
				elseif Board.WR==1 then NEWBOARD.WR=2
				end
			end
		elseif Board.BR~=2 and Board.Player==3 then
			if Board[8][1]~=R then
				if Board.BR==0 then NEWBOARD.BR=1
				elseif Board.BR==3 then NEWBOARD.BR=2
				end
			end
			if Board[8][8]~=R then
				if Board.BR==0 then NEWBOARD.BR=3
				elseif Board.BR==1 then NEWBOARD.BR=2
				end
			end
		end
	end
	if Lower(NEWBOARD[Y2][X2])==i then return nil end
	NEWBOARD.Player=-NEWBOARD.Player --#Longterm reversed
	NEWBOARD[Y2][X2]=NEWBOARD[Y1][X1]
	NEWBOARD[Y1][X1]=e
	local Detected=DetectKing(NEWBOARD,-NEWBOARD.Player)
	local Y=Detected[2]
	local X=Detected[1]
	if PlayerHits(NEWBOARD,X,Y,NEWBOARD.Player) then return nil end
	return NEWBOARD
end
--Create additional processes(threads)
for I=1,AmountOfProcesses do
	table.insert(Trity.Processors,love.thread.newThread("TrityProcessor.lua"))
	Trity.Processors[I]:start()
end

return Trity
