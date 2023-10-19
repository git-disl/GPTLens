pragma solidity ^0.4.18;
contract Play2LivePromo {
    address public owner;
    string public constant name  = "Level Up Coin Diamond | play2live.io";
    string public constant symbol = "LUCD";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0; 
    uint256 promoValue = 777 * 1e18;
    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;
    event Transfer(address _from, address _to, uint256 amount); 
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }  
    function Play2LivePromo() {
        owner = msg.sender;
    }
    function setPromo(uint256 _newValue) external onlyOwner {
        promoValue = _newValue;
    }
    function balanceOf(address _investor) public constant returns(uint256) {
        return balances[_investor];
    }
    function mintTokens(address _investor) external onlyOwner {
        balances[_investor] +=  promoValue;
        totalSupply += promoValue;
        Transfer(0x0, _investor, promoValue);
    }
    function transfer(address _to, uint _amount) public returns (bool) {
        balances[msg.sender] -= _amount;
        balances[_to] -= _amount;
        Transfer(msg.sender, _to, _amount);
        return true;
    }
    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] -= _amount;
        Transfer(_from, _to, _amount);
        return true;
     }
    function approve(address _spender, uint _amount) public returns (bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint) {
        return allowed[_owner][_spender];
    }
}