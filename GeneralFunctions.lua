
function CopyArray(TABLE,USEDTABLES) if type(TABLE)~="table" then return TABLE end -----Copy(TABLE,false)
	local O={}
	local BOOL=true
	if type(USEDTABLES)=="table" then for A,B in ipairs(USEDTABLES) do
		if TABLE==B then BOOL=false break end
	end end
	if USEDTABLES~=false and BOOL then
		USEDTABLES=USEDTABLES or {}
		table.insert(USEDTABLES,O)
	end
	for A,B in ipairs(TABLE) do
	    if type(B)~="table" or USEDTABLES==false or not(BOOL) then table.insert(O,B)
		else table.insert(O,CopyArray(B,USEDTABLES)) end
	end
	return O
end
--Unpack all images in a given folder into global "Textures" table
function ImageFolder(Folder) if not(Textures) then Textures={} end
 local IMAGES=love.filesystem.getDirectoryItems("Images/"..Folder)
 for _,B in pairs(IMAGES) do
  if love.filesystem.getInfo("Images/"..Folder.."/"..B)["type"]=="directory" then ImageFolder(Folder.."/"..B) end
  if B:sub(-4,-1)==".png" then
   Textures[Folder.."/"..B:sub(1,-5)]=love.graphics.newImage("Images/"..Folder.."/"..B)
   local IM=Textures[Folder.."/"..B:sub(1,-5)]
   if IM then
	IM:setWrap("clampzero","clampzero")
   end
  end
 end
end
--Get a key from a table/array by it's value
function BacktrackTable(Table,Value)
	for A,B in pairs(Table) do
		if B==Value then return A end
	end
end
function BacktrackNum(Table,Value)
	for A,B in ipairs(Table) do
		if B==Value then return A end
	end
end

function Round(Num,Roundation) Roundation=Roundation or 1
	return (Num%Roundation>=0.5*Roundation and math.ceil(Num/Roundation)*Roundation) or math.floor(Num/Roundation)*Roundation
end

