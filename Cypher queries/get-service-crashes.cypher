//GET SERVICE CRASHES
MATCH (rpcServer:RpcServer)-[:HAS_INTERFACE]->(rpcInterface:RpcInterface)
MATCH (rpcInterface:RpcInterface)-[:HAS_ENDPOINT]->(endpoint:Endpoint)
MATCH (rpcInterface)-[:WITH_METHOD]->(method)
MATCH (method)-[:ERROR]->(error:Error)
MATCH (error)-[:CAUSES_CRASH]->(service:Service)
RETURN rpcServer, rpcInterface, endpoint, method, service, error