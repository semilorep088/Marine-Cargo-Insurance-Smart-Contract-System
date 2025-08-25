# Marine Cargo Insurance Smart Contract System

A comprehensive blockchain-based marine cargo insurance system built on Stacks using Clarity smart contracts. This system provides end-to-end insurance coverage for international shipping cargo with automated risk assessment, premium calculation, claims processing, and dispute resolution.

## System Overview

The Marine Cargo Insurance system consists of five interconnected smart contracts:

1. **Cargo Assessment Contract** (`cargo-assessment.clar`)
    - Cargo value assessment and coverage determination
    - Policy creation and management
    - Coverage limits and deductible calculations

2. **Route Risk Analysis Contract** (`route-risk-analysis.clar`)
    - Route-based risk scoring and premium calculation
    - Weather and geopolitical risk factors
    - Dynamic premium adjustments

3. **Claims Processing Contract** (`claims-processing.clar`)
    - Automated claim submission and validation
    - Damage assessment and payout calculations
    - Multi-stage approval workflow

4. **Salvage Coordination Contract** (`salvage-coordination.clar`)
    - Salvage operation management
    - Recovery cost tracking and distribution
    - Salvage award calculations

5. **Compliance and Dispute Resolution Contract** (`compliance-dispute.clar`)
    - International maritime law compliance
    - Automated dispute resolution mechanisms
    - Regulatory reporting and audit trails

## Key Features

### Cargo Assessment & Coverage
- Automated cargo valuation based on type, quantity, and market rates
- Dynamic coverage determination with customizable limits
- Real-time policy generation and premium calculation
- Support for various cargo types (containers, bulk, liquid, etc.)

### Risk Analysis & Pricing
- Route-specific risk assessment using historical data
- Weather pattern analysis and seasonal adjustments
- Geopolitical risk factors and port security ratings
- Dynamic premium calculation based on multiple risk factors

### Claims Management
- Streamlined claim submission with required documentation
- Automated damage assessment using predefined criteria
- Multi-tier approval process for different claim amounts
- Instant payouts for pre-approved claim types

### Salvage Operations
- Coordinated salvage operation tracking
- Cost allocation between insurers and cargo owners
- Salvage award distribution according to maritime law
- Recovery asset management and liquidation

### Compliance & Disputes
- International maritime law compliance checking
- Automated dispute resolution with escalation paths
- Regulatory reporting and audit trail maintenance
- Multi-party arbitration support

## Contract Architecture

### Data Structures

**Policy Structure:**
- Policy ID, cargo owner, insured value
- Coverage type, deductible, premium
- Route information, validity period
- Status and claim history

**Cargo Information:**
- Cargo type, quantity, unit value
- Origin and destination ports
- Shipping method and vessel details
- Special handling requirements

**Risk Factors:**
- Route risk score, weather conditions
- Port security ratings, seasonal factors
- Historical loss data, geopolitical risks
- Insurance market conditions

**Claims Data:**
- Claim ID, policy reference, incident type
- Damage assessment, supporting documentation
- Approval status, payout amount
- Investigation notes and resolution

## Usage Examples

### Creating a Policy
```clarity
(contract-call? .cargo-assessment create-policy
  {
    cargo-type: "containers",
    quantity: u100,
    unit-value: u50000,
    origin-port: "SHANGHAI",
    destination-port: "LOSANGELES",
    coverage-type: "all-risks"
  }
)
