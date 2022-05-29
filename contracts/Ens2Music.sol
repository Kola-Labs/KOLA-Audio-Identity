// File: @ensdomains/resolver/contracts/Resolver.sol
pragma solidity >=0.4.24;

interface ETHRegistrarController {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

pragma solidity >= 0.7.0 < 0.9.0;

import "./provableAPI.sol";
import "./Strings.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Ens2Music is ERC721Enumerable, Ownable, usingProvable {

    using strings for *;
    using Counters for Counters.Counter;
    Counters.Counter private tokenId;
    Counters.Counter private musicPassId;

    // Metadata variables
    mapping(string => string) private metadataURIMap;
    string private metadataQueryBaseURI = "http://3.235.192.206:3000/e2m/get/metadata/testnet-v3/";

    // Music Genre
    enum musicGenre{ PURE_DANCING, RELAX_DANCING, ETHEREAL_AND_PEACEFUL }
    uint32 numberOfGenre = 3;

    // DID system
    string private ensSuffix = ".eth";

    // Music pass price
    uint256 private purchasePrice = 300000000000000 wei;

    // Max painting name length
    uint256 private maxDomainNameLength = 1000;
    uint256 private minDomainNameLength = 4;

    // Log event for indexing
    event LogNewMetadata(string ensDomain, string metadataUri);
    event LogNewProvableQuery(string description);
    event LogMusicPassCreated(uint256 indexed musicPassId, address indexed ownerWalletAddress,string ensDomain, uint32 genre);
    event LogMusicNftCreated(uint256 indexed musicNftId, address indexed ownerWalletAddress, string ensDomain, uint32 genre, string metadataUri);

    // contract paused
    bool public paused = false;

    // Mapping from domain name to its purchased status
    mapping(string => bool) private nftPurchased;

    // Mapping from music pass to its purchased status
    mapping(string => bool) private musicPassPurchased;

    // Commitments
    mapping(string => uint32) public musicGenreMap;

    constructor()
    ERC721("Ens2Music", "Ens2Music")
    {
    }

    // String utils helper function
    function stringConcat(string memory stringA, string memory stringB, string memory stringC, string memory stringD) internal pure returns (string memory) {
        return string(abi.encodePacked(stringA, stringB, stringC, stringD));
    }

    function sliceString(string memory str, string memory deli) private returns (string[] memory) {
        string[] memory parts = new string[](2);
        strings.slice memory s = str.toSlice();
        strings.slice memory delim = deli.toSlice();
        parts[0] = s.split(delim).toString();
        parts[1] = s.split(delim).toString();
        return parts;
    }

    // Oracle to query metadata
    function __callback(
        bytes32 myid,
        string memory result
    )
        public
        override
    {
        require(msg.sender == provable_cbAddress());

        // Return domain name and metadata URI
        string[] memory temp = sliceString(result, ";");

        // Set to metadataURI map
        metadataURIMap[temp[1]] = temp[0];
        emit LogNewMetadata(temp[1], temp[0]);

    }

    function update(string memory domainName)
        public
        payable
    {
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
        string memory query = stringConcat("json(", metadataQueryBaseURI, domainName, ").name");
        provable_query("URL", query);
    }


    // Purchase music pass and music NFT
    function purchaseMusicPass(string calldata domainName, uint32 genreId) external payable {
        require(!paused, "The contract has been paused");

        // The length of the domain name should within the range
        require(domainName.toSlice().len() <= maxDomainNameLength, "Name of the domain is too long.");
        require(domainName.toSlice().len() > minDomainNameLength, "Name of the domain is too short.");

        // Revert if the genre type is invalid
        require(genreId <= numberOfGenre, "Genre id is invalid.");

        // Revert the transaction if the amount is insufficient
        if (msg.sender != owner()) {
            require(msg.value >= purchasePrice, "Insufficient amount.");
        }

        // Revert the transaction if the music pass has been purchased
        require(!musicPassPurchased[domainName], "This domain has been purchased.");

        // TODO: Check domain name belongs to message sender

        musicGenreMap[domainName] = genreId;
        musicPassPurchased[domainName] = true;
        musicPassId.increment();
        emit LogMusicPassCreated(musicPassId.current(), msg.sender, domainName, genreId);
    }

    function redeemMusicNFT(string calldata domainName) external payable returns (uint256) {
        // TODO: Check domain name belongs to message sender

        require(!paused, "The contract has been paused");

        // Revert if the music NFT has been purchased
        require(!nftPurchased[domainName],  "The music NFT associated with this domain has already been purchased.");

        // Revert if the music pass has not been purchased
        require(musicPassPurchased[domainName],  "Please purchase music pass before redeem your NFT.");

        // Call Oracle to get the metadataURI
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
        string memory query = stringConcat("json(", metadataQueryBaseURI, domainName, ").name");
        provable_query("URL", query);

        tokenId.increment();
        uint256 newItemId = tokenId.current();
        _safeMint(msg.sender, newItemId);
        nftPurchased[domainName] = true;
        emit LogMusicNftCreated(newItemId, msg.sender, domainName, musicGenreMap[domainName], metadataURIMap[domainName]);

        return newItemId;
    }

    // Get functions
    function getPurchsePrice() external view returns (uint256) {
        return purchasePrice;
    }

    function getMetadataByDomain(string memory domainName) external view returns (string memory) {
        return metadataURIMap[domainName];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataQueryBaseURI;
    }

    // Only owner functions
    function setPurchasePrice(uint256 newPrice) public onlyOwner {
        purchasePrice = newPrice;
    }

    function setMetadataQueryURI(string memory newMetadataQueryURI) public onlyOwner {
        metadataQueryBaseURI = newMetadataQueryURI;
    }

    function pause(bool state) public onlyOwner {
        paused = state;
    }

    function withdraw() public payable onlyOwner {
        // This will payout the owner 100% of the contract balance.
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
