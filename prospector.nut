/*
 *	The prospector is used to find the best routes available
 */

class Prospector{
	function FindBestRoute(maxfunds);
	function GrowNetwork(from);
	function PathfindRoadRoute(start, end, maximumcost);
	function PathfindRailRoute(start, end, maximumcost);
	function FindStationSite(site, stationtype);
	function FindDepotSite(destination, stationtype);
	function FindBuildableAdjacent(site, transporttype);
}

function Prospector::FindBestRoute(maxfunds){
	//Find the best route possible for the maxfunds allowed
	AILog.Info("PROSPECTOR: Looking for the best route I can for " + maxfunds);
	
	local best_route = RouteInfo();
	
	local cargo = null;
	local cargolist = AICargoList();
	local multiplier = 0;
	
	local startlist = null;
	local startfreight = null;
	local endlist = null;
	local endfreight = null;
	
	local start = null;
	local end = null;
	
	local score = null;
	local starttile = null;
	local endtile = null;
	local distance = null;
	
	local neartown = null;
	local rating = null;
	
	local path = null;
	local bestpathed = null;
	local beststartname = null;
	local bestendname = null;
	
	//Starting with the most profitable cargo, try and find the most profitable connection
	cargolist.Valuate(AICargo.GetCargoIncome, 20, 10);
	cargo = cargolist.Begin();
	bestpathed = true;
	while(cargolist.HasNext()){
		multiplier = AICargo.GetCargoIncome(cargo, 20, 10) * 10;
		//Establish where the cargo needs to come from and go to
		if(AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS) || 
			AICargo.HasCargoClass(cargo, AICargo.CC_MAIL) ){
			//Collect from towns
			startlist = AITownList();
			startfreight = false;
			startlist.Valuate(AITown.GetLocation);
		} else {
			//Collect from industry
			startlist = AIIndustryList_CargoProducing(cargo);
			startfreight = true;
			startlist.Valuate(AIIndustry.GetLastMonthProduction, cargo);
			startlist.RemoveValue(0);
			startlist.Valuate(AIIndustry.GetLocation);
			
		}
		
		if(AICargo.GetTownEffect(cargo) == AICargo.TE_NONE){
			//Take it to industry
			endlist = AIIndustryList_CargoAccepting(cargo);
			endlist.Valuate(AIIndustry.GetLocation);
			endfreight = true;
		} else {
			//Take it to town
			endlist = AITownList();
			endlist.Valuate(AITown.GetLocation);
			endfreight = false;
		}
		
		//Score the routes
		start = startlist.Begin();
		while(startlist.HasNext()){
			if(startfreight){
				starttile = AIIndustry.GetLocation(start);
			} else {
				starttile = AITown.GetLocation(start);
			}
			
			end = endlist.Begin();
			while(endlist.HasNext()){
				if(end == start){
					end = endlist.Next();
					continue;
				}
				
				if(endfreight){
					endtile = AIIndustry.GetLocation(end);
				} else {
					endtile = AITown.GetLocation(end);
				}
				
				//Skip towns and industrys that are already connected
				if(startfreight && endfreight){
					if(Administrator.IsIndustryConnected(start, end)){
						end = endlist.Next();
						continue;
					}
				} else if(!startfreight && !endfreight){
					if(Administrator.IsTownConnected(start, end)){
						end = endlist.Next();
						continue;
					}
				}
				
				//Skip towns and industries which don't have a station and insufficent
				//rating to build one
				if(Administrator.IsTileAuthorityHostile(starttile)){
					end = endlist.Next();
					continue;
				}
				if(Administrator.IsTileAuthorityHostile(endtile)){
					end = endlist.Next();
					continue;
				}
				
				
				/*
				 * TODO: See if a town and industry are connected
				 */
				
				distance = AIMap.DistanceManhattan(starttile, endtile);
				
				if(startfreight){
					score = AIIndustry.GetLastMonthProduction(start, cargo) - 
							AIIndustry.GetLastMonthTransported(start, cargo);
					score = score * multiplier;
				} else {
					score = AITown.GetMaxProduction(start, cargo) - 
							AITown.GetLastMonthTransported(start, cargo);
					score = score * multiplier;
				}
				
				if(distance > 0){
					score = score / distance;
				} else {
					score = -1;
				}
				
				if(score > best_route.score){
					//Assign as the best route so far
					best_route.isfreight = startfreight;
					best_route.endfreight = endfreight;
					
					if(startfreight){
						best_route.source = AIIndustry.GetLocation(start);
						beststartname = AIIndustry.GetName(start);
					} else {
						best_route.source = AITown.GetLocation(start);
						beststartname = AITown.GetName(start);
					}
					
					if(endfreight){
						best_route.destination = AIIndustry.GetLocation(end);
						bestendname = AIIndustry.GetName(end);
					} else {
						best_route.destination = AITown.GetLocation(end);
						bestendname = AITown.GetName(end);
					}
					
					best_route.distance = distance;
					
					if(startfreight){
						best_route.stationtype = AIStation.STATION_TRUCK_STOP;
					} else {
						best_route.stationtype = AIStation.STATION_BUS_STOP;
					}
					best_route.score = score;
					best_route.cargo = cargo;
					
					bestpathed = false;
				}
				end = endlist.Next();
			}
			start = startlist.Next();
		}
		cargo = cargolist.Next();
	}
	if(bestpathed == false){
		AILog.Info("PROSPECTOR: Prospecting best route (" + AICargo.GetCargoLabel(best_route.cargo) + " from " + beststartname + " to " + bestendname + ")");
		path = Prospector.PathfindRoadRoute(best_route.source, best_route.destination, maxfunds);
		if(path == null || path == false){
			best_route.score = -1;
		}
		bestpathed = true;
		AILog.Info("PROSPECTOR: Seeking better opportunities.");
	}
	
	if(best_route.score == -1){
		AILog.Warning("Failed");
		return null;
	}
	if(best_route.cargo == null){
		AILog.Warning("PROSPECTOR: I couldn't find any new routes");
		return false;
	}
	local returnstring = "PROSPECTOR: My tests have shown that our best option is moving "
		+ AICargo.GetCargoLabel(best_route.cargo) + " from "
		+ beststartname + " to " + bestendname;
	
	AILog.Info(returnstring);
	return best_route;
}

function Prospector::PathfindRoadRoute(start, end, maximumcost){
	if(start == end){
		AILog.Warning("PROSPECTOR: Can not plot path from the same locations");
		return false;
	}

	/* Tell OpenTTD we want to build normal road (no tram tracks). */
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	/* Create an instance of the pathfinder. */
	local pathfinder = RoadPathFinder();
	
	//Set the values
	pathfinder.cost.max_cost = maximumcost;	//The most we can spend on the path
	pathfinder.cost.tile = 50;				//There is a road already
	
	if(AIRoad.IsRoadStationTile(start)){
		start = AIRoad.GetRoadStationFrontTile(start);
	}
	if(AIRoad.IsRoadStationTile(end)){
		end = AIRoad.GetRoadStationFrontTile(end);
	}
	
	
	if(!AITile.IsBuildable(start) && !AIRoad.IsRoadTile(start)){
		//We've been fed a dud tile. Probably an industry. Have a look at the adjacents instead.
		local tilelist = AITileList();
		tilelist.AddRectangle(start - AIMap.GetTileIndex(2, 2), start + AIMap.GetTileIndex(2, 2));
		tilelist.Valuate(AITile.IsBuildable);
		tilelist.KeepValue(1);
		if(tilelist.IsEmpty()){
			//No buildable tiles in the area, let's make some. Hehe.
			AILog.Info("PROSPECTOR: I couldn't find a clear spot. Builder, make me one.");
			return Builder.ClearSpace(start, 1, 1, 2);
		}
		start = tilelist.Begin();
	}
	
	if(!AITile.IsBuildable(end) && !AIRoad.IsRoadTile(end)){
		//We've been fed a dud tile. Probably an industry. Have a look at the adjacents instead.
		local tilelist = AITileList();
		tilelist.AddRectangle(end - AIMap.GetTileIndex(2, 2), end + AIMap.GetTileIndex(2, 2));
		tilelist.Valuate(AITile.IsBuildable);
		tilelist.KeepValue(1);
		if(tilelist.IsEmpty()){
			//No buildable tiles in the area, let's make some. Hehe.
			AILog.Info("PROSPECTOR: I couldn't find a clear spot. Builder, make me one.");
			return Builder.ClearSpace(end, 1, 1, 2);
		}
		end = tilelist.Begin();
	}
	
	/* Give the source and goal tiles to the pathfinder. */
	pathfinder.InitializePath([start], [end]);

	/* Try to find a path. */
	local path = false;
	local trycount = 0;
	local gettick = AIController.GetTick();
	local tickcount = 0;
	
	while (path == false && trycount < (MAXIMUM_PATH_TRIES * TRY_COUNT)) {
		trycount++;
		path = pathfinder.FindPath(100);
		
		//The pathfinding routine can be pretty longwinded, so check for any events that
		//may have occurred
		Manager.ManageEvents();
		this.Sleep(1);
	}
	tickcount = AIController.GetTick() - gettick;
	AILog.Info("PROSPECTOR: That took me " + tickcount + " ticks.");
	
	if(path == false){
		AILog.Warning("PROSPECTOR: I couldn't find a valid path in time. (Multiplier * " + TRY_COUNT + ")");
		return false;
	}
	if(path == null){
		AILog.Warning("PROSPECTOR: These 2 places cannot be joined " + AIError.GetLastErrorString());
		
	}
	return path;
}

function Prospector::PathfindRailRoute(start, end, maximumcost, route){
	local types = AIRailTypeList();
	AIRail.SetCurrentRailType(types.Begin());
	local pathfinder = RailPathFinder();

	//Set the values
	pathfinder.cost.max_cost = maximumcost;	//The most we can spend on the path
	pathfinder.cost.tile = 0;				//There is a road already
	
	/* Give the source and goal tiles to the pathfinder. */
	pathfinder.InitializePath([[start,start + AIMap.GetTileIndex(-1, 0)]], [[end + AIMap.GetTileIndex(-1, 0), end]]);

	/* Try to find a path. */
	local path = false;
	local trycount = 0;
	while (path == false && trycount < MAXIMUM_PATH_TRIES) {
		trycount++;
		path = pathfinder.FindPath(100);
		this.Sleep(1);
	}
	if(path == false){
		return false;
	}
	route.pathfinder = pathfinder;
	route.path = path;
	return true;
}

function Prospector::FindStationSite(site, stationtype){
	local options = AITileList();
	local radius = AIStation.GetCoverageRadius(stationtype);
	local tile = null;
	
	options.AddRectangle(site - AIMap.GetTileIndex(radius, radius), site + AIMap.GetTileIndex(radius, radius));
	//Look for one of our own stations already
	options.Valuate(AITile.IsStationTile);
		options.KeepValue(1);
	options.Valuate(AIStation.HasStationType, stationtype);
		options.KeepValue(1);
	options.Valuate(AITile.GetOwner);
		options.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	
	if(options.IsEmpty()){
		//Find a site for a new station
		options.AddRectangle(site - AIMap.GetTileIndex(radius, radius), site + AIMap.GetTileIndex(radius, radius));
		//Buildable tiles
		options.Valuate(AITile.IsBuildable);
		options.KeepValue(1);
		
		//Tiles in non-hostile town authority
		options.Valuate(Administrator.IsTileAuthorityHostile);
		options.RemoveValue(1);
		
		options.Valuate(AIMap.DistanceManhattan, site);
		options.KeepBottom(1);
		if(options.IsEmpty()){
			AILog.Warning("PROSPECTOR: Could not find suitable location");
			return false;
		}
		tile = options.Begin();
	} else {
		//Use the stations we found
		while(tile == null){
			local station = AIStation.GetStationID(options.Begin());
			if(AIStation.HasStationType(station, stationtype)){
				tile = AIStation.GetLocation(station);
				AILog.Info("PROSPECTOR: Found existing station");
			}
			tile = options.Next();
		}
	}
	
	AISign.BuildSign(tile, "tile");
	return tile;
}

function Prospector::FindDepotSite(destination, stationtype){
	//We need to find a depot site to service destination
	local tile = null;
	local options = AITileList();
	options.AddRectangle(destination - AIMap.GetTileIndex(DISTANCE_FROM_DEPOT, DISTANCE_FROM_DEPOT), 
		destination + AIMap.GetTileIndex(DISTANCE_FROM_DEPOT, DISTANCE_FROM_DEPOT));
	
	//Look for any existing depots
	local depots = null;
	
	switch(stationtype){
		case AIStation.STATION_BUS_STOP:
		case AIStation.STATION_TRUCK_STOP:
			depots = AIDepotList(AITile.TRANSPORT_ROAD);
			break;
		
		default:
			AILog.Warning("PROSPECTOR: I can't handle this station type");
			return false;
			break;
	}
	
	depots.KeepList(options);
	
	if(depots.IsEmpty()){
		//We didn't find any depots in the area. Find a site for a new one
		local tilelist = AITileList();
		local radius = AIStation.GetCoverageRadius(stationtype);
		
		tilelist.AddRectangle(destination - AIMap.GetTileIndex(DISTANCE_FROM_DEPOT, DISTANCE_FROM_DEPOT), 
			destination + AIMap.GetTileIndex(DISTANCE_FROM_DEPOT, DISTANCE_FROM_DEPOT));
		
		if(AITile.IsStationTile(destination)){
			//Destination is a station so we don't want to impede on its catchment
			AILog.Info("PROSPECTOR: Don't overlap station");
			tilelist.RemoveRectangle(destination - AIMap.GetTileIndex(radius, radius), 
				destination + AIMap.GetTileIndex(radius, radius));
		}
		tilelist.Valuate(AITile.IsBuildable);
		tilelist.KeepValue(1);
		
		tilelist.Valuate(AIMap.DistanceManhattan, destination);
		tilelist.KeepBottom(1);
		
		if(tilelist.IsEmpty()){
			return Builder.ClearSpace(destination, 1, 1, radius);
		}
		tile = tilelist.Begin();
		
	} else {
		//We have found an existing depot that is owned and of the correct type
		depots.Valuate(AIMap.DistanceManhattan, destination);
		depots.KeepBottom(1);
		tile = depots.Begin();
	}
	
	return tile;
}

function Prospector::FindBuildableAdjacent(site, transporttype){
	local adj = null;
	local list = AITileList();
	
	//Find a matching transport type
	list.AddTile(site + AIMap.GetTileIndex(0, 1));
	list.AddTile(site + AIMap.GetTileIndex(1, 0));
	list.AddTile(site - AIMap.GetTileIndex(0, 1));
	list.AddTile(site - AIMap.GetTileIndex(1, 0));
	
	list.Valuate(AITile.HasTransportType, transporttype);
	list.KeepValue(1);
	
	//Pick a buildable tile at random
	if(list.IsEmpty()){
		list = AITileList();
		list.AddTile(site + AIMap.GetTileIndex(0, 1));
		list.AddTile(site + AIMap.GetTileIndex(1, 0));
		list.AddTile(site - AIMap.GetTileIndex(0, 1));
		list.AddTile(site - AIMap.GetTileIndex(1, 0));
		list.Valuate(AITile.IsBuildable);
		list.KeepValue(1);
		if(list.IsEmpty()){
			AILog.Warning("PROSPECTOR: No adjacent tiles found");
			//No buildable tiles adjacent
			return false;
		}
	}
	adj = list.Begin();
	while(adj == site && list.HasNext()){
		adj = list.Next();
	}
	if(adj == site){
		return false;
	}
	return adj;
}