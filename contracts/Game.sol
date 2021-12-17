//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";

contract Game is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Character {
        uint256 hp;
        uint256 xp;
        uint256 gold;
        uint256 maxHp;
        string name;
        string image;
    }

    Character private boss;

    Character[] private characterTypes; 

    mapping(uint256 => Character) private characters;
    mapping(address => uint256) private charactersOwnedBy;

    event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);
    event PlayerContinued(uint256 tokenId);

    constructor(uint256[] memory hp, 
                uint256[] memory xp, 
                uint256[] memory gold, 
                uint256[] memory maxHp,
                string[] memory name, 
                string[] memory image) ERC721("Boss Encounters", "BOSS") {
        for (uint256 i = 0; i < hp.length - 1; i++) {
            characterTypes.push(Character(hp[i], xp[i], gold[i], maxHp[i], name[i], image[i]));
            
            console.log("Created character %s with hp %s and image %s", 
                name[i], hp[i], image[i]);
        }

        uint bossIndex = hp.length - 1;

        boss = Character(hp[bossIndex], xp[bossIndex], gold[bossIndex], maxHp[bossIndex],
            name[bossIndex], image[bossIndex]);
    }

    function getBoss() public view returns (Character memory) {
        return boss;
    }

    function getPlayer() public view returns (Character memory) {
        uint256 tokenId = charactersOwnedBy[msg.sender];
        return characters[tokenId];
    }

    function continuePlayer() public {
        uint256 tokenId = charactersOwnedBy[msg.sender];
        Character memory player = characters[tokenId];
        player.hp = player.maxHp;

        emit PlayerContinued(tokenId);
    }

    function getCharacterTypes() public view returns (Character[] memory) {
        return characterTypes;
    }

    function mintPlayer(uint256 characterType) external returns (uint256 tokenId) {
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);

        console.log("Minted Player NFT w/ tokenId %s", newTokenId);

        characters[newTokenId] = characterTypes[characterType];
        charactersOwnedBy[msg.sender] = newTokenId;

        _tokenIds.increment();

        emit CharacterNFTMinted(msg.sender, newTokenId, characterType);

        return newTokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        Character memory character = characters[tokenId];

        string memory hp = Strings.toString(character.hp);
        string memory xp = Strings.toString(character.xp);
        string memory gold = Strings.toString(character.gold);
        string memory maxHp = Strings.toString(character.maxHp);

        /* solhint-disable quotes */
        string memory name = string(abi.encodePacked('"name":"', character.name, '",'));
        string memory image = string(abi.encodePacked('"image":"', character.image, '",'));
        string memory hpAttribute = string(abi.encodePacked('{ "trait_type": "HP", "value":', hp, '},'));
        string memory maxHpAttribute = string(abi.encodePacked('{ "trait_type": "Max HP", "value":', maxHp, '},'));
        string memory xpAttribute = string(abi.encodePacked('{ "trait_type": "XP", "value":', xp, '},'));
        string memory goldAttribute = string(abi.encodePacked('{ "trait_type": "Gold", "value":', gold, '}'));
        string memory attributesFinal = string(abi.encodePacked('"attributes": [', hpAttribute, xpAttribute, goldAttribute, maxHpAttribute, "]"));
        /* solhint-enable quotes */

        string memory json = string(abi.encodePacked("{", name, image, attributesFinal, "}"));

        string memory jsonEncoded = Base64.encode(bytes(json));
        string memory finalTokenURI = string(abi.encodePacked("data:application/json;base64,", jsonEncoded));
        return finalTokenURI;
    }

    function attackBoss() public {
        // Get the state of the player's NFT.
        uint256 tokenId = charactersOwnedBy[msg.sender];
        Character memory player = characters[tokenId];

        console.log("\n%s about to attack. Has %s HP and %s XP", player.name, player.hp, player.xp);
        console.log("Boss %s has %s HP and %s XP", boss.name, boss.hp, boss.xp);

        // Make sure the player has more than 0 HP.
        require(player.hp > 0, "Player ded");
        // Make sure the boss has more than 0 HP.
        require(boss.hp > 0, "Boss has been defeated");

        // Allow player to attack boss.
        uint bossAttackDamage = random();
        if (boss.hp < bossAttackDamage) {
            boss.hp = 0;
        } else {
            boss.hp = boss.hp - bossAttackDamage;
        }

        console.log("Player deals %s damage. Boss HP %s", bossAttackDamage, boss.hp);

        // Allow boss to attack player.
        uint playerAttackDamage = random();
        if (player.hp < playerAttackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - playerAttackDamage;
        }

        console.log("Boss deals %s damage. Player hp: %s\n", playerAttackDamage, player.hp);

        // If the boss is defeated, award xp, gold
        if (boss.hp == 0) {
            player.xp = player.xp + boss.xp;
            player.gold = player.gold + boss.gold;
            console.log("Player awarded %s xp, total xp %s, gold awarded %s", boss.xp, player.xp, boss.gold);
            // TODO: Emit boss defeated award
        }

        emit AttackComplete(boss.hp, player.hp);
    }

    uint256 private nonce = 0;

    function random() internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 5;
        nonce++;
        return randomnumber;
    }

}
