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
    PriceStruct[] public price_test;

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


    function get_priceStruct(uint itemnum, uint arr_ind) public view returns (PriceStruct memory){

        return items[itemnum].prices[arr_ind];
    }

    function addItem(uint quantity, PriceStruct[] memory priceArray) public returns (uint) {
        /*
        Attempt 1:
        One-liner.
        Compile error.
        Automatic "memory" to "storage" copy is not supported
        Must manually copy over priceArray
        */

        items[numItems].quantityAvailable = quantity;//Item({quantityAvailable: quantity, dummy: 5, prices: priceArray});

        for (uint i = 0; i < priceArray.length; i++) {
            items[numItems].prices.push(priceArray[i]);
        }
        numItems++;
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
        // Item storage newItem = items[numItems++];
        // newItem.quantityAvailable = quantity;
        // // newItem.prices = priceArray;
        // for (uint i = 0; i < priceArray.length; i++)
        // {
        //     newItem.prices.push(priceArray[i]);// Todo, focus on addItem first
        // }
        // // Todo - expand "prices" array copy

        // return numItems - 1; // Item ID
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
    These will work as long as long as addItem is called in the same transaction.
    */
    function getNextItemId() public view returns (uint) {
        return numItems;
    }
    function getPreviousItemId() public view returns (uint) {
        return numItems - 1; // underflow if numItems = 0;
    }
}

contract CustomerBids {

    struct Customer {
        uint fundsWei;
        uint dummy;
    }

    struct Bid {
        address customerAddress;
        uint productId;
        uint bidWei;
        uint quantity;
    }

    mapping (address => Customer) public customers;
    mapping (uint => Bid) public bids;

    uint public numBids;

    function placeBid(uint productId, uint bidWei, uint quantity) public {
        bids[numBids++] = Bid({
            customerAddress: msg.sender,
            productId: productId,
            bidWei: bidWei,
            quantity: quantity
        });

        /* Non-pure/view functions only return transaction details, not values.
        So cannot return bidId to customer here.
        Must use another view function to get bidId.
        */
    }

    function removeBid(uint bidId) public {
        Bid storage bid = bids[bidId];
        require (bid.customerAddress == msg.sender);
        //delete bid; // cannot apply delete to storage pointer
        delete bids[bidId];

        // This requires more testing
    }

    // These will work as long as long as placeBid is called in the same transaction.
    function getNextBidId() public view returns (uint) {
        return numBids;
    }
    function getPreviousBidId() public view returns (uint) {
        return numBids - 1; // underflow if numBids = 0;
    }

    function depositFunds() public payable {
        // Increment funds
        customers[msg.sender].fundsWei += msg.value;
    }

    function withdrawFunds() public {
        // Transfer all funds
        msg.sender.transfer(customers[msg.sender].fundsWei);
        // Reset balance to zero
        customers[msg.sender].fundsWei = 0;
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

contract ProductRegistry {
    // Parts can be items or products
    enum PART_TYPE {
        ITEM,
        PRODUCT
    }

    struct Part {
        PART_TYPE part_type;
        uint manufacturer_ID; // Consider making this an address

        // If part is an item, part_ID should be the item_id in the
        // manufacturer's inventory.
        // If part is a product, part_ID should be the product_ID
        uint part_ID;
        uint quantity;
    }

    /*
    Because productId is tracked at a higher level, a full struct is unecessary
    to store just the partsArray

    struct Product {
        uint x;
        Part[] partsArray;
    }
    */

    uint public numProducts; // acts as ID
    mapping (uint => Part[]) public products;

    function addProduct(Part[] memory _partsArray) public returns (uint) {
        Part[] storage newProduct = products[numProducts++];

        // Copy _partsArray into newProduct
        for (uint i = 0; i < _partsArray.length; i++) {
            newProduct.push(_partsArray[i]);
        }
        return numProducts - 1; // return Product ID
    }

    function removeProduct(uint productId) public {
        delete products[productId];
    }
    function getNextProductId() public view returns (uint) {
        return numProducts;
    }
    function getPreviousProductId() public view returns (uint) {
        return numProducts - 1; // underflow if numProducts = 0;
    }
}
