pragma solidity >=0.5.0;

interface ERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external; // return bool?
}

contract RestrictedTokenFaucet {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public isOwner { wards[guy] = 1; }
    function deny(address guy) public isOwner { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }
    modifier isOwner { require(owner == msg.sender); _; }
    address public owner;

    uint256 public amt;
    mapping (address => mapping (address => bool)) public done;

    constructor (uint256 amt_) public {
        wards[msg.sender] = 1;
        owner = msg.sender;
        amt = amt_;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function gulp(address gem) external auth {
        require(!done[msg.sender][address(gem)], "token-faucet: already used faucet");
        require(ERC20Like(gem).balanceOf(address(this)) >= amt, "token-faucet: not enough balance");
        done[msg.sender][address(gem)] = true;
        ERC20Like(gem).transfer(msg.sender, amt);
    }

    function gulp(address gem, address payable[] calldata addrs) external {
        require(ERC20Like(gem).balanceOf(address(this)) >= mul(amt, addrs.length), "token-faucet: not enough balance");

        for (uint i = 0; i < addrs.length; i++) {
            require(wards[addrs[i]] == 1, "token-faucet: address not authed");
            require(!done[addrs[i]][address(gem)], "token-faucet: already used faucet");
            done[addrs[i]][address(gem)] = true;
            ERC20Like(gem).transfer(addrs[i], amt);
        }
    }

    function shut(ERC20Like gem) external isOwner {
        gem.transfer(msg.sender, gem.balanceOf(address(this)));
    }

    function unDone(address usr, address gem) external isOwner {
        done[usr][gem] = false;
    }

    function setamt(uint256 amt_) external isOwner {
        amt = amt_;
    }
}
