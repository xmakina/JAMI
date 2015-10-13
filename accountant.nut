/*
 *	The accountant is responsible for keeping the books healthy and balanced
 */
 
class Accountant{
	function GetMaxFunds();
	function MaximiseFunds();
	function MinimiseFunds();
}

function Accountant::GetMaxFunds(){
	local totalfunds = AICompany.GetBankBalance(AICompany.COMPANY_SELF) - AICompany.GetLoanAmount();
	totalfunds += AICompany.GetMaxLoanAmount();
	
	AILog.Info("ACCOUNTANT: The most we can spend is " + totalfunds);
	return totalfunds;
}

function Accountant::MaximiseFunds(){
	//Do everything possible to raise as much capital as we can
	AILog.Info("ACCOUNTANT: Maximising liquid assets");
	AICompany.SetLoanAmount(AICompany.GetMaxLoanAmount());
	
	local vehicles = AIVehicleList();
	vehicles.Valuate(AIVehicle.GetState);
	vehicles.KeepValue(AIVehicle.VS_IN_DEPOT);
	
	//Liquidise any unused vehicles
	local veh = vehicles.Begin();
	while(vehicles.HasNext()){
		AIVehicle.SellVehicle(veh);
		veh = vehicles.Next();
	}
}

function Accountant::MinimiseFunds(){
	//Do everything possible to reduce our capital to MINIMUM_SAFE_BALANCE
	AILog.Info("ACCOUNTANT: Reducing borrowings");
	
	local loanneeded = MINIMUM_SAFE_BALANCE - 
		AICompany.GetBankBalance(AICompany.ResolveCompanyID(AICompany.COMPANY_SELF)) + AICompany.GetLoanAmount();
	if(loanneeded > 0){
		AICompany.SetMinimumLoanAmount(loanneeded);
	} else {
		AICompany.SetLoanAmount(0);
	}
	
}