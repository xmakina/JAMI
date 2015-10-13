/*
 *	The engineer is responsible for pricing and buying vehicles
 */
 
class Engineer{
	function RecommendEngine(route);
	function GetProvisionCost(route);
	function AddToRoute(route);
	function ReplaceVehicle(vehicleid);
	function RescueVehicle(vehicleid);
}

function Engineer::RecommendEngine(route){
	//Work out how much it will cost to get the most effective vehicles on this route
	local engine_list = null;
	local chosen_engine = null;
	local total_cost = null;
	
	if(route.isfreight == false){
		if(route.stationtype == AIStation.STATION_BUS_STOP){
			local passengercargoid = route.cargo;
			
			
			engine_list = AIEngineList(AIVehicle.VT_ROAD);
			
			engine_list.Valuate(AIEngine.GetRoadType)
			engine_list.KeepValue(AIRoad.ROADTYPE_ROAD);
			
			engine_list.Valuate(AIEngine.GetCargoType);
			engine_list.KeepValue(passengercargoid);
			
			if(route.distance > MINIMUM_TRAIN_DISTANCE / 2){
				//Long distance bus route
				engine_list.Valuate(AIEngine.GetMaxSpeed);
				chosen_engine = engine_list.Begin();
			} else {
				//Short distance bus route
				engine_list.Valuate(AIEngine.GetCapacity);
				chosen_engine = engine_list.Begin();
			}
		} else {
			//Is a train or plane or even a dock!
			AIEngineer.Warning("ENGINEER: I can't work with other passenger services");
			return false;
		}
	} else {
		if(route.stationtype == AIStation.STATION_TRUCK_STOP){
			//Work out what truck to send back
			engine_list = AIEngineList(AIVehicle.VT_ROAD);
			engine_list.Valuate(AIEngine.CanRefitCargo, route.cargo);
			engine_list.KeepValue(1);
			
			if(engine_list.IsEmpty()){
				AILog.Warning("ENGINEER: I can't move " + AICargo.GetCargoLabel(route.cargo));
				return false;
			}
			engine_list.Valuate(AIEngine.GetMaxSpeed);
			chosen_engine = engine_list.Begin();
		} else {
			AIEngineer.Warning("ENGINEER: I can't work with other freight services");
			return false;
		}
		
	}
	AILog.Info("ENGINEER: I'm going to suggest the " + AIEngine.GetName(chosen_engine));
	return chosen_engine;
}

function Engineer::GetProvisionCost(route){
	local engine = Engineer.RecommendEngine(route);
	if(engine == false){
		return false;
	}
	local total_cost = AIEngine.GetPrice(engine);
	AILog.Info("ENGINEER: That will cost " + total_cost);
	return total_cost;
}

function Engineer::AddToRoute(route){
	//Add a new vehicle to the selected route
	AILog.Info("ENGINEER: Adding a vehicle to the route");
	local startflags = AIOrder.AIOF_NONE;
	local endflags = AIOrder.AIOF_NONE;
	
	//If there isn't a depot within 20 tiles then build a new one
	local depot = Builder.BuildDepot(route.source, route.stationtype)
	if(depot == false){
		AILog.Warning("ENGINEER: Could not add a vehicle to this route");
		return false;
	}
	
	local vehicle = AIVehicle.BuildVehicle(depot, Engineer.RecommendEngine(route));
	AIVehicle.RefitVehicle(vehicle, route.cargo);
	
	if(vehicle == false){
		switch(AIError.GetLastError()){
			case AIError.ERR_NOT_ENOUGH_CASH:
				if(Accountant.GetMoreCash()){
					vehicle = AIVehicle.BuildVehicle(depot, Engineer.RecommendEngine(route));
				}
				break;
			default:
				AILog.Warning("ENGINEER: I hit an unknown error - " + AIError.GetLastErrorString());
				return false;
				break;
		}
	}
	
	if(route.isfreight){
		startflags = AIOrder.AIOF_FULL_LOAD;
	} else {
		endflags = AIOrder.AIOF_FULL_LOAD;
	}
	
	if(AIOrder.AppendOrder(vehicle, route.source, startflags) == false){
		AILog.Warning("ENGINEER: Could not find source station");
		return false;
	}
	if(AIOrder.AppendOrder(vehicle, route.destination, endflags) == false){
		AILog.Warning("ENGINEER: Could not find destination station");
		return false;
	}
	
	AIVehicle.StartStopVehicle(vehicle);
}

function Engineer::ReplaceVehicle(vehicleid){
	AILog.Info("ENGINEER: Replacing vehicle " + vehicleid);
	
	local depotlist = null;
	
	switch(AIVehicle.GetVehicleType(vehicleid)){
		case AIVehicle.VT_ROAD:
			depotlist = AIDepotList(AITile.TRANSPORT_ROAD);
			break;
		default:
			AILog.Warning("ENGINEER: I can't handle this kind of vehicle");
			return false;
			break;
	}
	//Find the nearest depot to the vehicles starting station
	depotlist.Valuate(AIMap.DistanceManhattan, AIOrder.GetOrderDestination(vehicleid, 0));
	depotlist.KeepBottom(1);
	AIVehicle.StartStopVehicle(AIVehicle.CloneVehicle(depotlist.Begin(), vehicleid, true));
}

function Engineer::RescueVehicle(vehicleid){
	switch(AIVehicle.GetVehicleType(vehicleid)){
		case AIVehicle.VT_ROAD:
			local totalorders = AIOrder.GetOrderCount(vehicleid);
			local count = 0;
			for(count; count < totalorders; count++){
				
			}
			break;
		default:
			AILog.Warning("ENGINEER: I can't handle that vehicle type");
	}
}