//MAP INTERFACES, ENDPOINT, METHOD AND ERRORS
MATCH (rpcServer:RpcServer)-[:HAS_INTERFACE]->(rpcInterface:RpcInterface)
MATCH (rpcInterface:RpcInterface)-[:HAS_ENDPOINT]->(endpoint:Endpoint)
MATCH (rpcInterface)-[:WITH_METHOD]->(method)
MATCH (method)-[:ERROR]->(error:Error)
return rpcServer, rpcInterface, endpoint, method, error