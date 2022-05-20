// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/stdlib.sol";
import "forge-std/Vm.sol";
import "src/integrations/aUSTVault.sol";
import "./TestERC20.sol";
import "./Utils.sol";


// This test covers integration for comp-like vaults

contract TestsaUSTVault is DSTest {

    uint constant ADMINFEE=100;
    uint constant CALLERFEE=10;
    uint constant MAX_REINVEST_STALE= 1 hours;
    uint constant MAX_INT= 2**256 - 1;
    Vm public constant vm = Vm(HEVM_ADDRESS);

    IERC20 constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7); //WAVAX
    address constant wavaxHolder = 0xBBff2A8ec8D702E61faAcCF7cf705968BB6a5baB; 

    IERC20 constant UST = IERC20(0xb599c3590F42f8F995ECfa0f85D2980B76862fc1); //UST
    IERC20 constant aUST = IERC20(0xaB9A04808167C170A9EC4f8a87a0cD781ebcd55e); //aUST
    address constant USTHolder = 0x218Eb2694357FD7Dfd79Da8eeefF3049c4fbaC4E;

    address constant joePair = 0xA389f9430876455C36478DeEa9769B7Ca4E3DDB1; // USDC-WAVAX
    address constant joeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address constant aave = 0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;
    address constant aaveV3 = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    
    aUSTVault public vault;
    uint public underlyingBalance;
    function setUp() public {
        vault = new aUSTVault();
        vault.initialize(
            address(UST),
            "Vault",
            "VAULT",
            ADMINFEE,
            CALLERFEE,
            MAX_REINVEST_STALE,
            address(WAVAX),
            0xcEF9E167d3f8806771e9bac1d4a0d568c39a9388);

        vault.setJoeRouter(joeRouter);
        vault.setAAVE(aave, aaveV3);
        vault.setApprovals(address(WAVAX), joeRouter, MAX_INT);
        vault.setApprovals(address(UST), joeRouter, MAX_INT);
        
        vault.setApprovals(address(WAVAX), aave, MAX_INT);
        vault.setApprovals(address(UST), aave, MAX_INT);
        vault.setApprovals(address(UST), 0xcEF9E167d3f8806771e9bac1d4a0d568c39a9388, MAX_INT);

        vm.startPrank(wavaxHolder);
        WAVAX.transfer(address(this), WAVAX.balanceOf(wavaxHolder));
        vm.stopPrank();
        vm.startPrank(USTHolder);
        UST.transfer(address(this), UST.balanceOf(USTHolder));
        vm.stopPrank();

        vault.pushRewardToken(address(WAVAX));
        vault.pushRewardToken(address(UST));

        UST.approve(address(vault), MAX_INT);
        underlyingBalance=UST.balanceOf(address(this));
        vm.warp(1647861775-80 days);
    }


    function testVanillaDeposit(uint96 amt) public returns (uint) {
        // uint amt = 1e18;
        if (amt > underlyingBalance || amt<vault.MIN_FIRST_MINT()) {
            return 0;
        }
        uint preBalance = vault.balanceOf(address(this));
        vault.deposit(amt);
        uint postBalance = vault.balanceOf(address(this));
        assertTrue(postBalance == preBalance + amt - vault.FIRST_DONATION());
        return amt;
    }

    function testViewFuncs1(uint96 amt) public {
        if (amt > underlyingBalance || amt<vault.MIN_FIRST_MINT()) {
            return;
        }
        assertTrue(vault.receiptPerUnderlying() == 1e18);
        assertTrue(vault.underlyingPerReceipt() == 1e18);
        assertTrue(vault.totalSupply() == 0);
        vault.deposit(amt);
        assertTrue(vault.totalSupply() == amt);
        assertTrue(vault.receiptPerUnderlying() == 1e18);
        assertTrue(vault.underlyingPerReceipt() == 1e18);
    }


    function testVanillaDepositNredeem(uint96 amt) public {
        if (amt > underlyingBalance || amt<vault.MIN_FIRST_MINT()) {
            return;
        }
        vault.deposit(amt);
        uint preBalanceVault = vault.balanceOf(address(this));
        uint preBalanceToken = UST.balanceOf(address(this));
        vault.redeem(preBalanceVault);
        uint postBalanceVault = vault.balanceOf(address(this));
        uint postBalanceToken = UST.balanceOf(address(this));
        console.log(postBalanceVault, preBalanceVault);
        console.log(postBalanceToken, preBalanceToken);
        assertTrue(postBalanceVault == preBalanceVault - (amt - vault.FIRST_DONATION()));
        assertTrue(postBalanceToken == preBalanceToken + (amt - vault.FIRST_DONATION()));
    }
    function testVanillaDepositNCompoundOnly(uint96 amt) public returns (uint) {
        // uint amt = 1e18;
        if (amt > underlyingBalance || amt<1e5*vault.MIN_FIRST_MINT()) {
            return 0;
        }
        vault.deposit(amt);
        uint preBalance = vault.underlyingPerReceipt();
        vm.warp(block.timestamp+100 days);
        vault.compound();
        uint postBalance = vault.underlyingPerReceipt();
        assertTrue(postBalance > preBalance);
        return amt;
    }
    function testVanillaDepositNCompoundredeem(uint96 amt) public returns (uint) {
        // uint amt = 1e18;
        if (amt > underlyingBalance || amt<vault.MIN_FIRST_MINT()) {
            return 0;
        }
        vault.deposit(amt);
        vm.warp(block.timestamp+100 days);
        vault.compound();
        vault.redeem(vault.balanceOf(address(this)));
        assertTrue(amt < UST.balanceOf(address(this)));
        return amt;
    }
}
