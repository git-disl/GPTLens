pragma solidity ^0.4.19;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract SafeMath {
  function safeMul(uint256 a, uint256 b) returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint256 a, uint256 b) returns (uint256) {
    require(b <= a);
    return a - b;
  }
  function safeAdd(uint256 a, uint256 b) returns (uint256) {
    uint c = a + b;
    require(c >= a && c >= b);
    return c;
  }
}
contract Owned {
  address public owner;
  function Owned() {
    owner = msg.sender;
  }
  function setOwner(address _owner) returns (bool success) {
    owner = _owner;
    return true;
  }
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}
contract IDXM is Owned, SafeMath {
  uint8 public decimals = 8;
  bytes32 public standard = 'Token 0.1';
  bytes32 public name = 'IDEX Membership';
  bytes32 public symbol = 'IDXM';
  uint256 public totalSupply;
  event Approval(address indexed from, address indexed spender, uint256 amount);
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  event Transfer(address indexed from, address indexed to, uint256 value);
  uint256 public baseFeeDivisor;
  uint256 public feeDivisor;
  uint256 public singleIDXMQty;
  function () external {
    throw;
  }
  uint8 public feeDecimals = 8;
  struct Validity {
    uint256 last;
    uint256 ts;
  }
  mapping (address => Validity) public validAfter;
  uint256 public mustHoldFor = 604800;
  mapping (address => uint256) public exportFee;
  function IDXM() {
    totalSupply = 200000000000;
    balanceOf[msg.sender] = totalSupply;
    exportFee[0x00000000000000000000000000000000000000ff] = 100000000;
    precalculate();
  }
  bool public balancesLocked = false;
  function uploadBalances(address[] addresses, uint256[] balances) onlyOwner {
    require(!balancesLocked);
    require(addresses.length == balances.length);
    uint256 sum;
    for (uint256 i = 0; i < uint256(addresses.length); i++) {
      sum = safeAdd(sum, safeSub(balances[i], balanceOf[addresses[i]]));
      balanceOf[addresses[i]] = balances[i];
    }
    balanceOf[owner] = safeSub(balanceOf[owner], sum);
  }
  function lockBalances() onlyOwner {
    balancesLocked = true;
  }
  function transfer(address _to, uint256 _amount) returns (bool success) {
    require(!locked);
    require(balanceOf[msg.sender] >= _amount);
    require(balanceOf[_to] + _amount >= balanceOf[_to]);
    balanceOf[msg.sender] -= _amount;
    uint256 preBalance = balanceOf[_to];
    balanceOf[_to] += _amount;
    bool alreadyMax = preBalance >= singleIDXMQty;
    if (!alreadyMax) {
      if (now >= validAfter[_to].ts + mustHoldFor) validAfter[_to].last = preBalance;
      validAfter[_to].ts = now;
    }
    if (validAfter[msg.sender].last > balanceOf[msg.sender]) validAfter[msg.sender].last = balanceOf[msg.sender];
    Transfer(msg.sender, _to, _amount);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
    require(!locked);
    require(balanceOf[_from] >= _amount);
    require(balanceOf[_to] + _amount >= balanceOf[_to]);
    require(_amount <= allowance[_from][msg.sender]);
    balanceOf[_from] -= _amount;
    uint256 preBalance = balanceOf[_to];
    balanceOf[_to] += _amount;
    allowance[_from][msg.sender] -= _amount;
    bool alreadyMax = preBalance >= singleIDXMQty;
    if (!alreadyMax) {
      if (now >= validAfter[_to].ts + mustHoldFor) validAfter[_to].last = preBalance;
      validAfter[_to].ts = now;
    }
    if (validAfter[_from].last > balanceOf[_from]) validAfter[_from].last = balanceOf[_from];
    Transfer(_from, _to, _amount);
    return true;
  }
  function approveAndCall(address _spender, uint256 _amount, bytes _extraData) returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _amount)) {
      spender.receiveApproval(msg.sender, _amount, this, _extraData);
      return true;
    }
  }
  function approve(address _spender, uint256 _amount) returns (bool success) {
    require(!locked);
    allowance[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }
  function setExportFee(address addr, uint256 fee) onlyOwner {
    require(addr != 0x00000000000000000000000000000000000000ff);
    exportFee[addr] = fee;
  }
  function setHoldingPeriod(uint256 ts) onlyOwner {
    mustHoldFor = ts;
  }
  function feeFor(address from, address to, uint256 amount) constant external returns (uint256 value) {
    uint256 fee = exportFee[from];
    if (fee == 0) return 0;
    uint256 amountHeld;
    if (balanceOf[to] != 0) {
      if (validAfter[to].ts + mustHoldFor < now) amountHeld = balanceOf[to];
      else amountHeld = validAfter[to].last;
      if (amountHeld >= singleIDXMQty) return 0;
      return amount*fee*(singleIDXMQty - amountHeld) / feeDivisor;
    } else return amount*fee / baseFeeDivisor;
  }
  bool public locked = true;
  function unlockToken() onlyOwner {
    locked = false;
  }
  function precalculate() internal returns (bool success) {
    baseFeeDivisor = pow10(1, feeDecimals);
    feeDivisor = pow10(1, feeDecimals + decimals);
    singleIDXMQty = pow10(1, decimals);
  }
  function div10(uint256 a, uint8 b) internal returns (uint256 result) {
    for (uint8 i = 0; i < b; i++) {
      a /= 10;
    }
    return a;
  }
  function pow10(uint256 a, uint8 b) internal returns (uint256 result) {
    for (uint8 i = 0; i < b; i++) {
      a *= 10;
    }
    return a;
  }
}