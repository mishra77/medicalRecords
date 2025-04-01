// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import security protection against reentrancy attacks
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract medicalRecords is ReentrancyGuard {
    // The main admin address that controls the contract
    address public admin;
    
    // Counters for tracking how many entities exist
    uint256 public doctorCount;
    uint256 public patientCount;
    uint256 public medicineCount;

    // Stores all info about a doctor
    struct Doctor {
        address doctorAddress;  // Doctor's wallet address
        uint256 doctorId;       // Unique ID number
        string name;            // Doctor's full name
        string qualification;   // Their medical qualifications
        string workplace;       // Where they work
        string certificationHash; // IPFS link to their certifications
        bool isActive;          // If they can use the system
    }

    // Stores all info about a patient
    struct Patient {
        address patientAddress; // Patient's wallet address
        uint256 patientId;      // Unique ID number
        string name;            // Patient's full name
        uint8 age;              // Patient's age
        string[] diseases;      // List of their medical conditions
        string[] recordHashes;  // IPFS links to medical records
        bool isActive;          // If their record is active
    }

    // Stores all info about a medicine
    struct Medicine {
        uint256 medicineId;     // Unique ID number
        string name;            // Medicine name
        string expiryDate;      // When it expires
        string dosage;         // How to take it
        uint256 price;          // Cost in wei
        bool isActive;          // If it can be prescribed
    }

    // Storage areas for all data
    mapping(uint256 => Doctor) public doctors;                  // All doctors by ID
    mapping(uint256 => Patient) public patients;                // All patients by ID
    mapping(uint256 => Medicine) public medicines;              // All medicines by ID
    mapping(uint256 => uint256[]) public prescriptions;         // Patient ID to medicine IDs
    mapping(uint256 => mapping(string => bool)) private _existingRecords;  // Tracks patient records
    mapping(uint256 => mapping(string => bool)) private _existingDiseases; // Tracks patient diseases
    mapping(uint256 => mapping(uint256 => bool)) public doctorPatientAssignments; // Which doctors can access which patients

    // Events for logging important actions
    event DoctorRegistered(uint256 indexed doctorId, address indexed doctorAddress);
    event DoctorUpdated(uint256 indexed doctorId);
    event DoctorDeactivated(uint256 indexed doctorId);
    event DoctorCertificationUpdated(uint256 indexed doctorId, string ipfsHash);
    event PatientRegistered(uint256 indexed patientId, address indexed patientAddress);
    event PatientUpdated(uint256 indexed patientId);
    event PatientDeactivated(uint256 indexed patientId);
    event MedicineAdded(uint256 indexed medicineId);
    event MedicineUpdated(uint256 indexed medicineId);
    event MedicineDeactivated(uint256 indexed medicineId);
    event RecordAdded(uint256 indexed patientId, string recordHash);
    event DiseaseAdded(uint256 indexed patientId, string disease);
    event PrescriptionAdded(uint256 indexed patientId, uint256 indexed medicineId);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event DoctorAssigned(uint256 indexed doctorId, uint256 indexed patientId);

    // Only the admin can call this
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can do this");
        _;
    }

    // Only a specific doctor can call this
    modifier onlyDoctor(uint256 doctorId) {
        require(msg.sender == doctors[doctorId].doctorAddress, "Only this doctor can do this");
        require(doctors[doctorId].isActive, "Doctor is not active");
        _;
    }

    // Either the patient or their assigned doctor can call this
    modifier onlyPatientOrAssignedDoctor(uint256 patientId, uint256 doctorId) {
        require(
            msg.sender == patients[patientId].patientAddress || 
            (msg.sender == doctors[doctorId].doctorAddress && doctorPatientAssignments[doctorId][patientId]),
            "You don't have access"
        );
        _;
    }

    // Checks if a doctor exists
    modifier doctorExists(uint256 doctorId) {
        require(doctors[doctorId].doctorAddress != address(0), "Doctor doesn't exist");
        _;
    }

    // Checks if a patient exists
    modifier patientExists(uint256 patientId) {
        require(patients[patientId].patientAddress != address(0), "Patient doesn't exist");
        _;
    }

    // Checks if a medicine exists
    modifier medicineExists(uint256 medicineId) {
        require(medicines[medicineId].medicineId != 0, "Medicine doesn't exist");
        _;
    }

    // Sets up the contract with the creator as admin
    constructor() {
        admin = msg.sender;
    }

    // Lets the admin transfer their role to someone else
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0) && newAdmin != admin, "Invalid new admin");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    // Registers a new doctor to the system (admin only)
    function registerDoctor(
        address doctorAddress,
        uint256 doctorId,
        string memory name,
        string memory qualification,
        string memory workplace,
        string memory certificationHash
    ) external onlyAdmin {
        require(doctors[doctorId].doctorAddress == address(0), "Doctor already exists");
        require(doctorAddress != address(0), "Invalid address");
        require(bytes(name).length > 0 && bytes(qualification).length > 0 && 
               bytes(workplace).length > 0 && bytes(certificationHash).length > 0, "Empty fields not allowed");
        
        doctors[doctorId] = Doctor(doctorAddress, doctorId, name, qualification, workplace, certificationHash, true);
        doctorCount++;
        emit DoctorRegistered(doctorId, doctorAddress);
    }

    // Views basic doctor info
    function viewDoctorByID(uint256 doctorId) external view returns (string memory, string memory, string memory, string memory) {
        require(doctors[doctorId].doctorAddress != address(0), "Doctor doesn't exist");
        Doctor memory d = doctors[doctorId];
        return (d.name, d.qualification, d.workplace, d.certificationHash);
    }

    // Updates a doctor's certification document
    function updateDoctorCertification(uint256 doctorId, string memory ipfsHash) external onlyAdmin {
        require(doctors[doctorId].doctorAddress != address(0), "Doctor doesn't exist");
        require(bytes(ipfsHash).length > 0, "Empty hash not allowed");
        require(keccak256(bytes(doctors[doctorId].certificationHash)) != keccak256(bytes(ipfsHash)), "Same hash already set");
        doctors[doctorId].certificationHash = ipfsHash;
        emit DoctorCertificationUpdated(doctorId, ipfsHash);
    }

    // Updates a doctor's personal info
    function updateDoctorDetails(
        uint256 doctorId, 
        string memory name, 
        string memory qualification, 
        string memory workplace
    ) external onlyAdmin {
        require(doctors[doctorId].doctorAddress != address(0), "Doctor doesn't exist");
        require(bytes(name).length > 0 && bytes(qualification).length > 0 && bytes(workplace).length > 0, "Empty fields not allowed");
        doctors[doctorId].name = name;
        doctors[doctorId].qualification = qualification;
        doctors[doctorId].workplace = workplace;
        emit DoctorUpdated(doctorId);
    }

    // Deactivates a doctor
    function deactivateDoctor(uint256 doctorId) external onlyAdmin {
        require(doctors[doctorId].doctorAddress != address(0), "Doctor doesn't exist");
        doctors[doctorId].isActive = false;
        emit DoctorDeactivated(doctorId);
    }

    // Registers a new patient (doctor only)
    function registerPatient(
        uint256 doctorId,
        address patientAddress,
        uint256 patientId,
        string memory name,
        uint8 age,
        string[] memory diseases,
        string[] memory recordHashes
    ) external onlyDoctor(doctorId) {
        require(patients[patientId].patientAddress == address(0), "Patient already exists");
        require(patientAddress != address(0), "Invalid address");
        require(bytes(name).length > 0 && age > 0 && age <= 120, "Invalid info provided");
        
        patients[patientId] = Patient(patientAddress, patientId, name, age, diseases, recordHashes, true);

        // Track all diseases
        for (uint256 i = 0; i < diseases.length; i++) {
            _existingDiseases[patientId][diseases[i]] = true;
        }

        // Track all records
        for (uint256 i = 0; i < recordHashes.length; i++) {
            _existingRecords[patientId][recordHashes[i]] = true;
        }

        // Assign this doctor to patient
        doctorPatientAssignments[doctorId][patientId] = true;
        patientCount++;
        emit PatientRegistered(patientId, patientAddress);
        emit DoctorAssigned(doctorId, patientId);
    }

    // Views complete patient info (patient or their doctor only)
    function viewPatientDetails(uint256 doctorId, uint256 patientId) external view returns (Patient memory) {
        require(patients[patientId].patientAddress != address(0), "Patient doesn't exist");
        require(
            msg.sender == patients[patientId].patientAddress || 
            (msg.sender == doctors[doctorId].doctorAddress && doctorPatientAssignments[doctorId][patientId]),
            "You don't have access"
        );
        return patients[patientId];
    }

    // Adds a disease to patient's record (their doctor only)
    function updatePatientDisease(uint256 doctorId, uint256 patientId, string memory disease) external onlyDoctor(doctorId) {
        require(patients[patientId].patientAddress != address(0), "Patient doesn't exist");
        require(doctorPatientAssignments[doctorId][patientId], "Not this patient's doctor");
        require(!_existingDiseases[patientId][disease], "Disease already recorded");
        
        patients[patientId].diseases.push(disease);
        _existingDiseases[patientId][disease] = true;
        emit DiseaseAdded(patientId, disease);
    }

    // Adds a medical record to patient's file (their doctor only)
    function updatePatientRecord(uint256 doctorId, uint256 patientId, string memory recordHash) external onlyDoctor(doctorId) {
        require(patients[patientId].patientAddress != address(0), "Patient doesn't exist");
        require(doctorPatientAssignments[doctorId][patientId], "Not this patient's doctor");
        require(!_existingRecords[patientId][recordHash], "Record already exists");
        
        patients[patientId].recordHashes.push(recordHash);
        _existingRecords[patientId][recordHash] = true;
        emit RecordAdded(patientId, recordHash);
    }

    // Deactivates a patient (admin only)
    function deactivatePatient(uint256 patientId) external onlyAdmin {
        require(patients[patientId].patientAddress != address(0), "Patient doesn't exist");
        patients[patientId].isActive = false;
        emit PatientDeactivated(patientId);
    }

    // Adds a new medicine to the system (admin only)
    function addMedicine(
        uint256 medicineId,
        string memory name,
        string memory expiryDate,
        string memory dosage,
        uint256 price
    ) external onlyAdmin {
        require(medicines[medicineId].medicineId == 0, "Medicine already exists");
        require(bytes(name).length > 0 && bytes(expiryDate).length > 0 && bytes(dosage).length > 0, "Empty fields not allowed");
        require(price > 0, "Price must be positive");
        
        medicines[medicineId] = Medicine(medicineId, name, expiryDate, dosage, price, true);
        medicineCount++;
        emit MedicineAdded(medicineId);
    }

    // Views medicine details
    function viewMedicine(uint256 medicineId) external view returns (string memory, string memory, string memory, uint256) {
        require(medicines[medicineId].medicineId != 0, "Medicine doesn't exist");
        Medicine memory m = medicines[medicineId];
        return (m.name, m.expiryDate, m.dosage, m.price);
    }

    // Updates medicine info (admin only)
    function updateMedicine(
        uint256 medicineId,
        string memory name,
        string memory expiryDate,
        string memory dosage,
        uint256 price
    ) external onlyAdmin {
        require(medicines[medicineId].medicineId != 0, "Medicine doesn't exist");
        require(bytes(name).length > 0 && bytes(expiryDate).length > 0 && bytes(dosage).length > 0, "Empty fields not allowed");
        require(price > 0, "Price must be positive");

        medicines[medicineId].name = name;
        medicines[medicineId].expiryDate = expiryDate;
        medicines[medicineId].dosage = dosage;
        medicines[medicineId].price = price;
        emit MedicineUpdated(medicineId);
    }

    // Deactivates a medicine (admin only)
    function deactivateMedicine(uint256 medicineId) external onlyAdmin {
        require(medicines[medicineId].medicineId != 0, "Medicine doesn't exist");
        medicines[medicineId].isActive = false;
        emit MedicineDeactivated(medicineId);
    }

    // Prescribes medicine to a patient (their doctor only)
    function prescribeMedicine(uint256 doctorId, uint256 patientId, uint256 medicineId) external onlyDoctor(doctorId) {
        require(patients[patientId].patientAddress != address(0), "Patient doesn't exist");
        require(medicines[medicineId].medicineId != 0, "Medicine doesn't exist");
        require(doctorPatientAssignments[doctorId][patientId], "Not this patient's doctor");
        require(medicines[medicineId].isActive, "Medicine is inactive");
        
        prescriptions[patientId].push(medicineId);
        emit PrescriptionAdded(patientId, medicineId);
    }

    // Views all prescriptions for a patient (patient or their doctor only)
    function viewPrescribedMedicines(uint256 patientId, uint256 doctorId) external view returns (uint256[] memory) {
        require(patients[patientId].patientAddress != address(0), "Patient doesn't exist");
        require(
            msg.sender == patients[patientId].patientAddress || 
            (msg.sender == doctors[doctorId].doctorAddress && doctorPatientAssignments[doctorId][patientId]),
            "You don't have access"
        );
        return prescriptions[patientId];
    }

    // Assigns a doctor to a patient (admin only)
    function assignDoctorToPatient(uint256 doctorId, uint256 patientId) external onlyAdmin {
        require(doctors[doctorId].doctorAddress != address(0), "Doctor doesn't exist");
        require(patients[patientId].patientAddress != address(0), "Patient doesn't exist");
        doctorPatientAssignments[doctorId][patientId] = true;
        emit DoctorAssigned(doctorId, patientId);
    }
}