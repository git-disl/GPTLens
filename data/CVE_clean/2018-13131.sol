pragma solidity ^0.4.19;
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
contract DSPXToken is StandardToken {
  string public constant name = "SP8DE PreSale Token";
  string public constant symbol = "DSPX";
  uint8 public constant decimals = 18;
  address public preSale;
  address public team;
  bool public isFrozen = true;  
  uint public constant TOKEN_LIMIT = 888888888 * (1e18);
  function DSPXToken(address _preSale, address _team) {
      require(_preSale != address(0));
      require(_team != address(0));
      preSale = _preSale;
      team = _team;
  }
  function mint(address holder, uint value) {
    require(msg.sender == preSale);
    require(value > 0);
    require(totalSupply + value <= TOKEN_LIMIT);
    balances[holder] += value;
    totalSupply += value;
    Transfer(0x0, holder, value);
  }
  function unfreeze() external {
      require(msg.sender == team);
      isFrozen = false;
  }
  function transfer(address _to, uint _value) public returns (bool) {
      require(!isFrozen);
      return super.transfer(_to, _value);
  }
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
      require(!isFrozen);
      return super.transferFrom(_from, _to, _value);
  }
  function approve(address _spender, uint _value) public returns (bool) {
      require(!isFrozen);
      return super.approve(_spender, _value);
  }
}
contract SpadePreSale {
  DSPXToken public token;
  address public team;
  address public icoAgent;
  modifier teamOnly {require(msg.sender == team); _;}
  modifier icoAgentOnly {require(msg.sender == icoAgent); _;}
  bool public isPaused = false;
  enum PreSaleState { Created, PreSaleStarted, PreSaleFinished }
  PreSaleState public preSaleState = PreSaleState.Created;
  event PreSaleStarted();
  event PreSaleFinished();
  event PreSalePaused();
  event PreSaleResumed();
  event TokenBuy(address indexed buyer, uint256 tokens, uint factor, string tx);
  function SpadePreSale(address _team, address _icoAgent) public {
    require(_team != address(0));
    require(_icoAgent != address(0));
    team = _team;
    icoAgent = _icoAgent;
    token = new DSPXToken(this, team);
  }
  function startPreSale() external teamOnly {
    require(preSaleState == PreSaleState.Created);
    preSaleState = PreSaleState.PreSaleStarted;
    PreSaleStarted();
  }
  function pausePreSale() external teamOnly {
    require(!isPaused);
    require(preSaleState == PreSaleState.PreSaleStarted);
    isPaused = true;
    PreSalePaused();
  }
  function resumePreSale() external teamOnly {
    require(isPaused);
    require(preSaleState == PreSaleState.PreSaleStarted);
    isPaused = false;
    PreSaleResumed();
  }
  function finishPreSale() external teamOnly {
    require(preSaleState == PreSaleState.PreSaleStarted);
    preSaleState = PreSaleState.PreSaleFinished;
    PreSaleFinished();
  }
  function buyPreSaleTokens(address buyer, uint256 tokens, uint factor, string txHash) external icoAgentOnly returns (uint) {
    require(buyer != address(0));
    require(tokens > 0);
    require(preSaleState == PreSaleState.PreSaleStarted);
    require(!isPaused);
    token.mint(buyer, tokens);
    TokenBuy(buyer, tokens, factor, txHash);
  }
}