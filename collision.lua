--[[
This file contains the core of the collision viewing
--]]


dofile("memory.lua")
dofile("gbi.F3DZEX.lua")




local global_context = 0x0 --http://wiki.cloudmodding.com/oot/Global_Context
local current_scene = 0x0 -- current scene index

--There seem to be a few different pointers to the scene header
--I took 3 and labeled them based on how quickly they update
--during a map transition. 
local scene_fast = 0x0
local scene_slow = 0x0
local scene_med = 0x0

local fadeoutTimer = 0x0

local COLLISION_DLIST = 0x0;
local COLLISION_DLIST_END = COLLISION_DLIST;
local VERTEX_ARRAY = 0x0;
local VERTEX_ARRAY_END = VERTEX_ARRAY;

local clearZBufferDL = 0x0

local toDraw = {}

toDraw["scene"] = 0
for i = 0,49 do
	toDraw[i] = 0
end


function initOoT()
	global_context = 0x801C84A0
	current_scene = 0x801C8545

	scene_fast = 0x801d9c48
	scene_slow = 0x8018898c
	scene_med = 0x8016a67c

	fadeoutTimer = 0x801DA671

	COLLISION_DLIST = 0x80500000;
	COLLISION_DLIST_END = COLLISION_DLIST;
	VERTEX_ARRAY = 0x80400000;
	VERTEX_ARRAY_END = VERTEX_ARRAY;

	clearZBufferDL = 0x800f8440 --LOL, just stole this from the room chane blakc plane. Should probably figure out why it works
end

function initMM()
	global_context = 0x80
	current_scene = 0x80

	--[[scene_fast = 0x801d9c48
	scene_slow = 0x8018898c
	scene_med = 0x8016a67c--]]

	fadeoutTimer = 0 --TODO: find

	COLLISION_DLIST = 0 --TODO: either find or create fake heap node to create a buffer
	COLLISION_DLIST_END = COLLISION_DLIST;
	VERTEX_ARRAY = 0 --TODO: either find or create fake heap node to create a buffer
	VERTEX_ARRAY_END = VERTEX_ARRAY;

	clearZBufferDL = 0 -- TODO: find
end

--global_context +0x00 is a ptr to graphics_context
function graphicsContext()
	return readWord(global_context)
end

function scene()
	return readWord(scene_fast)
end

function getSceneCollisionHdrAddr()
	return readWord(global_context + 0x7c0) -- global_context pointer to scene collision header
end

function getCollisionHeader(coll_header_addr)
	local header = {}
	header["xmin"] = readShort(coll_header_addr)
	header["ymin"] = readShort(coll_header_addr + 0x02)
	header["zmin"] = readShort(coll_header_addr + 0x04)
	header["xmax"] = readShort(coll_header_addr + 0x06)
	header["ymax"] = readShort(coll_header_addr + 0x08)
	header["zmax"] = readShort(coll_header_addr + 0x0A)
	header["vertexNum"] = readHWord(coll_header_addr + 0x0C)
	header["verticies"] = readWord( coll_header_addr + 0x10)
	header["polyNum"] = readHWord(coll_header_addr + 0x14)
	header["polies"] = readWord(coll_header_addr + 0x18)
	header["polyTypes"] = readWord( coll_header_addr + 0x1C)
	return header
end

getCollisionHeader(getSceneCollisionHdrAddr())

function getVertexArray(collisionHdrAddr)
	local header = getCollisionHeader(collisionHdrAddr)
	local vertex_ary = header["verticies"]
	local vertex_num = header["vertexNum"]
	local verticies = {}
	verticies[-1] = vertex_num - 1
	for i=0,vertex_num-1 do
		verticies[i] = {readShort(vertex_ary),readShort(vertex_ary + 0x2),readShort(vertex_ary + 0x4)}
		vertex_ary = vertex_ary + 0x6
	end
	return verticies
end

function getPolyArray(collisionHdrAddr)
	local header = getCollisionHeader(collisionHdrAddr)
	local poly_ary = header["polies"]
	local poly_num = header["polyNum"]
	local polies = {}
	polies[-1] = poly_num-1
	for i=0,poly_num-1 do
		polies[i] = {readShort(poly_ary),readShort(poly_ary + 0x2),
			readShort(poly_ary + 0x4),readShort(poly_ary + 0x6),
			readShort(poly_ary + 0x8),readShort(poly_ary + 0xA),
			readShort(poly_ary + 0xC),readShort(poly_ary + 0xE)}
		poly_ary = poly_ary + 0x10
	end
	return polies
end

function getTriangles(collisionHdrAddr)
	local verticies = getVertexArray(collisionHdrAddr)
	local polies = getPolyArray(collisionHdrAddr)
	local triangles = {}
	triangles[-1] = polies[-1]
	for i=0,polies[-1] do
		triangles[i] = {}
		triangles[i][1] = verticies[bit.band(polies[i][2], 0xFFF)]
		triangles[i][2] = verticies[bit.band(polies[i][3], 0xFFF)]
		triangles[i][3] = verticies[bit.band(polies[i][4], 0xFFF)]
	end

	return triangles
end

function hookPOLY_XLU_DISP(dlist)
	local polyAddr = graphicsContext() + 0x2D0
	local poly_app = readWord(polyAddr)
	writeWord(poly_app, 0xDE000000)
	writeWord(poly_app + 4, dlist)
	writeWord(polyAddr ,poly_app + 8)
end

function writeVertex(vaddr, vertex)

	writeShort(vaddr       , vertex[1]) 			-- x coord
	writeShort(vaddr + 0x02, vertex[2]) 			-- y coord
	writeShort(vaddr + 0x04, vertex[3]) 			-- z coord
	writeShort(vaddr + 0x06, 0)						-- blank
	writeShort(vaddr + 0x08, 0)						-- s coord
	writeShort(vaddr + 0x0A, 0)						-- t coord
	writeByte (vaddr + 0x0C, math.random(256)-1)	-- r
	writeByte (vaddr + 0x0D, math.random(256)-1)	-- g
	writeByte (vaddr + 0x0E, math.random(256)-1)	-- b
	writeByte (vaddr + 0x0F, 0xFF)					-- a

	return vaddr + 0x10
end

function drawTriangles(addrs, tries)

	local dl = addrs[1]
	local vaddr = addrs[2]

	math.randomseed(420)

	numTries = tries[-1]
	print(numTries)
	print(table.getn(tries))
	for i=1,numTries do
		if tries[i] ~= nil then
			vaddr = writeVertex(vaddr, tries[i][1])
			vaddr = writeVertex(vaddr, tries[i][2])
			vaddr = writeVertex(vaddr, tries[i][3])
			dl = gSPVertex(dl, vaddr, 6, 0)
			dl = gSP2Trinagles(dl, 0, 1, 2, 0, 2, 1) --draw with both orientations to prevent backface culling
		end
	end



	return {dl, vaddr}
end


function generateDList()
	local dl = COLLISION_DLIST
	local vaddr = VERTEX_ARRAY

	dl = gDPPipeSync(dl)

	dl = gSPDisplayList(dl, clearZBufferDL) -- clear z-buffer by using premade d-list used by room change actors

	dl = gDPPipeSync(dl)

	dl = gSPMatrix(dl, vaddr , 0x03)
	for i=0,3 do
		for j = 0,3 do
			if(i==j) then
				writeShort(vaddr + 2*(4*i+j),1)
			else
				writeShort(vaddr + 2*(4*i+j),0)
			end
		end
	end

	for i=0,3 do
		for j = 0,3 do
			writeShort(vaddr + 0x20 + 2*(4*i+j),0)
		end
	end
	vaddr = vaddr + 0x40

	dl = gSPTexture(dl,0,0,0,0,0)
	dl = gSPGeometryMode(dl, 0xeF0000, 0x200005)
	
	dl = gDPSetCombineLERP_G_CC_SHADE_G_CC_SHADE(dl);

	local addrs = {dl, vaddr}

	print("finding tries")
	local tries = getTriangles(getSceneCollisionHdrAddr())
	print("found tries")
	addrs = drawTriangles(addrs, tries)

	dl = addrs[1]
	vaddr = addrs[2]


	dl = gSPPopMatrixN(dl,0,1)
	dl = gSPEndDisplayList(dl)

	COLLISION_DLIST_END = dl
	print(string.format("%x",COLLISION_DLIST_END))
end

memory.usememorydomain("RDRAM")



local timer = 0
local reDraw = 0
local startDrawing = 0
function hook()
	--local inputs = joypad.getimmediate()
	--print(inputs["Power"])
	--print(inputs["Reset"])

	gSPEndDisplayList(COLLISION_DLIST_END)
	
	if readByte(0x800FE49C) ~= 0x80 then
		--print("ovl_player_acotr not loaded, not running")
		return
	end
	
	hookPOLY_XLU_DISP(COLLISION_DLIST)
end


function validScene()

	--checks for a power cycle
	if readWord(bit.band(current_scene,0xFFFFFFFC)) == 0 then
		return false
	end

	local scene = readByte(current_scene)

	if scene == 0x00 then-- deku
		return true
	end

	if scene == 0x01 then-- dc
		return true
	end

	if scene == 0x02 then-- jabu
		return true
	end

	if scene == 0x03 then-- forest
		return true
	end
	
	if scene == 0x04 then-- fire
		return true
	end
	
	if scene == 0x05 then-- water
		return true
	end
	
	if scene == 0x06 then-- spirit
		return true
	end
	
	if scene == 0x07 then-- shadow
		return true
	end
	
	if scene == 0x08 then-- botw
		return true
	end

	if scene == 0x0A then--ganon's tower climb
		return true
	end

	if scene == 0x0D then-- ganon's castle
		return true
	end
	
	return false
end

local hookID
local enabled = false
--event.onmemorywrite(hook, 0x801DAA54) -- link's x coord

function enableCollision()
	enabled = true
	reDraw = 1
	timer = 2
	hookID = event.onmemorywrite(hook,  0x801DAA54, "drawing")
	--hookID = event.oninputpoll(hook, "drawing")
end

--[[function disableCollision()
	event.unregisterbyname("drawing")
	drawing = 0
	enabled = false
	event.unregisterbyid(hookID)
end


function check()
	if enabled then
		if not validScene() then
			print("disabling collision")
			disableCollision()
		end

		if readByte(0x800FE49C) ~= 0x80 and readByte(0x800FE480) ~= 0x80 and readByte(global_context) ~= 0x80 then
			print("power cycle")
			disableCollision()
			end
		return

	else
		if validScene() then --and readByte(fadeoutTimer) < 4 then
			generateDList()
			drawing = 1
			print("enabling collision")
			enableCollision()
		end
	end

end--]]

initOoT()

generateDList()
drawing = 1
print("enabling collision")
enableCollision()

print(graphicsContext())

while true do
	--hook()
	emu.frameadvance()
	--check()	
	--hookPOLY_OPA_DISP(dlist,0x80600000)
end