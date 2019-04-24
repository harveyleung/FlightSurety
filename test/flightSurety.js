var Web3Utils = require('web3-utils');
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/
  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

    // Ensure that access is denied for non-Contract Owner account
    let accessDenied = false;
    try
    {
      await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
    }
    catch(e) {
      accessDenied = true;
    }
    assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;
    try
    {
      await config.flightSuretyData.setOperatingStatus(false);
    }
    catch(e) {
      accessDenied = true;
    }
    assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

    await config.flightSuretyData.setOperatingStatus(false);

    let reverted = false;
    try
    {
      await config.flightSurety.setTestingMode(true);
    }
    catch(e) {
      reverted = true;
    }
    assert.equal(reverted, true, "Access not blocked for requireIsOperational");

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {

    // ARRANGE
    let newAirline = accounts[2];
    //try to register using the first airline

    // ACT
    try {
      await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {
      //console.log(e);
    }
    let result = await config.flightSuretyData.isRegistered.call(newAirline);

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(airline) can register an Airline using registerAirline() if it is  funded', async () => {
    // ARRANGE
    let newAirline = accounts[2];

    let result3 = await config.flightSuretyData.isRegistered.call(newAirline);
    console.log("is newAirline  registered? = " + result3);

    try {

      //await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
      //First, fund first airline

      await config.flightSuretyApp.fundAirline.sendTransaction( {from: config.firstAirline, "value": 10});
      result = await config.flightSuretyData.isRegistered.call(config.firstAirline);

      //Try to register a new airline:
      await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});

    }
    catch(e) {
      console.log(e);
    }

    result = await config.flightSuretyData.isRegistered.call(newAirline);
    console.log("Is new airline registered? = " + result);
    assert.equal(result, true, "Airline could be registered by a registered and fund airline!");
  });


  it('Multi consensus testing  ', async () => {


    let result = await config.flightSuretyData._getRegisteredAirlinesNum.call();
    console.log("Registered airline = " + result);
    // ARRANGE


    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
    let newAirline6 = accounts[6];
    let newAirline7 = accounts[7];
    let newAirline8 = accounts[8];

    result = await config.flightSuretyData.isRegistered.call(config.firstAirline);
    console.log("Is firstAirline registered? "+ result);
    try {


      //await config.flightSuretyApp.fundAirline.sendTransaction( {from: config.firstAirline, "value": 10});
     //result = await config.flightSuretyData.isRegistered.call(config.firstAirline);


      await config.flightSuretyApp.registerAirline(newAirline3, {from: config.firstAirline});
      await config.flightSuretyApp.registerAirline(newAirline4, {from: config.firstAirline});
      await config.flightSuretyApp.registerAirline(newAirline5, {from: config.firstAirline});
      //await config.flightSuretyApp.registerAirline(newAirline6, {from: config.firstAirline});
     // await config.flightSuretyApp.registerAirline(newAirline7, {from: config.firstAirline});

      let result3 = await config.flightSuretyData.isRegistered.call(newAirline3);
      let result4 = await config.flightSuretyData.isRegistered.call(newAirline4);
      let result5 = await config.flightSuretyData.isRegistered.call(newAirline5);
     // let result6 = await config.flightSuretyData.isRegistered.call(newAirline6);
    //  let result7 = await config.flightSuretyData.isRegistered.call(newAirline7);

      console.log("Using firstAirline to register  other as well,  " + result3 + " " + result4 + " "+ result5 );

      let noOf =  await config.flightSuretyData._getRegisteredAirlinesNum.call();
      console.log("No of registered airlines = " + noOf);

      //second airline fund itself.
      await config.flightSuretyApp.fundAirline.sendTransaction( {from: accounts[2], "value": 10});
      //third airline fund itself
      await config.flightSuretyApp.fundAirline.sendTransaction( {from: accounts[3], "value": 10});
      //If yes, vote for 5th airline by account[2]
      await config.flightSuretyApp.registerAirline(newAirline5, {from: accounts[2]});
      result = await config.flightSuretyData.isRegistered.call(newAirline5);
      console.log("accounts[3] should be registered now " + result3);

    }
    catch(e) {
      console.log(e);
    }
    assert.equal(result, true, "Airline[5] registered after votes for more than 50% airlines");
  });


  it('(insurance) Stop passenger from paying more than 1 Ether for insurance', async () => {

    // ARRANGE
    let passenger = accounts[6];
    let airline2 = accounts[2];
    let flight = "ND1309";
    let value = Web3Utils.toWei("1.7", "ether");
    let reverted = false;

    //ACT
    try {
      //await config.flightSuretyApp.registerFlight(airline2, flight, 0, {from: passenger, value: value, gasPrice: 0});
      await config.flightSuretyApp.registerFlight.sendTransaction(airline2, flight, 0 ,{from: passenger, "value": value});
    } catch (e) {
      reverted = true;
      //console.log("Reverted = " + e);
    }

    // ASSERT
    assert.equal(reverted, true, "Error: Maximum insurance payment exceeded");

  });

  it('(insurance       ) Passenger can buy insurance for a maximum of 1 Ether', async () => {

    // ARRANGE
    let passenger = accounts[7];
    let airline2 = accounts[2];
    let flight = "ND1309";
    let value = Web3Utils.toWei("1", "ether");
    let reverted = false;

    //ACT
    try {
      //await config.flightSuretyApp.registerFlight(airline2, flight, 0, {from: passenger, value: value, gasPrice: 0});
      await config.flightSuretyApp.registerFlight.sendTransaction(airline2, flight, 0 ,{from: passenger, "value": value});
    } catch (e) {
      reverted = true;
      // console.log(e);
    }

    // ASSERT

    assert.equal(reverted, false, "Error: Maximum insurance payment exceeded");

  })

  it('(insurance       ) Passenger balance (before insurance claim) is 0', async () => {

    // ARRANGE
    let passenger = accounts[7];
    let balance = 7;
    let reverted = false;

    //ACT
    try {
      balance = await config.flightSuretyApp.insureeBalance({from: passenger});
    } catch (e) {
      reverted = true;
    }

    // ASSERT

    assert.equal(balance.toNumber(), 0, "Error while getting traveler balance");
    assert.equal(reverted, false, "Error while getting traveler balance");

  });

  it('(oracles         ) Call submitOracleResponse() in a loop to emit processFlightStatus() - inspired by oracle.js', async () => {
    // ARRANGE
    const ORACLES_COUNT = 10;
    const STATUS_CODE_LATE_AIRLINE = 20;
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();
    let airline = accounts[2];
    let flight = 'ND1309';

    // ACT
    for(let i = 1; i < ORACLES_COUNT; i++) {
      await config.flightSuretyApp.registerOracle({from: accounts[i], value: fee});
      await config.flightSuretyApp.fetchFlightStatus(airline, flight, 0, {from: accounts[i]});

      for (let j = 0; j < 5; j++) {
        try {
          await config.flightSuretyApp.submitOracleResponse(j, airline, flight, 0, STATUS_CODE_LATE_AIRLINE, {from: accounts[i]});
          //console.log("Valid response received " + j);
        } catch (e) {
          //console.log(e.message);
        }
      }
    }
  });

  it('(passenger       ) check passenger was credited 1.5x but do not withdraw amount', async () => {
    let insuree = accounts[7];
    let reverted = false;
    let balance = 0;

    try {
      balance = await config.flightSuretyApp.insureeBalance({from: insuree});
    }
    catch(e) {
      reverted = true;
    }

    // ASSERT
    assert.equal(reverted, false, "Error:Unable to check balance.");

    assert.equal(balance.toString(), new BigNumber("1500000000000000000").toString(), "Error: Balance not credited.");
  });

  it('(passenger       ) Initiate withdrawal to account', async () => {
    //Insure one more flight

    let passenger = accounts[8];
    let airline2 = accounts[2];
    let flight = "ND1309";
    let value = Web3Utils.toWei("1", "ether");

    try {
      //await config.flightSuretyApp.registerFlight(airline2, flight, 0, {from: passenger, value: value, gasPrice: 0});
      await config.flightSuretyApp.registerFlight.sendTransaction(airline2, flight, 0 ,{from: passenger, "value": value});
    } catch (e) {
      reverted = true;
      // console.log(e);
    }

    let status = await config.flightSuretyData.getBalance.call();
    console.log("Data Contract Balance = "  + status);


    let insuree = accounts[7];
    let initialBalance = await web3.eth.getBalance(insuree)

    let balance = 1000;

    let reverted = false;
    try {
      await config.flightSuretyApp.makeWithdrawal({from: insuree});
      balance = await config.flightSuretyApp.insureeBalance({from: insuree});
    }
    catch(e) {
      reverted = true;
       console.log(e);
    }

    let currentBalance = await web3.eth.getBalance(insuree);

    assert.equal(reverted, false, "Failure on withdraw to passanger account.");
    assert.equal(balance.toString(), "0", "Balance should be 0");
    assert.equal(new BigNumber(currentBalance.toString()).isGreaterThan(new BigNumber(initialBalance.toString())), true, "Invalid balance on account");
  });

  it('(passenger       ) prevent multiple withdrawal to account', async () => {
    let insuree = accounts[7];
    let initialBalance = await web3.eth.getBalance(insuree);

    let reverted = false;
    try {
      await config.flightSuretyApp.makeWithdrawal({from: insuree});
    }
    catch(e) {
      reverted = true;
      //console.log(e);
    }

    let currentBalance = await web3.eth.getBalance(insuree);
    assert.equal(reverted, false, "Error. Contract should not allow multiple withdrawals.");
    assert.equal(new BigNumber(currentBalance.toString()).isEqualTo(new BigNumber(initialBalance.toString())), false, "Error: Balance is in error");
  });





});
