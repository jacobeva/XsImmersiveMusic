// put cba debug setting stuff here

if (isMultiplayer) then // if client is in multiplayer
{
	if (hasInterface) then
	{
        [
            "XIM_bNowPlayingEnabled", // the name of the variable which the output from the slider is assigned to
            "CHECKBOX", // interactive slider setting type
            ["Enable 'Now Playing' UI", "Enable or disable the UI which displays the song currently playing when it starts."], // name and tooltip for the setting
            ["XIM - X's Immersive Music", "UI elements"], // category the setting is in
            [true], // default value of true
            nil, // disables synchronising the XIM_bNowPlayingEnabled variable across clients, as it is not needed
            {} // executes nothing when the setting is changed, as it is not necessary
        ] call cba_settings_fnc_init;
		execVM "\XIM_Core\scripts\multiplayer\client.sqf"; // executes client.sqf
	};
	
	if (isServer) then // runs on the dedicated server, or player host, either way it runs on machine id 2
	{
        [
            "XIM_iCombatRange", // the name of the variable which the output from the slider is assigned to
            "SLIDER", // interactive slider setting type
            ["AI detection range", "The maximum range that AI can be from the player to instigate combat."], // name and tooltip for the setting
            ["XIM - X's Immersive Music", "Combat variables"], // category the setting is in, plus a subcategory
            [500, 2000, 500, 0], // minimum of 500, maximum of 2000, default of 500, no decimals
            nil, // disables synchronising the XIM_iCombatRange variable across clients, as it is not needed
            {} // executes nothing when the setting is changed, as it is not necessary
        ] call cba_settings_fnc_init;
        [
            "XIM_iCombatRefreshTime", // the name of the variable which the output from the slider is assigned to
            "SLIDER", // interactive slider setting type
            ["Combat refresh time", "How often to check if the player is still in combat (in seconds)."], // name and tooltip for the setting
            ["XIM - X's Immersive Music", "Combat variables"], // category the setting is in
            [1, 300, 120, 0], // minimum of 1, maximum of 300, default of 500, no decimals
            nil, // disables synchronising the XIM_iCombatRefreshTime variable across clients, as it is not needed
            {} // executes nothing when the setting is changed, as it is not necessary
        ] call cba_settings_fnc_init;

		execVM "\XIM_Core\scripts\multiplayer\server.sqf"; // executes server.sqf
	};
} 
else // if client is in singleplayer
{
	execVM "\XIM_Core\scripts\singleplayer\client.sqf"; // executes client.sqf
};