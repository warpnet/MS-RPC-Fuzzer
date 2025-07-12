//GET SPECIFIC METHOD
MATCH (rpcServer:RpcServer)-[:HAS_INTERFACE]->(rpcInterface:RpcInterface)
MATCH (rpcInterface:RpcInterface)-[:HAS_ENDPOINT]->(endpoint:Endpoint)
MATCH (rpcInterface)-[:WITH_METHOD]->(method)
WHERE method.Name = "RSensorBrokerServerGetActivityTriggerReports"
RETURN rpcServer, rpcInterface, endpoint, method