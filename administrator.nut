/*
 *	The Administrator is responsible for keeping any awkward lists, such as cargo manifests.
 *	He is also responsible for saving and loading information
 */
 
class Administrator{
	function FindCargoID(cargoclass, effect);
	function IsStationUsed(station);
	function HasStation(townid);
	function IsTownConnected(start, end);
	function IsIndustryConnected(start, end);
	function IsStationConnected(start, end);
	function IsTownHostile(town);
}

function Administrator::FindCargoID(cargoclass, effect){
	/*
	 *	Pretty much lifted from TrueAncestor
	 */
	local cargo_list = AICargoList();
	cargo_list.Valuate(AICargo.HasCargoClass, cargoclass);
	cargo_list.KeepValue(1);
	cargo_list.Valuate(AICargo.GetTownEffect);
	cargo_list.KeepValue(effect);
	if (cargo_list.Count() == 0){
		return -1;
	} else if (cargo_list.Count() == 1){
		return cargo_list.Begin();
	} else {
		// More were found, pick the best one based on acceptance
		local bigtown = TATownManager.GetBiggestTown();
		local bestacceptance = -1;
		local acceptance = 0;
		local bestcargo = -1;
		// Loop all found cargos
		foreach (cargo_list, value in cargo_list){
			acceptance = AITile.GetCargoAcceptance(AITown.GetLocation(bigtown), cargo_list, 1, 1, 5);
			if (acceptance > bestacceptance){
				bestacceptance = acceptance;
				bestcargo = cargo_list;
			}
		}
		// Return the best
		return bestcargo;
	}
}

function Administrator::HasStation(townid){
	/*
	 * Returns the tile index of a station or false if there is no station
	 */
	local townradius = AITileList();
	
	towncentre = AITown.GetLocation(townid);
	
	//Get the towns radius (or a DISTANCE_FROM_TOWN section of it)
	townradius.AddRectangle(
		AITown.GetLocation(towncentre) + AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN), 
		AITown.GetLocation(towncentre) - AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN));
	townradius.Valuate(AITile.IsWithinTownInfluence, towncentre);
	townradius.KeepValue(1);
	
	//Look for any of our stations in this area
	townradius.Valuate(AITile.GetOwner);
	townradius.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	if(townradius.IsEmpty()){
		return false;
	}
	
	townradius.Valuate(AITile.IsStationTile);
	townradius.KeepValue(1);
	if(townradius.IsEmpty()){
		return false;
	}
	
	stationlist_start = townradius;
}

function Administrator::IsTownConnected(start, end){
	if(!AITown.IsValidTown(start) || !AITown.IsValidTown(end)){
		AILog.Warning("ADMINISTRATOR: Supplied bad town information");
		return false;
	}

	//Taking start and end townid, find if we have a vehicle already running between these stations
	local townradius = AITileList();
	local stationlist_start = null;
	local stationstart = null;
	
	local stationlist_end = null;
	local stationend = null;
	
	//Get the towns radius (or a DISTANCE_FROM_TOWN section of it)
	townradius.AddRectangle(
		AITown.GetLocation(start) + AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN), 
		AITown.GetLocation(start) - AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN));
	townradius.Valuate(AITile.IsWithinTownInfluence, start);
	townradius.KeepValue(1);
	
	//Look for any of our stations in this area
	townradius.Valuate(AITile.GetOwner);
	townradius.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	if(townradius.IsEmpty()){
		return false;
	}
	
	townradius.Valuate(AITile.IsStationTile);
	townradius.KeepValue(1);
	if(townradius.IsEmpty()){
		return false;
	}
	
	stationlist_start = townradius;
	
	
	//Repeat for end town
	//Get the towns radius (or a DISTANCE_FROM_TOWN section of it)
	townradius.AddRectangle(
		AITown.GetLocation(end) + AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN), 
		AITown.GetLocation(end) - AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN));
	townradius.Valuate(AITile.IsWithinTownInfluence, end);
	townradius.KeepValue(1);
	
	//Look for any of our stations in this area
	townradius.Valuate(AITile.GetOwner);
	townradius.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	if(townradius.IsEmpty()){
		return false;
	}
	
	townradius.Valuate(AITile.IsStationTile);
	townradius.KeepValue(1);
	if(townradius.IsEmpty()){
		return false;
	}
	
	stationlist_end = townradius;
	
	if(stationlist_end.IsEmpty() || stationlist_start.IsEmpty()){
		AILog.Warning("empty lists");
		return false;
	} else {
		stationstart = stationlist_start.Begin();
		while(stationlist_start.HasNext()){
			stationend = stationlist_end.Begin();
			while(stationlist_end.HasNext()){
				if(Administrator.IsStationConnected(stationstart, stationend)){
					return true;
				}
				stationend = stationlist_end.Next();
			}
			stationstart = stationlist_start.Next();
		}
	}
	
	return false;
}

function Administrator::IsIndustryConnected(start, end){
	if(!AIIndustry.IsValidIndustry(start) || !AIIndustry.IsValidIndustry(end)){
		AILog.Warning("ADMINISTRATOR: Supplied bad industry information");
		return false;
	}

	//Taking start and end townid, find if we have a vehicle already running between these stations
	local industryradius = AITileList();
	local stationlist_start = null;
	local stationstart = null;
	
	local stationlist_end = null;
	local stationend = null;
	
	//Get the towns radius (or a DISTANCE_FROM_TOWN section of it)
	industryradius.AddRectangle(
		AIIndustry.GetLocation(start) + AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN), 
		AIIndustry.GetLocation(start) - AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN));
	
	//Look for any of our stations in this area
	industryradius.Valuate(AITile.GetOwner);
	industryradius.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	if(industryradius.IsEmpty()){
		return false;
	}
	
	industryradius.Valuate(AITile.IsStationTile);
	industryradius.KeepValue(1);
	if(industryradius.IsEmpty()){
		return false;
	}
	
	stationlist_start = industryradius;
	
	
	//Repeat for end town
	//Get the towns radius (or a DISTANCE_FROM_TOWN section of it)
	industryradius.AddRectangle(
		AIIndustry.GetLocation(end) + AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN), 
		AIIndustry.GetLocation(end) - AIMap.GetTileIndex(DISTANCE_FROM_TOWN, DISTANCE_FROM_TOWN));
	
	//Look for any of our stations in this area
	industryradius.Valuate(AITile.GetOwner);
	industryradius.KeepValue(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
	if(industryradius.IsEmpty()){
		return false;
	}
	
	industryradius.Valuate(AITile.IsStationTile);
	industryradius.KeepValue(1);
	if(industryradius.IsEmpty()){
		return false;
	}
	
	stationlist_end = industryradius;
	
	if(stationlist_end.IsEmpty() || stationlist_start.IsEmpty()){
		AILog.Warning("empty lists");
		return false;
	} else {
		stationstart = stationlist_start.Begin();
		while(stationlist_start.HasNext()){
			stationend = stationlist_end.Begin();
			while(stationlist_end.HasNext()){
				if(Administrator.IsStationConnected(stationstart, stationend)){
					return true;
				}
				stationend = AIStation.GetStationID(stationlist_end.Next());
			}
			stationstart = AIStation.GetStationID(stationlist_start.Next());
		}
	}
	
	return false;
}

function Administrator::IsStationConnected(start, end){
	if(AITile.IsStationTile(start) == false){
		AILog.Warning("ADMINISTRATOR: Start tile is not a station.");
		AISign.BuildSign(start, "NOT A STATION");
		return false;
	}
	if(AITile.IsStationTile(end) == false){
		AILog.Warning("ADMINISTRATOR: End tile is not a station.");
		AISign.BuildSign(end, "NOT A STATION");
		return false;
	}
	
	//Returns true if a vehicle runs between these two stations
	local vehiclelist_start = AIVehicleList_Station(AIStation.GetStationID(start));
	local vehiclelist_end = AIVehicleList_Station(AIStation.GetStationID(end));
	//Blend the two lists to see if there are any matches
	vehiclelist_end.KeepList(vehiclelist_start);
	
	
	
	if(vehiclelist_end.Count() > 0){
		return true;
	}
	return false;
}

function Administrator::IsTileAuthorityHostile(tile){
	local rating = 0;
	local neartown = AITile.GetClosestTown(tile);
	if(AITile.IsWithinTownInfluence(tile, neartown)){
		rating = AITown.GetRating(neartown, 
			AICompany.ResolveCompanyID(AICompany.COMPANY_SELF))
		if(rating < AITown.TOWN_RATING_VERY_POOR && rating != 0){
			AILog.Info("ADMINISTRATOR: Town Authority refuses to allow construction there " + rating);
			return true;
		}
	}
	return false;
}