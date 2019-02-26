const RPS = artifacts.require("RPS");

async function log_accounts(accounts, n)
{
  for (let i = 0; i < n; i++) {
    let ethbal = await web3.eth.getBalance(accounts[i]) / 1e18;
    console.log("account[" + i + "] " + ethbal);
  }
}

contract('RPS', (accounts) => {

  it('should pass trivial test', async () => {
    assert.equal(0, 0, "0 == 0");
  });

  it('should match choice to case-insensitive partial string', async () => {
    const rpsInstance = await RPS.deployed();

    // Cannot get enum names from solidity, so must make copy here
    var Choice = {
      UNKNOWN: 0,
      INVALID: 1,
      ROCK: 2,
      PAPER: 3,
      SCISSORS: 4,
    };

    async function check_choice(choice, string) {
      await rpsInstance.choice_to_enum(string).then(result =>
        assert.equal(result.valueOf(), choice, "got " + result.valueOf() + " for " + string + " instead of expected " + choice));
    }

    /*
    Note that if the choice_to_enum function is marked as non-pure, then it becomes a transaction.
    This is useful for enabling debugging, but then the return value becomes a transaction reciept,
    and is useless for unit testing.
    In the pure function case (not debuggable), the return value is the actual value, and can be used for unit testing.
    https://ethereum.stackexchange.com/questions/15704/how-to-get-return-value-of-function-for-solidity-contract
    */

    await check_choice(Choice.ROCK, "rock");
    await check_choice(Choice.ROCK, "ROCK");
    await check_choice(Choice.ROCK, "r");
    await check_choice(Choice.ROCK, "ro");
    await check_choice(Choice.ROCK, "rOcK");
    await check_choice(Choice.ROCK, "rOcKs");

    await check_choice(Choice.INVALID, "rs");
    await check_choice(Choice.INVALID, "rrock");

    await check_choice(Choice.PAPER, "paper");
    await check_choice(Choice.PAPER, "PAPER");
    await check_choice(Choice.PAPER, "p");
    await check_choice(Choice.PAPER, "pa");
    await check_choice(Choice.PAPER, "pAp");

    await check_choice(Choice.INVALID, "papr");
    await check_choice(Choice.INVALID, "paaper");

    await check_choice(Choice.SCISSORS, "scissors");
    await check_choice(Choice.SCISSORS, "SCISSORS");
    await check_choice(Choice.SCISSORS, "S");
    await check_choice(Choice.SCISSORS, "Sc");

    await check_choice(Choice.INVALID, "cissors");

    await check_choice(Choice.INVALID, "random");
  });

  it('should play correctly', async () => {
    const rpsInstance = await RPS.deployed();

    // todo random salt
    const p1_choice = "rock"
    const p1_salt = "mysalt"

    const p1_commitment = await rpsInstance.encode_commitment(p1_choice, p1_salt);
    console.log(p1_commitment);

    const p2_choice = "paper"
    const p2_salt = "othersalt"

    const p2_commitment = await rpsInstance.encode_commitment(p2_choice, p2_salt);
    console.log(p2_commitment);

    const p1 = accounts[1];
    const p2 = accounts[2];

    await log_accounts(accounts, 3);

    const wager = 1e18; // 1 eth
    await rpsInstance.play(p1_commitment, {value: wager, from: p1});
    await rpsInstance.play(p2_commitment, {value: wager, from: p2});

    const p1_address = await rpsInstance.p1_address();
    const p2_address = await rpsInstance.p2_address();

    /*
    // address debugging. problem solved now
    console.log(p1_address);
    console.log(p2_address);
    console.log(p1);
    console.log(p2);
    */

    //return;
    await rpsInstance.reveal(p1_choice, p1_salt, {from: p1});
    await rpsInstance.reveal(p2_choice, p2_salt, {from: p2});

    await rpsInstance.withdraw({from: p2});

    console.log("------ game played --------")
    await log_accounts(accounts, 3);

    //assert.equal(balance.valueOf(), 0, "first account not empty");
  });

  /*
  // old test for troubleshooting enum array
  it('array test', async () => {
    const rpsInstance = await RPS.deployed();

    await rpsInstance.withdraw();
    const winner = await rpsInstance.winner();

    console.log(winner);
  });
  */
});