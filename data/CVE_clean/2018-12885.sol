pragma solidity 0.4.23;
library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address internal contractOwner;
  constructor () internal {
    if(contractOwner == address(0)){
      contractOwner = msg.sender;
    }
  }
  modifier onlyOwner() {
    require(msg.sender == contractOwner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    contractOwner = newOwner;
  }
}
contract Pausable is Ownable {
  bool private paused = false;
  modifier whenNotPaused() {
    if(paused == true && msg.value > 0){
      msg.sender.transfer(msg.value);
    }
    require(!paused);
    _;
  }
  function triggerPause() onlyOwner external {
    paused = !paused;
  }
}
contract ChampFactory is Pausable{
    event NewChamp(uint256 champID, address owner);
    using SafeMath for uint; 
    struct Champ {
        uint256 id; 
        uint256 attackPower;
        uint256 defencePower;
        uint256 cooldownTime; 
        uint256 readyTime; 
        uint256 winCount;
        uint256 lossCount;
        uint256 position; 
        uint256 price; 
        uint256 withdrawCooldown; 
        uint256 eq_sword;
        uint256 eq_shield;
        uint256 eq_helmet;
        bool forSale; 
    }
    struct AddressInfo {
        uint256 withdrawal;
        uint256 champsCount;
        uint256 itemsCount;
        string name;
    }
    struct Item {
        uint8 itemType; 
        uint8 itemRarity; 
        uint256 attackPower;
        uint256 defencePower;
        uint256 cooldownReduction;
        uint256 price;
        uint256 onChampId; 
        bool onChamp;
        bool forSale; 
    }
    mapping (address => AddressInfo) public addressInfo;
    mapping (uint256 => address) public champToOwner;
    mapping (uint256 => address) public itemToOwner;
    mapping (uint256 => string) public champToName;
    Champ[] public champs;
    Item[] public items;
    uint256[] public leaderboard;
    uint256 internal createChampFee = 5 finney;
    uint256 internal lootboxFee = 5 finney;
    uint256 internal pendingWithdrawal = 0;
    uint256 private randNonce = 0; 
    uint256 public champsForSaleCount;
    uint256 public itemsForSaleCount;
    modifier onlyOwnerOfChamp(uint256 _champId) {
        require(msg.sender == champToOwner[_champId]);
        _;
    }
    modifier onlyNotOwnerOfChamp(uint256 _champId) {
        require(msg.sender != champToOwner[_champId]);
        _;
    }
    modifier isPaid(uint256 _price){
        require(msg.value >= _price);
        _;
    }
    modifier contractMinBalanceReached(){
        require( (address(this).balance).sub(pendingWithdrawal) > 1000000 );
        _;
    }
    modifier isChampWithdrawReady(uint256 _id){
        require(champs[_id].withdrawCooldown < block.timestamp);
        _;
    }
    modifier distributeInput(address _affiliateAddress){
        uint256 contractOwnerWithdrawal = (msg.value / 100) * 50; 
        addressInfo[contractOwner].withdrawal += contractOwnerWithdrawal;
        pendingWithdrawal += contractOwnerWithdrawal;
        if(_affiliateAddress != address(0) && _affiliateAddress != msg.sender){
            uint256 affiliateBonus = (msg.value / 100) * 25; 
            addressInfo[_affiliateAddress].withdrawal += affiliateBonus;
            pendingWithdrawal += affiliateBonus;
        }
        _;
    }
    function getChampsByOwner(address _owner) external view returns(uint256[]) {
        uint256[] memory result = new uint256[](addressInfo[_owner].champsCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < champs.length; i++) {
            if (champToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    function getChampsCount() external view returns(uint256){
        return champs.length;
    }
    function getChampReward(uint256 _position) public view returns(uint256) {
        if(_position <= 800){
            uint256 rewardPercentage = uint256(2000).sub(2 * (_position - 1));
            uint256 availableWithdrawal = address(this).balance.sub(pendingWithdrawal);
            return availableWithdrawal / 1000000 * rewardPercentage;
        }else{
            return uint256(0);
        }
    }
    function randMod(uint256 _modulus) internal returns(uint256) {
        randNonce++;
        return uint256(keccak256(randNonce, blockhash(block.number - 1))) % _modulus;
    }
    function createChamp(address _affiliateAddress) external payable
    whenNotPaused
    isPaid(createChampFee)
    distributeInput(_affiliateAddress)
    {
        uint256 id = champs.push(Champ(0, 2 + randMod(4), 1 + randMod(4), uint256(1 days)  - uint256(randMod(9) * 1 hours), 0, 0, 0, leaderboard.length + 1, 0, uint256(block.timestamp), 0,0,0, false)) - 1;
        champs[id].id = id; 
        leaderboard.push(id); 
        champToOwner[id] = msg.sender; 
        addressInfo[msg.sender].champsCount++;
        emit NewChamp(id, msg.sender);
    }
    function setCreateChampFee(uint256 _fee) external onlyOwner {
        createChampFee = _fee;
    }
    function changeChampsName(uint _champId, string _name) external
    onlyOwnerOfChamp(_champId){
        champToName[_champId] = _name;
    }
    function changePlayersName(string _name) external {
        addressInfo[msg.sender].name = _name;
    }
    function withdrawChamp(uint _id) external
    onlyOwnerOfChamp(_id)
    contractMinBalanceReached
    isChampWithdrawReady(_id)
    whenNotPaused {
        Champ storage champ = champs[_id];
        require(champ.position <= 800);
        champ.withdrawCooldown = block.timestamp + 1 days; 
        uint256 withdrawal = getChampReward(champ.position);
        addressInfo[msg.sender].withdrawal += withdrawal;
        pendingWithdrawal += withdrawal;
    }
    function withdrawToAddress(address _address) external
    whenNotPaused {
        address playerAddress = _address;
        if(playerAddress == address(0)){ playerAddress = msg.sender; }
        uint256 share = addressInfo[playerAddress].withdrawal; 
        require(share > 0); 
        addressInfo[playerAddress].withdrawal = 0; 
        pendingWithdrawal = pendingWithdrawal.sub(share); 
        playerAddress.transfer(share); 
    }
}
contract Items is ChampFactory {
    event NewItem(uint256 itemID, address owner);
    constructor () internal {
        items.push(Item(0, 0, 0, 0, 0, 0, 0, false, false));
    }
    modifier onlyOwnerOfItem(uint256 _itemId) {
        require(_itemId != 0);
        require(msg.sender == itemToOwner[_itemId]);
        _;
    }
    modifier onlyNotOwnerOfItem(uint256 _itemId) {
        require(msg.sender != itemToOwner[_itemId]);
        _;
    }
    function hasChampSomethingOn(uint _champId, uint8 _type) internal view returns(bool){
        Champ storage champ = champs[_champId];
        if(_type == 1){
            return (champ.eq_sword == 0) ? false : true;
        }
        if(_type == 2){
            return (champ.eq_shield == 0) ? false : true;
        }
        if(_type == 3){
            return (champ.eq_helmet == 0) ? false : true;
        }
    }
    function getItemsByOwner(address _owner) external view returns(uint256[]) {
        uint256[] memory result = new uint256[](addressInfo[_owner].itemsCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (itemToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    function takeOffItem(uint _champId, uint8 _type) public
        onlyOwnerOfChamp(_champId) {
            uint256 itemId;
            Champ storage champ = champs[_champId];
            if(_type == 1){
                itemId = champ.eq_sword; 
                if (itemId > 0) { 
                    champ.eq_sword = 0; 
                }
            }
            if(_type == 2){
                itemId = champ.eq_shield; 
                if(itemId > 0) {
                    champ.eq_shield = 0; 
                }
            }
            if(_type == 3){
                itemId = champ.eq_helmet; 
                if(itemId > 0) { 
                    champ.eq_helmet = 0; 
                }
            }
            if(itemId > 0){
                items[itemId].onChamp = false; 
            }
    }
    function putOn(uint256 _champId, uint256 _itemId) external
        onlyOwnerOfChamp(_champId)
        onlyOwnerOfItem(_itemId) {
            Champ storage champ = champs[_champId];
            Item storage item = items[_itemId];
            if(item.onChamp){
                takeOffItem(item.onChampId, item.itemType); 
            }
            item.onChamp = true; 
            item.onChampId = _champId; 
            if(item.itemType == 1){
                if(champ.eq_sword > 0){
                    takeOffItem(champ.id, 1);
                }
                champ.eq_sword = _itemId; 
            }
            if(item.itemType == 2){
                if(champ.eq_shield > 0){
                    takeOffItem(champ.id, 2);
                }
                champ.eq_shield = _itemId; 
            }
            if(item.itemType == 3){
                if(champ.eq_helmet > 0){
                    takeOffItem(champ.id, 3);
                }
                champ.eq_helmet = _itemId; 
            }
    }
    function openLootbox(address _affiliateAddress) external payable
    whenNotPaused
    isPaid(lootboxFee)
    distributeInput(_affiliateAddress) {
        uint256 pointToCooldownReduction;
        uint256 randNum = randMod(1001); 
        uint256 pointsToShare; 
        uint256 itemID;
        Item memory item = Item({
            itemType: uint8(uint256(randMod(3) + 1)), 
            itemRarity: uint8(0),
            attackPower: 0,
            defencePower: 0,
            cooldownReduction: 0,
            price: 0,
            onChampId: 0,
            onChamp: false,
            forSale: false
        });
        if(450 > randNum){
            pointsToShare = 25 + randMod(9); 
            item.itemRarity = uint8(1);
        }else if(720 > randNum){
            pointsToShare = 42 + randMod(17); 
            item.itemRarity = uint8(2);
        }else if(910 > randNum){
            pointsToShare = 71 + randMod(25); 
            item.itemRarity = uint8(3);
        }else if(980 > randNum){
            pointsToShare = 119 + randMod(33); 
            item.itemRarity = uint8(4);
        }else{
            pointsToShare = 235 + randMod(41); 
            item.itemRarity = uint8(5);
        }
        if(item.itemType == uint8(1)){ 
            item.attackPower = pointsToShare / 10 * 7; 
            pointsToShare -= item.attackPower; 
            item.defencePower = pointsToShare / 10 * randMod(6); 
            pointsToShare -= item.defencePower; 
            item.cooldownReduction = pointsToShare * uint256(1 minutes); 
            item.itemType = uint8(1);
        }
        if(item.itemType == uint8(2)){ 
            item.defencePower = pointsToShare / 10 * 7; 
            pointsToShare -= item.defencePower; 
            item.attackPower = pointsToShare / 10 * randMod(6); 
            pointsToShare -= item.attackPower; 
            item.cooldownReduction = pointsToShare * uint256(1 minutes); 
            item.itemType = uint8(2);
        }
        if(item.itemType == uint8(3)){ 
            pointToCooldownReduction = pointsToShare / 10 * 7; 
            item.cooldownReduction = pointToCooldownReduction * uint256(1 minutes); 
            pointsToShare -= pointToCooldownReduction; 
            item.attackPower = pointsToShare / 10 * randMod(6); 
            pointsToShare -= item.attackPower; 
            item.defencePower = pointsToShare; 
            item.itemType = uint8(3);
        }
        itemID = items.push(item) - 1;
        itemToOwner[itemID] = msg.sender; 
        addressInfo[msg.sender].itemsCount++; 
        emit NewItem(itemID, msg.sender);
    }
    function setLootboxFee(uint _fee) external onlyOwner {
        lootboxFee = _fee;
    }
}
contract ItemMarket is Items {
    event TransferItem(address from, address to, uint256 itemID);
    modifier itemIsForSale(uint256 _id){
        require(items[_id].forSale);
        _;
    }
    modifier itemIsNotForSale(uint256 _id){
        require(items[_id].forSale == false);
        _;
    }
    modifier ifItemForSaleThenCancelSale(uint256 _itemID){
      Item storage item = items[_itemID];
      if(item.forSale){
          _cancelItemSale(item);
      }
      _;
    }
    modifier distributeSaleInput(address _owner) {
        uint256 contractOwnerCommision; 
        uint256 playerShare; 
        if(msg.value > 100){
            contractOwnerCommision = (msg.value / 100);
            playerShare = msg.value - contractOwnerCommision;
        }else{
            contractOwnerCommision = 0;
            playerShare = msg.value;
        }
        addressInfo[_owner].withdrawal += playerShare;
        addressInfo[contractOwner].withdrawal += contractOwnerCommision;
        pendingWithdrawal += playerShare + contractOwnerCommision;
        _;
    }
    function getItemsForSale() view external returns(uint256[]){
        uint256[] memory result = new uint256[](itemsForSaleCount);
        if(itemsForSaleCount > 0){
            uint256 counter = 0;
            for (uint256 i = 0; i < items.length; i++) {
                if (items[i].forSale == true) {
                    result[counter]=i;
                    counter++;
                }
            }
        }
        return result;
    }
    function _cancelItemSale(Item storage item) private {
      item.forSale = false;
      itemsForSaleCount--;
    }
    function transferItem(address _from, address _to, uint256 _itemID) internal
      ifItemForSaleThenCancelSale(_itemID) {
        Item storage item = items[_itemID];
        if(item.onChamp && _to != champToOwner[item.onChampId]){
          takeOffItem(item.onChampId, item.itemType);
        }
        addressInfo[_to].itemsCount++;
        addressInfo[_from].itemsCount--;
        itemToOwner[_itemID] = _to;
        emit TransferItem(_from, _to, _itemID);
    }
    function giveItem(address _to, uint256 _itemID) public
      onlyOwnerOfItem(_itemID) {
        transferItem(msg.sender, _to, _itemID);
    }
    function cancelItemSale(uint256 _id) public
    itemIsForSale(_id)
    onlyOwnerOfItem(_id){
      Item storage item = items[_id];
       _cancelItemSale(item);
    }
    function setItemForSale(uint256 _id, uint256 _price) external
      onlyOwnerOfItem(_id)
      itemIsNotForSale(_id) {
        Item storage item = items[_id];
        item.forSale = true;
        item.price = _price;
        itemsForSaleCount++;
    }
    function buyItem(uint256 _id) external payable
      whenNotPaused
      onlyNotOwnerOfItem(_id)
      itemIsForSale(_id)
      isPaid(items[_id].price)
      distributeSaleInput(itemToOwner[_id])
      {
        transferItem(itemToOwner[_id], msg.sender, _id);
    }
}
contract ItemForge is ItemMarket {
	event Forge(uint256 forgedItemID);
	function forgeItems(uint256 _parentItemID, uint256 _childItemID) external
	onlyOwnerOfItem(_parentItemID)
	onlyOwnerOfItem(_childItemID)
	ifItemForSaleThenCancelSale(_parentItemID)
	ifItemForSaleThenCancelSale(_childItemID) {
        require(_parentItemID != _childItemID);
		Item storage parentItem = items[_parentItemID];
		Item storage childItem = items[_childItemID];
		if(childItem.onChamp){
			takeOffItem(childItem.onChampId, childItem.itemType);
		}
		parentItem.attackPower = (parentItem.attackPower > childItem.attackPower) ? parentItem.attackPower : childItem.attackPower;
		parentItem.defencePower = (parentItem.defencePower > childItem.defencePower) ? parentItem.defencePower : childItem.defencePower;
		parentItem.cooldownReduction = (parentItem.cooldownReduction > childItem.cooldownReduction) ? parentItem.cooldownReduction : childItem.cooldownReduction;
		parentItem.itemRarity = uint8(6);
		transferItem(msg.sender, address(0), _childItemID);
		emit Forge(_parentItemID);
	}
}
contract ChampAttack is ItemForge {
    event Attack(uint256 winnerChampID, uint256 defeatedChampID, bool didAttackerWin);
    modifier isChampReady(uint256 _champId) {
      require (champs[_champId].readyTime <= block.timestamp);
      _;
    }
    modifier notSelfAttack(uint256 _champId, uint256 _targetId) {
        require(_champId != _targetId);
        _;
    }
    modifier targetExists(uint256 _targetId){
        require(champToOwner[_targetId] != address(0));
        _;
    }
    function getChampStats(uint256 _champId) public view returns(uint256,uint256,uint256){
        Champ storage champ = champs[_champId];
        Item storage sword = items[champ.eq_sword];
        Item storage shield = items[champ.eq_shield];
        Item storage helmet = items[champ.eq_helmet];
        uint256 totalAttackPower = champ.attackPower + sword.attackPower + shield.attackPower + helmet.attackPower; 
        uint256 totalDefencePower = champ.defencePower + sword.defencePower + shield.defencePower + helmet.defencePower; 
        uint256 totalCooldownReduction = sword.cooldownReduction + shield.cooldownReduction + helmet.cooldownReduction; 
        return (totalAttackPower, totalDefencePower, totalCooldownReduction);
    }
    function subAttack(uint256 _playerAttackPoints, uint256 _x) internal pure returns (uint256) {
        return (_playerAttackPoints <= _x + 2) ? 2 : _playerAttackPoints - _x;
    }
    function subDefence(uint256 _playerDefencePoints, uint256 _x) internal pure returns (uint256) {
        return (_playerDefencePoints <= _x) ? 1 : _playerDefencePoints - _x;
    }
    function _attackCompleted(Champ storage _winnerChamp, Champ storage _defeatedChamp, uint256 _pointsGiven, uint256 _pointsToAttackPower) private {
        _winnerChamp.attackPower += _pointsToAttackPower; 
        _winnerChamp.defencePower += _pointsGiven - _pointsToAttackPower; 
        _defeatedChamp.attackPower = subAttack(_defeatedChamp.attackPower, _pointsToAttackPower); 
        _defeatedChamp.defencePower = subDefence(_defeatedChamp.defencePower, _pointsGiven - _pointsToAttackPower); 
        _winnerChamp.winCount++;
        _defeatedChamp.lossCount++;
        if(_winnerChamp.position > _defeatedChamp.position) { 
            uint256 winnerPosition = _winnerChamp.position;
            uint256 loserPosition = _defeatedChamp.position;
            _defeatedChamp.position = winnerPosition;
            _winnerChamp.position = loserPosition;
            leaderboard[winnerPosition - 1] = _defeatedChamp.id;
            leaderboard[loserPosition - 1] = _winnerChamp.id;
        }
    }
    function _getPoints(uint256 _pointsGiven) private returns (uint256 pointsGiven, uint256 pointsToAttackPower){
        return (_pointsGiven, randMod(_pointsGiven+1));
    }
    function attack(uint256 _champId, uint256 _targetId) external
    onlyOwnerOfChamp(_champId)
    isChampReady(_champId)
    notSelfAttack(_champId, _targetId)
    targetExists(_targetId) {
        Champ storage myChamp = champs[_champId];
        Champ storage enemyChamp = champs[_targetId];
        uint256 pointsGiven; 
        uint256 pointsToAttackPower; 
        uint256 myChampAttackPower;
        uint256 enemyChampDefencePower;
        uint256 myChampCooldownReduction;
        (myChampAttackPower,,myChampCooldownReduction) = getChampStats(_champId);
        (,enemyChampDefencePower,) = getChampStats(_targetId);
        if (myChampAttackPower > enemyChampDefencePower) {
            if(myChampAttackPower - enemyChampDefencePower < 5){
                (pointsGiven, pointsToAttackPower) = _getPoints(3);
            }else if(myChampAttackPower - enemyChampDefencePower < 10){
                (pointsGiven, pointsToAttackPower) = _getPoints(2);
            }else{
                (pointsGiven, pointsToAttackPower) = _getPoints(1);
            }
            _attackCompleted(myChamp, enemyChamp, pointsGiven, pointsToAttackPower);
            emit Attack(myChamp.id, enemyChamp.id, true);
        } else {
            (pointsGiven, pointsToAttackPower) = _getPoints(1);
            _attackCompleted(enemyChamp, myChamp, pointsGiven, pointsToAttackPower);
            emit Attack(enemyChamp.id, myChamp.id, false);
        }
        myChamp.readyTime = uint256(block.timestamp + myChamp.cooldownTime - myChampCooldownReduction);
    }
}
contract ChampMarket is ChampAttack {
    event TransferChamp(address from, address to, uint256 champID);
    modifier champIsForSale(uint256 _id){
        require(champs[_id].forSale);
        _;
    }
    modifier champIsNotForSale(uint256 _id){
        require(champs[_id].forSale == false);
        _;
    }
    modifier ifChampForSaleThenCancelSale(uint256 _champID){
      Champ storage champ = champs[_champID];
      if(champ.forSale){
          _cancelChampSale(champ);
      }
      _;
    }
    function getChampsForSale() view external returns(uint256[]){
        uint256[] memory result = new uint256[](champsForSaleCount);
        if(champsForSaleCount > 0){
            uint256 counter = 0;
            for (uint256 i = 0; i < champs.length; i++) {
                if (champs[i].forSale == true) {
                    result[counter]=i;
                    counter++;
                }
            }
        }
        return result;
    }
     function _cancelChampSale(Champ storage champ) private {
        champ.forSale = false;
        champsForSaleCount--;
     }
    function transferChamp(address _from, address _to, uint256 _champId) internal ifChampForSaleThenCancelSale(_champId){
        Champ storage champ = champs[_champId];
        addressInfo[_to].champsCount++;
        addressInfo[_from].champsCount--;
        champToOwner[_champId] = _to;
        if(champ.eq_sword != 0) { transferItem(_from, _to, champ.eq_sword); }
        if(champ.eq_shield != 0) { transferItem(_from, _to, champ.eq_shield); }
        if(champ.eq_helmet != 0) { transferItem(_from, _to, champ.eq_helmet); }
        emit TransferChamp(_from, _to, _champId);
    }
    function cancelChampSale(uint256 _id) public
      champIsForSale(_id)
      onlyOwnerOfChamp(_id) {
        Champ storage champ = champs[_id];
        _cancelChampSale(champ);
    }
    function giveChamp(address _to, uint256 _champId) external
      onlyOwnerOfChamp(_champId) {
        transferChamp(msg.sender, _to, _champId);
    }
    function setChampForSale(uint256 _id, uint256 _price) external
      onlyOwnerOfChamp(_id)
      champIsNotForSale(_id) {
        Champ storage champ = champs[_id];
        champ.forSale = true;
        champ.price = _price;
        champsForSaleCount++;
    }
    function buyChamp(uint256 _id) external payable
      whenNotPaused
      onlyNotOwnerOfChamp(_id)
      champIsForSale(_id)
      isPaid(champs[_id].price)
      distributeSaleInput(champToOwner[_id]) {
        transferChamp(champToOwner[_id], msg.sender, _id);
    }
}
contract MyCryptoChampCore is ChampMarket {
}