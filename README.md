ProvenancePulse
===============

This repository contains the Clarity smart contract for **ProvenancePulse**, a robust and transparent supply chain provenance and tracking system. This contract provides immutable records of product journeys, from raw materials to end consumers, ensuring data integrity, ownership tracking, quality certifications, and secure access control.

Table of Contents
-----------------

-   Features

-   Contract Overview

    -   Constants

    -   Data Maps and Variables

    -   Private Functions

    -   Public Functions

    -   Read-Only Functions

    -   Error Codes

-   Usage

    -   Deploying the Contract

    -   Interacting with the Contract

-   Contribution

-   License

-   Related

Features
--------

-   **Immutable Tracking:** Records every stage of a product's journey on the blockchain, from raw materials through manufacturing, quality control, packaging, distribution, retail, and consumption.

-   **Ownership Transfers:** Securely tracks and records changes in product ownership between authorized supply chain participants.

-   **Quality Certifications:** Allows authorized entities to add and verify quality certifications, inspections, and compliance records.

-   **Location Tracking:** Stores location data for each ownership transfer, enhancing transparency.

-   **Access Control:** Implements role-based access control, ensuring only authorized participants can perform specific actions.

-   **Audit Trail:** Provides a comprehensive audit trail for any product, validating its journey and associated certifications.

-   **Participant Management:** Registers and certifies supply chain participants, distinguishing roles and authorization levels.

Contract Overview
-----------------

The `ProvenancePulse` contract is written in Clarity, a decidable smart contract language for the Stacks blockchain.

### Constants

Defines fixed values used throughout the contract, including the `CONTRACT-OWNER` principal, various `ERR-*` codes for specific error conditions, and `STAGE-*` constants representing different supply chain stages.

| Constant Name           | Value       | Description                                  |
| :---------------------- | :---------- | :------------------------------------------- |
| `CONTRACT-OWNER`        | `tx-sender` | The principal who deploys the contract.      |
| `ERR-UNAUTHORIZED`      | `u100`      | Caller is not authorized for the action.     |
| `ERR-PRODUCT-NOT-FOUND` | `u101`      | Product with the given ID does not exist.    |
| `ERR-INVALID-STAGE`     | `u102`      | Invalid stage transition attempted.          |
| `ERR-ALREADY-EXISTS`    | `u103`      | Entity (participant/product) already exists. |
| `ERR-INVALID-PARTICIPANT`| `u104`     | The specified participant is not registered. |
| `ERR-CERTIFICATION-EXPIRED` | `u105`   | Certification has expired.                   |
| `STAGE-RAW-MATERIAL`    | `u1`        | Raw material stage.                          |
| `STAGE-MANUFACTURING`   | `u2`        | Manufacturing stage.                         |
| `STAGE-QUALITY-CONTROL` | `u3`        | Quality control stage.                       |
| `STAGE-PACKAGING`       | `u4`        | Packaging stage.                             |
| `STAGE-DISTRIBUTION`    | `u5`        | Distribution stage.                          |
| `STAGE-RETAIL`          | `u6`        | Retail stage.                                |
| `STAGE-CONSUMER`        | `u7`        | End consumer stage.                          |


### Data Maps and Variables

-   **`participants`**: A map storing information about registered supply chain participants (name, role, certification status, registration block).

    -   Key: `{ participant: principal }`

    -   Value: `{ name: (string-ascii 50), role: (string-ascii 20), certified: bool, registration-block: uint }`

-   **`products`**: The main map for product tracking data (name, category, origin, current owner, current stage, creation/last update timestamps).

    -   Key: `{ product-id: (string-ascii 32) }`

    -   Value: `{ name: (string-ascii 100), category: (string-ascii 30), origin: (string-ascii 50), current-owner: principal, current-stage: uint, created-at: uint, last-updated: uint }`

-   **`ownership-history`**: Records the history of ownership transfers for each product.

    -   Key: `{ product-id: (string-ascii 32), transfer-id: uint }`

    -   Value: `{ from-owner: principal, to-owner: principal, stage: uint, timestamp: uint, location: (string-ascii 50), notes: (string-ascii 200) }`

-   **`certifications`**: Stores quality certifications and inspection details for products.

    -   Key: `{ product-id: (string-ascii 32), cert-id: uint }`

    -   Value: `{ certifier: principal, cert-type: (string-ascii 30), issued-at: uint, expires-at: uint, status: (string-ascii 20), details: (string-ascii 150) }`

-   **`next-transfer-id`**: A data variable to generate unique IDs for ownership transfers.

-   **`next-cert-id`**: A data variable to generate unique IDs for certifications.

### Private Functions

-   `(is-authorized-participant (participant principal))`: Checks if a given participant is registered and certified.

-   `(is-valid-stage-transition (current-stage uint) (new-stage uint))`: Validates if a stage transition is valid (can only move forward or stay the same).

-   `(get-next-transfer-id)`: Increments and returns the next available transfer ID.

-   `(get-next-cert-id)`: Increments and returns the next available certification ID.

### Public Functions

These functions modify the contract state.

-   `(register-participant (name (string-ascii 50)) (role (string-ascii 20)))`: Allows any address to register as a supply chain participant. Initially, only the contract owner is certified.

-   `(certify-participant (participant principal))`: Authorizes a registered participant. Only the `CONTRACT-OWNER` can call this function.

-   `(create-product (product-id (string-ascii 32)) (name (string-ascii 100)) (category (string-ascii 30)) (origin (string-ascii 50)))`: Creates a new product, setting its initial stage to `STAGE-RAW-MATERIAL` and the caller as its current owner. Only authorized participants can call this.

-   `(transfer-ownership (product-id (string-ascii 32)) (to-owner principal) (new-stage uint) (location (string-ascii 50)) (notes (string-ascii 200)))`: Transfers ownership of a product to a new authorized participant and updates its stage. The caller must be the current owner of the product.

-   `(add-certification (product-id (string-ascii 32)) (cert-type (string-ascii 30)) (expires-at uint) (details (string-ascii 150)))`: Adds a quality certification to a product. Only authorized participants can call this.

-   `(generate-audit-trail (product-id (string-ascii 32)) (max-transfers uint) (validate-certifications bool))`: Provides a comprehensive audit trail for a product, including product info, total transfers, total certifications, audit timestamp, auditor, chain integrity check, and days in supply chain. It can also perform basic certification validation if `validate-certifications` is true. Access is restricted to the current owner, contract owner, or certified participants.

### Read-Only Functions

These functions do not modify the contract state and can be called without a transaction.

-   `(get-product (product-id (string-ascii 32)))`: Retrieves details of a product by its ID.

-   `(get-participant (participant principal))`: Retrieves details of a registered participant.

-   `(get-ownership-record (product-id (string-ascii 32)) (transfer-id uint))`: Retrieves a specific ownership transfer record for a product.

-   `(get-certification (product-id (string-ascii 32)) (cert-id uint))`: Retrieves a specific certification record for a product.

### Error Codes

The contract uses specific error codes to indicate the reason for a failed transaction.

-   `u100`: Unauthorized access or action.

-   `u101`: Product not found.

-   `u102`: Invalid supply chain stage transition.

-   `u103`: Entity (participant or product) already exists.

-   `u104`: Invalid or unregistered participant.

-   `u105`: Certification has expired (simplified check in `generate-audit-trail`).

Usage
-----

### Deploying the Contract

To use this contract, you will need to deploy it to the Stacks blockchain. You can use the Stacks CLI or a Stacks-compatible IDE (like Clarinet) for deployment.

1.  **Install Clarinet:** Follow the instructions on the [Clarinet GitHub page](https://github.com/hirosystems/clarinet "null") to install the Clarity development environment.

2.  **Create a new Clarinet project:**

    ```
    clarinet new my-supply-chain-app
    cd my-supply-chain-app

    ```

3.  **Place the contract:** Save the provided Clarity contract code as `contracts/provenance-pulse.clar` within your Clarinet project.

4.  **Deploy:**

    ```
    clarinet deploy

    ```

    This will deploy your contract to the specified network (e.g., testnet).

### Interacting with the Contract

Once deployed, you can interact with the contract's public and read-only functions using the Stacks.js library in a dApp or directly via the Stacks CLI.

**Example Interaction Flow:**

1.  **Register Participants:**

    ```
    ;; Alice registers as a "Manufacturer"
    (contract-call? .provenance-pulse register-participant "Alice Corp" "Manufacturer")
    ;; Bob registers as a "Distributor"
    (contract-call? .provenance-pulse register-participant "Bob Logistics" "Distributor")

    ```

2.  **Certify Participants (by CONTRACT-OWNER):**

    ```
    ;; Contract owner certifies Alice and Bob
    (contract-call? .provenance-pulse certify-participant ST1PQHQKV0RJZEK4XJ8GGQ9MGM6QZ6ENHGX8DQJRJ) ;; Alice's principal
    (contract-call? .provenance-pulse certify-participant ST2CY5K0CGF02X076GBJRPQW06YJ9418HGB6T4QG) ;; Bob's principal

    ```

3.  **Create a Product (by certified manufacturer):**

    ```
    ;; Alice creates a new product
    (contract-call? .provenance-pulse create-product "PROD001" "Organic Coffee Beans" "Ethiopia" "Highlands")

    ```

4.  **Transfer Ownership (e.g., from Manufacturer to Distributor):**

    ```
    ;; Alice transfers coffee beans to Bob
    (contract-call? .provenance-pulse transfer-ownership "PROD001" ST2CY5K0CGF02X076GBJRPQW06YJ9418HGB6T4QG STAGE-DISTRIBUTION "Warehouse A, Addis Ababa" "Shipped via air cargo")

    ```

5.  **Add Certification:**

    ```
    ;; A quality control entity adds a certification
    (contract-call? .provenance-pulse add-certification "PROD001" "Organic Certified" (+ block-height u1000) "Certified by Global Organic Alliance")

    ```

6.  **Generate Audit Trail:**

    ```
    ;; Get the full audit trail for PROD001
    (contract-call? .provenance-pulse generate-audit-trail "PROD001" u10 true)

    ```

7.  **Query Data (Read-Only):**

    ```
    ;; Get product details
    (contract-call? .provenance-pulse get-product "PROD001")
    ;; Get participant details
    (contract-call? .provenance-pulse get-participant ST1PQHQKV0RJZEK4XJ8GGQ9MGM6QZ6ENHGX8DQJRJ)

    ```

Contribution
------------

Contributions are welcome! If you have suggestions for improvements, bug reports, or want to add new features, please open an issue or submit a pull request.

1.  Fork the repository.

2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).

3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).

4.  Push to the branch (`git push origin feature/AmazingFeature`).

5.  Open a Pull Request.

License
-------

This project is licensed under the MIT License - see the `LICENSE` file (if applicable) for details.

Related
-------

-   Stacks Documentation

-   Clarity Language Guide

-   Clarinet Tooling
