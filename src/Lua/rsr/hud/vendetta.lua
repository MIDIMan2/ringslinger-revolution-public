-- Ringslinger Revolution - Flag Radar HUD

local RSR_DOVENDETTA = 0
local RSR_VENDETTADELAY = 0
local RSR_VENDETTATICKER = 0
local RSR_PINGTABLE = {}
local RSR_VDTRESULTS = {}

addHook("NetVars", function(network)
  RSR_DOVENDETTA = network($)
  RSR_VENDETTADELAY = network($)
  RSR_VENDETTATICKER = network($)
  RSR_PINGTABLE = network($)
  RSR_VDTRESULTS = {}
end)

--- Allows the Vendetta Monitor to call the ping function.
A_RSRVendettaPing = function(var1, var2)
	RSR_DOVENDETTA = var1+1
	RSR_VENDETTADELAY = var2
	RSR_VENDETTATICKER = 0
	RSR_PINGTABLE = {}
	RSR_VDTRESULTS = {}
end

--- Pings everything on the map a few times over a few seconds when a Vendetta Monitor is popped.
---@param v videolib
---@param player player_t
---@param thiscam camera_t
---@param target mobj_t Object to ping.
RSR.HUDVendettaPing = function(v, player, thiscam, target)
	if not (v and Valid(player) and Valid(player.realmo) and Valid(target)) then return false end

	if RSR_DOVENDETTA > 0 then
		if RSR_VENDETTATICKER < 1 then
			S_StartSound(player.mo, sfx_buzz3, player)
			RSR_DOVENDETTA = $ - 1
			RSR_VENDETTATICKER = RSR_VENDETTADELAY
			RSR_PINGTABLE = {}
			RSR_VDTRESULTS = {}
			for mo in mobjs.iterate() do
				if mo.type == MT_PLAYER then
					table.insert(RSR_PINGTABLE, {type = mo.type, x = mo.x, y = mo.y, z = mo.z})
				end
			end
		else
			-- Shout-outs to Lunewulff, Skydusk, and MRCE for the (original) R_World2Screen3 function
			for i in #RSR_PINGTABLE do
				table.insert(RSR_VDTRESULTS, R_World2Screen3FPS(i, v, player, thiscam, {x = RSR_PINGTABLE[i].x, y = RSR_PINGTABLE[i].y, z = RSR_PINGTABLE[i].z}))
			end
			for i in #RSR_VDTRESULTS do
				local minScale, maxScale = FRACUNIT/32, FRACUNIT/8
				if RSR_VDTRESULTS[i] and RSR_VDTRESULTS[i].onScreen then
					if not P_CheckSight(player.realmo, target) then
						minScale, maxScale = FRACUNIT/16, FRACUNIT/4
					end
					if RSR_VDTRESULTS[i].scale > maxScale then return false end
					local transScale = 0
					if RSR_VDTRESULTS[i].scale > minScale then
						transScale = FixedDiv(RSR_PINGTABLE[i].scale - minScale, maxScale - minScale)
					end
					-- R_World2Screen3 automatically adjusts for splitscreen, so roughly undo the adjustments
					if splitscreen then result.y = $*2 + (v.height()/v.dupy() - 200)*FRACUNIT/2 end
					local flagPatch = "RFLAGICO"
					local transFlag = FixedMul(9, min(transScale, FRACUNIT))*V_10TRANS
					flagPatch = v.cachePatch($)
					v.drawCropped(
						result.x - 46*result.scale,
						result.y - 31*result.scale,
						2*max(FRACUNIT/32, result.scale),
						2*max(FRACUNIT/32, result.scale),
						flagPatch,
						V_PERPLAYER|transFlag,
						nil,
						0,
						0,
						flagPatch.width*FRACUNIT,
						flagPatch.height*FRACUNIT
					)
					return true
				end
			end
		end
	else
		RSR_DOVENDETTA = 0
		RSR_VENDETTADELAY = 0
		RSR_VENDETTATICKER = 0
		RSR_PINGTABLE = {}
		RSR_VDTRESULTS = {}
	end
end