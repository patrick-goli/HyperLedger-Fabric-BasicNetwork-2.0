#TODO delete only those created. ==> see artifacts/docker-compose.yaml
echo "=====================STOPING THE NETWORK====================="
docker stop $(docker ps -aq)
docker rm -f $(docker ps -aq)


echo "=====================REMOVING OLD WALLETS DATA====================="
rm -rf ./api-2.0/org*-wallet

echo "=====================DONE====================="