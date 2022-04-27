## Task:

If you have not done so already, please read over README.md to get a better understanding of the project structure. 

At Yeti Finance, we believe the interview process should closely reflect the work that you will be doing on the job rather than some abstract leetcode-esque coding challenge. As such our dev evaluation task is a reflection of what we are actively working on at present.

Your task will be to write your own integration for the Anchor strategy. Fill in the skeleton located at contracts/src/integrations/aUSTVault.sol. Optionally, you can also create relevant test cases on your own in src/test.

The Anchor strategy consists of a yield bearing stable coin position. Users deposit [Wormhole UST Token](https://snowtrace.io/token/0xb599c3590F42f8F995ECfa0f85D2980B76862fc1)
 into the [Anchor protocol](https://app.anchorprotocol.com/earn) and recieve [aUST Token](https://snowtrace.io/token/0xab9a04808167c170a9ec4f8a87a0cd781ebcd55e) as a depository receipt. aUST is redeemable for a monotonically increasing amount of UST through the Anchor protocol.

 Some quirks to note:
 - Wormhole UST is bridged over from the Terra blockchain. There exists a liquid market on Curve and Trader Joe to trade UST for any other asset such as USDC or AVAX.
 - aUST is the depository receipt for the Anchor protocol. There is no liquid market to trade aUST for any other token on DEXs
 - The deposit and redemption process between UST \<-\> aUST is **NOT** atomic unlike other lending protocols such as Aave or Benqi. This means after you deposit UST into Anchor, you must wait a few blocks until a relayer sends your address aUST and vice versa

### Deliverable: 

You will design an integration for this strategy in which the user will deposit UST **OR** aUST (we leave the choice of underlying asset to the developer) and earn yield from the anchor strategy. The integration must also be able to accurately track yield generation to allow the admin to take a fee from the yield.

Something to consider:

Users **MUST** be able to redeem any amount of their Vault token for the underlying token at any time. This precludes the naive implementation of having the vault token deposit plain UST on behalf of their user and redeem when triggered as the redemption will not be atomic.