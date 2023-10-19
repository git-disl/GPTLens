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
contract AURA is SafeMath, Owned {
    bool public locked = true;
    string public name = "Aurora DAO";
    string public symbol = "AURA";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    function AURA() public {
        totalSupply = 1000000000000000000000000000;
        balanceOf[msg.sender] = totalSupply;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(!locked || msg.sender == owner);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        require(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(!locked);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    function unlockToken() onlyOwner {
      locked = false;
    }
    bool public balancesUploaded = false;
    function uploadBalances(address[] recipients, uint256[] balances) onlyOwner {
      require(!balancesUploaded);
      uint256 sum = 0;
      for (uint256 i = 0; i < recipients.length; i++) {
        balanceOf[recipients[i]] = safeAdd(balanceOf[recipients[i]], balances[i]);
        sum = safeAdd(sum, balances[i]);
      }
      balanceOf[owner] = safeSub(balanceOf[owner], sum);
    }
    function lockBalances() onlyOwner {
      balancesUploaded = true;
    }
}