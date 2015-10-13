class JAMI extends AIController {
	function Start();
	function Load();
	function NameGenerator();
	
	//Declare any constants here
	SUBSIDY_SAFETY = 1;					//How many days we should allow for each tile of distance
	MINIMUM_TRAIN_DISTANCE = 30;		//How many tiles have to be passed before a train line should be considered
	MINIMUM_TRAIN_POPULATION = 1000;	//The size a town should be before a train is considered
	MAXIMUM_PATH_TRIES = 100;			//How many times I should try to find a path
	DISTANCE_FROM_DEPOT = 20;			//How far a station can be from a depot before ordering a new one
	INCIDENTAL_MAX = 5000;				//Maximum expenditure on incidental costs, like connecting road depots
	DISTANCE_FROM_TOWN = 10;			//How far to look from the centre of a town for a nearby station
	MINIMUM_SAFE_BALANCE = 100000;		//The least we should have in the bank account
	TRY_COUNT = 0;						//How many times we've tried to find a route - expands the longer JAMI has been running
	
	AUTORENEW_MONTHS = 24;
	AUTORENEW_MONEY = 100000;
	
	//Information
	OM_NAME = "JAMI";
	OM_VERSION = 0;
	
	//Considerations
	MAX_BRIDGE_LENGTH = 20;				//How big is the biggest bridge?
	DELAY = 100							//How long to wait per loop
	
	constructor() {
		require("structures.nut");
		require("manager.nut");
		require("administrator.nut");
		require("accountant.nut");
		require("prospector.nut");
		require("builder.nut");
		require("engineer.nut");
	}
	
}

function JAMI::Start(){
	while(AICompany.SetName(JAMI.NameGenerator()) == false);
	AILog.Info(AICompany.GetName(AICompany.COMPANY_SELF) + " has been founded");
	AILog.Warning("ADMINISTRATOR: Using TrueAncestors GetBestCargo algorithm");
	
	AICompany.SetAutoRenewMonths(AUTORENEW_MONTHS);
	AICompany.SetAutoRenewMoney(AUTORENEW_MONEY);
	AICompany.SetAutoRenewStatus(true);
	
	while (true) {
		Manager.Run();
		this.Sleep(DELAY);
	}
}

function JAMI::NameGenerator(){
	local J = JAMI.PickLetter("J");
	
	local M = JAMI.PickLetter("M");
	local I = JAMI.PickLetter("I");
	return J + "and " + M + I;
}

function JAMI::PickLetter(theLetter){
	if(theLetter == "J"){
		local js = ["Jolly ", "Jaunty ", "John "];
		return js[AIBase.RandRange(js.len())];
	}
	if(theLetter == "M"){
		local js = ["Moribund ", "Moose ", "Moron "];
		return js[AIBase.RandRange(js.len())];
	}
	if(theLetter == "I"){
		local js = ["Industries", "Incorporated", "Integrated"];
		return js[AIBase.RandRange(js.len())];
	}
}