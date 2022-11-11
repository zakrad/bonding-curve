
const hre = require("hardhat");

async function main() {

  const ProposalFacory = await hre.ethers.getContractFactory("ProposalFactory");
  const pf = await ProposalFacory.deploy("0xa2c67EaC1Cc3DD40441C9f631fb53D3c5BA2eC41");

  await pf.deployed();

  console.log(
    `deployed to ${pf.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

//0x6516f28C1FF4FBb7f0290F368675d03D993DdB69 mumbai
//0x04613a9730EbBBF229de64413d3e4972aa9e01cf remix mumbai