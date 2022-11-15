
const hre = require("hardhat");

async function main() {

  const ProposalFacory = await hre.ethers.getContractFactory("ProposalFactory");
  const pf = await ProposalFacory.deploy("0xa2c67EaC1Cc3DD40441C9f631fb53D3c5BA2eC41");

  await pf.deployed();

  console.log(
    `deployed to ${pf.address}`
  );

  const Main = await hre.ethers.getContractFactory("Main");
  const main = await Main.deploy();

  await main.deployed();

  console.log(
    `deployed to ${main.address}`
  );

  const Proposal = await hre.ethers.getContractFactory("Proposal");
  const proposal = await Proposal.deploy();

  await proposal.deployed();

  console.log(
    `deployed to ${proposal.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

//0x6516f28C1FF4FBb7f0290F368675d03D993DdB69 mumbai
//0x7BEACEe32476f559B1E34ac5137e7d6E25021EBb factory
//0x34682530E9706F2eAA641b06Ad0f629417dB3C94 factory 2
//0x9fdc307e0c71AF9C34DAC361ab7D7Dc052295e14 main
//0x87979B95fe5242414df839b637eD1D85E1944F48 proposal
//0x04613a9730EbBBF229de64413d3e4972aa9e01cf remix mumbai
//0x7A9f65E8989d92ca200CE08839d90F3411088757
