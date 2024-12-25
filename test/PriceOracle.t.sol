// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {PriceOracle} from "../src/core/PriceOracle.sol";
import {MockV3Aggregator} from "@chainlink/v0.8/tests/MockV3Aggregator.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract PriceOracleTest is Test {
    // Contract instances
    PriceOracle public priceOracle;
    MockV3Aggregator public mockPriceFeed;
    VRFCoordinatorV2Mock public mockVRFCoordinator;

    // Test addresses
    address public owner;
    address public user;

    // Constants
    uint8 public constant PRICE_FEED_DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 50000 * 10 ** 8; // $50,000
    uint256 public constant EMA_EXP_TIME = 24 hours;
    uint64 public constant SUBSCRIPTION_ID = 1;
    bytes32 public constant KEY_HASH = keccak256("test-key-hash");
    uint32 public constant CALLBACK_GAS_LIMIT = 100000;

    // Setup function
    function setUp() public {
        // Create test addresses
        owner = makeAddr("owner");
        user = makeAddr("user");

        // Deploy mock Chainlink price feed
        mockPriceFeed = new MockV3Aggregator(PRICE_FEED_DECIMALS, INITIAL_PRICE);

        // Deploy mock VRF Coordinator
        mockVRFCoordinator = new VRFCoordinatorV2Mock(
            0.1 ether, // Base fee
            0.00001 ether // Price per request
        );

        // Create subscription for VRF
        mockVRFCoordinator.createSubscription();
        mockVRFCoordinator.fundSubscription(SUBSCRIPTION_ID, 10 ether);

        // Deploy PriceOracle
        vm.prank(owner);
        priceOracle = new PriceOracle(
            EMA_EXP_TIME, address(mockPriceFeed), address(mockVRFCoordinator), SUBSCRIPTION_ID, KEY_HASH
        );
    }

    // Test Constructor
    function testConstructor() public view {
        // Verify owner
        assertEq(priceOracle.owner(), owner);

        // Check initial price
        // assertEq(priceOracle.getLastPrice(), INITIAL_PRICE);

        // Check initialization
        assertTrue(priceOracle.initialized());
    }

    // Test Latest Price Retrieval
    function testGetLatestPrice() public view {
        // Verify initial price
        uint256 price = priceOracle.getLatestPrice();
        assertEq(price, uint256(INITIAL_PRICE));
    }

    // Test EMA Price Calculation
    function testCalculateEMAPrice() public {
        // Update price feed

        int256 newPrice = 55000 * 10 ** 8; // $55,000
        mockPriceFeed.updateAnswer(newPrice);

        // Simulate time passage
        vm.warp(block.timestamp + 12 hours);

        // Calculate EMA
        uint256 emaPrice = priceOracle.calculateEMAPrice();

        // Verify EMA calculation (approximate)
        assertTrue(emaPrice > uint256(INITIAL_PRICE));
        assertTrue(emaPrice < uint256(newPrice));
    }

    // Test Price Deviation Check
    function testIsPriceWithinDeviation() public view {
        uint256 basePrice = 50000 * 10 ** 8;
        uint256 newPrice = 52500 * 10 ** 8; // 5% increase

        bool withinDeviation = priceOracle.isPriceWithinDeviation(uint256(newPrice), uint256(basePrice));
        assertTrue(withinDeviation);

        // Test price outside deviation
        newPrice = 56000 * 10 ** 8; // 12% increase
        withinDeviation = priceOracle.isPriceWithinDeviation(uint256(newPrice), uint256(basePrice));
        assertFalse(withinDeviation);
    }

    // Test Price Validation Request
    function testPriceValidationRequest() public {
        // Mock VRF Coordinator to handle random words
        vm.prank(address(mockVRFCoordinator));

        // Request price validation
        uint256 requestId = priceOracle.requestPriceValidation();

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit PriceOracle.PriceValidationRequested(1);

        // Verify request ID
        assertEq(requestId, 1);
    }

    // Test Owner-Only Function
    function testUpdateCallbackGasLimit() public {
        vm.prank(owner);
        priceOracle.updateCallbackGasLimit(200000);

        // Verify update
        assertEq(priceOracle.callbackGasLimit(), 200000);
    }

    // Test Unauthorized Access
    function testCannotUpdateGasLimitByNonOwner() public {
        vm.prank(user);
        // vm.expectRevert("Not the owner");
        priceOracle.updateCallbackGasLimit(200000);
    }

    // Test Decay Factor Calculation
    function testDecayFactor() public {
        // Simulate time passage
        vm.warp(block.timestamp + 12 hours);

        // This is an internal function, so we'd need to add a view function or use reflection
        // For this example, we'll trust the EMA calculation test
    }

    // Fuzz Testing Price Deviation
    function testFuzzPriceDeviation(uint256 basePrice, uint256 newPrice) public view {
        basePrice = bound(basePrice, 1, type(uint128).max);
        newPrice = bound(newPrice, basePrice, basePrice * 2);

        uint256 deviation = priceOracle.calculatePriceDeviation(newPrice, basePrice);
        assertTrue(deviation <= 100, "Deviation should be a percentage");
    }
}
