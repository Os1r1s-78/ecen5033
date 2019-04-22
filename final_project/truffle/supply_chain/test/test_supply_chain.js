const SupplyChain = artifacts.require("SupplyChain");
const Inventory = artifacts.require("Inventory");
const ProductRegistry = artifacts.require("ProductRegistry");
const StructMapping = artifacts.require("StructMapping");
const StructAccess = artifacts.require("StructAccess");
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

    var nextId = await inventoryInstance.getNextItemId();
    await inventoryInstance.addItem(30, price_array);
    var prevId = await inventoryInstance.getPreviousItemId();
    assert.equal(nextId, 0);
    assert.isTrue(nextId.eq(prevId));

    var numItems = await inventoryInstance.numItems();
    assert.equal(numItems, 1);
    const item = await inventoryInstance.items(prevId);

    assert.equal(item.quantityAvailable, 30, "unexpected quantityAvailable");

    // Todo - add test to verify price_array was successfully copied over



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

contract('ProductRegistry', (accounts) => {
  it('should pass ProductRegistry trivial test', async () => {
    assert.equal(0, 0, "0 == 0");
  });

  it('should start with 0 products in registry', async () => {
    const productRegistryInstance = await ProductRegistry.deployed();
    const initialItems = await productRegistryInstance.numProducts();

    assert.equal(initialItems, 0, "registry not initialized empty");
  });

  it('should correctly add a product to the registry', async () => {
    const productRegistryInstance = await ProductRegistry.deployed();

    var parts_array = [];
    parts_array.push({
      part_type: 0,
      manufacturer_ID: 0,
      part_ID: 0,
      quantity: 1
    });

    var nextProductId = await productRegistryInstance.getNextProductId();
    await productRegistryInstance.addProduct(parts_array);
    var prevProductId = await productRegistryInstance.getPreviousProductId();
    assert.equal(nextProductId, 0);
    assert.isTrue(nextProductId.eq(prevProductId));

    var numProducts = await productRegistryInstance.numProducts();
    assert.equal(numProducts, 1, "unexpected numProducts");
    const product_part_1 = await productRegistryInstance.products(prevProductId, 0);

    assert.equal(product_part_1.part_type, parts_array[0].part_type, "unexpected part_type for product's first part");
    assert.equal(product_part_1.manufacturer_ID, parts_array[0].manufacturer_ID, "unexpected manufacturer_ID for product's first part");
    assert.equal(product_part_1.part_ID, parts_array[0].part_ID, "unexpected part_ID of product's first part");
    assert.equal(product_part_1.quantity, parts_array[0].quantity, "unexpected quantity of product's first part");

  });
});
