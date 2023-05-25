// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/BufferRandomizer.sol";
import { MyNFT } from "./mocks/MyNFT.sol";

contract BufferRandomizerTest is Test {

	BufferRandomizer public bufferRandomizer;
	MyNFT public myNFT;

	address public owner = address(0x420);

	event Transfer(address indexed from, address indexed to, uint256 indexed id);

	function basicWeightArray() public pure returns(int16[] memory) {
		int16[] memory buffs = new int16[](25);
		buffs[0] = -20;
		buffs[1] = -15;
		buffs[2] = -15;
		buffs[3] = -10;
		buffs[4] = -10;
		buffs[5] = -10;
		buffs[6] = -5;
		buffs[7] = -5;
		buffs[8] = -5;
		buffs[9] = -5;
		buffs[10] = 0;
		buffs[11] = 0;
		buffs[12] = 0;
		buffs[13] = 0;
		buffs[14] = 0;
		buffs[15] = 5;
		buffs[16] = 5;
		buffs[17] = 5;
		buffs[18] = 5;
		buffs[19] = 10;
		buffs[20] = 10;
		buffs[21] = 10;
		buffs[22] = 15;
		buffs[23] = 15;
		buffs[24] = 20;
		return buffs;
	}

	function setUp() public {
		// deploy NFT mock
		myNFT = new MyNFT("MyNFT", "NFT");
		int16[] memory buffs = basicWeightArray();
		address[] memory nftAddresses = new address[](1);
		nftAddresses[0] = address(myNFT);
		BufferRandomizer.Tier memory tier1 = BufferRandomizer.Tier(1, 5, 20);
		BufferRandomizer.Tier[] memory tiers = new BufferRandomizer.Tier[](1);
		tiers[0] = tier1;
		vm.prank(owner);
		bufferRandomizer = new BufferRandomizer(buffs, nftAddresses, tiers);
	}

	function testGetWeightBuffSize() public {
		int16[] memory buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 25);
	}

	function testBuffOrder() public {
		int16[] memory buffs = bufferRandomizer.getBuffs();
		int16[] memory basicBuffs = basicWeightArray();
		for(uint256 i = 0; i < buffs.length; i++) {
			assertEq(buffs[i], basicBuffs[i]);
		}
	}

	// we are not changing the block conditions, we always get the same output
	function testGetRandomWeight() public {
		address caller = address(0x421);
		uint256 hashAsUint256 = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number),caller)));
		int16[] memory randomNumbers = basicWeightArray();
		uint256 index = hashAsUint256 % randomNumbers.length;
		vm.startPrank(caller);
		int16 weight = bufferRandomizer.getRandomWeight();
		assertEq(weight, randomNumbers[index]);
	}

	// test if owner can add new buff
	function testAddBuff() public {
		int16[] memory buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 25);
		vm.prank(owner);
		bufferRandomizer.addBuff(10);
		buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 26);
		assertEq(buffs[25], 10);
	}

	// test if owner can remove buff
	function testRemoveBuff() public {
		int16[] memory buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 25);
		vm.prank(owner);
		bufferRandomizer.removeBuffAndShift(0);
		buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 24);
		assertEq(buffs[0], -15);
	}

	// test if owner can remove buff not keeping order
	function testRemoveBuffNotKeepOrder() public {
		int16[] memory buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 25);
		vm.prank(owner);
		bufferRandomizer.removeBuffAndReplace(0);
		buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 24);
		assertEq(buffs[0], 20);
	}

	// test if owner can add new tier with random address as NFT address
	function testAddTier() public {
		BufferRandomizer.Tier memory newNFTTier = BufferRandomizer.Tier(3, 1, 35);
		vm.prank(owner);
		bufferRandomizer.addAcceptedNFT(address(0x11), newNFTTier);
		BufferRandomizer.Tier memory tier = bufferRandomizer.getTier(address(0x11));
		assertEq(tier.tier, 3);
		assertEq(tier.mul, 1);
		assertEq(tier.buff, 35);
	}

	// test removal of buff one by one and test if it is removed
	function testRemoveBuffAndShiftOneByOne() public {
		int16[] memory buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 25);
		vm.startPrank(owner);
		for(uint256 i = 0; i < buffs.length; i++) {
			bufferRandomizer.removeBuffAndShift(0);
			buffs = bufferRandomizer.getBuffs();
			assertEq(buffs.length, 25 - i - 1);
			for(uint256 j = 0; j < buffs.length; j++) {
				assertEq(buffs[j], basicWeightArray()[j + i + 1]);
			}
		}
	}

	function testRemoveBuffAndReplaceOneByOne() public {
		int16[] memory buffs = bufferRandomizer.getBuffs();
		assertEq(buffs.length, 25);
		vm.startPrank(owner);
		for(uint256 i = 0; i < buffs.length; i++) {
			bufferRandomizer.removeBuffAndReplace(0);
			buffs = bufferRandomizer.getBuffs();
			assertEq(buffs.length, 25 - i - 1);
			assertEq(buffs[0], basicWeightArray()[basicWeightArray().length - i - 1]);
		}
	}


	function testAcceptNFT() public {
		vm.startPrank(owner);
		myNFT.mint(owner, 1);
		myNFT.approve(address(bufferRandomizer), 1);
		assertEq(bufferRandomizer.isAcceptedNFT(address(myNFT)), true);
		vm.expectEmit(true, true, true, true);
		emit Transfer(address(bufferRandomizer), address(0), 1);
		bufferRandomizer.getRandomBuff(10000, address(myNFT), 1);
	}

	function testRandomValueWithBuff() public {
		// this is deterministic test, we are not changing the block conditions, we always get the same output
		vm.warp(1 days);
		vm.startPrank(owner);
		myNFT.mint(owner, 1);
		myNFT.approve(address(bufferRandomizer), 1);
		assertEq(bufferRandomizer.isAcceptedNFT(address(myNFT)), true);
		vm.expectEmit(true, true, true, true);
		emit Transfer(address(bufferRandomizer), address(0), 1);
		int256 result = bufferRandomizer.getRandomBuff(10000, address(myNFT), 1);
		assertEq(result, 11500);
	}
}
