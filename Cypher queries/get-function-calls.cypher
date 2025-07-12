//GET FUNCTION CALLS
MATCH (rpcServer:RpcServer)-[:HAS_INTERFACE]->(rpcInterface:RpcInterface)
MATCH (rpcInterface:RpcInterface)-[:HAS_ENDPOINT]->(endpoint:Endpoint)
MATCH (rpcInterface)-[:WITH_METHOD]->(method)
MATCH (method)-[:ALLOWS_INPUT]->(allowsinput:AllowsInput)
MATCH (allowsinput)-[:CALLS_FUNCTION]->(functionCall:FunctionCall)
RETURN rpcServer, rpcInterface, endpoint, method, allowsinput, allowsinput.Endpoint, functionCall