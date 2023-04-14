// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract BKLoyalty is ERC721URIStorage, Ownable {
    
    // ============================================
    // Declaraciones iniciales
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    enum TokenType {Award, Subscription, Collectable, Other}

    //1ETH=0.00061 MATIC
    uint256 price_356 = 0.000061 ether;
    uint256 price_180 = 0.000037 ether;
    uint256 price_90 = 0.000020 ether;

    string uri_365 ="https://gateway.pinata.cloud/ipfs/QmcZvVnGJESMumVMr5mqRKrbwFMQc54tDPctZUCNFNGL68";

    // Estructura de datos con las propiedades del award
    struct LoyaltyToken {
        TokenType loyaltytype; 
        //string name;
        uint256 id;
        uint256 expiration; 
    }
 
    // Mapping from token ID to owner address
    mapping(uint256 => LoyaltyToken) private _loyaltytokens;
    
    
    constructor() ERC721("Hamburguesa Loyalty", "HAM") {}

    // Declaración del evento de asignación de un nuevo token de lealtad a un cliente
    event NewLoyalty(address indexed owner, uint256 id, TokenType loyaltytype);

    // Declaración del evento de Autorización de Pago
    event PaymentAuth(address indexed owner, uint256 id, uint paymentid);

    // Definición del precio de la suscripción 1 año
    function setPrice365(uint256 _price) external onlyOwner {
        price_356 = _price;
    }

    // Obtención del precio de la suscripción 1 año
    function getPrice365() external view returns (uint256) {
        return price_356;
    }

    // Actualización de la URI donde está la metadata del token en IPFS asociado a la suscripción 1 año
    function setUri365(string memory _uri) external onlyOwner {
        uri_365 = _uri;
    }

    // Obtención de la URI donde está la metadata del token en IPFS asociado a la suscripción 1 año
    function getUri365() external view returns (string memory) {
        return  uri_365;
    }


    function _mintNFT(address recipient, uint256 newItemId, string memory tokenURI)
        private
        returns (uint256)
    {
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    /*function mintNFT(address recipient, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }*/


    //Conceder un token de premio a un cliente
    function grantAward(address recipient, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        LoyaltyToken memory newLoyalty;
        newLoyalty.loyaltytype=TokenType.Award;
        //newLoyalty.name=name;
        newLoyalty.id=newItemId;
        newLoyalty.expiration=type(uint256).max; //Sin vencimiento
        
        _loyaltytokens[newItemId]=newLoyalty;
        
        _mintNFT(recipient, newItemId, tokenURI);
        
        emit NewLoyalty(recipient, newItemId, newLoyalty.loyaltytype);
    
        return newItemId;
    }

    //Comprar suscripción 1 año
    function buySubscription365 (address recipient)
        public payable
        returns (uint256)
    {
        require(msg.value >= price_356);

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        LoyaltyToken memory newLoyalty;
        newLoyalty.loyaltytype=TokenType.Subscription;
        //newLoyalty.name="1 YEAR SUBSCRIPTION";
        newLoyalty.id=newItemId;
        newLoyalty.expiration=block.timestamp+365 days; //Vencimiento 1 año
        
        _loyaltytokens[newItemId]=newLoyalty;
 
        _mintNFT(recipient, newItemId, uri_365);
        
        emit NewLoyalty(recipient, newItemId, newLoyalty.loyaltytype);
    
        return newItemId;
    }

    //Realizar un pago con un token: la función sirve para cualquier tipo de token
    function paywithToken (uint256 tokenId, uint256 paymentRef)
        public 
        returns (uint256)
    {
        
        require(_exists(tokenId),"Token id does not exists"); //El token debe existir
        require(msg.sender==_ownerOf(tokenId),"Token owner does not match with caller"); //El propietario del token debe ser el mismo que está invocando el uso
        require(_loyaltytokens[tokenId].expiration>block.timestamp,"Token has expired, it cannot be used"); //El token debe no debe estar vencido

        if(_loyaltytokens[tokenId].loyaltytype==TokenType.Award){
            _loyaltytokens[tokenId].expiration=block.timestamp; //En caso que el token sea tipo AWARD, de un único uso por lo tanto, debe quemarse
        }
        
        emit PaymentAuth(msg.sender, tokenId, paymentRef); //Se emite evento con referencia al pago para que se capture por el sistema de venta

        return tokenId;
    }

    // Extracción de los ethers del Smart Contract hacia el Owner 
    function withdraw() external payable onlyOwner {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }

    // Consultar el saldo recaudado en el smart contract por venta de suscripciones
    function getBalance() external view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    //función DUMMY
    function getTokenData(uint256 tokenId) external view returns (LoyaltyToken memory){
        require(_exists(tokenId),"Token id does not exists"); //El token debe existir
        return _loyaltytokens[tokenId];
    }

}
