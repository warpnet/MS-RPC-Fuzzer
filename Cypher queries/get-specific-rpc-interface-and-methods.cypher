//GET SPECIFIC RPC INTERFACE AND METHODS
MATCH (rpcServer:RpcServer)-[:HAS_INTERFACE]->(rpcInterface:RpcInterface)
WHERE rpcInterface.UUID = "db2ce634-191d-42af-a28c-16be97924ca7"
MATCH (rpcInterface:RpcInterface)-[:HAS_ENDPOINT]->(endpoint:Endpoint)
MATCH (rpcInterface)-[:WITH_METHOD]->(method)
RETURN rpcServer, rpcInterface, endpoint, method