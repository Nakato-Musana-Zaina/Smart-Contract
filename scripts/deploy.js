

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const LandTransaction = await ethers.getContractFactory("LandTransaction");
    const landTransaction = await LandTransaction.deploy();
    await landTransaction.deployed();

    console.log("LandTransaction deployed to:", landTransaction.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
