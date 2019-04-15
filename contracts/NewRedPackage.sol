pragma solidity ^0.5.1;
import "./Ownable.sol";
import "./SafeMath.sol";

contract NewRedPackage is Ownable {

    struct Gift {
        bool exists;                    // 0 Only true if this exists
        uint giftId;                    // 1 The gift ID
        address payable giver;          // 2 The address of the giver
        uint expiry;                    // 3 The expiry time
        bool redeemed;                  // 4 Whether the funds have already been redeemed
        string message;                 // 5 A message from the giver to the recipient
        uint timestamp;                 // 6 The timestamp of when the gift was given

        uint redPackageType;            // 7 The redPackageType, 0 is random, 1 is average.

        uint totalCount;                // 8 The packageCount
        uint remainCount;               // 9 current package count;

        uint totalAmount;               // 10 The amount of NEW
        uint remainAmount;              // 11 current amount;
        bool hasPassword;               // 12 hasPassword;
        bytes32 password;               // 13 password
        mapping (address => bool) recipientsMap; // 14 recipients map.
    }

    // Each gift has a unique ID. If you increment this value, you will get
    // an unused gift ID.
    uint public nextGiftId;

    // Maps each recipient address to a list of giftIDs of Gifts they have
    // received.
    mapping (address => uint[]) public recipientToGiftIds;

    // Maps each gift ID to its associated gift.
    mapping (uint => Gift) public giftIdToGift;
    // expiry time
    uint private expiryTime = 86400;
    // min amount range
    uint private minRate = 10;
    // max rate about average
    uint private maxRate = 2;

    event Constructed (address indexed by, uint indexed amount);

    event CollectedAllFees (address indexed by, uint indexed amount);

    event DirectlyDeposited(address indexed from, uint indexed amount);

    event Gave (uint indexed giftId,
        address indexed giver,
        uint amount, uint expiry,
        uint redPackageCount, uint redPackageType,
        bool hasPassword);

    event Redeemed (uint indexed giftId,
        address indexed giver,
        address indexed recipient,
        uint amount);

    // Constructor
    constructor() public payable {
        emit Constructed(msg.sender, msg.value);
    }

    // Fallback function which allows this contract to receive funds.
    function () external payable {
        // Sending ETH directly to this contract does nothing except log an
        // event.
        emit DirectlyDeposited(msg.sender, msg.value);
    }

    //// Getter functions:

    function getGiftIdsByRecipient (address recipient)
    public view returns (uint[] memory) {
        return recipientToGiftIds[recipient];
    }

    //// Contract functions:

    // Call this function while sending NEW to give a gift.
    // @message: Giver can provide the message for receiver.
    // @totalPackageCount: The count of the redPackage.
    // @redPackageType: 0 is random and 1 is average.
    // @hasPassword: bool, the package has password.
    // @password: giver provide the password, which string has made a hash.sha3(password).
    // Tested in test/test_give.js and test/TestGive.sol
    function give (string memory message, uint totalPackageCount, uint redPackageType, bool hasPassword, bytes32 password)
    public payable returns (uint) {

        address payable giver = msg.sender;
        // Validate the giver address
        assert(giver != address(0));
        // The gift must be a positive amount of ETH
        uint totalAmount = msg.value;
        require(totalAmount > 0, "7. Provide amount can not less than 0");
        // default expiry time is 24h.
        uint expiry = SafeMath.add(now, expiryTime);

        // Make sure nextGiftId is 0 or positive, or this contract is buggy
        assert(nextGiftId >= 0);

        // If a gift with this new gift ID already exists, this contract is buggy.
        assert(giftIdToGift[nextGiftId].exists == false);
        // redPackageCount must bigger than 1;
        assert(totalPackageCount > 0);
        // redPackageType must be 1 or 0;
        assert(redPackageType == 0 || redPackageType == 1);

        // Update the mappings
        giftIdToGift[nextGiftId] = Gift(true, nextGiftId, giver, expiry, false, message, now, redPackageType, totalPackageCount, totalPackageCount, msg.value, msg.value, hasPassword, password);

        uint giftId = nextGiftId;

        // Increment nextGiftId
        nextGiftId = SafeMath.add(giftId, 1);

        // If a gift with this new gift ID already exists, this contract is buggy.
        assert(giftIdToGift[nextGiftId].exists == false);

        // Log the event
        emit Gave(giftId, giver, totalAmount, expiry, totalPackageCount, redPackageType, hasPassword);

        return giftId;
    }

    // Call this function to redeem a gift of ETH.
    // Tested in test/test_redeem.js
    function redeem (uint giftId, address payable receiptAddress, bytes memory password) public onlyOwner{
        // The giftID should be 0 or positive
        require(giftId >= 0, "0. Gift id can not less then 0");
        assert(receiptAddress != address(0));
        // The gift must exist and must not have already been redeemed
        require(isValidGift(giftIdToGift[giftId]), "1. Invalid giftId");
        require(giftIdToGift[giftId].recipientsMap[receiptAddress] != true, "2. Receipt address has receipted the gift");
        require(giftIdToGift[giftId].remainAmount > 0, "3. Remain amount is 0");
        // The current datetime must be the same or after the expiry timestamp
        require(now <= giftIdToGift[giftId].expiry, "4. Gift has expiry");
        if(giftIdToGift[giftId].hasPassword) {
            require(giftIdToGift[giftId].password == getPassword(password), "5. Password is error");
        }

        // The amount must be positive because this is required in give()
        uint preRemainAmount = giftIdToGift[giftId].remainAmount;
        assert(preRemainAmount > 0);

        // The giver must not be the recipient because this was asserted in give()
        address giver = giftIdToGift[giftId].giver;
        //assert(giver != recipient);
        uint amount = calculateAmountByType(giftId);

        // Make sure the giver is valid because this was asserted in give();
        assert(giver != address(0));
        // Transfer the funds
        receiptAddress.transfer(amount);
        // update red package.
        uint remainCount = SafeMath.sub(giftIdToGift[giftId].remainCount, 1);
        giftIdToGift[giftId].remainCount = remainCount;
        if(remainCount == 0) {
            giftIdToGift[giftId].redeemed = true;
        }
        giftIdToGift[giftId].recipientsMap[receiptAddress] = true;
        giftIdToGift[giftId].remainAmount = SafeMath.sub(preRemainAmount, amount);

        // Log the event
        emit Redeemed(giftId, giftIdToGift[giftId].giver, receiptAddress, amount);
    }


    // Returns true only if the gift exists and has not already been
    // redeemed
    function isValidGift(Gift memory gift) private pure returns (bool) {
        return gift.exists == true && gift.redeemed == false && gift.remainCount > 0;
    }

    // get amount by redPackageType
    function calculateAmountByType(uint giftID) private view returns(uint){
        Gift memory gift = giftIdToGift[giftID];
        // 0 is random
        if(gift.redPackageType == 0) {
            // the latest package
            if(gift.remainCount == 1) {
                return gift.remainAmount;
            } else {
                uint averageAmount = SafeMath.div(gift.remainAmount, gift.remainCount);
                uint min = SafeMath.div(averageAmount, minRate);
                uint max = SafeMath.mul(averageAmount, maxRate);
                uint amount = SafeMath.div(SafeMath.mul(max, random()), 100);
                if(amount < min) {
                    amount = min;
                }
                return amount;
            }
            // 1 is average
        } else if(gift.redPackageType == 1){
            return SafeMath.div(gift.remainAmount, gift.remainCount);
        }
        return 0;
    }

    // get random number range(0 ~ 100);
    function random() private view returns (uint) {
        return now % 100;
    }

    // withDraw amount when the gift has expiry, onlyOwner can do it.
    function withDraw(uint giftId) public payable onlyOwner{
        assert(giftId >= 0);
        Gift memory gift = giftIdToGift[giftId];
        assert(gift.exists == true);
        address payable giver = gift.giver;
        require(now > gift.expiry, "6. Expiry time is bigger than now");
        giver.transfer(gift.remainAmount);
        giftIdToGift[giftId].remainAmount = 0;
        giftIdToGift[giftId].remainCount = 0;
        giftIdToGift[giftId].redeemed = true;
    }

    // Set Expiry time.
    function setExpiryTime(uint newExpiryTime) public payable onlyOwner {
        assert(newExpiryTime >= 0);
        expiryTime = newExpiryTime;
    }

    function getPassword(bytes memory password) private pure returns(bytes32) {
        return keccak256(password);
    }

    // update min rate
    function setMinRate(uint newMinRate) public payable onlyOwner {
        assert(newMinRate >= 0);
        minRate = newMinRate;
    }

    // update max rate
    function setMaxRate(uint newMaxRate) public payable onlyOwner {
        assert(newMaxRate >= 0);
        maxRate = newMaxRate;
    }


}
