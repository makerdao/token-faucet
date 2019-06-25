pragma solidity ^0.5.4;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./RestrictedTokenFaucet.sol";

contract FaucetUser {
    DSToken token;
    RestrictedTokenFaucet faucet;

    constructor(DSToken token_, RestrictedTokenFaucet faucet_) public {
        token = token_;
        faucet = faucet_;
    }

    function doGulp() public {
        faucet.gulp(address(token));
    }

    function doUndo(address usr) public {
        faucet.undo(usr, address(token));
    }

    function doHope(address usr) public {
        faucet.hope(usr);
    }

    function doNope(address usr) public {
        faucet.nope(usr);
    }

    function doShut() public {
        faucet.shut(ERC20Like(address(this)));
    }

    function doSetAmt(uint amt) public {
        faucet.setamt(amt);
    }
}

contract RestrictedTokenFaucetTest is DSTest {
    RestrictedTokenFaucet faucet;
    DSToken token;
    FaucetUser user1;
    FaucetUser user2;
    address self;

    function setUp() public {
        faucet = new RestrictedTokenFaucet(20);
        token = new DSToken("TEST");
        token.mint(address(faucet), 1000000);
        user1 = new FaucetUser(token, faucet);
        user2 = new FaucetUser(token, faucet);
        self = address(this);
    }

    function testSetupPrecondition() public {
        assertEq(faucet.wards(self), 1);
        assertEq(faucet.list(self), 1);
        assertEq(faucet.list(address(user1)), 0);
        assertEq(faucet.list(address(user2)), 0);
    }

    function testFail_gulp_no_auth_list() public {
        FaucetUser(user2).doGulp();
    }

    function test_gulp_auth_list() public {
        faucet.hope(address(user1));
        assertEq(faucet.list(address(user1)), 1);
        assertEq(token.balanceOf(address(user1)), 0);
        user1.doGulp();
        assertEq(token.balanceOf(address(user1)), 20);
    }

    function test_gulp_auth_list_all() public {
        faucet.hope(address(0));
        assertEq(faucet.list(address(0)), 1);
        assertEq(faucet.list(address(user1)), 0);
        assertEq(token.balanceOf(address(user1)), 0);
        user1.doGulp();
        assertEq(token.balanceOf(address(user1)), 20);
    }

    function testFail_hope_not_owner() public {
        user1.doHope(address(123));
    }

    function testFail_nope_not_owner() public {
        user1.doNope(address(this));
    }

    function test_gulp_multiple() public {
        address[] memory addrs = new address[](4);
        addrs[0] = address(123);
        faucet.hope(addrs[0]);
        addrs[1] = address(234);
        faucet.hope(addrs[1]);
        addrs[2] = address(567);
        faucet.hope(addrs[2]);
        addrs[3] = address(890);
        faucet.hope(addrs[3]);
        assertEq(token.balanceOf(address(123)), 0);
        assertEq(token.balanceOf(address(234)), 0);
        assertEq(token.balanceOf(address(567)), 0);
        assertEq(token.balanceOf(address(890)), 0);
        faucet.gulp(address(token), addrs);
        assertEq(token.balanceOf(address(123)), 20);
        assertEq(token.balanceOf(address(234)), 20);
        assertEq(token.balanceOf(address(567)), 20);
        assertEq(token.balanceOf(address(890)), 20);
    }

    function testFail_gulp_multiple() public {
        address[] memory addrs = new address[](2);
        addrs[0] = address(this); // already hope'ed
        addrs[2] = address(234); // not hope'ed
        faucet.gulp(address(token), addrs);
    }

    function testFail_gulp_twice() public {
        faucet.gulp(address(token));
        faucet.gulp(address(token));
    }

    function test_undo() public {
        assertEq(token.balanceOf(address(this)), 0);

        faucet.gulp(address(token));
        assertEq(token.balanceOf(address(this)), 20);
        assertTrue(faucet.done(address(this), address(token)));

        faucet.undo(address(this), address(token));
        assertTrue(!faucet.done(address(this), address(token)));

        faucet.gulp(address(token));
        assertEq(token.balanceOf(address(this)), 40);
    }

    function testFail_undo_not_owner() public {
        faucet.gulp(address(token));
        assertTrue(faucet.done(address(this), address(token)));
        user1.doUndo(address(this));
    }

    function test_shut() public {
        assertEq(token.balanceOf(address(this)), 0);
        faucet.shut(ERC20Like(address(token)));
        assertEq(token.balanceOf(address(this)), 1000000);
    }

    function testFail_shut_not_owner() public {
        user1.doShut();
    }

    function test_setamt() public {
        assertEq(faucet.amt(), 20);
        faucet.setamt(10);
        assertEq(faucet.amt(), 10);
    }

    function testFail_setamt_not_owner() public {
        user1.doSetAmt(10);
    }
}
