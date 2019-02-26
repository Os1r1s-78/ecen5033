pragma solidity ^0.5.0;

// API and some comments from https://ecen5033.org/proj2.pdf

contract RPS {

    // possibly better to store these in a player struct array

    bytes32 p1_commitment;
    bytes32 p2_commitment;

    address payable public p1_address;
    address payable public p2_address;

    enum Choice {UNKNOWN, INVALID, ROCK, PAPER, SCISSORS}
    Choice p1_choice = Choice.UNKNOWN; // these might be the defaults anyway
    Choice p2_choice = Choice.UNKNOWN;

    enum Winner {UNKNOWN, P1, P2, TIE, EITHER}

    uint wager;
    // no need for p2 wager
    
    // Player 2 end time, for reveal timeout
    uint p2_end_time;
    uint timeout_duration = 10 minutes;
    
    /*
    Returns true if first 'len' characters 'full' string matches of 'pre' string
    */
    function is_prefix(bytes memory pre, uint len, string memory full) private pure returns (bool) {
        bytes memory full_bytes = bytes(full);
        for (uint i = 0; i < len; i++) {
            if (pre[i] != full_bytes[i]) {
                return false;
            }
        }
        return true;
    }

    // note that memory type to memory type creates a reference
    function choice_to_enum(string memory choice_str) private pure returns (Choice) {
        bytes memory choice = bytes(choice_str);
        uint len = choice.length;
        // in-place conversion to lower-case
        for (uint i = 0; i < len; i++) {
            if (choice[i] >= bytes1("A") && choice[i] <= bytes1("Z")) {
                // convert to lower case, 'a' > 'A'
                /* I miss C :( */
                //choice[i] -= 'a' - 'A';
                //choice[i] -= bytes("a") - bytes("A");
                //choice[i] -= 32;
                //choice[i] -= bytes1(uint8(32));
                choice[i] = bytes1(uint8(choice[i]) - 32);
            }
        }
        if (is_prefix(choice, len, "rock")) {
            return Choice.ROCK;
        } else if (is_prefix(choice, len, "paper")) {
            return Choice.PAPER;
        } else if (is_prefix(choice, len, "scissors")) {
            return Choice.SCISSORS;
        } else {
            return Choice.INVALID;
        }
    }
    
    /*
       Given a choice (e.g. "rock", "paper" or "scissors")
       and a random/blinding string, returns a commitment
       of the pair. Note calls to this function occur offline
       (i.e. do not appear on the blockchain). If you leave the
       'pure' keyword in the function signature,
       function calls to this won't publish to the blockchain.
     */
    function encode_commitment(string memory choice, string memory rand)
    public pure returns (bytes32) {
        return keccak256(abi.encodePacked(choice, rand));
    }

    /*
       Accepts a commitment (generated via encode_commitment)
       and a wager of ethereum
     */
    function play(bytes32 commitment) public payable {
        // must make some wager
        require(msg.value > 0, "must make non-zero wager");

        // Note, wager should probably be high enough cover gas fee of 3rd party that may want to unlock contract after timeout

        // Using wager status to check whether p1 or p2
        if (wager == 0) {
            // P1
            p1_commitment = commitment;
            p1_address = msg.sender;
            wager = msg.value;
        }
        else { // wager != 0
            // P2

            // todo, double-check rollover risk with wager and value

            // must meet or exceed first wager
            require(msg.value >= wager, "must meet or exceed first wager");
            
            if (msg.value > wager) {
                // refund excess wager
                msg.sender.transfer(msg.value - wager);
            }

            p2_commitment = commitment;
            p2_address = msg.sender;

            // Todo, record timestamp of player2 play. This begins the reveal timeout
            p2_end_time = now;
        }
    }

    /*
       Once both players have commited (called play()),
       they reveal their choice and blinding string.
       This function verifies the commitment is correct
       and after both players submit, determines the winner.
     */
    function reveal(string memory choice, string memory rand) public {
        // Only players may reveal
        require(msg.sender == p1_address || msg.sender == p2_address, "must be a player address");
        
        bytes32 expected_commitment = keccak256(abi.encodePacked(choice, rand));

        // Todo eliminate code duplication. Good oportunity for player structs.

        if (msg.sender == p1_address) {
            if (p1_commitment == expected_commitment) {
                // commitments match
                p1_choice = choice_to_enum(choice);
            }
            else { // commitments do not match
                p1_choice = Choice.INVALID;
            }
        }
        else { // player 2
            if (p2_commitment == expected_commitment) {
                // commitments match
                p2_choice = choice_to_enum(choice);
            }
            else { // commitments do not match
                p2_choice = Choice.INVALID;
            }
        }

        /*
        If either player's reveal is invalid,
        then the other player may withdraw winnings.

        Players are allowed to reveal prematurely.

        Either player may withdraw after timeout elapsed since
        their reveal, even if they lost the round.
        Known losers could be excluded from withdraw,
        but that risks locking-up contract.
        */
    }

    // probably don't need to pass player choices, since those are already global, but nice to have pure function
    function determine_winner(Choice p1c, Choice p2c) private pure returns (Winner) {
        // Switch-case statements would be very convient here
        // Would be even better to index into 2D array of outcomes

        Winner[5][5] memory outcomes = [
            // P2   unknown         invalid         rock            paper           scissors  // p1     
            [Winner.UNKNOWN, Winner.UNKNOWN, Winner.UNKNOWN, Winner.UNKNOWN, Winner.UNKNOWN], // unknown
            [Winner.UNKNOWN, Winner.EITHER,  Winner.P2,      Winner.P2,      Winner.P2],      // invalid
            [Winner.UNKNOWN, Winner.P1,      Winner.TIE,     Winner.P2,      Winner.P1],      // rock
            [Winner.UNKNOWN, Winner.P1,      Winner.P1,      Winner.TIE,     Winner.P2],      // paper
            [Winner.UNKNOWN, Winner.P1,      Winner.P2,      Winner.P1,      Winner.TIE]];    // scissors

        return outcomes[uint8(p1c)][uint8(p2c)];
    }

    function reset() private {
        wager = 0;
        //p1_address = 0; // probably not critical to reset addresses
        //p2_address = 0;
        p1_commitment = 0;
        p2_commitment = 0;
        p1_choice = Choice.UNKNOWN;
        p2_choice = Choice.UNKNOWN;
    }
    /*
       After both players reveal, this allows the winner
       to claim their reward (both wagers).
       In the event of a tie, this function should let
       each player withdraw their initial wager.
     */
    function withdraw() public {
        // If anyone is withdrawing past timeout, they get all winnings
        /*
        Timeout counter start time is after P2 sends commitment.
        Todo capture P2 commitment timestamp
        Todo compare to current timestamp
        */
        bool timeout_expired = false; // todo
        
        // timeout expiry logic
        if(now > (p2_end_time + timeout_duration))
            timeout_expired = true;
            

        Winner winner = determine_winner(p1_choice, p2_choice);

        // Not restricting to withdraw by winning sender only.
        // Anyone is welcome to pay the gas to move the game along.
        if (winner == Winner.P1) {
            p1_address.transfer(wager * 2);
            reset();
        }
        else if (winner == Winner.P2) {
            p2_address.transfer(wager * 2);
            reset();
        }
        /*
        If tie, transfer to both accounts.
        No need to wait on second withdraw,
        although this is a bit unfair to make first withdrawer pay extra gas.
        */
        else if (winner == Winner.TIE) {
            p1_address.transfer(wager);
            p2_address.transfer(wager);
            reset();
        }
        else if (winner == Winner.EITHER) {
            // Going to allow anyone to withdraw and reset the contract
            // Could lock this down to either player
            msg.sender.transfer(wager * 2);
            reset();
        }
        // Winner unknown, check for timeout
        else if (timeout_expired) {
            if (p1_choice == Choice.UNKNOWN && p2_choice == Choice.UNKNOWN) {
                // neither player revealed yet
                // allow any 3rd party to collect winnings
                msg.sender.transfer(wager * 2);
                reset();

                // Could alternatively split winnings and / or divert a gas fee to 3rd party.
            }
            else if (p1_choice == Choice.UNKNOWN) {
                // waiting on player 1, so player 2 wins
                p2_address.transfer(wager * 2);
                reset();
            }
            else if (p2_choice == Choice.UNKNOWN) {
                // waiting on player 2, so player 1 wins
                p1_address.transfer(wager * 2);
                reset();
            }
            // This still allows a player with an invalid choice to win if their opponent never revealed
        }

        // Might be nice to allow anyone to force a transfer to winners after the timeout,
        // not sure if anyone is so eager to play that they would donate gas.

        /*
        No need to allow a lonely player_1 to withdraw their funds,
        since they can just play against themselves (assuming they have enough
        remaining funds to match their initial wager).
        */
    }
}
