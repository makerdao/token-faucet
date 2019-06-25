pragma solidity >=0.5.0;

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external; // return bool?
}

contract RestrictedTokenFaucet {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public auth { wards[guy] = 1; }
    function deny(address guy) public auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "token-faucet/no-auth");
        _;
    }
    // --- Gulp Whitelist ---
    mapping (address => uint) public list;
    function hope(address guy) public auth { list[guy] = 1; }
    function nope(address guy) public auth { list[guy] = 0; }

    uint256 public amt;
    mapping (address => mapping (address => bool)) public done;

    constructor (uint256 amt_) public {
        wards[msg.sender] = 1;
        list[msg.sender] = 1;
        amt = amt_;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "token-faucet/mul-overflow");
    }

    function gulp(address gem) external  {
        require(list[address(0)] == 1 || list[msg.sender] == 1, "token-faucet/no-whitelist");
        require(!done[msg.sender][gem], "token-faucet/already-used_faucet");
        require(ERC20Like(gem).balanceOf(address(this)) >= amt, "token-faucet/not-enough-balance");
        done[msg.sender][gem] = true;
        ERC20Like(gem).transfer(msg.sender, amt);
    }

    function gulp(address gem, address[] calldata addrs) external {
        require(ERC20Like(gem).balanceOf(address(this)) >= mul(amt, addrs.length), "token-faucet/not-enough-balance");

        for (uint i = 0; i < addrs.length; i++) {
            require(list[address(0)] == 1 || list[addrs[i]] == 1, "token-faucet/no-whitelist");
            require(!done[addrs[i]][address(gem)], "token-faucet/already-used-faucet");
            done[addrs[i]][address(gem)] = true;
            ERC20Like(gem).transfer(addrs[i], amt);
        }
    }

    function shut(ERC20Like gem) external auth {
        gem.transfer(msg.sender, gem.balanceOf(address(this)));
    }

    function undo(address usr, address gem) external auth {
        done[usr][gem] = false;
    }

    function setamt(uint256 amt_) external auth {
        amt = amt_;
    }
}
