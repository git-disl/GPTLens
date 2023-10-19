pragma solidity ^0.4.14;
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);
  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract StandardToken is ERC20, SafeMath {
  event Minted(address receiver, uint amount);
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  function isToken() public constant returns (bool weAre) {
    return true;
  }
  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  function approve(address _spender, uint _value) returns (bool success) {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}
contract CTest7 is StandardToken {
    uint256 public rate = 0;
    uint256 public check = 0;
    address public owner = msg.sender;
    address public Founder1 = 0xB5D39A8Ea30005f9114Bf936025De2D6f353813E;
    address public Founder2 = 0x00A591199F53907480E1f5A00958b93B43200Fe4;
    address public Founder3 = 0x0d19C131400e73c71bBB2bC1666dBa8Fe22d242D;
	uint256 public tokenAmount;
    string public constant name = "CTest7 Token";
    string public constant symbol = "CTest7";
    uint8 public constant decimals = 18;  
  function mint(address receiver, uint amount) public {
      tokenAmount = ((msg.value*rate)/(1 ether));
    if (tokenAmount != amount || amount == 0 || receiver != msg.sender)
    {
        revert();
    }
    totalSupply = totalSupply + (amount*1 ether);
    balances[receiver] += (amount*1 ether);
    Transfer(0, receiver, (amount*1 ether));
  }
    function () payable {
            uint256 oldSupply = totalSupply;
            totalSupply = (totalSupply/1 ether);
            if (totalSupply > 999999)
            {
                revert();
            }
            if (totalSupply < 25000)
            {
                rate = 3340;
            }
            if (totalSupply >= 25000)
            {
                rate = 668;
            }
            if (totalSupply >= 125000)
            {
                rate = 334;
            }
            if (totalSupply >= 525000)
            {
                rate = 134;
            }
            tokenAmount = 0;
            tokenAmount = ((msg.value*rate)/(1 ether));
            if (tokenAmount < 0)
            {
                revert();
            }
            check = 0;
            check = safeAdd(totalSupply, tokenAmount);
            if (check > 1000000)
            {
                revert();
            }
            if (totalSupply < 25000 && check > 25000)
            {
                revert();
            }
            if (totalSupply < 125000 && check > 125000)
            {
                revert();
            }
            if (totalSupply < 525000 && check > 525000)
            {
                revert();
            }
            uint256 senderBalance = (balances[msg.sender]/1 ether);
            if ((senderBalance + tokenAmount) > 50 && totalSupply < 25000)
            {
                revert();
            }
            totalSupply = oldSupply;
        	mint(msg.sender, tokenAmount);
        	tokenAmount = 0;							
        	check = 0;
        	rate = 0;
        	Founder1.transfer((msg.value/3));					
        	Founder2.transfer((msg.value/3));					
        	Founder3.transfer((msg.value/3));					
    }
    function Burn () {
        if (msg.sender == owner && totalSupply < 1000000)
        {
            totalSupply = 1000000;
        } else {throw;}
    }
}