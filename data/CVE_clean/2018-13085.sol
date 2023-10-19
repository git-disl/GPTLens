pragma solidity ^0.4.16;
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
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint public free = 100 * 10 ** uint256(decimals);
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public created;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    function changeFree(uint newFree) public {
        free = newFree;
    }
    function balanceOf(address _owner) public constant returns (uint balance) {
		if (!created[_owner] && balances[_owner] == 0) {
			return free;
		}
		else
		{
			return balances[_owner];
		}
	}
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balances[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;                               
   		created[msg.sender] = true;
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        if (!created[_from]) {
			balances[_from] = free;
			created[_from] = true;
		}
        if (!created[_to]) {
			created[_to] = true;
		}
        require(balances[_from] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);
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
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
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
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] -= _value;            
        totalSupply -= _value;                      
        emit Burn(msg.sender, _value);
        return true;
    }
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balances[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        emit Burn(_from, _value);
        return true;
    }
}
contract FreeCoin is owned, TokenERC20 {
    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    function FreeCoin(
        uint256 initialSupply,
        string tokenName ,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function buy() payable public {
        uint amount = msg.value / buyPrice;               
        _transfer(this, msg.sender, amount);              
    }
    function sell(uint256 amount) public {
        require(address(this).balance >= amount * sellPrice);      
        _transfer(msg.sender, this, amount);              
        msg.sender.transfer(amount * sellPrice);          
    }
}