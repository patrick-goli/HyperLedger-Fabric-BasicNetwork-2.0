export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/config/

export PRIVATE_DATA_CONFIG=${PWD}/private-data/collections_config.json

setGlobals(){
  ORG=$1
  PEER=$2
  if [ "$ORG" -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    if [ "$PEER" -eq 0 ]; then
      export CORE_PEER_ADDRESS=localhost:7051
    elif [ "$PEER" -eq 1 ]; then
      export CORE_PEER_ADDRESS=localhost:8051
    fi

  elif [ "$ORG" -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    if [ "$PEER" -eq 0 ]; then
      export CORE_PEER_ADDRESS=localhost:9051
    elif [ "$PEER" -eq 1 ]; then
      export CORE_PEER_ADDRESS=localhost:10051
    fi
  # @ Kouassi
  elif [ "$ORG" -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    if [ "$PEER" -eq 0 ]; then
      export CORE_PEER_ADDRESS=localhost:19051
    fi
  else
    echo "================== ERROR !!! ORG or Peer Unknown =================="
  fi
}
  CHANNEL_NAME=mychannel
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
  setGlobals 1 0
  peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} \
    --label ${CC_NAME}_${VERSION}
  echo "===================== Chaincode is packaged on peer0.org1 ===================== "
}

installChaincode() {
  setGlobals 1 0
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  echo "===================== Chaincode is installed on peer0.org1 ===================== "

  setGlobals 2 0
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  echo "===================== Chaincode is installed on peer0.org2 ===================== "

  setGlobals 3 0
  peer lifecycle chaincode install ${CC_NAME}.tar.gz
  echo "===================== Chaincode is installed on peer0.org3 ===================== "
}

queryInstalled() {
  setGlobals 1 0
  peer lifecycle chaincode queryinstalled >&log.txt
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  echo PackageID is "${PACKAGE_ID}"
  echo "===================== Query installed successful on peer0.org1 on channel ===================== "
}

approveForMyOrg() {
  setGlobals "$1" 0
  # set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com --tls \
    --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} \
    --version ${VERSION} --package-id "${PACKAGE_ID}" \
    --sequence ${VERSION}
  # set +x

  echo "===================== chaincode approved from org $1 ===================== "

}


checkCommitReadyness() {
  echo "===================== checking commit readyness from org $1 ===================== "
  setGlobals "$1" 0
  peer lifecycle chaincode checkcommitreadiness \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${VERSION} \
    --sequence ${VERSION} --output json
}


# provide addressess of the endorsing peers
commitChaincodeDefination() {
  setGlobals 1 0
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED --cafile "$ORDERER_CA" \
    --channelID $CHANNEL_NAME --name ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    --version ${VERSION} --sequence ${VERSION}
}

queryCommitted() {
  setGlobals 2 0
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}
}

chaincodeInvokeInit() {
  echo "===================== Init chaincode ===================== "
  setGlobals 3 0
  peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED --cafile "$ORDERER_CA" \
    -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    -c '{"Args":[]}'

}

chaincodeInvoke() {
  echo "===================== Init Ledger ===================== "
  setGlobals 3 0

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
}

chaincodeQuery() {
  echo "===================== query chaincode ===================== "
  setGlobals 1 0

  #Create Car
  peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile "$ORDERER_CA" \
    -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    -c '{"function": "createCar","Args":["CAR001", "Tesla", "Model S", "Grey", "Bob"]}'

  #Query all cars
  #sleep 5
  #peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["queryAllCars"]}'

  #Change Car owner
  sleep 5
  setGlobals 2 0
  peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile "$ORDERER_CA" \
    -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    -c '{"function": "changeCarOwner","Args":["CAR001", "Alice"]}'

  #wait for concensus and propagation
  sleep 5
  setGlobals 1 0
  peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "getHistoryForAsset","Args":["CAR001"]}'

  # Delete car
  sleep 5
  setGlobals 3 0
  peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls $CORE_PEER_TLS_ENABLED \
    --cafile "$ORDERER_CA" \
    -C $CHANNEL_NAME -n ${CC_NAME} \
    --peerAddresses localhost:7051 --tlsRootCertFiles "$PEER0_ORG1_CA" \
    --peerAddresses localhost:9051 --tlsRootCertFiles "$PEER0_ORG2_CA" \
    --peerAddresses localhost:19051 --tlsRootCertFiles "$PEER0_ORG3_CA" \
    -c '{"function": "deleteCar","Args":["CAR001"]}'

  # check history for deletion
  sleep 5
  setGlobals 3 0
  peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"function": "getHistoryForAsset","Args":["CAR001"]}'

}

# #Run this function if you add any new lines of code in chaincode
presetup

packageChaincode
installChaincode
queryInstalled
approveForMyOrg 1
checkCommitReadyness 1
approveForMyOrg 2
checkCommitReadyness 2

# @ Kouassi
approveForMyOrg 3
checkCommitReadyness 3

commitChaincodeDefination
queryCommitted
sleep 5
chaincodeInvokeInit
sleep 5
chaincodeInvoke
sleep 1
chaincodeQuery
