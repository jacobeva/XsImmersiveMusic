// This script is executed on either the player host (non-dedicated) or a dedicated server


// Below is the creation of arrays, that contain classnames of music tracks defined in config.cpp, randomized to make it fresh each time;
aCombatMusicClassnames = "'intense' in getArray (_x >> 'moods') " configClasses (configFile >> "CfgMusic") apply {configName _x} call BIS_fnc_arrayShuffle;
aDarkMusicClassnames = "'dark' in getArray (_x >> 'moods') " configClasses (configFile >> "CfgMusic") apply {configName _x} call BIS_fnc_arrayShuffle;
aCalmMusicClassnames = "'calm' in getArray (_x >> 'moods') " configClasses (configFile >> "CfgMusic") apply {configName _x} call BIS_fnc_arrayShuffle;



if (isDedicated) then {
  ["initialize",[aDarkMusicClassnames,aCombatMusicClassnames,aCalmMusicClassnames]] remoteExecCall ["BIS_fnc_jukebox",-2,true]; //Init jukebox on clients + JIP
} else {
  ["initialize",[aDarkMusicClassnames,aCombatMusicClassnames,aCalmMusicClassnames]] remoteExecCall ["BIS_fnc_jukebox",0,true]; //Init jukebox globally + JIP
};

// ======================================== FUNCTIONS ========================================

XIM_fncSendIDs = 
{
	params["_aPlayerMachineIDs"]; // defines the parameter _aPlayerMachineIDs in position zero
	XIM_aStateChange = []; // defines XIM_aStateChange, which is an empty array
	XIM_aStateChange append [_aPlayerMachineIDs]; // adds the _aPlayerMachineIDs array to XIM_aStateChange at position zero
	XIM_aStateChange append true; // adds true to the XIM_aStateChange array at position one
	publicVariableServer [XIM_aStateChange]; // sends the XIM_aStateChange variable to the server via its namespace
	XIM_aStateChange = nil; // destroys the XIM_aStateChange variable
};

XIM_fncMonitorPlayers = // this function gets the machine IDs of all players within a 500m radius of the argument, calls XIM_fncSendIDs with the array of the players
						// as the argument and then checks all of the players within 500m of the argument again every 5 seconds. 
						// if a new player has entered the 500m radius, then XIM_fncSendIDs is called, with the array containing the latest player machine IDs as the
						// argument.
{
	params["_oPlayer"]; // defines the parameter _oPlayer in position zero
	private _bUpdateCombat = false; // defines the _bUpdateCombat variable, which is false by default
	private _aPlayerMachineIDs = []; // defines the array _aPlayerMachineIDs, which is empty
	{
		if (_oPlayer distance _x <= 500) then // if the distance between the player currently being iterated in the outermost loop and the player currently being iterated in the innermost loop is less than or equal to 500
		{
			private _iPlayerID = owner _x; // assign _iPlayerID to the machine ID of the player who is selected
			_aPlayerMachineIDs pushBack _iPlayerID; // add the player's machine ID to the _aPlayerMachineIDs array
		};
	} forEach allPlayers - entities "HeadlessClient_F"; // for every player, except headless clients

	_aPlayerMachineIDs sort false; // sort _aPlayerMachineIDs in ascending order
	[_aPlayerMachineIDs] call XIM_fncSendIDs; // call XIM_fncSendIDs with the argument _aPlayerMachineIDs

	[_aPlayerMachineIDs, _oPlayer] spawn
	{
		params ["_aPlayerMachineIDs", "_oPlayer"];
		waitUntil // loop until the value true is returned
		{
			private _bUpdateCombat = false;
			sleep 5; // wait 5 seconds
			if (_oPlayer getVariable ["XIM_bCombat"] == false) exitWith {true}; // if the player is no longer in combat, exit the loop
			{
				_aRecentPlayerMachineIDs = []; // declares _aRecentPlayerMachineIDs, which is an empty array
				if (_oPlayer distance _x <= 500) then // if the distance between the player currently being iterated in the outermost loop and the player currently being iterated in the innermost loop is less than or equal to 500
				{
					private _iPlayerID = owner _x; // assign _iPlayerID to the machine ID of the player who is selected
					_aRecentPlayerMachineIDs pushBack _iPlayerID; // add the player's machine ID to the _aPlayerMachineIDs array
				};
			} forEach allPlayers - entities "HeadlessClient_F"; // for every player, except headless clients
			_aRecentPlayerMachineIDs sort false; // sort _aRecentPlayerMachineIDs in ascending order
			if (_aPlayerMachineIDs != _aRecentPlayerMachineIDs) then // if the arrays are not completely identical
			{
				{
					_iRecentMachineID = _x; // assign the currently selected machine ID to _iRecentMachineID, so it can be used in a findIf
					if (!(_aPlayerMachineIDs findIf {_x  = _iRecentMachineID})) then // if the selected ID from the _aRecentPlayerMachineIDs array is not in _aPlayerMachineIDs
					{
						_bUpdateCombat = true; // then change _bUpdateCombat to true
					};
				} forEach _aRecentPlayerMachineIDs // for every entry in the _aRecentPlayerMachineIDs array
			};
			if (_bUpdateCombat) then // if _bUpdateCombat is true
			{
				[_aRecentPlayerMachineIDs] call XIM_fncSendIDs; // call the XIM_fncSendIDs function with the argument _aRecentPlayerMachineIDs
			};
			_aPlayerMachineIDs = _aRecentPlayerMachineIDs; // set the value of _aPlayerMachineIDs to _aRecentPlayerMachineIDs
			false;
		};
	};
};

XIM_fncIteratePlayerCombat = // defines the XIM_fncIteratePlayers function, which iterates through each player and determines if they are in combat
{
	params ["_oFiringAI", "_oPlayer"]; // defines _oFiringAI, which is the object of the AI who fired
	private _aPlayerMachineIDs = []; // defines _aPlayerMachineIDs, which is an empty array

	if (_oPlayer getVariable ["XIM_bCombat"] == false) then // if the client is not already in combat
	{
		if (alive _oPlayer) then // if the player is not dead
		{
			if (_oPlayer distance _oFiringAI <= 500) then // if the distance to the AI who is firing is less than or equal to 500 metres
			{
				private _iPlayerID = owner _oPlayer; // finds the player's machine ID, and assigns the value to _iPlayerID
				_iPlayerID publicVariableClient ["XIM_bCombat", true]; // set the player's combat variable to true
			};
		};

		if (_oPlayer getVariable ["XIM_bCombat"] == true) then // if the player entered combat after previously not being in combat
		{
			private _oPlayer = _x;
		};
	};
	_aPlayerMachineIDs sort true; // sort the array in ascending order, and return the array
};

fncXIM_MusicHandler = { // defines the fncXIM_MusicHandler function, which disables ace's volume interference for the group, plays a certain type of music based on the parameter, and then reenables ace's volume interference for that same group
	params ["_aXIMPlayers","_musictype"];

	missionNameSpace setVariable ["ace_hearing_disableVolumeUpdate",true,_aXIMPlayers]; //Disable ACE interference
	["forceBehaviour",[_musictype]] remoteExecCall ["BIS_fnc_jukebox",_aXIMPlayers]; //Changes music type based on passed parameter
	[{missionNameSpace setVariable ["ace_hearing_disableVolumeUpdate",false,_aXIMPlayers];},[], 15] call CBA_fnc_waitAndExecute; //Wait 15 seconds, then enable ACE Volume Update again (earplugs, deafened,...)
};


fncXIM_MusicRemote = {
	params ["_aXIMPlayers", "_bXIMCombatState"]; //Defining params
	if (_bXIMCombatState) then {

		[_aXIMPlayers,"combat"] spawn fncXIM_MusicHandler; //Set music to type combat
			
	} else {
		private _sunrisesunset = date call BIS_fnc_sunriseSunsetTime;
		private _sunrise = _sunrisesunset select 0;
		private _sunset = _sunrisesunset select 1;

		if ((rain > 0.2) or (fog > 0.2) or ((daytime > _sunset) and (daytime < _sunrise))) then {

			[_aXIMPlayers,"stealth"] spawn fncXIM_MusicHandler; //Set music to type stealth (dark)
  			
		} else {

  			[_aXIMPlayers,"safe"] spawn fncXIM_MusicHandler; //Set music to type safe

		};

	};	
};

// ======================================== EVENT HANDLERS ========================================
onPlayerConnected // when a player connects
{
	XIM_bCombat = false; // declare XIM_bCombat, which is a variable to determine if the player is in combat or not
	_owner publicVariableClient "XIM_bCombat"; // broadcast the XIM_bCombat variable, with the default value of false
	XIM_bCombat = nil; // destroy the XIM_bCombat variable, as it is no longer needed
};

["ace_firedNonPlayer", [this select 0] call XIM_fncIteratePlayer] call CBA_fnc_addEventHandler; // adds event handler for when an AI fires

"XIM_aStateChange" addPublicVariableEventHandler 
{
	private _aXIMstatechange = _this select 1; //Store array in variable
	private _aXIMPlayers = _aXIMstatechange select 0; //Retrieve network ID's
	private _bXIMCombatState = _aXIMstatechange select 1; //Retrieve combat state for those network ID's
	
	[_aXIMPlayers,_bXIMCombatState] call fncXIM_MusicRemote;
};


"XIM_oSender" addPublicVariableEventHandler 
{
	private _oXIMSender = _this select 1; //Store array in variable
	private _senderID = owner _oXIMSender;
	ximnearestenemy = _oXIMSender findNearestEnemy _oXIMSender;


	XIM_oEnemy = ximnearestenemy; //Assign to missionNamespace var
	_senderID publicVariableClient "XIM_oEnemy";
};