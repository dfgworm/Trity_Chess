--Additional processes designed to utilize all processor cores for outcome computation
local RUN=true
local ChannelIN=love.thread.getChannel("Requests")
local ChannelOUT=love.thread.getChannel("Results")
require "ChessFunctions"
require "GeneralFunctions"
do
--Worthes of each piece
local PieceWorth={
				[r]=5,
				[b]=4,
				[k]=4,
				[p]=1,
				[q]=8,
				[i]=10,
				}
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
--different from similar function in main thread
local function PieceVariants(Board,X,Y,IncludeAlly)
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
			if Y+Player>0 and Y+Player<9 and X+1<9 and not(GetOwner(Board[Y+Player][X+1])==Player and not(IncludeAlly)) then table.insert(ARRAY,{X+1,Y+Player}) end
			if Y+Player>0 and Y+Player<9 and X-1>0 and not(GetOwner(Board[Y+Player][X-1])==Player and not(IncludeAlly)) then table.insert(ARRAY,{X-1,Y+Player}) end
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

--Move piece at X1,Y1 to X2,Y2, returns nothing if such turn exposes the king
local function NewChild(Board,X1,Y1,X2,Y2)
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
	NEWBOARD.Player=-NEWBOARD.Player
	NEWBOARD[Y2][X2]=NEWBOARD[Y1][X1]
	NEWBOARD[Y1][X1]=e
	local Detected=DetectKing(NEWBOARD,-NEWBOARD.Player)
	local Y=Detected[2]
	local X=Detected[1]
	if PlayerHits(NEWBOARD,X,Y,NEWBOARD.Player) then return nil end
	return NEWBOARD
end
--Get all possible outcomes of a board
function GetChildren(Board)
	if type(Board)=="string" then Board=DeConcatBoard(CONCAT) end
	local RETURN={}
	local Player=Board.Player
	for Y=1,8 do
		for X=1,8 do
			local LETTER=Board[Y][X]
			if GetOwner(LETTER)==Player then
				local Variants=PieceVariants(Board,X,Y)
				for A,B in ipairs(Variants) do
					if LETTER==Pieces[Player].Pawn then
						if GetOwner(Board[B[2]][B[1]])==-Player then table.insert(RETURN,NewChild(Board,X,Y,B[1],B[2])) end
					else
						table.insert(RETURN,NewChild(Board,X,Y,B[1],B[2]))
					end
				end
				if LETTER==Pieces[Player].Pawn then
					if Y+Player>0 and Y+Player<9 and Board[Y+Player][X]==e then
						table.insert(RETURN,NewChild(Board,X,Y,X,Y+Player))
						if Y+Player*2.5==4.5 and Board[Y+2*Player][X]==e then table.insert(RETURN,NewChild(Board,X,Y,X,Y+2*Player)) end
					end
				end
			end
		end
	end
	return RETURN
end

local ARRAY={PieceWorth[p],PieceWorth[b],PieceWorth[r],PieceWorth[q],PieceWorth[i]}
--Check who dominates a field using an array with amount of hits by each kind of pieces
local function CheckThreats(H,Player)
	local Leftovers
	local Win
	for _,Worth in ipairs(ARRAY) do if H[Worth] then
		Leftovers=(Leftovers or 0)+H[Worth]
		if Leftovers~=0 then
			local W=Round(Leftovers/math.abs(Leftovers))
			Win=Win or W
			if Win~=W then return nil end
		end
	end end
	if not(Leftovers) or Leftovers==0 then return nil end
	return (Win==Player)
end

do local HITS={Tolerance=false,AntiTolerance=false}
for Y=1,8 do
	table.insert(HITS,{})
	for X=1,8 do
		table.insert(HITS[Y],{})
	end
end 
--Evaluate current state of the board
--More = better for white, Less = better for black
function GetWorth(Board)
	local PieceWorth=PieceWorth
	if type(Board)=="string" then Board=DeConcatBoard(CONCAT) end
	local Worth=0
	HITS.Tolerance=false
	HITS.AntiTolerance=false
	HITS.C=nil
	for Y=1,8 do
		for X=1,8 do
			HITS[Y][X].C=nil
			HITS[Y][X].B=nil
			HITS[Y][X][1]=nil
			HITS[Y][X][4]=nil
			HITS[Y][X][5]=nil
			HITS[Y][X][8]=nil
			HITS[Y][X][10]=nil
		end
	end
	local KINGTHREAT=DetectKing(Board,Board.Player)
	KINGTHREAT=PlayerHits(Board,KINGTHREAT[1],KINGTHREAT[2],-Board.Player)
	if KINGTHREAT then
		local CONCAT=ConcatBoard(Board)
		local CHILDREN=GetChildren(Board)
		if #CHILDREN==0 then
			return 80*-Board.Player 
		end
	end
	for Y=1,8 do
		for X=1,8 do
			local LETTER=Board[Y][X]
			local Variants=PieceVariants(Board,X,Y,true)
			local Player=GetOwner(LETTER)
			for A,B in ipairs(Variants) do
				local TempBoard=CopyBoard(Board)
				TempBoard[B[2]][B[1]]=TempBoard[Y][X]
				TempBoard[Y][X]=e
				local Victim=Board[B[2]][B[1]]
				local v,l=Lower(Victim),Lower(LETTER)
				local K=DetectKing(TempBoard,Player)--#denying impossible moves and correcting threatened board worth
				if (l==i or v==i) or KINGTHREAT or not(PlayerHits(TempBoard,K[1],K[2],-Player)) then
					local H=HITS[B[2]][B[1]]
					if GetOwner(Victim)==-Player then
						if v==i then
							Worth=Worth-0.5*Board.Player
							HITS.C=true
							HITS[Y][X].C=true
						elseif type(H.B)~="number" or PieceWorth[v]-PieceWorth[l]>H.B then
							H.B=PieceWorth[v]-PieceWorth[l]
						end
					end
					H[PieceWorth[l]]=(H[PieceWorth[l]] or 0)+1*Player
				end 
			end
		end
	end
	for Y=1,8 do
		for X=1,8 do
			local LETTER=Board[Y][X]
			local l=Lower(LETTER)
			local H=HITS[Y][X]
			local Player=GetOwner(LETTER)
			local Dominance=CheckThreats(H,Player)
			if Player and Player==-Board.Player and (Dominance==false or (H.B and H.B>1)) and l~=i and (not(HITS.C) or H.C) then
				local LocalWorth=PieceWorth[l]
				local Variants=PieceVariants(Board,X,Y)
				for A,B in ipairs(Variants) do
					H=HITS[B[2]][B[1]]
					v=Lower(Board[B[2]][B[1]])
					if v~=i and H[PieceWorth[l]] then
						Dominance=CheckThreats(H,Player)
						H[PieceWorth[l]]=H[PieceWorth[l]]-1*Player
						local FakeDominance=CheckThreats(H,Player)
						H[PieceWorth[l]]=H[PieceWorth[l]]+1*Player
						if (FakeDominance==false and Dominance~=false) or (FakeDominance==nil and Dominance) or (v~=e and PieceWorth[v]-PieceWorth[l]>1) then
							LocalWorth=LocalWorth+0.1
							if v~=e then
								LocalWorth=LocalWorth+PieceWorth[v]/2
							end
						end
					end
				end
				if not(HITS.AntiTolerance) or HITS.AntiTolerance[3]<LocalWorth then
					HITS.AntiTolerance={X,Y,LocalWorth}
				end
			end
		end
	end
	if HITS.AntiTolerance then
		local Variants=PieceVariants(Board,HITS.AntiTolerance[1],HITS.AntiTolerance[2],true)
		local l=Lower(Board[HITS.AntiTolerance[2]][HITS.AntiTolerance[1]])
		for A,B in ipairs(Variants) do
			if HITS[B[2]][B[1]][PieceWorth[l]] then HITS[B[2]][B[1]][PieceWorth[l]]=HITS[B[2]][B[1]][PieceWorth[l]]+1*Board.Player end
		end
	end
	local CHBOOL
	for Y=1,8 do
		for X=1,8 do
			local LETTER=Board[Y][X]
			local FieldPrice=((X==1 or X==8 or Y==1 or Y==8) and 0.12) or ((X==7 or X==2 or Y==7 or Y==2) and 0.16) or 0.2
			local Player=GetOwner(LETTER)
			local H=HITS[Y][X]
			local Dominance=CheckThreats(H,Player or 1)
			if Player then
				if Lower(LETTER)~=i and Dominance==false then
					H.B=PieceWorth[Lower(LETTER)]-0.7
					if Player==-Board.Player and HITS.AntiTolerance then
						H.B=H.B+0.7
						HITS.AntiTolerance=nil
					end
				end
				if Lower(LETTER)~=i and H.B and (not(Dominance) or H.B>0) then
					if H.B<PieceWorth[Lower(LETTER)]*0.2 then H.B=PieceWorth[Lower(LETTER)]*0.2 end
					if Player==Board.Player and not(HITS.Tolerance) then
						HITS.Tolerance=H.B
						H.B=0
					elseif Player==Board.Player and type(HITS.Tolerance)=="number" and H.B>HITS.Tolerance then
						HITS.Tolerance,H.B=H.B,HITS.Tolerance
					end
				end
				if not(H.B) or H.B<0 then H.B=0 end
				Worth=Worth+(PieceWorth[Lower(LETTER)]-H.B)*Player
			else Player=1
			end
			if H.C then
				if (Dominance~=false and H.B>0) or CHBOOL==false then CHBOOL=true end
				if (Dominance==false or H.B<0) and CHBOOL==nil then CHBOOL=false end
			end
			if Dominance then
				Worth=Worth+FieldPrice*Player
			elseif Dominance==false then
				Worth=Worth-FieldPrice*Player
			end
		end
	end
	if HITS.C and CHBOOL then Worth=Worth-2*Board.Player end
	return Round(Worth,0.01)
end
end
end

--Communicate with main thread
while RUN do
	local Message=ChannelIN:demand()
	if type(Message)=="string" then
		collectgarbage()
	elseif type(Message)=="table" then
		if Message.R==1 then
			local CHILDREN=GetChildren(Message)
			ChannelOUT:push({ConcatBoard(Message),CHILDREN})
			for A,B in ipairs(CHILDREN) do
				ChannelOUT:push({ConcatBoard(B),GetWorth(B)})
			end
		elseif Message.R==2 then
			local CHILDREN=GetChildren(Message)
			local Worthes={}
			local MAXIMA
			for A,B in ipairs(CHILDREN) do
				Worthes[A]=GetWorth(B)
				if not(MAXIMA) or Worthes[A]*Message.Player>MAXIMA*Message.Player then MAXIMA=Worthes[A] end
			end
			for I=#CHILDREN,1,-1 do
				if math.abs(MAXIMA-Worthes[I])>3 then table.remove(Worthes,I) table.remove(CHILDREN,I)
				else ChannelOUT:push({ConcatBoard(CHILDREN[I]),Worthes[I]})
				end
			end
			ChannelOUT:push({ConcatBoard(Message),CHILDREN})
			
		end
	end
end
