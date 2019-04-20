const SupplyChain = artifacts.require("SupplyChain");

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

    await supplyInstance.always_passes().then(result =>
      assert.equal(result.valueOf(), true, "does not always pass"));

  });
});
