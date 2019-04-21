pragma solidity ^0.5.0;
// Needed to pass in array-of-struct parameters
pragma experimental ABIEncoderV2;


contract Inventory {
    // How to let other contracts know about these structs?
    // Do they need to be put in another shared contract?
    struct PriceStruct {
        uint quantity;
        uint priceWei;
    }
    struct Item {
        //id; // ID tracked in higher-level data structure
        uint quantityAvailable;
        uint dummy; // Amazing that this is required to get code to work
        PriceStruct[] prices; // Probably don't need to specify "stoarge" type. Seems implied.
    }

    PriceStruct public temporary_price_struct_for_testing;

    function use_to_test_passing_struct_from_web3(PriceStruct memory ps) public {
        temporary_price_struct_for_testing = ps;
    }

    // Probably want to store items as hash map for lookup by ID
    uint public numItems; // this will act as an ID.
    mapping (uint => Item) public items;
    address owner;
    // Just single inventory per owner for now
    //id; // ID necessary to allow multiple Inventories per owner
    // ID tracked in higher level data structure

    function replaceQuantity(uint itemId, uint newQuantity) public {
        items[itemId].quantityAvailable = newQuantity;
    }

    // Suspected atomicity issues between reading quantity and calling replace.
    // So also allowing "increment", which may also be negative.
    // Considering renaming increment to "adjustQuantity".
    /* Type conversion issues means it's easier to just create two separate functions
    function incrementQuantity(uint itemId, int increment) public {
        items[itemId].quantityAvailable += increment;
    }
    */
    function incrementQuantity(uint itemId, uint increment) public {
        items[itemId].quantityAvailable += increment;
    }
    function decrementQuantity(uint itemId, uint decrement) public {
        items[itemId].quantityAvailable -= decrement;
    }

    function replacePrices(uint itemId, PriceStruct[] memory priceArray) public {
        // Direct copy not supported: https://github.com/ethereum/solidity/issues/3446
        //items[itemId].prices = priceArray;
        // Must use loop instead:
        // Delete array first. This just sets all elements to zero
        delete items[itemId].prices;
        // Todo, check if deleting reference works instead.
        //delete prices;

        // Not sure if memory is better than storage. Should just be a reference to storage
        PriceStruct[] storage prices = items[itemId].prices; // reference

        for (uint i = 0; i < prices.length; i++)
        {
            // Todo, focus on addItem first
        }
    }

    function addItem(uint quantity, PriceStruct[] memory priceArray) public returns (uint) {
        /*
        Attempt 1:
        One-liner.
        Compile error.
        Automatic "memory" to "storage" copy is not supported
        Must manually copy over priceArray
        */
        //items[numItems++] = Item({quantityAvailable: quantity, dummy: 5, prices: priceArray});

        /*
        Attempt 2:
        Create "memory" reference type.
        All of these lines compile.
        Testing shows that quantityAvailable is not written to storage.
        */
        /*
        Item memory newItem = items[numItems++];
        newItem.quantityAvailable = quantity;
        newItem.prices = priceArray;
        */

        /*
        Attempt 3:
        Create "storage" reference type.
        Suspect that storage ref required for data to stick.
        All of these lines except for the last one involving "prices" array compile.
        */
        /*
        */
        Item storage newItem = items[numItems++];
        newItem.quantityAvailable = quantity;
        //newItem.prices = priceArray;
        // Todo - expand "prices" array copy

        return numItems - 1; // Item ID
        /*
        Having trouble retrieving item ID in javascript tests.
        Seems that values are only returned from pure/view functions.
        Workaround is to just use get<Next/Previous>ItemId() view functions.
        */
    }

    /*
    How will the owner be able to track item IDs?
    Can just request with view function.
    Seem to have issues with retrieving values from non-pure/view functions,
    so can't get this value from addItem call.
    */
    function getNextItemId() public view returns (uint) {
        return numItems;
    }
    function getPreviousItemId() public view returns (uint) {
        return numItems - 1; // underflow if numItems = 0;
    }
}

contract SupplyChain {

    uint numInventories; // this will act as an ID.
    mapping (uint => Inventory) inentories;
    
    // Dummy function for sanity testing of truffle
    function alwaysPasses() public pure returns (bool) {
        return true;
    }
}
