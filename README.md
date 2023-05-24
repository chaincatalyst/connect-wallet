# BufferRandomizer


The **BufferRandomizer** contract randomizes integer weights and can apply optional buffs if a user sacrifices a **Non-Fungible Token** (NFT). 
These buffs are determined by the **NFT tier**, which defines a multiplier and a buff value that can be added to the pool of weights for a single randomization.

## Setup

The contract is initialized with three arrays buffs, NFT addresses, and NFT tiers.

- ```buffs```: An array of integer weights (buffs) that the contract can randomize.
- ```nftAddresses```: An array of NFT contract addresses. Each address has a corresponding tier.
- ```tiers```: An array of tiers. 

### Tier Struct

- ```tier```: The tier of the NFT. This is used to organize the buff and multiplier.
- ```mul```: The multiplier for the buff. This is used to determine the buff and multiplier.
- ```buff```: The buff value. This is used to determine the buff and multiplier.


```solidity
   struct Tier {
	uint8 tier;
	uint8 mul;
	int16 buff;
   }
```


### Functions

- ```getRandomWeight```: Returns a random weight from the pool of weights.
- ```getRandomBuff```: Returns a base value multiplied by a random weight from the pool of weights, optionally modified by a buff associated with an NFT. If the NFT address is not zero, the contract uses the _getRandomWeightWithNFTBuffer function, otherwise it uses _getRandomWeight.
- ```addBuff```: Adds a buff to the pool of weights. Only callable by the owner.
- ```removeBuffAndReplace```: Removes a buff from the pool of weights by index and replaces it with the last buff in the array. Only callable by the owner.
- ```removeBuffAndShift```: Removes a buff from the pool of weights by index and shifts all subsequent buffs to fill the gap. Only callable by the owner.
- ```getBuffs```: Returns the entire pool of weights.
- ```getBuff```: Returns a buff from the pool of weights by index.
- ```addAcceptedNFT```: Adds an NFT and its associated tier to the contract. Only callable by the owner.
- ```getTier```: Returns the tier associated with an NFT address.

### Errors

- ```NotOwner```: Emitted when a function restricted to the owner is called by a different address.
- ```IndexOutOfBounds```: Emitted when an index is out of the bounds of the buffs array.
- ```InvalidBaseValue```: Emitted when the base value in getRandomBuff is zero.
- ```InvalidTier```: Emitted when the NFT tier is zero in _getRandomWeightWithNFTBuffer.
- ```InvalidWeights```: Emitted when there are no weights in the pool in getRandomBuff.


## Notes

- The contract uses integer weights instead of probabilities or percentages. This allows for more variability in weights while avoiding the complexities of fractional arithmetic in Solidity.
- Buffs associated with NFTs are optional and only applied if the user sacrifices an NFT.
- The contract burns the NFT when applying a buff.
- The contract owner can add and remove weights.

## More notes - This may not be suitable for all use cases

- The randomness in this contract is not truly random, as it uses the keccak256 hash function for pseudo-randomness. This is ok for most lower value use cases, but if you need true randomness, you should use an oracle.
- This contract suffers from **Modulo Bias** and don't try to fix it. You can change the weights such this is minimized. I don't think this is a big deal for most use cases.