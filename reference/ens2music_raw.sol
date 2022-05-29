// File: @ensdomains/resolver/contracts/Resolver.sol
pragma solidity >=0.4.24;

interface ETHRegistrarController {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/provable-things/ethereum-api/provableAPI_0.5.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract e2m is ERC721Enumerable, Ownable, usingProvable {

  using Address for address;
  using Strings for uint256;

  // The ENS registry
  ETHRegistrarController public ens;

  // Max painting name length
  uint256 private maxDomainNameLength = 1000;
  uint256 private minDomainNameLength = 4;

  // purchase price
  uint256 private _purchasePrice = 3000000000000000 wei;

  // baseURI for Metadata
  string private metadataURI = "https://minty.kola.app/e2m/metadata/testnet-v2/";
  string private ensSuffix = ".eth";

  // contract paused
  bool public paused = false;

  // token supply
  uint256 private _tokenSupply = 0;

  // Mapping from domain name to its purchased status
  mapping(uint256 => bool) private domainPurchases;

  // Mapping from token Id to domain name
  mapping(uint256 => string) private tokenIdToDomain;

  // Mapping from domain name to token id
  mapping(string => uint256) private domainToTokenId;

  /**
  * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
  */

  constructor(
    string memory _name,
    string memory _symbol,
    ETHRegistrarController _ens
  ) ERC721(_name, _symbol) {
    setBaseURI(metadataURI);
    ens = _ens;
  }

  function tokenSupply() external view returns (uint256) {
    return _tokenSupply;
  }

  function domainToHashKey(string calldata domainName) internal view returns (uint256) {
    uint256 slen = bytes(domainName).length;
    string memory name = domainName[:slen-4];
    string memory suffix = domainName[slen-4:];
    require(keccak256(abi.encodePacked(suffix)) == keccak256(abi.encodePacked(ensSuffix)), "Wrong ENS suffix.");
    bytes32 label = keccak256(bytes(name));
    uint256 hashKey = uint256(label);
    return hashKey;
  }

  function domainInfo(string memory domainName) external view returns (uint256) {
    return domainToTokenId[domainName];
  }

  function tokenInfo(uint256 tokenId) external view returns (string memory) {
    return tokenIdToDomain[tokenId];
  }

  function purchsePrice() external view returns (uint256) {
    return _purchasePrice;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return metadataURI;
  }

  function queryMetadata(string memory domain) public payable {
    provable_query("URL", "json(https://songify.kola.app/metadata/)");
  }

  function walletOfOwner(address owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return tokenIds;
  }

  function mint(string calldata domainName) external payable returns (uint256) {
    require(bytes(domainName).length <= maxDomainNameLength, "Name of the domain is too long.");
    require(bytes(domainName).length > minDomainNameLength, "Name of the domain is too short.");
    if (msg.sender != owner()) {
      require(msg.value >= _purchasePrice, "Insufficient message value.");
    }

    uint256 hashKey = domainToHashKey(domainName);
    require(!domainPurchases[hashKey],  "This domain has already been purchased.");
    require(msg.sender == ens.ownerOf(hashKey),  "You are not the owner of this ENS domain.");

    _safeMint(msg.sender, _tokenSupply + 1);
    _tokenSupply = _tokenSupply + 1;
    tokenIdToDomain[_tokenSupply] = domainName;
    domainToTokenId[domainName] = _tokenSupply;
    domainPurchases[hashKey] = true;

    return _tokenSupply;
  }

  //only owner
  function setPrice(uint256 newPrice) public onlyOwner {
    _purchasePrice = newPrice;
  }

  function setBaseURI(string memory newMetadataURI) public onlyOwner {
    metadataURI = newMetadataURI;
  }

  function pause(bool state) public onlyOwner {
    paused = state;
  }
}