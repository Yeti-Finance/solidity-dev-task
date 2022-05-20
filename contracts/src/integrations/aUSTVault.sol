// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "src/Vault.sol";
import {IAnchorRouter} from "src/interfaces/IAnchorRouter.sol";

/** 
 * @notice aUSTVault is the vault token for UST token rewards.
 * It collects rewards from the anchor router and distributes them to the
 * swap so that it can autocompound. 
 */
contract aUSTVault is Vault {

    IAnchorRouter public router;
    address public aUST = 0xaB9A04808167C170A9EC4f8a87a0cD781ebcd55e;

    function initialize(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint256 _adminFee,
        uint256 _callerFee,
        uint256 _maxReinvestStale,
        address _WAVAX,
        address _router
    ) public {
        initialize(_underlying,
                    _name,
                    _symbol,
                    _adminFee,
                    _callerFee,
                    _maxReinvestStale,
                    _WAVAX
                    );
        
        router = IAnchorRouter(_router);
        underlying.approve(_router, MAX_INT);
    }
    
    function _triggerDepositAction(uint256 _amt) internal override {
        router.depositStable(_amt);
    }

    function _triggerWithdrawAction(uint256 amtToReturn) internal override {
        router.redeemStable(amtToReturn);
    }

    function _pullRewards() internal override {
        router.redeemStable(IERC20(aUST).balanceOf(address(this)));
    }
}
