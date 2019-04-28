--Some aliases for shorter code
r="r"
k="k"
b="b"
i="i"
q="q"
p="p"
P="P"
R="R"
K="K"
B="B"
I="I"
Q="Q"
e="e"
Pieces={
	White={
		Rook=r,
		Knight=k,
		Bishop=b,
		King=i,
		Queen=q,
		Pawn=p,
	},
	Black={
		Pawn=P,
		Rook=R,
		Knight=K,
		Bishop=B,
		King=I,
		Queen=Q,
	},
	Empty=e,
}
Pieces[1]=Pieces.White
Pieces[-1]=Pieces.Black
--Find coordinates of the king of given player on given board
function DetectKing(Board,Player)
	local Piece=(Player==1 and i) or I
	for Y=1,8 do
		for X=1,8 do
			if Board[Y][X]==Piece then return {X,Y} end
		end
	end
end
--Returns owner of the piece
function GetOwner(Piece,Player)
	return Piece~=e and ((Piece:lower()==Piece and 1) or -1)
end
--Checking if a rook at X1,Y1 would hit field at X2,Y2.
local function StraightHit(Board,X1,Y1,X2,Y2)
	if X1==X2 and Y1==Y2 then return false end
	if X1==X2 then
		local MOD=Y1-Y2
		MOD=MOD/math.abs(MOD)
		for I=Y2+MOD,Y1-MOD,MOD do
			if Board[I][X1]~=Pieces.Empty then return false end
		end
		return true
	elseif Y1==Y2 then
		local MOD=X1-X2
		MOD=MOD/math.abs(MOD)
		for I=X2+MOD,X1-MOD,MOD do
			if Board[Y1][I]~=Pieces.Empty then return false end
		end
		return true
	end
	return false
end
--Checking if a bishop at X1,Y1 would hit field at X2,Y2.
local function DiagonalHit(Board,X1,Y1,X2,Y2)
	if X1==X2 and Y1==Y2 then return false end
	if X1-Y1==X2-Y2 or X1+Y1==X2+Y2 then
		local MODX=X1-X2
		MODX=MODX/math.abs(MODX)
		local MODY=Y1-Y2
		MODY=MODY/math.abs(MODY)
		for I=1,math.abs(X1-X2)-1,1 do
			if Board[Y2+MODY*I][X2+MODX*I]~=Pieces.Empty then return false end
		end
		return true
	end
	return false
end
--Checks if any of player's pieces can hit given field
function PlayerHits(Board,TargetX,TargetY,Player)
	if Board[TargetY-Player] and Board[TargetY-Player][TargetX+1]==Pieces[Player].Pawn then return true end
	if Board[TargetY-Player] and Board[TargetY-Player][TargetX-1]==Pieces[Player].Pawn then return true end
	local Detected={{},{},{},{},{}}
	local q=Pieces[Player].Queen
	local r=Pieces[Player].Rook
	local b=Pieces[Player].Bishop
	local k=Pieces[Player].Knight
	local i=Pieces[Player].King
	for Y=1,8 do
		for X=1,8 do
			if Board[Y][X]==r then table.insert(Detected[2],{X,Y})
			elseif Board[Y][X]==b then table.insert(Detected[3],{X,Y})
			elseif Board[Y][X]==k then table.insert(Detected[4],{X,Y})
			elseif Board[Y][X]==i then table.insert(Detected[5],{X,Y})
			elseif Board[Y][X]==q then table.insert(Detected[1],{X,Y})
			end
		end
	end
	for NUM,VALUE in ipairs(Detected[1]) do
		local Y=VALUE[2]
		local X=VALUE[1]
		if StraightHit(Board,X,Y,TargetX,TargetY) or DiagonalHit(Board,X,Y,TargetX,TargetY) then return true end
	end
	for NUM,VALUE in ipairs(Detected[2]) do
		local Y=VALUE[2]
		local X=VALUE[1]
		if StraightHit(Board,X,Y,TargetX,TargetY) then return true end
	end
	for NUM,VALUE in ipairs(Detected[3]) do
		local Y=VALUE[2]
		local X=VALUE[1]
		if DiagonalHit(Board,X,Y,TargetX,TargetY) then return true end
	end
	for NUM,VALUE in ipairs(Detected[4]) do
		local Y=VALUE[2]
		local X=VALUE[1]
		if (math.abs(X-TargetX)==2 and math.abs(Y-TargetY)==1) or (math.abs(X-TargetX)==1 and math.abs(Y-TargetY)==2) then return true end
	end
	local Y=Detected[5][1][2]
	local X=Detected[5][1][1]
	if math.abs(X-TargetX)<=1 and math.abs(Y-TargetY)<=1 then return true end
end
--Encode board into a string
function ConcatBoard(Board)
	STRING=((Board.Player==1 and "1") or "2")..Board.WR..Board.BR
	for Y=1,8 do
		STRING=STRING..table.concat(Board[Y])
	end
	return STRING
end
--Decode board from a string
function DeConcatBoard(String)
	local Board={{},Player=((String:sub(1,1)=="1" and 1) or -1),WR=tonumber(String:sub(2,2)),BR=tonumber(String:sub(3,3))}
	local INDEX1=1
	local INDEX2=1
	for Char in String:gmatch("(%D)") do
		if INDEX2>8 then INDEX1=INDEX1+1 Board[INDEX1]={} INDEX2=1 end
		table.insert(Board[INDEX1],Char)
		INDEX2=INDEX2+1
	end
	return Board
end

function CopyBoard(Board)
	local Return={Player=Board.Player,WR=Board.WR,BR=Board.BR}
	for Y=1,8 do
		table.insert(Return,{})
		for X=1,8 do
			table.insert(Return[Y],Board[Y][X])
		end
	end
	return Return
end
