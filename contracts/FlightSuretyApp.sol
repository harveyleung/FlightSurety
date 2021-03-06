pragma solidity ^0.4.24;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    uint256 private constant INSURANCE_MAX_AMOUNT = 1 ether;

    address private contractOwner;          // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    mapping(address => address[] ) private airlineVotes;

    FlightSuretyData dataContract ;





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
         // Modify to call data contract's status
        require(this.isOperational(), "Contract is currently not operational");
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

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                address dataContractAddress
                                )
                                public
    {
        contractOwner = msg.sender;
        //is it just a reference to the datacontract using it's smart contract address?
        dataContract = FlightSuretyData(dataContractAddress);

    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational()
                            public
                            returns(bool)
    {
        return dataContract.isOperational() ;
        //return true;  // Modify to call data contract's status
    }



    function setOperatingStatus(bool _mode)
                                            public
                                            requireContractOwner {
        dataContract.setOperatingStatus(_mode);
    }
    /*
    * Testing method only, no need to copy.
    */
    function getVotes(address passinAddress) public returns (uint256)
    {
        return  airlineVotes[passinAddress].length;
    }
    /**Testing method only, no need to copy.
    */
    function getPrecentage(address passinAddress) public returns (uint256)
    {
     uint256 noOfRegAirlines = dataContract._getRegisteredAirlinesNum();
      // return ( airlineVotes[passinAddress].length.div(noOfRegAirlines).mul(100));
        return (( airlineVotes[passinAddress].length).mul(100).div(noOfRegAirlines));
    }


    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


   /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline
                            (
                            address passinAirline
                            )
                            external

                            returns(bool success, uint256 votes)
                           // returns(uint256 number)
    {
        // check if msg.sender is registered?
        require(dataContract.isRegistered(msg.sender), 'Only registered airline can register ' );
        // check if msg.sender is paid as well
        require(dataContract.isPaid(msg.sender), 'Only paid airline can register another airline');

        //Check if passinAirline is not registered?
        require(!dataContract.isRegistered(passinAirline), 'Passin address Already registered!');
        //Check if passinAirline is not paid?
        require(!dataContract.isPaid(passinAirline), 'Only paid airline can register another airline');

        if(dataContract._getRegisteredAirlinesNum() < 4) {
            //registerAirline, register = true
            dataContract.registerAirline(passinAirline, true);

        } else {
            //If nothing added before
            if(airlineVotes[passinAirline].length == 0){
                address[] memory voters =  new address[](1);
                voters[0] = msg.sender;
                airlineVotes[passinAirline] = voters;
            } else{
                //check if msg.sender voted for passinAirline first
                bool isDuplicate = false;
                for(uint c=0; c<airlineVotes[passinAirline].length; c++) {
                    if (airlineVotes[passinAirline][c] == msg.sender) {
                        isDuplicate = true;
                        break;
                    }
                }
                require(!isDuplicate, "Caller has already called this function.");
                //msg.sender vote for passinAirline
                airlineVotes[passinAirline].push(msg.sender);
                //get no of votes in passinAirline

                //check if over 50% (no of votes/ no of registered Airlines)
                uint256 noOfRegAirlines = dataContract._getRegisteredAirlinesNum();
                if (airlineVotes[passinAirline].length.mul(100).div(noOfRegAirlines) >= 50  ) {

                    //airlines[newAirline].isRegistered = true;
                    //if yes, registered
                    dataContract.registerAirline(passinAirline,true);
                }

            }

        }
        return (success, airlineVotes[passinAirline].length);
//        number =  airlineVotes[passinAirline].length;
//        return number;
    }

    /** Fund airline to data contract, change it's status too
    */
    function fundAirline
        (

        )
        external
        payable
    {
        require(msg.value >= 10, "Not enough Ether to fund airline. Requires 10 ETH" );
        require(dataContract.isRegistered(msg.sender) == true, "Airline must be registered before fund!");
        require(dataContract.isPaid(msg.sender) == false, "Airline is already funded");

        //Transfer 10 ether to data contract
        dataContract.fund.value(msg.value)();
        //dataContract.setFund(msg.sender, true);
        //dataContract.transfer(msg.value);
        dataContract.setFund(msg.sender,true);
    }

    /**
     * get insureebalance
    */
    function insureeBalance() external view
        requireIsOperational
    returns (uint256)
    {
        return dataContract.insureeBalance(msg.sender);
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight
                                (
                                    address airline,
                                    string flightCode,
                                    uint256 timestamp
                                )
                                external
                                payable

    {

        //Do not allow more than 1 ether insurance
        require(msg.value <= INSURANCE_MAX_AMOUNT, "Maximum insurance amount exceeded");
        address(dataContract).transfer(msg.value);
        dataContract.buy(msg.sender, airline, flightCode, timestamp, msg.value);

    }



    function isAirline(
        address passinAirline
    )
    external
    view
   // requireIsCallerAuthorized
   // requireIsOperational
    returns(bool)
    {
        return dataContract.isRegistered(passinAirline);
    }


   /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flightCode,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                requireIsOperational
    {
        //Run creditissurance from datacontract when status code = 20
        if (statusCode == STATUS_CODE_LATE_AIRLINE) {
            dataContract.creditInsurees(airline, flightCode, timestamp);
        }
    }

    /*
    */

    function makeWithdrawal()
    external
    requireIsOperational
    {
        dataContract.pay(msg.sender);
    }



    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    }


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32)
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (
                                address account
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion


}
//Interface contract
contract FlightSuretyData {
    function _getRegisteredAirlinesNum() external returns(uint number);
    function isOperational() public view returns(bool);
    function setOperatingStatus (bool mode) external;
    function registerAirline(address airlineAddress, bool registered) external;

    function isPaid(address airlineAddress)  returns (bool);
    function isRegistered(address airlineAddress) returns (bool);
    function voteAirline(address airlineAddress) returns (uint8);
    function noOfVotes(address airlineAddress) returns (uint8);
    function fund () public payable {}
    function getBalance() public view returns (uint256);

    function buy(address sender, address airline, string flightCode, uint256 timestamp, uint256 amount) external;
    function insureeBalance(address sender) external returns (uint256);
    function creditInsurees(address airline, string flightCode, uint256 timestamp) external;
    function pay(address sender) external;

    function setFund (address airlineAddress, bool isFund) external ;
    function() external payable;
}