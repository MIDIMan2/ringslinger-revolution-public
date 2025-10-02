-- Ringslinger Revolution - Global Hooks
-- This script condenses the many MapChange and ThinkFrame functions into one place.

addHook("MapChange", function(_)
	RSR.ConvertItemsMapChange()
	RSR.EnemyThinkersMapChange()
	RSR.WavesMapChange()
	RSR.HUDBossHealthMapChange()
	RSR.HUDHypeMapChange()
	RSR.HUDKillfeedMapChange()
end)

addHook("MapLoad", function(_)
	RSR.ConvertItemsMapLoad()
	RSR.EmeraldsMapLoad()
	RSR.WavesMapLoad()
end)

addHook("ThinkFrame", function()
	if not RSR.GamemodeActive() then return end

	RSR.EnemyThinkersThinkFrame()
	RSR.WavesThinkFrame()
	RSR.HUDBossHealthThinkFrame()
	RSR.HUDHypeThinkFrame()
	RSR.HUDKillfeedThinkFrame()
end)
