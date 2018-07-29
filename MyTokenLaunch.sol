pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// interface ERC223Receiver {
//     function tokenFallback(address _sender, uint _value, bytes _data);
// }

contract MyTokenLaunch is ERC20Interface {
    string public name = "MANDY";
    string public symbol = "MDY";
    uint8 public decimals = 0;
    uint public totalSupply = 100;
    uint public supplyLeft;
    uint exchangeRatePerEther = 2;

    mapping(address => uint) public balanceOf;
    // allowances[spender][tokenholder]
    mapping(address => mapping(address => uint)) allowances;

    constructor() public {
        // balanceOf[msg.sender] = totalSupply;
        supplyLeft = totalSupply;
        emit Transfer(address(this), msg.sender, totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balanceOf[tokenOwner];
    }

    function transfer(address to, uint token) public returns (bool success) {
        require(balanceOf[msg.sender] >= token, "You dont have enough tokens to send");
        require(token > 0, "specify some tokens to transfer");
        balanceOf[msg.sender] -= token;
        balanceOf[to] += token;
        emit Transfer(msg.sender, to, token);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(balanceOf[msg.sender] >= tokens, "You dont have enough tokens to send");
        require(tokens > 0, "specify some tokens to transfer");
        balanceOf[msg.sender] -= tokens;
        allowances[spender][msg.sender] += tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(allowances[msg.sender][from] >= tokens, "You dont have enough allowance to transfer");
        require(tokens > 0, "specify some tokens to transfer");
        allowances[msg.sender][from] -= tokens;
        balanceOf[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowances[spender][tokenOwner];
    }

    function buyToken(uint _token) public payable {
        require(_token <= supplyLeft, "No more tokens to distribute");
        if(supplyLeft - _token > totalSupply/2) {
            require(_token*(1 ether/2) <= msg.value, "You havent send enough ether 1");
            address(msg.sender).transfer(msg.value - _token*(1 ether/2));
            balanceOf[msg.sender] += _token;
            supplyLeft -= _token;
        } else if(supplyLeft <= totalSupply/2) {
            require(_token <= msg.value, "You havent send enough ether 2");
            address(msg.sender).transfer(msg.value - _token*1 ether);
            balanceOf[msg.sender] += _token;
            supplyLeft -= _token;
        } else {
            uint value = (supplyLeft - totalSupply/2)*(1 ether/2) + (_token -supplyLeft + totalSupply/2)* 1 ether;
            require(msg.value >= value, "You dont send enough ether 3");
            address(msg.sender).transfer(msg.value - value);
            balanceOf[msg.sender] += _token;
            supplyLeft -= _token;
        }
    }

    function () public payable {
        uint etherReceived = msg.value/10**18;
        if(supplyLeft > totalSupply/2 && supplyLeft - totalSupply/2 > etherReceived*2) {
            buyToken(etherReceived*2);
        } else if(supplyLeft <= totalSupply/2) {
            buyToken(etherReceived);
        } else {
            uint ether5 = (supplyLeft - totalSupply/2);
            uint ether10 = etherReceived - ether5/2;
            if(ether5+ether10 >= supplyLeft) {
                buyToken(supplyLeft);
            } else {
                buyToken(ether5 + ether10);
            }
        }
    }

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}
