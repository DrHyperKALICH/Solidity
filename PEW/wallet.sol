pragma solidity 0.4.24;

// ----------------------------------------------------------------------------
// Personal Ethereum Wallet
//
// 2018 (c) Sergey Kalich
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Modified ERC Interface
// ----------------------------------------------------------------------------
contract ERCInterface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Deposit(address indexed _from, uint _value);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
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
// Personal Ethereum Wallet
// ----------------------------------------------------------------------------
contract PEW is ERCInterface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;

    constructor() public {
        symbol = "PEW";
        name = "Personal Ethereum Wallet";
        decimals = 18;
        _totalSupply = 0;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint amount) public onlyOwner returns (bool success) {
        require(amount <= balances[msg.sender]);
        require(amount != 0);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        _totalSupply = _totalSupply.sub(amount);
        to.transfer(amount);
        return true;
    }
    
    function multitransfer(address[] to, uint[] amount) public onlyOwner returns (uint) {
        for (uint256 i = 0; i < to.length; i++) {
            require(amount[i] <= balances[msg.sender]);
            require(amount[i] != 0);
            balances[msg.sender] = balances[msg.sender].sub(amount[i]);
            emit Transfer(msg.sender, address(0), amount[i]);
            to[i].transfer(amount[i]);
        }
        return(i);
    }
    
    function () public payable {
        emit Deposit(msg.sender, msg.value);
        balances[owner] = balances[owner].add(msg.value);
        emit Transfer(address(0), owner, msg.value);
        _totalSupply = _totalSupply.add(msg.value);
    }
    
     function withdraw() public onlyOwner returns (bool success) {
        owner.transfer(address(this).balance);
        return true;
    }    

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERCInterface(tokenAddress).transfer(owner, tokens);
    }
}
