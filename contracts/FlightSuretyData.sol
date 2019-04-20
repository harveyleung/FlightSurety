pragma solidity ^0.4.25;

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

    struct Flight{             //Airline structure
        bool ed;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
        string id;
        bool hasBeenInsured;
    }
    //mapping (string => Flight) private registeredFlights;
    //mapping of flight -> passengers[]
    //mapping of key(flight+passenger) -> value (insurance)

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
    returns(uint256)
    {
        return airlineArray.length;

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
        if(airlines[passinAirline].exists){
            airlines[passinAirline] = Airline({
                registered : registered,
                feePaid: false,
                name: '',
                exists: true
            });
            airlineArray.push(passinAirline);
        } else{
            //already registered,
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



    //Register Flight, only check whether the pass-in airline has been registered

    function registerFlight
    (

    )
    external

    //requireContractOwner

    {


    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {
            //Check if msg.value <1
            //Only can less than 1
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                //flight no
                                )
                                external
                                pure
    {
        //This method will get the particular flight from the array and try to calculate all passengers (buy)
        // credits x 1.5

        //mark the flight isured status => true
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            //passenger address
                            )
                            external
                            pure
    {
        //withdraw the credit to passenger by the amount calculated in creditInsurees()

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

