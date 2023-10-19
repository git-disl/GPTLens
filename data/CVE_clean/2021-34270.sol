pragma solidity ^0.4.13;
contract owned { 
    address public owner;
    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}
contract doftManaged { 
    address public doftManager;
    function doftManaged() {
        doftManager = msg.sender;
    }
    modifier onlyDoftManager {
        require(msg.sender == doftManager);
        _;
    }
    function transferDoftManagment(address newDoftManager) onlyDoftManager {
        doftManager = newDoftManager;
    }
}
contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract BasicToken is ERC20 { 
    uint256 _totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    function totalSupply() constant returns (uint totalSupply){
	totalSupply = _totalSupply;
    }
    function balanceOf(address _owner) constant returns (uint balance){
        return balanceOf[_owner];
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] > _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]); 
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;                           
        Transfer(_from, _to, _value);
    }
    function transfer(address _to, uint _value) returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        require (_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowance[_owner][_spender];
    }
}
contract Doftcoin is BasicToken, owned, doftManaged { 
    string public name; 
    string public symbol; 
    uint256 public decimals; 
    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public miningStorage;
    string public version; 
    event Mine(address target, uint256 minedAmount);
    function Doftcoin() {
        decimals = 18;
        _totalSupply = 5000000 * (10 ** decimals);  
        miningStorage = _totalSupply / 2;
        name = "Doftcoin";                                   
        symbol = "DFC";                               
        balanceOf[msg.sender] = _totalSupply;              
	version = "1.0";
    }
    function mintToken(address _target, uint256 _mintedAmount) onlyOwner {
        require (_target != 0x0);
        balanceOf[_target] += _mintedAmount;
        _totalSupply += _mintedAmount;
        Transfer(0, this, _mintedAmount);
        Transfer(this, _target, _mintedAmount);
    }
    function buy() payable {
	    require(buyPrice > 0);
        uint amount = msg.value / buyPrice;               
        _transfer(this, msg.sender, amount);              
    }
    function sell(uint256 _amount) {
	    require(sellPrice > 0);
        require(this.balance >= _amount * sellPrice);      
        _transfer(msg.sender, this, _amount);              
        msg.sender.transfer(_amount * sellPrice);          
    }
    function setPrices(uint256 _newSellPrice, uint256 _newBuyPrice) onlyDoftManager {
        sellPrice = _newSellPrice;
        buyPrice = _newBuyPrice;
    }
    function mine(address _target, uint256 _minedAmount) onlyDoftManager {
	require (_minedAmount > 0);
        require (_target != 0x0);
        require (miningStorage - _minedAmount >= 0);
        require (balanceOf[doftManager] >= _minedAmount);                
        require (balanceOf[_target] + _minedAmount > balanceOf[_target]); 
	    balanceOf[doftManager] -= _minedAmount;
	    balanceOf[_target] += _minedAmount;
	    miningStorage -= _minedAmount;
	    Mine(_target, _minedAmount);
    } 
}