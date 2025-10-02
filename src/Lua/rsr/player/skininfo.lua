-- Ringslinger Revolution - Skin Info

if not RSR.SKIN_INFO then
	---@type rsrskininfo_t[]
	RSR.SKIN_INFO = {}
end

RSR.SKIN_INFO["DEFAULT"] = {
	hooks = {
		touchWeapon = RSR.TouchWeaponDefault,
		touchPowerup = RSR.TouchPowerupDefault,
		touchHealth = RSR.TouchHealthDefault,
		touchArmor = RSR.TouchArmorDefault
	}
}

RSR.SKIN_INFO["amy"] = {
	meleeicon = "RSRHAMMR",
	meleename = "Piko Piko Hammer"
}
