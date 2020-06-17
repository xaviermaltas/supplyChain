pragma solidity ^0.5.16;

/**
    Group 6

    Xavier Maltas 
    Enric Camacho
    Guille Pujol
    Gerard Garcia
    Laia Gil
    Alexander Ramirez
    
*/

//This is the standard of the token ERC20
contract ERC20Token {

    string name;
    mapping(address => uint256) public balances;
    
    constructor(string memory _name) public { name = _name; }

    //Function to mint tokens
    function mint(uint256 refund) public {  balances[tx.origin] += refund; }

}

//This is the token of the supply chain
contract SupplyCoin is ERC20Token {

    string public symbol;
    
    address[] public owners;
    uint256 public ownerCount;
    
    
    constructor(string memory _name, string memory _symbol)


    ERC20Token(_name) public { symbol = _symbol; }

    //Acuñar tokens
    //Function to mint SupplyCoins inherited from ERC20Token
    function mint(uint256 refund) public {
        super.mint(refund);
        ownerCount ++;
        owners.push(msg.sender);
    }
    
    //Giving an address, returns its balance 
    function getAccountBalance(address accountAddress) public view returns(uint256){
        return balances[accountAddress];
    }
    
    //Allows to move tokens between two accounts
    function moveTokens(uint256 amount, address _from, address _to) external {
        balances[_from] = balances[_from] - amount;
        balances[_to] = balances[_to] + amount;
    }
}



contract supply_Chain {
    
    //Total of products
    uint public totalProducts;
    
    //Total of participants (Users)
    uint public totalParticipants;
    
    //Total of tracked Item
    uint public totalTrackedItems;

    //This address is the address of the minting smart contract SUPPLYCOINS
    //address dels tokens que generas
    address public token;
    
    //This address will receive the ETHER
    address payable wallet;
    
    constructor(address payable _wallet, address _token) public {
        wallet = _wallet;
        token = _token;
        totalProducts = 0;
        totalParticipants = 0;
        totalTrackedItems = 0;
    }

    struct track_product {
        uint productId;
        uint previousOwnerId;
        uint ownerId;
        address productOwner;
        uint transfertimeStamp;
    }

    struct product {
        string productName;
        uint productCost;
        string productDescription;
        address productOwner;
        uint manufactureDate;
    }
    
    struct participant {
        string participantName;
        address participantAddress;
        string userType;
    }

    // These are all the mapping where we'll safe the information
    mapping(uint => track_product) public tracks;
    mapping(uint => product) public products;
    mapping(uint => participant) public participants;
    
    //The functions with this modifier will only be able to be executed by the owner of the product. 
    modifier onlyOwner(uint pid) {
        require(msg.sender == products[pid].productOwner, "Error: Only the owner of the product can execute this function");
        _;
    }

    //Function to buy Supply Coins
    function buySupplyCoins() public payable {
        SupplyCoin _token = SupplyCoin(address(token));
        _token.mint(msg.value);
        wallet.transfer(msg.value);
    }


    //Create a new participant
    function createParticipant(string memory name, address u_add, string memory utype) public returns (uint){
        uint user_id = totalParticipants++;
        participants[user_id].participantName = name;
        participants[user_id].participantAddress = u_add;
        participants[user_id].userType = utype;
        
        return user_id;
    }

    //Giving the id of a participant, return its name, address and type
    function getParticipant(uint part_id) public view returns  (string memory, address, string memory) {
        return (participants[part_id].participantName, participants[part_id].participantAddress, participants[part_id].userType);
    }
    
    //Create a new product on the supply chain
    function newProduct(uint own_id, string memory prod_name, uint prod_cost, string memory prod_description ) public  returns (uint) {
        if(keccak256(abi.encodePacked(participants[own_id].userType)) == keccak256("Manufacturer")) {
            uint product_id = totalProducts++;

            products[product_id].productName = prod_name;
            products[product_id].productCost = prod_cost;
            products[product_id].productDescription = prod_description;
            products[product_id].productOwner = participants[own_id].participantAddress;
            products[product_id].manufactureDate = now;

            return product_id;
        }
        
       return 0;
    }


    //Get the details of a product, giving its ID
    function getProduct_details(uint prod_id) public view returns (string memory, uint, address, uint){
        return (products[prod_id].productName, products[prod_id].productCost, products[prod_id].productOwner, products[prod_id].manufactureDate);
    }

    //This functions makes possible the transfer of a product between two participants
    //Every transfer is registered on the tracks mapping 
    function transferOwnership_product(uint user1_id, uint user2_id, uint prod_id) onlyOwner(prod_id) public returns(bool) {
        participant storage p1 = participants[user1_id];
        participant storage p2 = participants[user2_id];
        bool functionStatus = false;
        uint track_id = totalTrackedItems;
        
        if(keccak256(abi.encodePacked(p1.userType)) == keccak256("Manufacturer") && keccak256(abi.encodePacked(p2.userType))==keccak256("Supplier")){

            tracks[track_id].productId = prod_id;
            tracks[track_id].previousOwnerId = user1_id;
            tracks[track_id].ownerId = user2_id;
            tracks[track_id].productOwner = p2.participantAddress;
            tracks[track_id].transfertimeStamp = now;

            products[prod_id].productOwner = p2.participantAddress;

            uint256 productPrice = products[prod_id].productCost;
            payTransfer(productPrice, p1.participantAddress, p2.participantAddress);

            totalTrackedItems = totalTrackedItems++;
            
            functionStatus = true;
        }

        if(keccak256(abi.encodePacked(p1.userType)) == keccak256("Supplier") && keccak256(abi.encodePacked(p2.userType))==keccak256("Supplier")){

            tracks[track_id].productId = prod_id;
            tracks[track_id].previousOwnerId = user1_id;
            tracks[track_id].ownerId = user2_id;
            tracks[track_id].productOwner = p2.participantAddress;
            tracks[track_id].transfertimeStamp = now;

            products[prod_id].productOwner = p2.participantAddress;
            
            uint256 productPrice = products[prod_id].productCost;
            payTransfer(productPrice, p1.participantAddress, p2.participantAddress);

            totalTrackedItems = totalTrackedItems++;
            
            functionStatus = true;
        }
        
        else if(keccak256(abi.encodePacked(p1.userType)) == keccak256("Supplier") && keccak256(abi.encodePacked(p2.userType))==keccak256("Customer")){

            tracks[track_id].productId =prod_id;
            tracks[track_id].previousOwnerId = user1_id;
            tracks[track_id].ownerId = user2_id;
            tracks[track_id].productOwner = p2.participantAddress;
            tracks[track_id].transfertimeStamp = now;
            
            products[prod_id].productOwner = p2.participantAddress;
            
            uint256 productPrice = products[prod_id].productCost;
            payTransfer(productPrice, p1.participantAddress, p2.participantAddress);

            totalTrackedItems = totalTrackedItems++;
            
            functionStatus = true;
        }
        
        return functionStatus;
    }

    //This function allow to check if the buyer has enough money to pay the transfer and does the transfer of supplyCoins
    function payTransfer(uint256 cost, address receiverAddress, address senderAddress) internal {
        SupplyCoin _token = SupplyCoin(address(token));
        uint256 senderBalance = _token.getAccountBalance(senderAddress);
        require(senderBalance >= cost, "Not enough money");
        _token.moveTokens(cost, senderAddress, receiverAddress);
	} 

    //Giving the Id of a product, we'll get the info of this tracked product
    function getProduct_trackindex(uint trck_id)  public view returns (uint, uint, uint, address, uint) {
        track_product storage trackProduct = tracks[trck_id];
        return (trackProduct.productId,  trackProduct.previousOwnerId, trackProduct.ownerId, trackProduct.productOwner, trackProduct.transfertimeStamp);
    }

}