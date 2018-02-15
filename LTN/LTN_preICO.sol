pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Contract for managing a LTN preICO token crowdsale.
// 2018 (c) Sergey Kalich
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe math - only used functions
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Owned contract
// beneficiary - owner's multi signature wallet
// ----------------------------------------------------------------------------

contract Owned {
    address public owner;
    address public newOwner;
    address public beneficiary; // = 0x404c832bbed4e54139bc3c7c543527f0ff97592f;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
      owner = msg.sender;
    }
  
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// Connection to sale function of main token contract
// ----------------------------------------------------------------------------

contract MAIN {
   function sale(address to, uint tokens) public returns (bool);
}


// ----------------------------------------------------------------------------
// LTN preICO token crowdsale
// ----------------------------------------------------------------------------

contract LTNpreICO is Owned {

    using SafeMath for uint;

    address public token = 0x473758E6b83F2c050b2ba4bE3E43F4b4fB7d7c0f;

    string public name = "LybertyLance preICO";
    uint8 public decimals = 18;
    uint256 saleTokens;
    uint256 public rate = 7500; // 6250 + 20% bonus
    uint256 public tokensForSale = 600000 * 10**uint(decimals);
    uint256 public tokensSold = 0;
    uint256 public startTime = now;
    uint256 public finishTime = now + 7 days;


// ----------------------------------------------------------------------------
// ETH accepting only at preICO running, only in tokens for sale available
// ----------------------------------------------------------------------------
    function () public payable {
        require(startTime <= now && finishTime >= now);
        saleTokens = msg.value.mul(rate);
        require(tokensSold.add(saleTokens) <= tokensForSale);
        MAIN token_contract = MAIN(token);
        token_contract.sale(msg.sender, saleTokens);
        require(beneficiary != address(0));
        beneficiary.transfer(msg.value);
        tokensSold = tokensSold.add(saleTokens);
    }


// ----------------------------------------------------------------------------
// Set/change main contract address
// ----------------------------------------------------------------------------
    function setToken(address _token) public onlyOwner returns (bool success) {
        token = _token;
        return true;
    }

// ----------------------------------------------------------------------------
// Set/change beneficiary
// ----------------------------------------------------------------------------
    function setBeneficiary(address _beneficiary) public onlyOwner returns (bool success) {
        beneficiary = _beneficiary;
        return true;
    }


// ----------------------------------------------------------------------------
// Set/change rate of sale (ether/token)
// ----------------------------------------------------------------------------
    function setRate(uint256 _rate) public onlyOwner returns (bool success) {
        rate = _rate;
        return true;
    }


// ----------------------------------------------------------------------------
// Set start and finish time in unix timestamp. https://www.unixtimestamp.com
// ----------------------------------------------------------------------------
    function setTime(uint256 _startTime, uint256 _finishTime) public onlyOwner returns (bool success) {
        startTime = _startTime;
        finishTime = _finishTime;
        return true;
    }


// ------------------------------------------------------------------------
// Owner can transfer out any accidentally sent ERC20 tokens
// ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


// ------------------------------------------------------------------------
// Additional withdrawal function
// ------------------------------------------------------------------------
    function safeWithdrawal() public onlyOwner returns (bool success){
        beneficiary.transfer(this.balance);
        return true;
    }
}