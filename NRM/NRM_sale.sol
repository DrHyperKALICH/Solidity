pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// Contract for managing a NRM token crowdsale.
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

    function burnTokens(uint tokens) public returns (bool success);

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

    address public beneficiary = 0xb55c9A974513B7D9e53C953305c16527C877C979;
    address public mainContract = 0x00000B233566fcC3825F94D68d4fc410F8cb2300;

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// NRM token crowdsale
// ----------------------------------------------------------------------------

contract NRMsale is Owned {

    using SafeMath for uint;

    mapping(address => bool) whitelist;

    string public name = "NRMsale";
    uint8 public decimals = 18;
    bool public whitelisting = false;
    uint256 saleTokens;
    uint256 public rate = 67500; 
    uint256 public tokensSold = 0;
    uint256 public startTime = 1524225600;
    uint256 public finishTime = 1524657600;

    // -------------------------------------------------------------------------
    // Get the whitelist status for account
    // -------------------------------------------------------------------------
    function isWhite(address ethAddress) public constant returns (bool white) {
        return whitelist[ethAddress];
    }


    // ------------------------------------------------------------------------
    // Add addresses to whitelist
    // ------------------------------------------------------------------------
    function whitelistAdd (address[] users) public onlyOwner returns (uint256) {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = true;
        }
        return(i);
    }


    // ------------------------------------------------------------------------
    // Remove addresses from whitelist
    // ------------------------------------------------------------------------
    function whitelistRem (address[] users) public onlyOwner returns (uint256) {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = false;
        }
        return(i);
    }
    

    // ------------------------------------------------------------------------
    // Enable-disable whitelisting
    // ------------------------------------------------------------------------
    function whiteOnOff () public onlyOwner returns (bool success) {
        if (whitelisting) { whitelisting = false; } else { whitelisting = true; }
        return true;
    }


    // ------------------------------------------------------------------------
    // ETH accepting if tokens for sale available
    // ------------------------------------------------------------------------
    function () public payable {
        require(startTime <= now && finishTime >= now);
        if (whitelisting) { require(whitelist[msg.sender] == true); }
        saleTokens = msg.value.mul(rate);
        require(ERC20Interface(mainContract).transfer(msg.sender, saleTokens));
        require(beneficiary != address(0));
        beneficiary.transfer(msg.value);
        tokensSold = tokensSold.add(saleTokens);
    }


    // ------------------------------------------------------------------------
    // Set/change main contract address
    // ------------------------------------------------------------------------
    function setMainContract(address _mainContract) public onlyOwner returns (bool success) {
        mainContract = _mainContract;
        return true;
    }


    // ------------------------------------------------------------------------
    // Set/change beneficiary
    // ------------------------------------------------------------------------
    function setBeneficiary(address _beneficiary) public onlyOwner returns (bool success) {
        beneficiary = _beneficiary;
        return true;
    }


    // ------------------------------------------------------------------------
    // Set/change rate of sale (ether/token)
    // ------------------------------------------------------------------------
    function setRate(uint256 _rate) public onlyOwner returns (bool success) {
        rate = _rate;
        return true;
    }


    // ------------------------------------------------------------------------
    // Set start and finish time in unix timestamp. https://www.unixtimestamp.com
    // ------------------------------------------------------------------------
    function setTime(uint256 _startTime, uint256 _finishTime) public onlyOwner returns (bool success) {
        startTime = _startTime;
        finishTime = _finishTime;
        tokensSold = 0;
        return true;
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Owner can burn unsold tokens
    // ------------------------------------------------------------------------
    function burnUnsoldTokens() public onlyOwner returns (bool success) {
        uint256 tokensToBurn = ERC20Interface(mainContract).balanceOf(address(this));
        require(ERC20Interface(mainContract).burnTokens(tokensToBurn));
        return true;
    }


    // ------------------------------------------------------------------------
    // Additional withdrawal function
    // ------------------------------------------------------------------------
    function safeWithdrawal() public onlyOwner returns (bool success){
        beneficiary.transfer(address(this).balance);
        return true;
    }
}