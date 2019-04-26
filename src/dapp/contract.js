import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';

import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));

       // this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);

        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];

            let counter = 1;

            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            //Initial for 5 airlines,

            callback();
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.airlines[0],
            flight: flight,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }

    registerFlight(flight, value, callback) {
        let self = this;
        let flightNumber = flight;
        let flightTime =  Math.floor(Date.now() / 1000)
       // let flightTime = 5678;
        console.log("Going to send to airline = " + self.airlines[0] + " passengers = " + self.passengers[0]);
        console.log("Flight " + flightNumber  + " timestamp=" + flightTime);

        self.flightSuretyApp.methods
            .registerFlight(self.airlines[0], flightNumber,flightTime )
            .send({from: self.passengers[0], value: self.web3.utils.toWei(value, "ether"), gas:3000000 }, (error, result) => {
                if (error) {
                    console.log("ERROR:");
                    console.log(error);
                } else {
                    console.log(result);
                    callback(result);
                }
            });
    } //end registerFlight

    oracleReport(callback) {
        let self = this;
        self.flightSuretyApp.events.OracleReport({}, function (error, event) {
            if (error) {
                console.log(error);
            } else {
                callback(event.returnValues);
            }
        })
    }

    flightStatusInfo(callback) {
        let self = this;
        self.flightSuretyApp.events.FlightStatusInfo({}, function (error, event) {
            if (error) {
                console.log(error);
            } else {
                callback(event.returnValues);
            }
        })
    }


}