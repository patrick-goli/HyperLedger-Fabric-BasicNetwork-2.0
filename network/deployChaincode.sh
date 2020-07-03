export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/config/

export PRIVATE_DATA_CONFIG=${PWD}/private-data/collections_config.json

export CHANNEL_NAME=mychannel

setGlobalsForOrderer() {
  export CORE_PEER_LOCALMSPID="OrdererMSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp

}

setGlobalsForPeer0Org1() {
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  # export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:7051
}

setGlobalsForPeer1Org1() {
  export CORE_PEER_LOCALMSPID="Org1MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  export CORE_PEER_ADDRESS=localhost:8051

}

setGlobalsForPeer0Org2() {
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:9051

}

setGlobalsForPeer1Org2() {
  export CORE_PEER_LOCALMSPID="Org2MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  export CORE_PEER_ADDRESS=localhost:10051

}

setGlobalsForPeer0Org3() {
  export CORE_PEER_LOCALMSPID="Org3MSP"
  export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
  export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
  export CORE_PEER_ADDRESS=localhost:19051

}

  CC_RUNTIME_LANGUAGE="java"
  CC_NAME="fabcar"
  VERSION="1"
  CC_SRC_PATH="../chaincode/fabcar/java/build/install/fabcar"

presetup() {
  echo Compiling Java code ...
  pushd ../chaincode/fabcar/java || return
  ./gradlew installDist
  popd || return
  echo Finished compiling Java code
}

packageChaincode() {
  rm -rf ${CC_NAME}.tar.gz
  setGlobalsForPeer0Org1
  peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
    --label ${CC_NAME}_${VERSION}
  echo "===================== Chaincode is packaged on peer0.org1 ===================== "
}

installChaincode() {
  setGlobalsForPeer0Org1
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  echo "===================== Chaincode is installed on peer0.org1 ===================== "

  # setGlobalsForPeer1Org1
  # peer lifecycle chaincode install ${CC_NAME}.tar.gz
  # echo "===================== Chaincode is installed on peer1.org1 ===================== "

  setGlobalsForPeer0Org2
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  echo "===================== Chaincode is installed on peer0.org2 ===================== "

  setGlobalsForPeer0Org3
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  echo "===================== Chaincode is installed on peer0.org3 ===================== "
}

queryInstalled() {
  setGlobalsForPeer0Org1
  peer lifecycle chaincode queryinstalled >&log.txt
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  echo PackageID is "${PACKAGE_ID}"
  echo "===================== Query installed successful on peer0.org1 on channel ===================== "
}

approveForMyOrg1() {
  setGlobalsForPeer0Org1
  # set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com --tls \
    --collections-config "$PRIVATE_DATA_CONFIG" \
    --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
    --init-required --package-id "${PACKAGE_ID}" \
    --sequence ${VERSION}
  # set +x

  echo "===================== chaincode approved from org 1 ===================== "

}

approveForMyOrg2() {
  setGlobalsForPeer0Org2

  peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED \
    --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} \
    --collections-config "$PRIVATE_DATA_CONFIG" \
    --version ${VERSION} --init-required --package-id "${PACKAGE_ID}" \
    --sequence ${VERSION}

  echo "===================== chaincode approved from org 2 ===================== "
}

# approveForMyOrg2

approveForMyOrg3() {
  setGlobalsForPeer0Org3

  peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com --tls $CORE_PEER_TLS_ENABLED \
    --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} \
    --collections-config "$PRIVATE_DATA_CONFIG" \
    --version ${VERSION} --init-required --package-id "${PACKAGE_ID}" \
    --sequence ${VERSION}

  echo "===================== chaincode approved from org 3 ===================== "
}

checkCommitReadyness() {
  echo "===================== checking commit readyness from org $1 ===================== "
  setGlobalsForPeer0Org"$1"
  peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --collections-config "$PRIVATE_DATA_CONFIG" \
    --name ${CC_NAME} --version ${VERSION} --sequence ${VERSION} --output json --init-required
}


# provide addressess of the endorsing peers
commitChaincodeDefination() {
  setGlobalsForPeer0Org1
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED --cafile "$ORDERER_CA" \
    --channelID $CHANNEL_NAME --name ${CC_NAME} \
    --collections-config "$PRIVATE_DATA_CONFIG" \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    --version ${VERSION} --sequence ${VERSION} --init-required

}

queryCommitted() {
  setGlobalsForPeer0Org2
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}

}

chaincodeInvokeInit() {
  setGlobalsForPeer0Org2
  peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED --cafile "$ORDERER_CA" \
    -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    --isInit -c '{"Args":[]}'

}

chaincodeInvoke() {
  # setGlobalsForPeer0Org1
  # peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
  # --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} \
  # --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
  # --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA  \
  # -c '{"function":"initLedger","Args":[]}'

  setGlobalsForPeer0Org1

  ## Create Car
  # peer chaincode invoke -o localhost:7050 \
  #     --ordererTLSHostnameOverride orderer.example.com \
  #     --tls $CORE_PEER_TLS_ENABLED \
  #     --cafile $ORDERER_CA \
  #     -C $CHANNEL_NAME -n ${CC_NAME}  \
  #     --peerAddresses localhost:7051 \
  #     --tlsRootCertFiles $PEER0_ORG1_CA \
  #     --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA   \
  #     -c '{"function": "createCar","Args":["Car-ABCDEEE", "Audi", "R8", "Red", "Kouassi"]}'

  ## Init ledger
  peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile "$ORDERER_CA" \
    -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    -c '{"function": "initLedger","Args":[]}'

  ## Add private data
  export CAR=$(echo -n "{\"key\":\"1111\", \"make\":\"Tesla\",\"model\":\"Tesla A1\",\"color\":\"White\",\"owner\":\"Kouassi\",\"price\":\"10000\"}" | base64 | tr -d \\n)
  peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile "$ORDERER_CA" \
    -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    -c '{"function": "createPrivateCar", "Args":[]}' \
    --transient "{\"car\":\"$CAR\"}"
}

chaincodeQuery() {
  setGlobalsForPeer0Org1

  # Query all cars
  peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["queryAllCars"]}'

  # Query Car by Id
  #peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "queryCar","Args":["CAR0"]}'
  #'{"Args":["GetSampleData","Key1"]}'

  # Query Private Car by Id
  #peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "readPrivateCar","Args":["1111"]}'
  #peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "readCarPrivateDetails","Args":["1111"]}'
}

# Run this function if you add any new dependency in chaincode
presetup

packageChaincode
installChaincode
queryInstalled
approveForMyOrg1
checkCommitReadyness 1
approveForMyOrg2
checkCommitReadyness 2

# @ Kouassi
approveForMyOrg3
checkCommitReadyness 3
# @ Kouassi
commitChaincodeDefination
queryCommitted
chaincodeInvokeInit
sleep 4
chaincodeInvoke
sleep 3
chaincodeQuery
