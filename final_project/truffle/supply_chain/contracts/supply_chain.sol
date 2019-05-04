pragma solidity ^0.5.0;
// Needed to pass in array-of-struct parameters
pragma experimental ABIEncoderV2;



// Revising this to just a struct in SupplyChain
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

    /*
    Every "supplier" has an "inventory" full of "items".
    Every "designer" has a "product registry" full of "products".
    Each "product" is an array of "parts".
    A "part" is either a "product" or "item".
    */

    // ---------- Inventory section --------------

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

    struct Inventory {
        uint numItems; // this will act as an ID.
        uint dummy;
        mapping (uint => Item) items;
    }

    // Supplier inventories tied to their owner address
    // Notes on working with mapping of contracts:
    // https://ethereum.stackexchange.com/questions/32354/mapping-to-contract
    mapping (address => Inventory) public inventories;
    mapping (address => bool) public inventoryAvailable;

    function addItem(uint quantity, bytes32 description, PriceStruct[] memory priceArray) public {
        if (!inventoryAvailable[msg.sender]) {
            inventoryAvailable[msg.sender] = true;
            // Unnecessary now that we're using structs instead of contracts
            //inventories[msg.sender] = new Inventory();
        }

        // Helper references to save typing
        Inventory storage inventory = inventories[msg.sender];
        Item storage item = inventory.items[inventory.numItems];

        item.quantityAvailable = quantity;
        item.hashedDescription = description;

        for (uint i = 0; i < priceArray.length; i++) {
            item.prices.push(priceArray[i]);
        }

        inventory.numItems++;
    }

    // Cannot return values from non-pure/view functions, so can't get ID from addItem call.
    function getNextItemId() public view returns (uint) {
        if (inventoryAvailable[msg.sender]) {
            return inventories[msg.sender].numItems;
        } else {
            return 0; // Next id will be zero if inventory does not exist yet
        }
    }

    function getPreviousItemId() public view returns (uint) {
        if (inventoryAvailable[msg.sender] && inventories[msg.sender].numItems != 0) {
            return inventories[msg.sender].numItems - 1;
        } else {
            return ~uint(0); // largest uint
        }
    }

    function replaceQuantity(uint itemId, uint newQuantity) public {
        require(inventoryAvailable[msg.sender], "Inventory not available");
        inventories[msg.sender].items[itemId].quantityAvailable = newQuantity;
    }

    // Suspected atomicity issues between reading quantity and calling replace.
    // So also allowing "increment", which may also be negative.
    // Considering renaming increment to "adjustQuantity".
    /* Type conversion issues means it's easier to just create two separate functions
    function incrementQuantity(uint itemId, int increment) public {
        inventories[msg.sender].items[itemId].quantityAvailable += increment;
    }
    */
    function incrementQuantity(uint itemId, uint increment) public {
        require(inventoryAvailable[msg.sender], "Inventory not available");
        inventories[msg.sender].items[itemId].quantityAvailable += increment;
    }
    function decrementQuantity(uint itemId, uint decrement) public {
        require(inventoryAvailable[msg.sender], "Inventory not available");
        inventories[msg.sender].items[itemId].quantityAvailable -= decrement;
    }


    function replacePrices(uint itemId, PriceStruct[] memory priceArray) public {
        require(inventoryAvailable[msg.sender], "Inventory not available");

        // Helper references to save typing
        Inventory storage inventory = inventories[msg.sender];
        Item storage item = inventory.items[inventory.numItems];


        // Direct copy not supported: https://github.com/ethereum/solidity/issues/3446
        //item.prices = priceArray;
        // Must use loop instead:
        // Delete array first. This just sets all elements to zero
        delete item.prices;
        // Todo, check if deleting reference works instead.
        //delete prices;

        PriceStruct[] storage prices = item.prices;

        /**
        Would have been nice to have helper function to do
        this here and in additem, but function parameters have to be
        memeory and memory items don't have the push.
        There maybe a way to get around, to figure out later
         */
        for (uint i = 0; i < prices.length; i++) {
            prices.push(priceArray[i]);
        }
    }

    // Helper getter functions for working with web3
    // getNumItems() is just slightly more convenient.
    // getItem and getPriceStruct are required, since there is not other way to access this data

    function getNumItems() public view returns (uint) {
        if (inventoryAvailable[msg.sender]) {
            return inventories[msg.sender].numItems;
        } else {
            return 0; // Zero items if inventory does not exist yet
        }
    }

    function getItem(uint itemId) public view returns (Item memory){
        require(inventoryAvailable[msg.sender], "Inventory not available");
        return inventories[msg.sender].items[itemId];
    }

    function getPriceStruct(uint itemId, uint priceStructIndex) public view returns (PriceStruct memory){
        require(inventoryAvailable[msg.sender], "Inventory not available");
        return inventories[msg.sender].items[itemId].prices[priceStructIndex];
    }


    // ---------- Product registry section --------------

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

    // This is a way to track all customer bids for each product
    struct ProductBid {
        address customer;
        uint bidId;
    }

    struct Product {
        Part[] partsArray;
        // Bids needs to be another data structure that supports deletion.
        // Singly-linked list would work.
        ProductBid[] productBids;
        uint numBids;
        uint dummy;
    }

    struct ProductRegistry {
        uint numProducts; // acts as ID
        uint dummy;
        mapping (uint => Product) products;
        mapping (uint => bool) productAvailable; // Likely need this
    }

    // Designer product registries tied to their owner address
    mapping (address => ProductRegistry) public productRegistries;
    mapping (address => bool) public productRegistryAvailable;


    function addProduct(Part[] memory partsArray) public {
        if (!productRegistryAvailable[msg.sender]) {
            productRegistryAvailable[msg.sender] = true;
        }

        ProductRegistry storage registry = productRegistries[msg.sender];
        registry.productAvailable[registry.numProducts] = true;

        Part[] storage newProduct = registry.products[registry.numProducts++].partsArray;

        // Copy partsArray into newProduct
        for (uint i = 0; i < partsArray.length; i++) {
            newProduct.push(partsArray[i]);
        }
    }

    function removeProduct(uint productId) public {
        require(productRegistryAvailable[msg.sender], "Product registry not available");

        ProductRegistry storage registry = productRegistries[msg.sender];

        delete registry.products[productId];
        registry.productAvailable[productId] = false;
    }

    function getNextProductId() public view returns (uint) {
        if (productRegistryAvailable[msg.sender]) {
            return productRegistries[msg.sender].numProducts;
        } else {
            return 0; // Next id will be zero if registry does not exist yet
        }
    }

    function getPreviousProductId() public view returns (uint) {
        if (productRegistryAvailable[msg.sender] && productRegistries[msg.sender].numProducts != 0) {
            return productRegistries[msg.sender].numProducts - 1;
        } else {
            return ~uint(0); // largest uint
        }
    }

    // Helper getter functions for working with web3
    // getNumProducts() is just slightly more convenient.
    // getProduct, getProductPart, and getProductBid are required,
    // since there is not other way to access this data.

    function getNumProducts() public view returns (uint) {
        if (productRegistryAvailable[msg.sender]) {
            return productRegistries[msg.sender].numProducts;
        } else {
            return 0; // Zero items if product registry does not exist yet
        }
    }

    function getProduct(uint productId) public view returns (Product memory) {
        require(productRegistryAvailable[msg.sender], "Product Registry not available");
        return productRegistries[msg.sender].products[productId];
    }

    function getProductPart(uint productId, uint partIndex) public view returns (Part memory) {
        require(productRegistryAvailable[msg.sender], "Product Registry not available");
        return productRegistries[msg.sender].products[productId].partsArray[partIndex];
    }

    function getProductBid(uint productId, uint bidIndex) public view returns (ProductBid memory) {
        require(productRegistryAvailable[msg.sender], "Product Registry not available");
        return productRegistries[msg.sender].products[productId].productBids[bidIndex];
    }


    /*
    May only bid on products, not items.
    Could eliminate quantity field by requiring creation of another product to specify quantity.
    Note that array is not the best long-term solution for tracking bids. Will grow large.
    */
    struct Bid {
        address designer;
        uint productId;
        uint bidWei;
        uint quantity;
    }

    // Each customer has funds and array of bids
    struct Customer {
        uint fundsWei;
        uint numBids;
        Bid[] bids;
    }

    mapping (address => Customer) public customers;

    function placeBid(address designer, uint productId, uint bidWei, uint quantity) public {
        // Ensure that product is available
        require(productRegistryAvailable[designer], "Product registry not available for designer");
        ProductRegistry storage registry = productRegistries[designer];
        require(registry.productAvailable[productId], "Product not available in registry");

        // Double-check if uninitialized mapping can be accessed like this.
        Customer storage customer = customers[msg.sender];

        // Get next bid
        Bid storage bid = customer.bids[customer.numBids];

        // Copy all values
        // Might need to create struct instance with Bid({ instead.
        bid.designer = designer;
        bid.productId = productId;
        bid.bidWei = bidWei;
        bid.quantity = quantity;

        // Add lookup to product registry

        // Cannot get storage reference to Product struct
        //ProductRegistry.Product storage product = registry.products[productId];
        //ProductRegistry.Product storage product = registry.products(productId);
        //ProductRegistry.Product storage product = registry.getProductAtId(productId);

        //ProductRegistry.ProductBid storage productBid = product.productBids[product.numBids++];
        //productBid.customer = msg.sender;
        //productBid.bidId = customer.numBids;

        // Increment customer bid count
        customer.numBids++;

        // Todo - this function needs testing
    }

    function removeBid(uint bidId) public {
        Customer storage customer = customers[msg.sender];

        //Bid storage bid = customer.bids[bidId];
        //delete bid; // cannot apply delete to storage pointer
        delete customer.bids[bidId];

        // Todo - There is a current flaw in product registry customer bid
        // That needs a better data structure to support deletion.

        // Todo - This requires more testing
    }

    // These will work as long as long as placeBid is called in the same transaction.
    function getNextBidId() public view returns (uint) {
        return customers[msg.sender].numBids;
    }
    function getPreviousBidId() public view returns (uint) {
        return customers[msg.sender].numBids - 1; // underflow if numBids = 0;
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

    // Also tracking bids on a per-designer-product level for easier scanning.
    // Tracking these within each product


    /*
    Next Steps:
    Do some basic testing of new customer and bidding scheme.
    Should just involve porting over bidding test.

    Create a helper function to print out data with human-readable account names.
    For example
        Print all bids.
        Print product tree. This might be tough.

    Get metamask setup with human-readable account names that match ganache.

    Make website more meaningful. Link with actual code.
    Possible to populate website with web3.js test code? Likely.

    Show visualization of price curve.
    Show visualization of all customer bids - this might be tough.

    Create many more accounts and pseudorandomly place bids.
    Update visualization.

    Deploy on testnet? This may be slow.

    */

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

    /* Need to rework this
    function execute(address bidsAddress, uint productId)  public {
        CustomerBids bidsContract = CustomerBids(bidsAddress);
        uint bids_num = bidsContract.getNextBidId();
        // how is above different from
        //bidsAddress.call(abi.encodeWithSignature("getNextBidId()"));

        bool errorFlag = false;
        uint productNum = 0;

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

        // Needs to be checked, whole execute should be reverted when
        // customer with bid does not have enough funds for the item
        if(errorFlag)
            revert();

        // Each vendor needs to be paid productNum * itemPrice
    }
    */

    function createHash(string memory data)
    public pure returns (bytes32) {
        return keccak256(abi.encodePacked(data));
    }
}
