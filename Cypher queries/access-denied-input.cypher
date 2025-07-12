//MAP INTERFACES, ENDPOINT, METHOD AND ACCESS DENIED
MATCH (rpcServer:RpcServer)-[:HAS_INTERFACE]->(rpcInterface:RpcInterface)
MATCH (rpcInterface:RpcInterface)-[:HAS_ENDPOINT]->(endpoint:Endpoint)
MATCH (rpcInterface)-[:WITH_METHOD]->(method)
MATCH (method)-[:ACCESS_DENIED]->(accessdenied:AccessDenied)
return rpcServer, rpcInterface, endpoint, method, accessdenied