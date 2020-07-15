const process = require('child_process');

console.log(`${__dirname}/../../network/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt`)

const NET_ROOT = `./../../network`
const CC_NAME = "fabcar";
const CHANNEL_NAME = "mychannel";

let envVars = `
export CORE_PEER_TLS_ENABLED=true &&
export ORDERER_CA=${NET_ROOT}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem &&
export PEER0_ORG1_CA=${NET_ROOT}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt &&
export PEER0_ORG2_CA=${NET_ROOT}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt &&
export PEER0_ORG3_CA=${NET_ROOT}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt &&
export FABRIC_CFG_PATH=${NET_ROOT}/config/`

let variables = `export CORE_PEER_LOCALMSPID="Org1MSP" &&
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA &&
export CORE_PEER_MSPCONFIGPATH=${NET_ROOT}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && 
export CORE_PEER_ADDRESS=localhost:7051`;

process.exec(envVars,
    function (err, stdout, stderr) {
        if (err) {
            console.log("\n" + stderr);
        } else {
            console.log(stdout);
        }
    });

process.exec(variables,
    function (err, stdout, stderr) {
        if (err) {
            console.log("\n" + stderr);
        } else {
            console.log(stdout);
        }
    });

process.exec(`peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{"Args":["queryAllCars"]}'`,
    function (err, stdout, stderr) {
        if (err) {
            console.log("\n" + stderr);
        } else {
            console.log(stdout);
        }
    });