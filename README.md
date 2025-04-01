# Medical Records Smart Contract

## Overview
The **Medical Records** smart contract is a blockchain-based system designed to securely store and manage medical records using Solidity. It ensures transparency, security, and accessibility while maintaining privacy and control over medical data. This contract allows admins to manage doctors, patients, and medicines while ensuring that only authorized parties can access or update sensitive medical information.

## Features
- **Admin Control:** The admin can register doctors, update their information, and deactivate them.
- **Doctor Management:** Doctors can be registered with their details and certification stored on IPFS.
- **Patient Management:** Doctors can register patients, update medical conditions, and manage records.
- **Medicine Management:** Admins can add, update, or deactivate medicines.
- **Access Control:** Only assigned doctors or the patients themselves can view patient data.
- **Prescription Handling:** Doctors can prescribe medicines to patients.
- **Reentrancy Protection:** Uses OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks.

## Technologies Used
- **Solidity** (Smart contract language)
- **OpenZeppelin** (Security enhancements)
- **IPFS** (Decentralized storage for medical records and doctor certifications)

## Contract Structure
### State Variables
- `admin`: Stores the address of the contract administrator.
- `doctorCount`, `patientCount`, `medicineCount`: Counters for tracking registered entities.

### Structs
- `Doctor`: Contains information about doctors, including their address, name, qualification, workplace, and certification hash.
- `Patient`: Stores patient details such as age, diseases, and medical records.
- `Medicine`: Stores medicine details like expiry date, dosage, and price.

### Mappings
- `doctors`, `patients`, `medicines`: Store respective entities using IDs.
- `prescriptions`: Maps patients to prescribed medicines.
- `doctorPatientAssignments`: Tracks which doctors are assigned to which patients.

### Events
- Various events for logging doctor registration, patient updates, medicine additions, and more.

## Access Control
### Modifiers
- `onlyAdmin()`: Restricts function access to the contract administrator.
- `onlyDoctor(doctorId)`: Ensures only the specified doctor can perform certain actions.
- `onlyPatientOrAssignedDoctor(patientId, doctorId)`: Allows either the patient or their assigned doctor to access data.
- `doctorExists(doctorId)`, `patientExists(patientId)`, `medicineExists(medicineId)`: Ensure referenced entities exist.

## Functions
### Admin Functions
- `transferAdmin(address newAdmin)`: Transfers admin rights to another address.
- `registerDoctor()`, `updateDoctorDetails()`, `deactivateDoctor()`: Manage doctor records.
- `addMedicine()`, `updateMedicine()`, `deactivateMedicine()`: Manage medicine records.
- `assignDoctorToPatient()`: Assigns a doctor to a patient.

### Doctor Functions
- `registerPatient()`: Adds a new patient.
- `updatePatientDisease()`, `updatePatientRecord()`: Updates patient medical data.
- `prescribeMedicine()`: Prescribes medicine to a patient.

### Patient & Doctor Functions
- `viewDoctorByID()`: Retrieves doctor details.
- `viewPatientDetails()`: Retrieves patient details.
- `viewPrescribedMedicines()`: Retrieves a patient’s prescriptions.

## Installation & Deployment
1. Install dependencies:
   ```sh
   npm install @openzeppelin/contracts
   ```
2. Compile the contract using Hardhat:
   ```sh
   npx hardhat compile
   ```
3. Deploy using Hardhat scripts:
   ```sh
   npx hardhat run scripts/deploy.js --network <network>
   ```

## Security Considerations
- **Access Control:** Only authorized users can modify sensitive data.
- **IPFS Storage:** Medical records are stored off-chain for privacy.
- **Reentrancy Protection:** Utilizes OpenZeppelin’s `ReentrancyGuard` to prevent attacks.

## License
This project is licensed under the **MIT License**.

## Author
Gaurav Kumar Mishra

