# System channel
SYS_CHANNEL="sys-channel"

# channel name defaults
CHANNEL_NAME="mychannel"

# Delete existing artifacts
if [ -d "./organizations/peerOrganizations" ]; then
    rm -rf ./organizations/peerOrganizations
fi

if [ -d "./organizations/ordererOrganizations" ]; then
    rm -rf ./organizations/ordererOrganizations
fi

if [ -d "./channel-artifacts" ]; then
    rm ./channel-artifacts/*.block
    rm -rf ./channel-artifacts/*.tx
fi


echo "#######    Generate Crypto artifactes for organizations  ##########"
cryptogen generate --config=./organizations/cryptogen/crypto-config-orgs.yaml --output=./organizations

echo "#######    Generate Crypto artifactes for orderers  ##########"
cryptogen generate --config=./organizations/cryptogen/crypto-config-orderers.yaml --output=./organizations

echo "#######    Generate System Genesis block  ##########"
configtxgen -profile OrdererGenesis -configPath . -channelID $SYS_CHANNEL  -outputBlock ./channel-artifacts/genesis.block

echo "#######    Generate channel configuration block  ##########"
configtxgen -profile BasicChannel -configPath . -outputCreateChannelTx ./channel-artifacts/$CHANNEL_NAME.tx -channelID $CHANNEL_NAME

echo "#######    Generating anchor peer update for Org1MSP  ##########"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

echo "#######    Generating anchor peer update for Org2MSP  ##########"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP

# @Kouassi
echo "#######    Generating anchor peer update for Org3MSP  ##########"
configtxgen -profile BasicChannel -configPath . -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP