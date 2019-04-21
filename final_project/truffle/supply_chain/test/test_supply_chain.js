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

  it('should be able to add inventory item', async () => {
    const inventoryInstance = await Inventory.deployed();

    /*
    See this example for how to add pass struct parameter via web3.
    https://github.com/trufflesuite/truffle/pull/1409/commits/e82707817cc2697a349633cc23d29118a564ed0b#diff-17925857bd735731a1948f43a126acb2

    I suspect this can also work with array of struct, but should probably start with simple struct example first.
    See next function for this.

    */
    //assert.equal(todo, todo, "failed to add inventory item");
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
});