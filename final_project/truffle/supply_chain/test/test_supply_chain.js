const SupplyChain = artifacts.require("SupplyChain");
/*
const Inventory = artifacts.require("Inventory");
const ProductRegistry = artifacts.require("ProductRegistry");
const CustomerBids = artifacts.require("CustomerBids");
const StructMapping = artifacts.require("StructMapping");
const StructAccess = artifacts.require("StructAccess");
*/

async function log_accounts(accounts, n)
{
  for (let i = 0; i < n; i++) {
    let ethbal = await web3.eth.getBalance(accounts[i]) / 1e18;
    console.log("account[" + i + "] " + ethbal);
  }
}


contract('SupplyChain', (accounts) => {
  it('should pass Inventory trivial test', async () => {
    assert.equal(0, 0, "0 == 0");
  });

  it('should start with 0 items in inventory', async () => {
    const instance = await SupplyChain.deployed();

    const inventory = await instance.inventories(accounts[0]);
    const initialItems = inventory.numItems;
    //console.log({initialItems});
    assert.equal(initialItems, 0, "some items already in inventory");

    // Interesting that this doesn't work:
    // Possible strange interaction with await and struct member
    //const initialItems2 = await instance.inventories(accounts[0]).numItems;
    //console.log({initialItems2});
    //assert.equal(initialItems2, 0, "some items already in inventory");

    // This is probably the best way to execute this test
    const initialItems3 = (await instance.inventories(accounts[0])).numItems;
    //console.log({initialItems3});
    assert.equal(initialItems3, 0, "some items already in inventory");
  });

  it('should be able to add inventory item', async () => {
    //const inventoryInstance = await Inventory.deployed();

    const instance = await SupplyChain.deployed();

    var price_array = [];
    const descHash = await instance.createHash('sample description');
    // Interesting that these produce different hashes
    //const crypto = require("crypto");
    //const descHash = crypto.createHash('sha256').update('sample description').digest();
    //console.log({descHash});
    //console.log({descHashPure});
    //assert.equal(descHash, descHashPure, "Unequal hashes");
    price_array.push({
        quantity: 100,
        priceWei: 200
    });

    var nextId = await instance.getNextItemId();
    await instance.addItem(30, descHash, price_array);
    var prevId = await instance.getPreviousItemId();
    assert.equal(nextId, 0);
    assert.isTrue(nextId.eq(prevId));

    var numItems = await instance.getNumItems();
    // This also works in place of getNumItems()
    //var numItems = (await instance.inventories(accounts[0])).numItems;
    assert.equal(numItems, 1);
    var item = await instance.getItem(prevId);

    assert.equal(item.quantityAvailable, 30, "unexpected quantityAvailable");
    var price_list = await instance.getPriceStruct(0, 0);

    assert.equal(price_list.quantity, 100 , "unexpected price list quantity");
    assert.equal(price_list.priceWei, 200 , "unexpected price list price");

    // second item being added to the inventory
    const descHash2 = await instance.createHash('second sample description');
    price_array.push({
      quantity: 456,
      priceWei: 678
    });

    nextId = await instance.getNextItemId();
    await instance.addItem(40, descHash2, price_array);
    numItems = (await instance.inventories(accounts[0])).numItems;
    assert.equal(numItems, 2);
    prevId = await instance.getPreviousItemId();
    assert.equal(nextId, 1);
    assert.isTrue(nextId.eq(prevId));

    item = await instance.getItem(prevId);
    assert.equal(item.quantityAvailable, 40, "unexpected quantityAvailable");

    price_list = await instance.getPriceStruct(prevId, 1);
    assert.equal(price_list.quantity, 456 , "unexpected price list quantity");
    assert.equal(price_list.priceWei, 678 , "unexpected price list price");

    nextId = await instance.getNextItemId();
    assert.equal(nextId, 2);
  });

  // Todo - there are many untested inventory functions:
  // replaceQuantity, incrementQuantity, decrementQuantity, replacePrices
});


contract('SupplyChain', (accounts) => {
  it('should pass ProductRegistry trivial test', async () => {
    assert.equal(0, 0, "0 == 0");
  });

  it('should start with 0 products in registry', async () => {
    const instance = await SupplyChain.deployed();

    const initialItems = await instance.getNumProducts();

    assert.equal(initialItems, 0, "registry not initialized empty");
  });

  it('should correctly add a product to the registry', async () => {
    const instance = await SupplyChain.deployed();

    var parts_array = [];
    parts_array.push({
      part_type: 1,
      manufacturer_ID: accounts[2],
      part_ID: 3,
      quantity: 4
    });
    parts_array.push({
      part_type: 1,
      manufacturer_ID: accounts[3],
      part_ID: 4,
      quantity: 4
    });

    var nextProductId = await instance.getNextProductId();
    await instance.addProduct(parts_array);
    var prevProductId = await instance.getPreviousProductId();
    assert.equal(nextProductId, 0);
    assert.isTrue(nextProductId.eq(prevProductId));

    var numProducts = await instance.getNumProducts();
    assert.equal(numProducts, 1, "unexpected numProducts");

    for (i = 0; i < parts_array.length; i++) {
      const product_part = await instance.getProductPart(prevProductId, i);

      assert.equal(product_part.part_type, parts_array[i].part_type, "unexpected part_type");
      assert.equal(product_part.manufacturer_ID, parts_array[i].manufacturer_ID, "unexpected manufacturer_ID");
      assert.equal(product_part.part_ID, parts_array[i].part_ID, "unexpected part_ID");
      assert.equal(product_part.quantity, parts_array[i].quantity, "unexpected quantity");
    }

  });
});

contract('SupplyChain', (accounts) => {

  it('should start with 0 bids', async () => {
    const instance = await SupplyChain.deployed();

    const initialBids = await instance.getNumBids();

    assert.equal(initialBids, 0, "some bids already recorded");
  });

  it('should be able to place bid', async () => {
    const instance = await SupplyChain.deployed();

    const designer = accounts[1];

    // May only bid on products in registry, so must set one of those up first
    var parts_array = [];
    parts_array.push({
      part_type: 1,
      manufacturer_ID: accounts[2],
      part_ID: 3,
      quantity: 4
    });
    await instance.addProduct(parts_array, {from: designer});

    const productId = await instance.getPreviousProductId({from: designer});
    const bidWei = 20;
    const quantity = 2;

    await instance.placeBid(designer, productId, bidWei, quantity);

    var numBids = await instance.getNumBids();

    assert.equal(numBids, 1, "something other than just a single bid");

    const bidId = await instance.getPreviousBidId();

    const bid = await instance.bids(bidId);

    assert.equal(bid.customer, accounts[0], "bid customer mismatch");
    assert.equal(bid.designer, designer, "bid designer mismatch");
    //assert.equal(bid.productId, productId, "bid productId mismatch");
    // BN workaround. No need to change bidWei and quantity comparison, since those are not BN in js yet.
    assert.isTrue(bid.productId.eq(productId), "bid productId mismatch");
    assert.equal(bid.bidWei, bidWei, "bid wei mismatch");
    assert.equal(bid.quantity, quantity, "bid quantity mismatch");

    // Delete bid to clean-up for next test
    await instance.removeBid(bidId);

    var numBids = await instance.getNumBids();
    assert.equal(numBids, 0, "some bids remaining");
  });

  it('place and delete multiple bids', async () => {
    const instance = await SupplyChain.deployed();

    var numBids = await instance.getNumBids();

    assert.equal(numBids, 0, "some bids already recorded");

    // Create parts to bid on and place bids

    const designer = accounts[1];

    // May only bid on products in registry, so must set one of those up first
    var parts_array = [];
    parts_array.push({
      part_type: 1,
      manufacturer_ID: accounts[2],
      part_ID: 3,
      quantity: 4
    });

    // Setup array of bids
    var bid_array = [];

    for (var i = 10; i < 15; i++) {
      parts_array[0].part_ID = i;
      await instance.addProduct(parts_array, { from: designer });
      const productId = await instance.getPreviousProductId({ from: designer });

      bid_array.push({ designer: designer, productId: productId, bidWei: i * 10, quantity: i });
    }

    // Setup dict of bids with bidId key and place those bids
    var bid_dict = {};
    for (bid of bid_array) {
      //console.log(bid);
      await instance.placeBid(bid.designer, bid.productId, bid.bidWei, bid.quantity);
      var bidId = await instance.getPreviousBidId();
      bid_dict[bidId] = bid;
    }

    // Check that bidId incremented appropriately
    numBids = await instance.getNumBids();
    assert.equal(numBids, bid_array.length, "missing bids");

    // Read bid data on-chain and compare to expected values
    // Async function to avoid duplication
    async function compareToExpected() {
      for (const [ key, value ] of Object.entries(bid_dict)) {
        var bid = await instance.bids(key);
        assert.equal(bid.customer, accounts[0], "bid customer mismatch");
        assert.equal(bid.designer, designer, "bid designer mismatch");
        //assert.equal(bid.productId, value.productId, "bid productId mismatch");
        // BN workaround. No need to change bidWei and quantity comparison, since those are not BN in js yet.
        assert.isTrue(bid.productId.eq(value.productId), "bid productId mismatch");
        assert.equal(bid.bidWei, value.bidWei, "bid wei mismatch");
        assert.equal(bid.quantity, value.quantity, "bid quantity mismatch");
      }
    }

    await compareToExpected();

    // Delete some bids
    for (const key in bid_dict) {
      // only delete even bidIds
      if (key % 2 == 0) {
        await instance.removeBid(key);
        delete bid_dict[key];

        // Ensure deleted
        var bid = await instance.bids(key);
        assert.equal(bid.customer, 0, "bid customer not deleted");
        assert.equal(bid.designer, 0, "bid designer not deleted");
        assert.equal(bid.productId, 0, "bid productId not deleted");
        assert.equal(bid.bidWei, 0, "bid wei not deleted");
        assert.equal(bid.quantity, 0, "bid quantity not deleted");
      }
    }

    // Make sure other bids are still on chain
    await compareToExpected();

  });

  it('deposit and withdraw funds', async () => {
    const instance = await SupplyChain.deployed();

    const c1 = accounts[1];
    const c2 = accounts[2];

    const c1_starting_balance = await web3.eth.getBalance(c1);
    const c2_starting_balance = await web3.eth.getBalance(c2);

    //const deposit_amount = web3.utils.toWei(1);
    const deposit_amount = 1e18;
    const weiDelta = 1e16; // 1% of 1 eth

    // Transfer funds from c1
    await instance.depositFunds({value: deposit_amount, from: c1});
    // Check that balances transfered
    // Customer account debited
    var c1_balance = await web3.eth.getBalance(c1);
    var c1_loss = c1_starting_balance - c1_balance;
    assert.closeTo(c1_loss, deposit_amount, weiDelta, "c1 did not lose deposit amount");
    // Customer funds recorded on chain
    var c1_customer_struct = await instance.customers(c1);
    var c1_contract_funds = c1_customer_struct.fundsWei;
    assert.equal(c1_contract_funds, deposit_amount, "c1 contract funds not incremented");

    // Transfer funds from c2
    await instance.depositFunds({value: deposit_amount, from: c2});
    // Check that balances transfered
    // Customer account debited
    var c2_balance = await web3.eth.getBalance(c2);
    var c2_loss = c2_starting_balance - c2_balance;
    assert.closeTo(c2_loss, deposit_amount, weiDelta, "c2 did not lose deposit amount");
    // Customer funds recorded on chain
    var c2_customer_struct = await instance.customers(c2);
    var c2_contract_funds = c2_customer_struct.fundsWei;
    assert.equal(c2_contract_funds, deposit_amount, "c2 contract funds not incremented");

    // Withdraw funds from c1
    await instance.withdrawFunds({from: c1});
    // Check that balances transfered
    // Customer account debited
    var c1_balance = await web3.eth.getBalance(c1);
    var c1_loss = c1_starting_balance - c1_balance;
    assert.closeTo(c1_loss, 0, weiDelta, "c1 did not get funds returned");
    // Customer funds recorded on chain
    var c1_customer_struct = await instance.customers(c1);
    var c1_contract_funds = c1_customer_struct.fundsWei;
    assert.equal(c1_contract_funds, 0, "c1 contract funds not zeroed");

    // Withdraw funds from c1 again
    await instance.withdrawFunds({from: c1});
    // Check that balances transfered
    // Customer account debited
    var c1_balance = await web3.eth.getBalance(c1);
    var c1_loss = c1_starting_balance - c1_balance;
    assert.closeTo(c1_loss, 0, weiDelta, "c1 did not get funds returned");
    // Customer funds recorded on chain
    var c1_customer_struct = await instance.customers(c1);
    var c1_contract_funds = c1_customer_struct.fundsWei;
    assert.equal(c1_contract_funds, 0, "c1 contract funds not zeroed");

    // Withdraw funds from c2
    await instance.withdrawFunds({from: c2});
    // Check that balances transfered
    // Customer account debited
    var c2_balance = await web3.eth.getBalance(c2);
    var c2_loss = c2_starting_balance - c2_balance;
    assert.closeTo(c2_loss, 0, weiDelta, "c2 did not get funds returned");
    // Customer funds recorded on chain
    var c2_customer_struct = await instance.customers(c2);
    var c2_contract_funds = c2_customer_struct.fundsWei;
    assert.equal(c2_contract_funds, 0, "c2 contract funds not zeroed");

  });

});

contract('SupplyChain', (accounts) => {

  it('should pass real-ish world example', async () => {
    const instance = await SupplyChain.deployed();

    const kbAccessoriesCo = accounts[1];
    // keycaps, switches - item
    const miscElectronicsCo = accounts[2];
    // diodes - item
    const pcbFabCo = accounts[3];
    // pcb - item
    const plasticsCo = accounts[4];
    // enclosure - item
    const shippingCo = accounts[5];
    // fulfillment - item

    const kbDesigner = accounts[6];
    // keyboard - product (all of the above except for fulfillment)

    // customers bid on:
    // shipped keyboard - product (keyboard + fulfillment)

    const customer1 = accounts[7];
    const customer2 = accounts[8];
    const customer3 = accounts[9];

    // ---------- Supplier phase

    // add keycaps
    const keycapDesc = "Generic keyboard keycaps";
    const keycapHashedDesc = await instance.createHash(keycapDesc);
    const keycapQuantity = 50000;
    var keycapPriceArray = [];
    keycapPriceArray.push({ quantity: 1, priceWei: 10 });
    keycapPriceArray.push({ quantity: 100, priceWei: 8 });
    keycapPriceArray.push({ quantity: 10000, priceWei: 5 });

    await instance.addItem(
      keycapQuantity,
      keycapHashedDesc,
      keycapPriceArray,
      { from: kbAccessoriesCo }
    );

    keycapId = await instance.getPreviousItemId({from: kbAccessoriesCo});
    //keycapId = keycapId.toNumber(); // Need to convert these from BN for use in parts array. toString() may be better.
    assert.equal(keycapId, 0, "unexpected keycapId");


    // add switches
    const switchDesc = "Premium mechanical keyboard switches";
    const switchHashedDesc = await instance.createHash(switchDesc);
    const switchQuantity = 10000;
    var switchPriceArray = [];
    switchPriceArray.push({ quantity: 1, priceWei: 500 });
    switchPriceArray.push({ quantity: 100, priceWei: 400 });
    switchPriceArray.push({ quantity: 10000, priceWei: 250 });

    await instance.addItem(
      switchQuantity,
      switchHashedDesc,
      switchPriceArray,
      { from: kbAccessoriesCo }
    );

    const switchId = await instance.getPreviousItemId({from: kbAccessoriesCo});
    assert.equal(switchId, 1, "unexpected switchId");


    // add diodes
    const diodeDesc = "Some common diodes";
    const diodeHashedDesc = await instance.createHash(diodeDesc);
    const diodeQuantity = 30000;
    var diodePriceArray = [];
    diodePriceArray.push({ quantity: 1, priceWei: 1000 });
    diodePriceArray.push({ quantity: 25, priceWei: 500 });
    diodePriceArray.push({ quantity: 500, priceWei: 300 });

    await instance.addItem(
      diodeQuantity,
      diodeHashedDesc,
      diodePriceArray,
      { from: miscElectronicsCo }
    );

    const diodeId = await instance.getPreviousItemId({from: miscElectronicsCo});
    assert.equal(diodeId, 0, "unexpected diodeId");


    // add pcbs
    const pcbDesc = "Custom PCBs for this keyboard";
    const pcbHashedDesc = await instance.createHash(pcbDesc);
    const pcbQuantity = 400;
    var pcbPriceArray = [];
    pcbPriceArray.push({ quantity: 1, priceWei: 100000 });
    pcbPriceArray.push({ quantity: 5, priceWei: 50000 });
    pcbPriceArray.push({ quantity: 10, priceWei: 20000 });
    pcbPriceArray.push({ quantity: 25, priceWei: 10000 });

    await instance.addItem(
      pcbQuantity,
      pcbHashedDesc,
      pcbPriceArray,
      { from: pcbFabCo }
    );

    const pcbId = await instance.getPreviousItemId({from: pcbFabCo});
    assert.equal(pcbId, 0, "unexpected pcbId");


    // add enclosures
    const enclosureDesc = "Robust custom plastic enclosures for this keyboard";
    const enclosureHashedDesc = await instance.createHash(enclosureDesc);
    const enclosureQuantity = 300;
    var enclosurePriceArray = [];
    enclosurePriceArray.push({ quantity: 5, priceWei: 10000 });
    enclosurePriceArray.push({ quantity: 25, priceWei: 6000 });
    enclosurePriceArray.push({ quantity: 100, priceWei: 3000 });

    await instance.addItem(
      enclosureQuantity,
      enclosureHashedDesc,
      enclosurePriceArray,
      { from: plasticsCo }
    );

    const enclosureId = await instance.getPreviousItemId({from: plasticsCo});
    assert.equal(enclosureId, 0, "unexpected enclosureId");



    // ----------------------------- Designer phase
    // Links items and products together to form a "keyboard" product

    // Cannot get enum names from solidity, so must make copy here
    var PartType = {
      ITEM: 0,
      PRODUCT: 1,
    };

    // Keyboard product contains:
    // 75 each of: keycaps, switches, diodes
    // 1 each of: pcb, enclosure
    // Simplified version of: https://imgur.com/d6wb1NC

    var kbPartsArray = [];
    kbPartsArray.push({
      part_type: PartType.ITEM,
      manufacturer_ID: kbAccessoriesCo,
      part_ID: keycapId.toNumber(), // Convert from BN
      quantity: 75
    });
    kbPartsArray.push({
      part_type: PartType.ITEM,
      manufacturer_ID: kbAccessoriesCo,
      part_ID: switchId.toNumber(),
      quantity: 75
    });
    kbPartsArray.push({
      part_type: PartType.ITEM,
      manufacturer_ID: miscElectronicsCo,
      part_ID: diodeId.toNumber(),
      quantity: 75
    });
    kbPartsArray.push({
      part_type: PartType.ITEM,
      manufacturer_ID: pcbFabCo,
      part_ID: pcbId.toNumber(),
      quantity: 1
    });
    kbPartsArray.push({
      part_type: PartType.ITEM,
      manufacturer_ID: plasticsCo,
      part_ID: enclosureId.toNumber(),
      quantity: 1
    });

    await instance.addProduct(kbPartsArray, {from: kbDesigner});
    const kbProductId = await instance.getPreviousProductId({from: kbDesigner});
    assert.equal(kbProductId, 0, "unexpected kbProductId");

    // ---------------- Bidding phase
    // Customers bid on their own unique "shipped keyboards" product
    // Fulfillment will add their hashed addresses during this step

    async function setupShipping(customer_address) {
      const shippingHashedDesc = await instance.createHash(customer_address);
      // Generate a random-ish price based on the address
      const price = shippingHashedDesc[0] * 10000;
      const shippingQuantity = 1;
      var shippingPriceArray = [];
      shippingPriceArray.push({ quantity: 1, priceWei: price });

      await instance.addItem(
        shippingQuantity,
        shippingHashedDesc,
        shippingPriceArray,
        { from: shippingCo }
      );

      const shippingId = await instance.getPreviousItemId({ from: shippingCo });
      return shippingId;
    }

    // Customer 1 wants a single kb
    var shippedKbC1PartsArray = [];
    shippedKbC1PartsArray.push({
      part_type: PartType.PRODUCT,
      manufacturer_ID: kbDesigner,
      part_ID: kbProductId.toNumber(),
      quantity: 1
    });

    const shippingC1Id = await setupShipping("Shipping from KB plant to customer 1 at 123 fake street, Springfield USA");
    assert.equal(shippingC1Id, 0, "unexpected shippingC1Id");

    shippedKbC1PartsArray.push({
      part_type: PartType.ITEM,
      manufacturer_ID: shippingCo,
      part_ID: shippingC1Id.toNumber(),
      quantity: 1
    });

    await instance.addProduct(shippedKbC1PartsArray, {from: customer1});
    const shippedKbC1ProductId = await instance.getPreviousProductId({from: customer1});

    // Customer 2 wants five KBs
    var shippedKbC2PartsArray = [];
    shippedKbC2PartsArray.push({
      part_type: PartType.PRODUCT,
      manufacturer_ID: kbDesigner,
      part_ID: kbProductId.toNumber(),
      quantity: 5
    });

    const shippingC2Id = await setupShipping("Shipping from KB plant to customer 2 at 555 somewhere");
    assert.equal(shippingC2Id, 1, "unexpected shippingC2Id");

    shippedKbC2PartsArray.push({
      part_type: PartType.ITEM,
      manufacturer_ID: shippingCo,
      part_ID: shippingC2Id.toNumber(),
      quantity: 1
    });

    await instance.addProduct(shippedKbC2PartsArray, {from: customer2});
    const shippedKbC2ProductId = await instance.getPreviousProductId({from: customer2});


    // Customer 3 wants a single kb
    var shippedKbC3PartsArray = [];
    shippedKbC3PartsArray.push({
      part_type: PartType.PRODUCT,
      manufacturer_ID: kbDesigner,
      part_ID: kbProductId.toNumber(),
      quantity: 1
    });

    const shippingC3Id = await setupShipping("Shipping from KB plant to customer 3 where the sidewalk ends");
    assert.equal(shippingC3Id, 2, "unexpected shippingC3Id");

    shippedKbC3PartsArray.push({
      part_type: PartType.ITEM,
      manufacturer_ID: shippingCo,
      part_ID: shippingC3Id.toNumber(),
      quantity: 1
    });

    await instance.addProduct(shippedKbC3PartsArray, {from: customer3});
    const shippedKbC3ProductId = await instance.getPreviousProductId({from: customer3});
  });
});
/*

*/