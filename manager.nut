/*
	The manager is the brains of the operation and is responsible for what to do next
*/

import("pathfinder.road", "RoadPathFinder", 3);
import("pathfinder.rail", "RailPathFinder", 1);

class Manager{
	function Run();
	function BuildNewRoute(MaximumCost);
	function ManageEvents();
}

function Manager::Run(){
	AILog.Info("MANAGER: New session");
	//This function runs the manager to decide what to do next
	if(AIEventController.IsEventWaiting()){
		Manager.ManageEvents();
		return;
	}
	Manager.BuildNewRoute(Accountant.GetMaxFunds());
}

function Manager::BuildNewRoute(MaximumCost){
	TRY_COUNT++;
	AILog.Info("MANAGER: I need to find the best route possible.");
	//Consult with finance to find the total start up funds we have
	local best_route = Prospector.FindBestRoute(Accountant.GetMaxFunds());
	local max_infra_cost = 0;
	local vehicle_cost = 0;
	
	if(best_route == null){
		//We can't find a good start
		AILog.Warning("MANAGER: I need something better than that.");
		//Go to sleep and try again later
		return false;
	}
	AILog.Info("MANAGER: How much will that cost to provide?");
	vehicle_cost = Engineer.GetProvisionCost(best_route);
	if(vehicle_cost == false){
		AILog.Info("MANAGER: Well that sucks. Nevermind then.");
		return false;
	}
	if(vehicle_cost > Accountant.GetMaxFunds() / 10){
		AILog.Info("MANAGER: That is a little high. Give me a route estimate");
		AILog.Warning("NOTHING HERE");
		return false;
	} else {
		AILog.Info("MANAGER: That's fine by me. Let's get this route built.");
		Accountant.MaximiseFunds();
		best_route = Builder.BuildRoute(best_route);
		
		if(best_route == false){
			AILog.Info("MANAGER: Nevermind. Let's try again.");
			return false;
		}
	}
	AILog.Info("MANAGER: Excellent. Engineer, fill her up!");
	Engineer.AddToRoute(best_route);
	
	Accountant.MinimiseFunds();
	
	return true;
}

function Manager::ManageEvents(){
	while (AIEventController.IsEventWaiting()) {
		local e = AIEventController.GetNextEvent();
		switch (e.GetEventType()) {
			case AIEvent.AI_ET_VEHICLE_CRASHED:
				AILog.Info("MANAGER: A vehicle has crashed!");
				Engineer.ReplaceVehicle(AIEventVehicleCrashed.Convert(e).GetVehicleID());
				break;
			case AIEvent.AI_ET_VEHICLE_LOST:
				AILog.Info("MANAGER: A vehicle has gotten lost!");
				Engineer.RescueVehicle(AIEventVehicleCrashed.Convert(e).GetVehicleID());
		}
	}
}