pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// LKT token - token with mining by transfer
//
// Symbol       : LKT
// Name         : LKT token
// Total supply : variable-burnable
// Decimals     : 18
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
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// LKT ERC20 Token 
// ----------------------------------------------------------------------------
contract LKT is ERC20Interface, Owned {
    using SafeMath for uint;

    bool public running = true;
    bool public mining = true;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;
    uint saleTokens;
    uint luckTokens;
    uint public luck;
    uint public luckThreshold = 500;
    uint public saleRate = 10000;
    uint public startTime;
    uint public finishTime;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Contract init. Set symbol, name, decimals and initial supply
    // ------------------------------------------------------------------------
    function LKT() public {
        symbol = "LKT";
        name = "LKT token";
        decimals = 18;
        _totalSupply = 0;
    }


    // ------------------------------------------------------------------------
    // Start-stop contract functions:
    // transfer, approve, transferFrom, approveAndCall
    // ------------------------------------------------------------------------

    modifier isRunnning {
        require(running);
        _;
    }

    function startStopContract () public onlyOwner returns (bool success) {
        if (running) { running = false; } else { running = true; }
        return true;
    }

    // ------------------------------------------------------------------------
    // Start-stop token mining
    // ------------------------------------------------------------------------

    modifier isMining {
        require(mining);
        _;
    }

    function startStopMining () public onlyOwner returns (bool success) {
        if (mining) { mining = false; } else { mining = true; }
        return true;
    }

    // ----------------------------------------------------------------------------
    // ETH accepting
    // ----------------------------------------------------------------------------
    function () public payable {
        //require(startTime <= now && finishTime >= now);
        saleTokens = msg.value.mul(saleRate);
        _totalSupply = _totalSupply.add(saleTokens);
        balances[msg.sender] = balances[msg.sender].add(saleTokens);
        Transfer(address(0), msg.sender, saleTokens);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        getLuckyTokens(msg.sender);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        require(tokens != 0);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        getLuckyTokens(msg.sender);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // ------------------------------------------------------------------------
    // Luck 
    // ------------------------------------------------------------------------
    function getLuck() internal returns (uint) {
    luck = uint(sha256(block.timestamp))%1000 + uint(sha256(block.difficulty))%1000;
    return luck;
    }

    function getLuckyTokens(address from) internal {
    if (mining) {
        getLuck();
        if (luck < luckThreshold) { 
            luckTokens = luck * 10**uint(decimals); 
        } else {
            luckTokens = 0;
            address temp = from;
        }
        _totalSupply = _totalSupply.add(luckTokens);
        balances[from] = balances[from].add(luckTokens);
        Transfer(address(0), from, luckTokens);
        } 
    }

    // ----------------------------------------------------------------------------
    // Set luck threshold
    // ----------------------------------------------------------------------------
    function setThreshold(uint256 threshold) public onlyOwner returns (bool success) {
        require(threshold <= 999);
        luckThreshold = threshold;
        return true;
    }

    // ----------------------------------------------------------------------------
    // Set rate of sale (ether/token)
    // ----------------------------------------------------------------------------
    function setRate(uint256 rate) public onlyOwner returns (bool success) {
        saleRate = rate;
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
    // Tokens burn
    // ------------------------------------------------------------------------
    function burnTokens(uint256 tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        Transfer(msg.sender, address(0), tokens);
        return true;
    }    


    // ------------------------------------------------------------------------
    // Tokens distribution by owner
    // ------------------------------------------------------------------------
    function distribution(address[] to, uint256[] values) public onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < to.length) {
            _totalSupply = _totalSupply.add(values[i]);
            balances[to[i]] = balances[to[i]].add(values[i]);
            Transfer(address(0), to[i], values[i]);
            i += 1;
        }
        return(i);
    }

    // ------------------------------------------------------------------------
    // Safe withdrawal function
    // ------------------------------------------------------------------------
    function safeWithdrawal() public onlyOwner {
        owner.transfer(this.balance);
    }
}
