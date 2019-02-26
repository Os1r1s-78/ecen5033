const Vuln = artifacts.require("Vuln");
const Steal = artifacts.require("Steal");

async function log_accounts(accounts, n)
{
  for (let i = 0; i < n; i++) {
    let ethbal = await web3.eth.getBalance(accounts[i]) / 1e18;
    console.log("account[" + i + "] " + ethbal);
  }
}

// returns wei
function round_wei_to_nearest_eth(wei)
{
  let eth = wei / 1e18;
  return Math.round(eth) * 1e18;
}

contract('Vuln', (accounts) => {
  it('should pass trivial test', async () => {
    assert.equal(0, 0, "0 == 0");
  });
  it('should start with 0 first account', async () => {
    const vulnInstance = await Vuln.deployed();
    const balance = await vulnInstance.balances(accounts[0]);

    assert.equal(balance.valueOf(), 0, "first account not empty");
  });
  it('should accept deposit', async () => {
    const vulnInstance = await Vuln.deployed();

    let b1 = await web3.eth.getBalance(accounts[0]);

    const deposit_amount = 1e18;    
    await vulnInstance.deposit({value: deposit_amount});

    const balance = await vulnInstance.balances(accounts[0]);
    assert.equal(balance.valueOf(), deposit_amount, "account should contain deposited amount");

    let b2 = await web3.eth.getBalance(accounts[0]);
    let diff_eth = (b2 - b1) / 1e18
    console.log("b1: " + b1 + " b2: " + b2 + " diff: " + diff_eth);

  });
  it('should allow withdraw after deposit', async () => {
    const vulnInstance = await Vuln.deployed();

    let b1 = await web3.eth.getBalance(accounts[0]);

    const original_contract_amount = await vulnInstance.balances(accounts[0]);

    const deposit_amount = 1e18;    
    await vulnInstance.deposit({value: deposit_amount});

    const expected_contract_amount = parseInt(original_contract_amount) + parseInt(deposit_amount);

    const balance = await vulnInstance.balances(accounts[0]);
    assert.equal(balance.valueOf(), expected_contract_amount, "account should contain deposited amount");

    await vulnInstance.withdraw();

    const cleared_balance = await vulnInstance.balances(accounts[0]);
    assert.equal(cleared_balance.valueOf(), 0, "account should be zeroed out");

    let b2 = await web3.eth.getBalance(accounts[0]);
    let diff_eth = (b2 - b1) / 1e18
    console.log("b1: " + b1 + " b2: " + b2 + " diff: " + diff_eth);

    await log_accounts(accounts, 3);
  });
  it('should let account 1 deposit and account 2 steal', async () => {
    const vulnInstance = await Vuln.deployed();

    const victim = accounts[1];
    const thief = accounts[2];

    const victim_starting_balance = await web3.eth.getBalance(victim);
    const thief_starting_balance = await web3.eth.getBalance(thief);

    // Victim deposits 1 ETH

    //const deposit_amount = web3.utils.toWei(1);
    const deposit_amount = 1e18;
    await vulnInstance.deposit({value: deposit_amount, from: victim});

    // Thief steals 1 ETH from vulnerable contract

    const steal_fraction = deposit_amount / 5;
    const stealInstance = await Steal.new({from: thief});

    stealInstance.add_fund(vulnInstance.address,
      {value: steal_fraction,
        from: accounts[2]});

    stealInstance.steal(vulnInstance.address, {from: thief});

    stealInstance.get_back({from: thief});

    // Check account totals

    await log_accounts(accounts, 3);

    const victim_final_balance = await web3.eth.getBalance(victim);
    const thief_final_balance = await web3.eth.getBalance(thief);

    assert.equal(round_wei_to_nearest_eth(victim_final_balance - victim_starting_balance),
      0 - deposit_amount, "victim lost 1 eth");

    assert.equal(round_wei_to_nearest_eth(thief_final_balance - thief_starting_balance),
      deposit_amount, "thief gained 1 eth");
  });
});