## Project 2

### Offline Testing

Automated testing is available for both `rock paper scissors` and `vulnerable contract` on a local blockchain using the Truffle framework.

#### Testing Steps

Install Truffle:

```npm install -g truffle```

To test:
1. In one terminal, run `truffle develop --log`
2. In another terminal, navigate to either `truffle/vuln` or `truffle/rps`
3. run `truffle test`

### Part 1 - Rock Paper Scissors

#### Rules
* Any account is allowed to pay gas to enable the withdraw operation.
* Upon a tie, the first call to `withdraw` deposits funds to both players. There is some unfairness in making the caller the sole bearer of the gas fee. A possible improvement is to deduct this gas fee from the wager pool and refund this to the caller.
* Players that make invalid plays or commitments forfit their wager. If both player choices are invalid, the first withdrawer gets all wagers.
* After the 2nd play, there is a 10 minute time limit for both players to reveal their commitment. After this timeout period anyone can trigger a withdraw, and players with no revealed choice forfit their wager.
* An uncooperative participant can make an initial wager below the gas price, and this will disincentivize another player from participating, since their gas fees will exceed any possible winnings. Of course, the initial player is also burning gas without the possibility of reclaiming these fees. Increasing the lower wager limit will avoid this issue, but that interferres with the use case of users who have ethical objections to gambling, but who still want to play RPS on blockchain.

### Part 2 - Vulnerable Contract    

Contract is at [0x7f7c957edb5e57d6fde45229608ce1052e615c2b](https://ropsten.etherscan.io/address/0x7f7c957edb5e57d6fde45229608ce1052e615c2b)      

<br>Deposit 0.1 ether from attack contract into the vulnearbale contract          
   ![Deposit From Contract](screenshots/deposit_from_contract.JPG)  

<br>Stole from the vulnerable contract and emptied out the contract, stealing is limited to 5x the initial deposit:  
   ![Stole From Contract](screenshots/stole_5times_emptied_contract.JPG)  
