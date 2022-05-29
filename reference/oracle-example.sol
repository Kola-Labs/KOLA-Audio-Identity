// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "https://github.com/provable-things/ethereum-api/provableAPI_0.5.sol";

contract DieselPrice is usingProvable {

    uint public dieselPriceUSD;

    event LogNewDieselPrice(string price);
    event LogNewProvableQuery(string description);

    function __callback(
        bytes32 _myid,
        string memory _result
    )
        public
    {
        require(msg.sender == provable_cbAddress());
        emit LogNewDieselPrice(_result);
        dieselPriceUSD = parseInt(_result, 2); // Let's save it as cents...
        // Now do something with the USD Diesel price...
        // {
        //     "domain": "ruofeng.eth",
        //     "metadata_url": "ipfs://..."
        // }
    }

    function update(string memory domain)
        public
        payable
    {
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
        provable_query("URL", "json(https://minty.kola.app/e2m/metadata/testnet-v2/6000)");
    }
}