export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt
export FABRIC_CFG_PATH=${PWD}/config/

export CHANNEL_NAME=mychannel

# setGlobalsForOrderer(){
#     export CORE_PEER_LOCALMSPID="OrdererMSP"
#     export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
#     export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp
    
# }
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

createChannel(){
    setGlobals 1 0
    
    peer channel create -o localhost:7050 -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride orderer.example.com \
    -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
    --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}


joinChannel(){
  echo "=====================JOINING ORG 1 TO THE CHANNEL====================="
    setGlobals 1 0
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobals 1 1
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

    echo "=====================JOINING ORG 2 TO THE CHANNEL====================="
    setGlobals 2 0
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
    setGlobals 2 1
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

# @Kouassi
# Join peer0.org3 to the default channel

echo "=====================JOINING ORG 3 TO THE CHANNEL====================="

setGlobals 3 0
peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
    
}

updateAnchorPeers(){
    setGlobals 1 0
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
    setGlobals 2 0
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
    
	setGlobals 3 0
	peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA
}

echo "Creating channel" $1

createChannel
joinChannel
updateAnchorPeers


#setGlobals 1 0
peer channel list
