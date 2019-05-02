pragma solidity ^0.5.0;
// Needed to pass in array-of-struct parameters
pragma experimental ABIEncoderV2;


contract Inventory {
    // How to let other contracts know about these structs?
    // Do they need to be put in another shared contract?
    //   A: Should be able to use them with `Inventory.PriceStruct`
    struct PriceStruct {
        uint quantity;
        uint priceWei;
    }
    struct Item {
        //id; // ID tracked in higher-level data structure
        uint quantityAvailable;
        uint dummy; // Amazing that this is required to get code to work
        bytes32 hashedDescription;
        PriceStruct[] prices; // Probably don't need to specify "storage" type. Seems implied.
    }

    /**
    Put this back as it was failing a test, will remove this and the test case later
    */
    PriceStruct public temporary_price_struct_for_testing;
    function use_to_test_passing_struct_from_web3(PriceStruct memory ps) public {
        temporary_price_struct_for_testing = ps;
    }


    // Probably want to store items as hash map for lookup by ID
    uint public numItems; // this will act as an ID.
    mapping (uint => Item) public items;
    // No need for owner here, since owner address is key to parent mapping
    //address owner;
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

        /**
        World have been nice to have helper function to do
        this here and in additem, but function parametrs have to be
        memeory and memory items don't have the push.
        There maybe a way to get around, to figure out later
         */
        for (uint i = 0; i < prices.length; i++)
        {
            items[itemId].prices.push(priceArray[i]);
        }
    }


    function get_priceStruct(uint itemnum, uint arr_ind) public view returns (PriceStruct memory){

        return items[itemnum].prices[arr_ind];
    }

    function addItem(uint quantity, bytes32 description, PriceStruct[] memory priceArray) public returns (uint) {

        items[numItems].quantityAvailable = quantity;
        items[numItems].hashedDescription = description;

        for (uint i = 0; i < priceArray.length; i++) {
            items[numItems].prices.push(priceArray[i]);
        }

        numItems++;
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

contract ProductRegistry {
    // Parts can be items or products
    enum PART_TYPE {
        ITEM,
        PRODUCT
    }

    struct Part {
        PART_TYPE part_type;
        // If part is item, then manufacturer_ID is supplier address
        // If part is product, then manufacturer_ID is designer address
        address manufacturer_ID;

        //bytes32 hashedDescription;
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
        // Todo - remove returning of values from all non-(view/pure) functions
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

contract SupplyChain {

    /*
    Every "supplier" has an "inventory" full of "items".
    Every "designer" has a "product registry" full of "products".
    Each "product" is an array of "parts".
    A "part" is either a "product" or "item".
    */

    // Supplier inventories tied to their owner address
    // Notes on working with mapping of contracts:
    // https://ethereum.stackexchange.com/questions/32354/mapping-to-contract
    mapping (address => Inventory) public inventories;
    mapping (address => bool) public inventoryAvailable;

    // Designer product registries tied to their owner address
    mapping (address => ProductRegistry) public productRegistries;
    mapping (address => bool) public productRegistryAvailable;

    function addItem(uint quantity, bytes32 description, Inventory.PriceStruct[] memory priceArray) public {
        if (!inventoryAvailable[msg.sender]) {
            inventoryAvailable[msg.sender] = true;
            inventories[msg.sender] = new Inventory();
        }
        inventories[msg.sender].addItem(quantity, description, priceArray);
    }

    function getNextItemId() public view returns (uint) {
        if (inventoryAvailable[msg.sender]) {
            return inventories[msg.sender].getNextItemId();
        } else {
            return ~uint(0); // largest uint
        }
    }

    function getPreviousItemId() public view returns (uint) {
        if (inventoryAvailable[msg.sender]) {
            return inventories[msg.sender].getPreviousItemId();
        } else {
            return ~uint(0); // largest uint
        }
    }


    function addProduct(ProductRegistry.Part[] memory _partsArray) public {
        if (!productRegistryAvailable[msg.sender]) {
            productRegistryAvailable[msg.sender] = true;
            productRegistries[msg.sender] = new ProductRegistry();
        }
        productRegistries[msg.sender].addProduct(_partsArray);
    }

    function removeProduct(uint productId) public {
        if (productRegistryAvailable[msg.sender]) {
            productRegistries[msg.sender].removeProduct(productId);
        }
    }

    function getNextProductId() public view returns (uint) {
        if (productRegistryAvailable[msg.sender]) {
            productRegistries[msg.sender].getNextProductId();
        } else {
            return ~uint(0); // largest uint
        }
    }

    function getPreviousProductId() public view returns (uint) {
        if (productRegistryAvailable[msg.sender]) {
            productRegistries[msg.sender].getPreviousProductId();
        } else {
            return ~uint(0); // largest uint
        }
    }


    /**
    bidsContract parameter may not be required here
    execution will happen for a particaular product
    by this function being called by the executioner

    run through all bids for this product
    check if the customer has funds in their account for the
    amount they bid
    if yes pay to contract
    remove bid
    then run through the design contract of the product
    and pay all vendors
     */

    function execute(address bidsAddress, uint productId)  public {
        CustomerBids bidsContract = CustomerBids(bidsAddress);
        uint bids_num = bidsContract.getNextBidId();
        // how is above different from
        //bidsAddress.call(abi.encodeWithSignature("getNextBidId()"));

        bool errorFlag = false;
        uint productNum = 0;

        /* Does not compile
        for(uint i=0;i<bidsContract.numBids();i++) {
            if(bidsContract.bids[i].productId = productId ) {
                errorFlag = true;
                require(bidsContract.bids[i].customerAddress.fundsWei >
                        bidsContract.bids[i].bidWei,"Not enough funds");
                bidsContract.bids[i].customerAddress.balance -= bidsContract.bids[i].bidWei;
                bidsContract.removeBid(i);
                errorFlag = false;
                productNum++;
            }
        }
        */

        /**
        Needs to be checked, whole execute should be reverted when
        customer with bid does not have enough funds for the item
         */
        if(errorFlag)
            revert();

        /**
        Each vendor needs to be paid productNum * itemPrice
         */
    }

}
