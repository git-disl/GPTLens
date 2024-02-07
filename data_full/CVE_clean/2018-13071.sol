pragma solidity ^0.4.17;
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
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract token {
    string public standard = "T10 1.0";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping(address=>uint256) public indexes;
    mapping(uint256=>address) public addresses;
    uint256 public lastIndex = 0;
    event Transfer(address indexed from, address indexed to, uint256 value);
    function token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              
        totalSupply = initialSupply;                        
        name = tokenName;                                   
        symbol = tokenSymbol;                               
        decimals = decimalUnits;                            
        addresses[1] = msg.sender;
        indexes[msg.sender] = 1;
        lastIndex = 1;
    }
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                            
        Transfer(msg.sender, _to, _value);                   
    }
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                 
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;   
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    function () {
        throw;     
    }
}
contract CCindexToken is owned, token {
    uint256 public sellPrice;
    uint256 public buyPrice;
    mapping(address=>bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    uint256 public constant initialSupply = 40000000 * 10**18;
    uint8 public constant decimalUnits = 18;
    string public tokenName = "CCindex10";
    string public tokenSymbol = "T10";
    function CCindexToken() token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        if (frozenAccount[msg.sender]) throw;                
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                            
        Transfer(msg.sender, _to, _value);                   
        if(_value > 0){
            if(balanceOf[msg.sender] == 0){
                addresses[indexes[msg.sender]] = addresses[lastIndex];
                indexes[addresses[lastIndex]] = indexes[msg.sender];
                indexes[msg.sender] = 0;
                delete addresses[lastIndex];
                lastIndex--;
            }
            if(indexes[_to]==0){
                lastIndex++;
                addresses[lastIndex] = _to;
                indexes[_to] = lastIndex;
            }
        }
    }
    function getAddresses() constant returns (address[]){
        address[] memory addrs = new address[](lastIndex);
        for(uint i = 0; i < lastIndex; i++){
            addrs[i] = addresses[i+1];
        }
        return addrs;
    }
    function distributeTokens(uint startIndex,uint endIndex) onlyOwner returns (uint) {
        uint distributed = 0;
        require(startIndex < endIndex);
        for(uint i = startIndex; i < lastIndex; i++){
            address holder = addresses[i+1];
            uint reward = balanceOf[holder] * 3 / 100;
            balanceOf[holder] += reward;
            distributed += reward;
            Transfer(0, holder, reward);
        }
        totalSupply += distributed;
        return distributed;
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                        
        if (balanceOf[_from] < _value) throw;                 
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (_value > allowance[_from][msg.sender]) throw;   
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function buy() payable {
        uint amount = msg.value / buyPrice;                
        if (balanceOf[this] < amount) throw;               
        balanceOf[msg.sender] += amount;                   
        balanceOf[this] -= amount;                         
        Transfer(this, msg.sender, amount);                
    }
    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount ) throw;        
        balanceOf[this] += amount;                         
        balanceOf[msg.sender] -= amount;                   
        if (!msg.sender.send(amount * sellPrice)) {        
            throw;                                         
        } else {
            Transfer(msg.sender, this, amount);            
        }
    }
}