pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    mapping(address => uint8) private authorizedContracts;              // Mapping for checking whether caller is authorized

    struct Airline{             //Airline structure
        bool registered;
        bool feePaid;
        string name;
        bool exists;
    }

    mapping (address=> Airline) private airlines; //Registered airlines
    address[] private airlineArray; //Array of airline addresses

    //struct of data for each insured passenger
    struct FlightInsurance {
        bool isInsured;// is passenger insured
        bool isCredited;//used to determine if the passenger was payed(avoid multiple payments)
        uint256 amount;//amount passenger is insured
    }

    //What will be payble to each insured passenger (or what was payed?)
    mapping(address => uint256) private insureeBalances;

    //Insurance details of each passenger (all flights)
    mapping(bytes32 => FlightInsurance) private flightInsurances;

    //List of insured passengers per flight
    mapping(bytes32 => address[]) private insureesMap;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/




    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                    address firstAirline
                                ) 
                                public 
    {
        contractOwner = msg.sender;

        airlines[firstAirline] = Airline({
            registered : true,
            feePaid: false,
            name: '',
            exists: true
            });
        //register firstairline here
        airlineArray.push(firstAirline);
    }



    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireFlightNotInsured(address sender, address airline, string flightCode, uint256 timestamp){
        require(!isFlightInsured(sender, airline, flightCode, timestamp), "Passenger is already insured");
        _;
    }

    /*
    * Let contract owner to add authorize contract here
    */
    function authorizeCaller
    (
        address contractAddress
    )
    external
    //requireContractOwner
    {
        authorizedContracts[contractAddress] = 1;
    }

    /**
    * Let contract owner decide to remove authorize contract here
    */
    function deAuthorizeCaller
    (
        address contractAddress
    )
    external
    //requireContractOwner
    {
        delete authorizedContracts[contractAddress];
    }

    function isAuthorizedCaller (address caller) public view returns (bool) {
        return authorizedContracts[caller] == 1;
    }


    function isFlightInsured(address sender, address airline, string flightCode, uint256 timestamp) public view
    returns (bool)
    {
        FlightInsurance storage insurance = flightInsurances[getKey(sender, airline, flightCode, timestamp)];
        return insurance.isInsured;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isRegistered(
        address passinAirline
    )
    public
    view
    returns(bool)
    {
        return airlines[passinAirline].registered;
    }

    function isPaid(
        address passinAirline
    )
    public
    view
    returns(bool)
    {
        return airlines[passinAirline].feePaid;
    }


    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational()
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


    function _getRegisteredAirlinesNum()
    external
    view
   // requireIsOperational
    returns
    (
        uint256 number
    )
    {
        //Get the number of airlines registered
        number = airlineArray.length;
        return number;
       // number = 100;
       // return number;
    }



    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline
                            (
                                address passinAirline,
                                bool registered
                            )
                            external

                           // requireContractOwner

    {
        //If not exists, add a new one to the list
        if(!airlines[passinAirline].exists){
            airlines[passinAirline] = Airline({
                registered : registered,
                feePaid: false,
                name: '',
                exists: true
            });
            airlineArray.push(passinAirline);
        } else{
            //already exists,
            if(registered)
                airlines[passinAirline].registered = true;
        }

    }

    function setFund
    (
        address passinAirline,
        bool isFund
    )
    external
    //requireContractOwner
    {
        airlines[passinAirline].feePaid = true;
    }

    function insureeBalance (address sender) external
        requireIsOperational
        //requireIsCallerAuthorized
            view
        returns (uint256)
    {
        return insureeBalances[sender];
    }




    //Register Flight, only check whether the pass-in airline has been registered

    function registerFlight
    (

    )
    external

    //requireContractOwner

    {


    }


    function buy
    (
        address sender,
        address airline,
        string flightCode,
        uint256 timestamp,
        uint256 insuranceAmount
    )
    external
    requireIsOperational
   // requireIsCallerAuthorized
    requireFlightNotInsured(sender, airline, flightCode, timestamp)
    {
        FlightInsurance storage flInsurance = flightInsurances[getKey(sender, airline, flightCode, timestamp)];
        flInsurance.isInsured = true;
        flInsurance.amount = insuranceAmount;

        saveInsuree(sender, airline, flightCode, timestamp);
    }

    function saveInsuree(address sender, address airline, string flightCode, uint256 timestamp) internal requireIsOperational {
        address [] storage insurees = insureesMap[getKey(address(0), airline, flightCode, timestamp)];
        bool insureeExists = false;

        for(uint256 i = 0; i < insurees.length; i++) {
            if(insurees[i] == sender) {
                insureeExists = true;
                break;
            }
        }

        if(!insureeExists) {
            insurees.push(sender);
        }
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
    (
        address airline,
        string flightCode,
        uint256 timestamp
    )
    external
    requireIsOperational
   // requireIsCallerAuthorized
    {
        address [] storage insurees = insureesMap[getKey(address(0), airline, flightCode, timestamp)];

        for(uint i = 0; i < insurees.length; i++) {
            FlightInsurance storage insurance = flightInsurances[getKey(insurees[i], airline, flightCode, timestamp)];

            //Verify the passenger was not previously credited before
            // his payment amount is increased by 1.5x
            if(insurance.isInsured && !insurance.isCredited) {
                insurance.isCredited = true;
                insureeBalances[insurees[i]] = insureeBalances[insurees[i]].add(insurance.amount.div(10).mul(15));
            }
        }
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay (address sender) external
    requireIsOperational
    //requireIsCallerAuthorized
    {
        //Fail fast if contract has no funds
        require(address(this).balance >= insureeBalances[sender], "Error: Not enought funds in contract");
        //Continue with withdrawl
        uint256 tmp = insureeBalances[sender];
        insureeBalances[sender] = 0;
        sender.transfer(tmp);

    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *      (For airline)
    */   
    function fund
                            (   
                            )
                            public
                            payable

    {
          //got pay here from ?
            //isPaid = true

    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getKey(
        address insuree,
        address airline,
        string memory flight,
        uint256 timestamp
    ) pure internal returns(bytes32){
        return keccak256(abi.encodePacked(insuree, airline, flight, timestamp));
    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

