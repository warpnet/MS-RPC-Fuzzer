//GET HIGH PRIVILEGED FILE OPERATION FUNCTION CALLS
MATCH (rpcServer:RpcServer)-[:HAS_INTERFACE]->(rpcInterface:RpcInterface)
MATCH (rpcInterface:RpcInterface)-[:HAS_ENDPOINT]->(endpoint:Endpoint)
MATCH (rpcInterface)-[:WITH_METHOD]->(method)
MATCH (method)-[:ALLOWS_INPUT]->(allowsinput:AllowsInput)
MATCH (allowsinput)-[:HIGH_PRIVILEGED_FILE_OP]->(highPrivilegedFileOp:HighPrivilegedFileOp)
RETURN rpcServer, rpcInterface, endpoint, method, allowsinput, allowsinput.Endpoint, highPrivilegedFileOp