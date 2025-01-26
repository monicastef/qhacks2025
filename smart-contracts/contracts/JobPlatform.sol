// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IVerifier {
    function verifyProof(bytes calldata proof, uint[] calldata publicSignals) external view returns (bool);
}

contract JobPlatform {
    address public owner;
    IVerifier public verifier; // ZKP verifier contract
    mapping(address => bytes32) public applicantData; // Stores hashes of applicant credentials

    struct Job {
        uint id;
        string title;
        address employer;
        bool active;
    }

    Job[] public jobs;
    mapping(uint => address[]) public jobApplicants;

    event JobPosted(uint jobId, string title, address indexed employer);
    event ApplicationSubmitted(uint jobId, address indexed applicant);

    constructor(address _verifier) {
        owner = msg.sender;
        verifier = IVerifier(_verifier); // Assign the verifier contract
    }

    // Post a job
    function postJob(string calldata title) external {
        jobs.push(Job(jobs.length, title, msg.sender, true));
        emit JobPosted(jobs.length - 1, title, msg.sender);
    }

    // Apply for a job using ZKP
    function applyForJob(uint jobId, bytes32 hashedData, bytes calldata proof, uint[] calldata publicSignals) external {
        require(jobId < jobs.length, "Invalid job ID");
        require(jobs[jobId].active, "Job is no longer active");

        // Verify ZKP proof
        bool valid = verifier.verifyProof(proof, publicSignals);
        require(valid, "Invalid ZKP proof");

        // Save applicant data and track their application
        applicantData[msg.sender] = hashedData;
        jobApplicants[jobId].push(msg.sender);

        emit ApplicationSubmitted(jobId, msg.sender);
    }

    // Deactivate a job
    function deactivateJob(uint jobId) external {
        require(jobs[jobId].employer == msg.sender, "Only the employer can deactivate this job");
        jobs[jobId].active = false;
    }
}
