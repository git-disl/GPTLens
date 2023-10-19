pragma solidity ^0.4.13;
contract owned {
    address public centralAuthority;
    address public plutocrat;
    function owned() {
        centralAuthority = msg.sender;
	plutocrat = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != centralAuthority) revert();
        _;
    }
    modifier onlyPlutocrat {
        if (msg.sender != plutocrat) revert();
        _;
    }
    function transfekbolOwnership(address newOwner) onlyPlutocrat {
        centralAuthority = newOwner;
    }
    function transfekbolPlutocrat(address newPlutocrat) onlyPlutocrat {
        plutocrat = newPlutocrat;
    }
}
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract token {
    string public decentralizedEconomy = 'PLUTOCRACY';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event InterestFreeLending(address indexed from, address indexed to, uint256 value, uint256 duration_in_days);
    event Settlement(address indexed from, address indexed to, uint256 value, string notes, string reference);
    event AuthorityNotified(string notes, string reference);
    event ClientsNotified(string notes, string reference);
    event LoanRepaid(address indexed from, address indexed to, uint256 value, string reference);
    event TokenBurnt(address indexed from, uint256 value);
    event EconomyTaxed(string base_value, string target_value, string tax_rate, string taxed_value, string notes);
    event EconomyRebated(string base_value, string target_value, string rebate_rate, string rebated_value, string notes);
    event PlutocracyAchieved(string value, string notes);
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
    }
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                               
        if (balanceOf[msg.sender] < _value) revert();           
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 
        balanceOf[msg.sender] -= _value;                        
        balanceOf[_to] += _value;                               
        Transfer(msg.sender, _to, _value);                      
    }
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval (msg.sender, _spender, _value);
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
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert();                 
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        if (_value > allowance[_from][msg.sender]) revert();     
        balanceOf[_from] -= _value;                              
        balanceOf[_to] += _value;                                
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    function () {
        revert();                                                
    }
}
contract Krown is owned, token {
    string public nominalValue;
    string public update;
    string public sign;
    string public website;
    uint256 public totalSupply;
    uint256 public notificationFee;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    function Krown(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        address centralMinter
    ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {
        if(centralMinter != 0 ) centralAuthority = centralMinter;      
        balanceOf[centralAuthority] = initialSupply;                   
    }
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();
        if (balanceOf[msg.sender] < _value) revert();           
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 
        if (frozenAccount[msg.sender]) revert();                
        balanceOf[msg.sender] -= _value;                        
        balanceOf[_to] += _value;                               
        Transfer(msg.sender, _to, _value);                      
    }
	function lend(address _to, uint256 _value, uint256 _duration_in_days) {
        if (_to == 0x0) revert();                               
        if (balanceOf[msg.sender] < _value) revert();           
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 
        if (frozenAccount[msg.sender]) revert();                
        if (_duration_in_days > 36135) revert();
        balanceOf[msg.sender] -= _value;                        
        balanceOf[_to] += _value;                               
        InterestFreeLending(msg.sender, _to, _value, _duration_in_days);    
    }
    function repayLoan(address _to, uint256 _value, string _reference) {
        if (_to == 0x0) revert();                               
        if (balanceOf[msg.sender] < _value) revert();           
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 
        if (frozenAccount[msg.sender]) revert();                
        if (bytes(_reference).length != 66) revert();
        balanceOf[msg.sender] -= _value;                        
        balanceOf[_to] += _value;                               
        LoanRepaid(msg.sender, _to, _value, _reference);                   
    }
    function settlvlement(address _from, uint256 _value, address _to, string _notes, string _reference) onlyOwner {
        if (_from == plutocrat) revert();
        if (_to == 0x0) revert();
        if (balanceOf[_from] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        if (bytes(_reference).length != 66) revert();
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Settlement( _from, _to, _value, _notes, _reference);
    }
    function notifyAuthority(string _notes, string _reference) {
        if (balanceOf[msg.sender] < notificationFee) revert();
        if (bytes(_reference).length > 66) revert();
        if (bytes(_notes).length > 64) revert();
        balanceOf[msg.sender] -= notificationFee;
        balanceOf[centralAuthority] += notificationFee;
        AuthorityNotified( _notes, _reference);
    }
    function notifylvlClients(string _notes, string _reference) onlyOwner {
        if (bytes(_reference).length > 66) revert();
        if (bytes(_notes).length > 64) revert();
        ClientsNotified( _notes, _reference);
    }
    function taxlvlEconomy(string _base_value, string _target_value, string _tax_rate, string _taxed_value, string _notes) onlyOwner {
        EconomyTaxed( _base_value, _target_value, _tax_rate, _taxed_value, _notes);
    }
    function rebatelvlEconomy(string _base_value, string _target_value, string _rebate_rate, string _rebated_value, string _notes) onlyOwner {
        EconomyRebated( _base_value, _target_value, _rebate_rate, _rebated_value, _notes);
    }
    function plutocracylvlAchieved(string _value, string _notes) onlyOwner {
        PlutocracyAchieved( _value, _notes);
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();                                  
        if (frozenAccount[_from]) revert();                        
        if (balanceOf[_from] < _value) revert();                   
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();    
        if (_value > allowance[_from][msg.sender]) revert();       
        balanceOf[_from] -= _value;                                
        balanceOf[_to] += _value;                                  
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    function mintlvlToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    function burnlvlToken(address _from, uint256 _value) onlyOwner {
        if (_from == plutocrat) revert();
        if (balanceOf[_from] < _value) revert();                   
        balanceOf[_from] -= _value;                                
        totalSupply -= _value;                                     
        TokenBurnt(_from, _value);
    }
    function freezelvlAccount(address target, bool freeze) onlyOwner {
        if (target == plutocrat) revert();
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    function setlvlSign(string newSign) onlyOwner {
        sign = newSign;
    }
    function setlvlNominalValue(string newNominalValue) onlyOwner {
        nominalValue = newNominalValue;
    }
    function setlvlUpdate(string newUpdate) onlyOwner {
        update = newUpdate;
    }
    function setlvlWebsite(string newWebsite) onlyOwner {
        website = newWebsite;
    }
    function setlvlNfee(uint256 newFee) onlyOwner {
        notificationFee = newFee;
    }
}