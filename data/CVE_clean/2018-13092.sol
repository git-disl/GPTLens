pragma solidity ^0.4.18;
contract owned {
    address public owner;
    function owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract ReimburseToken is owned{
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function ReimburseToken(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = "Reimburse Token"; 
        symbol = "REIM";
        decimals = 18;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOf[_owner];
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}
contract AdvReimburseToken is owned, ReimburseToken {
    function AdvReimburseToken(
        uint256 initialSupply
    ) ReimburseToken(initialSupply) public {}
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value);               
        require (balanceOf[_to] + _value > balanceOf[_to]); 
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;                           
        Transfer(_from, _to, _value);
    }
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
}