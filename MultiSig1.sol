pragma solidity ^0.4.20;



contract MultiSig1 {

    address private walletOwner;
    address[] private contributorsList;
    address[] private openBeneficiariesProposals;
    address[] private approvers= [0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1,
                                  0xFFcf8FDEE72ac11b5c542428B35EEF5769C409f0,
                                  0x22d491Bde2303f2f43325b2108D26f1eAbA1e32b];
    bool flag=true;
    uint private totalFund;
    //uint private approvedFund;
    uint public openFund;



    //mappings
    mapping(address => uint) contributionAmount;
    mapping(address => uint) beneficiaryProposal;
    mapping (address => Proposal) private proposals;
    mapping (address => [uint]) proposalHistory;

        //structures here
    struct Proposal {
      address from;
      uint amount;
      uint8 signatureCount;
      uint8 rejectsignatureCount;
      bool isSubmitted;
      mapping(address => uint) signs;
    }

    //all events here
    event ReceivedContribution(address indexed _contributor, uint _valueInWei);
    event ProposalSubmitted(address indexed _beneficiary, uint _valueInWei);
    event ProposalApproved(address indexed _approver, address indexed _beneficiary, uint _valueInWei);
    event ProposalRejected(address indexed _rejecter, address indexed _beneficiary, uint _valueInWei);
    event WithdrawPerformed(address indexed _beneficiary, uint _valueInWei);


    constructor()  {
        walletOwner = msg.sender;
    }

      function owner() external returns(address)
      {
        return  walletOwner;
      }

      modifier allowedContribution()
      {
          require(flag == true,"contribution should be open");
          _;
      }

      modifier isApprover()
      {
        require(msg.sender==approvers[0] || msg.sender == approvers[1] || msg.sender == approvers[2],"must be signer" );
        _;
      }

  function() payable public allowedContribution
  {
      require(msg.value > 0,"amount should be positive");
      require(address(msg.sender) != 0x0,"shouldn't be invalid address");
      require(msg.sender.balance >= msg.value,"sender should have enough balance to send");
      if(contributionAmount[msg.sender] > 0)
      {
             contributionAmount[msg.sender] += msg.value;
      }
      else
      {

      contributionAmount[msg.sender]=msg.value;
      contributorsList.push(msg.sender);
      }


    emit ReceivedContribution(msg.sender, msg.value);

  }

  function getApprovers() external returns (address[])
  {
      return approvers;
  }

  function endContributionPeriod() external isApprover {
      require(flag == true ,"alredy contribution ended");
      flag=false;
      totalFund = address(this).balance;
      openFund=totalFund;
  }

  function submitProposal(uint _valueInWei) external
  {
      require(_valueInWei > 0,"amount should be greater that zero");
      require(flag ==false,"Contribution is still going on Cant submit proposal");
      require(msg.sender != approvers[0] && msg.sender != approvers[1] && msg.sender != approvers[2], "Signer Cant submit proposal" );
      require(openFund >= _valueInWei,"contract dont have open Fund left");
      uint tenPercent = _valueInWei;
      //require(contributionAmount[msg.sender] >= _valueInWei,"proposal amount should be less then or equal to contributed amount");
      require(tenPercent*10 <= totalFund,"amount should be 10% or less than the total holding of contract");

      Proposal storage props = proposals[msg.sender];
      if(beneficiaryProposal[msg.sender]>0 && props.isSubmitted == true && props.rejectsignatureCount <2 && props.rejectsignatureCount >=0 && props.signatureCount>=0 && props.signatureCount <=2)
      {
          revert("Proposal is already submitted and its under processing");
      }

      if(beneficiaryProposal[msg.sender]>0 && props.isSubmitted == true && props.signatureCount <=1 &&  props.rejectsignatureCount >=2 )
      {
      props.amount=_valueInWei;
      props.signatureCount=0;
      props.rejectsignatureCount=0;
      props.isSubmitted=true;
      proposals[msg.sender]=props;
      beneficiaryProposal[msg.sender] = _valueInWei;
      openBeneficiariesProposals.push(msg.sender);
      openFund -= _valueInWei;
      emit ProposalSubmitted(msg.sender, _valueInWei);

      }

    if(props.isSubmitted == false)
    {

      beneficiaryProposal[msg.sender] = _valueInWei;

      Proposal memory prop;
      prop.from= msg.sender;
      prop.amount=_valueInWei;
      prop.signatureCount=0;
      prop.rejectsignatureCount=0;
      prop.isSubmitted=true;
      proposals[msg.sender]=prop;
      openFund -= _valueInWei;
      openBeneficiariesProposals.push(msg.sender);
      proposalHistory[msg.sender].push(block.number);
    emit ProposalSubmitted(msg.sender, _valueInWei);
    }
    else
    {
        revert("you have already open Proposal pending");
    }

  }

  function getProposalHistory() external view returns ([uint]) {
    return proposalHistory[msg.sender];
  }

  function listOpenBeneficiariesProposals() external view returns (address[])
  {
      return openBeneficiariesProposals;
  }


  function listContributors() external view returns (address[])
  {
      return contributorsList;
  }


  function getContributorAmount(address _contributor) external view returns (uint)
  {
     // require(contributionAmount[_contributor] >0,"you are not a beneficiary");
      return contributionAmount[_contributor];
  }

    /*
   * Returns the value requested by the given beneficiary in his proposal.
   */
  function getBeneficiaryProposal(address _beneficiary) external view returns (uint)
  {
     // require(beneficiaryProposal[_beneficiary] >0,"you are not a beneficiary");
      return beneficiaryProposal[_beneficiary];
  }

    /*
   * Approve the proposal for the given beneficiary
   */
  function approve(address _beneficiary) external isApprover
  {
      require(flag == false,"contribution period havent ended");
     // require(contributionAmount[_beneficiary] > 0,"should be a contributor");
      Proposal storage propSign = proposals[_beneficiary];
      require(propSign.isSubmitted == true,"Proposal must be submited before Approval");
      require(propSign.signs[msg.sender] == 0 ,"signer already signed cant do it again");
      require(propSign.rejectsignatureCount <3,"proposal is rejected by all signers");
      require(propSign.signatureCount <3,"proposal is approved already by all the signers");
      propSign.signs[msg.sender]=1;
      propSign.signatureCount +=1;
      proposals[msg.sender]=propSign;


      emit ProposalApproved(msg.sender,_beneficiary, propSign.amount);

  }


  function reject(address _beneficiary) external isApprover{
      require(flag == false,"contribution havent ended");
      //require(contributionAmount[_beneficiary] > 0, "should be a contributor");
      Proposal storage propRej = proposals[_beneficiary];
      require(propRej.isSubmitted == true,"Proposal must be submited before Approval");
      require(propRej.signs[msg.sender] == 0 ,"signer already signed cant do it again");
      require(propRej.signatureCount <= 3,"proposal is approved already by all the signers");
      require(propRej.rejectsignatureCount <= 3,"proposal is rejected already by all the signers");

      propRej.signs[msg.sender]=2;
      propRej.rejectsignatureCount +=1;
      if(propRej.rejectsignatureCount >= 2)
      {
        for(uint i=0; i<openBeneficiariesProposals.length; i++)
          {
              if(openBeneficiariesProposals[i]== msg.sender)
              {
                  openBeneficiariesProposals[i]=openBeneficiariesProposals[openBeneficiariesProposals.length-1];
                  delete openBeneficiariesProposals[openBeneficiariesProposals.length-1];
                  openBeneficiariesProposals.length--;
                  break;
              }
          }
          beneficiaryProposal[msg.sender]=0;
          openFund += propRej.amount;


          propRej.amount=0;
          propRej.signatureCount=0;
          propRej.rejectsignatureCount=0;

      }
     proposals[msg.sender]=propRej;

      emit ProposalRejected(msg.sender,_beneficiary, propRej.amount);

  }

      /*
   * Withdraw the specified value in Wei from the wallet.
   * The beneficiary can withdraw any value less than or equal the value
   * he/she proposed. If he/she wants to withdraw more, a new proposal
   * should be sent.
   *
   */
  function withdraw(uint _valueInWei) external
  {
      require(flag == false,"contribution havent ended");
      Proposal storage propwithdraw = proposals[msg.sender];
      require(propwithdraw.from == msg.sender, "you should be beneficiary to withdraw");
      require(propwithdraw.isSubmitted == true, "proposal must be submit before Withdraw");
      require(propwithdraw.signatureCount>=2,"you dont have enough votes to withdraw");
      require(propwithdraw.rejectsignatureCount < 2,"majority of signers voted reject");
      require(propwithdraw.amount >= _valueInWei,"you are not allowed then that you have proposed");
      propwithdraw.amount -=_valueInWei;
      totalFund -=_valueInWei;
      if(propwithdraw.amount == 0)
      {
          for(uint i=0; i<openBeneficiariesProposals.length; i++)
          {
              if(openBeneficiariesProposals[i]== msg.sender)
              {
                  openBeneficiariesProposals[i]=openBeneficiariesProposals[openBeneficiariesProposals.length-1];
                  delete openBeneficiariesProposals[openBeneficiariesProposals.length-1];
                  openBeneficiariesProposals.length--;
                  break;
              }
          }
            msg.sender.transfer(_valueInWei);
            propwithdraw.signs[0xfA3C6a1d480A14c546F12cdBB6d1BaCBf02A1610]=0;
            propwithdraw.signs[0x2f47343208d8Db38A64f49d7384Ce70367FC98c0]=0;
            propwithdraw.signs[0x7c0e7b2418141F492653C6bF9ceD144c338Ba740]=0;
            delete proposals[msg.sender];
      }
      else
      {

         proposals[msg.sender]=propwithdraw;
         msg.sender.transfer(_valueInWei);
      }
        emit WithdrawPerformed(msg.sender, _valueInWei);

  }

  function getSignerVote(address _signer, address _beneficiary) view external returns(uint)
  {
            Proposal storage propSigned = proposals[_beneficiary];
            return propSigned.signs[_signer];
  }


}
