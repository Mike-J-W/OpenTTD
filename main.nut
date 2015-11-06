/* Team Real Intelligence
  Mike Warburton
  Mary Claire McCarthy
  Shay Bromer
  Ryan Wilson
*/


import("pathfinder.road", "RoadPathFinder", 3);

class RIAI extends AIController 
{

  passenger_cargo_id = -1;
  liquid_cargo_id = -1;
  built_in_towns = AIList();
  oil_wells = AIList();
  oil_refineries = AIList();
  bus_group_id = 0;
  tanker_group_id = 0;

  constructor()
  {
  
    /* Find cargo id for passengers.  Sourced from WrightAI */
    local list = AICargoList();
    for (local i = list.Begin(); list.HasNext(); i = list.Next()) {
      if (AICargo.HasCargoClass(i, AICargo.CC_PASSENGERS)) {
        this.passenger_cargo_id = i;
      }
      if (AICargo.HasCargoClass(i, AICargo.CC_LIQUID))
      {
        this.liquid_cargo_id = i;
      }
    }
  }

  function Start();
}

function RIAI::Start()
{
  AICompany.SetName("Planes Are A Cop-Out");

  bus_group_id = AIGroup.CreateGroup(AIVehicle.VT_ROAD);
  tanker_group_id = AIGroup.CreateGroup(AIVehicle.VT_ROAD);

  /* Get a list of all oil wells and oil refineries on the map. */
  this.oil_wells = AIIndustryList_CargoProducing (liquid_cargo_id);
  this.oil_refineries = AIIndustryList_CargoAccepting (liquid_cargo_id);


  this.BuildAirports();
  this.MakeBusWeb();
  this.ConnectIndustries();
  while(true)
  {
    this.Sleep(500);
    this.AdjustBuses();

    this.Sleep(100);
    this.MakeBusWeb();

    this.Sleep(100);
    this.AdjustTankers();

    this.Sleep(100);
    this.ConnectIndustries();

    this.Sleep(100);
    this.RemoveVehicles();

    this.Sleep(100);
    if(AICompany.GetLoanAmount() > 20000)
    {
      AICompany.SetLoanAmount(AICompany.GetLoanAmount() - 10000);
    }
	
    this.Advertise();
	
    AICompany.SetLoanAmount(0);
    AILog.Info("I guess it's working.");
  }
  
  AILog.Info("Done");
}


function RIAI::Advertise()
{
  AILog.Info("advertising");
  this.built_in_towns.Sort(AIAbstractList.SORT_BY_VALUE, true);
  local town_id = this.built_in_towns.Begin();
  if(AICompany.GetBankBalance(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) > 30000 && !(AITown.GetRating(town_id, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_VERY_GOOD || AITown.GetRating(town_id, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_EXCELLENT || AITown.GetRating(town_id, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_OUTSTANDING)) 
  {
    AITown.PerformTownAction(town_id, AITown.TOWN_ACTION_ADVERTISE_SMALL);
    AILog.Info("ad in " + AITown.GetName(town_id));
  }
  while(this.built_in_towns.HasNext())
  {
    town_id = this.built_in_towns.Next();
    if(AICompany.GetBankBalance(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) > 30000 && !(AITown.GetRating(town_id, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_VERY_GOOD || AITown.GetRating(town_id, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_EXCELLENT || AITown.GetRating(town_id, AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) == AITown.TOWN_RATING_OUTSTANDING)) 
    {
      AITown.PerformTownAction(town_id, AITown.TOWN_ACTION_ADVERTISE_SMALL);
      AILog.Info("ad in " + AITown.GetName(town_id));
    }
  }
}


function RIAI::RemoveVehicles()
{
  AILog.Info("removing");
  local veh_list = AIVehicleList_Group(this.bus_group_id);
  local veh_id = veh_list.Begin();
  if(AIVehicle.GetAge(veh_id) > 2 && AIVehicle.GetProfitLastYear(veh_id) < 0 && AIVehicle.GetProfitThisYear(veh_id) < 0)
  {
    AIVehicle.SendVehicleToDepot(veh_id);
    AIVehicle.SellVehicle(veh_id);
  }
  while(veh_list.HasNext())
  {
    veh_id = veh_list.Next();
    AILog.Info(veh_id);
    if(AIVehicle.GetAge(veh_id) > 2 && AIVehicle.GetProfitLastYear(veh_id) < 0 && AIVehicle.GetProfitThisYear(veh_id) < 0)
    {
      AIVehicle.SendVehicleToDepot(veh_id);
      AIVehicle.SellVehicle(veh_id);
    }
  }
  
  veh_list = AIVehicleList_Group(this.tanker_group_id);
  veh_id = veh_list.Begin();
  if(AIVehicle.GetAge(veh_id) > 2 && AIVehicle.GetProfitLastYear(veh_id) < 0 && AIVehicle.GetProfitThisYear(veh_id) < 0)
  {
    AIVehicle.SendVehicleToDepot(veh_id);
    AIVehicle.SellVehicle(veh_id);
  }
  while(veh_list.HasNext())
  {
    veh_id = veh_list.Next();
    if(AIVehicle.GetAge(veh_id) > 2 && AIVehicle.GetProfitLastYear(veh_id) < 0 && AIVehicle.GetProfitThisYear(veh_id) < 0)
    {
      AIVehicle.SendVehicleToDepot(veh_id);
      AIVehicle.SellVehicle(veh_id);
    }
  }

  veh_list = AIVehicleList_DefaultGroup(AIVehicle.VT_AIR);
  veh_id = veh_list.Begin();
  if(AIVehicle.GetAge(veh_id) > 2 && AIVehicle.GetProfitLastYear(veh_id) < 0 && AIVehicle.GetProfitThisYear(veh_id) < 0)
  {
    AIVehicle.SendVehicleToDepot(veh_id);
    AIVehicle.SellVehicle(veh_id);
  }
  if(veh_list.HasNext())
  {
    veh_id = veh_list.Next();
    if(AIVehicle.GetAge(veh_id) > 2 && AIVehicle.GetProfitLastYear(veh_id) < 0 && AIVehicle.GetProfitThisYear(veh_id) < 0)
    {
      while(AIOrder.IsValidVehicleOrder(veh_id, 0))
      {
        AIOrder.RemoveOrder(veh_id, 0);
      }
      AIVehicle.SendVehicleToDepot(veh_id);
      AIVehicle.SellVehicle(veh_id);	  
    }
  }

}

function RIAI::AdjustTankers()
{
  local station_list = AIStationList(AIStation.STATION_TRUCK_STOP);
  local depot_list = AIDepotList(AITile.TRANSPORT_ROAD);
  local well_station_list = AIAbstractList();
  local s = station_list.Begin();
  if(AIStation.GetCargoRating(s, this.liquid_cargo_id) > 0)
    well_station_list.AddItem(s, 0);
  while(station_list.HasNext())
  {
    s = station_list.Next();
    if(AIStation.GetCargoRating(s, this.liquid_cargo_id) > 0)
    well_station_list.AddItem(s, 0);
  }
  //goes through all the stations
  local well_station = well_station_list.Begin();
  for(local i = 1; i < well_station_list.Count(); i=i+1)
  {
    // the criteria for another bus
    if (AIStation.GetCargoWaiting(well_station, this.liquid_cargo_id) > 100)
    { 
      local depot = depot_list.Begin();
      // searches for the nearest depot
      while(!(AIMap.DistanceManhattan(depot, AIStation.GetLocation(well_station)) <= 10 || !depot_list.HasNext()))
      {
        depot = depot_list.Next();
      }
      if(AIMap.DistanceManhattan(depot, AIStation.GetLocation(well_station)) <= 10 )
      {
        if(this.GetMoney(8000))
        {
          // builds a new bus at that depot and copies the orders of a bus that has the route desired for this one
          local tanker_id = this.BuildNewOilTanker(depot);
          local station_tanker_list = AIVehicleList_Station(well_station);
          AIOrder.CopyOrders(tanker_id, station_tanker_list.Begin());
          AIVehicle.StartStopVehicle(tanker_id);
          AIGroup.MoveVehicle(this.tanker_group_id, tanker_id);
        }
      }
    }
    well_station = well_station_list.Next();
  }
    
}



function RIAI::ConnectIndustries()
{
  if(this.oil_wells.Count() < 2 || this.oil_refineries.Count() < 2) return;
  local well_id = this.oil_wells.Begin();
  local refinery_id = this.oil_refineries.Begin();
  
  while (AIMap.DistanceManhattan(AIIndustry.GetLocation(well_id), AIIndustry.GetLocation(refinery_id)) > 150 && this.oil_refineries.HasNext())
  {
    while (AIMap.DistanceManhattan(AIIndustry.GetLocation(well_id), AIIndustry.GetLocation(refinery_id)) > 150 && this.oil_wells.HasNext())
    {
      well_id = this.oil_wells.Next();
      AILog.Info("Consider " + AIIndustry.GetName(well_id));
    }
    this.oil_refineries.RemoveItem(refinery_id);
    refinery_id = this.oil_refineries.Begin();
    AILog.Info("Considering " + AIIndustry.GetName(refinery_id));
    well_id = this.oil_wells.Begin();
  }
  this.oil_refineries.RemoveItem(refinery_id);
  this.oil_wells.RemoveItem(well_id);
  
  if (AIIndustry.IsCargoAccepted(refinery_id, this.liquid_cargo_id))
  {
    local costs = AIAccounting();
    AITestMode();
	
    local accepting_station_tile = this.BuildAcceptingTruckStation(refinery_id);
    local producing_station_tile = this.BuildProducingTruckStation(well_id);
    local depot_tile = BuildRoadConnectIndustries(accepting_station_tile, producing_station_tile);
    local tanker_id = BuildNewOilTanker(depot_tile);
    AIOrder.AppendOrder(tanker_id, producing_station_tile, AIOrder.AIOF_FULL_LOAD);
    AIOrder.AppendOrder(tanker_id, depot_tile, AIOrder.AIOF_SERVICE_IF_NEEDED);
    AIOrder.AppendOrder(tanker_id, accepting_station_tile, AIOrder.AIOF_UNLOAD);
    AIVehicle.StartStopVehicle(tanker_id);
    AIGroup.MoveVehicle(this.tanker_group_id, tanker_id);
	
    AIExecMode();
    local price = costs.GetCosts();
    if(this.GetMoney(price+15000))
    {
      AILog.Info("trying to connect " + AIIndustry.GetName(well_id) + " to " + AIIndustry.GetName(refinery_id));
  
      local accepting_station_tile = this.BuildAcceptingTruckStation(refinery_id);
      local producing_station_tile = this.BuildProducingTruckStation(well_id);
      local depot_tile = BuildRoadConnectIndustries(accepting_station_tile, producing_station_tile);
      local tanker_id = BuildNewOilTanker(depot_tile);
      AIOrder.AppendOrder(tanker_id, producing_station_tile, AIOrder.AIOF_FULL_LOAD);
      AIOrder.AppendOrder(tanker_id, depot_tile, AIOrder.AIOF_SERVICE_IF_NEEDED);
      AIOrder.AppendOrder(tanker_id, accepting_station_tile, AIOrder.AIOF_UNLOAD);
      AIVehicle.StartStopVehicle(tanker_id);
      AIGroup.MoveVehicle(this.tanker_group_id, tanker_id);
	
    }
  }
  
}


function RIAI::BuildNewOilTanker(depot)
{
  /* Sourced from WrightAI 
     creates a list of road engines that carry passengers */
  local road_engine_list = AIEngineList(AIVehicle.VT_ROAD);
  road_engine_list.Valuate(AIEngine.GetCargoType);
  road_engine_list.KeepValue(this.liquid_cargo_id);

  // grabs the first such engine
  local engine = road_engine_list.Begin();
  // checks that it's the proper engine
  while(AIEngine.GetName(engine) != "Witcombe Oil Tanker")
  {
    engine = road_engine_list.Next();
  }
 
  // builds the engine in the first depot
  local vehicle_id = AIVehicle.BuildVehicle(depot, engine);

  // returns the id of the bus
  return vehicle_id;

}



//  finds and builds a road between town_a and town_b.  also places a depot on the road
function RIAI::BuildRoadConnectIndustries(id_a, id_b)
{

  local depot_location = AIMap.GetTileIndex(5,5);

  /* Tell OpenTTD we want to build normal road (no tram tracks). */
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

  /* Create an instance of the pathfinder. */
  local pathfinder = RoadPathFinder();

  /* Set the cost for making a turn extreme high. */
  pathfinder.cost.turn = 500;

  /* Give the source and goal tiles to the pathfinder. */
  pathfinder.InitializePath([id_a], [id_b]);

  /* Try to find a path. */
  local path = false;
  while (path == false) {
    AILog.Info("Looking for path.");
    path = pathfinder.FindPath(100);
    this.Sleep(1);
  }

  if (path == null) {
    /* No path was found. */
    AILog.Info("No path found.");
    AILog.Error("pathfinder.FindPath return null");
  }
  
  local depot_built = false;
  local count = 0;
  
  // 'this.GetMoney' will get the money for the road if the money is available
  // if the money isn't available, the road won't be built
  while (path != null) {
    AILog.Info("Trying to build road.");
    count = count + 1;
    if(count % 60 == 0) depot_built = false;
    local par = path.GetParent();
    if (par != null) {
      local last_node = path.GetTile();
      if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
        if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
          /* An error occured while building a piece of road. TODO: handle it. 
           * Note that is can also be the case that the road was already build. */
        }else if(!depot_built && !AITile.IsSteepSlope(AITile.GetSlope(path.GetTile())))
        {
          /* Try building road depot on adjacent tile until one is built. 
            Needs some alteration because of the error mentioned in line 160.
            Before that change, this would pull the road to the depot and
            disconnect the path being built. */
          local depot_x = AIMap.GetTileX(path.GetTile());
          local depot_y = AIMap.GetTileY(path.GetTile());
          
          // will be checking all tiles adjacent to the recently built road tile
          for(local i=-1; i<2; i=i+1)
          { 
            for(local j=-1; j<2; j=j+1)
            {
              // current adjacent tile to try
              local depot_tile_index = AIMap.GetTileIndex(depot_x + i, depot_y + j);
	
              // so long as a depot hasn't already been built and the current tile isn't part of the road path, try building a depot
              if(!depot_built && depot_tile_index != path.GetTile() && depot_tile_index != par.GetTile())
              {
                depot_built = AIRoad.BuildRoadDepot(depot_tile_index, path.GetTile());
                if(depot_built)
                { 
                  // tries to ensure the depot is connected to the road
                  local road_built = AIRoad.BuildRoad(path.GetTile(), depot_tile_index);
                  if(!road_built)
                  {
                    // if it can't be connected, we need a different depot
                    AIRoad.RemoveRoadDepot(depot_tile_index);
                    depot_built = false;
                    AILog.Info("Couldn't connect depot to road so had to remove depot.");
                  }else
                  {
                    // if the location is successful, we help the road builing algorithm make sure no
                    // part of the road is missed due to the depot.
                    AIRoad.BuildRoadFull(path.GetTile(), par.GetTile());
                    depot_location = depot_tile_index;
                  }
                }
              }
            }
          }
        }
      } else {
        /* Build a bridge or tunnel. */
        if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
          /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
          if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
          if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
            if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {/*
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
  return depot_location
}


//  tries to place a drive through truck station around given industry
function RIAI::BuildAcceptingTruckStation(industry_id)
{
  local station_built = false;

  /* Tell OpenTTD we want to build normal road (no tram tracks). */
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  
  local accepting_tiles = AITileList_IndustryAccepting(industry_id, AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP));
  local tile = accepting_tiles.Begin()
  
  while(accepting_tiles.HasNext())	 
  {
    tile = accepting_tiles.Next();
    local station_x = AIMap.GetTileX(tile);
    local station_y = AIMap.GetTileY(tile);
	
    /* Set the front tile of the station. */
    local station_front_x = station_x + 1;
    local station_front_y = station_y;
      
    /* Will try to build the road if the current coordinates point to a tile that is a road tile without something already on it. */
    if(AITile.IsBuildable(AIMap.GetTileIndex(station_x, station_y)) && AITile.IsBuildable(AIMap.GetTileIndex(station_front_x, station_front_y)))
    {
      station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW);
      if(station_built)
      {
        AIRoad.BuildRoadFull(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y));
        AIRoad.BuildRoadFull(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_x - 1, station_y));
        return AIMap.GetTileIndex(station_x, station_y);		  
      }
    }
    else
    {
      station_front_x = station_x;
      station_front_y = station_y + 1;
      if(AITile.IsBuildable(AIMap.GetTileIndex(station_x, station_y)) && AITile.IsBuildable(AIMap.GetTileIndex(station_front_x, station_front_y)))
      {
        station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW);
        if(station_built)
        {
          AIRoad.BuildRoadFull(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y));
          AIRoad.BuildRoadFull(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_x, station_y - 1));
          return AIMap.GetTileIndex(station_x, station_y);
        }
      }
    }
  }
}




//  tries to place a drive through truck station around given industry
function RIAI::BuildProducingTruckStation(industry_id)
{
  local station_built = false;

  /* Tell OpenTTD we want to build normal road (no tram tracks). */
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  
  local producing_tiles = AITileList_IndustryProducing(industry_id, AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP));
  local tile = producing_tiles.Begin()
  
  while(producing_tiles.HasNext())	 
  {
    tile = producing_tiles.Next();
    local station_x = AIMap.GetTileX(tile);
    local station_y = AIMap.GetTileY(tile);
	
    /* Set the front tile of the station. */
    local station_front_x = station_x + 1;
    local station_front_y = station_y;
      
    /* Will try to build the road if the current coordinates point to a tile that is a road tile without something already on it. */
    if(AITile.IsBuildable(AIMap.GetTileIndex(station_x, station_y)) && AITile.IsBuildable(AIMap.GetTileIndex(station_front_x, station_front_y)))
    {
      station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW);
      if(station_built)
      {
        AIRoad.BuildRoadFull(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y));
        AIRoad.BuildRoadFull(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_x - 1, station_y));
        return AIMap.GetTileIndex(station_x, station_y);		  
      }
    }
    else
    {
      station_front_x = station_x;
      station_front_y = station_y + 1;
      if(AITile.IsBuildable(AIMap.GetTileIndex(station_x, station_y)) && AITile.IsBuildable(AIMap.GetTileIndex(station_front_x, station_front_y)))
      {
        station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_TRUCK, AIStation.STATION_NEW);
        if(station_built)
        {
          AIRoad.BuildRoadFull(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y));
          AIRoad.BuildRoadFull(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_x, station_y - 1));
          return AIMap.GetTileIndex(station_x, station_y);
        }
      }
    }
  }
}




// Will check to see if the waiting cargo is enough to warrent more buses.
function RIAI::AdjustBuses()
{
  local station_list = AIStationList(AIStation.STATION_BUS_STOP);
  local depot_list = AIDepotList(AITile.TRANSPORT_ROAD);
  local hub = station_list.Begin();
  local station = station_list.Begin();
  //goes through all the stations
  for(local i = 1; i < station_list.Count(); i=i+1)
  {
    // the criteria for another bus
    if (AIStation.GetCargoWaiting(station, this.passenger_cargo_id) > 75 && AITown.GetPopulation(AIStation.GetNearestTown(station)) > 400 && AIStation.GetCargoWaiting(hub, this.passenger_cargo_id) > 20)
    {
      local town_id = AIStation.GetNearestTown(station);
      local depot = depot_list.Begin();
      // searches for the nearest depot
      while(!(AIMap.DistanceManhattan(depot, AIStation.GetLocation(station)) <= 10 || !depot_list.HasNext()))
      {
        depot = depot_list.Next();
      }
      if(AIMap.DistanceManhattan(depot, AIStation.GetLocation(station)) <= 10 && this.GetMoney(8000))
      {
        // builds a new bus at that depot and copies the orders of a bus that has the route desired for this one
        local bus_id = this.BuildNewBus(depot);
        local station_bus_list = AIVehicleList_Station(station);
        AIOrder.CopyOrders(bus_id, station_bus_list.Begin());
        AIVehicle.StartStopVehicle(bus_id);
        AIGroup.MoveVehicle(this.bus_group_id, bus_id);
      }
    }
    station = station_list.Next();
  }
  
}


function RIAI::MakeBusWeb()
{
  /* Get a list of all towns on the map. */
  local townlist = AITownList();

  /* Sort the list by population, lowest population first. */
  townlist.Valuate(AITown.GetPopulation);
  townlist.Sort(AIAbstractList.SORT_BY_VALUE, true);
  /* Get the smallest town.  */
  local smallest_town = townlist.Begin();
  
  /* Sort the list by population, highest population first. */
  townlist.Valuate(AITown.GetPopulation);
  townlist.Sort(AIAbstractList.SORT_BY_VALUE, false);

  /* Pick the two towns with the highest population. */
  local townid_a = townlist.Begin();
  local townid_b = townlist.Next();
  
  /* Find towns to build between */
  local need_towns = true;
  local loop_count = 0;
  while(need_towns)
  {
    this.Sleep(1);
    // counts the number of hub/starter towns tried
    loop_count++;
    AILog.Info(loop_count);
    /* Find a second town that is large but isn't too far from the first. */
    while ((AITile.GetDistanceManhattanToTile(AITown.GetLocation(townid_b), AITown.GetLocation(townid_a)) > 50 || this.built_in_towns.HasItem(townid_b)) && townid_b != smallest_town)
    {
      // If this is running then the previous town_b didn't match the criteria and we need a new one.
      AILog.Info("Distance between " + AITown.GetName(townid_a) + " and " + AITown.GetName(townid_b) + " is " + AITile.GetDistanceManhattanToTile(AITown.GetLocation(townid_a), AITown.GetLocation(townid_b)));
      AILog.Info("Discarded " + AITown.GetName(townid_b));
      townid_b = townlist.Next();
    }
  
    /* Test the next largest town if the previous town_a didn't have any good options. */
    if (AITown.GetPopulation(townid_b) < 300 || this.built_in_towns.HasItem(townid_a))
    {
      // the for loop iterates past all the towns tried before to get the next largest hub town candidate
      townid_a = townlist.Begin();
      for(local i=0; i<loop_count; i++)
      {
        townid_a = townlist.Next();
        if(AITown.GetPopulation(townid_a) < 500)
          return;
      }
      // town_b couldn't be any of the previous because those combinations have already been eliminated
      if(townlist.HasNext()) townid_b = townlist.Next();
      else break;
    }
    else
    {
      // if a good match has been found, we can exit the while loop
      AILog.Info("The hub town is " + AITown.GetName(townid_a));
      need_towns = false;
    }
  }
  
  local bus_costs = AIAccounting();
  AITestMode();
  // map info for the hub town.  want to place a bus station in the town
  local town_tile_index = AITown.GetLocation(townid_a);
  local stationx = AIMap.GetTileX(town_tile_index);
  local stationy = AIMap.GetTileY(town_tile_index);
  local station_a_tile = this.BuildDriveThroughBusStation(stationx, stationy, true); 
  this.built_in_towns.AddItem(townid_a, 1);
    
  // now we want to build roads from the hub town to any town within 50 tiles
  local townid_c = townlist.Begin();

  // a loop to iterate through the town list  
  while(townlist.HasNext())
  {
    townid_c = townlist.Next();
  
    // starts the road building process if the town is within the proper radius
    if(townid_c != townid_a && !this.built_in_towns.HasItem(townid_c) && AITile.GetDistanceManhattanToTile(AITown.GetLocation(townid_a), AITown.GetLocation(townid_c)) < 55)
    {
      AILog.Info("I like " + AITown.GetName(townid_c));
      // builds a road bewteen this town and the hub town.  the build road function also places a depot near this town
      // and returns the depot tile index
      local depot_tile = this.BuildRoadConnectTowns(townid_a, townid_c);
      if(depot_tile != AIMap.GetTileIndex(1,1))
      {
        // Variables to use in placing bus station.   
        town_tile_index = AITown.GetLocation(townid_c);
        local stationx_c = AIMap.GetTileX(town_tile_index);
        local stationy_c = AIMap.GetTileY(town_tile_index);
        local station_c_tile = this.BuildDriveThroughBusStation(stationx_c, stationy_c, true); 
        this.built_in_towns.AddItem(townid_c, 1);
 
        // now we need a bus to run between the towns
        local bus_id = this.BuildNewBus(depot_tile);
        AIOrder.AppendOrder(bus_id, station_c_tile, AIOrder.AIOF_FULL_LOAD);
        AIOrder.AppendOrder(bus_id, depot_tile, AIOrder.AIOF_SERVICE_IF_NEEDED);
        AIOrder.AppendOrder(bus_id, station_a_tile, AIOrder.AIOF_FULL_LOAD);
        AIVehicle.StartStopVehicle(bus_id);
        AIGroup.MoveVehicle(this.bus_group_id, bus_id);
      }
    }
    
  }
  
  AIExecMode();
  if(this.GetMoney(bus_costs.GetCosts() + 15000))
  {
    // map info for the hub town.  want to place a bus station in the town
    local town_tile_index = AITown.GetLocation(townid_a);
    local stationx = AIMap.GetTileX(town_tile_index);
    local stationy = AIMap.GetTileY(town_tile_index);
    local station_a_tile = this.BuildDriveThroughBusStation(stationx, stationy, true); 
    this.built_in_towns.AddItem(townid_a, 0);
    
    // now we want to build roads from the hub town to any town within 50 tiles
    local townid_c = townlist.Begin();

    // a loop to iterate through the town list  
    while(townlist.HasNext())
    {
      townid_c = townlist.Next();
   
      // starts the road building process if the town is within the proper radius
      if(townid_c != townid_a && !this.built_in_towns.HasItem(townid_c) && AITile.GetDistanceManhattanToTile(AITown.GetLocation(townid_a), AITown.GetLocation(townid_c)) < 55)
      {
        AILog.Info("I like " + AITown.GetName(townid_c));
        // builds a road bewteen this town and the hub town.  the build road function also places a depot near this town
        // and returns the depot tile index
        local depot_tile = this.BuildRoadConnectTowns(townid_a, townid_c);
        if(depot_tile != AIMap.GetTileIndex(1,1))
        {
          // Variables to use in placing bus station.   
          town_tile_index = AITown.GetLocation(townid_c);
          local stationx_c = AIMap.GetTileX(town_tile_index);
          local stationy_c = AIMap.GetTileY(town_tile_index);
          local station_c_tile = this.BuildDriveThroughBusStation(stationx_c, stationy_c, true); 
          this.built_in_towns.AddItem(townid_c, 0);
 
          // now we need a bus to run between the towns
          local bus_id = this.BuildNewBus(depot_tile);
          AIOrder.AppendOrder(bus_id, station_c_tile, AIOrder.AIOF_FULL_LOAD);
          AIOrder.AppendOrder(bus_id, depot_tile, AIOrder.AIOF_SERVICE_IF_NEEDED);
          AIOrder.AppendOrder(bus_id, station_a_tile, AIOrder.AIOF_FULL_LOAD);
          AIVehicle.StartStopVehicle(bus_id);
          AIGroup.MoveVehicle(this.bus_group_id, bus_id);
        }
      }
    }
  } 
}


//  builds a bus in the first depot.  needs to be generalized for any depot.
function RIAI::BuildNewBus(depot)
{
  /* Sourced from WrightAI 
   creates a list of road engines that carry passengers */
  local road_engine_list = AIEngineList(AIVehicle.VT_ROAD);
  road_engine_list.Valuate(AIEngine.GetCargoType);
  road_engine_list.KeepValue(this.passenger_cargo_id);

  // grabs the first such engine
  local engine = road_engine_list.Begin();
  // checks that it's the proper engine
  while(AIEngine.GetName(engine) != "MPS Regal Bus")
  {
    engine = road_engine_list.Next();
  }
 
  this.GetMoney(10000);
  // builds the engine in the first depot
  local vehicle_id = AIVehicle.BuildVehicle(depot, engine);

  // returns the id of the bus
  return vehicle_id;

}


//  finds and builds a road between town_a and town_b.  also places a depot on the road
function RIAI::BuildRoadConnectTowns(townid_a, townid_b)
{

  local depot_location = AIMap.GetTileIndex(5,5);

  /* From here to line 136 was sourced from the wiki */
  /* Print the names of the towns we'll try to connect. */
  AILog.Info("Going to connect " + AITown.GetName(townid_a) + " to " + AITown.GetName(townid_b));
  
  /* Tell OpenTTD we want to build normal road (no tram tracks). */
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

  /* Create an instance of the pathfinder. */
  local pathfinder = RoadPathFinder();

  /* Set the cost for making a turn extreme high. */
  pathfinder.cost.turn = 500;

  /* Give the source and goal tiles to the pathfinder. */
  pathfinder.InitializePath([AITown.GetLocation(townid_a)], [AITown.GetLocation(townid_b)]);

  /* Try to find a path. */
  local path = false;
  while (path == false) {
    AILog.Info("Looking for path.");
    path = pathfinder.FindPath(100);
    this.Sleep(1);
  }

  if (path == null) {
    /* No path was found. */
    AILog.Info("No path found.");
    AILog.Error("pathfinder.FindPath return null");
  }
  
  local depot_built = false;
  
  // 'this.GetMoney' will get the money for the road if the money is available
  // if the money isn't available, the road won't be built
  while (path != null) {
    AILog.Info("Trying to build road.");
    local par = path.GetParent();
    if (par != null) {
      local last_node = path.GetTile();
      if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
        if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
          /* An error occured while building a piece of road. TODO: handle it. 
           * Note that is can also be the case that the road was already build. */
        }else if(!depot_built && !AITile.IsSteepSlope(AITile.GetSlope(path.GetTile())))
        {
          /* Try building road depot on adjacent tile until one is built. 
            Needs some alteration because of the error mentioned in line 160.
            Before that change, this would pull the road to the depot and
            disconnect the path being built. */
          local depot_x = AIMap.GetTileX(path.GetTile());
          local depot_y = AIMap.GetTileY(path.GetTile());

          // will be checking all tiles adjacent to the recently built road tile
          for(local i=-1; i<2; i=i+1)
          { 
            for(local j=-1; j<2; j=j+1)
            {
              // current adjacent tile to try
              local depot_tile_index = AIMap.GetTileIndex(depot_x + i, depot_y + j);
			  
              // so long as a depot hasn't already been built and the current tile isn't part of the road path, try building a depot
              if(!depot_built && depot_tile_index != path.GetTile() && depot_tile_index != par.GetTile())
              {
                depot_built = AIRoad.BuildRoadDepot(depot_tile_index, path.GetTile());
                if(depot_built)
                { 
                  // tries to ensure the depot is connected to the road
                  local road_built = AIRoad.BuildRoad(path.GetTile(), depot_tile_index);
                  if(!road_built)
                  {
                    // if it can't be connected, we need a different depot
                    AIRoad.RemoveRoadDepot(depot_tile_index);
                    depot_built = false;
                    AILog.Info("Couldn't connect depot to road so had to remove depot.");
                  }else
                  {
                    // if the location is successful, we help the road builing algorithm make sure no
                    // part of the road is missed due to the depot.
                    AIRoad.BuildRoadFull(path.GetTile(), par.GetTile());
                    depot_location = depot_tile_index;
                  }
                }
              }
            }
          }
        }
      } else {
        /* Build a bridge or tunnel. */
        if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
          /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
          if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
          if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
            if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {/*
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
  return depot_location;
}


//  tries to ensure the company has the money it wants
function RIAI::GetMoney(request)
{
  local balance = AICompany.GetBankBalance(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF));
  if (balance < request)
  {
    // finds the total loan required in order to get the requested money
    local needed = AICompany.GetLoanAmount() + request - balance;
    local loan_needed = AICompany.GetLoanInterval();
    while (loan_needed < needed)
    {
      // increases the theoretical loan amount by the proper interval until it's higher than the required loan
      loan_needed = loan_needed + AICompany.GetLoanInterval();
    }
    // gets the loan from the bank if it can.  returns the boolean of whether or not it was successful in getting the money.
    return AICompany.SetLoanAmount(loan_needed);
  }
  else
  {
    // if here, then the company already had enough money
    return true;
  }
}


//  tries to place a drive through bus station around given coordinates
function RIAI::BuildDriveThroughBusStation(given_station_x, given_station_y, new_station)
{
  local radius = 0;
  local station_built = false;

  /* Tell OpenTTD we want to build normal road (no tram tracks). */
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  
  while(true)	 
  {
    local station_x = given_station_x + radius;
    local station_y = given_station_y;
	
    for(local i=-radius; i<=radius; i=i+1)
    {	
      station_y = given_station_y + i;
	
      /* Set the front tile of the station. */
      local station_front_x = station_x + 1;
      local station_front_y = station_y;
      
      /* Will try to build the road if the current coordinates point to a tile that is a road tile without something already on it. */
      if(AIRoad.IsRoadTile(AIMap.GetTileIndex(station_x, station_y)))
      {
        if(new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
        if(!new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
        if(station_built)
        {
          return AIMap.GetTileIndex(station_x, station_y);		  
        }
        else
        {
          station_front_x = station_x;
          station_front_y = station_y + 1;
          if(new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
          if(!new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
          if(station_built)
          {
            return AIMap.GetTileIndex(station_x, station_y);
          }
        }
      }
    }
	
    station_x = given_station_x - radius;
	
    for(local i=-radius; i<=radius; i=i+1)
    {	
      station_y = given_station_y + i;
	
      /* Set the front tile of the station. */
      local station_front_x = station_x + 1;
      local station_front_y = station_y;
      
      /* Will try to build the road if the current coordinates point to a tile that is a road tile without something already on it. */
      if(AIRoad.IsRoadTile(AIMap.GetTileIndex(station_x, station_y)))
      {
        if(new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
        if(!new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
        if(station_built)
        {
          return AIMap.GetTileIndex(station_x, station_y);		  
        }
        else
        {
          station_front_x = station_x;
          station_front_y = station_y + 1;
          if(new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
          if(!new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
          if(station_built)
          {
            return AIMap.GetTileIndex(station_x, station_y);
          }
        }
      }
    }

    station_y = given_station_y + radius;
	
    for(local i=-radius; i<=radius; i=i+1)
    {	
      station_x = given_station_x + i;
	
      /* Set the front tile of the station. */
      local station_front_x = station_x + 1;
      local station_front_y = station_y;
      
      /* Will try to build the road if the current coordinates point to a tile that is a road tile without something already on it. */
      if(AIRoad.IsRoadTile(AIMap.GetTileIndex(station_x, station_y)))
      {
        if(new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
        if(!new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
        if(station_built)
        {
          return AIMap.GetTileIndex(station_x, station_y);		  
        }
        else
        {
          station_front_x = station_x;
          station_front_y = station_y + 1;
          if(new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
          if(!new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
          if(station_built)
          {
            return AIMap.GetTileIndex(station_x, station_y);
          }
        }
      }
    }

    station_y = given_station_y - radius;
	
    for(local i=-radius; i<=radius; i=i+1)
    {	
      station_x = given_station_x + i;
	
      /* Set the front tile of the station. */
      local station_front_x = station_x + 1;
      local station_front_y = station_y;
      
      /* Will try to build the road if the current coordinates point to a tile that is a road tile without something already on it. */
      if(AIRoad.IsRoadTile(AIMap.GetTileIndex(station_x, station_y)))
      {
        if(new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
        if(!new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
        if(station_built)
        {
          return AIMap.GetTileIndex(station_x, station_y);		  
        }
        else
        {
          station_front_x = station_x;
          station_front_y = station_y + 1;
          if(new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
          if(!new_station) station_built = AIRoad.BuildDriveThroughRoadStation(AIMap.GetTileIndex(station_x, station_y), AIMap.GetTileIndex(station_front_x, station_front_y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_JOIN_ADJACENT);
          if(station_built)
          {
            return AIMap.GetTileIndex(station_x, station_y);
          }
        }
      }
    }
    radius = radius + 1;
  }
}


function RIAI:: BuildAirports(){
	AILog.Info("mary claire");
	
	//builds airplane and gives orders
	local air_engine_list = AIEngineList(AIVehicle.VT_AIR);
	air_engine_list.Valuate(AIEngine.GetCargoType);
	air_engine_list.Sort(AIAbstractList.SORT_BY_VALUE, false)
	AILog.Info(AIEngine.GetName(air_engine_list.Begin()));
	local plane = air_engine_list.Next();
	AILog.Info(AIEngine.GetName(plane));
	local build_plane = false;
		
	//gets town list and sorts so that largest are at the top of the list - gets the largest town - this is where we will attempt to build the first airport
	local townlist = AITownList();
	townlist.Valuate(AITown.GetPopulation);
	townlist.RemoveBelowValue(750);
	townlist.Sort(AIAbstractList.SORT_BY_VALUE, false);
	//prints names of towns in townlist
	while(townlist.HasNext()){
		AILog.Info("townlist: " + AITown.GetName(townlist.Next()));
	}
	local townid_a = townlist.Begin();
	
	//finds a proper location to build the airport on	
	local town_center = AITown.GetLocation(townid_a);
	AILog.Info("town center tile: " + town_center);
	local town_center_x = AIMap.GetTileX(town_center);
	local town_center_y = AIMap.GetTileY(town_center);
	local airport_built = false;
	local apx1 = town_center_x;
	local apy1 = town_center_y;
	local apx2 = town_center_x;
	local apy2 = town_center_y
	local apx3 = town_center_x;
	local apy3 = town_center_y;
	local order1 = false;
	local order2 = false;
	local order3 = false;
	//finds place to put airport by circling around the town until the airport is built
	while(airport_built == false){	
		for(local i = 0; i<7; i=i+1){
			for(local j = 0; j<7; j=j+1){	
				
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x+i, town_center_y+j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){
						build_plane = AIVehicle.BuildVehicle(AIAirport.GetHangarOfAirport(AIMap.GetTileIndex(town_center_x+i, town_center_y+j)), plane);
						apx1 = town_center_x+i;
						apy1 = town_center_y+j;
						order1 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx1,apy1), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}			
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x-i, town_center_y-j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){
						build_plane = AIVehicle.BuildVehicle(AIAirport.GetHangarOfAirport(AIMap.GetTileIndex(town_center_x-i, town_center_y-j)), plane);
						apx1 = town_center_x-i;
						apy1 = town_center_y-j;
						order1 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx1,apy1), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
				if(airport_built==true){
						break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x+i, town_center_y-j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){
						build_plane = AIVehicle.BuildVehicle(AIAirport.GetHangarOfAirport(AIMap.GetTileIndex(town_center_x+i, town_center_y-j)), plane);
						apx1 = town_center_x+i;
						apy1 = town_center_y-j;
						order1 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx1,apy1), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x-i, town_center_y+j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){
						build_plane = AIVehicle.BuildVehicle(AIAirport.GetHangarOfAirport(AIMap.GetTileIndex(town_center_x-i, town_center_y+j)), plane);
						apx1 = town_center_x-i;
						apy1 = town_center_y+j;
						order1 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx1,apy1), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
			}
		}
		if(airport_built==false){
			//removes town from townlist because an airport cannot be built there - moves to next town and tries to build
			townlist.RemoveItem(townid_a);
			if(townlist.HasNext==false){
        return;
			}
			townid_a = townlist.Begin();
			town_center = AITown.GetLocation(townid_a);
			AILog.Info("town center tile: " + town_center);
			town_center_x = AIMap.GetTileX(town_center);
			town_center_y = AIMap.GetTileY(town_center);
			AILog.Info("Can't build there, found a new town to build in: " + AITown.GetName(townid_a));
		}
	}
	
	AILog.Info("build_plane is: " + build_plane);
	
	//removes town from list of possible towns because we have built there
	townlist.RemoveItem(townid_a);
	//prints names of towns in townlist
	while(townlist.HasNext()){
		AILog.Info("townlist: " + AITown.GetName(townlist.Next()));
	}
	AILog.Info("First airport has been built: " + airport_built + " in " + AITown.GetName(townid_a));
	this.built_in_towns.AddItem(townid_a, -1);
	
	//builds second airport in the town farthest from the first from the townlist
	local townid_b = townlist.Begin();
	airport_built = false;
	while(airport_built == false){	
		AILog.Info("loop");
		townid_b = townlist.Begin();
		AILog.Info("This is what town B is: " + AITown.GetName(townid_b));
		local temp_town = townlist.Next();
		//gets the fathest town from the first airport of all those towns still in the town list
		while(townlist.HasNext()){
			local B = AITile.GetDistanceSquareToTile(AITown.GetLocation(townid_a), AITown.GetLocation(townid_b));
			local temp = AITile.GetDistanceSquareToTile(AITown.GetLocation(townid_a), AITown.GetLocation(temp_town));
			if(B<temp){
					townid_b = temp_town;
					temp_town = townlist.Next();
					AILog.Info("town B: " + AITown.GetName(townid_b));
					AILog.Info("temp town: " + AITown.GetName(temp_town));
			}
				temp_town = townlist.Next();
		}
		//finds a proper location to build the airport within selected town
		local town_center2 = AITown.GetLocation(townid_b);
		AILog.Info("town center tile: " + town_center2);
		local town_center_x2 = AIMap.GetTileX(town_center2);
		local town_center_y2 = AIMap.GetTileY(town_center2);
		//tries to build the airport in the selected town
		for(local i = 0; i<9; i=i+1){
			for(local j = 0; j<9; j=j+1){	
				
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x2+i, town_center_y2+j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){	
						apx2 = town_center_x2+i;
						apy2 = town_center_y2+j;
						order2 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx2,apy2), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}			
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x2-i, town_center_y2-j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){		
						apx2 = town_center_x2-i;
						apy2 = town_center_y2-j;
						order2 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx2,apy2), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x2+i, town_center_y2-j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){		
						apx2 = town_center_x2+i;
						apy2 = town_center_y2-j;
						order2 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx2,apy2), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x2-i, town_center_y2+j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){	
						apx2 = town_center_x2-i;
						apy2 = town_center_y2+j;
						order2 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx2,apy2), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
			}
		}
		if(airport_built==false){
			//removes town from townlist because an airport cannot be built there - while loop will then try whole process again
			townlist.RemoveItem(townid_b);
			if(townlist.HasNext==false){
				if(second_loop == true){
					townlist = AITownList();
					townlist.Valuate(AITown.GetPopulation);
					townlist.RemoveBelowValue(150);
					townlist.RemoveAboveValue(750);
					townlist.Sort(AIAbstractList.SORT_BY_VALUE, false);
					townid_b = townlist.Begin();
				}else{return;}
			}
			townid_b = townlist.Begin();
			town_center = AITown.GetLocation(townid_b);
			AILog.Info("town center tile: " + town_center);
			town_center_x2 = AIMap.GetTileX(town_center);
			town_center_y2 = AIMap.GetTileY(town_center);
			AILog.Info("Can't build there, found a new town to build in: " + AITown.GetName(townid_b));
		}
	}
	AILog.Info("Second airport has been built: " + airport_built + " in " + AITown.GetName(townid_b));
	this.built_in_towns.AddItem(townid_b, -1);
	
	AILog.Info(build_plane);
	
	AILog.Info("Money: " + AICompany.GetBankBalance(AICompany.COMPANY_SELF));
	AILog.Info(AICompany.GetName(AICompany.COMPANY_SELF));
	
	//gives plane orders
	AILog.Info("Order 1 was: " + order1);
	AILog.Info("Order 2 was: " + order2);
	AIVehicle.StartStopVehicle(build_plane);
		
	AICompany.SetLoanAmount(300000);
	
	townlist.RemoveItem(townid_b);
	//builds third airport in the town farthest from the first from the townlist
	local townid_c = townlist.Begin();
	airport_built = false;
	while(airport_built == false){	
		AILog.Info("loop");
		townid_c = townlist.Begin();
		AILog.Info("This is what town B is: " + AITown.GetName(townid_c));
		local temp_town = townlist.Next();
		//gets the fathest town from the first airport of all those towns still in the town list
		while(townlist.HasNext()){
			local C = AITile.GetDistanceSquareToTile(AITown.GetLocation(townid_a), AITown.GetLocation(townid_c));
			local temp = AITile.GetDistanceSquareToTile(AITown.GetLocation(townid_a), AITown.GetLocation(temp_town));
			if(C<temp){
				townid_c = temp_town;
				temp_town = townlist.Next();
				AILog.Info("town B: " + AITown.GetName(townid_c));
				AILog.Info("temp town: " + AITown.GetName(temp_town));
			}
				temp_town = townlist.Next();
		}
		//finds a proper location to build the airport within selected town
		local town_center3 = AITown.GetLocation(townid_c);
		AILog.Info("town center tile: " + town_center3);
		local town_center_x3 = AIMap.GetTileX(town_center3);
		local town_center_y3 = AIMap.GetTileY(town_center3);
		//tries to build the airport in the selected town
		for(local i = 0; i<9; i=i+1){
			for(local j = 0; j<9; j=j+1){	
				
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x3+i, town_center_y3+j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){	
						apx3 = town_center_x3+i;
						apy3 = town_center_y3+j;
						order3 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx3,apy3), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}			
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x3-i, town_center_y3-j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){		
						apx3 = town_center_x3-i;
						apy3 = town_center_y3-j;
						order3 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx3,apy3), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x3+i, town_center_y3-j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){		
						apx3 = town_center_x3+i;
						apy3 = town_center_y3-j;
						order3 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx3,apy3), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
				if(airport_built==true){
					break;
				}else{
					airport_built = AIAirport.BuildAirport(AIMap.GetTileIndex(town_center_x3-i, town_center_y3+j), AIAirport.AT_LARGE, AIStation.STATION_NEW);
					if(airport_built==true){	
						apx3 = town_center_x3-i;
						apy3 = town_center_y3+j;
						order3 = AIOrder.AppendOrder(build_plane, AIMap.GetTileIndex(apx3,apy3), AIOrder.AIOF_FULL_LOAD_ANY);
					}
				}
			}
		}
		if(airport_built==false){
			//removes town from townlist because an airport cannot be built there - while loop will then try whole process again
			townlist.RemoveItem(townid_c);
			if(townlist.HasNext==false){
				if(second_loop == true){
					townlist = AITownList();
					townlist.Valuate(AITown.GetPopulation);
					townlist.RemoveBelowValue(150);
					townlist.RemoveAboveValue(750);
					townlist.Sort(AIAbstractList.SORT_BY_VALUE, false);
					townid_c = townlist.Begin();
				}else{return;}
			}
			townid_c = townlist.Begin();
			town_center = AITown.GetLocation(townid_c);
			AILog.Info("town center tile: " + town_center);
			town_center_x3 = AIMap.GetTileX(town_center);
			town_center_y3 = AIMap.GetTileY(town_center);
			AILog.Info("Can't build there, found a new town to build in: " + AITown.GetName(townid_c));
		}else{this.built_in_towns.AddItem(townid_c, -1);}
	}
	
	//builds airplane and gives orders
	local air_engine_list2 = AIEngineList(AIVehicle.VT_AIR);
	air_engine_list2.Valuate(AIEngine.GetCargoType);
	air_engine_list2.Sort(AIAbstractList.SORT_BY_VALUE, false)
	AILog.Info(AIEngine.GetName(air_engine_list2.Begin()));
	local plane2 = air_engine_list2.Next();
	plane2 = air_engine_list2.Next();
	plane2 = air_engine_list2.Next();
	AILog.Info(AIEngine.GetName(plane2));
	local build_plane2 = false;
	
	local total_pop = AITown.GetPopulation(townid_a)+AITown.GetPopulation(townid_b);
	AILog.Info("total pop: " + total_pop);
	if(total_pop>2600){
		AILog.Info("yay>3000");
		local build_plane2 = AIVehicle.BuildVehicle(AIAirport.GetHangarOfAirport(AIMap.GetTileIndex(apx1, apy1)), plane2);
		AILog.Info(build_plane2);
		local order4 = AIOrder.AppendOrder(build_plane2, AIMap.GetTileIndex(apx1,apy1), AIOrder.AIOF_FULL_LOAD_ANY);
		local order5 = AIOrder.AppendOrder(build_plane2, AIMap.GetTileIndex(apx2,apy2), AIOrder.AIOF_FULL_LOAD_ANY);
		AIVehicle.StartStopVehicle(build_plane2);
	}
	
	//while(airport_built==true){
		//AILog.Info("Money: " + AICompany.GetBankBalance(AICompany.COMPANY_SELF));
	//}
	
	AILog.Info("Leaving Airport Build Code");
}


function RIAI::Save()
{
  local table = {};	
  //TODO: Add your save data to the table.
  return table;
}
 
function RIAI::Load(version, data)
{
  AILog.Info(" Loaded");
  //TODO: Add your loading routines.
}
