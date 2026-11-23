// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecureFund {
    address public admin;
    bool private locked;

    struct Campaign {
        uint256 id;
        address owner;
        string title;
        string description;
        uint256 goal;
        uint256 amountRaised;
        bool active;
    }

    struct Donation {
        uint256 id;
        uint256 campaignId;
        address donor;
        uint256 amount;
        uint256 amountUsed;
    }

    uint256 public campaignCount;
    uint256 public donationCount;

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Donation) public donations;
    mapping(address => uint256[]) public userDonations;
    mapping(address => bool) public approvedNGOs;
    mapping(address => mapping(address => bool)) public approvedBeneficiaries;

    event CampaignCreated(
        uint256 indexed id,
        address indexed owner,
        string title,
        uint256 goal
    );
    event DonationReceived(
        uint256 indexed donationId,
        uint256 indexed campaignId,
        address indexed donor,
        uint256 amount
    );
    event FundsDistributed(
        uint256 indexed donationId,
        uint256 indexed campaignId,
        address indexed beneficiary,
        uint256 amountDistributed
    );
    event NGOApprovalUpdated(address indexed ngo, bool approved);
    event BeneficiaryApprovalUpdated(
        address indexed ngo,
        address indexed beneficiary,
        bool approved
    );
    event CampaignDeactivated(uint256 indexed campaignId);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyApprovedNGO() {
        require(approvedNGOs[msg.sender], "NGO is not approved");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "Re-entrancy detected");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        admin = msg.sender;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    function setNGOApproval(address ngo, bool approved) external onlyAdmin {
        require(ngo != address(0), "Invalid NGO address");
        approvedNGOs[ngo] = approved;
        emit NGOApprovalUpdated(ngo, approved);
    }

    function setBeneficiaryApproval(address beneficiary, bool approved)
        external
        onlyApprovedNGO
    {
        require(beneficiary != address(0), "Invalid beneficiary address");
        approvedBeneficiaries[msg.sender][beneficiary] = approved;
        emit BeneficiaryApprovalUpdated(msg.sender, beneficiary, approved);
    }

    function createCampaign(
        string calldata _title,
        string calldata _description,
        uint256 _goal
    ) external onlyApprovedNGO {
        require(bytes(_title).length > 0, "Title is required");
        require(_goal > 0, "Goal must be greater than 0");

        campaignCount++;
        campaigns[campaignCount] = Campaign({
            id: campaignCount,
            owner: msg.sender,
            title: _title,
            description: _description,
            goal: _goal,
            amountRaised: 0,
            active: true
        });

        emit CampaignCreated(campaignCount, msg.sender, _title, _goal);
    }

    function donate(uint256 _campaignId) external payable {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Invalid campaign");
        require(campaigns[_campaignId].active, "Campaign is not active");
        require(msg.value > 0, "Donation must be greater than 0");

        donationCount++;
        donations[donationCount] = Donation({
            id: donationCount,
            campaignId: _campaignId,
            donor: msg.sender,
            amount: msg.value,
            amountUsed: 0
        });
        userDonations[msg.sender].push(donationCount);
        campaigns[_campaignId].amountRaised += msg.value;

        emit DonationReceived(donationCount, _campaignId, msg.sender, msg.value);
    }

    function distributeFunds(
        uint256 _campaignId,
        uint256 _donationId,
        address _beneficiary,
        uint256 _amountToDistribute
    ) external nonReentrant {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Invalid campaign");
        require(_donationId > 0 && _donationId <= donationCount, "Invalid donation");

        Campaign storage campaign = campaigns[_campaignId];
        Donation storage donation = donations[_donationId];

        require(msg.sender == campaign.owner, "Only campaign owner can distribute");
        require(donation.campaignId == _campaignId, "Donation ID mismatch");
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(
            approvedBeneficiaries[campaign.owner][_beneficiary],
            "Beneficiary is not approved by NGO"
        );
        require(_amountToDistribute > 0, "Amount must be greater than 0");

        uint256 remaining = donation.amount - donation.amountUsed;
        require(_amountToDistribute <= remaining, "Insufficient donation balance");
        require(address(this).balance >= _amountToDistribute, "Contract balance insufficient");

        donation.amountUsed += _amountToDistribute;

        (bool success, ) = payable(_beneficiary).call{value: _amountToDistribute}("");
        require(success, "Transfer failed");

        emit FundsDistributed(
            _donationId,
            _campaignId,
            _beneficiary,
            _amountToDistribute
        );
    }

    function deactivateCampaign(uint256 _campaignId) external {
        require(_campaignId > 0 && _campaignId <= campaignCount, "Invalid campaign");
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.owner, "Only campaign owner can deactivate");
        require(campaign.active, "Campaign is already inactive");

        campaign.active = false;
        emit CampaignDeactivated(_campaignId);
    }

    function getAllCampaigns() external view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](campaignCount);
        for (uint256 i = 0; i < campaignCount; i++) {
            allCampaigns[i] = campaigns[i + 1];
        }
        return allCampaigns;
    }

    function getMyDonations() external view returns (Donation[] memory) {
        uint256[] storage donationIds = userDonations[msg.sender];
        Donation[] memory myDonations = new Donation[](donationIds.length);

        for (uint256 i = 0; i < donationIds.length; i++) {
            myDonations[i] = donations[donationIds[i]];
        }
        return myDonations;
    }
}
