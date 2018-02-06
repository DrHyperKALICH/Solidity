pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// T13 Pre-ICO && ICO token contract
//
// Symbol      : T13
// Name        : T13 token contract
// Total supply: 10,000,000,000.000000000000000000 (burnable)
// Decimals    : 18
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
// T13 ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract T13 is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals = 18;
    uint public _totalSupply;

    address public saleAddress;
    address distributionAddr = 0;
    address fcwallet = 0xF162124017d015376B368aFFfcE6e992D39Dd5A3;

    address a4closedPreICO =     0xF162124017d015376B368aFFfcE6e992D39Dd5A3;
    address a4PreICO =           0xF162124017d015376B368aFFfcE6e992D39Dd5A3;
    // address a4ICO =           owner;
    address a4freezeTeam =       0x5555555555555555555555555555555555555555;
    address a4freezeDevelop =    0x7777777777777777777777777777777777777777;
    address a4bonus =            0xF162124017d015376B368aFFfcE6e992D39Dd5A3;
    address a4advisors =         0xF162124017d015376B368aFFfcE6e992D39Dd5A3;

    // Tokens for convert NRMc to NRM
    uint tokens4closedPreICO =  50000000 * 10**uint(decimals);
    // Tokens for pre-ICO
    uint tokens4PreICO =        600000000 * 10**uint(decimals);
    // Tokens for ICO
    uint tokens4ICO =           5400000000 * 10**uint(decimals);
    // Tokens for team (freezed for 1 year)
    uint tokens4freezeTeam =    1500000000 * 10**uint(decimals);
    // Tokens for future development (freezed for 1 year)
    uint tokens4freezeDevelop = 1500000000 * 10**uint(decimals);
    // Tokens for bonuses
    uint tokens4bonus =         500000000 * 10**uint(decimals);
    // Tokens for advisors
    uint tokens4advisors =      500000000 * 10**uint(decimals);

    bool startDone = false;
    uint tier0 = 0;
    uint tier1 = 0;
    uint tier2 = 0;
    uint tier3 = 0;
    uint tier4 = 0;
    uint tier5 = 0;
    uint tier6 = 0;

    uint tier01rate = 67500;
    uint tier23rate = 54000;
    uint tier34rate = 49500;
    uint tier45rate = 45000;

    uint rate = 0;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function T13() public {
        symbol = "T13";
        name = "T13 Token";
        decimals = 18;
        _totalSupply = 10000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);

        balances[owner] = balances[owner].sub(tokens4closedPreICO);
        balances[a4closedPreICO] = balances[a4closedPreICO].add(tokens4closedPreICO);
        Transfer(owner, a4closedPreICO, tokens4closedPreICO);

        balances[owner] = balances[owner].sub(tokens4PreICO);
        balances[a4PreICO] = balances[a4PreICO].add(tokens4PreICO);
        Transfer(owner, a4PreICO, tokens4PreICO);

        balances[owner] = balances[owner].sub(tokens4freezeTeam);
        balances[a4freezeTeam] = balances[a4freezeTeam].add(tokens4freezeTeam);
        Transfer(owner, a4freezeTeam, tokens4freezeTeam);

        balances[owner] = balances[owner].sub(tokens4freezeDevelop);
        balances[a4freezeDevelop] = balances[a4freezeDevelop].add(tokens4freezeDevelop);
        Transfer(owner, a4freezeDevelop, tokens4freezeDevelop);

        balances[owner] = balances[owner].sub(tokens4bonus);
        balances[a4bonus] = balances[a4bonus].add(tokens4bonus);
        Transfer(owner, a4bonus, tokens4bonus);

        balances[owner] = balances[owner].sub(tokens4advisors);
        balances[a4advisors] = balances[a4advisors].add(tokens4advisors);
        Transfer(owner, a4advisors, tokens4advisors);
    }

    // ------------------------------------------------------------------------
    // Start
    // ------------------------------------------------------------------------
    function start(uint256 startInMinutes) public onlyOwner returns (bool success) {

        require(!startDone);
        
        // pre ICO start time
        tier0 = now + startInMinutes * 1 minutes;
        
        // pre-ICO end time after 7 days
        tier1 = tier0 + 30 * 1 minutes; 
        
        // ICO start time after 3 days break
        tier2 = tier1 + 30 * 1 minutes; 
        
        // ICO bonus +20% first 7 days ends
        tier3 = tier2 + 30 * 1 minutes; 
        
        // ICO bonus +10% second 7 days ends
        tier4 = tier3 + 30 * 1 minutes;

        // ICO end time
        tier5 = tier4 + 30 * 1 minutes;

        // Unfreeze time
        tier6 = now + 365 * 1 days;

        // |tier0|-----------|tier1|---------|tier2|-------------|tier3|-------------|tier4|-------------|tier5|
        //        pre-ICO(7d)       break(3d)       bonus+20%(7d)       bonus+10%(7d)       no-bonus(14d)

        startDone = true;
        return true;
    }


    // ------------------------------------------------------------------------
    // Unfreeze tokens for team in 1 year
    // ------------------------------------------------------------------------

    function unfreezeTeam(address teamTokens) public onlyOwner returns (bool success) {
        require(now >= tier6);
        balances[a4freezeTeam] = balances[a4freezeTeam].sub(tokens4freezeTeam);
        balances[teamTokens] = balances[teamTokens].add(tokens4freezeTeam);
        Transfer(a4freezeTeam, teamTokens, tokens4freezeTeam);
        return true;
    }


    // ------------------------------------------------------------------------
    // Unfreeze tokens for development in 1 year
    // ------------------------------------------------------------------------

    function unfreezeDevelop(address developTokens) public onlyOwner returns (bool success) {
        require(now >= tier6);
        balances[a4freezeDevelop] = balances[a4freezeDevelop].sub(tokens4freezeDevelop);
        balances[developTokens] = balances[developTokens].add(tokens4freezeDevelop);
        Transfer(a4freezeDevelop, developTokens, tokens4freezeDevelop);
        return true;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
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
    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
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
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        require(tokens != 0);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
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
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Tokens multisend ["A","B","C"],["D","E","F"],[2,4,8]
    // ------------------------------------------------------------------------
    function multisend(address[] from, address[] to, uint256[] values) public onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < to.length) {
            balances[from[i]] = balances[from[i]].sub(values[i]);
            balances[to[i]] = balances[to[i]].add(values[i]);
            Transfer(from[i], to[i], values[i]);
            i += 1;
        }
        return(i);
    }

    // ------------------------------------------------------------------------
    // Closed pre-ICO tokens distribution "O",["A","B","C"],[2,4,8]
    // ------------------------------------------------------------------------
    function distribution(address _tokenAddr, address[] to, uint256[] values) public onlyOwner returns (uint256) {
        uint256 i = 0;
        while (i < to.length) {
            balances[_tokenAddr] = balances[_tokenAddr].sub(values[i]);
            balances[to[i]] = balances[to[i]].add(values[i]);
            Transfer(_tokenAddr, to[i], values[i]);
            i += 1;
        }
        return(i);
    }


    // ------------------------------------------------------------------------
    // ETH accepting
    // ------------------------------------------------------------------------
    function () public payable {

        require(startDone);

               if (now > tier0 && now < tier1) {    rate = tier01rate;
        } else if (now > tier2 && now < tier3) {    rate = tier23rate;
        } else if (now > tier3 && now < tier4) {    rate = tier34rate;
        } else if (now > tier4 && now < tier5) {    rate = tier45rate;
        } else { revert(); }

        if (now > tier0 && now < tier1) { distributionAddr = a4PreICO;
        } else { distributionAddr = owner; }

        uint256 tokens = msg.value.mul(rate);
        require(tokens <= balances[distributionAddr]);
        
        balances[distributionAddr] = balances[distributionAddr].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        Transfer(distributionAddr, msg.sender, tokens);
        forwardFunds();
    } 

    // ------------------------------------------------------------------------
    // Send ether to the fund collection wallet
    // ------------------------------------------------------------------------

    function forwardFunds() internal {
        fcwallet.transfer(msg.value);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


    // ------------------------------------------------------------------------
    // Tokens burn for Owner
    // ------------------------------------------------------------------------
    function burnTokensOwner(address burn, uint256 tokens) public onlyOwner returns (bool success) {
        require(tokens <= balances[burn]);
        require(tokens != 0);
        balances[burn] = balances[burn].sub(tokens);
        balances[address(0)] = balances[address(0)].add(tokens);
        Transfer(burn, address(0), tokens);
        return true;
    }    


    // ------------------------------------------------------------------------
    // Tokens burn for everyone
    // ------------------------------------------------------------------------
    function burnTokens(uint256 tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[address(0)] = balances[address(0)].add(tokens);
        Transfer(msg.sender, address(0), tokens);
        return true;
    }    


    // ------------------------------------------------------------------------
    // Contract ETH withdrawal
    // ------------------------------------------------------------------------
    function safeWithdrawal() public onlyOwner {
        fcwallet.transfer(this.balance);
    }


    // ------------------------------------------------------------------------
    // SALE from external contract
    // ------------------------------------------------------------------------

    modifier onlySaleConract(){
        require(msg.sender == saleAddress);
        _;
    }

    function setSaleAddress(address newSaleAddress) public onlyOwner returns (bool) {
        require(newSaleAddress != 0x0);
        saleAddress = newSaleAddress;
        return true;
    }

    function sale(address from, address to, uint tokens) external onlySaleConract returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens != 0);
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    
    // ------------------------------------------------------------------------
    // Contract suicide
    // ------------------------------------------------------------------------
    function killContract() public onlyOwner {
    selfdestruct(owner);
    }

}

// mapping (address => uint256) public deposited;

// test addresses
// 0x0dEEE267Fe6259b0b291dDaF6d4682aE21302F4F
// 0xF162124017d015376B368aFFfcE6e992D39Dd5A3
// 0x6253F2D3603e261Fb8Dafc956819552639060118
// 0xE0dD9065d6eecA96a7B3Fd7fBa4e6eBF26BFb9FB
// 0x670BbC85b2a596b3D000Ede398978C971a4bA548

