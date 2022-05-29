//pragma solidity >=0.5.0 <0.6.0;
//import "./provableAPI.sol";
//
//contract QueryMetadata is usingProvable {
//
//    string private baseMetadataURI = "https://minty.kola.app/e2m/metadata/testnet-v2/";
//    string metadataURI;
//
//    event LogNewMetadataURI(string metadataURI);
//    event LogNewProvableQuery(string description);
//
//    constructor() public {
//        queryDomainName("6000"); // First check at contract creation...
//    }
//
//    function __callback(bytes32 myid, string memory result) public {
//        require(msg.sender == provable_cbAddress());
//        emit LogNewMetadataURI(result);
//        metadataURI = result[0];
//    }
//
//    function stringConcat(string memory stringA, string memory stringB, string memory stringC, string memory stringD) internal pure returns (string memory) {
//        return string(abi.encodePacked(stringA, stringB, stringC, stringD));
//    }
//
//    function queryDomainName(string memory domainName) public payable {
//        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
//        string memory query = stringConcat("json(", baseMetadataURI, domainName, ").[name, description]");
//        provable_query("URL", query);
//    }
//}