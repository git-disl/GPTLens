pragma solidity ^0.4.13;
contract owned {
    address public owner;
    mapping (address =>  bool) public admins;
    function owned() {
        owner = msg.sender;
        admins[msg.sender]=true;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAdmin   {
        require(admins[msg.sender] == true);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    function makeAdmin(address newAdmin, bool isAdmin) onlyOwner {
        admins[newAdmin] = isAdmin;
    }
}
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}
contract GRX is owned {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 minBalanceForAccounts;
    bool public usersCanTrade;
    bool public usersCanUnfreeze;
    bool public ico = true; 
    mapping (address => bool) public admin;
    modifier notICO {
        require(admin[msg.sender] || !ico);
        _;
    }
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address =>  bool) public frozen;
    mapping (address =>  bool) public canTrade; 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Reward(address from, address to, uint256 value, string data, uint256 time);
    event Burn(address indexed from, uint256 value);
    event Frozen(address indexed addr, bool frozen);
    event Unlock(address indexed addr, address from, uint256 val);
    function GRX() {
        uint256 initialSupply = 20000000000000000000000000;
        balanceOf[msg.sender] = initialSupply ;              
        totalSupply = initialSupply;                        
        name = "Gold Reward Token";                                   
        symbol = "GRX";                               
        decimals = 18;                            
        minBalanceForAccounts = 1000000000000000;
        usersCanTrade=false;
        usersCanUnfreeze=false;
        admin[msg.sender]=true;
        canTrade[msg.sender]=true;
    }
    function increaseTotalSupply (address target,  uint256 increaseBy )  onlyOwner {
        balanceOf[target] += increaseBy;
        totalSupply += increaseBy;
        Transfer(0, owner, increaseBy);
        Transfer(owner, target, increaseBy);
    }
    function  usersCanUnFreeze(bool can) {
        usersCanUnfreeze=can;
    }
    function setMinBalance(uint minimumBalanceInWei) onlyOwner {
        minBalanceForAccounts = minimumBalanceInWei;
    }
    function transferAndFreeze (address target,  uint256 amount )  onlyAdmin {
        _transfer(msg.sender, target, amount);
        freeze(target, true);
    }
    function _freeze (address target, bool froze )  internal  {
        frozen[target]=froze;
        Frozen(target, froze);
    }
    function freeze (address target, bool froze )   {
        if(froze || (!froze && !usersCanUnfreeze)) {
            require(admin[msg.sender]);
        }
        _freeze(target, froze);
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                   
        require(!frozen[_from]);                       
        require(balanceOf[_from] >= _value);                
        require(balanceOf[_to] + _value > balanceOf[_to]); 
        balanceOf[_from] -= _value;                         
        balanceOf[_to] += _value;                           
        Transfer(_from, _to, _value);
    }
    function transfer(address _to, uint256 _value) notICO {
        require(!frozen[msg.sender]);                       
        if (msg.sender.balance  < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        _transfer(msg.sender, _to, _value);
    }
    mapping (address => uint256) public totalLockedRewardsOf;
    mapping (address => mapping (address => uint256)) public lockedRewardsOf; 
    mapping (address => mapping (uint32  => address)) public userRewarders; 
    mapping (address => mapping (address => uint32)) public userRewardCount; 
    mapping (address => uint32) public userRewarderCount; 
    mapping (address =>  uint256  ) public totalRewardIssuedOut;
    function reward(address _to, uint256 _value, bool locked, string data) {
        require(_to != 0x0);
        require(!frozen[msg.sender]);                       
        if (msg.sender.balance  < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        if(!locked) {
            _transfer(msg.sender, _to, _value);
        }else{
            require(balanceOf[msg.sender] >= _value);                
            require(totalLockedRewardsOf[_to] + _value > totalLockedRewardsOf[_to]); 
            balanceOf[msg.sender] -= _value;                         
            totalLockedRewardsOf[_to] += _value;                           
            lockedRewardsOf[_to][msg.sender] += _value;
            if(userRewardCount[_to][msg.sender]==0) {
                userRewarderCount[_to] += 1;
                userRewarders[_to][userRewarderCount[_to]]=msg.sender;
            }
            userRewardCount[_to][msg.sender]+=1;
            totalRewardIssuedOut[msg.sender]+= _value;
            Transfer(msg.sender, _to, _value);
        }
        Reward(msg.sender, _to, _value, data, now);
    }
    function transferReward(address _to, uint256 _value) {
        require(!frozen[msg.sender]);                       
        require(lockedRewardsOf[msg.sender][_to] >= _value );
        require(totalLockedRewardsOf[msg.sender] >= _value);
        if (msg.sender.balance  < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        totalLockedRewardsOf[msg.sender] -= _value;                           
        lockedRewardsOf[msg.sender][_to] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    function unlockReward(address addr, uint256 _value) {
        require(totalLockedRewardsOf[addr] > _value);                       
        require(lockedRewardsOf[addr][msg.sender] >= _value );
        if(_value==0) _value=lockedRewardsOf[addr][msg.sender];
        if (msg.sender.balance  < minBalanceForAccounts) {
            sell((minBalanceForAccounts - msg.sender.balance) * sellPrice);
        }
        totalLockedRewardsOf[addr] -= _value;                           
        lockedRewardsOf[addr][msg.sender] -= _value;
        balanceOf[addr] += _value;
        Unlock(addr, msg.sender, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(!frozen[_from]);                       
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value)
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) onlyOwner
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    function burn(uint256 _value) onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }
    function burnFrom(address _from, uint256 _value)  returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] -= _value;                         
        allowance[_from][msg.sender] -= _value;             
        totalSupply -= _value;                              
        Burn(_from, _value);
        return true;
    }
    uint256 public sellPrice = 608;
    uint256 public buyPrice = 760;
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    function setUsersCanTrade(bool trade) onlyOwner {
        usersCanTrade=trade;
    }
    function setCanTrade(address addr, bool trade) onlyOwner {
        canTrade[addr]=trade;
    }
    function buy() payable returns (uint256 amount){
        if(!usersCanTrade && !canTrade[msg.sender]) revert();
        amount = msg.value * buyPrice;                    
        require(balanceOf[this] >= amount);               
        balanceOf[msg.sender] += amount;                  
        balanceOf[this] -= amount;                        
        Transfer(this, msg.sender, amount);               
        return amount;                                    
    }
    function sell(uint256 amount) returns (uint revenue){
        require(!frozen[msg.sender]);
        if(!usersCanTrade && !canTrade[msg.sender]) {
            require(minBalanceForAccounts > amount/sellPrice);
        }
        require(balanceOf[msg.sender] >= amount);         
        balanceOf[this] += amount;                        
        balanceOf[msg.sender] -= amount;                  
        revenue = amount / sellPrice;
        require(msg.sender.send(revenue));                
        Transfer(msg.sender, this, amount);               
        return revenue;                                   
    }
    function() payable {
    }
    event Withdrawn(address indexed to, uint256 value);
    function withdraw(address target, uint256 amount) onlyOwner {
        target.transfer(amount);
        Withdrawn(target, amount);
    }
    function setAdmin(address addr, bool enabled) onlyOwner {
        admin[addr]=enabled;
    }
    function setICO(bool enabled) onlyOwner {
        ico=enabled;
    }
}