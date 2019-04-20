
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


    let newAirline3 = accounts[3];
    let newAirline4 = accounts[4];
    let newAirline5 = accounts[5];
    let newAirline6 = accounts[6];
    let newAirline7 = accounts[7];
    let newAirline8 = accounts[8];
    let result = await config.flightSuretyData._getRegisteredAirlinesNum() ;
    console.log("No of registered airlines =  " + result);
    // ACT
    try {

      //funded airline can register 4 airlines
      await config.flightSuretyApp.registerAirline(newAirline3, {from: config.firstAirline});

    //  await config.flightSuretyApp.registerAirline(newAirline4, {from: config.firstAirline});
   //   await config.flightSuretyApp.registerAirline(newAirline5, {from: config.firstAirline});
    //  await config.flightSuretyApp.registerAirline(newAirline6, {from: config.firstAirline});

    }
    catch(e) {
      console.log("error in funding an Airline ",e)
    }

    let result1 = await config.flightSuretyData.isRegistered.call( accounts[1]);
    let result2 = await config.flightSuretyData.isRegistered.call( accounts[2]);
    let result3 = await config.flightSuretyData.isRegistered.call(newAirline3);
    let result4 = await config.flightSuretyData.isRegistered.call(newAirline4);
    let result5 = await config.flightSuretyData.isRegistered.call(newAirline5);
    let result6 = await config.flightSuretyData.isRegistered.call(newAirline6);
    console.log("Is new airline registered? = " + result1+ " " +result2 + " "+result3 + " " + result4 + " " + result5 + " " + result6);


  });

});
