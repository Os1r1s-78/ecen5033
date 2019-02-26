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

  it('should play correctly without timeout', async () => {
    const rpsInstance = await RPS.deployed();

    async function play_simple_round(p1_choice, p2_choice, wager, expected_p1_gain, expected_p2_gain) {
      const p1 = accounts[1];
      const p2 = accounts[2];

      const p1_initial_balance = await web3.eth.getBalance(p1);
      const p2_initial_balance = await web3.eth.getBalance(p2);

      // todo random salt
      const p1_salt = "mysalt"
      const p1_commitment = await rpsInstance.encode_commitment(p1_choice, p1_salt);

      const p2_salt = "othersalt"
      const p2_commitment = await rpsInstance.encode_commitment(p2_choice, p2_salt);

      await rpsInstance.play(p1_commitment, {value: wager, from: p1});
      await rpsInstance.play(p2_commitment, {value: wager, from: p2});

      await rpsInstance.reveal(p1_choice, p1_salt, {from: p1});
      await rpsInstance.reveal(p2_choice, p2_salt, {from: p2});

      // Any account is welcome to pay the gas fee to withdraw.
      // So letting 3rd party account withdraw to test if both players lose.
      await rpsInstance.withdraw({from: accounts[0]});

      const p1_final_balance = await web3.eth.getBalance(p1);
      const p2_final_balance = await web3.eth.getBalance(p2);

      const p1_gain = p1_final_balance - p1_initial_balance;
      const p2_gain = p2_final_balance - p2_initial_balance;

      // Round gains to nearest wager multiple to account for unknown gas cost
      assert.equal(Math.round(p1_gain / wager), Math.round(expected_p1_gain / wager), "unexpected player 1 gains");
      assert.equal(Math.round(p2_gain / wager), Math.round(expected_p2_gain / wager), "unexpected player 2 gains");
    }

    const bet = 1e18;
    await play_simple_round("rock",  "rock",     bet, 0,    0);
    await play_simple_round("rock",  "paper",    bet, -bet, bet);
    await play_simple_round("rock",  "scissors", bet, bet,  -bet);
    await play_simple_round("paper", "r",        bet, bet,  -bet);
    await play_simple_round("paper", "p",        bet, 0,    0);
    await play_simple_round("paper", "s",        bet, -bet, bet);
    await play_simple_round("s",     "r",        bet, -bet, bet);
    await play_simple_round("s",     "p",        bet, bet,  -bet);
    await play_simple_round("s",     "s",        bet, 0,    0);

    // Wagers are lost to first withdrawer if both player's choices are invalid
    await play_simple_round("foo",   "bar",      bet, -bet, -bet);

    // A valid choice always wins against an invalid choice
    await play_simple_round("rock",  "bar",      bet, bet,  -bet);
  });
});
