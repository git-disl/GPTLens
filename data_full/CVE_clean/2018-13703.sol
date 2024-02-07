pragma solidity ^0.4.21;
contract tokenRecipient { function receiveApproval(address from, uint256 value, address token, bytes extraData) public; }
contract CERB_Coin
  { 
    string  public name;                                                        
    string  public symbol;                                                      
    uint8   public decimals;                                                    
    uint256 public totalSupply;                                                 
    uint256 public remaining;                                                   
    uint    public ethRate;                                                     
    address public owner;                                                       
    uint256 public amountCollected;                                             
    uint    public icoStatus;                                                   
    uint    public icoTokenPrice;                                               
    address public benAddress;                                                  
    address public bkaddress;                                                   
    uint    public allowTransferToken;                                          
    mapping (address => uint256) public balanceOf;                              
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value, string typex); 
    function CERB_Coin() public
    {
      totalSupply = 1000000000000000000000000000;                                 
      owner =  msg.sender;                                                      
      balanceOf[owner] = totalSupply;                                           
      name = "CERB Coin";                                                     
      symbol = "CERB";                                                          
      decimals = 18;                                                            
      remaining = totalSupply;                                                  
      ethRate = 665;                                                            
      icoStatus = 1;                                                            
      icoTokenPrice = 50;                                                       
      benAddress = 0x4532828EC057e6cFa04a42b153d74B345084C4C2;                  
      bkaddress  = 0x1D38b496176bDaB78D430cebf25B2Fe413d3BF84;                   
      allowTransferToken = 0;                                                   
    }
   modifier onlyOwner()
    {
        require((msg.sender == owner) || (msg.sender ==  bkaddress));
        _;
    }
    function () public payable                                                  
    {
    }    
    function sellOffline(address rec_address,uint256 token_amount) public onlyOwner 
    {
        if (remaining > 0)
        {
            uint finalTokens =  (token_amount  * (10 ** 18));              
            if(finalTokens < remaining)
                {
                    remaining = remaining - finalTokens;
                    _transfer(owner,rec_address, finalTokens);    
                    TransferSell(owner, rec_address, finalTokens,'Offline');
                }
            else
                {
                    revert();
                }
        }
        else
        {
            revert();
        }        
    }
    function getEthRate() onlyOwner public constant returns  (uint)            
    {
        return ethRate;
    }
    function getConBal() onlyOwner public constant returns  (uint)            
    {
        return this.balance;
    }    
    function setEthRate (uint newEthRate) public  onlyOwner                    
    {
        ethRate = newEthRate;
    } 
    function getTokenPrice() onlyOwner public constant returns  (uint)         
    {
        return icoTokenPrice;
    }
    function setTokenPrice (uint newTokenRate) public  onlyOwner               
    {
        icoTokenPrice = newTokenRate;
    }     
    function setTransferStatus (uint status) public  onlyOwner                 
    {
        allowTransferToken = status;
    }   
    function changeIcoStatus (uint8 statx)  public onlyOwner                   
    {
        icoStatus = statx;
    } 
    function withdraw(uint amountWith) public onlyOwner                        
        {
            if((msg.sender == owner) || (msg.sender ==  bkaddress))
            {
                benAddress.transfer(amountWith);
            }
            else
            {
                revert();
            }
        }
    function withdraw_all() public onlyOwner                                   
        {
            if((msg.sender == owner) || (msg.sender ==  bkaddress) )
            {
                var amountWith = this.balance - 10000000000000000;
                benAddress.transfer(amountWith);
            }
            else
            {
                revert();
            }
        }
    function mintToken(uint256 tokensToMint) public onlyOwner 
        {
            if(tokensToMint > 0)
            {
                var totalTokenToMint = tokensToMint * (10 ** 18);
                balanceOf[owner] += totalTokenToMint;
                totalSupply += totalTokenToMint;
                Transfer(0, owner, totalTokenToMint);
            }
        }
	 function adm_trasfer(address _from,address _to, uint256 _value)  public onlyOwner
		  {
			  _transfer(_from, _to, _value);
		  }
    function freezeAccount(address target, bool freeze) public onlyOwner 
        {
            frozenAccount[target] = freeze;
            FrozenFunds(target, freeze);
        }
    function getCollectedAmount() onlyOwner public constant returns (uint256 balance) 
        {
            return amountCollected;
        }        
    function balanceOf(address _owner) public constant returns (uint256 balance) 
        {
            return balanceOf[_owner];
        }
    function totalSupply() private constant returns (uint256 tsupply) 
        {
            tsupply = totalSupply;
        }    
    function transferOwnership(address newOwner) public onlyOwner 
        { 
            balanceOf[owner] = 0;                        
            balanceOf[newOwner] = remaining;               
            owner = newOwner; 
        }        
  function _transfer(address _from, address _to, uint _value) internal 
      {
          if(allowTransferToken == 1 || _from == owner )
          {
              require(!frozenAccount[_from]);                                   
              require (_to != 0x0);                                             
              require (balanceOf[_from] > _value);                              
              require (balanceOf[_to] + _value > balanceOf[_to]);               
              balanceOf[_from] -= _value;                                       
              balanceOf[_to] += _value;                                         
              Transfer(_from, _to, _value);                                     
          }
          else
          {
               revert();
          }
      }
  function transfer(address _to, uint256 _value)  public
      {
          _transfer(msg.sender, _to, _value);
      }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) 
      {
          require (_value < allowance[_from][msg.sender]);                      
          allowance[_from][msg.sender] -= _value;
          _transfer(_from, _to, _value);
          return true;
      }
  function approve(address _spender, uint256 _value) public returns (bool success) 
      {
          allowance[msg.sender][_spender] = _value;
          return true;
      }
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
      {
          tokenRecipient spender = tokenRecipient(_spender);
          if (approve(_spender, _value)) {
              spender.receiveApproval(msg.sender, _value, this, _extraData);
              return true;
          }
      }        
  function burn(uint256 _value) public returns (bool success) 
      {
          require (balanceOf[msg.sender] > _value);                             
          balanceOf[msg.sender] -= _value;                                      
          totalSupply -= _value;                                                
          Burn(msg.sender, _value);
          return true;
      }
  function burnFrom(address _from, uint256 _value) public returns (bool success) 
      {
          require(balanceOf[_from] >= _value);                                  
          require(_value <= allowance[_from][msg.sender]);                      
          balanceOf[_from] -= _value;                                           
          allowance[_from][msg.sender] -= _value;                               
          totalSupply -= _value;                                                
          Burn(_from, _value);
          return true;
      }
}