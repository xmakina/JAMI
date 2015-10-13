/*
 *	The builder is responsible for constructing the various routes
 */

class Builder{
	function BuildRoute(route);
	function BuildRoad(start, end);
	function BuildRoadStation(site, destination, stationtype);
	function BuildDepot(destination, stationtype);
	function RemoveRoadStation(site);
	function ClearSpace(site, width, height, radius);
}

function Builder::BuildRoute(route){
	//This constructs a route using supplied information
	AILog.Info("BUILDER: Constructing a new route");
	local start = route.source;
	local end = route.destination;
	local result = null;
	local buildstart = true;
	local buildend = true;
	
	//See if there are any new nearby stations, otherwise find somewhere to build stations
	start = Prospector.FindStationSite(start, route.stationtype);
	end = Prospector.FindStationSite(end, route.stationtype);
	
	if(!start || !end){
		return false;
	}
	
	route.source = start;
	route.destination = end;
	
	if(AITile.IsStationTile(start) && AITile.IsStationTile(end)){
		//We have two existing stations. Are they connected?
		AILog.Info("BUILDER: Stations already built");
		if(Administrator.IsStationConnected(start, end)){
			AILog.Info("BUILDER: Stations already connected");
			return route;
		} else {
			//Connect their front tiles
			AILog.Info("BUILDER: Connecting stations");
			result = Builder.BuildRoad(AIRoad.GetRoadStationFrontTile(start), 
				AIRoad.GetRoadStationFrontTile(end));
			if(result == false){
				AILog.Warning("BUILDER: Could not connect existing stations");
				return false;
			}
		}
	}
	
	if(AITile.IsStationTile(start)){
		//Start station already built
		start = AIRoad.GetRoadStationFrontTile(start);
		buildstart = false;
	}
	
	if(AITile.IsStationTile(end)){
		//End station already built
		end = AIRoad.GetRoadStationFrontTile(end);
		buildend = false;
	}
	
	AILog.Info("BUILDER: Connecting source to destination");
	result = Builder.BuildRoad(start, end);
	if(result == false){
		AILog.Warning("BUILDER: Could not connect source to destination");
		return false;
	}
	
	AILog.Info("BUILDER: Building starting station");
	if(buildstart){
		start = Builder.BuildRoadStation(start, route.stationtype);
		if(start == false){
			return false;
		} else {
			route.source = start;
		}
	}
	
	AILog.Info("BUILDER: Building ending station");
	if(buildend){
		end = Builder.BuildRoadStation(end, route.stationtype);
		if(end == false){
			return false;
		} else {
			route.destination = end;
		}
	}
	
	return route;
}

function Builder::BuildRoad(start, end){
	//Build a road from start to end
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	
	//Build to front if it's a station tile
	if(AIRoad.IsRoadStationTile(start)){
		start = AIRoad.GetRoadStationFrontTile(start);
	}
	if(AIRoad.IsRoadStationTile(end)){
		end = AIRoad.GetRoadStationFrontTile(end);
	}
	AILog.Info("BUILDER: Constructing a road from " + start + " to " + end);
	
	local path = Prospector.PathfindRoadRoute(start, end, Accountant.GetMaxFunds());
	if(path == false){
		AILog.Warning("BUILDER: Could not find road path");
		return false;
	}
	if(path == null){
		AILog.Warning("BUILDER: Pathfinder returned null - " + AIError.GetLastErrorString());
		return false;
	}
	
	return Builder.BuildPath(path);
}

function Builder::BuildPath(path){
	while (path != null) {
		local par = path.GetParent();
		if (par != null) {
			local last_node = path.GetTile();
			if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
				if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
					switch(AIError.GetLastError()){
						case AIError.ERR_ALREADY_BUILT:
							break;
						
						case AIError.ERR_AREA_NOT_CLEAR:
							if(!AIRoad.IsRoadTile(path.GetTile()) && 
								!AIRoad.IsRoadStationTile(path.GetTile())){
								AILog.Warning("Clear this");
								AISign.BuildSign(path.GetTile(), "Clear this");
							} else if(AIRoad.IsRoadTile(path.GetTile())){
								//Rouge road tile?
								AITile.DemolishTile(path.GetTile);
								AIRoad.BuildRoad(path.GetTile(), par.GetTile());
							}
							break;
						
						default:
							AILog.Warning("BUILDER: Road construction problem: " + AIError.GetLastErrorString());
							break;
					}
				}
			} else {
				/* Build a bridge or tunnel. */
				if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
					/* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
					if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
					if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
						if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
							/* An error occured while building a tunnel. TODO: handle it. */
						}
					} else {
						local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
						bridge_list.Valuate(AIBridge.GetMaxSpeed);
						bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
						if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
							/* An error occured while building a bridge. TODO: handle it. */
						}
					}
				}
			}
		}
		path = par;
	}
	return true;
}

function Builder::BuildRoadStation(site, stationtype){
	//Construct a road station at the specified location
	AILog.Info("BUILDER: Constructing a road station");
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

	local vehicletype = null;
	local adjacent = null;
	
	if(stationtype == AIStation.STATION_BUS_STOP){
		vehicletype = AIRoad.ROADVEHTYPE_BUS;
	} else {
		vehicletype = AIRoad.ROADVEHTYPE_TRUCK;
	}
	
	if(AIRoad.IsRoadStationTile(site)){
		//I have been provided with an existing station
		local station = AIStation.GetStationID(site);
		if(AIStation.HasStationType(station, stationtype)){
			AILog.Info("BUILDER: Station already exists");
			return site;
		} else {
			//Add to the station
			AILog.Warning("BUILDER: I can't expand stations!");
			return false;
		}
	}
	
	adjacent = Prospector.FindBuildableAdjacent(site, AITile.TRANSPORT_ROAD);
	if(adjacent == false){
		//Can't build here
		return false;
	}
	AIRoad.BuildRoad(site, adjacent);
	
	local result = AIRoad.BuildRoadStation(site, adjacent, vehicletype, AIStation.STATION_NEW);
	if(result == false){
		AILog.Warning("BUILDER: Could not build road station - " + AIError.GetLastErrorString());
		return false;
	}
	return site;
}

function Builder::BuildDepot(destination, stationtype){
	//Build a depot with the intention of servicing destination
	local site = Prospector.FindDepotSite(destination, stationtype);
	if(site == false){
		AILog.Warning("BUILDER: Unable to find depot site");
		return false;
	}
	if(AIRoad.IsRoadDepotTile(site)){
		AILog.Info("BUILDER: Depot already built");
		return site;
	}
	//Destination should be a station tile
	if(AIRoad.IsRoadStationTile(destination) == false){
		//It wasn't. Abort.
		AILog.Warning("BUILDER: Depots must be linked to stations");
		return false;
	}
	
	
	Builder.BuildRoad(destination, site);
	AIRoad.BuildRoadDepot(site, Prospector.FindBuildableAdjacent(site, AITile.TRANSPORT_ROAD));
	return site;
}

function Builder::RemoveRoadStation(station){
	local vehiclelist = AIVehicleList_Station(station);
	if(vehiclelist.IsEmpty()){
		AIRoad.RemoveRoadDepot(AIStation.GetLocation(station));
	}
}

function Builder::ClearSpace(site, width, height, radius){
	AILog.Info("BUILDER: I love this bit. Clearing some space.");
	local area = AITileList();
	local demosite = null;
	local clearradius = 1;
	
	AILog.Warning("BUILDER: I CAN ONLY CLEAR ONE TILE");
	for(clearradius = 1; clearradius <= radius; clearradius++){
		area.AddRectangle(site - AIMap.GetTileIndex(clearradius, clearradius), site + AIMap.GetTileIndex(clearradius, clearradius));
		demosite = area.Begin();
		while(AITile.DemolishTile(demosite) == false && area.HasNext()){
			demosite = area.Next();
		}
		if(area.HasNext() == false){
			AILog.Warning("BUILDER: I couldn't blow anything up!");
			return false;
		} else {
			return demosite;
		}
	}
	return false;
}