const SupplyChain = artifacts.require("SupplyChain");
const Inventory = artifacts.require("Inventory");
// Eventually want to omit directly including inventory contract.

async function log_accounts(accounts, n)
{
  for (let i = 0; i < n; i++) {
    let ethbal = await web3.eth.getBalance(accounts[i]) / 1e18;
    console.log("account[" + i + "] " + ethbal);
  }
}

contract('SupplyChain', (accounts) => {

  it('should pass trivial test', async () => {
    assert.equal(0, 0, "0 == 0");
  });

  it('should pass slightly less trivial test', async () => {
    const supplyInstance = await SupplyChain.deployed();

    await supplyInstance.alwaysPasses().then(result =>
      assert.equal(result.valueOf(), true, "does not always pass"));
  });

});

contract('Inventory', (accounts) => {
  it('should pass Inventory trivial test', async () => {
    assert.equal(0, 0, "0 == 0");
  });

  it('should start with 0 items in inventory', async () => {
    const inventoryInstance = await Inventory.deployed();
    const initialItems = await inventoryInstance.numItems();

    assert.equal(initialItems, 0, "some items already in inventory");
    // This works too
    //assert.equal(initialItems.valueOf(), 0, "some items already in inventory");
  });

  it('should be able to pass struct', async () => {
    const inventoryInstance = await Inventory.deployed();
    const price_struct = {
        quantity: 100,
        priceWei: 200
    };

    await inventoryInstance.use_to_test_passing_struct_from_web3(price_struct);
    const internal_ps = await inventoryInstance.temporary_price_struct_for_testing();

    assert.equal(internal_ps.quantity, price_struct.quantity);
    assert.equal(internal_ps.priceWei, price_struct.priceWei);
  });

  it('should be able to add inventory item', async () => {
    const inventoryInstance = await Inventory.deployed();
    var price_array = [];
    price_array.push({
        quantity: 100,
        priceWei: 200
    });

    console.log("Hello.....");

    var nextId = await inventoryInstance.getNextItemId();
    await inventoryInstance.addItem(30, price_array);
    var prevId = await inventoryInstance.getPreviousItemId();
    assert.equal(nextId, nextId);
    assert.equal(nextId, 0);
    assert.equal(0, prevId);
    assert.equal(prevId, prevId);
    /* All of the above pass, but the below fails with this absurd error:
    AssertionError: expected <BN: 0> to equal <BN: 0>
    */
    //assert.equal(nextId, prevId);
    /* BN comparison also failing
    https://github.com/EthWorks/bn-chai/issues/2
    */
    //expect(nextId).to.eq.BN(prevId);
    /* Unwrapped workaround
    TypeError: Cannot read property 'be' of undefined
    */
    //(nextId.eq(prevId)).should.be.true;

    /* This seems to be the only correct way
    */
    assert.isTrue(nextId.eq(prevId));


    var numItems = await inventoryInstance.numItems();
    assert.equal(numItems, 1);

    /*
    One of these is supposedly the correct way to do it.
    https://ethereum.stackexchange.com/questions/34614/return-a-struct-from-a-mapping-in-test-truffle
    Not sure why structure is not being returned correctly.
    Might be due to experimental ABI. Could test with smaller standalone project.

    Todo - get correct access to item struct
    */
    //const item = await inventoryInstance.items(prevId);
    //const item = await inventoryInstance.items.call(prevId);
    const item = await inventoryInstance.items(0);
    //const item = await inventoryInstance.items.call(0);
    console.log(item); // this logs the item quantity as hex BN
    console.log(item.quantityAvailable); // undefined

    assert.equal(item.quantityAvailable, 30);




    // Test adding another item
    nextId = await inventoryInstance.getNextItemId();
    await inventoryInstance.addItem(40, price_array);
    prevId = await inventoryInstance.getPreviousItemId();
    assert.equal(nextId, 1);
    assert.isTrue(nextId.eq(prevId));

    var numItems = await inventoryInstance.numItems();
    assert.equal(numItems, 2);
  });
});