pragma solidity ^0.4.18;
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
contract Ownable {
  address public owner;
  function Ownable() {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused {
    require(paused);
    _;
  }
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}
contract PausableToken is StandardToken, Pausable {
  function transfer(address _to, uint _value) whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }
  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}
contract UNLB is PausableToken {
  string public constant name = "UnolaboToken";
  string public constant symbol = "UNLB";
  uint256 public constant decimals = 18;
  function UNLB() {
    owner = msg.sender;
  }
  function mint(address _x, uint _v) public onlyOwner {
    balances[_x] += _v;
    totalSupply += _v;
    Transfer(0x0, _x, _v);
  }
}
contract ICO is Pausable {
  uint public constant ICO_START_DATE =  1511773200;
  uint public constant ICO_END_DATE   =  1525018620;
  address public constant admin      = 0xFeC0714C2eE71a486B679d4A3539FA875715e7d8;
  address public constant teamWallet = 0xf16d5733A31D54e828460AFbf7D60aA803a61C51;
  UNLB public unlb;
  bool public isFinished = false;
  event ForeignBuy(address investor, uint unlbValue, string txHash);
  function ICO() {
    owner = admin;
    unlb = new UNLB();
    unlb.pause();
  }
  function pricePerWei() public constant returns(uint) {
    if     (now <  1511799420) return 800.0 * 1 ether;
    else if(now <  1511885820) return 750.0 * 1 ether;
    else if(now <  1513181820) return 675.0 * 1 ether;
    else if(now <  1515514620) return 575.0 * 1 ether;
    else if(now <  1516205820) return 537.5 * 1 ether;
    else                                                return 500.0 * 1 ether;
  }
  function() public payable {
    require(!paused && now >= ICO_START_DATE && now < ICO_END_DATE);
    uint _tokenVal = (msg.value * pricePerWei()) / 1 ether;
    unlb.mint(msg.sender, _tokenVal);
  }
  function foreignBuy(address _investor, uint _unlbValue, string _txHash) external onlyOwner {
    require(!paused && now >= ICO_START_DATE && now < ICO_END_DATE);
    require(_unlbValue > 0);
    unlb.mint(_investor, _unlbValue);
    ForeignBuy(_investor, _unlbValue, _txHash);
  }
  function finish(address _team, address _fund, address _bounty, address _backers) external onlyOwner {
    require(now >= ICO_END_DATE && !isFinished);
    unlb.unpause();
    isFinished = true;
    uint _total = unlb.totalSupply() * 100 / (100 - 12 - 15 - 5 - 3);
    unlb.mint(_team,   (_total * 12) / 100);
    unlb.mint(_fund,   (_total * 15) / 100);
    unlb.mint(_bounty, (_total *  5) / 100);
    unlb.mint(_backers, (_total *  3) / 100);
  }
  function withdraw() external onlyOwner {
    teamWallet.transfer(this.balance);
  }
}