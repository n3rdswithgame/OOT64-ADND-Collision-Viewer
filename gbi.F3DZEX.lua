--[[
	This is an incomplete gbi for the F3DZEX microcode. I have only implemnted
	these the microcodes as I need them. 

	For all of these functions, the first argument (dl) is the mainmemory address
	of the display list to write to. All subsequent arguments are command
	specific.

	basically, if you have a variable dl that points to the end of of your custom 
	display list, you would use `dl = g***(dl, ...)` to append the *** command
	to the end of your display list, where dl is a pointer to the end of the 
	displaylist you wish to append to.

	More information on what each command does can be found at
	http://wiki.cloudmodding.com/oot/F3DZEX/Opcode_Details
--]]


 --includes all of the functions I defined in memory.lua w/o placing them in a module
dofile("memory.lua")

function gDPNoOpTag(dl, tag) 
	writeWord(dl    , 0)
	writeWord(dl + 4, tag)
	return dl+8;
end

function gSPVertex(dl, vaddr, numv, vbidx) 
	writeWord(dl    , 0x01000000 + numv*0x1000 + 2 * bit.band(vbidx + numv , 0x7F));
	writeWord(dl + 4, vaddr);
	return dl+8;
end

function gSP2Trinagles(dl, x1, y1, z1, x2, y2, z2) 
	writeWord(dl    , 0x06000000 + x1 * 0x20000 + y1 * 0x200 + z1 * 2)
	writeWord(dl + 4,              x2 * 0x20000 + y2 * 0x200 + z2 * 2)
	return dl+8;
end

function gSPTexture(dl, scaleS, scaleT, level, tile, on) 
	level = bit.band(level,0x07);
	writeWord(dl    , 0xD7000000 +  (level * 8 + tile) * 0x100 + on)
	writeWord(dl + 4, scaleS * 0x10000 + scaleT)
	return dl + 8;
end

function gSPPopMatrixN(dl, which, num) 
	writeWord(dl    , 0xD8380002)
	writeWord(dl + 4, num * 64)
	return dl + 8
end

function gSPGeometryMode(dl, clear, set) 
	writeWord(dl    , bit.bor(0xD9000000 , bit.band( bit.bnot(clear) , 0x00FFFFFF)))
	writeWord(dl + 4, set)
	return dl + 8;
end

function gSPMatrix(dl, mtxaddr, params)
	writeWord(dl    , 0xDA380000 + bit.bxor(params , 0x01))
	writeWord(dl + 4, mtxaddr)
	return dl + 8;
end

function gSPDisplayList(dl, branchTo) 
	writeWord(dl    , 0xDE000000)
	writeWord(dl + 4, bit.band(branchTo , 0x00FFFFFF))
	return dl + 8;
end

function gSPEndDisplayList(dl) 
	writeWord(dl    , 0xDF000000)
	writeWord(dl + 4, 0)
	return dl + 8;
end

function gSPSetOtherMode(dl, opcode, shift, lenght, data)
	writeWord(dl    , opcode * 0x1000000 + (32 - shift - length) * 0x100 + (length - 1))
	writeWord(dl + 4, data)
	return dl + 8;
end

function gsSPSetOtherModeLo(dl, shift, lenght, data) 
	return gSPSetOtherMode(dl, 0xE2, shift, lenght, data)
end

function gsSPSetOtherModeHi(dl, shift, lenght, data) 
	return gSPSetOtherMode(dl, 0xE3, shift, lenght, data)
end

function gDPPipeSync(dl) 
	writeWord(dl    , 0xE7000000)
	writeWord(dl + 4, 0)
	return dl + 8
end

function gDPSetCombineLERP_G_CC_SHADE_G_CC_SHADE(dl) 
	writeWord(dl    , 0xFC000000)
	writeWord(dl + 4, 0x00020909)
	return dl + 8;
end

function gDPSetDepthImage(dl, imgaddr) 
	writeWord(dl    , 0xFE000000)
	writeWord(dl + 4, imgaddr)
	return dl + 8;
end

function gDPSetColorImage(dl, fmt, siz, width, imgaddr) 
	writeWord(dl    , 0xFF00000000 + (bit.bor(fmt * 32, siz * 8) )*0x10000 + (width - 1))
	writeWord(dl + 4, imgaddr)
	return dl + 8
end