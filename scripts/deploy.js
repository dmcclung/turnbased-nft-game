const hre = require("hardhat");

async function main() {
  const hp = [3, 1, 1, 5, 100];
  const xp = [4, 2, 2, 4, 100];
  const gold = [5, 2, 4, 20, 100];
  const name = ["Drake", "Slime", "Ghost", "Knight", "Dragon Lord"];
  const image = [
    "https://cdn.wikimg.net/en/strategywiki/images/9/99/Dw_drakee.gif",
    "https://cdn.wikimg.net/en/strategywiki/images/5/57/Dw_slime.gif",
    "https://cdn.wikimg.net/en/strategywiki/images/7/7c/Dw_ghost.gif",
    "https://cdn.wikimg.net/en/strategywiki/images/a/a1/DQ3_sprite_Hero_NES.png",
    "https://cdn.wikimg.net/en/strategywiki/images/0/0e/Dw_dlord1.gif",
  ];

  const Game = await hre.ethers.getContractFactory("Game");
  const game = await Game.deploy(hp, xp, gold, name, image);

  await game.deployed();

  console.log("Game deployed to:", game.address);

  const tx = await game.mintPlayer("Player #1", 3);
  await tx.wait();

  console.log("Minted player", tx.hash);

  const tokenURI = await game.tokenURI(0);
  console.log("Token URI", tokenURI);

  const tx2 = await game.attackBoss();
  await tx2.wait();

  const tx3 = await game.attackBoss();
  await tx3.wait();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
