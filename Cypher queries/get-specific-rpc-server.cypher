//GET SPECIFIC RPC SERVER
MATCH (rpcServer:RpcServer)-[:HAS_INTERFACE]->(rpcInterface:RpcInterface)
WHERE rpcServer.Name = "SensorService.dll"
MATCH (rpcInterface:RpcInterface)-[:HAS_ENDPOINT]->(endpoint:Endpoint)
MATCH (rpcInterface)-[:WITH_METHOD]->(method)
RETURN rpcServer, rpcInterface, endpoint, method