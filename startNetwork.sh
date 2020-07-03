echo "=====================GENERATING CRYPTO MATERIALS====================="
pushd ./artifacts/channel/ || return
./create-artifacts.sh

echo "=====================POWERING UP THE NETWORK====================="
popd || return
docker-compose -f ./artifacts/docker-compose.yaml up -d

sleep 4
echo "=====================CREATING CHANNEL====================="
./createChannel.sh

sleep 2

echo "=====================DEPLOYING CHAINCODE====================="
./deployChaincode.sh

echo "=====================DONE====================="
