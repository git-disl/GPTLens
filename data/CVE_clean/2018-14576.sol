contract owned {
  address public owner;
  function owned() {
    owner = msg.sender;
  }
  modifier onlyOwner {
    if (msg.sender != owner) throw;
    _;
  }
  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }
}
contract tokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
} 
contract IERC20Token {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
} 
contract SunContractToken is IERC20Token, owned{
  string public standard = "SunContract token v1.0";
  string public name = "SunContract";
  string public symbol = "SNC";
  uint8 public decimals = 18;
  address public icoContractAddress;
  uint256 public tokenFrozenUntilBlock;
  uint256 supply = 0;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowances;
  mapping (address => bool) restrictedAddresses;
  event Mint(address indexed _to, uint256 _value);
  event Burn(address indexed _from, uint256 _value);
  event TokenFrozen(uint256 _frozenUntilBlock, string _reason);
  function SunContractToken(address _icoAddress) {
    restrictedAddresses[0x0] = true;
    restrictedAddresses[_icoAddress] = true;
    restrictedAddresses[address(this)] = true;
    icoContractAddress = _icoAddress;
  }
  function totalSupply() constant returns (uint256 totalSupply) {
    return supply;
  }
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
  function transfer(address _to, uint256 _value) returns (bool success) {
    if (block.number < tokenFrozenUntilBlock) throw;    
    if (restrictedAddresses[_to]) throw;                
    if (balances[msg.sender] < _value) throw;           
    if (balances[_to] + _value < balances[_to]) throw;  
    balances[msg.sender] -= _value;                     
    balances[_to] += _value;                            
    Transfer(msg.sender, _to, _value);                  
    return true;
  }
  function approve(address _spender, uint256 _value) returns (bool success) {
    if (block.number < tokenFrozenUntilBlock) throw;    
    allowances[msg.sender][_spender] = _value;          
    Approval(msg.sender, _spender, _value);             
    return true;
  }
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {            
    tokenRecipient spender = tokenRecipient(_spender);              
    approve(_spender, _value);                                      
    spender.receiveApproval(msg.sender, _value, this, _extraData);  
    return true;     
  }     
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {      
    if (block.number < tokenFrozenUntilBlock) throw;    
    if (restrictedAddresses[_to]) throw;                
    if (balances[_from] < _value) throw;                
    if (balances[_to] + _value < balances[_to]) throw;  
    if (_value > allowances[_from][msg.sender]) throw;  
    balances[_from] -= _value;                          
    balances[_to] += _value;                            
    allowances[_from][msg.sender] -= _value;            
    Transfer(_from, _to, _value);                       
    return true;     
  }         
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {         
    return allowances[_owner][_spender];
  }         
  function mintTokens(address _to, uint256 _amount) {         
    if (msg.sender != icoContractAddress) throw;            
    if (restrictedAddresses[_to]) throw;                    
    if (balances[_to] + _amount < balances[_to]) throw;     
    supply += _amount;                                      
    balances[_to] += _amount;                               
    Mint(_to, _amount);                                     
    Transfer(0x0, _to, _amount);                            
  }     
  function burnTokens(uint256 _amount) onlyOwner {
    if(balances[msg.sender] < _amount) throw;               
    if(supply < _amount) throw;                             
    supply -= _amount;                                      
    balances[msg.sender] -= _amount;                        
    Burn(msg.sender, _amount);                              
    Transfer(msg.sender, 0x0, _amount);                     
  }
  function freezeTransfersUntil(uint256 _frozenUntilBlock, string _reason) onlyOwner {      
    tokenFrozenUntilBlock = _frozenUntilBlock;
    TokenFrozen(_frozenUntilBlock, _reason);
  }
  function isRestrictedAddress(address _querryAddress) constant returns (bool answer){
    return restrictedAddresses[_querryAddress];
  }
}