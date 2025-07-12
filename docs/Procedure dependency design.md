# Design for a solution to procedure dependency

Currently, the fuzzer directly formats all parameters for a procedure using the `Format-DefaultParameters` function.
If the parameter is "complex", for example a contex handle, the RPC call will most likely result in a `Parameter Invalid` error message.
This is because by default we create an instance for these parameters: `return [System.Activator]::CreateInstance($Type)`

To improve this and actually make a proper call, we should get a valid parameter value for the complex type.
The chosen approach is to first sort all the procedures within the interface, depending on what their input parameters are.
For example, if procedure A outputs a parameter that procedure B needs, it will first call procedure A and store it's output parameter in a list.

This fuzzing method/algorithm can be used instead of the default one by setting the parameter:
```powershell
'.\rpcServerData.json' | Invoke-RpcFuzzer --OutPath .\output\ -FuzzerType sorted
[+] dbghelp.dll successfully initialized
[+] Starting fuzzer...
[+] Completed fuzzing
[+] To load data into Neo4j use: '.\output\Allowed.json' | Import-DatatoNeo4j -Neo4jHost '127.0.0.1:7474' -Neo4jUsername 'neo4j'
```

```mermaid
graph TD
    A[Start Fuzzer] --> B{Loop through each RPC Interface};

    B --> BA[Initialize Stored Parameters List for Interface];
    BA --> BB[Sort Procedures within Interface by Dependency Output -> Input];

    BB --> BC{Loop through Sorted Procedures};
    BC --> C[Parse Parameters with Format-DefaultParameters];
    C --> D{Any Complex Parameters Required?};

    D -- Yes --> E{Check Stored Parameters for Complex Type};
    E -- Found --> F[Use Stored Parameter as Input for Current Method];
    E -- Not Found --> G[Generate Instance for Complex Type];

    F --> H[Prepare RPC Call Details];
    G --> H[Prepare RPC Call Details];
    D -- No --> H;

    H --> I[Log RPC Call Details];
    I --> J[Invoke RPC Method];
    J --> K[Store Output Parameters from Current Procedure];

    K --> L{More Procedures in Interface to Fuzz?};
    L -- Yes --> BC;
    L -- No --> M[Clear Stored Parameters for Interface];

    M --> N{More Interfaces to Fuzz?};
    N -- Yes --> B;
    N -- No --> O[End Fuzzer];


    %% Styling for colors
    style A fill:#D4EDDA,stroke:#28A745,stroke-width:2px,color:#000;
    style O fill:#D4EDDA,stroke:#28A745,stroke-width:2px,color:#000;
    style B fill:#FFF3CD,stroke:#FFC107,stroke-width:2px,color:#000;
    style D fill:#FFF3CD,stroke:#FFC107,stroke-width:2px,color:#000;
    style E fill:#FFF3CD,stroke:#FFC107,stroke-width:2px,color:#000;
    style L fill:#FFF3CD,stroke:#FFC107,stroke-width:2px,color:#000;
    style N fill:#FFF3CD,stroke:#FFC107,stroke-width:2px,color:#000;
    style BC fill:#FFF3CD,stroke:#FFC107,stroke-width:2px,color:#000;

    style BA fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style BB fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style C fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style F fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style G fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style H fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style I fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style J fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style K fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
    style M fill:#E2E3E5,stroke:#6C757D,stroke-width:2px,color:#000;
```